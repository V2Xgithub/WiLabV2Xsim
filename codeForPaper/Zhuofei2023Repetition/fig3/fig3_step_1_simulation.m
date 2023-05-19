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

configFile = 'fig3_config.cfg';


%% set parameters for paralle simulation
repNumbers = 1:4;
times = 30;                             % repeat simulation
sensitivity = [-100, -103, -120];       % preamble detection threshold
p_repNum = [];
p_sens = [];
p_outfolder = [];
for sens = sensitivity
    for t = 1:times
        for repNum = repNumbers
            p_repNum = [p_repNum, repNum];
            p_sens = [p_sens, sens];
            p_outfolder = [p_outfolder;...
                fullfile(path_output,...
                sprintf("replicate_%d_sensitivity__%d", repNum, abs(sens)),...
                sprintf("sim_%d",t))];
        end
    end
end


%% simulation
par_num = length(p_repNum);     % total simualtion numbers
parfor i = 1:par_num            % if not work, use "for" instead of "parfor"
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
        'ITSNumberOfReplicasMax', p_repNum(i),...
        'sensitivity11p_dBm', p_sens(i),...
        'folderPERcurves', path_PERcurves,...
        'outputFolder', p_outfolder(i)); 
end


