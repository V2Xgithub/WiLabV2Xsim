classdef LTE_Mode2 < matlab.unittest.TestCase
    methods (Test)

        function testExample(testCase)
            packetSize = 1000;        % 1000B packet size
            nTransm = 1;              % Number of transmission for each packet
            sizeSubchannel = 10;      % Number of Resource Blocks for each subchannel
            Raw = [50, 150, 300];   % Range of Awarness for evaluation of metrics
            speed = 70;               % Average speed
            speedStDev = 7;           % Standard deviation speed
            SCS = 15;                 % Subcarrier spacing [kHz]
            pKeep = 0.4;              % keep probability
            periodicity = 0.1;        % periodic generation every 100ms
            sensingThreshold = -126;  % threshold to detect resources as busy
            configFile = 'Highway3GPP.cfg';
            BandMHz = 10;
            MCS = 11;
            simTime = 3;
            % HD periodic
            outputFolder = fullfile(tempdir, "v2xsim_tests", "smoke", "LTE_mode2");
            % Launches simulation
            WiLabV2Xsim(configFile, 'outputFolder', outputFolder, 'Technology', 'LTE-V2X', 'MCS_LTE', MCS, 'beaconSizeBytes', packetSize, ...
                        'simulationTime', simTime, 'probResKeep', pKeep, 'BwMHz', BandMHz, 'vMean', speed, 'vStDev', speedStDev, ...
                        'cv2xNumberOfReplicasMax', nTransm, 'allocationPeriod', periodicity, 'sizeSubchannel', sizeSubchannel, ...
                        'powerThresholdAutonomous', sensingThreshold, 'Raw', Raw, 'FixedPdensity', false, 'dcc_active', false, 'cbrActive', true);
        end

    end
end
