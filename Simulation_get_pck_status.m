

close all    % Close all open figures
clear        % Reset variables
clc          % Clear the command window



%% 部分设置
packetSize=350;                     % packet size [KB]
BandMHz = 10;                       % [MHz]
rho = 0.1;                          % density [vehs/m]
rho_km = rho * 1000;                % density [vehs/km]
speed=(43.14-197.5*rho) * 3.6;      % Average speed [km/h]
speedStDev= speed/10;               % Standard deviation speed [km/h]
simTime = 60;                       % simulation time [s]

%% 其余设置见两个配置文件
% only_NR.cfg
% only_ITS.cfg


%% NR-V2X simulation
% Configuration file
configFile = 'only_NR.cfg';
outputFolder = sprintf('Output/NRV2X/rho%d_v_km',rho_km);

% Launches simulation
WiLabV2Xsim(configFile,'outputFolder',outputFolder,'beaconSizeBytes',packetSize, ...
    'simulationTime',simTime,'rho',rho_km,'vMean',speed,'vStDev',speedStDev, ...
    'printPacketReceptionStatusAll', true);

%% IEEE 802.11p simulations
% Configuration file
configFile = 'only_ITS.cfg';
outputFolder = sprintf('Output/ITS/rho%d_v_km',rho_km);

% Launches simulation
WiLabV2Xsim(configFile,'outputFolder',outputFolder,'beaconSizeBytes',packetSize, ...
    'simulationTime',simTime,'rho',rho_km,'vMean',speed,'vStDev',speedStDev, ...
    'printPacketReceptionStatusAll', true);



