% For balanced technology
data_additional_name = "";
varTs = [0, -1];
computer_names = "felix";
data_name_output = "";

for varT = varTs
    fig_1_read_prr_data(computer_names,varT,data_name_output);
    fig_2_read_packet_delay_data(computer_names,varT,data_name_output);
    fig_3_read_data_age(computer_names,varT,data_name_output);
end


% computer_names = ["felix_2_3_lte", "felixlen_1_3_lte"];
% data_name_output = ["2_3_lte", "1_3_lte"];
% 
% for i=1:length(computer_names)
%     fig_1_read_prr_data(computer_names(i),data_name_output(i));
%     fig_2_read_packet_delay_data(computer_names(i),data_name_output(i));
%     fig_3_read_data_age(computer_names(i),data_name_output(i));
% end



