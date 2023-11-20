function [X,Y] = convertToGrid(Xvehicle,Yvehicle,XminMap,YmaxMap,StepMap)
% Convert coordinates of vehicles to GridProp

% Coordinates of vehicles converted to grid
X = (Xvehicle-XminMap)./StepMap+1;
Y = (YmaxMap-Yvehicle)./StepMap+1;

end

