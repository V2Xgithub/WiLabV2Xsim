%% init
%% was running on Giammarco's computer
close all       % Close all open figures
clear           % Reset variables
clc             % Clear the command window
path(pathdef);  % Reset Matlab path

path_task = fileparts(mfilename('fullpath'));
path_sim = fileparts(fileparts(fileparts(path_task)));
addpath(genpath(path_sim));
rmpath(genpath(fullfile(path_sim, "codeForPaper")));
addpath(path_task);

path_PERcurves	= fullfile(path_sim,"PERcurves", "G5-HighwayLOS");
path_output = fullfile(path_task, "mataData");


%% set parameters for paralle simulation
configFile = 'fig5_config.cfg';
density = flip([1:10,12:2:30,40:20:100]);

% NOTE: The threshold index here is inversed compared with the paper
% if replicate type is 0, thresholds would be ignored
thre1 = 0.03;       % threshold 3 in paper
thre2 = 0.05;       % threshold 2 in paper
thre3 = 0.09;       % threshold 1 in paper

ch_model = [0, 3];          % [winner+ B1, ECC rural]
repType = [0,1,2];            % [0,1,2]: [static, deterministic, probabilistic]
p_ch = [];
p_roadL = [];
p_dens = [];
p_reptype = [];
p_repnum = [];
p_outfolder = [];

for ch = ch_model       
    for rType = repType
        if rType == 0
            repNumbers = 1:4;
        else
            repNumbers = 4;
        end
        for replicate = repNumbers
            for dens_km = density
                if dens_km <= 10
                    times = 1;          % 300
                elseif dens_km <= 30
                    times = 1;          % 150
                else
                    times = 1;          % 20
                end
    
                if ch == 0
                    roadLength = 2000; 
                    dens = dens_km;
                elseif ch == 3
                    roadLength = 8000;
                    dens = dens_km/4;
                end
    
                for t = 1:times
                    p_ch = [p_ch, ch];
                    p_roadL = [p_roadL, roadLength];
                    p_dens = [p_dens, dens];
                    p_reptype = [p_reptype, rType];
                    p_repnum = [p_repnum, replicate];
                    scenario = sprintf("ch_%d_rType_%d_replicate_%d_dens_%.2f",...
                        ch, rType, replicate, dens);
                    p_outfolder = [p_outfolder;...
                        fullfile(path_output, scenario,...
                        sprintf("sim_%d", t))];
                end
            end
        end
    end
end
           

%% simulation
par_num = length(p_ch);
parfor i = 1:par_num
    % if not complete at last time, remove files and restart
    if exist(p_outfolder(i), "dir") 
        if ~exist(fullfile(p_outfolder(i), "MainOut.xls"), "file")
            rmdir(p_outfolder(i),"s");
        else
            continue;
        end
    end

    WiLabV2Xsim(configFile, 'seed', 0,...
        'rho', p_dens(i), 'roadLength', p_roadL(i),...
        'retransType', p_reptype(i), 'ITSNumberOfReplicasMax', p_repnum(i),...
        'ITSReplicasThreshold1', thre1, 'ITSReplicasThreshold2', thre2,...
        'ITSReplicasThreshold3', thre3,...
        'folderPERcurves', path_PERcurves,'channelModel',p_ch(i),...
        'outputFolder', p_outfolder(i)); 
end
