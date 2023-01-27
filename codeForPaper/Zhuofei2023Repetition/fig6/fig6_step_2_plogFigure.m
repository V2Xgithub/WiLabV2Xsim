%% init
close all       % Close all open figures
clear           % Reset variables
clc             % Clear the command window
path(pathdef);  % Reset Matlab path
path_task = fileparts(mfilename('fullpath'));

%% ========
dataFolder = "originalData";            % or "mataData"
%% ========
path_data = fullfile(path_task, dataFolder);

%% init figure
time_range = 101:200;       % point step is 0.1 s
fig = tiledlayout("flow","TileSpacing","tight");

color_space =   [246,107,23;
                174,249,55;
                37,192,230;
                34,12,54] ./ 255; 
x_range_max = 15;
x_range_min = 13;
y_range_max = 1900;
y_range_min = 1800;
bg_range_x = [x_range_min,x_range_max,x_range_max,x_range_min,x_range_min];
bg_range_y = [y_range_min,y_range_min,y_range_max,y_range_max,y_range_min];

%% full pictures
for rType = [1 2]
    nexttile([2,1])
    hold on;
    if rType == 1
        repName = "Deterministic";
    else
        repName = "Probabilistic";
    end
    repNum = 4;
    folderName = fullfile(path_data, sprintf("rType_%d", rType));
    data(rType) = load(fullfile(folderName, '_log_replications_1_80211p.mat'));
    repetitionLog = data(rType).ITSReplicasLog(:,time_range)-1;
    positionLog = data(rType).positionLog(:,time_range);
    for vID = 1:size(repetitionLog,1)
        for i_rep = 0:3
            i_p = repetitionLog(vID,:) == i_rep;
            scatter(time_range(i_p)./10, positionLog(vID,i_p), 5, color_space(i_rep+1,:), 'filled');
        end
    end
    mean_rep = mean(repetitionLog,"all");
    title(sprintf("%s",repName));
    xlabel('Simulation time [s]');
    if rType == 1
        ylabel('Vehicle location [m]');
    end
    line(bg_range_x, bg_range_y, 'LineWidth',1.5, 'color', [255,0,0]./255);
    ylim([0, 2000]);
end

%% zoomed
markers = ["^", "diamond", "square", "o"];
for rType = [1 2]
    nexttile
    hold on;
    if rType == 1
        repName = "Deterministic, zoomed";
    else
        repName = "Probabilistic, zoomed";
    end
    repNum = 4;
    folderName = fullfile(path_data, sprintf("rType_%d", rType));
    data(rType) = load(fullfile(folderName, '_log_replications_1_80211p.mat'));
    repetitionLog = data(rType).ITSReplicasLog(:,time_range)-1;
    positionLog = data(rType).positionLog(:,time_range);
    for vID = 1:size(repetitionLog,1)
        for i = 0:3
            i_p = repetitionLog(vID,:) == i;
            scatter(time_range(i_p)./10, positionLog(vID,i_p), 20+i*20, color_space(i+1,:), 'filled',markers(i+1));
        end
    end
    mean_rep = mean(repetitionLog,"all");
    title(sprintf("%s",repName));
    xlabel('Simulation time [s]');
    if rType == 1
        ylabel('Vehicle location [m]');
    end

    ylim([y_range_min, y_range_max]);
    xlim([x_range_min, x_range_max]);
end

%% for legend
for i = 0:3
    if i == 1
        legendName = sprintf("%d repetition",i);
    else
        legendName = sprintf("%d repetitions",i);
    end
    h(i+1) = scatter(min(time_range./10),2001, 7,color_space(i+1,:),"filled", markers(i+1),"DisplayName",legendName);
end

lgnd = legend(h,'NumColumns',4,'box','off','Orientation', 'Horizontal');
lgnd.Layout.Tile = 'north';

saveas(fig,fullfile(path_task,"fig_compare_loc_rep_allin1.png"));
