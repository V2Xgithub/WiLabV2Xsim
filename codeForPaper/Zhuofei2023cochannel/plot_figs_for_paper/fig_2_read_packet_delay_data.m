function fig_2_read_packet_delay_data(computer_name, varTs, output_name)

path_task = fileparts(mfilename("fullpath"));
addpath(genpath(path_task));
path_data = fullfile(fileparts(path_task), "data");

%% fixed params
dens = 0.5:0.5:6; % cars per lane per km
dens_km = dens * 6; % dens per km

Raw = 300;
Raw_list = [50, 150, 300, 500];
countNum = sum(Raw>=Raw_list);

%% variable params

Methods = ["no_method", "enhanced_A", "method_B", "dynamic_C", "method_F", "dynamic_C_preamble"];
data_log = [];
n_file = "packet_delay";

if varTs == 0
    n_vgi = "period";
else
    n_vgi = "CAM";
end

for tech = ["IEEE11p", "NR"]
    if strcmp(tech, "IEEE11p")
        add_name = "11p";
        plot_methods = ["only_ITS", Methods];
    else
        add_name = "5G";
        plot_methods = ["only_NR", Methods];
    end
    if ~isfield(data_log, tech)
        data_log.(tech) = [];
    end
    for i_com_name = 1:length(computer_name)
        for i_method = 1:length(plot_methods)
            if ~isfield(data_log.(tech), plot_methods(i_method))
                data_log.(tech).(plot_methods(i_method)) = [];
            end
            for i_den = 1:length(dens_km)
                if ~isfield(data_log.(tech).(plot_methods(i_method)), sprintf("dens_%d",dens_km(i_den)))
                    data_log.(tech).(plot_methods(i_method)).(sprintf("dens_%d",dens_km(i_den))) = [];
                end
                path_prr = fullfile(path_data,computer_name(i_com_name), plot_methods(i_method),...
                    sprintf("dens_%d_vgi_%s", dens_km(i_den), n_vgi));
                sims = dir(fullfile(path_prr, "sim_*"));
                for i_sim = 1:length(sims)
                    res_folder = fullfile(sims(i_sim).folder, sims(i_sim).name);
                    res_files = dir(fullfile(res_folder, sprintf("%s_*_%s.xls", n_file, add_name)));
                    for i_f = 1:length(res_files)
                        if ~exist(fullfile(res_files(i_f).folder, sprintf("test_error_log_%d.txt", i_f)), "file")
                            data_temp = load(fullfile(path_prr, sims(i_sim).name, sprintf("%s_%d_%s.xls",n_file, i_f, add_name)));
                            if ~issorted(data_temp(:,1))
                                data_temp = [];
                                continue;
                            end
                        else
                            continue;
                        end
                        data_1 = sum(data_temp(:,(2:2:2+(countNum-1)*2)),2);
                        if isempty(data_log.(tech).(plot_methods(i_method)).(sprintf("dens_%d",dens_km(i_den))))
                            data_log.(tech).(plot_methods(i_method)).(sprintf("dens_%d",dens_km(i_den))) = [data_temp(:,1), data_1];
                        else
                            data_log.(tech).(plot_methods(i_method)).(sprintf("dens_%d",dens_km(i_den)))(:,2) = data_log.(tech).(plot_methods(i_method)).(sprintf("dens_%d",dens_km(i_den)))(:,2) + data_1;
                        end
                    end
                end               
            end
        end
    end
end
save(fullfile(path_data, sprintf("fig_2%s_%s_data_%s",output_name, n_file, n_vgi)), "data_log");