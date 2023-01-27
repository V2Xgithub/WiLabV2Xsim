%% init
close all    % Close all open figures

path(pathdef);  % Reset Matlab path
path_task = fileparts(mfilename('fullpath'));
path_readData = fullfile(path_task, 'readData');

% load data
load(fullfile(path_readData, "data_prr_vs_distance.mat"));

% figure settings
color_space =   [27,158,119;
                217,95,2;
                117,112,179;
                231,41,138;
                102,166,30;
                230,171,2] ./ 255;   % dark green, additional method
markers = ["^", "diamond", "square", "o"];

repNumbers = 1:4;
sensitivity = [-100, -103];

for sens = sensitivity
    % init figure
    fig = figure();
    grid on;
    hold on;
    
    % Compared preamble detectioin
    for repNum = repNumbers
        data_name = sprintf("replicate_%d_sensitivity__%d", repNum, abs(sens));
        data_temp = data.(data_name);

        legend_name = sprintf("%d rep., %d dBm", repNum-1, sens);
        data_prr = mean(data_temp(:,2:end),2);
        plot(data_temp(:,1), data_prr, 'Color', color_space(repNum,:),...
            'linestyle', '-', 'LineWidth', 1.5, 'HandleVisibility','on',...
            'Marker',markers(repNum),'MarkerIndices',(10:10:length(data_prr)),...
            'MarkerFaceColor',color_space(repNum,:), 'DisplayName',legend_name);   
    end
    
    % plot ideal preamble detection (with -120 dBm)
    for repNum = repNumbers
        data_name = sprintf("replicate_%d_sensitivity__%d", repNum, 120);
        data_temp = data.(data_name);

        legend_name = sprintf("%d rep., ideal", repNum-1);
        data_prr = mean(data_temp(:,2:end),2);
        plot(data_temp(:,1), data_prr, 'Color', color_space(repNum,:),...
            'linestyle', '--', 'LineWidth', 1.5, 'HandleVisibility','on',...
            'Marker',markers(repNum),'MarkerIndices',(5:10:length(data_prr)),...
            'MarkerFaceColor','none', 'DisplayName',legend_name);
    end

    % plot arrows
    annotation('arrow',[0.4, 0.65],[0.6,0.7],Color=[0,0,0],LineWidth=1.5,LineStyle='--');
    annotation('arrow',[0.41, 0.66],[0.59,0.69],Color=[0,0,0],LineWidth=1.5,LineStyle='-');
    text(620, 0.8, "$From ~ 0 ~ to ~ 3 ~ rep.$","FontSize",12, Interpreter="latex");

    xlabel('Distance [m]');
    ylabel('Packet reception ratio (PRR)');
    ylim([0, 1.05]);
    title(sprintf("Preamble detection at %d dBm", sens));

    % save fig
    lgnd = legend('Location','southwest');
    set(lgnd.BoxFace, 'ColorType', 'truecoloralpha', 'ColorData', uint8([255;255;255;0.5*255]));
    saveas(fig, fullfile(path_task, sprintf("fig_compare_preamble_ideal_and_%d_dbm.png",abs(sens))));
end
