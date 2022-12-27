close all % Close all open figures
clear % Reset variables
clc % Clear the command window
path_task = fileparts(mfilename('fullpath'));
colorspace = [0,0,204
            0,187,255
            197,19,132]./255;
SCS_NR = [15, 30, 60];
haveIBE = ["true", "false"];


fig = figure();
grid on;
hold on;
markers = ["o", "^", "square"];
for i_SCS = 1:length(SCS_NR)
    for IBE = haveIBE
        if IBE == "true"   
            lgd_ibe = "w";
            ls = "-";
            mfc = colorspace(i_SCS,:);
            if SCS_NR(i_SCS) == 60  % situation not considered
                continue;
            end
        else
            lgd_ibe = "w/o";
            ls = "--";
            mfc = "none";
        end
        dataFile = fullfile(path_task, "Output", "data_fig_7", ...
            sprintf("SCS_%d_IBE_%s",SCS_NR(i_SCS), IBE), "packet_reception_ratio_1_5G.xls");
        data = load(dataFile);
        legend_name = sprintf("SCS=%d kHz %s IBE", SCS_NR(i_SCS), lgd_ibe);
        
        plot(data(:,1), data(:,6), "displayname", legend_name, "LineWidth",1.5,...
            "lineStyle", ls, "Marker", markers(i_SCS), "MarkerFaceColor", mfc,...
            "Color", colorspace(i_SCS,:));
    end
end

legend("location","southwest");
xlim([0,150]);
saveas(fig, fullfile(path_task, "Output", "data_fig_7", "figure7.png"))