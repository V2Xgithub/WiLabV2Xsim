function [timeManagement,stationManagement,sinrManagement] = CV2XsensingProcedure(timeManagement,stationManagement,sinrManagement,simParams,phyParams,appParams,outParams)
% Sensing-based autonomous resource reselection algorithm (3GPP MODE 4)
% as from 3GPP TS 36.321 and TS 36.213
% Resources are allocated for a Resource Reselection Period (SPS)
% Sensing is performed in the last 1 second
% Map of the received power and selection of the best 20% transmission hypothesis
% Random selection of one of the M best candidates
% The selection is rescheduled after a random period, with random
% probability controlled by the input parameter 'probResKeep'

% Calculate current T within the NbeaconsT
currentT = mod(timeManagement.elapsedTime_TTIs-1,appParams.NbeaconsT)+1; 

%% PART 1: Update the sensing matrix
% The sensingMatrix is a 3D matrix with
% 1st D -> Number of values to be stored in the time domain, corresponding
%          to the standard duration of 1 second, of size ceil(1/Tbeacon)
% 2nd D -> BRid, of size Nbeacons
% 3rd D -> IDs of vehicles

% Array of BRids in the current subframe 
BRids_currentSF = ((currentT-1)*appParams.NbeaconsF+1):(currentT*appParams.NbeaconsF);

% A shift is performed to the estimations (1st dimension) corresponding 
% to the BRids in the current subframe for all vehicles
stationManagement.sensingMatrixCV2X(:,BRids_currentSF,:) = circshift(stationManagement.sensingMatrixCV2X(:,BRids_currentSF,:),1);

% The values in the first position of the 1st dimension (means last measurement) of
% the BRids in the current subframe are reset for all vehicles
%sensedPowerCurrentSF = 0;
% Refactoring in Version 5.3.1_3
sensedPowerCurrentSF_MHz = zeros(length(BRids_currentSF),length(stationManagement.activeIDsCV2X));

%stationManagement.sensingMatrix(1,BRids_currentSF,:) = 0;
% In case, the values will be hereafter filled with the latest measurements

% Update of the sensing matrix
% First the LTE to LTE sensed power is saved in sensedPowerCurrentSF
if ~isempty(stationManagement.transmittingIDsCV2X)   
    
    if isempty(sinrManagement.sensedPowerByLteNo11p)                
        sensedPowerCurrentSF_MHz = sensedPowerCV2X(stationManagement,sinrManagement,appParams,phyParams);
    else        
        sensedPowerCurrentSF_MHz = sinrManagement.sensedPowerByLteNo11p;
    end
else
    % if there are no LTE transmissions, the sensedPowerCurrentSF remains 0
end

% sensedPowerCurrentSF = sensedPowerCurrentSF + repmat((sinrManagement.coex_averageSFinterfFrom11pToLTE(stationManagement.activeIDsCV2X))',appParams.NbeaconsF,1);
% Possible addition of 11p interfrence
if simParams.technology~=4 || simParams.coexMethod~=3 || ~simParams.coexC_11pDetection
    interfFrom11p = (sinrManagement.coex_averageSFinterfFrom11pToLTE(stationManagement.activeIDsCV2X));
    sensedPowerCurrentSF_MHz = sensedPowerCurrentSF_MHz + repmat(interfFrom11p',appParams.NbeaconsF,1);
else
    % In case of method C, 11p interference is not added if an 11p
    % transmission has been detected
    interfFrom11p = (sinrManagement.coex_averageSFinterfFrom11pToLTE(stationManagement.activeIDsCV2X)) .* ~sinrManagement.coex_lteDetecting11pTx(stationManagement.activeIDsCV2X);
    sensedPowerCurrentSF_MHz = sensedPowerCurrentSF_MHz + repmat(interfFrom11p',appParams.NbeaconsF,1);
    sinrManagement.coex_lteDetecting11pTx(:,:) = false;
end

% Small interference is changed to 0 to avoid small interference affecting
% the allocation process
sensedPowerCurrentSF_MHz(sensedPowerCurrentSF_MHz<phyParams.Pnoise_MHz) = 0;

% Sensign matrix updated
stationManagement.sensingMatrixCV2X(1,BRids_currentSF,stationManagement.activeIDsCV2X) = sensedPowerCurrentSF_MHz;
    
%% PART 2: Update the knownUsedMatrix (i.e., the status as read from the SCI messages)

% Cycle that updates per each vehicle and BR the knownUsedMatrix
% The known used matrix of this TTI (next beacon interval) is reset
stationManagement.knownUsedMatrixCV2X(BRids_currentSF,:) = 0;


% Reset of matrix of received SCIs for the current subframe
if simParams.technology==4 && simParams.coexMethod==6
    stationManagement.coexF_knownUsed(BRids_currentSF,:) = 0;
end

if ~isempty(stationManagement.transmittingIDsCV2X)
    for i = 1:length(stationManagement.indexInActiveIDsOnlyLTE_OfTxLTE)
        idVtx = stationManagement.transmittingIDsCV2X(i);
        indexVtxLte = stationManagement.indexInActiveIDsOnlyLTE_OfTxLTE(i);
        %BRtx = stationManagement.BRid(idVtx,1);
        BRtx = (currentT-1)*appParams.NbeaconsF+stationManagement.transmittingFusedLTE(i);
        %
        % Detects if the transmission is a "first transmission" or retransmission
        hasFirstResourceThisTbeacon = ceil(stationManagement.BRid(idVtx,1)/appParams.NbeaconsF)==currentT;
                              
        if phyParams.cv2xNumberOfReplicasMax>1 && hasFirstResourceThisTbeacon && simParams.mode5G
            % BR of the next reserved resource (blind retransmission)
            BRnextReservedTransmission=stationManagement.BRid(idVtx,2);
        else
            BRnextReservedTransmission=-1;
        end
            
        for indexNeighborsOfVtx = 1:length(stationManagement.neighborsIDLTE(indexVtxLte,:))
           idVrx = stationManagement.neighborsIDLTE(indexVtxLte,indexNeighborsOfVtx);
           if idVrx<=0
               break;
           end
           % IF the SCI is transmitted in this subframe AND if it is correctly
           % received 
           if stationManagement.correctSCImatrixCV2X(i,indexNeighborsOfVtx) == 1                
               if simParams.technology==4 && simParams.coexMethod==6
                   % Matrix registering the received SCIs for mitigation
                   % method F
                   stationManagement.coexF_knownUsed(BRtx,idVrx) = 1;
               end
               % if the reselection counter for the transmission is greater
               % than 1 the 'knownUsedMatrix' is updated.
               % if the reselection counter has reached 1, then the value
               % of 'knownUsedMatrix' is set to 0.
               % 'knownUsedMatrix' set to 0 advertise that the resource is
               % not used for the next transmission period.

               if stationManagement.resReselectionCounterCV2X(idVtx)>1
                   % Reserve the next resource
                    stationManagement.knownUsedMatrixCV2X(BRtx,idVrx) = 1;                    
               else
                    stationManagement.knownUsedMatrixCV2X(BRtx,idVrx) = 0;
               end

%                % if HARQ is active in 5G -> reserve the next retransmission
               if phyParams.cv2xNumberOfReplicasMax>1 && hasFirstResourceThisTbeacon && BRnextReservedTransmission~=-1 && simParams.mode5G
                    % BR of the next reserved resource (blind retransmission)
                    stationManagement.knownUsedMatrixCV2X(BRnextReservedTransmission,idVrx) = 1;
                    % Power associated to the future reservation
                    % max between previous sensing and retransmission reservation
                    reservationRetransmissionPower = max(stationManagement.sensingMatrixCV2X(1,BRnextReservedTransmission,idVrx),stationManagement.sensingMatrixCV2X(1,BRtx,idVrx));
                    % Sensign matrix updated
                    stationManagement.sensingMatrixCV2X(1,BRnextReservedTransmission,idVrx) = reservationRetransmissionPower;
               end
               
               % If overlap of beacon resources is allowed, the SCI
               % information is used to update partially overlapping beacon
               % resources
               if phyParams.BRoverlapAllowed
                   for indexBR=BRids_currentSF
                       if (indexBR<BRtx && indexBR+phyParams.NsubchannelsBeacon-1>=BRtx) || ...
                          (indexBR>BRtx && indexBR-phyParams.NsubchannelsBeacon+1<=BRtx)
                           if stationManagement.resReselectionCounterCV2X(idVtx)>1
                               % Reserve the next resource
                                stationManagement.knownUsedMatrixCV2X(indexBR,idVrx) = 1;                                                            
                           else
                               % If RC=1 or lower the next resource is not reserved
                                stationManagement.knownUsedMatrixCV2X(indexBR,idVrx) = 0;
                           end                          
                        end
                    end
               end

%                % If overlap of beacon resources is allowed, the SCI
%                % information is used to update partially overlapping beacon
%                % resources when reserving resources for retransmissions
               if phyParams.BRoverlapAllowed && phyParams.cv2xNumberOfReplicasMax>1 && hasFirstResourceThisTbeacon && BRnextReservedTransmission~=-1 && simParams.mode5G
%                    % identify subframe of BR
%                    % Array of BRids in the slot of the retransmission
%                    % Slot at which the retransmission occurs
                   retransmitT = ceil(BRnextReservedTransmission/appParams.NbeaconsF);
                   BRids_retransmitSF = ((retransmitT-1)*appParams.NbeaconsF+1):(retransmitT*appParams.NbeaconsF);                  

                   for indexBR=BRids_retransmitSF
                       if (indexBR<BRnextReservedTransmission && indexBR+phyParams.NsubchannelsBeacon-1>=BRnextReservedTransmission) || ...
                          (indexBR>BRnextReservedTransmission && indexBR-phyParams.NsubchannelsBeacon+1<=BRnextReservedTransmission)
                               % Reserve the next resource
                                stationManagement.knownUsedMatrixCV2X(indexBR,idVrx) = 1;                                                                        
                        end
                   end
               end
           end
        end
    end
end

%% Removed from here since version 5.2.9 - now in the main
% %% PART 3: Calculation of the channel busy ratio
% % The channel busy ratio is calculated, if needed, every subframe for those
% % nodes that have a packet generated in the subframe that just ended
% if ~isempty(sinrManagement.cbrLTE)
%     [timeManagement,stationManagement,sinrManagement] = cbrUpdateLTE(timeManagement,stationManagement,sinrManagement,appParams,simParams,phyParams,outParams);
% end
%%

end

