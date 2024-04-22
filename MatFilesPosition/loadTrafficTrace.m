function [trafficTraceTimetable] = loadTrafficTrace(TraceFileName, NameValueArgs)
    arguments (Input)
        TraceFileName (1, 1) string
        NameValueArgs.Duration (1, 1) double {mustBePositive} = inf
    end

    arguments (Output)
        trafficTraceTimetable (:, 4) timetable
    end

    t = readtable(TraceFileName);
    if width(t) == 4
        t.Properties.VariableNames = ["Time", "Vehicle", "X", "Y"];
        t.V = NaN(height(t), 1);
    elseif width(t) == 5
        t.Properties.VariableNames = ["Time", "Vehicle", "X", "Y", "V"];
    else
        error("Trace file has %d columns, unknown format", width(t));
    end

    % Drop rows longer than duration
    t(t.Time > NameValueArgs.Duration, :) = [];
    
    % Convert the first column to duration vector
    t.Time = seconds(t.Time);

    trafficTraceTimetable = table2timetable(t, "RowTimes", "Time");
end
