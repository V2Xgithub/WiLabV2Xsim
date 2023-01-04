close all % Close all open figures
clear % Reset variables
clc % Clear the command window

%% init simulator and path
% path of simulation task
version_fit = "V6.2";  % simulator V6.2 is needed
path_task = fileparts(mfilename('fullpath'));
addpath(path_task);

% path of simulator
path_simulator = fileparts(fileparts(path_task));
addpath(genpath(path_simulator));

% path of output
path_output = fullfile(path_task, 'Output', 'data_fig_11');


%% Simulation for different SCS
% Configuration file
configFile = 'fig11_config.cfg';

simTime = 10; % simulation time
nTransm=1; % Number of transmission for each packet
sizeSubchannel=10; % Number of Resource Blocks for each subchannel
Raw = 150; % Range of Awarness for evaluation of metrics
rho = 100; % density of vehicles
speed=70; % Average speed
speedStDev=7; % Standard deviation speed
pKeep=0.4; % keep probability
BandMHz=10;
SCS = 15;
nDMRS = 24;
thresholds = -126; % threshold to detect resources as busy
pSizes = 350; % 350B packet size
MCS = 4;
avgRSRPin5G = [true, false];
co_arrivals = [true, false];

generationInterval = 0.2; % periodic generation every 100 ms (default)
M_values = [1, 0.2];

for M = M_values
    for avgRSRP = avgRSRPin5G
        for coarri = co_arrivals
            if coarri
                if M == 0.2 || avgRSRP  % condition not considered
                    continue;
                end
                allocationPeriod=0.2; % RRI
            else
                allocationPeriod=0.1; % RRI
            end
            outputsubfolder = sprintf("M_%d_avgRSRP_%d_coherentArrival_%d",100*M,avgRSRP,coarri);
            WiLabV2Xsim(configFile,'CheckVersion', version_fit,...
                'simulationTime',simTime,...
                'rho',rho,'vMean',speed,'vStDev',speedStDev,...
                'beaconSizeBytes',pSizes,'allocationPeriod',allocationPeriod,...
                'generationInterval',generationInterval,'Raw',Raw,...
                'Technology','5G-V2X','MCS_NR',MCS,'SCS_NR',SCS,'nDMRS_NR',nDMRS,...
                'probResKeep',pKeep,'BwMHz',BandMHz,'sizeSubchannel',sizeSubchannel,...
                'cv2xNumberOfReplicasMax',nTransm,...
                'powerThresholdAutonomous',thresholds,'FixedPdensity',true,...
                'testMBest_5G', M,'avgRSRPin5G',avgRSRP,...
                'dcc_active',false,'cbrActive',true,...
                'outputFolder',fullfile(path_output,outputsubfolder),...
                'Message', sprintf("Simulation: %s is running", outputsubfolder));

        end
    end
end