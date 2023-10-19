function [bufferGraphStruct] = BufferGraphInit(stationManagement)
%BUFFERGRAPHINIT Summary of this function goes here
%   Detailed explanation goes here
%   Detailed explanation goes here
bufferGraphStruct = struct;
bufferGraphStruct.figure = figure("Name", "Buffer Size");
bufferGraphStruct.axes = axes(bufferGraphStruct.figure, 'XLim',[1,length(stationManagement.pckBuffer)], 'YLim',[0,5]);
bufferGraphStruct.bar = bar(bufferGraphStruct.axes, stationManagement.pckBuffer);
bufferGraphStruct.axes.Title.String = "Buffer Size";
bufferGraphStruct.axes.XLabel.String = "Vehicle ID";
bufferGraphStruct.axes.YLabel.String = "Buffer Size";
ylim(bufferGraphStruct.axes , [0, 5]);
end

