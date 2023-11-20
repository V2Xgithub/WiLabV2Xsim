function [simParams,simValues,positionManagement,appParams] = initVehiclePositions(simParams,appParams)
% Function to initialize the positions of vehicles
% Description of simulator state variables:
% positionManagement
% ------------------
% vehiclePositionReal - table with four columns: x, y, d, v
% vehiclePositionEstimated - table with four columns: x, y, d, v
% ------------------
% simValues
% ------------------
% vehicleIds - 1xN string array of active vehicle ids in use
% preallocate table, concat it later
positionManagement.vehiclePositionReal = table('Size', [0 4], ...
    'VariableTypes', {'double', 'double', 'double', 'double'}, ...
    'VariableNames', ["X" "Y" "V" "D"]);

if simParams.typeOfScenario == constants.SCENARIO_HIGHWAY
    [positionManagement.vehiclePositionReal, simValues.vehicleIds] = initVehiclePositionsForHighway( ...
        "rho", simParams.rho, "vMean", simParams.vMean, "vStdDev", simParams.vStdDev, ...
        "nLanes", simParams.nLanes, "roadLength", simParams.roadLength, ...
        "laneWidth", simParams.laneWidth, "laneGap", simParams.laneGap);
if simParams.typeOfScenario~=2 % Not traffic trace
    if simParams.typeOfScenario==4 %ETSI-Urban
        simValues.Nblocks=simParams.Nblocks;
        %The dimension x and y of each block
        simValues.XmaxBlock=simParams.XmaxBlock;
        simValues.YmaxBlock=simParams.YmaxBlock;
        %Single block definition - n. of horizontal lanes and n. vertical lanes
        simValues.NLanesBlockH=simParams.NLanesBlockH;%n_lanes_block_horizontal=4;
        simValues.NLanesBlockV=simParams.NLanesBlockV;%n_lanes_block_vertical=4;
        simValues.roadWdt=simParams.roadWdt; %lane width
        %veh_speed_kmh= 15;% km/h max speed - 15 km/h, 60 km/h
        simValues.vMean=simParams.vMean;
        simValues.vStDev=simParams.vStDev;
        % simValues.IVvalue=simParams.IVvalue;
        vMeanMs = simValues.vMean/3.6;                % Mean vehicle speed (m/s)
        vStDevMs = simValues.vStDev/3.6;              % Speed standard deviation (m/s)
        simValues.rhoM = simParams.rho/1e3;           % Average vehicle density (vehicles/m)
        %number of vehicles per horizontal lanes per block,
        % per vertical lanes per block
        n_veh_h_block=round(simValues.NLanesBlockH.*simValues.rhoM*simValues.XmaxBlock);
        n_veh_v_block=round(simValues.NLanesBlockV.*simValues.rhoM*simValues.YmaxBlock);
        Nvehicles = simValues.Nblocks*(n_veh_h_block+n_veh_v_block); 
        %The origins of the blocks in x and y
        X0=(0:2)'*ones(1,3).*simValues.XmaxBlock;
        Y0=ones(3,1)*(0:2).*simValues.YmaxBlock;
        % A set with the blocks sorted, in the sense that I might have less blocks
        % but when I define it I follow that order
        order_idx=[1,2,5,4,3,6,9,8,7]; 
        Orig_set=[X0(order_idx)', Y0(order_idx)'];
        % the direction of the lanes sorted
        direction_h_lanes_block=[-1,-1,1,1]';
        direction_v_lanes_block=[1,1,-1,-1]';
        %0 indica + e 1 indica -
        y_h_lanes_block=[(0:1).*simValues.roadWdt+simValues.roadWdt/2,simValues.YmaxBlock-...
            2.*simValues.roadWdt+(1:-1:0).*simValues.roadWdt+simValues.roadWdt/2]';
        x_v_lanes_block=[(0:1).*simValues.roadWdt+simValues.roadWdt/2,simValues.XmaxBlock-...
            2.*simValues.roadWdt+(1:-1:0).*simValues.roadWdt+simValues.roadWdt/2]';
        h_lane=unidrnd(simValues.NLanesBlockH,simValues.Nblocks*n_veh_h_block,1);
        v_lane=unidrnd(simValues.NLanesBlockV,simValues.Nblocks*n_veh_v_block,1);
        % For the horizontal vehicles, a random x position is picked
        % The y position is fixed by the lane
        % The direction is fixed by the lane
        gen_veh_h=[unifrnd(0,simValues.XmaxBlock,simValues.Nblocks*n_veh_h_block,1),y_h_lanes_block(h_lane),direction_h_lanes_block(h_lane)];
        gen_veh_v=[x_v_lanes_block(v_lane),unifrnd(0,simValues.YmaxBlock,simValues.Nblocks*n_veh_v_block,1),direction_v_lanes_block(v_lane)];
        Or_block_pos_x=repmat(Orig_set(1:simValues.Nblocks,1)',n_veh_h_block,1);
        Or_block_pos_y=repmat(Orig_set(1:simValues.Nblocks,2)',n_veh_h_block,1);
        pos_veh_h=gen_veh_h(:,1:2)+[Or_block_pos_x(:),Or_block_pos_y(:)];
        Or_block_pos_x=repmat(Orig_set(1:simValues.Nblocks,1)',n_veh_v_block,1);
        Or_block_pos_y=repmat(Orig_set(1:simValues.Nblocks,2)',n_veh_v_block,1);
        pos_veh_v=gen_veh_v(:,1:2)+[Or_block_pos_x(:),Or_block_pos_y(:)];
        direction_h=gen_veh_h(:,3);
        direction_v=gen_veh_v(:,3);
        Pos=[pos_veh_h; pos_veh_v];
        positionManagement.XvehicleReal(:) = Pos(:,1);
        positionManagement.YvehicleReal(:) = Pos(:,2);
        positionManagement.Xmin = 0;                           % Min X coordinate
        simValues.Xmax = max(X0(order_idx(1:simValues.Nblocks)))+...
            simValues.XmaxBlock+1i.*max(Y0(order_idx(1:simValues.Nblocks)))+1i.*simValues.YmaxBlock;%sqrt(simValues.Nblocks).*simValues.XmaxBlock+1i*sqrt(simValues.Nblocks).*simValues.YmaxBlock;        % Max X coordinate
        positionManagement.Ymin = 0;                           % Min Y coordinate
        simValues.vehicleIds = string(1:Nvehicles);             % Vector of IDs
        % Generate driving direction
        % 0 -> from left to right
        % 1 -> from right to left
        directionX =  zeros(Nvehicles,1);
        directionX(1:simValues.Nblocks*n_veh_h_block)=direction_h;
        directionY =  zeros(Nvehicles,1);
        directionY((simValues.Nblocks*n_veh_h_block+1):end)=direction_v;
        direction=directionX+1i*directionY;
        % we asssign the vehicle speed later
        positionManagement.vehiclePositionReal = table(Pos(:,1), Pos(:,2),direction, zeros(Nvehicles, 1), ...
                    "VariableNames", ["x" "y" "d" "v"], ...
                    "RowNames", simValues.vehicleIds);
    
    else
        

        positionManagement.vehiclePositionReal = table(XvehicleReal, YvehicleReal, direction, zeros(Nvehicles, 1), ...
                    "VariableNames", ["x" "y" "d" "v"], ...
                    "RowNames", simValues.vehicleIds);
    end
    
    % Assign speed to vehicles
    % Gaussian with 'vMeanMs' mean and 'vStDevMs' standard deviation
    % the Gaussian is truncated to avoid negative values or still vehicles
    v = max(abs(random("Normal", vMeanMs, vStDevMs, [Nvehicles 1])), 0.1);
    positionManagement.vehiclePositionReal(:, "v") = v;
else
    
    % Call function to load the traffic trace up to the selected simulation
    % time and, if selected, take only a portion of the scenario
    [tracefileTimetable, capableSimTime] = loadTrafficTrace(simParams);
    
    % Call function to interpolate the traffic trace (if needed)
    [simValues,simParams] = interpolateTrace(dataLoaded,simParams,appParams.allocationPeriod);
    
    % Round time column (representation format)
    simValues.dataTrace(:,1) = round(simValues.dataTrace(:,1)*100)/100;
    
    % Find trace details (Xmin,Xmax,Ymin,Ymax,maxID)
    positionManagement.Xmin = min(simValues.dataTrace(:,3));     % Min X coordinate Trace
    simValues.Xmax = max(simValues.dataTrace(:,3));     % Max X coordinate Trace
    positionManagement.Ymin = min(simValues.dataTrace(:,4));     % Min Y coordinate Trace
    simValues.Ymax = max(simValues.dataTrace(:,4));     % Max Y coordinate Trace
    simValues.maxID = max(simValues.dataTrace(:,2));    % Maximum vehicle's ID
    
    % Call function to read vehicle positions from file at time zero
    [positionManagement.XvehicleReal, positionManagement.YvehicleReal, simValues.vehicleId, simValues.v] = updatePositionFile(0,simValues.dataTrace,[],-1,-1,-1,simValues,[]);
    
end

% Throw an error if there are no vehicles in the scenario
if isempty(simValues.vehicleId)
    error('Error: no vehicles in the simulation.');
end

% RSUs addition
if appParams.nRSUs>0
    idRSUs = simValues.maxID+1:simValues.maxID+appParams.nRSUs;
    simValues.maxID = simValues.maxID + appParams.nRSUs;
    simValues.vehicleId = [simValues.vehicleId; idRSUs'];
    positionManagement.XvehicleReal = [positionManagement.XvehicleReal; appParams.RSU_xLocation'];
    positionManagement.YvehicleReal = [positionManagement.YvehicleReal; appParams.RSU_yLocation'];
end


% NEW TEST MODALITY for C-V2X: asyncronous transmitters TODO (Vittorio)
% if active takes a %x of vehicles at random and create a separate
% vector with theirs IDs ->> these transmitters transmit
% asyncronously
if simParams.technology==1 && simParams.BRAlgorithm==18 && simParams.asynMode == 1       
   % find number of asyn vehicles
   NasynVehicles=ceil(Nvehicles*simParams.percAsynUser);
   % create permutation vector of the overall vehicles
   rpMatrix = randperm(Nvehicles);
   % permutate the ids of the vehicles
   NvehiclesPerm = simValues.vehicleId(rpMatrix);
   % consider the first %X of vehicles to select them at random
   IDvehicleAsyn = NvehiclesPerm(1:NasynVehicles);
   simParams.IDvehicleAsyn = sort(IDvehicleAsyn);
end

% Temporary
% if simParams.mco_nVehInterf>0
%     [simParams,simValues,positionManagement] = mco_initVehiclePositionsInterfering(positionManagement,simParams,appParams,simValues);
% end


end
