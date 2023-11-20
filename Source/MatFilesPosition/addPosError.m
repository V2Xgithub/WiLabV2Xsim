function [Xvehicle, Yvehicle] = addPosError(XvehicleReal,YvehicleReal,sigma)
% Add positioning error based on the Gaussian model

Nvehicles = length(XvehicleReal(:,1));
error = sigma.*randn(Nvehicles,1);               % Generate error samples
angle = 2*pi.*rand(Nvehicles,1);                 % Generate random angles

Xvehicle = (XvehicleReal + error.*cos(angle));
Yvehicle = (YvehicleReal + error.*sin(angle));

end