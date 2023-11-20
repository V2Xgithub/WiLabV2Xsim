classdef TestLoadTrafficTrace < matlab.unittest.TestCase
    properties (TestParameter)
        type = {'string'};
        filename = struct('col3', "4v_3col.txt", 'col4', "4v_4col.txt", 'col5', "4v_5col.txt");
    end
    methods (Test)
        function tracefilepath = getTraceFilePath(filename)
        end

        function testReturnsTableWithCorrectColumnNames(testCase, filename)
            [this_dir, ~, ~] = fileparts(mfilename('fullpath'));
            tracefilepath = fullfile(this_dir, filename);
            trafficTrace = loadTrafficTrace(tracefilepath, 3);
            testCase.verifyClass(trafficTrace, "timetable");
            testCase.verifyEqual(width(trafficTrace), 5);
            column_names = ["Id" "X" "Y" "V" "D"];
            for column_name = column_names
                testCase.verifyEqual(ismember(column_name, trafficTrace.Properties.VariableNames), true);
            end
        end

        function testLoadsCorrectNumberOfVehicles(testCase, filename)
            [this_dir, ~, ~] = fileparts(mfilename('fullpath'));
            tracefilepath = fullfile(this_dir, filename);
            trafficTrace = loadTrafficTrace(tracefilepath, 3);
            vehicle_ids = unique(trafficTrace.Id);
            testCase.verifyEqual(numel(vehicle_ids), 4);
        end

        function testShorterDurationResultsInTruncatedTable(testCase, filename)
            [this_dir, ~, ~] = fileparts(mfilename('fullpath'));
            tracefilepath = fullfile(this_dir, filename);
            trafficTrace = loadTrafficTrace(tracefilepath, 1);
            max_time = max(trafficTrace.Properties.RowTimes);
            testCase.verifyEqual(max_time <= 1, true);
        end

        function testTimetableIsSorted(testCase, filename)
            [this_dir, ~, ~] = fileparts(mfilename('fullpath'));
            tracefilepath = fullfile(this_dir, filename);
            trafficTrace = loadTrafficTrace(tracefilepath, 1);
            for i = 2:height(trafficTrace)
                testCase.verifyEqual(trafficTrace.Properties.RowTimes(i - 1) <= trafficTrace.Properties.RowTimes(i), true);
            end
        end

        function test3ColumnTraceFileGeneratesNanVandDColumn(testCase)
            [this_dir, ~, ~] = fileparts(mfilename('fullpath'));
            tracefilepath = fullfile(this_dir, "4v_3col.txt");
            trafficTrace = loadTrafficTrace(tracefilepath, 3);
            testCase.verifyEqual(all(isnan(trafficTrace.V)), true);
            testCase.verifyEqual(all(isnan(trafficTrace.D)), true);
        end

        function test4ColumnTraceFileGeneratesNonNanVColumn(testCase)
            [this_dir, ~, ~] = fileparts(mfilename('fullpath'));
            tracefilepath = fullfile(this_dir, "4v_4col.txt");
            trafficTrace = loadTrafficTrace(tracefilepath, 3);
            testCase.verifyEqual(any(isnan(trafficTrace.V)), false);
        end

        function test5ColumnTraceFileGeneratesNonNanDColumn(testCase)
            [this_dir, ~, ~] = fileparts(mfilename('fullpath'));
            tracefilepath = fullfile(this_dir, "4v_5col.txt");
            trafficTrace = loadTrafficTrace(tracefilepath, 3);
            testCase.verifyEqual(any(isnan(trafficTrace.D)), false);
        end
 
    end
end
