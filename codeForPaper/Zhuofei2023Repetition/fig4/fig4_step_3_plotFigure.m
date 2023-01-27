close all;
path(pathdef);  % Reset Matlab path
path_task = fileparts(mfilename('fullpath'));
path_readData = fullfile(path_task, 'readData');
addpath(path_task);

%% ============ Need to change if you have your own data
readData = load(fullfile(path_readData, "original_two_ch_data.mat"));
%% ============

color_space =   [27,158,119;
                217,95,2;
                117,112,179;
                231,41,138;
                102,166,30;
                230,171,2] ./ 255;   % dark green, additional method

% common settings
dens = [1:9,10:2:30,40:20:100];
threshold = 0.9;  % PRR threshold to get Range


%% init figure
fig = figure();
grid on;
hold on;
xlabel('Net CBR');
markers = ["^", "diamond", "square", "o"];
marker_points = 6;

% left y-axis winner+ B1
yyaxis left;
ylabel(sprintf('Range with Winner+ B1 [m]'));
ch = 0;
ylim([230, 450]);
xlim([0, 0.2]);

h1 = [];
for reptime = 1:4
    data_cbr_plot = [];
    data_dis_plot = [];
    for i_den = 1:length(dens)
        prrDataName = sprintf("PRR_ch_%d_rep_%d_dens_%d", ch, reptime, dens(i_den));
        cbrDataName = sprintf("CBR_ch_%d_rep_%d_dens_%d", ch, reptime, dens(i_den));
        
        if ~isfield(readData.data, prrDataName) || ~isfield(readData.data, cbrDataName)
            continue;
        end

        data_prr_temp = readData.data.(prrDataName);
        data_cbr_temp = readData.data.(cbrDataName);

        prr_mu = zeros(size(data_prr_temp, 1), 2);
        prr_mu(:, 1) = data_prr_temp(:, 1);
        data_prr_temp(:,1) = [];
        for i = 1:size(data_prr_temp, 1)
            index_data = ~isnan(data_prr_temp(i,:));
            prr_mu(i, 2) = mean(data_prr_temp(i,index_data));
        end
        range = round(getdis(prr_mu(:,1), prr_mu(:,2), threshold));
        data_dis_plot = [data_dis_plot, range];
        data_cbr_plot = [data_cbr_plot, mean(data_cbr_temp)/reptime];
    end
    [data_cbr_plot, index] = sort(data_cbr_plot);
    data_dis_plot = data_dis_plot(index);

    legend_name = sprintf("%d rep., Winner+ B1", reptime-1);

    color = color_space(reptime,:);
    x_points = data_cbr_plot(1) + (data_cbr_plot(end)-data_cbr_plot(1))/(marker_points+1)*(1:marker_points);
    i_marker = [];
    for i = 1:marker_points
        new_point = sum(data_cbr_plot <= x_points(i));
        i_marker = [i_marker, new_point];
    end
    h1(reptime) = plot(data_cbr_plot, data_dis_plot, 'Color', color,...
        'LineStyle','-','LineWidth', 1.5, 'HandleVisibility','on',...
        'Marker', markers(reptime),'MarkerIndices', i_marker-1,...
        'MarkerFaceColor',color, 'DisplayName',legend_name);
end

% right ECC rural
yyaxis right;
ylabel(sprintf('Range with ECC rural [m]'));
ch = 3;
ylim([800, 2000]);
xlim([0, 0.15]);
dens = dens./4;

for reptime = 1:4
    data_cbr_plot = [];
    data_dis_plot = [];
    for i_den = 1:length(dens)
        prrDataName = sprintf("PRR_ch_%d_rep_%d_dens_%d", ch, reptime, 100*dens(i_den));
        cbrDataName = sprintf("CBR_ch_%d_rep_%d_dens_%d", ch, reptime, 100*dens(i_den));
        
        if ~isfield(readData.data, prrDataName) || ~isfield(readData.data, cbrDataName)
            continue;
        end

        data_prr_temp = readData.data.(prrDataName);
        data_cbr_temp = readData.data.(cbrDataName);

        prr_mu = zeros(size(data_prr_temp, 1), 2);
        prr_mu(:, 1) = data_prr_temp(:, 1);
        data_prr_temp(:,1) = [];
        for i = 1:size(data_prr_temp, 1)
            index_data = ~isnan(data_prr_temp(i,:));
            prr_mu(i, 2) = mean(data_prr_temp(i,index_data));
        end
        range = round(getdis(prr_mu(:,1), prr_mu(:,2), threshold));
        data_dis_plot = [data_dis_plot, range];
        data_cbr_plot = [data_cbr_plot, mean(data_cbr_temp)/reptime];
    end
    [data_cbr_plot, index] = sort(data_cbr_plot);
    data_dis_plot = data_dis_plot(index);

    legend_name = sprintf("%d rep., ECC", reptime-1);

    color = color_space(reptime,:);
    x_points = data_cbr_plot(1) + (data_cbr_plot(end)-data_cbr_plot(1))/(marker_points+1)*(1:marker_points);
    i_marker = [];
    for i = 1:marker_points
        new_point = sum(data_cbr_plot <= x_points(i));
        i_marker = [i_marker, new_point];
    end
    h2(reptime) = plot(data_cbr_plot, data_dis_plot, 'Color', color,...
        'linestyle', '--', 'LineWidth', 1.5, 'HandleVisibility','on',...
        'Marker', markers(reptime),'MarkerIndices', i_marker,...
        'MarkerFaceColor','none', 'DisplayName',legend_name);
end

annotation('arrow',[0.8, 0.45],[0.47,0.2],Color=[0,0,0],LineWidth=1.5,LineStyle='-');
annotation('arrow',[0.81, 0.46],[0.46,0.19],Color=[0,0,0],LineWidth=1.5,LineStyle='--');
text(0.02, 900, "$From ~ 0 ~ to ~ 3 ~ rep.$","FontSize",12, Interpreter="latex");

ax = gca;
ax.YAxis(1).Color = 'k';
ax.YAxis(2).Color = 'k';
title("Range vs. net CBR");

lgnd = legend([h1,h2],'Location','best','NumColumns',2);
set(lgnd.BoxFace, 'ColorType', 'truecoloralpha', 'ColorData', uint8([255;255;255;0.5*255]));

saveas(fig, fullfile(path_task, sprintf("fig_Range_vs_net_CBR_thre_%.2f.png",threshold)));
