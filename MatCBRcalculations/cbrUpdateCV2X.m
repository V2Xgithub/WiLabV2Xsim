function [timeManagement,stationManagement,sinrManagement,CBRvalues,coex_cbrLTEonlyValues] = cbrUpdateCV2X(timeManagement,vehiclesToConsider,stationManagement,positionManagement,sinrManagement,appParams,simParams,phyParams,outParams,outputValues)

% ETSI TS 103 574 V1.1.1 (2018-11)
% 5.2 Calculation of CBR [...]
% For PSSCH, CBR is the fraction of "sub-channels" whose S-RSSI exceeds a threshold -94 dBm.
% Note: sensingMatrix is per-MHz
% The threshold needs to be converted from sub-channel to RB
threshCBR_perSubchannel = db2pow(-94-30); % fixed in this version
%threshCBR_perRB = threshCBR_perSubchannel/phyParams.sizeSubchannel;
threshCBR_perMHz = threshCBR_perSubchannel / phyParams.BwMHz_cv2xSubCH;

% The sensingMatrix is a 3D matrix with
% 1st D -> Number of values to be stored in the time domain, corresponding
%          to the standard duration of 1 second, of size ceil(1/Tbeacon)
%          First is current frame, then the second is the previous one
%          and so on
% 2nd D -> BRid, of size Nbeacons
% 3rd D -> IDs of vehicles
sensingMatrix = stationManagement.sensingMatrixCV2X;
% nAllocationPeriodsCBR counts the number of allocation periods used for the
% sensing
nAllocationPeriodsCBR = min(ceil(simParams.cbrSensingInterval/appParams.allocationPeriod),size(sensingMatrix,1));

% The list of vehicles that must be updated is provided in input

% CBR is calculated only if enough subframes have elapsed
if ~isempty(vehiclesToConsider) && timeManagement.elapsedTime_TTIs > nAllocationPeriodsCBR * appParams.NbeaconsT
    % calculate CBR for each vehicle
    
%     currentT = (mod((timeManagement.elapsedTime_TTIs-1),appParams.NbeaconsT)+1);
%     sensingMatrix(:,currentT+1:end,:) = circshift(sensingMatrix(:,currentT+1:end,:), 1, 2);
    BRfree = sensingMatrix(1:nAllocationPeriodsCBR,:,vehiclesToConsider) <= threshCBR_perMHz;
    % 1. To use reshape function, the 1st and 2nd dimention should be
    % exchanged. because it outputs as follows
    % [1 2;        
    %  3 4]   -->> [1 3 2 4]
    %
    % 2. After reshape, BRfree should be with dimention a*b*c, where:
    % 1st-D is for different BR in one frame, 'a' is number of BRs in frequency
    % 2nd-D is for subframes, 'b' is the number of frames (= nAllocationPeriodsCBR * appParams.NbeaconsT)
    % 3rd-D is for different vehicles, 'c' is the number of vehicles to be considered
    BRfree = reshape(permute(BRfree, [2, 1, 3]), appParams.NbeaconsF, [], length(vehiclesToConsider));
    subchannelFree = true(phyParams.NsubchannelsFrequency, size(BRfree, 2), length(vehiclesToConsider));
    if ~phyParams.BRoverlapAllowed
        % fill BRfree on the subchannelFree.
        % 5 subchannels, each beacon occupies 2 subchannels, 2 BRs in frequency
        % [1 2]' stands for BRfree senced by one vehicle
        % [1    [0    [1
        %  1     0     1
        %  0  +  2  =  2
        %  0     2     2
        %  0]    0]    0]
        % 2 BRs on 5 subchannels
        subchannelFree(1:phyParams.NsubchannelsBeacon*appParams.NbeaconsF,:,:) =...
            subchannelFree(1:phyParams.NsubchannelsBeacon*appParams.NbeaconsF,:,:) & repelem(BRfree, phyParams.NsubchannelsBeacon, 1);
    else
        % overlap BRfree on the subchannelFree. An easy way to consider the overlap,
        % the follow figure might explain the idea: 
        % 5 subchannels, each beacon occupies 2 subchannels, 4 BRs in frequency
        % [1 2 3 4]' stands for BRfree senced by one vehicle
        %      [1;   [0   [1
        %       2;    1    1 2
        %       3; +  2 =    2 3  
        %       4;    3        3 4
        %       0]    4]         4]
        % 4 BRs on 5 subchannels
        for i = 1:phyParams.NsubchannelsBeacon
            subchannelFree(i:i+appParams.NbeaconsF-1,:,:) = subchannelFree(i:i+appParams.NbeaconsF-1,:,:) & BRfree;
        end
    end
    if simParams.technology == constants.TECH_COEX_STD_INTERF && simParams.coexMethod == constants.COEX_METHOD_A
        % TTI mark to exclude the 11p part if it has (assuming TTI = 1 ms)
        mask_length = nAllocationPeriodsCBR * appParams.NbeaconsT;
        mask_lte = [true(1, simParams.coex_endOfLTE/phyParams.TTI), false(1, round((simParams.coex_superFlength-simParams.coex_endOfLTE)/phyParams.TTI))];
        mask = repmat(mask_lte, 1, mask_length/length(mask_lte));
        subchannelFree = subchannelFree(:, mask, :);
        sinrManagement.cbrCV2X(vehiclesToConsider) = sum(~subchannelFree, [1, 2]) ./ numel(subchannelFree(:,:,1));
    end
    
    % Dynamic setting of PDelta
    if strcmp(phyParams.duplexCV2X,'FD') && simParams.FDalgorithm~=0 && simParams.dynamicPDelta==1
        for indexV = 1:length(vehiclesToConsider)
            iV = vehiclesToConsider(indexV);
            if (0<=sinrManagement.cbrCV2X(iV)) && (sinrManagement.cbrCV2X(iV)<0.5)
                stationManagement.PDelta(iV) = 1.1;   % 0.41dB
            elseif (0.5<=sinrManagement.cbrCV2X(iV)) && (sinrManagement.cbrCV2X(iV)< 0.6)
                stationManagement.PDelta(iV) = 1.25;     % 0.97dB
            elseif (0.6<=sinrManagement.cbrCV2X(iV)) && (sinrManagement.cbrCV2X(iV)< 0.7)
                stationManagement.PDelta(iV) = 1.5;     % 1.76dB
            elseif (0.7<=sinrManagement.cbrCV2X(iV)) && (sinrManagement.cbrCV2X(iV)< 0.8)
                stationManagement.PDelta(iV) = 2;     % 3dB
            elseif (0.8<=sinrManagement.cbrCV2X(iV)) && (sinrManagement.cbrCV2X(iV)< 0.85)
                stationManagement.PDelta(iV) = 4;     % 6dB (was 4.78dB for FDalg2)
            elseif (0.85<=sinrManagement.cbrCV2X(iV)) && (sinrManagement.cbrCV2X(iV)< 0.9)
                stationManagement.PDelta(iV) = 8;     % 9dB (was 6dB for FDalg2)
            elseif (0.9<=sinrManagement.cbrCV2X(iV)) && (sinrManagement.cbrCV2X(iV)< 0.95)
                stationManagement.PDelta(iV) = 16;    % 12dB (was 9dB for FDalg2)      
            elseif (0.95<=sinrManagement.cbrCV2X(iV)) && (sinrManagement.cbrCV2X(iV)<= 1)
                stationManagement.PDelta(iV) = 32;    % 15dB (was 12dB for FDalg2)
            else
                error("error in CBR calculation")
            end
        end
    end
end

if simParams.technology == constants.TECH_COEX_STD_INTERF
    % calculation of the CBR_LTE for the dynamic slot duration

    % update the cbr
    if ~isempty(vehiclesToConsider) && timeManagement.elapsedTime_TTIs > nAllocationPeriodsCBR * appParams.NbeaconsT
        if simParams.coexMethod>1 && simParams.coex_slotManagement==2 && simParams.coex_printTechPercentage
            filenameTechP = sprintf('%s/coex_TechPercStatistic_%.0f.xls',outParams.outputFolder,outParams.simID);
            fpTechP = fopen(filenameTechP,'at');
            
            % the file could not be opened sometimes
            if fpTechP == -1
                reOpenTimes = 10;
                while fpTechP == -1 && reOpenTimes > 0
                    pause(5);
                    fpTechP = fopen(filenameTechP,'at');
                    reOpenTimes = reOpenTimes - 1;
                end
                if fpTechP == -1
                    error('Could not open file:\n%s', filenameTechP);
                end
            end
        end        
        % same timing as std CBR
        for iV = vehiclesToConsider'

            %% VARIANTS for CBR_LTE
            % 1: number of received SCIs over number of beacon resources
            %    this is valid only if all packets use the same number of
            %    subchannels - cannot be the one in the standards
            if simParams.coex_cbrLteVariant==1
                sinrManagement.cbrCV2X_coexLTEonly(iV) = sum(sinrManagement.coex_correctSCIhistory(:,iV))/appParams.Nbeacons;

            % 2: number of received SCIs over number of subchannels
            %    expected to understimate the use of the channel (saturates
            %    before 100%)
            elseif simParams.coex_cbrLteVariant==2
                sinrManagement.cbrCV2X_coexLTEonly(iV) = sum(sinrManagement.coex_correctSCIhistory(:,iV))/(appParams.NbeaconsT * phyParams.NsubchannelsFrequency);

            % 3: CBR_LTE = sum( SCI*subchannels_per_SCI ) / (num_subchannels*num_subframes)
            %    NOTE: with this definition and overlapping packets, it migth
            %    happen that the CBR_LTE goes above 100%
            elseif simParams.coex_cbrLteVariant==3
                sinrManagement.cbrCV2X_coexLTEonly(iV) = sum(sinrManagement.coex_correctSCIhistory(:,iV)*phyParams.NsubchannelsBeacon)/(appParams.NbeaconsT * phyParams.NsubchannelsFrequency);

            % 4: CBR_LTE = sum( subchannels_used ) / (num_subchannels*num_subframes)
            elseif simParams.coex_cbrLteVariant==4
                if ~phyParams.BRoverlapAllowed
                     sinrManagement.cbrCV2X_coexLTEonly(iV) = sum(sinrManagement.coex_correctSCIhistory(:,iV)*phyParams.NsubchannelsBeacon) / ...
                         (appParams.NbeaconsT * phyParams.NsubchannelsFrequency);
                else
                    % I store in BRoccupied the evaluation of the power sensed in
                    % each beacon resource
                    % The vector length is nBeaconsF x nBeaconsT x nAllocationPeriodsCBR            
                    BRfree = ~sinrManagement.coex_correctSCIhistory(:,iV)';
                    % Then I need to convert from beacon resources to subchannels
                    % A matrix is used of size "nSubchannels" x "nBeaconsT x nAllocationPeriodsCBR"
                    subchannelFree = true(phyParams.NsubchannelsFrequency,length(BRfree)/appParams.NbeaconsF);
                    for i=1:appParams.NbeaconsF
                        subchannelFree(i:(i+phyParams.NsubchannelsBeacon-1),:) = subchannelFree(i:(i+phyParams.NsubchannelsBeacon-1),:) & repmat(BRfree(i:appParams.NbeaconsF:end),phyParams.NsubchannelsBeacon,1);
                    end    
                    sinrManagement.cbrCV2X_coexLTEonly(iV) = sum(~subchannelFree, "all") ...
                        / (appParams.NbeaconsT * phyParams.NsubchannelsFrequency);                    
                end
            elseif simParams.coex_cbrLteVariant==5
                BRfree = ~sinrManagement.coex_correctSCIhistory(:,iV)';
                TTIFree = true(1,length(BRfree)/appParams.NbeaconsF);
                for i=1:appParams.NbeaconsF
                    TTIFree = TTIFree & BRfree(i:appParams.NbeaconsF:end);
                end    
                sinrManagement.cbrCV2X_coexLTEonly(iV) = sum(~TTIFree, "all") / appParams.NbeaconsT;  
            else
                error('Variant of CBR_LTE not implemented');
            end
            
            if ~ismember(simParams.coexMethod, [constants.COEX_METHOD_NON, constants.COEX_METHOD_A])  
                % Update of the parameter "simParams.coex_NtsLTE"
                if simParams.coex_cbrTotVariant==1
                    Tech_percentage = sinrManagement.cbrCV2X_coexLTEonly(iV)./sinrManagement.cbrCV2X(iV);
                elseif simParams.coex_cbrTotVariant==2
                    Tech_percentage = sinrManagement.cbrCV2X_coexLTEonly(iV)./(sinrManagement.cbrCV2X_coexLTEonly(iV)+sinrManagement.cbrCV2X_coex11ponly(iV));
                elseif simParams.coex_cbrTotVariant==9
                    % todo:
                    error("Following code need to be checked in case of NR-V2X");
                    BRfree = reshape(sensingMatrix(1:nAllocationPeriodsCBR,:,iV) <= threshCBR_perMHz, 1, []);
                    TTIFree = true(1,length(BRfree)/appParams.NbeaconsF);
                    for i=1:appParams.NbeaconsF
                        TTIFree(1,:) = subchannelFree(1,:) & BRfree(i:appParams.NbeaconsF:end);
                    end    
                    totLTEbusy = 0;
                    tot11pBusy = 0;
                    for j=1:(nAllocationPeriodsCBR * appParams.NbeaconsT/simParams.coex_superframeTTI)
                        totLTEbusy = totLTEbusy + sum(~TTIFree((j-1)*simParams.coex_superframeSF+1:(j-1)*simParams.coex_superframeSF+sinrManagement.coex_NtotSubframeLTE(iV)));
                        tot11pBusy = tot11pBusy + sum(~TTIFree((j-1)*simParams.coex_superframeSF+sinrManagement.coex_NtotSubframeLTE(iV)+1:j*simParams.coex_superframeSF));
                    end
                    sinrManagement.cbrCV2X_coexLTEonly(iV) = totLTEbusy ...
                        / (nAllocationPeriodsCBR * appParams.NbeaconsT * (sinrManagement.coex_NtotSubframeLTE(iV)/simParams.coex_superframeSF));
                    sinrManagement.cbrCV2X_coex11ponly(iV) = tot11pBusy ...
                        / (nAllocationPeriodsCBR * appParams.NbeaconsT * (1-sinrManagement.coex_NtotSubframeLTE(iV)/simParams.coex_superframeSF));
                    Tech_percentage = sum(stationManagement.vehicleState==100)/length(stationManagement.vehicleState);
                    %sinrManagement.cbrCV2X_coexLTEonly(iV)./(sinrManagement.cbrCV2X_coexLTEonly(iV)+sinrManagement.cbrCV2X_coex11ponly(iV));
                else
                    error('simParams.coex_cbrTotVariant=%d not accepted',simParams.coex_cbrTotVariant);
                end
                % The new number of subframes that can be used by node iV is
                % calculated, same as NR-V2X
                if simParams.coex_slotManagement == constants.COEX_SLOT_DYNAMIC
                    nSubframes = round(Tech_percentage * simParams.coex_superframeSF);
                    sinrManagement.coex_NtotSubframeLTE(iV) = max(5,min(nSubframes,simParams.coex_superframeSF-5));
                    sinrManagement.coex_NtotTTILTE(iV) = sinrManagement.coex_NtotSubframeLTE(iV) * (phyParams.Tsf / phyParams.TTI);
                end
                if ~ismember(simParams.coexMethod, [constants.COEX_METHOD_NON, constants.COEX_METHOD_A]) &&...
                        simParams.coex_slotManagement==constants.COEX_SLOT_DYNAMIC && simParams.coex_printTechPercentage
                    if simParams.coex_cbrTotVariant == 1
                        fprintf(fpTechP,'%f\t%d\t%f\t%f\t%f\t%d\n',timeManagement.timeNow,iV,sinrManagement.cbrCV2X_coexLTEonly(iV),sinrManagement.cbrCV2X(iV),Tech_percentage,sinrManagement.coex_NtotSubframeLTE(iV));
                    else
                        fprintf(fpTechP,'%f\t%d\t%f\t%f\t%f\t%d\n',timeManagement.timeNow,iV,sinrManagement.cbrCV2X_coexLTEonly(iV),(sinrManagement.cbrCV2X_coexLTEonly(iV)+sinrManagement.cbrCV2X_coex11ponly(iV)),Tech_percentage,sinrManagement.coex_NtotSubframeLTE(iV));
                    end
                end
            end
        end

        if simParams.coexMethod>1 && simParams.coex_slotManagement==2 && simParams.coex_printTechPercentage
            fclose(fpTechP);
        end        
    end
    coex_cbrLTEonlyValues = sinrManagement.cbrLTE_coexLTEonly(vehiclesToConsider);
else
    coex_cbrLTEonlyValues = sinrManagement.cbrCV2X(vehiclesToConsider);
end

CBRvalues = sinrManagement.cbrCV2X(vehiclesToConsider);

if ~isempty(CBRvalues) && (min(CBRvalues)<-1e-6 || max(CBRvalues)>1+1e-6)
    error('Some CBRvalue is lower than 0 or higher than 1...');
end

if simParams.dcc_active
    % ETSI TS 103 574 V1.1.1, page 8, Table 1 ( CAM is PPPP 5 )                
    %CRlimit = (1*(CBRvalues<=0.3*phyParams.cv2xCbrFactor) + 0.03*(CBRvalues>0.3*phyParams.cv2xCbrFactor & CBRvalues<=0.65*phyParams.cv2xCbrFactor) + 0.006*(CBRvalues>0.65*phyParams.cv2xCbrFactor & CBRvalues<=0.8*phyParams.cv2xCbrFactor) + 0.003*(CBRvalues>0.8*phyParams.cv2xCbrFactor))*phyParams.cv2xCbrFactor;
    CRlimit = (1*(CBRvalues<=0.3) + 0.03*(CBRvalues>0.3 & CBRvalues<=0.65) + 0.006*(CBRvalues>0.65 & CBRvalues<=0.8) + 0.003*(CBRvalues>0.8))*phyParams.cv2xCbrFactor;
    if phyParams.cv2xNumberOfReplicasMax>1
        stationManagement.cv2xNumberOfReplicas(vehiclesToConsider) = phyParams.cv2xNumberOfReplicasMax;            
        for i=1:length(vehiclesToConsider)
            % (Vittorio 5.5.3)
            % CR = stationManagement.cv2xNumberOfReplicas(vehiclesToConsider(i)) * (phyParams.NsubchannelsBeacon)/(phyParams.NsubchannelsFrequency) * phyParams.Tsf / timeManagement.generationInterval(vehiclesToConsider(i));
            CR = stationManagement.cv2xNumberOfReplicas(vehiclesToConsider(i)) * (phyParams.NsubchannelsBeacon)/(phyParams.NsubchannelsFrequency) * phyParams.TTI / timeManagement.generationIntervalDeterministicPart(vehiclesToConsider(i));
            %fprintf('%f\n',CR);
            while (CR > CRlimit(i)) && (stationManagement.cv2xNumberOfReplicas(vehiclesToConsider(i))>1)
                stationManagement.cv2xNumberOfReplicas(vehiclesToConsider(i)) = stationManagement.cv2xNumberOfReplicas(vehiclesToConsider(i))-1;
                stationManagement.dccLteTriggeredHarq(stationManagement.vehicleChannel(vehiclesToConsider(i))) = true;
            end
            % If the number of retransmissions is reduced, there might be
            % need to remove current packets from the queue
            if stationManagement.pckBuffer(vehiclesToConsider(i))>0 && ... 
                stationManagement.pckNextAttempt(vehiclesToConsider(i)) > stationManagement.cv2xNumberOfReplicas(vehiclesToConsider(i))
                [stationManagement,outputValues] = bufferOverflowLTE(vehiclesToConsider(i),timeManagement,positionManagement,stationManagement,phyParams,appParams,outputValues,outParams);
            end
        end
    end
    %(Vittorio 5.5.3)
    % timeManagement.dcc_minInterval(vehiclesToConsider) = stationManagement.cv2xNumberOfReplicas(vehiclesToConsider) .* (phyParams.NsubchannelsBeacon)/(phyParams.NsubchannelsFrequency) * phyParams.Tsf ./ CRlimit;          
	timeManagement.dcc_minInterval(vehiclesToConsider) = stationManagement.cv2xNumberOfReplicas(vehiclesToConsider) .* (phyParams.NsubchannelsBeacon)/(phyParams.NsubchannelsFrequency) * phyParams.TTI ./ CRlimit;          
    % move dcc trigger to mainV2X.m, because the random part of generation
    % interval would change value if they appear at different places
    % if timeManagement.dcc_minInterval(vehiclesToConsider)>timeManagement.generationIntervalDeterministicPart(vehiclesToConsider)
    %     stationManagement.dccLteTriggered(stationManagement.vehicleChannel(vehiclesToConsider)) = true;
    % end
end
