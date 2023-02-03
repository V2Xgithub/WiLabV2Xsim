% close all    % Close all open figures
clear        % Reset variables
clc          % Clear the command window
path(pathdef);  % Reset Matlab path
path_task = fileparts(mfilename('fullpath'));
addpath(path_task);
path_readData = fullfile(path_task, 'readData');

%% ============ Need to change if you have your own data
totData = load(fullfile(path_readData, "original_prr_data_two_ch"));
%% ============

color_space =   [27,158,119;
                217,95,2;
                117,112,179;
                231,41,138;
                102,166,30;
                230,171,2] ./ 255; 
density = [1:1:9,10:2:30,40:20:100];
threshold = 0.9;
ch_model = [0, 3];          % [winner+ B1, ECC rural]

for ch = ch_model
    % init figure
    fig = figure();
    grid on;
    hold on;
    xlabel('Density [vehicles/km]');
    
    markers = ["^", "diamond", "square", "o"];
    marker_points = 6;

    % plot static
    rtype = 0;
    reps = 1:4;
    for repNum = reps
        index_dens = [];
        data_dis09 = [];
        for dens_km = density
            if ch == 0
                dens = dens_km;
            else
                dens = 100 *(dens_km / 4);
            end

            data_name = sprintf("ch_%d_rType_%d_replicate_%d_dens_%d", ch, rtype, repNum, dens);
            if ~isfield(totData.data, data_name)
                continue;
            end
            
            data_temp = totData.data.(data_name);
            prr_mu = zeros(size(data_temp, 1), 2);
            prr_mu(:, 1) = data_temp(:, 1);
            prr_mu(:,2) = mean(data_temp(:, 2:size(data_temp,2)), 2);
    
            range = round(getdis(prr_mu(:,1), prr_mu(:,2), threshold));
            data_dis09 = [data_dis09, range];
            index_dens = [index_dens, dens];
        end
        if repNum == 2
            legend_name = "1 repetition";
            color = color_space(repNum,:);
            lineStyle = '--';
        else
            legend_name = sprintf("%d repetitions", repNum-1);
            color = color_space(repNum,:);
            lineStyle = '--';
        end
        x_points = index_dens(1) + (index_dens(end)-index_dens(1))/(marker_points+1)*(1:marker_points);
        i_marker = [];
        for i = 1:marker_points
            new_point = sum(index_dens <= x_points(i));
            i_marker = [i_marker, new_point];
        end
        plot(index_dens, data_dis09, 'Color', color,...
            'linestyle', lineStyle, 'LineWidth', 1.5, 'DisplayName', legend_name,...
            'Marker',markers(repNum),'MarkerIndices',i_marker,...
            'MarkerFaceColor','none');
    end
    
    %% plot dynamic, new threshold
    for rtype = 1:2
        reps = 4;
        for repNum = reps
            index_dens = [];
            data_dis09 = [];
            for dens_km = density
                if ch == 0
                    dens = dens_km;
                else
                    dens = 100 *(dens_km / 4);
                end

                data_name = sprintf("ch_%d_rType_%d_replicate_%d_dens_%d", ch, rtype, repNum, dens);
                if ~isfield(totData.data, data_name)
                    continue;
                end
                
                data_temp = totData.data.(data_name);
                prr_mu = zeros(size(data_temp, 1), 2);
                prr_mu(:, 1) = data_temp(:, 1);
                prr_mu(:,2) = mean(data_temp(:, 2:size(data_temp,2)), 2);
        
                range = round(getdis(prr_mu(:,1), prr_mu(:,2), threshold));
                data_dis09 = [data_dis09, range];
                index_dens = [index_dens, dens];
            end
            if rtype == 1
                legend_name = "Deterministic strategy";
                color = color_space(repNum+1,:);
                lineStyle = '-.';
                i_shift = -1;
            else
                legend_name = "Probabilistic strategy";
                color = color_space(repNum+2,:);
                lineStyle = '-';
                i_shift = 1;
            end
            x_points = index_dens(1) + (index_dens(end)-index_dens(1))/(marker_points+1)*(1:marker_points);
            i_marker = [];
            for i = 1:marker_points
                new_point = sum(index_dens <= x_points(i));
                i_marker = [i_marker, new_point];
            end
            plot(index_dens, data_dis09, 'Color', color,...
                'linestyle', lineStyle, 'LineWidth', 1.5, 'DisplayName', legend_name,...
                'Marker',markers(repNum),'MarkerIndices',i_marker+i_shift,...
                'MarkerFaceColor',color);
        end
    end

    lgnd = legend('Location','northeast','NumColumns',2);
    set(lgnd.BoxFace, 'ColorType', 'truecoloralpha', 'ColorData', uint8([255;255;255;0.5*255]));
    annotation('arrow',[0.8, 0.5],[0.63,0.24],Color=[0,0,0],LineWidth=1.5,LineStyle='--');
    if ch == 0
        text(20, 50, "$From ~ 0 ~ to ~ 3 ~ rep.$","FontSize",12, Interpreter="latex");
        title("Effectiveness of the repetition strategies, Winner+ B1");
        ylabel('Range with Winner+ B1 [m]');
        saveas(fig, fullfile(path_task, "fig_Effectiveness of the repetition strategies Winner.png"));
    else
        text(500, 200, "$From ~ 0 ~ to ~ 3 ~ rep.$","FontSize",12, Interpreter="latex");
        title("Effectiveness of the repetition strategies, ECC rural");
        ylabel('Range with ECC [m]');
        saveas(fig, fullfile(path_task, "fig_Effectiveness of the repetition strategies ECC.png"));
    end
end
