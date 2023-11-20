function [dUpdate,S,distanceRealOld] = updateDistanceChangeForShadowing(distanceReal,distanceRealOld,indexOldVehicles,indexOldVehiclesToOld,Shadowing_dB,stdDevShadowLOS_dB)
% This function calculates the difference of the distance between two
% vehicles w.r.t. the previous instant and it updates the
% shadowing matrix removing vehicles out of the scenario and ordering
% indices

Nvehicles = length(distanceReal(:,1));
dUpdate = zeros(Nvehicles,Nvehicles);
S = randn(Nvehicles,Nvehicles)*stdDevShadowLOS_dB;

% Update distance matrix
dUpdate(indexOldVehicles,indexOldVehicles) = abs(distanceReal(indexOldVehicles,indexOldVehicles)-distanceRealOld(indexOldVehiclesToOld,indexOldVehiclesToOld));

% Update shadowing matrix 
S(indexOldVehicles,indexOldVehicles) = Shadowing_dB(indexOldVehiclesToOld,indexOldVehiclesToOld);

% Update distanceRealOld for next snapshot
distanceRealOld = distanceReal;

end

