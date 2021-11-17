function [stationManagement,sinrManagement,outputValues,simValues] = updateKPICV2X(activeIDsTXLTE,indexInActiveIDsOnlyLTE,awarenessID_LTE,neighborsID_LTE,timeManagement,stationManagement,positionManagement,sinrManagement,outputValues,outParams,simParams,appParams,phyParams,simValues)

% Update the counter for transmissions and retransmissions
outputValues.cv2xTransmissionsIncHarq = outputValues.cv2xTransmissionsIncHarq + length(activeIDsTXLTE);
outputValues.cv2xTransmissionsFirst = outputValues.cv2xTransmissionsFirst + sum(stationManagement.pckTxOccurring(activeIDsTXLTE)==1);

% Error detection (up to RawMax)
% Each line corresponds to an error [TX, RX, BR, distance] within RawMax
%errorMatrixRawMax = findErrors_TEMP(activeIDsTXLTE,indexInActiveIDsOnlyLTE,neighborsID_LTE,sinrManagement,stationManagement,positionManagement,phyParams);
% From v 5.4.14
[fateRxListRawMax,stationManagement,sinrManagement] = elaborateFateRxCV2X(timeManagement,activeIDsTXLTE,indexInActiveIDsOnlyLTE,neighborsID_LTE,sinrManagement,stationManagement,positionManagement,appParams,phyParams);

% Error detection (within each value of Raw)
for iPhyRaw=1:length(phyParams.Raw)
    
    % From v 5.4.14
    %errorMatrix = errorMatrixRawMax(errorMatrixRawMax(:,4)<phyParams.Raw(iPhyRaw),:);
    correctRxList = fateRxListRawMax(fateRxListRawMax(:,4)<phyParams.Raw(iPhyRaw) & fateRxListRawMax(:,5)==1,:);
    errorRxList = fateRxListRawMax(fateRxListRawMax(:,4)<phyParams.Raw(iPhyRaw) & fateRxListRawMax(:,5)==0,:);

    % Call function to create awarenessMatrix
    % [#Correctly transmitted beacons, #Errors, #Neighbors]
    %awarenessMatrix = counterTX(activeIDsTXLTE,indexInActiveIDsOnlyLTE,awarenessID_LTE(:,:,iPhyRaw),errorMatrix);
    %awarenessMatrix = counterTX(activeIDsTXLTE,indexInActiveIDsOnlyLTE,awarenessID_LTE(:,:,iPhyRaw),correctRxList);

    % Number of errors
    for iChannel = 1:phyParams.nChannels
        for pckType = 1:appParams.nPckTypes
            %Nerrors = length(errorMatrix( (stationManagement.pckType(errorMatrix(:,1))==pckType & stationManagement.vehicleChannel(errorMatrix(:,1))==iChannel),1));
            %Nerrors = sum(awarenessMatrix((stationManagement.pckType(activeIDsTXLTE)==pckType & stationManagement.vehicleChannel(activeIDsTXLTE)==iChannel),2));
            Nerrors = length(errorRxList( (stationManagement.pckType(errorRxList(:,1))==pckType & stationManagement.vehicleChannel(errorRxList(:,1))==iChannel),1));
            outputValues.NerrorsCV2X(iChannel,pckType,iPhyRaw) = outputValues.NerrorsCV2X(iChannel,pckType,iPhyRaw) + Nerrors;
            outputValues.NerrorsTOT(iChannel,pckType,iPhyRaw) = outputValues.NerrorsTOT(iChannel,pckType,iPhyRaw) + Nerrors;
        %end
    %end
    
    % Number of correctly transmitted beacons
    %for iChannel = 1:phyParams.nChannels
        %for pckType = 1:appParams.nPckTypes
            %NcorrectlyTxBeacons = sum(awarenessMatrix((stationManagement.pckType(activeIDsTXLTE)==pckType & stationManagement.vehicleChannel(activeIDsTXLTE)==iChannel),1));
            NcorrectlyTxBeacons = length(correctRxList( (stationManagement.pckType(correctRxList(:,1))==pckType & stationManagement.vehicleChannel(correctRxList(:,1))==iChannel),1));
            outputValues.NcorrectlyTxBeaconsCV2X(iChannel,pckType,iPhyRaw) = outputValues.NcorrectlyTxBeaconsCV2X(iChannel,pckType,iPhyRaw) + NcorrectlyTxBeacons;
            outputValues.NcorrectlyTxBeaconsTOT(iChannel,pckType,iPhyRaw) = outputValues.NcorrectlyTxBeaconsTOT(iChannel,pckType,iPhyRaw) + NcorrectlyTxBeacons;
    %    end
    %end
    
    % Number of transmitted beacons
    %for iChannel = 1:phyParams.nChannels
        %for pckType = 1:appParams.nPckTypes
            %NtxBeacons = sum(awarenessMatrix((stationManagement.pckType(activeIDsTXLTE)==pckType & stationManagement.vehicleChannel(activeIDsTXLTE)==iChannel),3));
            NtxBeacons = Nerrors + NcorrectlyTxBeacons;
            outputValues.NtxBeaconsCV2X(iChannel,pckType,iPhyRaw) = outputValues.NtxBeaconsCV2X(iChannel,pckType,iPhyRaw) + NtxBeacons;
            outputValues.NtxBeaconsTOT(iChannel,pckType,iPhyRaw) = outputValues.NtxBeaconsTOT(iChannel,pckType,iPhyRaw) + NtxBeacons;
        end
    end
    
    % Compute update delay (if enabled)
    if outParams.printUpdateDelay
        %[simValues.updateTimeMatrixCV2X,outputValues.updateDelayCounterCV2X] = countUpdateDelay(stationManagement,iPhyRaw,activeIDsTXLTE,indexInActiveIDsOnlyLTE,stationManagement.BRid,appParams.NbeaconsF,awarenessID_LTE(:,:,iPhyRaw),errorMatrix,timeManagement.timeNow,simValues.updateTimeMatrixCV2X,outputValues.updateDelayCounterCV2X,outParams.delayResolution,outParams.enableUpdateDelayHD);
        [simValues.updateTimeMatrixCV2X,outputValues.updateDelayCounterCV2X] = countUpdateDelay(stationManagement,iPhyRaw,activeIDsTXLTE,indexInActiveIDsOnlyLTE,awarenessID_LTE(:,:,iPhyRaw),correctRxList,timeManagement.timeNow,simValues.updateTimeMatrixCV2X,outputValues.updateDelayCounterCV2X,outParams.delayResolution,simValues);
    end

    % Compute data age (if enabled)
    if outParams.printDataAge
        %[simValues.dataAgeTimestampMatrixCV2X,outputValues.dataAgeCounterCV2X] = countDataAge(stationManagement,iPhyRaw,timeManagement,activeIDsTXLTE,indexInActiveIDsOnlyLTE,stationManagement.BRid,appParams.NbeaconsF,awarenessID_LTE(:,:,iPhyRaw),errorMatrix,timeManagement.timeNow,simValues.dataAgeTimestampMatrixCV2X,outputValues.dataAgeCounterCV2X,outParams.delayResolution,appParams);
        [simValues.dataAgeTimestampMatrixCV2X,outputValues.dataAgeCounterCV2X] = countDataAge(stationManagement,iPhyRaw,timeManagement,activeIDsTXLTE,indexInActiveIDsOnlyLTE,awarenessID_LTE(:,:,iPhyRaw),correctRxList,timeManagement.timeNow,simValues.dataAgeTimestampMatrixCV2X,outputValues.dataAgeCounterCV2X,outParams.delayResolution,simValues);
    end

    % Compute packet delay (if enabled)
    if outParams.printPacketDelay
        outputValues.packetDelayCounterCV2X = countPacketDelay(stationManagement,iPhyRaw,activeIDsTXLTE,timeManagement.timeNow,timeManagement.timeGeneratedPacketInTxLTE,correctRxList,outputValues.packetDelayCounterCV2X,outParams.delayResolution);
    end

    % Compute power control allocation (if enabled)
    if outParams.printPowerControl
        error('Output not updated in v5');
        %   % Convert linear PtxERP values to Ptx in dBm
        %	Ptx_dBm = 10*log10((phyParams.PtxERP_RB*appParams.RBsBeacon)/(2*phyParams.Gt))+30;
        %	outputValues.powerControlCounter = countPowerControl(IDvehicleTX,Ptx_dBm,outputValues.powerControlCounter,outParams.powerResolution);
    end

    % Update matrices needed for PRRmap creation in urban scenarios (if enabled)
    if simParams.typeOfScenario==2 && outParams.printPRRmap
        simValues = counterMap(iPhyRaw,simValues,stationManagement.activeIDsCV2X,indexInActiveIDsOnlyLTE,activeIDsTXLTE,awarenessID_LTE(:,:,iPhyRaw),errorMatrix);
    end

end

% Count distance details for distances up to the maximum awareness range (if enabled)
if outParams.printPacketReceptionRatio
    %outputValues.distanceDetailsCounterCV2X = countDistanceDetails(indexInActiveIDsOnlyLTE,activeIDsTXLTE,neighborsID_LTE,stationManagement.neighborsDistanceLTE,errorMatrixRawMax,outputValues.distanceDetailsCounterCV2X,stationManagement,outParams,appParams,phyParams);
    outputValues.distanceDetailsCounterCV2X = countDistanceDetails(fateRxListRawMax(fateRxListRawMax(:,5)==1,:),fateRxListRawMax(fateRxListRawMax(:,5)==0,:),outputValues.distanceDetailsCounterCV2X,stationManagement,outParams,appParams,phyParams);
end