function fig_3_plot_data_age(varTs, data_name)
path_task = fileparts(mfilename("fullpath"));
addpath(genpath(path_task));
path_data = fullfile(fileparts(path_task), "data");
if varTs == 0
    n_vgi = "period";
else
    n_vgi = "CAM";
end
path_fig = fullfile(fileparts(path_task), "figures", n_vgi);
if ~exist(path_fig,"dir")
    mkdir(path_fig);
end

color_methods = [150,150,150
            228,26,28       % A
            55,126,184      % B
            77,175,74       % C
            255,127,0
            152,78,163      % F
            166,86,40
            247,129,191]./255;

ls_methods = [":", "-", "-", "-", "-","-"];
mk_methods = ["none", "o", "*", "square", "diamond", "pentagram"];
ls_only_method = "--";
%% fixed params
dens = 0.5:0.5:6; % cars per lane per km
dens_km = dens * 6; % dens per km

%% variable params
Raw = 500;
data_only = load(fullfile(path_data, sprintf("fig_3_data_age_data_%s.mat", n_vgi)));
data = load(fullfile(path_data, sprintf("fig_3%s_data_age_data_%s.mat",data_name, n_vgi)));
% varTs = [0,-1];   % variabilityTbeacon, [0, -1]
dataSize = 350;
plot_methods = ["no_method", "enhanced_A", "method_B", "dynamic_C", "dynamic_C_preamble", "method_F"];
lgd_name = ["No-method", "eM_{A}-time-split", "M_{B}-E-signals", "dM_{C}-preamble", "M_{C}-preamble-no-SF", "M_{F}-CTS-To-Self"];
for tech = ["IEEE11p", "NR"]
    if strcmp(tech, "IEEE11p")
        plot_only_methods = "only_ITS";
        lgd_only_name = "Only 11p";
        ttl = "ITS-G5";
    else
        plot_only_methods = "only_NR";
        lgd_only_name = "Only NR";
        ttl = "NR-V2X";
    end

    fig = figure();
    hold on;
    grid on;

    % plot other methods
    for i_method = 1:length(plot_methods)
        x_temp = [];
        y_temp = [];
        for i_den = 1:length(dens_km)
            if isempty(data.data_log.(tech).(plot_methods(i_method)).(sprintf("dens_%d",dens_km(i_den))))
                continue;
            else
                data_temp = data.data_log.(tech).(plot_methods(i_method)).(sprintf("dens_%d",dens_km(i_den)));
                data_avg = sum(data_temp(:,1) .* data_temp(:,2)) / sum(data_temp(:,2)) ;
                x_temp = [x_temp, dens_km(i_den)];
                y_temp = [y_temp, data_avg];
            end
        end
        h(i_method) = plot(x_temp, y_temp, DisplayName=lgd_name(i_method), Color=color_methods(i_method,:),...
            LineWidth=2, LineStyle=ls_methods(i_method),Marker=mk_methods(i_method));
    end
    
    % plot only method
    x_temp = [];
    y_temp = [];
    for i_den = 1:length(dens_km)
        if isempty(data_only.data_log.(tech).(plot_only_methods).(sprintf("dens_%d",dens_km(i_den))))
            continue;
        else
            data_temp = data_only.data_log.(tech).(plot_only_methods).(sprintf("dens_%d",dens_km(i_den)));
            data_avg = sum(data_temp(:,1) .* data_temp(:,2)) / sum(data_temp(:,2)) ;
            x_temp = [x_temp, dens_km(i_den)];
            y_temp = [y_temp, data_avg];
        end
    end
    h_only = plot(x_temp, y_temp, DisplayName=lgd_only_name, Color=color_methods(1,:),...
        LineWidth=2, LineStyle=ls_only_method);


    t_name = sprintf('Average data age of %s within %d m, %s', ttl, Raw, n_vgi);
    title(t_name, 'Interpreter','none');
    xlabel('Density [vehicles/km]');
    ylabel('Data Age [s]');
    ylim([0.1, 0.2]);
    lgnd = legend([h(1), h_only, h(2:end)], 'Location','best', FontSize=8);
    set(lgnd.BoxFace, 'ColorType', 'truecoloralpha', 'ColorData', uint8([255;255;255;0.6*255]));
    saveas(fig, fullfile(path_fig, sprintf("fig_3%s_data_age_with_tech_%s_%s.png",data_name, tech, n_vgi)));
end
