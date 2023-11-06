classdef IEEE80211p < matlab.unittest.TestCase
    methods (Test)

        function testExample(testCase)
            packetSize = 1000;        % 1000B packet size
            nTransm = 1;              % Number of transmission for each packet
            Raw = [50, 150, 300];   % Range of Awarness for evaluation of metrics
            speed = 70;               % Average speed
            speedStDev = 7;           % Standard deviation speed
            periodicity = 0.1;        % periodic generation every 100ms
            configFile = 'Highway3GPP.cfg';
            BandMHz = 10;
            simTime = 3;
            % HD periodic
            outputFolder = fullfile(tempdir, "v2xsim_tests", "smoke", "IEEE_80211p");
            % Launches simulation
            WiLabV2Xsim(configFile, 'outputFolder', outputFolder, 'Technology', '80211p', 'beaconSizeBytes', packetSize, ...
                        'simulationTime', simTime, 'BwMHz', BandMHz, 'vMean', speed, 'vStDev', speedStDev, ...
                        'cv2xNumberOfReplicasMax', nTransm, 'allocationPeriod', periodicity,  ...
                        'Raw', Raw, 'FixedPdensity', false, 'dcc_active', false, 'cbrActive', true);
        end

    end
end
