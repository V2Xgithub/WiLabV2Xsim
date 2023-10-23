function tests = test_addPosDelay
    % only include functions that begin with the name "test"
    idx = cellfun(@(f) startsWith(func2str(f), 'test'), localfunctions);
    fs = localfunctions;
    tests = functiontests(fs(idx));
end

function testNoDelay(testCase)
    % test that if the posDelay is 0, the positions should not be delayed at
    % all, regardless of the time
    for time_now = [0 1 100]
        [X_real, Y_real] = mockVehiclePositionData(100);
        [X_history, Y_history] = mockVehiclePositionHistory(100);
        [X_est, Y_est, ~, ~] = addPosDelay(X_real, Y_real, X_history, Y_history, time_now, 0, 0);
        verifyEqual(testCase, X_est, X_real);
        verifyEqual(testCase, Y_est, Y_real);
    end
end

function testFiniteDelayReturnsOldestDataForTimesBeforeDelay(testCase)
    % for the edge case where posDelay > 0 and timeNow <= posDelay, assert that
    % the positions returned is always the oldest one
    posDelay = 3;
    [X_init, Y_init] = mockVehiclePositionData(100);
    [X_history, Y_history] = mockVehiclePositionHistory(100);
    [~, ~, X_history, Y_history] = addPosDelay(X_init, Y_init, X_history, Y_history, 0, 3, 0);
    for time_now = linspace(0.1, 2.9, 10)
        [X_real, Y_real] = mockVehiclePositionData(100);
        [X_est, Y_est, X_history, Y_history] = addPosDelay(X_real, Y_real, X_history, Y_history, time_now, posDelay, 0);
        verifyEqual(testCase, X_est, X_init);
        verifyEqual(testCase, Y_est, Y_init);
    end
end

function testFiniteDelayReturnsDelayedData(testCase)
    % eventually, when timeNow > posDelay, return snapshots of positions at least posDelay
    % seconds ago
    posDelay = 3;
    X_real_cell = cell(6, 1);
    Y_real_cell = cell(6, 1);
    for i = 1:6
        [X_t, Y_t] = mockVehiclePositionData(100);
        X_real_cell{i} = X_t;
        Y_real_cell{i} = Y_t;
    end
    [X_history, Y_history] = mockVehiclePositionHistory(100);
    for time_now = 1:6
        X_real = X_real_cell{time_now};
        Y_real = Y_real_cell{time_now};
        [X_est, Y_est, X_history, Y_history] = addPosDelay(X_real, Y_real, X_history, Y_history, time_now, posDelay, 0);
        if time_now > 3
            X_pos_delay_ago = X_real_cell{time_now - posDelay};
            Y_pos_delay_ago = Y_real_cell{time_now - posDelay};
            verifyEqual(testCase, X_est, X_pos_delay_ago);
            verifyEqual(testCase, Y_est, Y_pos_delay_ago);
        end
    end
end

function testNonzeroPacketLossResultsInTimetablesOfVaryingHeights(testCase)
    % When there is packet loss, the height of the history tables should not be
    % the same. Test with 100 vehicles, 50% loss chance, 10 position updates.
    % This test has a very, very small chance of producing a false failure.
    % P(Binomial(100*10, 0.5)=0) = 9.33E-302
    % If this test fails on you, you should probably take a break and ponder
    % what did you do to offend the RNG machines of the universe.
    posDelay = 3;
    [X_history, Y_history] = mockVehiclePositionHistory(100);
    for time_now = linspace(0, 5, 10)
        [X_real, Y_real] = mockVehiclePositionData(100);
        [~, ~, X_history, Y_history] = addPosDelay(X_real, Y_real, X_history, Y_history, time_now, posDelay, 0.5);
    end
    history_table_heights = unique(cellfun(@height, X_history));
    verifyEqual(testCase, numel(history_table_heights) ~= 1, true);
end

function [X, Y] = mockVehiclePositionData(n_vehicles)
    % creates a mock vehicle position data
    arguments
        n_vehicles (1, 1) double {mustBeInteger mustBePositive}
    end
    X = rand(n_vehicles, 1) .* 1000;
    Y = rand(n_vehicles, 1) .* 1000;
end

function [X_history, Y_history] = mockVehiclePositionHistory(n_vehicles)
    % creates mock vehicle position timetable (empty)
    X_history = cell(n_vehicles, 1);
    Y_history = cell(n_vehicles, 1);
    for i = 1:n_vehicles
        X_history{i} = timetable(Size = [0 1], VariableTypes = {'double'}, TimeStep = seconds(0.1));
        Y_history{i} = timetable(Size = [0 1], VariableTypes = {'double'}, TimeStep = seconds(0.1));
    end
end
