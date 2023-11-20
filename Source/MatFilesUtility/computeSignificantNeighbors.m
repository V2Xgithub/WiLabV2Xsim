function [effAwarenessID,effNeighborsID,XvehicleRealOld,YvehicleRealOld,alphaOld] = computeSignificantNeighbors(IDvehicle,XvehicleReal,YvehicleReal,XvehicleRealOld,YvehicleRealOld,neighborsID,indexNewVehicles,indexOldVehicles,indexOldVehiclesToOld,angleOld,margin,Raw,RawMax,neighborsDistance)
% Function that calculates effective neighbors i.e. neighbors at
% distance lower than MaxRaw and whose trajectories are signficant

% Initialise matrix of effective neighbors
effNeighborsID = neighborsID*0;

% Adjust dimension of old coordinate arrays
Xold =  zeros(length(XvehicleReal),1);
Xold(indexOldVehicles) = XvehicleRealOld(indexOldVehiclesToOld);

Yold = zeros(length(YvehicleReal),1);
Yold(indexOldVehicles) = YvehicleRealOld(indexOldVehiclesToOld);

% Adjust dimension of old angle array
alphaOld = zeros(length(Yold),1);
alphaOld(indexNewVehicles) = pi;
alphaOld(indexOldVehicles) = angleOld(indexOldVehiclesToOld);

% Calculate angle of trajectory
angle = computeAngle(XvehicleReal,YvehicleReal,Xold,Yold,alphaOld);

% Build matrix of significant neighbors
for i=1:length(neighborsID(:,1))
    for j=1:nnz(neighborsID(i,:))
        index = find(IDvehicle==neighborsID(i,j));
        % Check whether they are relevant neighbors
        relevant = computeMinSegmentDistance(XvehicleReal(i),YvehicleReal(i),XvehicleReal(index),YvehicleReal(index),angle(i),angle(index),margin,RawMax);

        % Build matrix of effective neighbors
        if relevant
            effNeighborsID(i,j) = neighborsID(i,j);
        else
            effNeighborsID(i,j) = 0;
        end
        
    end
end

% Matrix of significant neighbors in the awareness range
effAwarenessID = (neighborsDistance<Raw).*effNeighborsID;

% Update old coordinates and angle
XvehicleRealOld = XvehicleReal;
YvehicleRealOld = YvehicleReal;
alphaOld = angle;

end
