% Simplified scenario to use WilabV2Xsim
% Packet size and MCS are set accordingly to utilize the whole channel
% Each transmission uses all the subchannels available.
% NR-V2X is considered for these simulations

% WiLabV2Xsim('help')

close all    % Close all open figures
clear        % Reset variables
clc          % Clear the command window

packetSize=1000;        % 1000B packet size
nTransm=1;              % Number of transmission for each packet
sizeSubchannel=10;      % Number of Resource Blocks for each subchannel
Raw = 50;               % Range of Awarness for evaluation of metrics
speed=70;               % Average speed
speedStDev=7;           % Standard deviation speed
SCS=15;                 % Subcarrier spacing [kHz]
pKeep=0.4;              % keep probability
periodicity=0.1;        % periodic generation every 100ms
sensingThreshold=-126;  % threshold to detect resources as busy

% Configuration file
configFile = 'test_trace.cfg';


%% NR-V2X PERIODIC GENERATION
BandMHz = 10;
MCS = 11;
rho = 100;              % number of vehicles/km
simTime=10;             % simTime=300

% related path, change your related path below
path_task = fileparts(mfilename("fullpath"));
dirTraceFile = fullfile(fileparts(path_task), "TrafficTraces", "Bologna", "BolognaAPositions.txt");
outputFolder = fullfile(path_task, 'Output', 'test_trace');

% Launches simulation
% WiLabV2Xsim(configFile,...
%     'outputFolder',outputFolder, "filenameTrace", dirTraceFile,...
%     'Technology','5G-V2X', 'MCS_NR',MCS, 'SCS_NR',SCS, 'beaconSizeBytes',packetSize,...
%     'simulationTime',simTime, 'probResKeep',pKeep, 'BwMHz',BandMHz,...
%     'cv2xNumberOfReplicasMax',nTransm,...
%     'allocationPeriod',periodicity, 'sizeSubchannel',sizeSubchannel,...
%     'powerThresholdAutonomous',sensingThreshold, 'Raw',Raw,'FixedPdensity',false,...
%     'dcc_active',false,'cbrActive',true)

% Launches simulation of IEEE 802.11p
WiLabV2Xsim(configFile,...
    'outputFolder',outputFolder, "filenameTrace", dirTraceFile,...
    'Technology','80211p', 'MCS_11p',7, 'beaconSizeBytes',packetSize,...
    'simulationTime',simTime, 'BwMHz',BandMHz,...
    'allocationPeriod',periodicity, ...
    'Raw',Raw,...
    'dcc_active',false,'cbrActive',true)



