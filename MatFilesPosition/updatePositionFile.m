function [XvehicleReal,YvehicleReal,IDvehicle,indexNewVehicles,indexOldVehicles,indexOldVehiclesToOld,IDvehicleExit,speedNow, direction] = updatePositionFile(time,dataTrace,oldIDvehicle,XvehiclePrevious,YvehiclePrevious,timePrevious,simValues,outParams)
% Update position of vehicles from file

%XvehiclePrevious = XvehicleReal;
%YvehiclePrevious = YvehicleReal;
tPrevious = find(dataTrace(:,1)<time,1,'Last');

fileIndex = find(dataTrace(:,1)==time);
IDvehicle = dataTrace(fileIndex,2);

% Sort IDvehicle
[IDvehicle,indexOrder] = sort(IDvehicle);

% IDs of vehicles that are exiting the scenario
IDvehicleExit = setdiff(oldIDvehicle,IDvehicle);

% Indices of vehicles in IDvehicle that are new
[~,indexNewVehicles] = setdiff(IDvehicle,oldIDvehicle,'stable');

% Indices of vehicles in IDvehicle that are both in IDvehicle and OldIDvehicle
indexOldVehicles = find(ismember(IDvehicle,oldIDvehicle));

% Indices of vehicles in OldIDvehicle that are both in IDvehicle and OldIDvehicle
indexOldVehiclesToOld = find(ismember(oldIDvehicle,IDvehicle));

% Sort XvehicleReal and YvehicleReal by IDvehicle
XvehicleReal = dataTrace(fileIndex,3);
XvehicleReal = XvehicleReal(indexOrder);

YvehicleReal = dataTrace(fileIndex,4);
YvehicleReal = YvehicleReal(indexOrder);

if size(dataTrace, 2) > 4
    speedNow = dataTrace(fileIndex,5);
    speedNow = speedNow(indexOrder);
else
    speedNow = zeros(size(IDvehicle));  % assume the speed of new vehicles are all 0  
    speedNow(indexOldVehicles) = ((YvehicleReal(indexOldVehicles)-YvehiclePrevious(indexOldVehiclesToOld)).^2 + (XvehicleReal(indexOldVehicles)-XvehiclePrevious(indexOldVehiclesToOld)).^2).^0.5 ./ (time-tPrevious);
end

direction = complex(zeros(size(IDvehicle)));  % assume the direction of the new vehicles are all 0  
direction(indexOldVehicles) = complex((XvehicleReal(indexOldVehicles) - XvehiclePrevious(indexOldVehiclesToOld)), (YvehicleReal(indexOldVehicles) - YvehiclePrevious(indexOldVehiclesToOld)));


% Print speed (if enabled)
if ~isempty(outParams) && outParams.printSpeed
    printSpeedToFile(time,IDvehicle,speedNow,simValues.maxID,outParams);
end
