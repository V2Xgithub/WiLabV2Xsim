function [XVehicleEstimated, YVehicleEstimated, XVehicleHistory, YVehicleHistory] = addPosDelay(XVehicle, YVehicle, XVehicleHistory, YVehicleHistory, timeNow, posDelay, posPacketLoss)
    arguments (Input)
        XVehicle (:, 1) double {mustBeNonNan, mustBeReal}
        YVehicle (:, 1) double {mustBeNonNan, mustBeReal}
        XVehicleHistory (:, :) cell
        YVehicleHistory (:, :) cell
        timeNow (1, 1) double {mustBeNonnegative}
        posDelay (1, 1) double {mustBeNonnegative}
        posPacketLoss (1, 1) double {mustBeNonnegative, mustBeLessThan(posPacketLoss, 1)}
    end
    arguments (Output)
        XVehicleEstimated (:, 1) double {mustBeNonNan, mustBeReal}
        YVehicleEstimated (:, 1) double {mustBeNonNan, mustBeReal}
        XVehicleHistory (:, :) cell
        YVehicleHistory (:, :) cell
    end
    % preconditions: inputs are equal length
    % histories are cells of timetable (not timeseries, because timeseries
    % will no longer be viewable in variable editor in a future release)
    n_vehicles = numel(YVehicle);
    assert(numel(XVehicle) == numel(YVehicle));
    assert(numel(XVehicleHistory) == numel(YVehicleHistory));
    assert(numel(XVehicle) == numel(XVehicleHistory));
    time_now = seconds(timeNow);
    % operations on cell arrays unfortunately cannot be vectorized
    % it is faster to use forloop than to use cellfun
    % initialise output
    XVehicleEstimated = zeros(n_vehicles, 1);
    YVehicleEstimated = zeros(n_vehicles, 1);
    for i = 1:n_vehicles
        % copy the data out first to avoid repeated indexing
        this_vehicle_x_history = XVehicleHistory{i};
        this_vehicle_y_history = YVehicleHistory{i};
        % just in case
        assert(isa(this_vehicle_x_history, 'timetable'));
        assert(isa(this_vehicle_y_history, 'timetable'));
        % there should only be one variable
        assert(width(this_vehicle_x_history) == 1);
        assert(width(this_vehicle_y_history) == 1);
        % if the timetables are empty, always append
        % else, flip coin for packet loss probability, if the inverse case is
        % true, add to the history timetable
        if isempty(this_vehicle_x_history) || binornd(1, 1 - posPacketLoss)
            this_vehicle_x_history{time_now, 1} = XVehicle(i);
            this_vehicle_y_history{time_now, 1} = YVehicle(i);
            % timetables are value types, so we have to insert it back into the
            % cell array
            XVehicleHistory{i} = this_vehicle_x_history;
            YVehicleHistory{i} = this_vehicle_y_history;
        end
        % find the best position snapshot
        % for simplicity we find the index using the X position table
        oldest_valid_snapshot_time = max(this_vehicle_x_history.Properties.RowTimes(this_vehicle_x_history.Properties.RowTimes <= seconds(timeNow - posDelay)));
        if isempty(oldest_valid_snapshot_time)
            oldest_snapshot = min(this_vehicle_x_history.Properties.RowTimes);
            XVehicleEstimated(i) = table2array(this_vehicle_x_history(oldest_snapshot, 1));
            YVehicleEstimated(i) = table2array(this_vehicle_y_history(oldest_snapshot, 1));
        else
            XVehicleEstimated(i) = table2array(this_vehicle_x_history(oldest_valid_snapshot_time, 1));
            YVehicleEstimated(i) = table2array(this_vehicle_y_history(oldest_valid_snapshot_time, 1));
            % delete rows that are older than the oldest valid snapshot
            this_vehicle_x_history(this_vehicle_x_history.Properties.RowTimes < oldest_valid_snapshot_time, :) = [];
            this_vehicle_y_history(this_vehicle_y_history.Properties.RowTimes < oldest_valid_snapshot_time, :) = [];
            % timetables are value types, so we have to insert it back into the
            % cell array
            XVehicleHistory{i} = this_vehicle_x_history;
            YVehicleHistory{i} = this_vehicle_y_history;
        end
    end
end
