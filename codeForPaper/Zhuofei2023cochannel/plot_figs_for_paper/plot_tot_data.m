% For balanced technology
data_additional_name = "";
varTs = [0, -1];
for varT = varTs
    fig_1_plot_prr_max_dis(varT, data_additional_name);
    fig_2_plot_packet_delay(varT, data_additional_name);
    fig_3_plot_data_age(varT, data_additional_name);
end

% % For unbalanced technology
% data_names = ["_2_3_lte", "_1_3_lte"];
% varTs = 0;
% 
% for data_name = data_names
%     fig_1_plot_prr_max_dis(varTs, data_name);
%     fig_2_plot_packet_delay(varTs, data_name);
%     fig_3_plot_data_age(varTs, data_name);
% end


