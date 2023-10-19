function [errors_timetable, br_topology, br_id_timetable, position_timetable, activeTX_timetable] = LoadExperiment(output_container_name, output_folder, experiment_id)
    errors_timetable = parse_errors_timetable(output_container_name, output_folder, experiment_id );
    br_topology = parse_br_topology_struct(output_container_name, output_folder, experiment_id);
    br_id_timetable = parse_br_id_timetable(output_container_name, output_folder, experiment_id);
    position_timetable = parse_position_timetable(output_container_name, output_folder, experiment_id);
    activeTX_timetable = parse_activeTX_timetable(output_container_name, output_folder, experiment_id);
end

function errors_timetable = parse_errors_timetable(output_container_name, output_folder, experiment_id)
    to_sec = @(s) seconds(sscanf(s,"%f sec"));
    errors_file_name = sprintf("%s/%s/errors-%s.csv", output_container_name, output_folder, experiment_id);
    opts = delimitedTextImportOptions(VariableNames={'Time', 'rx_successes', 'rx_errors'}, VariableTypes=repmat({'string'},3, 1),DataLines=2, VariableDescriptionsLine=1,VariableNamingRule='preserve');
    errors_table = readtable(errors_file_name, opts);
    errors_table_row_times = arrayfun(to_sec, errors_table.Time);
    errors_table.Time = [];
    if isempty(errors_table_row_times)
        errors_timetable = table2timetable(errors_table, 'TimeStep', seconds(0.1));
    else
        errors_timetable = table2timetable(errors_table, 'rowTimes', errors_table_row_times);
    end
end

function br_topology = parse_br_topology_struct(output_container_name, output_folder, experiment_id)
    br_topology_file_name = sprintf("%s/%s/br-topology-%s.xml", output_container_name, output_folder, experiment_id);
    br_topology = readstruct(br_topology_file_name);
end

function br_id_timetable = parse_br_id_timetable(output_container_name, output_folder, experiment_id)
    to_sec = @(s) seconds(sscanf(s,"%f sec"));
    br_id_timetable_file_name = sprintf("%s/%s/brid-%s.csv", output_container_name, output_folder, experiment_id);
    f = fopen(br_id_timetable_file_name,'r');
    first_line = fgetl(f);
    fclose(f);
    variable_names = split(first_line, ',');
    opts = delimitedTextImportOptions(VariableNames=variable_names, VariableTypes=repmat({'string'}, length(variable_names), 1),DataLines=2,Delimiter=',');
    br_id_table = readtable(br_id_timetable_file_name, opts);
    br_id_table_row_times = arrayfun(to_sec, br_id_table.Time);
    br_id_table.Time = [];
    br_id_timetable = table2timetable(br_id_table, 'rowTimes', br_id_table_row_times);
end

function position_timetable = parse_position_timetable(output_container_name, output_folder, experiment_id)
    to_sec = @(s) seconds(sscanf(s,"%f"));
    position_timetable_file_name = sprintf("%s/%s/positions-%s.csv", output_container_name, output_folder, experiment_id);
    f = fopen(position_timetable_file_name,'r');
    first_line = fgetl(f);
    fclose(f);
    variable_names = split(first_line, ',');
    opts = delimitedTextImportOptions(VariableNames=variable_names, VariableTypes=repmat({'string'}, length(variable_names), 1),DataLines=2,Delimiter=',');
    position_table = readtable(position_timetable_file_name, opts);
    position_table_row_times = arrayfun(to_sec, position_table.Time);
    position_timetable = timetable('Size', [height(position_table) 1], 'VariableTypes', {'string'}, 'VariableNames', {'Position'}, 'RowTimes', position_table_row_times);
    for i = 1:height(position_table)
        this_instant_table = table(str2num(position_table{i, "Vehicles"})', ...
                                        str2num(position_table{i, "X"})', ...
                                        str2num(position_table{i, "Y"})', ...
                                        str2num(position_table{i, "Speed"})', ...
                                        str2num(position_table{i, "Heading"})', ...
                                        'VariableNames', {'Vehicle', 'X', 'Y', 'Speed', 'Heading'});
        bs = num2str(getByteStreamFromArray(this_instant_table));
        rhs = cell(1, 1);
        rhs{1,1} = bs;
        position_timetable{i, 1} = rhs;
    end
end

function activeTX_timetable = parse_activeTX_timetable(output_container_name, output_folder, experiment_id)
    to_sec = @(s) seconds(sscanf(s,"%f sec"));
    errors_file_name = sprintf("%s/%s/tx-%s.csv", output_container_name, output_folder, experiment_id);
    opts = detectImportOptions(errors_file_name);
    opts = setvartype(opts,{'Time', 'activeTXid'}, 'string');
    tx_table = readtable(errors_file_name, opts);
    tx_table_row_times = arrayfun(to_sec, tx_table.Time);
    tx_table.Time = [];
    activeTX_timetable = table2timetable(tx_table, 'rowTimes', tx_table_row_times);
end
