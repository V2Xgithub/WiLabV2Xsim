function [tracefileTimetable, capableSimTime] = loadTrafficTrace(tracefilename, simulationDuration, args)
    arguments(Input)
        tracefilename (1, 1) string {mustBeNonzeroLengthText}
        simulationDuration (1, 1) double {mustBeReal, mustBeNonnegative}
        args.minX (1, 1) double {mustBeReal} = -inf
        args.minY (1, 1) double {mustBeReal} = -inf
        args.maxX (1, 1) double {mustBeReal} = +inf
        args.maxY (1, 1) double {mustBeReal} = +inf
    end

    arguments(Output)
        tracefileTimetable (:, :) timetable
        capableSimTime (1, 1) double {mustBeNonnegative}
    end

    % The full traffic trace is loaded
    tracefileTable = readtable(tracefilename);

    % Find maximum time in trace file
    maxTime = max(tracefileTable{:, 1});

    % Check if time in input is longer than the maximum in the trace file
    if simulationDuration > maxTime
        capableSimTime = maxTime;
    else
        capableSimTime = simulationDuration;
    end

    % Format table
    % if it has 4 cols, it is time, id, x, y
    if width(tracefileTable) == 4
        tracefileTable.Properties.VariableNames = ["Time" "Id" "X" "Y"];
        tracefileTable.V = NaN(height(tracefileTable), 1);
        tracefileTable.D = NaN(height(tracefileTable), 1);
        % if it has 5 cols, it is time, id, x, y, v
    elseif width(tracefileTable) == 5
        tracefileTable.Properties.VariableNames = ["Time" "Id" "X" "Y" "V"];
        tracefileTable.D = NaN(height(tracefileTable), 1);
        % if it has 5 cols, it is time, id, x, y, v, d
    elseif width(tracefileTable) == 6
        tracefileTable.Properties.VariableNames = ["Time" "Id" "X" "Y" "V" "D"];
    end

    % Normalise Id into strings
    if isnumeric(tracefileTable.Id)
        tracefileTable.Id = arrayfun(@string, tracefileTable.Id);
    end
    % prepend veh_trace_ to the vehicle id
    tracefileTable.Id = arrayfun(@(s) sprintf("veh_trace_%s", s), tracefileTable.Id);

    rf = rowfilter(tracefileTable);
    % Truncate rows outside of the simulation duration
    tracefileTable(rf.Time > simulationDuration, :) = [];
    % Truncate rows out of bounds
    tracefileTable(rf.X > args.maxX, :) = [];
    tracefileTable(rf.X < args.minX, :) = [];
    tracefileTable(rf.Y > args.maxY, :) = [];
    tracefileTable(rf.Y < args.minY, :) = [];

    row_times = seconds(tracefileTable{:, "Time"});
    tracefileTable(:, "Time") = [];
    tracefileTimetable = table2timetable(tracefileTable, "RowTimes", row_times);
    tracefileTimetable = sortrows(tracefileTimetable);

end
