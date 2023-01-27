%% init
path(pathdef);  % Reset Matlab path
path_task = fileparts(mfilename('fullpath'));
path_mataData = fullfile(path_task, 'mataData');
path_readData = fullfile(path_task, "readData");
if ~exist(path_readData,'dir')
    mkdir(path_readData);
end


%% read dynamic data
density = [1:9,10:2:30,40:20:100];
data = [];
ch_model = [0, 3];          % [winner+ B1, ECC rural]
repType = [0,1,2];
for ch = ch_model
    for rType = repType
        if rType == 0
            replicate = 1:4;
        else
            replicate = 4;
        end
        for repNum = replicate
            for dens_km = density
                if ch == 0
                    dens = dens_km;
                    nameData = sprintf("ch_%d_rType_%d_replicate_%d_dens_%d", ch, rType, repNum, dens);
                    
                else
                    dens = dens_km/4;
                    nameData = sprintf("ch_%d_rType_%d_replicate_%d_dens_%d", ch, rType, repNum, 100*dens);
                    
                end
                scenario = sprintf("ch_%d_rType_%d_replicate_%d_dens_%.2f", ch, rType, repNum, dens);
                
                fileList = dir(fullfile(path_mataData, scenario));      
                fileList = fileList(3:end);
                for i = 1:length(fileList)
                    try
                        datatemp = load(fullfile(fileList(i).folder, fileList(i).name, "packet_reception_ratio_1_11p.xls"));
                    catch
                        continue;
                    end
                    if ~isfield(data, nameData)
                        data.(nameData) = [datatemp(:,1), datatemp(:,6)];
                    else
                        data.(nameData) = [data.(nameData), datatemp(:, 6)];
                    end
                end
            end
        end
    end
end

save(fullfile(path_readData, "prr_data_two_ch"),"data");