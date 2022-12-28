close all % Close all open figures
clear % Reset variables
clc % Clear the command window
path_task = fileparts(mfilename('fullpath'));
path_data = fullfile(path_task, "Output", "data_fig_9");

colorspace = [0,0,204
            0,187,255
            197,19,132]./255;
markers = ["o", "^", "square"];
M_values = [1,0.5,0.2];
thresholds = [-126, -110];

for pSize = [350, 1000]
    fig = figure();
    grid on;
    hold on;
    for i_m = 1:length(M_values)
        if M_values(i_m) == 1
            lgd_name = "Mode 2";
        else
            lgd_name = sprintf("L2, M=%d%%",100*M_values(i_m));
        end
        for i_thr = 1:length(thresholds)
            if thresholds(i_thr) == -126   
                ls = "-";
                mfc = colorspace(i_m,:);
            else
                ls = "--";
                mfc = "none";
            end
            dataFile = fullfile(path_data, ...
                sprintf("M_%d_thr__%d_dBm_psize_%d",100*M_values(i_m), abs(thresholds(i_thr)), pSize), "packet_reception_ratio_1_5G.xls");
            data = load(dataFile);

            plot(data(:,1), data(:,6), "displayname", sprintf("%s, Thr. %d dBm", lgd_name, thresholds(i_thr)),...
                "LineWidth",1.5,...
                "lineStyle", ls, "Marker", markers(i_m), "MarkerFaceColor", mfc,...
                "Color", colorspace(i_m,:),"MarkerIndices",[1:5:length(data(:,1))]);
        end
    end
    
    legend("location","southwest");
    saveas(fig, fullfile(path_data, sprintf("figure9_%d.png",pSize)))
end
