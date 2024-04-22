function [positions] = updatePositionFile(TrafficTraceTimetable, AtTime, VehicleIds)
    arguments (Input)
        TrafficTraceTimetable (:, 4) timetable
        AtTime (1, 1) double {mustBeReal, mustBeNonnegative}
        VehicleIds (:, 1) double {mustBeReal, mustBePositive}
    end

    arguments (Output)
        positions (:, 4) table
    end

    n_vehicles = numel(VehicleIds);
    X = zeros(n_vehicles, 1);
    Y = zeros(n_vehicles, 1);
    V = NaN(n_vehicles, 1);
    for i = 1:n_vehicles
        vehicle = VehicleIds(i);
        subtable = TrafficTraceTimetable(TrafficTraceTimetable.Vehicle == vehicle, :);
        if isempty(subtable)
            continue
        end
        X(i) = interp1(subtable.Properties.RowTimes, subtable.X, seconds(AtTime), 'linear', 0);
        Y(i) = interp1(subtable.Properties.RowTimes, subtable.Y, seconds(AtTime), 'linear', 0);
    end

    positions = table(VehicleIds, X, Y, V, ...
                        'VariableNames', ["Vehicle", "X", "Y", "V"]);
end
