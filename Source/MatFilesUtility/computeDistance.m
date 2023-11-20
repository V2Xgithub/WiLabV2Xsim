function [positionManagement,stationManagement] = computeDistance (simParams,simValues,stationManagement,positionManagement)
% Function derived dividing previous version in computeDistance and
% computeNeighbors (version 5.6.0)


% Compute distance matrix
positionManagement.distanceReal = sqrt((positionManagement.XvehicleReal - positionManagement.XvehicleReal').^2+(positionManagement.YvehicleReal - positionManagement.YvehicleReal').^2);
%if simParams.technology ~= 2 && ... % not only 11p
if sum(stationManagement.vehicleState(stationManagement.activeIDs)==constants.V_STATE_LTE_TXRX)>0  && ...   
    (simParams.posError95 || positionManagement.NgroupPosUpdate~=1) %LTE
    positionManagement.distanceEstimated = sqrt((simValues.XvehicleEstimated - simValues.XvehicleEstimated').^2+(simValues.YvehicleEstimated - simValues.YvehicleEstimated').^2);
else
    positionManagement.distanceEstimated = positionManagement.distanceReal;
end

end