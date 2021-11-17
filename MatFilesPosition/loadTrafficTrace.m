function [dataOut,simParams] = loadTrafficTrace(simParams)
% This function loads the traffic trace and if needed reduces it in time
% and space (both X and Y axis
% Input: 1) name of the file, 2) duration of the simulation, 3) minimum X
% to be simulated, 4) maximum X to be simulated, 5) minimum Y
% to be simulated, 6) maximum Y to be simulated
% Output: a matrix with the traffic trace
% If any of the input limitations (in time or space) is set to -1, then no
% limitation is assumed; for example, if the minimum X is set to -1, then
% the traffic trace is not reduced in the minimum X
% Note: if in the new trace a vehicle exits the scenario and later returns
% in it, then it is treated as two different vehicles; for this reason, the
% IDs of the original vehicles may not correspond to the IDs of the output
% trace

% Store input value of the simulation time in duration
duration = simParams.simulationTime;

fprintf('Loading Trace File\n');

tic

% The full traffic trace is loaded
dataIn = load(simParams.filenameTrace);

% The input time interval is derived from the input file
deltaTorig = max(dataIn(2:end,1)-dataIn(1:end-1,1));

% Check if time in input is shorter than time resolution in the trace file
if simParams.simulationTime<deltaTorig
    error('Error: simulationTime must be equal or larger than the time resolution of the trace file');
end

% Find maximum time in trace file
maxTime = max(dataIn(:,1)); 

% Check if time in input is longer than the maximum in the trace file
if duration>maxTime
    fprintf('Simulation time exceeds maximum time in the trace file: ');
    duration = maxTime;
    fprintf('set to %.1fs\n', maxTime);
end

% If the simulation time is not -1, then the trace is reduced in time
if simParams.simulationTime~=-1
    dataIn = dataIn(dataIn(:,1)<=duration,:);
end

% The input time interval is derived from the input file
deltaT = max(dataIn(2:end,1)-dataIn(1:end-1,1));

% If the min X field is not -1, then the trace is reduced
if simParams.XminTrace~=-1
    dataIn = dataIn(dataIn(:,3)>=simParams.XminTrace,:);
end

% If the max X field is not -1, then the trace is reduced
if simParams.XmaxTrace~=-1
    dataIn = dataIn(dataIn(:,3)<=simParams.XmaxTrace,:);
end

% If the min Y field is not -1, then the trace is reduced
if simParams.YminTrace~=-1
    dataIn = dataIn(dataIn(:,4)>=simParams.YminTrace,:);
end

% If the max Y field is not -1, then the trace is reduced
if simParams.YmaxTrace~=-1
    dataIn = dataIn(dataIn(:,4)<=simParams.YmaxTrace,:);
end

% The data matrix is saved in vectors to speed up processing
t = dataIn(:,1);
id = dataIn(:,2);
xV = dataIn(:,3);
yV = dataIn(:,4);
if length(dataIn(1,:))>4
    vV = dataIn(:,5);
end

% The output matrix is initialized with the correct size
dataAll = zeros(length(dataIn(:,1)),length(dataIn(1,:)));

% Cycle among the vehicles in the trace
% The IDs of output vehicles are sequential and start from 1
startIndex = 1;
outputID = 1;
for idToCheck = min(dataIn(:,2)):max(dataIn(:,2))    
    % IDs of vehicles that are not present are skipped
    if  nnz(dataIn(:,2)==idToCheck)>0
        % Vectors that focus on a specific vehicle
        tCheck = t(id==idToCheck);
        xCheck = xV(id==idToCheck);
        yCheck = yV(id==idToCheck);
        if length(dataIn(1,:))>4
            vCheck = vV(id==idToCheck); 
        end
        
        % Vectors related to possible events where a vehicle exits the
        % scenario and later returns in the scenario
        outAndIn = (tCheck(2:end)-tCheck(1:end-1))>deltaT;
        indexesStart = [1; find(outAndIn==1)+1];
        indexesEnd = [find(outAndIn==1); length(tCheck)];
        for i=1:length(indexesStart)
            % Concatenation to the previous vehicles
            endIndex = startIndex + indexesEnd(i) - indexesStart(i);
            dataAll(startIndex:endIndex,1) = tCheck(indexesStart(i):indexesEnd(i));
            dataAll(startIndex:endIndex,2) = outputID;
            dataAll(startIndex:endIndex,3) = xCheck(indexesStart(i):indexesEnd(i));
            dataAll(startIndex:endIndex,4) = yCheck(indexesStart(i):indexesEnd(i));
            if length(dataIn(1,:))>4
                dataAll(startIndex:endIndex,5) = vCheck(indexesStart(i):indexesEnd(i));
            end
            startIndex = endIndex+1;
            % The ID of the next vehicle is updated
            outputID = outputID+1;
        end
    end
end
% The output file is sorted along the time column (it was sorted along the vehicle ID)
dataOut = sortrows(dataAll,1);

% Update value of the simulation time
simParams.simulationTime = duration;

toc

end