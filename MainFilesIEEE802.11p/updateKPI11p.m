function [simValues,outputValues,sinrManagement,stationManagement] = updateKPI11p(idEvent,indexEvent,timeManagement,stationManagement,positionManagement,sinrManagement,simParams,phyParams,outParams,simValues,outputValues)
% KPIs: correct transmissions and errors are counted

% The message is correctly received if:
% 1) the node is currently receiving
% 2) the node is receiving from idEvent
% 3) the average SINR is above the threshold
% Values are counted within a circle of radius raw
% filename = sprintf('%s/_DebugKPI_%d.xls',outParams.outputFolder,outParams.simID);

indexEventInActiveIDs11p = find(stationManagement.activeIDs11p == idEvent);
activeIDs11p = stationManagement.activeIDs11p;
indexInActiveIDs_of11pnodes = stationManagement.indexInActiveIDs_of11pnodes;


% Note: I need to work with line vectors, otherwise it works differently when
% sinrVector11p is a vector and when sinrVector11p is a scalar
sinrThr = phyParams.LOS(indexInActiveIDs_of11pnodes,indexEvent)'.*phyParams.sinrVector11p_LOS(randi(length(phyParams.sinrVector11p_LOS),1,length(indexInActiveIDs_of11pnodes)))+...
(1-phyParams.LOS(indexInActiveIDs_of11pnodes,indexEvent)').*(phyParams.sinrVector11p_NLOS(randi(length(phyParams.sinrVector11p_NLOS),1,length(indexInActiveIDs_of11pnodes))));

% Update of cumulativeSINR, to account for possible Maximal Ratio Combining
sinrManagement.cumulativeSINR(activeIDs11p, idEvent) =...
    stationManagement.preambleAlreadyDetected(activeIDs11p, idEvent).*(sinrManagement.cumulativeSINR(activeIDs11p, idEvent)+sinrManagement.sinrAverage11p(activeIDs11p));

% preamble not detected condition
totalSINR = sinrManagement.cumulativeSINR(activeIDs11p, idEvent) +...
    (1-stationManagement.preambleAlreadyDetected(activeIDs11p, idEvent)).*sinrManagement.sinrAverage11p(activeIDs11p);

% Rx OK for all of the vehicles
% earlier - from this packet was first transmitted to the last time
% thisTime - during this packet is transmitted this time
% now - including all of the history of this packet
rxOK_earlier = stationManagement.pckReceived(activeIDs11p, idEvent);
rxOK_thisTime = ...
    (stationManagement.vehicleState(activeIDs11p)==constants.V_STATE_11P_RX) & ...
    (sinrManagement.idFromWhichRx11p(activeIDs11p)==idEvent) & ...
    (totalSINR >= sinrThr');
rxOK_now = rxOK_earlier | rxOK_thisTime;

if stationManagement.pckTxOccurring(idEvent) == 1
    notRxOK_earlier = zeros(size(indexInActiveIDs_of11pnodes));
else
    notRxOK_earlier = ~rxOK_earlier;
end
notRxOK_now = ~rxOK_now;

% From version 5.3.1, multiple channels may be present
sameChannel = (stationManagement.vehicleChannel==stationManagement.vehicleChannel(idEvent));

pckType = stationManagement.pckType(idEvent);
iChannel = stationManagement.vehicleChannel(idEvent);

for iPhyRaw = 1:length(phyParams.Raw)
    awarenessID11p = stationManagement.awarenessID11p(indexEventInActiveIDs11p,:,iPhyRaw)';
    
    % Vehicles' ID inside Raw
    IDIn_thisTime = awarenessID11p(awarenessID11p~=0) .* sameChannel(awarenessID11p(awarenessID11p~=0));
    
    % Index of activeIDs11p in the range of Raw:
    % earlier - from this packet was first transmitted to the last time
    % thisTime - during this packet is transmitted this time
    % now - including all of the history of this packet
    indexInRaw_earlier = stationManagement.indexInRaw_earler(activeIDs11p, idEvent, iPhyRaw);
    indexInRaw_thisTime = ismember(activeIDs11p,IDIn_thisTime);
    indexInRaw_now = indexInRaw_thisTime | indexInRaw_earlier;
    
    % Rx OK of "earlier", "this time" and "till now"
    rxOKRaw_earlier = indexInRaw_earlier & stationManagement.pckReceived(activeIDs11p, idEvent);
    rxOKRaw_thisTime = indexInRaw_thisTime & rxOK_thisTime;
    rxOKRaw_now = rxOKRaw_thisTime | rxOKRaw_earlier;
    % Rx OK of "just this time" 
    rxOKRaw_justThisTime = (rxOKRaw_thisTime - rxOKRaw_earlier) == 1;

    % number of neighbors in history
    NneighborsRaw_earlier = nnz(indexInRaw_earlier);
    % number of neighbors now (includes history)
    NneighborsRaw_now = nnz(indexInRaw_now);
    NneighborsRaw_justThisTime = nnz((indexInRaw_thisTime - indexInRaw_earlier)==1);

    NcorrectlyTxBeacons_earlier = nnz(rxOKRaw_earlier);
    NcorrectlyTxBeacons_now = nnz(rxOKRaw_now);
    NcorrectlyTxBeacons_jusTthisTime = nnz(rxOKRaw_justThisTime);
    
    outputValues.NcorrectlyTxBeacons11p(iChannel,pckType,iPhyRaw) =...
        outputValues.NcorrectlyTxBeacons11p(iChannel,pckType,iPhyRaw) -...
        NcorrectlyTxBeacons_earlier +...
        NcorrectlyTxBeacons_now;
    outputValues.NcorrectlyTxBeaconsTOT(iChannel,pckType,iPhyRaw) =...
        outputValues.NcorrectlyTxBeaconsTOT(iChannel,pckType,iPhyRaw) -...
        NcorrectlyTxBeacons_earlier +...
        NcorrectlyTxBeacons_now;

    % Number of errors
    Nerrors_earlier = NneighborsRaw_earlier - NcorrectlyTxBeacons_earlier;
    Nerrors_now = NneighborsRaw_now - NcorrectlyTxBeacons_now;
    
    outputValues.Nerrors11p(iChannel,pckType,iPhyRaw) =...
        outputValues.Nerrors11p(iChannel,pckType,iPhyRaw) -...
        Nerrors_earlier + Nerrors_now;
    outputValues.NerrorsTOT(iChannel,pckType,iPhyRaw) =...
        outputValues.NerrorsTOT(iChannel,pckType,iPhyRaw) -...
        Nerrors_earlier + Nerrors_now;

    % Number of received beacons (correct + errors == neighbors)
    outputValues.NtxBeacons11p(iChannel,pckType,iPhyRaw) =...
        outputValues.NtxBeacons11p(iChannel,pckType,iPhyRaw) -...
        NneighborsRaw_earlier + NneighborsRaw_now;

    outputValues.NtxBeaconsTOT(iChannel,pckType,iPhyRaw) =...
        outputValues.NtxBeaconsTOT(iChannel,pckType,iPhyRaw) -...
        NneighborsRaw_earlier + NneighborsRaw_now;

    % Compute update delay (if enabled)
    if outParams.printUpdateDelay
        % Find maximum delay in updateDelayCounter
        delayMax = length(outputValues.updateDelayCounter11p(1,1,:,1))*outParams.delayResolution;

        % ID of vehicles that are outside the awareness range of vehicle i
        all = (1:simValues.maxID)';
        IDOut = setdiff(all,IDIn_thisTime);
        simValues.updateTimeMatrix11p(idEvent,IDOut,iPhyRaw)=-1;
        for iRaw = 1:length(IDIn_thisTime)
            % If the beacon is currently correctly received by the neighbor
            % inside the awareness range
            if find(activeIDs11p(rxOKRaw_justThisTime)==IDIn_thisTime(iRaw))
                % Store previous timestamp
                previousTimeStamp = simValues.updateTimeMatrix11p(idEvent,IDIn_thisTime(iRaw),iPhyRaw);
                % If there was a previous timestamp
                if previousTimeStamp>0
                    % Compute update delay
                    updateDelay = timeManagement.timeNow - previousTimeStamp;
                    if updateDelay>=delayMax
                        % Increment last counter
                        outputValues.updateDelayCounter11p(iChannel,pckType,end,iPhyRaw) = outputValues.updateDelayCounter11p(iChannel,pckType,end,iPhyRaw) + 1;
                    else
                        % Increment counter corresponding to the current delay
                        outputValues.updateDelayCounter11p(iChannel,pckType,ceil(updateDelay/outParams.delayResolution),iPhyRaw) = ...
                            outputValues.updateDelayCounter11p(iChannel,pckType,ceil(updateDelay/outParams.delayResolution),iPhyRaw) + 1;
                    end
                end
            end
        end
        % Update updateTimeMatrix with timeNow
        simValues.updateTimeMatrix11p(idEvent,activeIDs11p(rxOKRaw_justThisTime),iPhyRaw) = timeManagement.timeNow;
    end

    % Compute data age (if enabled)
    if outParams.printDataAge
        % Find maximum delay in updateDelayCounter
        delayMax = length(outputValues.dataAgeCounter11p(1,1,:,1))*outParams.delayResolution;

        % ID of vehicles that are outside the awareness range of vehicle i
        all = (1:length(simValues.dataAgeTimestampMatrix11p(:,1,iPhyRaw)))';
        IDOut = setdiff(all,IDIn_thisTime);
        simValues.dataAgeTimestampMatrix11p(idEvent,IDOut,iPhyRaw)=-1;
        for iRaw = 1:length(IDIn_thisTime)
            % If the beacon is currently correctly received by the neighbor
            % inside the awareness range
            if find(activeIDs11p(rxOKRaw_justThisTime)==IDIn_thisTime(iRaw))
                % Store previous timestamp
                previousTimeStamp = simValues.dataAgeTimestampMatrix11p(idEvent,IDIn_thisTime(iRaw),iPhyRaw);
                % If there was a previous timestamp
                if previousTimeStamp>0
                    % Compute update delay
                    dataAge = timeManagement.timeNow - previousTimeStamp;
                    if dataAge>=delayMax
                        % Increment last counter
                        outputValues.dataAgeCounter11p(iChannel,pckType,end,iPhyRaw) = outputValues.dataAgeCounter11p(iChannel,pckType,end,iPhyRaw) + 1;
                    else
                        % Increment counter corresponding to the current delay
                        outputValues.dataAgeCounter11p(iChannel,pckType,ceil(dataAge/outParams.delayResolution),iPhyRaw) = ...
                            outputValues.dataAgeCounter11p(iChannel,pckType,ceil(dataAge/outParams.delayResolution),iPhyRaw) + 1;
                    end
                end
            end
        end
        % Update updateTimeMatrix with timeNow
        simValues.dataAgeTimestampMatrix11p(idEvent,activeIDs11p(rxOKRaw_justThisTime),iPhyRaw) = timeManagement.timeLastPacket(idEvent);
    end

    % Compute packet delay (if enabled)
    if outParams.printPacketDelay
        % Find maximum delay in updateDelayCounter
        delayMax = length(outputValues.packetDelayCounter11p(1,1,:,1))*outParams.delayResolution;
        % Compute packet delay
        packetDelay = timeManagement.timeNow - timeManagement.timeLastPacket(idEvent);
        if packetDelay>=delayMax
            % Increment last counter
            outputValues.packetDelayCounter11p(iChannel,pckType,end,iPhyRaw) = outputValues.packetDelayCounter11p(iChannel,pckType,end,iPhyRaw) + NcorrectlyTxBeacons_jusTthisTime;
        else
            % Increment counter corresponding to the current delay
            outputValues.packetDelayCounter11p(iChannel,pckType,ceil(packetDelay/outParams.delayResolution),iPhyRaw) = ...
                outputValues.packetDelayCounter11p(iChannel,pckType,ceil(packetDelay/outParams.delayResolution),iPhyRaw) + NcorrectlyTxBeacons_jusTthisTime;
        end
    end

    % Update matrices needed for PRRmap creation (if enabled)
    if simParams.typeOfScenario==2 && outParams.printPRRmap
        indexRxOkRaw = find(rxOKRaw_justThisTime);
        % Count correctly received beacons
        for iRaw = 1:length(indexRxOkRaw)
            simValues.correctlyReceivedMap11p(simValues.YmapFloor(indexRxOkRaw(iRaw)),simValues.XmapFloor(indexRxOkRaw(iRaw)),iPhyRaw) = ...
                simValues.correctlyReceivedMap11p(simValues.YmapFloor(indexRxOkRaw(iRaw)),simValues.XmapFloor(indexRxOkRaw(iRaw)),iPhyRaw) + 1;
        end
        % Count neighbors of idEvent
        simValues.neighborsMap11p(simValues.YmapFloor(indexEvent),simValues.XmapFloor(indexEvent),iPhyRaw) = ...
            simValues.neighborsMap11p(simValues.YmapFloor(indexEvent),simValues.XmapFloor(indexEvent),iPhyRaw) + NneighborsRaw_justThisTime;
    end

    % update index of activeIDs11p in the range of Raw earlier (during one packet
    % and it's retransmission)
    stationManagement.indexInRaw_earler(activeIDs11p, idEvent, iPhyRaw) = indexInRaw_now;
end
% update packet Rx OK
stationManagement.pckReceived(activeIDs11p, idEvent) =...
    stationManagement.pckReceived(activeIDs11p, idEvent) | rxOK_thisTime;

% Compute power control allocation (if enabled)
if outParams.printPowerControl
    % Convert linear PtxERP value to Ptx in dBm
    P_ERP_MHz_dBm = 10*log10(phyParams.P_ERP_MHz_11p(idEvent)/phyParams.Gt)+30;
    
    % Convert power to powerControlCounter vector
    P_ERP_MHz_dBm = round(P_ERP_MHz_dBm/outParams.powerResolution)+101;
    maxP_ERP_MHz = length(outputValues.powerControlCounter);
    
    % Store value in powerControlCounter array
    if P_ERP_MHz_dBm>=maxP_ERP_MHz
        outputValues.powerControlCounter(end) = outputValues.powerControlCounter(end) + 1;
    elseif P_ERP_MHz_dBm<=1
        outputValues.powerControlCounter(1) = outputValues.powerControlCounter(1) + 1;
    else
        outputValues.powerControlCounter(P_ERP_MHz_dBm) = outputValues.powerControlCounter(P_ERP_MHz_dBm) + 1;
    end
end

% Count correct receptions and errors up to the maximum awareness range (if enabled)
if outParams.printPacketReceptionRatio
    if ~simParams.neighborsSelection
        AllNeighbors = (activeIDs11p~=idEvent);
    else
        neighborsID11p = stationManagement.neighborsID11p(indexEventInActiveIDs11p,:)';
        AllNeighbors = ismember(activeIDs11p,neighborsID11p);
    end
    distanceIdEventTo11p = positionManagement.distanceReal(stationManagement.indexInActiveIDs_of11pnodes, indexEvent);

    for iRaw = 1:1:floor(phyParams.RawMax11p/outParams.prrResolution)
        distance = iRaw * outParams.prrResolution;

        % Correctly decoded beacons
        RxOKiRaw = AllNeighbors .* (distanceIdEventTo11p<distance) .* rxOK_now .* sameChannel(stationManagement.activeIDs11p);
        RxOKiRaw_earlier = AllNeighbors .* (distanceIdEventTo11p<distance) .* rxOK_earlier .* sameChannel(stationManagement.activeIDs11p);
        
        if stationManagement.ifBeaconLarge
            outputValues.distanceDetailsCounter11p(iChannel,pckType,iRaw,2) = outputValues.distanceDetailsCounter11p(iChannel,pckType,iRaw,2) - nnz(RxOKiRaw_earlier) + nnz(RxOKiRaw);
        else
            outputValues.distanceDetailsCounter11p(iChannel,pckType,iRaw,6) = outputValues.distanceDetailsCounter11p(iChannel,pckType,iRaw,6) - nnz(RxOKiRaw_earlier) + nnz(RxOKiRaw);
        end

        % Errors
        RxErroriRaw = AllNeighbors .* (distanceIdEventTo11p<distance) .* notRxOK_now .* sameChannel(stationManagement.activeIDs11p);
        RxErroriRaw_earlier = AllNeighbors .* (distanceIdEventTo11p<distance) .* notRxOK_earlier .* sameChannel(stationManagement.activeIDs11p);

        if stationManagement.ifBeaconLarge
            outputValues.distanceDetailsCounter11p(iChannel,pckType,iRaw,3) = outputValues.distanceDetailsCounter11p(iChannel,pckType,iRaw,3) - nnz(RxErroriRaw_earlier) + nnz(RxErroriRaw);
        else
            outputValues.distanceDetailsCounter11p(iChannel,pckType,iRaw,7) = outputValues.distanceDetailsCounter11p(iChannel,pckType,iRaw,7) - nnz(RxErroriRaw_earlier) + nnz(RxErroriRaw);
        end
    end
end

end