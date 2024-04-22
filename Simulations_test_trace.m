% Simplified scenario to use WilabV2Xsim
% Packet size and MCS are set accordingly to utilize the whole channel
% Each transmission uses all the subchannels available.
% NR-V2X is considered for these simulations

% WiLabV2Xsim('help')

close all    % Close all open figures
clear        % Reset variables
clc          % Clear the command window

% Configuration file
configFile = 'Bologna.cfg';

% Launches simulation
WiLabV2Xsim(configFile,...
    'cbrActive',false);
