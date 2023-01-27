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
path_output = fullfile(path_task, 'Output', 'data_fig_7');


%% Simulation for different SCS
% Configuration file
configFile = 'fig7_config.cfg';

simTime = 10; % simulation time
packetSize=350; % 350B packet size
nTransm=1; % Number of transmission for each packet
sizeSubchannel=10; % Number of Resource Blocks for each subchannel
Raw = 150; % Range of Awarness for evaluation of metrics
rho = 100; % density of vehicles
speed=70; % Average speed
speedStDev=7; % Standard deviation speed
pKeep=0.4; % keep probability
periodicity=0.1; % RRI 
% generationInterval = 0.1; % periodic generation every 100 ms (default)
sensingThreshold=-126; % threshold to detect resources as busy
BandMHz=10;

SCS = [15, 30, 60];
nDMRS = [24, 18, 12];

haveIBE = [true, false];  
IBE_name = ["true", "false"];

for i_SCS = 1:length(SCS)
    for i_IBE = 1:length(haveIBE)           
        if SCS(i_SCS) == 60 && haveIBE(i_IBE) == 1  % situation not considered
            continue;
        end
        outputsubfolder = sprintf("SCS_%d_IBE_%s", SCS(i_SCS), IBE_name(i_IBE));
        WiLabV2Xsim(configFile,'CheckVersion', version_fit,...
            'simulationTime',simTime,...
            'rho',rho,'vMean',speed,'vStDev',speedStDev,...
            'beaconSizeBytes',packetSize,'allocationPeriod',periodicity,'Raw',Raw,...
            'Technology','5G-V2X','MCS_NR',21,'SCS_NR',SCS(i_SCS),'nDMRS_NR',nDMRS(i_SCS),...
            'probResKeep',pKeep,'BwMHz',BandMHz,'sizeSubchannel',sizeSubchannel,...
            'cv2xNumberOfReplicasMax',nTransm,'haveIBE',haveIBE(i_IBE),...
            'powerThresholdAutonomous',sensingThreshold,'FixedPdensity',true,...
            'dcc_active',false,'cbrActive',true,...
            'outputFolder',fullfile(path_output,outputsubfolder),...
            'Message', sprintf("Simulation: %s is running", outputsubfolder));
    end
end