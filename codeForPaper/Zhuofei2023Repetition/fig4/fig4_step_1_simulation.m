%% init
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

configFile = 'fig4_config.cfg';


%% set parameters for paralle simulation
density = [1:10,12:2:30,40:20:100];
ch_model = [0, 3];      % [winner+ B1, ECC rural]
repNumbers = 1:4;       % statistic repetition number
p_ch = [];
p_roadL = [];
p_dens = [];
p_repNum = [];
p_psize = [];
p_outfolder = [];

for ch = ch_model
    for dens_kms = density
        % the lower density, the more simulations need to be repeat
        % here for quick check, only set 1 times
        if dens_kms <= 10
            times = 1;          % 450
        elseif dens_kms <= 30
            times = 1;          % 250
        else
            times = 1;          % 20
        end

        if ch == 0
            roadLength = 2000; 
            dens = dens_kms;
        elseif ch == 3
            roadLength = 8000;
            dens = dens_kms./4;
        end

        for repNum = repNumbers
            for t = times
                p_ch = [p_ch, ch];
                p_roadL = [p_roadL, roadLength];
                p_dens = [p_dens, dens];
                p_repNum = [p_repNum, repNum];
                p_outfolder = [p_outfolder;...
                    fullfile(path_output,...
                    sprintf("ch_%d_replicate_%d_dens_%.2f",ch, repNum, dens),...
                    sprintf("sim_%d", t))];
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

    % start simulation
    WiLabV2Xsim(configFile, 'seed', 0,...
        'rho', p_dens(i), 'roadLength', p_roadL(i),...
        'ITSNumberOfReplicasMax', p_repNum(i),...
        'folderPERcurves', path_PERcurves, 'channelModel',p_ch(i),...
        'outputFolder', p_outfolder(i)); 
end
