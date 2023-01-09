function [phyParams,simValues,outputValues,sinrManagement,stationManagement,timeManagement] = ...
            mainCV2XtransmissionEnds(appParams,simParams,phyParams,outParams,simValues,outputValues,timeManagement,positionManagement,sinrManagement,stationManagement)
% some C-V2X transmissions end 
     
% local variables for simpler reading
awarenessID_LTE = stationManagement.awarenessIDLTE;
neighborsID_LTE = stationManagement.neighborsIDLTE;

% Compute elapsed time [the unit of measure is the subframe time i.e. phyParams.Tsf]
%elapsedTime_subframes = floor((timeManagement.timeNow-1e-9)/phyParams.Tsf)+1;

if ~isempty(stationManagement.transmittingIDsCV2X)   

    % Find ID and index of vehicles that are currently transmitting in LTE
    activeIDsTXLTE = stationManagement.transmittingIDsCV2X;
    indexInActiveIDsOnlyLTE = stationManagement.indexInActiveIDsOnlyLTE_OfTxLTE;

    if simParams.technology == 4 % COEXISTENCE IN THE SAME BAND
        [timeManagement,stationManagement,sinrManagement,outputValues] = coexistenceAtLTEsubframeEnd(timeManagement,stationManagement,sinrManagement,simParams,simValues,phyParams,outParams,outputValues);
    end

    %% Start computing KPIs only after the first BR assignment (after the first cycle)

    % Compute SINR of received beacons
    % sinrManagement = updateSINRLTE(timeManagement.timeNow,stationManagement,sinrManagement,phyParams.Pnoise_MHz*phyParams.BwMHz_cv2xBR,simParams,appParams);
    % (Vittorio) Now the call passes the value of PnoiseData and PnoiseSCI
    sinrManagement = updateSINRCV2X(timeManagement.timeNow,stationManagement,sinrManagement,phyParams.PnoiseData,phyParams.PnoiseSCI,simParams,appParams);
    
    % Code for possible DEBUG
    % figure(100)
    % plot(elapsedTime_subframes*ones(1,length(neighborsSINRaverageCV2X(:,:))),10*log10(neighborsSINRaverageCV2X(:,:)),'*');
    % hold on

    % DEBUG TX
    printDebugTx(timeManagement.timeNow,false,-1,stationManagement,positionManagement,sinrManagement,outParams,phyParams);

    % Code for possible DEBUG
    % figure(200)
    % plot(elapsedTime_subframes*ones(1,length(errorMatrixRawMax(:,4))),errorMatrixRawMax(:,4),'*');
    % hold on

    % Code for possible DEBUG
    % figure(300)
    % plot(elapsedTime_subframes*ones(1,length(errorMatrix(1,:))),10*log10(errorMatrix(1,:)),'*');
    % hold on

    % Check the correctness of SCI messages
    if simParams.BRAlgorithm==18
        % correctSCImatrix is nTXLTE x nNeighblors
        stationManagement.correctSCImatrixCV2X = (sinrManagement.neighborsSINRsciAverageCV2X > phyParams.minSCIsinr);
        
        %if simParams.technology==4 && simParams.coexMethod>1 && simParams.coex_slotManagement==2
        if simParams.technology==4 %&& simParams.coexMethod>1 && simParams.coex_slotManagement==2
            % In mitigation methods with dynamic slot duration, 
            % we need the calculation of the CBR_LTE
            % To this aim, the correct/wrong reception of SCI messages in this subframe is
            % stored in "stationManagement.correctSCImatrixCV2X(,)"
            % A record with the SCI messages in the last 100 subframes is
            % required: "stationManagement.coex_correctSCIhistory(subframe,idVehicle)" is used 
            % Step 1: circular shift of the matrix and zeros to remove oldest record
            sinrManagement.coex_correctSCIhistory(:,:) = circshift(sinrManagement.coex_correctSCIhistory(:,:),appParams.NbeaconsF);
            sinrManagement.coex_correctSCIhistory(1:appParams.NbeaconsF,:) = 0;
            % Step 2: new record
            for i = 1:length(stationManagement.transmittingIDsCV2X)
                
                % Replicas do not cause an update of 'coex_correctSCIhistory'
                if stationManagement.pckTxOccurring(activeIDsTXLTE(i))>1
                    continue;
                end
                
                indexVtxLte = stationManagement.indexInActiveIDsOnlyLTE_OfTxLTE(i);
                for indexNeighborsOfVtx = 1:length(stationManagement.neighborsIDLTE(indexVtxLte,:))
                   idVrx = stationManagement.neighborsIDLTE(indexVtxLte,indexNeighborsOfVtx);
                   if idVrx<=0
                       break;
                   end
                   if stationManagement.correctSCImatrixCV2X(i,indexNeighborsOfVtx) == 1 % correct reception of the SCI                       
                       %sinrManagement.coex_correctSCIhistory(mod(stationManagement.BRid(stationManagement.transmittingIDsCV2X(i))-1,appParams.NbeaconsF)+1,idVrx) = 1;
                       sinrManagement.coex_correctSCIhistory(stationManagement.transmittingFusedLTE(i),idVrx) = 1;
                   end
                end
            end
        end
    end
    
    %% KPIs Computation (Snapshot)
    [stationManagement,sinrManagement,outputValues,simValues] = updateKPICV2X(activeIDsTXLTE,indexInActiveIDsOnlyLTE,awarenessID_LTE,neighborsID_LTE,timeManagement,stationManagement,positionManagement,sinrManagement,outputValues,outParams,simParams,appParams,phyParams,simValues);

            
else
% No LTE transmitting (Vittorio)
    if simParams.technology == 4
        % IDvehicleTXLTE is empty
        % but I need to update the average interfering power from 11p nodes
        % sinrManagement = updateSINRLTE(timeManagement.timeNow,stationManagement,sinrManagement,phyParams.Pnoise_MHz*phyParams.BwMHz_cv2xBR,simParams,appParams);
        sinrManagement = updateSINRCV2X(timeManagement.timeNow,stationManagement,sinrManagement,phyParams.PnoiseData,phyParams.PnoiseSCI,simParams,appParams);
        
        % and in some cases (Method B) I need to reset Interf power from
        % LTE nodes
        %if simParams.coexMethod==2
        if sum(sinrManagement.coex_InterfFromLTEto11p)>0
            [timeManagement,stationManagement,sinrManagement,outputValues] = coexistenceAtLTEsubframeEnd(timeManagement,stationManagement,sinrManagement,simParams,simValues,phyParams,outParams,outputValues);
        end
    end
end 

