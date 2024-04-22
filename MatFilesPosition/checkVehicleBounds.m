function [activeIds, enteredIds, exitedIds] = checkVehicleBounds(VehiclePositions, PreviouslyActiveIds, NameValueArguments)
    arguments (Input)
        VehiclePositions (:, 4) table
        PreviouslyActiveIds (:, 1) double {mustBeReal, mustBePositive, mustBeInteger}
        NameValueArguments.XMin (1, 1) double {mustBeReal} = -inf
        NameValueArguments.XMax (1, 1) double {mustBeReal} = inf
        NameValueArguments.YMin (1, 1) double {mustBeReal} = -inf
        NameValueArguments.YMax (1, 1) double {mustBeReal} = inf
    end

    arguments (Output)
        activeIds (:, 1) double {mustBeReal, mustBePositive, mustBeInteger}
        enteredIds (:, 1) double {mustBeReal, mustBePositive, mustBeInteger}
        exitedIds (:, 1) double {mustBeReal, mustBePositive, mustBeInteger}
    end

    indices_in_x_bounds = (VehiclePositions.X >= NameValueArguments.XMin) & (VehiclePositions.X < NameValueArguments.XMax);
    indices_in_y_bounds = (VehiclePositions.Y >= NameValueArguments.YMin) & (VehiclePositions.Y < NameValueArguments.YMax);
    activeIds = VehiclePositions.Vehicle(indices_in_x_bounds & indices_in_y_bounds);
    enteredIds = setdiff(activeIds, PreviouslyActiveIds);
    exitedIds = setdiff(PreviouslyActiveIds, activeIds);
end

