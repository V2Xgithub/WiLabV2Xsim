%% Init path
path_task = fileparts(mfilename('fullpath'));
path_mataData = fullfile(path_task, "mataData");
path_readData = fullfile(path_task, "readData");
if ~exist(path_readData,'dir')
    mkdir(path_readData);
end


%% read static preamble data
sensitivity = [-100, -103, -120];
data = [];
for sens = sensitivity
    for repNum = 1:4
        scenario = sprintf("replicate_%d_sensitivity__%d", repNum, abs(sens));
        sim_list = dir(fullfile(path_mataData, scenario));
        sim_list = sim_list(3:end);
        for i = 1:length(sim_list)
            fileName = fullfile(sim_list(i).folder, sim_list(i).name, "packet_reception_ratio_1_11p.xls");
            if ~exist(fileName, "file")
                continue;
            end
            datatemp = load(fileName);
            if ~isfield(data, scenario)
                data.(scenario) = [datatemp(:,1), datatemp(:,6)];
            else
                data.(scenario) = [data.(scenario), datatemp(:, 6)];
            end
        end
    end
end

save(fullfile(path_readData, "data_prr_vs_distance"),"data");
