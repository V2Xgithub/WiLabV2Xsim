%% init
close all    % Close all open figures
clear        % Reset variables
clc          % Clear the command window
path(pathdef);  % Reset Matlab path
path_task = fileparts(mfilename('fullpath'));
addpath(path_task);

color_space =   [27,158,119;
                217,95,2;
                117,112,179;
                231,41,138;
                102,166,30;
                230,171,2] ./ 255;   % dark green, additional method

repType = 0;
ch = 0;
psize = 350;
repNumbers = 1:4;

%% init figure
fig = figure();
grid on;
xlabel('Distance [m]');
ylabel('Packet reception ratio (PRR)');
hold on;
ylim([0, 1.05]);


%% not cumulate preamble
density = 5;
load(fullfile(path_task, sprintf("data_prr_dis_psize_%d_cumPre_F.mat",psize)));
for repNum = repNumbers
    data_name = sprintf("rType_%d_replicate_%d_dens_%d_cumPre_F", repType, repNum, density);
    data_temp = data.(data_name);
    if repNum == 2
        legend_name = "1 repetition, w/ preamble";
    else
        legend_name = sprintf("%d repetitions, w/ preamble", repNum-1);
    end
    
    plot(data_temp(:,1), mean(data_temp(:,2:end),2), 'Color', color_space(repNum,:),...
        'linestyle', '-', 'LineWidth', 1.5, 'DisplayName', legend_name);
end


%% cumulate preamble
load(fullfile(path_task, sprintf("data_prr_dis_psize_%d_cumPre_T.mat",psize)));
for repNum = repNumbers
    data_name = sprintf("rType_%d_replicate_%d_dens_%d_cumPre_T", repType, repNum, density);
    data_temp = data.(data_name);
    if repNum == 2
        legend_name = "1 repetition, w/o preamble";
    else
        legend_name = sprintf("%d repetitions, w/o preamble", repNum-1);
    end
    
    plot(data_temp(:,1), mean(data_temp(:,2:end),2), 'Color', color_space(repNum,:),...
        'linestyle','--', 'LineWidth', 1.5, 'DisplayName', legend_name);
end

%% save fig
figure(fig);
lgnd = legend('Location','southwest');
set(lgnd.BoxFace, 'ColorType', 'truecoloralpha', 'ColorData', uint8([255;255;255;0.5*255]));
saveas(fig, fullfile(path_task, sprintf("fig_distance_vs_prr_psize_%d_10Hz_compare.png",psize)));
% saveas(fig, fullfile(path_figures, sprintf("fig_distance_vs_prr_psize_%d_10Hz_compare.fig",psize)));

% close(fig);