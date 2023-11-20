function [XvehicleReal,YvehicleReal,IDvehicle,indexNewVehicles,indexOldVehicles,indexOldVehiclesToOld,IDvehicleExit,speedNow] = updatePositionFile(time,dataTrace,oldIDvehicle,XvehiclePrevious,YvehiclePrevious,timePrevious,simValues,outParams)
% Update position of vehicles from file

%XvehiclePrevious = XvehicleReal;
%YvehiclePrevious = YvehicleReal;
%tPrevious = find(dataTrace(:,1)<time,1,'Last');

fileIndex = find(dataTrace(:,1)==time);
IDvehicle = dataTrace(fileIndex,2);
XvehicleReal = dataTrace(fileIndex,3);
YvehicleReal = dataTrace(fileIndex,4);
if length(dataTrace(1,:))>4
    speedNow = dataTrace(fileIndex,5);
end

% Sort IDvehicle, XvehicleReal and YvehicleReal by IDvehicle
[IDvehicle,indexOrder] = sort(IDvehicle);
XvehicleReal = XvehicleReal(indexOrder);
YvehicleReal = YvehicleReal(indexOrder);
if length(dataTrace(1,:))>4
    speedNow = speedNow(indexOrder);
end

[~,indexNewVehicles] = setdiff(IDvehicle,oldIDvehicle,'stable');

% Find IDs of vehicles that are exiting the scenario
IDvehicleExit = setdiff(oldIDvehicle,IDvehicle);

% Find indices of vehicles in IDvehicle that are both in IDvehicle and OldIDvehicle
indexOldVehicles = find(ismember(IDvehicle,oldIDvehicle));

% Find indices of vehicles in OldIDvehicle that are both in IDvehicle and OldIDvehicle
indexOldVehiclesToOld = find(ismember(oldIDvehicle,IDvehicle));

%figure(1)
%plot(XvehicleReal,YvehicleReal,'p');

if length(dataTrace(1,:))==4
    speedNow = zeros(length(IDvehicle),1);
    for i=1:length(IDvehicle)
        iOld = find(oldIDvehicle==IDvehicle(i));
        if ~isempty(iOld)
            speedNow(i) = sqrt((XvehicleReal(i)-XvehiclePrevious(iOld)).*(XvehicleReal(i)-XvehiclePrevious(iOld)) + ...
                       (YvehicleReal(i)-YvehiclePrevious(iOld)).*(YvehicleReal(i)-YvehiclePrevious(iOld)))/(time-timePrevious);
        %else           
        %    speedNow(i) = 0;
        end

    %     if IDvehicle(i)==1
    %         figure(2)
    %         plot(time,speedNow(i),'pr');
    %         hold on
    %     end
    end
end

% Print speed (if enabled)
if ~isempty(outParams) && outParams.printSpeed
    printSpeedToFile(time,IDvehicle,speedNow,simValues.maxID,outParams);
end
