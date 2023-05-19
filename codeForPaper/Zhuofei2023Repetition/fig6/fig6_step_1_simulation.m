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
configFile = 'fig6_config.cfg';

% NOTE: The threshold index here is inversed compared with the paper
% if replicate type is 0, thresholds would be ignored
thre1 = 0.03;       % threshold 3 in paper
thre2 = 0.05;       % threshold 2 in paper
thre3 = 0.09;       % threshold 1 in paper
         

%% simulation
for rType = [1,2]
    WiLabV2Xsim(configFile, 'seed', 0,...
        'retransType', rType, 'ITSNumberOfReplicasMax', 4,...
        'ITSReplicasThreshold1', thre1, 'ITSReplicasThreshold2', thre2,...
        'ITSReplicasThreshold3', thre3,...
        'folderPERcurves', path_PERcurves,'channelModel',0,...
        'outputFolder', fullfile(path_output, sprintf("rType_%d",rType))); 
end

