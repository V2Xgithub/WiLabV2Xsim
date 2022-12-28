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
path_output = fullfile(path_task, 'Output', 'data_fig_9');


%% Simulation for different SCS
% Configuration file
configFile = 'fig9_config.cfg';

simTime = 10; % simulation time 
nTransm=1; % Number of transmission for each packet
sizeSubchannel=10; % Number of Resource Blocks for each subchannel
Raw = 150; % Range of Awarness for evaluation of metrics
rho = 100; % density of vehicles
speed=70; % Average speed
speedStDev=7; % Standard deviation speed
pKeep=0.4; % keep probability
periodicity=0.1; % RRI 
% generationInterval = 0.1; % periodic generation every 100 ms (default)
BandMHz=10;

SCS = 15;
nDMRS = 24;

M_values = [1, 0.5, 0.2];
thresholds = [-126, -110]; % threshold to detect resources as busy
pSizes = [350, 1000]; % 350B packet size

for i_m = 1:length(M_values)
    for i_thr = 1:length(thresholds)
        for i_ps = 1:length(pSizes)
            if pSizes(i_ps) == 350
                MCS = 4;
            else
                MCS = 11;
            end
            outputsubfolder = sprintf("M_%d_thr__%d_dBm_psize_%d", ...
                100*M_values(i_m), abs(thresholds(i_thr)), pSizes(i_ps));
            WiLabV2Xsim(configFile,'CheckVersion', version_fit,...
                'simulationTime',simTime,...
                'rho',rho,'vMean',speed,'vStDev',speedStDev,...
                'beaconSizeBytes',pSizes(i_ps),'allocationPeriod',periodicity,'Raw',Raw,...
                'Technology','5G-V2X','MCS_NR',MCS,'SCS_NR',SCS,'nDMRS_NR',nDMRS,...
                'probResKeep',pKeep,'BwMHz',BandMHz,'sizeSubchannel',sizeSubchannel,...
                'cv2xNumberOfReplicasMax',nTransm,...
                'powerThresholdAutonomous',thresholds(i_thr),'FixedPdensity',true,...
                'testMBest_5G', M_values(i_m),...
                'dcc_active',false,'cbrActive',true,...
                'outputFolder',fullfile(path_output,outputsubfolder),...
                'Message', sprintf("Simulation: %s is running", outputsubfolder));
        end
    end
end