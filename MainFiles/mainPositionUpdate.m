function [appParams,simParams,phyParams,outParams,simValues,outputValues,timeManagement,positionManagement,sinrManagement,stationManagement] = ...
    mainPositionUpdate(appParams,simParams,phyParams,outParams,simValues,outputValues,timeManagement,positionManagement,sinrManagement,stationManagement)
% the position of all vehicles is updated

if simParams.typeOfScenario ~= constants.SCENARIO_TRACE % Not traffic trace
    % Call function to update vehicles positions
    [indexNewVehicles,indexOldVehicles,indexOldVehiclesToOld,stationManagement.activeIDsExit,positionManagement] = updatePosition(timeManagement.timeNow,stationManagement.activeIDs,simParams.positionTimeResolution,positionManagement,simValues,outParams,simParams);
else
    % Store IDs of vehicles at the previous beacon period and update positions
    [positionManagement.XvehicleReal,positionManagement.YvehicleReal,stationManagement.activeIDs,indexNewVehicles,indexOldVehicles,indexOldVehiclesToOld,stationManagement.activeIDsExit,positionManagement.v,positionManagement.direction] = updatePositionFile( ...
        round(timeManagement.timeNextPosUpdate,2), ...
        simValues.dataTrace,stationManagement.activeIDs, ...
        positionManagement.XvehicleReal,positionManagement.YvehicleReal, ...
        round(timeManagement.timeNextPosUpdate,2)-simParams.positionTimeResolution,simValues,outParams);
    %% ONLY LTE
    if sum(stationManagement.vehicleState(stationManagement.activeIDs)==100)>0
    %if simParams.technology ~= 2 % not only 11p
        % Update stationManagement.BRid vector (variable number of vehicles in the scenario)
        [stationManagement.BRid] = updateBRidFile(stationManagement.BRid,stationManagement.activeIDs,indexNewVehicles);
    end
end

% Vectors IDvehicleLTE and IDvehicle11p are updated
stationManagement.activeIDsCV2X = stationManagement.activeIDs.*(stationManagement.vehicleState(stationManagement.activeIDs)==100);
stationManagement.activeIDsCV2X = stationManagement.activeIDsCV2X(stationManagement.activeIDsCV2X>0);
stationManagement.activeIDs11p = stationManagement.activeIDs.*(stationManagement.vehicleState(stationManagement.activeIDs)~=100);
stationManagement.activeIDs11p = stationManagement.activeIDs11p(stationManagement.activeIDs11p>0);
[~, stationManagement.indexInActiveIDs_ofLTEnodes] = ismember(stationManagement.activeIDsCV2X, stationManagement.activeIDs);
[~, stationManagement.indexInActiveIDs_of11pnodes] = ismember(stationManagement.activeIDs11p, stationManagement.activeIDs);


% % For possible DEBUG
% figure(300)
% plot(timeManagement.timeNextPosUpdate*100*ones(1,length(positionManagement.XvehicleReal)),positionManagement.XvehicleReal,'*');
% hold on

% Update variables for resource allocation in LTE-V2V
%if simParams.technology ~= 2 % not only 11p
if sum(stationManagement.vehicleState(stationManagement.activeIDs)==100)>0
    
    % if simParams.BRAlgorithm==18 && timeManagement.timeNow > phyParams.Tsf (Vittorio 5.5.3)
    if simParams.BRAlgorithm==constants.REASSIGN_BR_STD_MODE_4 && timeManagement.timeNow > phyParams.TTI
        % First random allocation 
        if ~isempty(indexNewVehicles)
            %[stationManagement.BRid,~] = BRreassignmentRandom(simValues.IDvehicle,stationManagement.BRid,simParams,sinrManagement,appParams);
            [stationManagement.BRid(stationManagement.activeIDs(indexNewVehicles),1),~] = BRreassignmentRandom(simParams.T1autonomousModeTTIs,simParams.T2autonomousModeTTIs,stationManagement.activeIDs(indexNewVehicles),simParams,timeManagement,sinrManagement,stationManagement,phyParams,appParams);
            if simParams.technology==constants.TECH_COEX_STD_INTERF && ismember(simParams.coexMethod, [constants.COEX_METHOD_A, constants.COEX_METHOD_B, constants.COEX_METHOD_F])
                timeManagement.coex_timeNextSuperframe(stationManagement.activeIDs(indexNewVehicles)) = timeManagement.timeNow + ...
                    (simParams.coex_knownEndOfLTE(stationManagement.activeIDs(indexNewVehicles)) + simParams.coex_guardTimeAfter) * ones(length(stationManagement.activeIDs(indexNewVehicles)),1);
                timeManagement.coex_timeNextSuperframe(stationManagement.activeIDs(indexNewVehicles)) = timeManagement.coex_timeNextSuperframe(stationManagement.activeIDs(indexNewVehicles)) +...
                    ( rand(length(stationManagement.activeIDs(indexNewVehicles)),1) * (2*simParams.coexA_desynchError) - simParams.coexA_desynchError);
            end
        end
        % Update stationManagement.resReselectionCounterCV2X for vehicles EXITING the scenario
        stationManagement.resReselectionCounterCV2X(stationManagement.activeIDsExit) = Inf;
        
        % Update stationManagement.resReselectionCounterCV2X for vehicles ENTERING the scenario
        % a) LTE vehicles that enter or are blocked start with a counter set to 0
        % b) 11p vehicles are set to Inf
        indexNewVehicleInAll = zeros(simValues.maxID,1);
        indexNewVehicleInAll(stationManagement.activeIDs(indexNewVehicles)) = deal(1);
        stationManagement.resReselectionCounterCV2X(indexNewVehicleInAll & (stationManagement.vehicleState==constants.V_STATE_LTE_TXRX)) = 0;
        stationManagement.resReselectionCounterCV2X(indexNewVehicleInAll & (stationManagement.vehicleState~=constants.V_STATE_LTE_TXRX)) = Inf;
        
        % Reset stationManagement.errorSCImatrixLTE for new computation of correctly received SCIs
        %stationManagement.correctSCImatrixCV2X = zeros(length(stationManagement.activeIDsCV2X),length(stationManagement.activeIDsCV2X)-1);
    end
    
    % Add LTE positioning delay (if selected)
    [simValues.XvehicleEstimated,simValues.YvehicleEstimated,PosUpdateIndex] = addPosDelay(simValues.XvehicleEstimated,simValues.YvehicleEstimated,positionManagement.XvehicleReal,positionManagement.YvehicleReal,stationManagement.activeIDs,indexNewVehicles,indexOldVehicles,indexOldVehiclesToOld,positionManagement.posUpdateAllVehicles,simParams.positionTimeResolution);

    % Add LTE positioning error (if selected)
    % (Xvehicle, Yvehicle): fictitious vehicles' position seen by the eNB
    [simValues.XvehicleEstimated(PosUpdateIndex),simValues.YvehicleEstimated(PosUpdateIndex)] = addPosError(positionManagement.XvehicleReal(PosUpdateIndex),positionManagement.YvehicleReal(PosUpdateIndex),simParams.sigmaPosError);
end

% Call function to compute the distances
[positionManagement,stationManagement] = computeDistance (simParams,simValues,stationManagement,positionManagement);

% Call function to update positionManagement.distance matrix where D(i,j) is the
% change in positionManagement.distance of link i to j from time n-1 to time n and used
% for updating Shadowing matrix
[dUpdate,sinrManagement.Shadowing_dB,positionManagement.distanceRealOld] = updateDistanceChangeForShadowing(positionManagement.distanceReal,positionManagement.distanceRealOld,indexOldVehicles,indexOldVehiclesToOld,sinrManagement.Shadowing_dB,phyParams.stdDevShadowLOS_dB);

% Calculation of channel and then received power
[sinrManagement,simValues.Xmap,simValues.Ymap,phyParams.LOS] = computeChannelGain(sinrManagement,stationManagement,positionManagement,phyParams,simParams,dUpdate);

% Update of the neighbors
[positionManagement,stationManagement] = computeNeighbors (stationManagement,positionManagement,phyParams);

% Floor coordinates for PRRmap creation (if enabled)
if simParams.typeOfScenario==constants.SCENARIO_TRACE && outParams.printPRRmap % only traffic trace 
    simValues.XmapFloor = floor(simValues.Xmap);
    simValues.YmapFloor = floor(simValues.Ymap);
end

% Call function to calculate effective neighbors (if enabled)
if simParams.neighborsSelection
    %% TODO - needs update
    error('Significant neighbors not updated in v5');
%     if simParams.technology ~= 2 % not only 11p
%         % LTE
%         [stationManagement.awarenessIDLTE,stationManagement.neighborsIDLTE,positionManagement.XvehicleRealOld,positionManagement.YvehicleRealOld,positionManagement.angleOld] = computeSignificantNeighbors(stationManagement.activeIDs,positionManagement.XvehicleReal,positionManagement.YvehicleReal,positionManagement.XvehicleRealOld,positionManagement.YvehicleRealOld,stationManagement.neighborsIDLTE,indexNewVehicles,indexOldVehicles,indexOldVehiclesToOld,positionManagement.angleOld,simParams.Mvicinity,phyParams.RawLTE,phyParams.RawMaxCV2X,stationManagement.neighborsDistance);
%     end
%     if simParams.technology ~= 1 % not only LTE
%         % 11p
%         [stationManagement.awarenessID11p,stationManagement.neighborsID11p,positionManagement.XvehicleRealOld,positionManagement.YvehicleRealOld,positionManagement.angleOld] = computeSignificantNeighbors(stationManagement.activeIDs,positionManagement.XvehicleReal,positionManagement.YvehicleReal,positionManagement.XvehicleRealOld,positionManagement.YvehicleRealOld,stationManagement.neighborsID11p,indexNewVehicles,indexOldVehicles,indexOldVehiclesToOld,positionManagement.angleOld,simParams.Mvicinity,phyParams.Raw11p,phyParams.RawMax11p,stationManagement.neighborsDistance);
%     end
end

% Call function to compute hidden or non-hidden nodes (if enabled)
if outParams.printHiddenNodeProb
    %% TODO - needs update
    error('printHiddenNodeProb not updated in v5');
    %[outputValues.hiddenNodeSumProb,outputValues.hiddenNodeProbEvents] = computeHiddenNodeProb(stationManagement.activeIDs,positionManagement.distanceReal,sinrManagement.RXpower,phyParams.gammaMin,phyParams.PnRB,outParams.PthRB,outputValues.hiddenNodeSumProb,outputValues.hiddenNodeProbEvents);
end

% Number of vehicles in the scenario
outputValues.Nvehicles = length(stationManagement.activeIDs);
outputValues.NvehiclesTOT = outputValues.NvehiclesTOT + outputValues.Nvehicles;
outputValues.NvehiclesLTE = outputValues.NvehiclesLTE + length(stationManagement.activeIDsCV2X);
outputValues.Nvehicles11p = outputValues.Nvehicles11p + length(stationManagement.activeIDs11p);

% Number of neighbors
[outputValues,~,NneighborsRawLTE,NneighborsRaw11p] = updateAverageNeighbors(simParams,stationManagement,outputValues,phyParams);

% Print number of neighbors per vehicle to file (if enabled)
if outParams.printNeighbors
    printNeighborsToFile(timeManagement.timeNow,positionManagement,outputValues.Nvehicles,NneighborsRawLTE/length(stationManagement.activeIDsCV2X),NneighborsRaw11p/length(stationManagement.activeIDs11p),outParams,phyParams);
end

% Prepare matrix for update delay computation (if enabled)
if outParams.printUpdateDelay
    % Reset update time of vehicles that are outside the scenario
    allIDOut = setdiff(1:simValues.maxID,stationManagement.activeIDs);
    simValues.updateTimeMatrix11p(allIDOut,:,:) = -1;
    simValues.updateTimeMatrix11p(:,allIDOut,:) = -1;
    simValues.updateTimeMatrixCV2X(allIDOut,:,:) = -1;
    simValues.updateTimeMatrixCV2X(:,allIDOut,:) = -1;
end

% Prepare matrix for update delay computation (if enabled)
if outParams.printDataAge
    % Reset update time of vehicles that are outside the scenario
    allIDOut = setdiff(1:simValues.maxID,stationManagement.activeIDs);
    simValues.dataAgeTimestampMatrix11p(allIDOut,:,:) = -1;
    simValues.dataAgeTimestampMatrix11p(:,allIDOut,:) = -1;
    simValues.dataAgeTimestampMatrixCV2X(allIDOut,:,:) = -1;
    simValues.dataAgeTimestampMatrixCV2X(:,allIDOut,:) = -1;
end

% Compute wireless blind spot probability (if enabled - update delay is required)
% The WBSP is calculated at every position update
if outParams.printUpdateDelay && outParams.printWirelessBlindSpotProb
%     %error('Not updated in v. 5.X');
%     %% TODO with coexistence
%     if simParams.technology~=1 && simParams.technology~=2
%         error('Not implemented');
%     end
%     if simParams.technology==2 || elapsedTime_subframes>appParams.NbeaconsT
%         if simParams.technology==1
%             outputValues.wirelessBlindSpotCounter = countWirelessBlindSpotProb(simValues.updateTimeMatrixCV2X,outputValues.wirelessBlindSpotCounter,timeManagement.timeNow);
%         else
%             outputValues.wirelessBlindSpotCounter = countWirelessBlindSpotProb(simValues.updateTimeMatrix11p,outputValues.wirelessBlindSpotCounter,timeManagement.timeNow);
%         end
%     end       
    if ~isempty(stationManagement.activeIDsCV2X)
        for iRaw = 1:length(phyParams.Raw)
            valuesEnteredInRange = outputValues.enteredInRangeLTE(:,:,iRaw);
            valuesEnteredInRange(stationManagement.activeIDsCV2X,stationManagement.activeIDsCV2X) = (valuesEnteredInRange(stationManagement.activeIDsCV2X,stationManagement.activeIDsCV2X)<0 & positionManagement.distanceReal(stationManagement.indexInActiveIDs_ofLTEnodes,stationManagement.indexInActiveIDs_ofLTEnodes)<=phyParams.Raw(iRaw))*(1+timeManagement.timeNow)-1;
            valuesEnteredInRange( positionManagement.distanceReal > phyParams.Raw(iRaw) ) = -1;
            outputValues.enteredInRangeLTE(:,:,iRaw) = valuesEnteredInRange - (diag(diag(valuesEnteredInRange+1)));
        end
    	outputValues.wirelessBlindSpotCounterCV2X = countWirelessBlindSpotProb(simValues.updateTimeMatrixCV2X,outputValues.enteredInRangeLTE,outputValues.wirelessBlindSpotCounterCV2X,timeManagement.timeNow,phyParams);
    end
    if ~isempty(stationManagement.activeIDs11p)
        for iRaw = 1:length(phyParams.Raw)
            valuesEnteredInRange = outputValues.enteredInRange11p(:,:,iRaw);
            valuesEnteredInRange(stationManagement.activeIDs11p,stationManagement.activeIDs11p) = (valuesEnteredInRange(stationManagement.activeIDs11p,stationManagement.activeIDs11p)<0 & positionManagement.distanceReal(stationManagement.indexInActiveIDs_of11pnodes,stationManagement.indexInActiveIDs_of11pnodes)<=phyParams.Raw(iRaw))*(1+timeManagement.timeNow)-1;
            valuesEnteredInRange( positionManagement.distanceReal > phyParams.Raw(iRaw) ) = -1;
            outputValues.enteredInRange11p(:,:,iRaw) = valuesEnteredInRange - (diag(diag(valuesEnteredInRange+1)));
        end
    	outputValues.wirelessBlindSpotCounter11p = countWirelessBlindSpotProb(simValues.updateTimeMatrix11p,outputValues.enteredInRange11p,outputValues.wirelessBlindSpotCounter11p,timeManagement.timeNow,phyParams);
    end
end

% Update of parameters related to transmissions in IEEE 802.11p to cope
% with vehicles exiting the scenario
%if simParams.technology ~= 1 % not only LTE
if sum(stationManagement.vehicleState(stationManagement.activeIDs)~=100)>0    
    
    timeManagement.timeNextTxRx11p(stationManagement.activeIDsExit) = Inf;
    sinrManagement.idFromWhichRx11p(stationManagement.activeIDsExit) = stationManagement.activeIDsExit;
    sinrManagement.instantThisSINRavStarted11p(stationManagement.activeIDsExit) = Inf;
    stationManagement.vehicleState(stationManagement.activeIDsExit(stationManagement.vehicleState(stationManagement.activeIDsExit)~=100)) =  1;
    
    % The average SINR of all vehicles is then updated
    sinrManagement = updateSINR11p(timeManagement,sinrManagement,stationManagement,phyParams);

    % The nodes that may stop receiving must be checked
    [timeManagement,stationManagement,sinrManagement,outputValues] = checkVehiclesStopReceiving11p(timeManagement,stationManagement,sinrManagement,simParams,phyParams,outParams,outputValues);

    % The present overall/useful power received and the instant of calculation are updated
    % The power received must be calculated after
    % 'checkVehiclesStopReceiving11p', to have the correct idFromWhichtransmitting
    [sinrManagement] = updateLastPower11p(timeManagement,stationManagement,sinrManagement,phyParams,simValues);       
end

% Generate time values of new vehicles entering the scenario
timeManagement.timeNextPacket(stationManagement.activeIDs(indexNewVehicles)) = round(timeManagement.timeNow + appParams.allocationPeriod * rand(1,length(indexNewVehicles)), 10);
if appParams.variabilityGenerationInterval == constants.PACKET_GENERATION_ETSI_CAM
    timeManagement.generationIntervalDeterministicPart(stationManagement.activeIDs(indexNewVehicles)) = generationPeriodFromSpeed(positionManagement.v(indexNewVehicles),appParams);
else
    timeManagement.generationIntervalDeterministicPart(stationManagement.activeIDs(indexNewVehicles)) = appParams.generationInterval - appParams.variabilityGenerationInterval/2 + appParams.variabilityGenerationInterval*rand(length(indexNewVehicles),1);
    timeManagement.generationIntervalDeterministicPart(stationManagement.activeIDsCV2X) = appParams.generationInterval;
end
% timeManagement.timeOfResourceAllocationLTE is for possible use in the future
%timeManagement.timeOfResourceAllocationLTE(stationManagement.activeIDs(indexNewVehicles)) = timeManagement.timeNextPacket(stationManagement.activeIDs(indexNewVehicles));
%timeManagement.timeOfResourceAllocationLTE(stationManagement.activeIDs11p) = -1;

% Reset time next packet and tx-rx for vehicles that exit the scenario
timeManagement.timeNextPacket(stationManagement.activeIDsExit) = Inf;

% Reset time next packet and tx-rx for vehicles that exit the scenario
stationManagement.pckBuffer(stationManagement.activeIDsExit) = 0;
stationManagement.pckReceived(:,stationManagement.activeIDsExit) = 0;
sinrManagement.cumulativeSINR(:,stationManagement.activeIDsExit) = 0;
stationManagement.preambleAlreadyDetected(:,stationManagement.activeIDsExit) = 0;
stationManagement.alreadyStartCBR(:,stationManagement.activeIDsExit) = 0;

stationManagement.pckNextAttempt(stationManagement.activeIDsExit) = 1;
stationManagement.pckTxOccurring(stationManagement.activeIDsExit) = 0;

%% CBR settings for the new vehicles
if simParams.cbrActive && (outParams.printCBR || (simParams.technology==constants.TECH_COEX_STD_INTERF && simParams.coexMethod~=constants.COEX_METHOD_NON && simParams.coex_slotManagement==constants.COEX_SLOT_DYNAMIC))
    timeManagement.cbr11p_timeStartMeasInterval(stationManagement.activeIDs(indexNewVehicles)) = timeManagement.timeNow;
    if simParams.technology==constants.TECH_COEX_STD_INTERF && simParams.coexMethod==constants.COEX_METHOD_A    
        timeManagement.cbr11p_timeStartBusy(stationManagement.activeIDs(indexNewVehicles) .* timeManagement.coex_superframeThisIsLTEPart(stationManagement.activeIDs(indexNewVehicles))) = timeManagement.timeNow;
    end
end
