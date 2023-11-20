function [BRid] = updateBRidFile(BRid,IDvehicle,indexNewVehicles)
% Update BRid vector if using File Trace (variable number of vehicles)

BRidIn = BRid(IDvehicle,:);
BRidIn(indexNewVehicles,:)=-1;
BRid = -2*ones(length(BRid(:,1)),length(BRid(1,:)));
BRid(IDvehicle,:) = BRidIn;

end