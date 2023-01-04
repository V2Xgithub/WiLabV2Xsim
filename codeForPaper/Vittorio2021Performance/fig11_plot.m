close all % Close all open figures
clear % Reset variables
clc % Clear the command window
path_task = fileparts(mfilename('fullpath'));
path_data = fullfile(path_task, "Output", "data_fig_11");

colorspace = [0,0,204
            0,187,255
            197,19,132]./255;
markers = ["o", "^", "square"];
thresholds = [-126, -110];


fig = figure();
grid on;
hold on;
fileName = "packet_reception_ratio_1_5G.xls";
% line 1
dataFile = fullfile(path_data, "M_100_avgRSRP_0_coherentArrival_0", fileName);
data = load(dataFile);
plot(data(:,1), data(:,6), "displayname", "Mode 2",...
    "LineWidth",1.5,...
    "lineStyle", '-', "Marker", markers(1), "MarkerFaceColor", colorspace(1,:),...
    "Color", colorspace(1,:),"MarkerIndices",[1:5:length(data(:,1))]);

% line 2
dataFile = fullfile(path_data, "M_20_avgRSRP_0_coherentArrival_0", fileName);
data = load(dataFile);
plot(data(:,1), data(:,6), "displayname", "L2, M=20%",...
    "LineWidth",1.5,...
    "lineStyle", '-', "Marker", markers(2), "MarkerFaceColor", colorspace(2,:),...
    "Color", colorspace(2,:),"MarkerIndices",[1:5:length(data(:,1))]);

% line 3
dataFile = fullfile(path_data, "M_100_avgRSRP_1_coherentArrival_0", fileName);
data = load(dataFile);
plot(data(:,1), data(:,6), "displayname", "average RSRP",...
    "LineWidth",1.5,...
    "lineStyle", '-', "Marker", markers(3), "MarkerFaceColor", colorspace(3,:),...
    "Color", colorspace(3,:),"MarkerIndices",[1:5:length(data(:,1))]);

% line 4
dataFile = fullfile(path_data, "M_20_avgRSRP_1_coherentArrival_0", fileName);
data = load(dataFile);
plot(data(:,1), data(:,6), "displayname", "L2, M=20%, average RSRP",...
    "LineWidth",1.5,...
    "lineStyle", '--', "Marker", markers(3), "MarkerFaceColor", "none",...
    "Color", colorspace(3,:),"MarkerIndices",[1:5:length(data(:,1))]);

% line 5
dataFile = fullfile(path_data, "M_100_avgRSRP_0_coherentArrival_1", fileName);
data = load(dataFile);
plot(data(:,1), data(:,6), "displayname", "Mode 2, coherent arrivals",...
    "LineWidth",1.5,...
    "lineStyle", '--', "Marker", markers(1), "MarkerFaceColor", "none",...
    "Color", colorspace(1,:),"MarkerIndices",[1:5:length(data(:,1))]);

legend("location","southwest");
saveas(fig, fullfile(path_data, "figure11.png"))

