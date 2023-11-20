function  simValues = counterMap(iPhyRaw,simValues,IDvehicle,indexVehicleTX,IDvehicleTX,awarenessID,errorMatrix)
% Function to update matrices needed for PRRmap creation in urban scenarios

% Number of vehicles transmitting at the current time
Ntx = length(IDvehicleTX);

for i = 1:Ntx
    awarenessIndex = find(awarenessID(indexVehicleTX(i),:)>0);
    for j = 1:length(awarenessIndex)
        % ID and index of receiving vehicle
        IDvehicleRX = awarenessID(indexVehicleTX(i),awarenessIndex(j));
        indexVehicleRX = find(IDvehicle==IDvehicleRX);
        % Count correctly received beacons
        if isempty(find(errorMatrix(:,1)==IDvehicleTX(i) & errorMatrix(:,2)==IDvehicleRX, 1))
            simValues.correctlyReceivedMapCV2X(simValues.YmapFloor(indexVehicleRX),simValues.XmapFloor(indexVehicleRX),iPhyRaw) = ...
                simValues.correctlyReceivedMapCV2X(simValues.YmapFloor(indexVehicleRX),simValues.XmapFloor(indexVehicleRX),iPhyRaw) + 1;
        end
    end
    % Count neighbors of IDVehicleTX(i)
    NneighborsRaw = length(awarenessIndex);
    simValues.neighborsMapCV2X(simValues.YmapFloor(indexVehicleTX(i)),simValues.XmapFloor(indexVehicleTX(i)),iPhyRaw) = ...
        simValues.neighborsMapCV2X(simValues.YmapFloor(indexVehicleTX(i)),simValues.XmapFloor(indexVehicleTX(i)),iPhyRaw) + NneighborsRaw;
end

end