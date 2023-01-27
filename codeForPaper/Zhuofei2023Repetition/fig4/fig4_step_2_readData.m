path_task = fileparts(mfilename('fullpath'));
path_mataData = fullfile(path_task, 'mataData');
path_readData = fullfile(path_task, 'readData');
if ~exist(path_readData,'dir')
    mkdir(path_readData);
end


density = [1:9,10:2:30,40:20:100];
ch_model = [0,3];
repNumbers = 1:4;

data = [];
for ch = ch_model
    for repNum = repNumbers
        for dens_km = density
            if ch == 0
                dens = dens_km;
                nameCBRdata = sprintf("CBR_ch_%d_rep_%d_dens_%d", ch, repNum, dens);
                namePRRdata = sprintf("PRR_ch_%d_rep_%d_dens_%d", ch, repNum, dens);
            elseif ch == 3
                dens = dens_km/4;
                nameCBRdata = sprintf("CBR_ch_%d_rep_%d_dens_%d", ch, repNum, 100*dens);
                namePRRdata = sprintf("PRR_ch_%d_rep_%d_dens_%d", ch, repNum, 100*dens);
            end
            scenario = sprintf("ch_%d_replicate_%d_dens_%.2f", ch, repNum, dens);
            file_list = dir(fullfile(path_mataData, scenario));
            file_list = file_list(3:end);
            for i = 1:length(file_list)
                cbrFileName = fullfile(file_list(i).folder, file_list(i).name,...
                    "CBRofGenericVehicle_1_11p.xls");
                prrFileName = fullfile(file_list(i).folder, file_list(i).name,...
                    "packet_reception_ratio_1_11p.xls");
    
                % load CBR data
                cbrDataTemp = load(cbrFileName);
                if ~isfield(data, nameCBRdata)
                    data.(nameCBRdata) = cbrDataTemp(:,2);
                else
                    data.(nameCBRdata) = [data.(nameCBRdata); cbrDataTemp(:, 2)];
                end

                % load PRR data
                prrDataTemp = load(prrFileName);
                if ~isfield(data, namePRRdata)
                    data.(namePRRdata) = prrDataTemp(:,[1,6]);
                else
                    data(namePRRdata) = [data, prrDataTemp(:,6)];
                end
            end
        end
    end
end


save(fullfile(path_readData, "two_ch_data"),"data");

