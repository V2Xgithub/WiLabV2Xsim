function [dUpdate,S,distanceRealOld] = updateDistanceChangeForShadowing(distanceReal,distanceRealOld,stdDevShadowLOS_dB, activeVehicles, enteredVehicles, exitedVehicles)
% This function calculates the difference of the distance between two
% vehicles w.r.t. the previous instant and it updates the
% shadowing matrix removing vehicles out of the scenario and ordering
% indices
arguments (Input)
    distanceReal (:, :) double {mustBeReal, mustBeNonempty} % current distance matrix, always size of max vehicles
    distanceRealOld (:, :) double {mustBeReal, mustBeNonempty} % previous distance matrix, always size of max vehicles
    stdDevShadowLOS_dB (1, 1) double {mustBeReal} % physical parameter
    activeVehicles (:, 1) double {mustBeReal, mustBePositive} % currently active vehicles
    enteredVehicles (:, 1) double {mustBeReal, mustBePositive} % vehicles that just entered in this epoch
    exitedVehicles (:, 1) double {mustBeReal, mustBePositive} % vehicles that just exited in this epoch
end
arguments (Output)
    dUpdate (:, :) double {mustBeReal} % change in position, max_vehicles size, diagonal must be 0
    S (:, :) double {mustBeReal} % change in shadowing, max_vehicles size
    distanceRealOld (:, :) double {mustBeReal, mustBeNonempty} % return the current distance matrix
end

% sanity check - the global state matrices must have the correct size
if size(distanceReal) ~= size(distanceRealOld)
    error("Matrices do not have the correct size")
end
max_vehicles = width(distanceReal);
S = randn(max_vehicles, max_vehicles)*stdDevShadowLOS_dB;
% Update distance matrix
dUpdate = abs(distanceReal - distanceRealOld);

% Update distanceRealOld for next snapshot
distanceRealOld = distanceReal;

% sanity check - diagonals must be 0
if any(diag(dUpdate))
    error("dUpdate's diagonal is not all 0")
end

end

