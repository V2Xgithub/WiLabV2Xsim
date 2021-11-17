function [simValues,outputValues] = updateKPI11p(idEvent,indexEvent,timeManagement,stationManagement,positionManagement,sinrManagement,simParams,phyParams,outParams,simValues,outputValues)
% KPIs: correct transmissions and errors are counted

% The message is correctly received if:
% 1) the node is currently receiving
% 2) the node is receiving from idEvent
% 3) the average SINR is above the threshold
% Values are counted within a circle of radius raw

indexEvent11p = find(stationManagement.activeIDs11p == stationManagement.activeIDs(indexEvent));

IDvehicle11p = stationManagement.activeIDs11p;
indexVehicle11p = stationManagement.indexInActiveIDs_of11pnodes;
neighborsID11p = stationManagement.neighborsID11p(indexEvent11p,:)';
distance11p = positionManagement.distanceReal(stationManagement.vehicleState(stationManagement.activeIDs)~=100,stationManagement.vehicleState(stationManagement.activeIDs)~=100);

% Note: I need to work with line vectors, otherwise it works differently when
% sinrVector11p is a vector and when sinrVector11p is a scalar

sinrThr = phyParams.LOS(indexVehicle11p,indexEvent)'.*phyParams.sinrVector11p_LOS(randi(length(phyParams.sinrVector11p_LOS),1,length(indexVehicle11p)))+...%phyParams.LOS(IDvehicle11p,idEvent)*(phyParams.sinrVector11p_LOS(randi(length(phyParams.sinrVector11p_LOS),1,length(IDvehicle11p))))+...
(1-phyParams.LOS(indexVehicle11p,indexEvent)').*(phyParams.sinrVector11p_NLOS(randi(length(phyParams.sinrVector11p_NLOS),1,length(indexVehicle11p))));

rxOK = (stationManagement.vehicleState(IDvehicle11p)==9)' .* (sinrManagement.idFromWhichRx11p(IDvehicle11p)==idEvent)'...
    .* (sinrManagement.sinrAverage11p(IDvehicle11p)' >= sinrThr);

%rxOK = (stationManagement.vehicleState(IDvehicle11p)==9) .* (sinrManagement.idFromWhichRx11p(IDvehicle11p)==idEvent)...
%    .* (sinrManagement.sinrAverage11p(IDvehicle11p) >= (phyParams.sinrVector11p(randi(length(phyParams.sinrVector11p),length(IDvehicle11p),1))))';
rxOK = rxOK';
notRxOK = (~rxOK);

% From version 5.3.1, multiple channels may be present
sameChannel = (stationManagement.vehicleChannel==stationManagement.vehicleChannel(idEvent));

pckType = stationManagement.pckType(idEvent);
iChannel = stationManagement.vehicleChannel(idEvent);

for iPhyRaw = 1:length(phyParams.Raw)
    awarenessID11p = stationManagement.awarenessID11p(indexEvent11p,:,iPhyRaw)';
    awarenessID11p(awarenessID11p~=0) = awarenessID11p(awarenessID11p~=0) .* sameChannel(awarenessID11p(awarenessID11p~=0));

    % Number of correctly received beacons
    neighborsRaw = ismember(IDvehicle11p,awarenessID11p);
    NneighborsRaw = nnz(neighborsRaw);
    rxOKRaw = logical(neighborsRaw .* rxOK);
    NcorrectlyTxBeacons = nnz(rxOKRaw);
    outputValues.NcorrectlyTxBeacons11p(iChannel,pckType,iPhyRaw) = outputValues.NcorrectlyTxBeacons11p(iChannel,pckType,iPhyRaw) + NcorrectlyTxBeacons;
    outputValues.NcorrectlyTxBeaconsTOT(iChannel,pckType,iPhyRaw) = outputValues.NcorrectlyTxBeaconsTOT(iChannel,pckType,iPhyRaw) + NcorrectlyTxBeacons;

    % Number of errors
    Nerrors = NneighborsRaw - NcorrectlyTxBeacons;
    outputValues.Nerrors11p(iChannel,pckType,iPhyRaw) = outputValues.Nerrors11p(iChannel,pckType,iPhyRaw) + Nerrors;
    outputValues.NerrorsTOT(iChannel,pckType,iPhyRaw) = outputValues.NerrorsTOT(iChannel,pckType,iPhyRaw) + Nerrors;

    % Number of received beacons (correct + errors)
    NtxBeacons = NcorrectlyTxBeacons + Nerrors;
    outputValues.NtxBeacons11p(iChannel,pckType,iPhyRaw) = outputValues.NtxBeacons11p(iChannel,pckType,iPhyRaw) + NtxBeacons;
    outputValues.NtxBeaconsTOT(iChannel,pckType,iPhyRaw) = outputValues.NtxBeaconsTOT(iChannel,pckType,iPhyRaw) + NtxBeacons;

    % Compute update delay (if enabled)
    if outParams.printUpdateDelay
        % Find maximum delay in updateDelayCounter
        delayMax = length(outputValues.updateDelayCounter11p(1,1,:,1))*outParams.delayResolution;
        % Vehicles inside the awareness range of vehicle with ID i
        IDIn = awarenessID11p(awarenessID11p>0);
        % ID of vehicles that are outside the awareness range of vehicle i
        all = (1:length(simValues.updateTimeMatrix11p(:,1,iPhyRaw)))';
        IDOut = setdiff(all,IDIn);
        simValues.updateTimeMatrix11p(idEvent,IDOut,iPhyRaw)=-1;
        for iRaw = 1:length(IDIn)
            % If the beacon is currently correctly received by the neighbor
            % inside the awareness range
            if find(IDvehicle11p(rxOKRaw)==IDIn(iRaw))
                % Store previous timestamp
                previousTimeStamp = simValues.updateTimeMatrix11p(idEvent,IDIn(iRaw),iPhyRaw);
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
        simValues.updateTimeMatrix11p(idEvent,IDvehicle11p(rxOKRaw),iPhyRaw) = timeManagement.timeNow;
    end

    % Compute data age (if enabled)
    if outParams.printDataAge
        % Find maximum delay in updateDelayCounter
        delayMax = length(outputValues.dataAgeCounter11p(1,1,:,1))*outParams.delayResolution;
        % Vehicles inside the awareness range of vehicle with ID i
        IDIn = awarenessID11p(awarenessID11p>0);
        % ID of vehicles that are outside the awareness range of vehicle i
        all = (1:length(simValues.dataAgeTimestampMatrix11p(:,1,iPhyRaw)))';
        IDOut = setdiff(all,IDIn);
        simValues.dataAgeTimestampMatrix11p(idEvent,IDOut,iPhyRaw)=-1;
        for iRaw = 1:length(IDIn)
            % If the beacon is currently correctly received by the neighbor
            % inside the awareness range
            if find(IDvehicle11p(rxOKRaw)==IDIn(iRaw))
                % Store previous timestamp
                previousTimeStamp = simValues.dataAgeTimestampMatrix11p(idEvent,IDIn(iRaw),iPhyRaw);
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
        simValues.dataAgeTimestampMatrix11p(idEvent,IDvehicle11p(rxOKRaw),iPhyRaw) = timeManagement.timeLastPacket(idEvent);
    end

    % Compute packet delay (if enabled)
    if outParams.printPacketDelay
        % Find maximum delay in updateDelayCounter
        delayMax = length(outputValues.packetDelayCounter11p(1,1,:,1))*outParams.delayResolution;
        % Compute packet delay
        packetDelay = timeManagement.timeNow - timeManagement.timeLastPacket(idEvent);
        if packetDelay>=delayMax
            % Increment last counter
            outputValues.packetDelayCounter11p(iChannel,pckType,end,iPhyRaw) = outputValues.packetDelayCounter11p(iChannel,pckType,end,iPhyRaw) + NcorrectlyTxBeacons;
        else
            % Increment counter corresponding to the current delay
            outputValues.packetDelayCounter11p(iChannel,pckType,ceil(packetDelay/outParams.delayResolution),iPhyRaw) = ...
                outputValues.packetDelayCounter11p(iChannel,pckType,ceil(packetDelay/outParams.delayResolution),iPhyRaw) + NcorrectlyTxBeacons;
        end
    end

    % Update matrices needed for PRRmap creation (if enabled)
    if simParams.typeOfScenario==2 && outParams.printPRRmap
        indexRxOkRaw = find(rxOKRaw);
        % Count correctly received beacons
        for iRaw = 1:length(indexRxOkRaw)
            simValues.correctlyReceivedMap11p(simValues.YmapFloor(indexRxOkRaw(iRaw)),simValues.XmapFloor(indexRxOkRaw(iRaw)),iPhyRaw) = ...
                simValues.correctlyReceivedMap11p(simValues.YmapFloor(indexRxOkRaw(iRaw)),simValues.XmapFloor(indexRxOkRaw(iRaw)),iPhyRaw) + 1;
        end
        % Count neighbors of idEvent
        simValues.neighborsMap11p(simValues.YmapFloor(indexEvent),simValues.XmapFloor(indexEvent),iPhyRaw) = ...
            simValues.neighborsMap11p(simValues.YmapFloor(indexEvent),simValues.XmapFloor(indexEvent),iPhyRaw) + NneighborsRaw;
    end
end

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
        AllNeighbors = (IDvehicle11p~=idEvent);
    else
        AllNeighbors = ismember(IDvehicle11p,neighborsID11p);
    end
%    AllNeighbors(awarenessID11p~=0) = awarenessID11p(awarenessID11p~=0) .* sameChannel(awarenessID11p(awarenessID11p~=0));
    for iRaw = 1:1:floor(phyParams.RawMax11p/outParams.prrResolution)
        distance = iRaw * outParams.prrResolution;

        % Correctly decoded beacons
        RxOKiRaw = AllNeighbors .* (distance11p(:,indexEvent11p)<distance) .* rxOK .* sameChannel(stationManagement.activeIDs11p);
        if stationManagement.ifBeaconLarge
            outputValues.distanceDetailsCounter11p(iChannel,pckType,iRaw,2) = outputValues.distanceDetailsCounter11p(iChannel,pckType,iRaw,2) + nnz(RxOKiRaw);
        else
            outputValues.distanceDetailsCounter11p(iChannel,pckType,iRaw,6) = outputValues.distanceDetailsCounter11p(iChannel,pckType,iRaw,6) + nnz(RxOKiRaw);
        end
        % Errors
        RxErroriRaw = AllNeighbors .* (distance11p(:,indexEvent11p)<distance) .* notRxOK .* sameChannel(stationManagement.activeIDs11p);
        if stationManagement.ifBeaconLarge
            outputValues.distanceDetailsCounter11p(iChannel,pckType,iRaw,3) = outputValues.distanceDetailsCounter11p(iChannel,pckType,iRaw,3) + nnz(RxErroriRaw);
        else
            outputValues.distanceDetailsCounter11p(iChannel,pckType,iRaw,7) = outputValues.distanceDetailsCounter11p(iChannel,pckType,iRaw,7) + nnz(RxErroriRaw);
        end
    end
end


end