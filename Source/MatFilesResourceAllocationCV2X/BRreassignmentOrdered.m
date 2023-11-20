function [BRid, Nreassign] = BRreassignmentOrdered(Xvehicle,IDvehicle,BRid,NbeaconsT,NbeaconsF)
% Benchmark Algorithm 102 (ORDERED ALLOCATION)

Nvehicles = length(IDvehicle(:,1));   % Number of vehicles

% Assign beacon resources ordered by X coordinates to vehicles
[~,indexOrder] = sort(Xvehicle);
IDvehicle = IDvehicle(indexOrder);

% Create ordered BRid vector
Nbeacons = NbeaconsT*NbeaconsF;
BRs = (1:Nbeacons)';
BRFs = mod(BRs-1,NbeaconsF)+1;
[~,index] = sort(BRFs);
BRordered = BRs(index);
BRordered = repmat(BRordered,ceil(Nvehicles/Nbeacons),1);

% Assign resources to vehicles
BRid(IDvehicle) = BRordered(1:Nvehicles);

Nreassign = Nvehicles;

end