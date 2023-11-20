function [simParams,positionManagement] = loadObstaclesMapFile(simParams,positionManagement)
% Function to load the Ostacles Map File (map of roads and buildings)

tic

fprintf('\nLoading Obstacles Map File\n');

fileID = fopen(simParams.filenameObstaclesMap,'r');

% Read the first line of the file
Info = fscanf(fileID,'%d,%d,%d,%d,\n');

positionManagement.XminMap = Info(1);
positionManagement.XmaxMap = Info(2);
positionManagement.YminMap = Info(3);
positionManagement.YmaxMap = Info(4);
positionManagement.StepMap = Info(5);

Ncolumns = (positionManagement.XmaxMap-positionManagement.XminMap)/positionManagement.StepMap;
Nrows = (positionManagement.YmaxMap-positionManagement.YminMap)/positionManagement.StepMap;

% Copy all columns in a char matrix
stringMap = fscanf(fileID,'%s\n',[Ncolumns Nrows]);

% Initialize output matrix
positionManagement.GridMap = zeros(Nrows,Ncolumns);

% Do the transpose and copy the values to the output matrix
for i = 1:Ncolumns
    for j = 1:Nrows
        positionManagement.GridMap(j,i) = str2double(stringMap(i,j));
    end
end

toc

end
