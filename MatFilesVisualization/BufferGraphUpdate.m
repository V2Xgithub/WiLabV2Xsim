function [bufferGraphStruct] = BufferGraphUpdate(bufferGraphStruct, stationManagement)
%BUFFERGRAPHUPDATE Summary of this function goes here
%   Detailed explanation goes here
bufferGraphStruct.bar.YData = stationManagement.pckBuffer;
end

