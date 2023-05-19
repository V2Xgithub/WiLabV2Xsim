% init env
close all    % Close all open figures
clear        % Reset variables
clc          % Clear the command window

% add path of the simulator and the code of this paper
path(pathdef);  % Reset Matlab path
path_task = fileparts(mfilename("fullpath"));
path_code = fileparts(path_task);
path_simulator = fileparts(fileparts(path_code));
addpath(genpath(path_simulator));
rmpath(genpath(fileparts(path_code)));
addpath(genpath(path_task));


%% fixed params
dens = 0.5:0.5:6; % cars per lane per km
Raw = [50, 150, 300, 500];
dens_km = dens * 6; % dens per km
roadLength = 8; % km
ratio_lte = 1/3;
v_lte = ceil(dens_km * ratio_lte * roadLength); 
v_11p = roadLength*dens_km - v_lte;

%% variable params
varTs = 0;   % variabilityTbeacon, [0, -1]
sTime = 120;    % simulation time
computer_name = "felix_1_3_lte";
dataSize = 350;

Methods = ["no_method", "enhanced_A", "method_B", "dynamic_C", "method_F", "dynamic_C_preamble"];

p_method = [];
p_dens = [];
p_vgi = [];
p_n_vgi = [];
p_v_lte = [];
p_v_11p = [];
p_stop_times = [];
p_sim_ids = [];
p_configFile = [];
p_outputF = [];
for tot_time = 1:50
    for i_d = 1:length(dens_km)
        if dens_km(i_d) < 10
            stop_times = 20;
        elseif dens_km(i_d) < 20
            stop_times = 10;
        elseif dens_km(i_d) <= 30
            stop_times = 5;
        else
            stop_times = 2;
        end
        if tot_time > stop_times
            continue;
        end
        for VGI = varTs
            if VGI == -1
                n_vgi = "CAM";
            else
                n_vgi = "period";
            end
            for method = Methods
                p_method = [p_method, method];
                p_dens = [p_dens, dens_km(i_d)];
                p_n_vgi = [p_n_vgi, n_vgi];
                p_vgi = [p_vgi, VGI];
                p_v_11p = [p_v_11p, v_11p(i_d)];
                p_v_lte = [p_v_lte, v_lte(i_d)];
                p_sim_ids = [p_sim_ids, tot_time];
                p_configFile = [p_configFile; convertCharsToStrings(fullfile(path_task, sprintf('wp_%s.cfg',method)))];
                outfolder = fullfile(fileparts(path_task), "dataNewSetting", computer_name,...
    method, sprintf("dens_%d_vgi_%s", dens_km(i_d), n_vgi));
                p_outputF = [p_outputF; outfolder];
            end
        end
    end
end

parfor i = 1:length(p_dens)
    % if not complete at last time, remove files and restart
    if exist(fullfile(p_outputF(i), sprintf("sim_%d", p_sim_ids(i))), "dir") 
        if ~exist(fullfile(p_outputF(i), sprintf("sim_%d", p_sim_ids(i)), "MainOut.xls"), "file")
            rmdir(fullfile(p_outputF(i), sprintf("sim_%d", p_sim_ids(i))),"s");
        else
            continue;
        end
    end
    if strcmp(p_method(i), "only_NR")
        WiLabV2Xsim(p_configFile(i), ...
            'simulationTime', sTime, 'rho', p_dens(i), 'roadLength', roadLength*1000,...
            'Raw', Raw, ...
            'variabilityGenerationInterval', p_vgi(i), 'beaconSizeBytes', dataSize,...
            'printWirelessBlindSpotProb', true, 'printUpdateDelay', true,...
            'printPacketDelay', true, 'printDataAge', true,...
            'message', sprintf("dens: %d, VGI: %d, method: %s", p_dens(i), p_vgi(i), p_method(i)),...
            'outputFolder', fullfile(p_outputF(i), sprintf("sim_%d", p_sim_ids(i))));
    elseif strcmp(p_method(i), "only_ITS")
        WiLabV2Xsim(p_configFile(i),...
            'simulationTime', sTime, 'rho', p_dens(i),  'roadLength', roadLength*1000,...
            'Raw', Raw,...
            'variabilityGenerationInterval', p_vgi(i), 'beaconSizeBytes', dataSize,...
            'printWirelessBlindSpotProb', true, 'printUpdateDelay', true,...
            'printPacketDelay', true, 'printDataAge', true,...
            'message', sprintf("dens: %d, VGI: %d, method: %s", p_dens(i), p_vgi(i), p_method(i)),...
            'outputFolder', fullfile(p_outputF(i), sprintf("sim_%d", p_sim_ids(i))));
    else
        WiLabV2Xsim(p_configFile(i),...
            'simulationTime', sTime, 'rho', p_dens(i), 'roadLength', roadLength*1000,...
            'Raw', Raw, ...
            'variabilityGenerationInterval', p_vgi(i), 'beaconSizeBytes', dataSize,...
            'numVehiclesLTE', p_v_lte(i), 'numVehicles11p', p_v_11p(i),...
            'printWirelessBlindSpotProb', true, 'printUpdateDelay', true,...
            'printPacketDelay', true, 'printDataAge', true,...
            'message', sprintf("dens: %d, VGI: %s, method: %s\n", p_dens(i), p_n_vgi(i), p_method(i)),...
            'outputFolder', fullfile(p_outputF(i), sprintf("sim_%d", p_sim_ids(i))));
    end
end


