function [stationManagement,outputValues] = bufferOverflowLTE(idOverflow,timeManagement,positionManagement,stationManagement,phyParams,appParams,outputValues,outParams)

pckType = stationManagement.pckType(idOverflow);
iChannel = stationManagement.vehicleChannel(idOverflow);

%if (stationManagement.cv2xNumberOfReplicas(idOverflow) - stationManagement.pckRemainingTx(idOverflow)) > 0
if stationManagement.pckNextAttempt(idOverflow) > 1 % means that one attempt was made
    notYetReceived = stationManagement.activeIDsCV2X(stationManagement.pckReceived(stationManagement.activeIDsCV2X,idOverflow)<=0);
end


for iPhyRaw=1:length(phyParams.Raw)
    % from v 5.4.15, retransmissions are possible - thus packets are
    % discarded if this is the first transmission, otherwise is an error
    %if (stationManagement.cv2xNumberOfReplicas(idOverflow) - stationManagement.pckRemainingTx(idOverflow)) > 0
    currentT = (mod((timeManagement.elapsedTime_TTIs-1),appParams.NbeaconsT)+1);
    if stationManagement.pckNextAttempt(idOverflow) > 1 
        % || ceil((stationManagement.BRid(idOverflow,1))/appParams.NbeaconsF)==currentT    
        % Count as an error if not already received
         NtxBeacons = nnz(positionManagement.distanceReal(idOverflow,notYetReceived) < phyParams.Raw(iPhyRaw)) - 1; % -1 to remove self
         outputValues.NerrorsCV2X(iChannel,pckType,iPhyRaw) = outputValues.NerrorsCV2X(iChannel,pckType,iPhyRaw) + NtxBeacons;
         outputValues.NerrorsTOT(iChannel,pckType,iPhyRaw) = outputValues.NerrorsTOT(iChannel,pckType,iPhyRaw) + NtxBeacons;
         outputValues.NtxBeaconsCV2X(iChannel,pckType,iPhyRaw) = outputValues.NtxBeaconsCV2X(iChannel,pckType,iPhyRaw) + NtxBeacons;
         outputValues.NtxBeaconsTOT(iChannel,pckType,iPhyRaw) = outputValues.NtxBeaconsTOT(iChannel,pckType,iPhyRaw) + NtxBeacons;
    else    
        % Count as a blocked transmission (previous packet is discarded without any attempt)
        outputValues.NblockedCV2X(iChannel,pckType,iPhyRaw) = outputValues.NblockedCV2X(iChannel,pckType,iPhyRaw) + nnz(positionManagement.distanceReal(idOverflow,stationManagement.activeIDsCV2X) < phyParams.Raw(iPhyRaw)) - 1; % -1 to remove self
        outputValues.NblockedTOT(iChannel,pckType,iPhyRaw) = outputValues.NblockedTOT(iChannel,pckType,iPhyRaw) + nnz(positionManagement.distanceReal(idOverflow,stationManagement.activeIDsCV2X) < phyParams.Raw(iPhyRaw)) - 1;
    end
end
if outParams.printPacketReceptionRatio
    for iRaw = 1:1:floor(phyParams.RawMaxCV2X/outParams.prrResolution)
        distance = iRaw * outParams.prrResolution;
        %if (stationManagement.cv2xNumberOfReplicas(idOverflow) - stationManagement.pckRemainingTx(idOverflow)) > 0
        if stationManagement.pckNextAttempt(idOverflow) > 1
            % Count as an error if not already received
            NtxBeacons = nnz(positionManagement.distanceReal(idOverflow,notYetReceived)<distance) - 1;
            outputValues.distanceDetailsCounterCV2X(iChannel,pckType,iRaw,3) = outputValues.distanceDetailsCounterCV2X(iChannel,pckType,iRaw,3) + NtxBeacons;           
        else
            outputValues.distanceDetailsCounterCV2X(iChannel,pckType,iRaw,4) = outputValues.distanceDetailsCounterCV2X(iChannel,pckType,iRaw,4) + nnz(positionManagement.distanceReal(idOverflow,stationManagement.activeIDsCV2X)<distance) - 1;
        end
    end
end

%% Print in command window
% if ~isfield(outParams,'nLTEoverflow')
%     outParams.nLTEoverflow=0;
% end
% outParams.nLTEoverflow=outParams.nLTEoverflow+1;
% fprintf('\nMore than one packet in the queue of an LTE node (counter=%d). Not expected.\n',outParams.nLTEoverflow);

stationManagement.pckBuffer(idOverflow) = stationManagement.pckBuffer(idOverflow) - 1;
