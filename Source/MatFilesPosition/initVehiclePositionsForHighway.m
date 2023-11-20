function [vehiclePositions, vehicleIds] = initVehiclePositionsForHighway(args)
% Initializes a traffic scenario according to ETSI TR 138 913 V14.3.0
% (2017-10) Section 6.1.8
% Vehicles move along the x-axis either left or right
% The standard does not define if consecutive lanes must be in the same direction, but
% using common sense we assume it is so
arguments (Input)
    args.roadLength (1, 1) double {mustBePositive, mustBeReal}
    args.nLanes (1, 1) double {mustBeGreaterThanOrEqual(args.nLanes, 1)}
    args.laneWidth (1, 1) double {mustBePositive, mustBeReal}
    args.laneGap (1, 1) double {mustBeNonnegative, mustBeReal} = 0;
    args.rho (1, 1) double {mustBePositive, mustBeReal}
    args.vMean (1, 1) double {mustBePositive, mustBeReal}
    args.vStdDev (1, 1) double {mustBeNonnegative, mustBeReal}
end
arguments (Output)
    vehiclePositions (:, 4) table {mustBeNonempty}
    vehicleIds (:, 1) string {mustBeNonzeroLengthText}
end
n_vehicles = ceil(args.roadLength / 1000 * args.rho);
v_lane_selections = randi([1 args.nLanes*2], n_vehicles, 1);
% the direction depends on the selected lane
% first half of the lane is right (direction = 1)
% second half of the lane is left (direction = -1)
v_D = ((v_lane_selections <= args.nLanes).*(1)) + ((v_lane_selections > args.nLanes).*(-1));
% the y coordinate depends on 3 things: the lane selected, the lane gap,
% and a uniform distribution within the lane width
v_Y = ((v_lane_selections-1) .* (args.laneWidth+args.laneGap)) + random("Uniform", 0, args.laneWidth, [n_vehicles 1]);
% the x coordinate is just uniformly distributed along the length of the
% road
v_X = random("Uniform", 0, args.roadLength, [n_vehicles 1]);
% the speed is a normal distribution
v_V = random("Normal", args.vMean * 5/18, args.vStdDev, [n_vehicles 1]);
vehicleIds = arrayfun(@(d) sprintf("veh_highway_%d", d), 1:n_vehicles)';
vehiclePositions = table(v_X, v_Y, v_V, v_D,'VariableNames',["X" "Y" "V" "D"], 'RowNames', vehicleIds);

end
