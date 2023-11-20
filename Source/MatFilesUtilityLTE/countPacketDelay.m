function packetDelayCounter = countPacketDelay(stationManagement,iPhyRaw,IDvehicleTX,subframeNow,subframeLastPacket,correctRxList,packetDelayCounter,delayResolution)
% Function to compute the packet delay between received beacons
% Returns the updated packetDelayCounter

% Number of vehicles transmitting at the current time
Ntx = length(IDvehicleTX);

% Find maximum delay in updateDelayCounter
delayMax = length(packetDelayCounter(1,1,:,1))*delayResolution;

for i = 1:Ntx
    % Packet type
    pckType = stationManagement.pckType(IDvehicleTX(i));
    iChannel = stationManagement.vehicleChannel(IDvehicleTX(i));
    % Number of correct receptions
    iNcorrect = length(correctRxList(correctRxList(:,1)==IDvehicleTX(i),1));
    % Compute packet delay of the Tx vehicle (module is used to adapt the
    % calculation to the simulator design)
    if subframeLastPacket(IDvehicleTX(i))>0
        packetDelay = subframeNow - subframeLastPacket(IDvehicleTX(i));
    
        if packetDelay<0
            error('Delay of a packet z 0');
        elseif packetDelay>=delayMax
            % Increment last counter
            packetDelayCounter(iChannel,pckType,end,iPhyRaw) = packetDelayCounter(iChannel,pckType,end,iPhyRaw) + iNcorrect;
        else
            % Increment counter corresponding to the current delay
            packetDelayCounter(iChannel,pckType,ceil(packetDelay/delayResolution),iPhyRaw) = ...
                packetDelayCounter(iChannel,pckType,ceil(packetDelay/delayResolution),iPhyRaw) + iNcorrect;
        end
    end
end

end
