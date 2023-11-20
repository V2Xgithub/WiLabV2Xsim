classdef TestInitVehiclePositionsForHighway < matlab.unittest.TestCase
    properties (TestParameter)
        rho = {50, 100, 200};
        vMean = {30 80 120};
        vStdDev = {0 10 20};
        nLanes = {1 2 3};
        roadLength = {1000 2000 300};
        laneWidth = {5 10 15};
        laneGap = {0 5 10};
    end
    methods (Test)
        function testFunctionReturnsATableWithFourColumns(testCase, rho, vMean, vStdDev, nLanes, roadLength, laneWidth, laneGap)
            [positions, ~] = initVehiclePositionsForHighway("rho", rho, "vMean", vMean, "vStdDev", vStdDev, "nLanes", nLanes, "roadLength", roadLength, ...
                "laneWidth", laneWidth, "laneGap", laneGap);
            testCase.verifyClass(positions, ?table);
            testCase.verifyEqual(width(positions), 4);
            testCase.verifyTrue(all(ismember(["X" "Y" "V" "D"], positions.Properties.VariableNames)));
        end
        function testVehiclesOnlyMoveInTwoDirections(testCase, rho, vMean, vStdDev, nLanes, roadLength, laneWidth, laneGap)
            [positions, ~] = initVehiclePositionsForHighway("rho", rho, "vMean", vMean, "vStdDev", vStdDev, "nLanes", nLanes, "roadLength", roadLength, ...
                "laneWidth", laneWidth, "laneGap", laneGap);
            testCase.verifyEqual(numel(unique(positions.D)), 2);
        end

        function testVStdDevProducesVariance(testCase, rho, vMean, vStdDev, nLanes, roadLength, laneWidth, laneGap)
            if vStdDev == 0
                return
            end
            [positions, ~] = initVehiclePositionsForHighway("rho", rho, "vMean", vMean, "vStdDev", vStdDev, "nLanes", nLanes, "roadLength", roadLength, ...
                "laneWidth", laneWidth, "laneGap", laneGap);
            measured_vStdDev = std(positions.V);
            testCase.verifyTrue(ismembertol(measured_vStdDev, vStdDev, 50));
        end

        function testVehiclesStayInLane(testCase, rho, vMean, vStdDev, nLanes, roadLength, laneWidth, laneGap)
            [positions, ~] = initVehiclePositionsForHighway("rho", rho, "vMean", vMean, "vStdDev", vStdDev, "nLanes", nLanes, "roadLength", roadLength, ...
                "laneWidth", laneWidth, "laneGap", laneGap);
            vehicles_within_lane = 0;
            for i = 1:(nLanes*2)
                expected_Ymin = (i-1)*laneWidth + (i-1)*laneGap;
                expected_Ymax = expected_Ymin + laneWidth;
                rf = rowfilter(positions);
                vehicles_in_this_lane = height(positions(rf.Y > expected_Ymin & rf.Y < expected_Ymax, :));
                vehicles_within_lane = vehicles_within_lane + vehicles_in_this_lane;
            end
            testCase.verifyEqual(vehicles_within_lane, height(positions));
        end

        function testExpectedNumberOfVehicles(testCase, rho, vMean, vStdDev, nLanes, roadLength, laneWidth, laneGap)
            [positions, ~] = initVehiclePositionsForHighway("rho", rho, "vMean", vMean, "vStdDev", vStdDev, "nLanes", nLanes, "roadLength", roadLength, ...
                "laneWidth", laneWidth, "laneGap", laneGap);
            actual_number_of_vehicles = height(positions);
            expected_number_of_vehicles = roadLength / 1000 * rho;
            testCase.verifyTrue(ismembertol(actual_number_of_vehicles, expected_number_of_vehicles, 1));
        end

        function testvMeanIsConvertedToMetersPerSecond(testCase, rho, vMean, vStdDev, nLanes, roadLength, laneWidth, laneGap)
            if vStdDev ~= 0
                return
            end
            [positions, ~] = initVehiclePositionsForHighway("rho", rho, "vMean", vMean, "vStdDev", vStdDev, "nLanes", nLanes, "roadLength", roadLength, ...
                "laneWidth", laneWidth, "laneGap", laneGap);
            actual_v = unique(positions.V);
            expected_v = vMean * (5/18);
            testCase.verifyTrue(ismembertol(actual_v, expected_v));
        end
    end
end
