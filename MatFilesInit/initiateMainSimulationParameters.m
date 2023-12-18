function [simParams,varargin] = initiateMainSimulationParameters(fileCfg,varargin)
% function simParams = initiateMainSimulationParameters(fileCfg,varargin)
%
% Main settings of the simulation
% It takes in input the name of the (possible) file config and the inputs
% of the main function
% It returns the structure "simParams"

fprintf('Simulation settings\n');
% [CheckVersion]
% check if the simulation tasks are running on the right simulator verion
[simParams,varargin] = addNewParam([],'CheckVersion',constants.SIM_VERSION,'Simulator version needed','string',fileCfg,varargin{1});
if simParams.CheckVersion ~= constants.SIM_VERSION
    error('You are using a wrong version!');
end

% [seed]
% Seed for the random numbers generation
% If seed = 0, the seed is randomly selected (the selected value is saved
% in the main output file)
[simParams,varargin] = addNewParam([],'seed',0,'Seed for random numbers','integer',fileCfg,varargin{1});
if simParams.seed == 0
    simParams.seed = getseed();
    fprintf('Seed used in the simulation: %d\n',simParams.seed);
end
rng(simParams.seed);

% [simulationTime]
% Duration of the simulation in seconds
[simParams,varargin] = addNewParam(simParams,'simulationTime',10,'Simulation duration (s)','double',fileCfg,varargin{1});
if simParams.simulationTime<=0
    error('Error: "simParams.simulationTime" cannot be <= 0');
end

% [Technology]
% Choose if simulate C-V2X (lte or 5G) or 802.11p
% String: "CV2V" or "80211p"
[simParams,varargin] = addNewParam(simParams,'Technology','LTE-V2X','Choose radio access technology to simulate: "LTE-V2X", "802.11p", "COEX-NO-INTERF", "COEX-STD-INTERF", "NR-V2X"/"5G-V2X", "COEX-STD-INTERF-5G"','string',fileCfg,varargin{1});
% Check that the string is correct
switch upper(simParams.Technology)
    case 'LTE-V2X'
        simParams.technology = constants.TECH_ONLY_CV2X; % CV2X
        simParams.mode5G = constants.MODE_LTE; % LTE
        simParams.stringCV2X = 'LTE';
    case '80211P'
        simParams.technology = constants.TECH_ONLY_11P; % 11p
    case 'COEX-NO-INTERF'
        simParams.technology = constants.TECH_COEX_NO_INTERF; % LTE+11p, not interfering to each other
        simParams.mode5G = constants.MODE_LTE; % LTE
        simParams.stringCV2X = 'LTE';
    case 'COEX-STD-INTERF'
        simParams.technology = constants.TECH_COEX_STD_INTERF; % LTE+11p, interfering with standard protocols
        simParams.mode5G = constants.MODE_LTE; % LTE
        simParams.stringCV2X = 'LTE';
    case {'5G-V2X', 'NR-V2X'}
        simParams.technology = constants.TECH_ONLY_CV2X; % CV2X
        simParams.mode5G = constants.MODE_5G; % 5G
        simParams.stringCV2X = '5G';
    case 'COEX-STD-INTERF-5G'
        simParams.technology = constants.TECH_COEX_STD_INTERF; % LTE+5G NR V2X, interfering with standard protocols
        simParams.mode5G = constants.MODE_5G; % 5G
        simParams.stringCV2X = '5G';
    otherwise
        error('"simParams.Technology" must be ["LTE-V2X", "802.11p", "COEX-NO-INTERF", "COEX-STD-INTERF", ["NR-V2X","5G-V2X"], "COEX-STD-INTERF-5G]');
end

% In coexistence case, set the proportion of 802.11p and C-V2X
if ~ismember(simParams.technology, [constants.TECH_ONLY_CV2X, constants.TECH_ONLY_11P]) % if coexistence
    % [numVehiclesLTE]
    [simParams,varargin] = addNewParam(simParams,'numVehiclesLTE',1,'How many consecutive vehicles use LTE-V2X','integer',fileCfg,varargin{1});
    if simParams.numVehiclesLTE<0
        error('Error: "simParams.numVehiclesLTE" must be equal or greater than 0');
    end
    % [numVehicles11p]
    [simParams,varargin] = addNewParam(simParams,'numVehicles11p',1,'How many consecutive vehicles use IEEE 802.11p','integer',fileCfg,varargin{1});
    if simParams.numVehicles11p<0
        error('Error: "simParams.numVehicles11p" must be equal or greater than 0');
    end
    if simParams.numVehiclesLTE==0 && simParams.numVehicles11p==0
        error('Error: "simParams.numVehiclesLTE" and "simParams.numVehicles11p" cannot be both 0');
    end
end

%% Parameters for coexistence
% [coexMethod]
if simParams.technology==constants.TECH_COEX_STD_INTERF % if coexistence with reciprocal interference
    [simParams,varargin] = initiateCoexistenceParameters(simParams,fileCfg,varargin{1});
end

%% [typeOfScenario]
% Select if want to use Trace File: true or false
[simParams,varargin] = addNewParam(simParams,'TypeOfScenario','PPP','Type of scenario ("PPP"=random 1-D, "Traces"=traffic trace, "ETSI-Highway"=ETSI highway high speed','string',fileCfg,varargin{1});
% Check string
switch upper(simParams.TypeOfScenario)
    case 'PPP'
        simParams.typeOfScenario = constants.SCENARIO_PPP;       % Random speed and direction on multiple parallel roads, all configurable
    case 'TRACES'
        simParams.typeOfScenario = constants.SCENARIO_TRACE;     % Traffic traces
    case 'ETSI-HIGHWAY'
        simParams.typeOfScenario = constants.SCENARIO_HIGHWAY;   % ETSI Highway high speed scenario
    case 'ETSI-URBAN'
        simParams.typeOfScenario = constants.SCENARIO_URBAN;     % ETSI Highway high speed scenario
    otherwise
        error('"simParams.TypeOfScenario" must be "PPP" or "Traces" or "ETSI-Highway" or "ETSI-Urban"');
end

% [positionTimeResolution]
% Time resolution for the positioning update of the vehicles in the trace file (s)
[simParams,varargin] = addNewParam(simParams,'positionTimeResolution',0.1,'Time resolution for the positioning update of the vehicles in the trace file (s)','double',fileCfg,varargin{1});
if simParams.positionTimeResolution<=0
    error('Error: "simParams.positionTimeResolution" cannot be <= 0');
end

switch simParams.typeOfScenario
    case constants.SCENARIO_PPP  % PPP
        simParams.fileObstaclesMap = false;
        % [roadLength]
        % Length of the road to be simulated (m)
        [simParams,varargin] = addNewParam(simParams,'roadLength',4000,'Road Length (m)','double',fileCfg,varargin{1});
        if simParams.roadLength<=0
            error('Error: "simParams.roadLength" cannot be <= 0');
        end
        
        % [roadWidth]
        % Width of each lane (m)
        [simParams,varargin] = addNewParam(simParams,'roadWidth',3.5,'Road Width (m)','double',fileCfg,varargin{1});
        if simParams.roadWidth<0
            error('Error: "simParams.roadWidth" cannot be < 0');
        end
        
        % [vMean]
        % Mean speed of vehicles (km/h)
        [simParams,varargin] = addNewParam(simParams,'vMean',114.23,'Mean speed of vehicles (Km/h)','double',fileCfg,varargin{1});
        if simParams.vMean<0
            error('Error: "simParams.vMean" cannot be < 0');
        end
        
        % [vStDev]
        % Standard deviation of speed of vehicles (km/h)
        [simParams,varargin] = addNewParam(simParams,'vStDev',12.65,'Standard deviation of speed of vehicles (Km/h)','double',fileCfg,varargin{1});
        if simParams.vStDev<0
            error('Error: "simParams.vStDev" cannot be < 0');
        end
        
        % [rho]
        % Density of vehicles (vehicles/km)
        [simParams,varargin] = addNewParam(simParams,'rho',100,'Density of vehicles (vehicles/km)','double',fileCfg,varargin{1});
        if simParams.rho<=0
            error('Error: "simParams.rho" cannot be <= 0');
        end
        
        % [NLanes]
        % Number of lanes per direction
        [simParams,varargin] = addNewParam(simParams,'NLanes',3,'Number of lanes per direction','integer',fileCfg,varargin{1});
        if simParams.NLanes<=0
            error('Error: "simParams.NLanes" cannot be <= 0');
        end
    case constants.SCENARIO_TRACE % Traffic traces
        % [fileObstaclesMap]
        % Select if want to use Obstacles Map File: true or false
        [simParams,varargin] = addNewParam(simParams,'fileObstaclesMap',false,'If using a obstacles map file','bool',fileCfg,varargin{1});
        if simParams.fileObstaclesMap~=false && simParams.fileObstaclesMap~=true
            error('Error: "simParams.fileObstaclesMap" must be equal to false or true');
        end
        
        % [filenameTrace]
        % If the trace file is used, this selects the file
        [simParams,varargin] = addNewParam(simParams,'filenameTrace','null.txt','File trace name','string',fileCfg,varargin{1});
        % Check that the file exists. If the file does not exist, the
        % simulation is aborted.
        fid = fopen(simParams.filenameTrace);
        if fid==-1
            fprintf('File trace "%s" not found. Simulation Aborted.',simParams.filenameTrace);
        else
            fclose(fid);
        end
        
        % [XminTrace]
        % Minimum X coordinate to keep in the traffic trace (m)
        [simParams,varargin] = addNewParam(simParams,'XminTrace',-1,'Minimum X coordinate to keep in the traffic trace (m)','double',fileCfg,varargin{1});
        if simParams.XminTrace~=-1 && simParams.XminTrace<0
            error('Error: the value set for "simParams.XminTrace" is not valid');
        end
        
        % [XmaxTrace]
        % Maximum X coordinate to keep in the traffic trace (m)
        [simParams,varargin] = addNewParam(simParams,'XmaxTrace',-1,'Maximum X coordinate to keep in the traffic trace (m)','double',fileCfg,varargin{1});
        if simParams.XmaxTrace~=-1 && simParams.XmaxTrace<0 && simParams.XmaxTrace<simParams.XminTrace
            error('Error: the value set for "simParams.XmaxTrace" is not valid');
        end
        
        % [YminTrace]
        % Minimum Y coordinate to keep in the traffic trace (m)
        [simParams,varargin] = addNewParam(simParams,'YminTrace',-1,'Minimum Y coordinate to keep in the traffic trace (m)','double',fileCfg,varargin{1});
        if simParams.YminTrace~=-1 && simParams.YminTrace<0
            error('Error: the value set for "simParams.YminTrace" is not valid');
        end
        
        % [YmaxTrace]
        % Maximum Y coordinate to keep in the traffic trace (m)
        [simParams,varargin] = addNewParam(simParams,'YmaxTrace',-1,'Maximum Y coordinate to keep in the traffic trace (m)','double',fileCfg,varargin{1});
        if simParams.YmaxTrace~=-1 && simParams.YmaxTrace<0 && simParams.XmaxTrace<simParams.YminTrace
            error('Error: the value set for "simParams.YmaxTrace" is not valid');
        end
        
        %     % Changed from version 5.2.10 - moved before and applied to all
        %     scenarios
        %     % [positionTimeResolution]
        %     % Time resolution for the positioning update of the vehicles in the trace file (s)
        %     [simParams,varargin] = addNewParam(simParams,'positionTimeResolution',-1,'Time resolution for the positioning update of the vehicles in the trace file (s)','double',fileCfg,varargin{1});
        %     if simParams.positionTimeResolution<=0 && simParams.positionTimeResolution~=-1
        %         error('Error: "simParams.positionTimeResolution" cannot be <= 0 or different from -1');
        %     end
        
        % Depending on the setting of "simParams.fileObstaclesMap", other parameters must
        % be set
        if simParams.fileObstaclesMap
            % [filenameObstaclesMap]
            % If the obstacles map file is used, this selects the file
            [simParams,varargin] = addNewParam(simParams,'filenameObstaclesMap','null.txt','File obstacles map name','string',fileCfg,varargin{1});
            % Check that the file exists. If the file does not exist, the
            % simulation is aborted.
            fid = fopen(simParams.filenameObstaclesMap);
            if fid==-1
                fprintf('File obstacles map "%s" not found. Simulation Aborted.',simParams.filenameObstaclesMap);
            else
                fclose(fid);
            end
        end
    case constants.SCENARIO_HIGHWAY  % ETSI Highway high speed
        simParams.fileObstaclesMap = false;
        % [roadLength]
        % Length of the road to be simulated (m)
        [simParams,varargin] = addNewParam(simParams,'roadLength',2000,'Road Length (m)','double',fileCfg,varargin{1});
        if simParams.roadLength<0
            % The length can be zero to simulate all the vehicles in the same position
            error('Error: "simParams.roadLength" cannot be < 0');
        end
        
        % [roadWidth]
        % Width of each lane (m)
        [simParams,varargin] = addNewParam(simParams,'roadWidth',4,'Road Width (m)','double',fileCfg,varargin{1});
        if simParams.roadWidth<0
            error('Error: "simParams.roadWidth" cannot be < 0');
        end
        
        % [vMean]
        % Mean speed of vehicles (km/h)
        [simParams,varargin] = addNewParam(simParams,'vMean',240,'Mean speed of vehicles (Km/h)','double',fileCfg,varargin{1});
        if simParams.vMean<0
            error('Error: "simParams.vMean" cannot be < 0');
        end
        
        % [vStDev]
        % Standard deviation of speed of vehicles (km/h)
        [simParams,varargin] = addNewParam(simParams,'vStDev',0,'Standard deviation of speed of vehicles (Km/h)','double',fileCfg,varargin{1});
        if simParams.vStDev<0
            error('Error: "simParams.vStDev" cannot be < 0');
        end
        
        % [rho]
        % Density of vehicles (vehicles/km)
        [simParams,varargin] = addNewParam(simParams,'rho',35,'Density of vehicles (vehicles/km)','double',fileCfg,varargin{1});
        if simParams.rho<=0
            error('Error: "simParams.rho" cannot be <= 0');
        end

        % [randomXPosition]
        % switch if vehicles are randomly or Uniformly positioned
        [simParams, varargin] = addNewParam(simParams, 'randomXPosition', true, 'Randomly/uniformly position', 'bool',fileCfg,varargin{1});

        % [NLanes]
        % Number of lanes per direction
        [simParams,varargin] = addNewParam(simParams,'NLanes',3,'Number of lanes per direction','integer',fileCfg,varargin{1});
        if simParams.NLanes<=0
            error('Error: "simParams.NLanes" cannot be <= 0');
        end
    case constants.SCENARIO_URBAN  % ETSI Urban
        simParams.fileObstaclesMap = false;
        % [roadLength]
        % Length of the road to be simulated (m)
        %         [simParams,varargin] = addNewParam(simParams,'rho',35,'Density of vehicles (vehicles/km)','double',fileCfg,varargin{1});
        %         if simParams.rho<=0
        %             error('Error: "simParams.rho" cannot be <= 0');
        %         end
        [simParams,varargin] = addNewParam(simParams,'Nblocks',4,'Number of blocks','integer',fileCfg,varargin{1});
        if simParams.Nblocks<=0
            error('Error: "simParams.Nblocks" cannot be <= 0');
        end
        
        [simParams,varargin] = addNewParam(simParams,'XmaxBlock',250,'Maximum X coordinate per block','double',fileCfg,varargin{1});
        if simParams.XmaxBlock<=0
            error('Error: "simParams.XmaxBlock" cannot be <= 0');
        end
        
        [simParams,varargin] = addNewParam(simParams,'YmaxBlock',433,'Maximum Y coordinate per block','double',fileCfg,varargin{1});
        if simParams.YmaxBlock<=0
            error('Error: "simParams.YmaxBlock" cannot be <= 0');
        end
        
        [simParams,varargin] = addNewParam(simParams,'roadLength',2732,'Road Length (m)','double',fileCfg,varargin{1});
        if simParams.roadLength<=0
            error('Error: "simParams.roadLength" cannot be <= 0');
        end
        
        [simParams,varargin] = addNewParam(simParams,'NLanesBlockH',4,'Number of horizontal lanes per block','integer',fileCfg,varargin{1});
        if simParams.NLanesBlockH<=0
            error('Error: "simParams.NLanesBlockH" cannot be <= 0');
        end
        
        [simParams,varargin] = addNewParam(simParams,'NLanesBlockV',4,'Number of vertical lanes per block','integer',fileCfg,varargin{1});
        if simParams.NLanesBlockV<=0
            error('Error: "simParams.NLanesBlockV" cannot be <= 0');
        end
        
        
        [simParams,varargin] = addNewParam(simParams,'roadWidth',3.5,'Lane width','double',fileCfg,varargin{1});
        if simParams.roadWidth<=0
            error('Error: "simParams.roadWidth" cannot be <= 0');
        end
     
        % Density in v/km in the case of 60km/h according to the TR
        [simParams,varargin] = addNewParam(simParams,'rho',24,'Inter vehicle distance factor in sec (sec * absolute vehicle speed is the density)','double',fileCfg,varargin{1});
        if simParams.rho<=0
            error('Error: "simParams.rho" cannot be <= 0');
        end
        
        [simParams,varargin] = addNewParam(simParams,'vMean',60,'Number of blocks','double',fileCfg,varargin{1});
        if simParams.vMean<=0
            error('Error: "simParams.vMean" cannot be <= 0');
        end
        
        [simParams,varargin] = addNewParam(simParams,'vStDev',0,'Number of blocks','double',fileCfg,varargin{1});
        if simParams.vStDev<0
            error('Error: "simParams.vStDev" cannot be <= 0');
        end
end


% [neighborsSelection]
% Choose whether to use significant neighbors selection
[simParams,varargin] = addNewParam(simParams,'neighborsSelection',false,'If using significant neighbors selection','bool',fileCfg,varargin{1});
if simParams.neighborsSelection~=false && simParams.neighborsSelection~=true
    error('Error: "simParams.neighborsSelection" must be equal to false or true');
end

if simParams.neighborsSelection
    error('This version of the simulator has not been tested with "neighborsSelection"');
    % [Mvicinity]
    % Margin for trajectory vicinity (m)
    %[simParams,varargin] = addNewParam(simParams,'Mvicinity',10,'Margin for trajectory vicinity (m)','integer',fileCfg,varargin{1});
    %if simParams.Mvicinity < 0
    %    error('Error: "simParams.Mvicinity" cannot be negative.');
    %end
end

fprintf('\n');

end
