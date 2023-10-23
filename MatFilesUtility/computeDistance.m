function [positionManagement] = computeDistance (positionManagement)
% Operates on struct members XvehicleReal, YvehicleReal, XvehicleEstimated,
% YvehiclesEstimated to populate struct members distanceReal,
% distanceEstimated
positionManagement.distanceReal = sqrt((positionManagement.XvehicleReal - positionManagement.XvehicleReal').^2+(positionManagement.YvehicleReal - positionManagement.YvehicleReal').^2);
positionManagement.distanceEstimated = sqrt((positionManagement.XvehicleEstimated - positionManagement.XvehicleEstimated').^2+(positionManagement.YvehicleEstimated - positionManagement.YvehicleEstimated').^2);
end
