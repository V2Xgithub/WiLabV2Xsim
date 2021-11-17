function [Xvehicle,Yvehicle,PosUpdateIndex] = addPosDelay(Xvehicle,Yvehicle,XvehicleReal,YvehicleReal,IDvehicle,indexNewVehicles,...
    indexOldVehicles,indexOldVehiclesToOld,posUpdateAllVehicles,PosUpdatePeriod)
% Update positions of vehicles in the current positioning update period
% (PosUpdatePeriod)

% Initialize temporary Xvehicle and Yvehicle
Nvehicles = length(IDvehicle);
XvehicleTemp = zeros(Nvehicles,1);
YvehicleTemp = zeros(Nvehicles,1);

% Position of new vehicles in the scenario immediately updated
XvehicleTemp(indexNewVehicles) = XvehicleReal(indexNewVehicles);
YvehicleTemp(indexNewVehicles) = YvehicleReal(indexNewVehicles);

% Copy old coordinates to temporary Xvehicle and Yvehicle
XvehicleTemp(indexOldVehicles) = Xvehicle(indexOldVehiclesToOld);
YvehicleTemp(indexOldVehicles) = Yvehicle(indexOldVehiclesToOld);
Xvehicle = XvehicleTemp;
Yvehicle = YvehicleTemp;

% Find index of vehicles in the scenario whose position will be updated
PosUpdateIndex = find(posUpdateAllVehicles(IDvehicle)==PosUpdatePeriod);

% Update positions
Xvehicle(PosUpdateIndex) = XvehicleReal(PosUpdateIndex);
Yvehicle(PosUpdateIndex) = YvehicleReal(PosUpdateIndex);

end

