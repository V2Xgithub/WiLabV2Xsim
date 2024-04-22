function [appParams,simParams,phyParams,outParams,simValues,outputValues,...
    sinrManagement,timeManagement,positionManagement,stationManagement] = mainInit(appParams,simParams,phyParams,outParams,simValues,outputValues,positionManagement)
% Initialization function

%% Init of active vehicles and states
% Move IDvehicle from simValues to station Management
stationManagement.activeIDs = [];

% The simulation starts at time '0'
timeManagement.timeNow = 0;

% State of each node
% Discriminates C-V2X nodes from 11p nodes
if simParams.technology==constants.TECH_ONLY_CV2X
    
    % All vehicles in C-V2X (lte or 5g) are currently in the same state
    % 100 = LTE TX/RX
    stationManagement.vehicleState = constants.V_STATE_LTE_TXRX * ones(simValues.maxID,1);
 
elseif simParams.technology==constants.TECH_ONLY_11P
   
    % The possible states in 11p are four:
    % 1 = IDLE :    the node has no packet and senses the medium as free
    % 2 = BACKOFF : the node has a packet to transmit and senses the medium as
    %               free; it is thus performing the backoff
    % 3 = TX :      the node is transmitting
    % 9 = RX :      the node is sensing the medium as busy and possibly receiving
    %               a packet (the sender it firstly sensed is saved in
    %               idFromWhichRx)
    stationManagement.vehicleState = ones(simValues.maxID,1);

else % coexistence
    
    % Init all as LTE
    stationManagement.vehicleState = constants.V_STATE_LTE_TXRX * ones(simValues.maxID,1);
    %Then use simParams.numVehiclesLTE and simParams.numVehicles11p to
    %initialize
    stationManagement.vehicleState(simParams.numVehiclesLTE+1:simParams.numVehiclesLTE+simParams.numVehicles11p) = constants.V_STATE_11P_IDLE;
end

% RSUs technology set
if appParams.nRSUs>0
    if strcmpi(appParams.RSU_technology,'11p')
        stationManagement.vehicleState(end-appParams.nRSUs+1:end) = constants.V_STATE_11P_IDLE;
    elseif strcmpi(appParams.RSU_technology,'LTE')
        stationManagement.vehicleState(end-appParams.nRSUs+1:end) = constants.V_STATE_LTE_TXRX;
    end
end

%% Initialization of the vectors of active vehicles in each technology, 
% which is helpful to work with smaller vectors and matrixes
stationManagement.activeIDsCV2X = stationManagement.activeIDs.*(stationManagement.vehicleState(stationManagement.activeIDs)==constants.V_STATE_LTE_TXRX);
stationManagement.activeIDsCV2X = stationManagement.activeIDsCV2X(stationManagement.activeIDsCV2X>0);
stationManagement.activeIDs11p = stationManagement.activeIDs.*(stationManagement.vehicleState(stationManagement.activeIDs)~=constants.V_STATE_LTE_TXRX);
stationManagement.activeIDs11p = stationManagement.activeIDs11p(stationManagement.activeIDs11p>0);
stationManagement.activeIDsEnter = [];
stationManagement.activeIDsExit = [];
stationManagement.indexInActiveIDs_ofLTEnodes = zeros(length(stationManagement.activeIDsCV2X),1);
for i=1:length(stationManagement.activeIDsCV2X)
    stationManagement.indexInActiveIDs_ofLTEnodes(i) = find(stationManagement.activeIDs==stationManagement.activeIDsCV2X(i));
end
stationManagement.indexInActiveIDs_of11pnodes = zeros(length(stationManagement.activeIDs11p),1);
for i=1:length(stationManagement.activeIDs11p)
    stationManagement.indexInActiveIDs_of11pnodes(i) = find(stationManagement.activeIDs==stationManagement.activeIDs11p(i));
end

%% Number of vehicles at the current time
outputValues.Nvehicles =  simValues.maxID;
outputValues.NvehiclesTOT = outputValues.NvehiclesTOT + outputValues.Nvehicles;
outputValues.NvehiclesLTE = outputValues.NvehiclesLTE + length(stationManagement.activeIDsCV2X);
outputValues.Nvehicles11p = outputValues.Nvehicles11p + length(stationManagement.activeIDs11p);
outputValues.meanPositionError = zeros(outputValues.Nvehicles, 1);

%% Initialization of packets management 
% Number of packets in the queue of each node
stationManagement.pckBuffer = zeros(simValues.maxID,1);
% Type of packets
% 1 = CAM
% 2 = DENM
stationManagement.pckType = constants.PACKET_TYPE_CAM * ones(simValues.maxID,1);
if appParams.nRSUs>0 && ~strcmpi(appParams.RSU_pckTypeString,'CAM')
    stationManagement.pckType(end-appParams.nRSUs+1:end) = constants.PACKET_TYPE_DENM;
end
% From v 5.4.14 the following are needed for multiple transmissions 
% 'pckReceived' registers if the current packet has already been received
% pckReceived=1 means already received
% pckReceived=0 means never attempted to decode
% pckReceived=-x means attempted to decode 'x' times 
stationManagement.pckReceived = zeros(simValues.maxID,simValues.maxID); % (TO, FROM)
% cumulate SINR
sinrManagement.cumulativeSINR = zeros(simValues.maxID,simValues.maxID); % (TO, FROM)

stationManagement.preambleAlreadyDetected = zeros(simValues.maxID,simValues.maxID); % (TO, FROM)
% counting the CBR of 11p, for many repetitions, only counting the first
% received packets
stationManagement.alreadyStartCBR = zeros(simValues.maxID,simValues.maxID); % (TO, FROM)

% pckNextAttempt is the total times the packet transmitting if countting
% the next packet
stationManagement.pckNextAttempt = ones(simValues.maxID,1);
% pckTxOccurring is used in LTE and set at the beginning of the subframe,
% because pckRemainingTx might change during the subframe
stationManagement.pckTxOccurring = zeros(simValues.maxID,1);

% Parameter for 11p retransmission KPI calculation, the index of active11p
% in the range during earlier retransmission
NactiveIDs11p = length(stationManagement.activeIDs11p);
stationManagement.indexInRaw_earler = zeros(NactiveIDs11p, NactiveIDs11p, length(phyParams.Raw)); % (to, from, idRaw)

% HARQ init
stationManagement.cv2xNumberOfReplicas = phyParams.cv2xNumberOfReplicasMax * ones(simValues.maxID,1);
% IGS-G5 retransmission init
stationManagement.ITSNumberOfReplicas = phyParams.ITSNumberOfReplicasMax * ones(simValues.maxID,1);
%%%%%%%


%% Packet generation
timeManagement.timeGeneratedPacketInTxLTE = -1 * ones(simValues.maxID,1);
if appParams.variabilityGenerationInterval == constants.PACKET_GENERATION_ETSI_CAM
    if simParams.typeOfScenario ~= constants.SCENARIO_TRACE % Not traffic trace
        timeManagement.generationIntervalDeterministicPart = generationPeriodFromSpeed(positionManagement.v,appParams);
    else
        timeManagement.generationIntervalDeterministicPart = appParams.generationInterval * ones(simValues.maxID,1);
    end
else
    timeManagement.generationIntervalDeterministicPart = appParams.generationInterval - appParams.variabilityGenerationInterval/2 + appParams.variabilityGenerationInterval*rand(simValues.maxID,1);
    timeManagement.generationIntervalDeterministicPart(stationManagement.activeIDsCV2X) = appParams.generationInterval;
end
% this additional delay can be used to add a delay from application to
% access layer or to add an artificial delay in the generatioon
timeManagement.addedToGenerationTime = zeros(simValues.maxID,1);

% From v5.2.5: RSU DENM and hpDENM are sent at fixed 20 Hz
if appParams.nRSUs>0 && ~strcmpi(appParams.RSU_pckTypeString,'CAM')
    timeManagement.generationIntervalDeterministicPart(end-appParams.nRSUs+1:end) = 0.05;
end
%timeManagement.generationIntervalDeterministicPart(stationManagement.activeIDsCV2X) = appParams.averageTbeacon;
timeManagement.timeNextPacket = Inf * ones(simValues.maxID,1);
timeManagement.timeNextPacket(stationManagement.activeIDs) = round(timeManagement.generationIntervalDeterministicPart(stationManagement.activeIDs) .* rand(length(stationManagement.activeIDs),1), 10);
timeManagement.timeLastPacket = -1 * ones(simValues.maxID,1); % needed for the calculation of the CBR

timeManagement.dcc_minInterval = zeros(simValues.maxID,1);
stationManagement.dcc11pTriggered = false(1,phyParams.nChannels);
stationManagement.dccLteTriggered = false(1,phyParams.nChannels);
stationManagement.dccLteTriggeredHarq = false(1,phyParams.nChannels);

% Initialization of variables related to transmission in LTE-V2V - must be
% initialized also if 11p is not present
%if simParams.technology~=2 % if not only 11p
    sinrManagement.coex_currentInterfFrom11pToLTE = zeros(simValues.maxID,1);
    sinrManagement.coex_currentInterfEach11pNodeToLTE = zeros(simValues.maxID,simValues.maxID);
%end
% Initialization of variables related to transmission in 11p - must be
% initialized also if LTE is not present
%if simParams.technology~=1 % if not only LTE
   sinrManagement.coex_InterfFromLTEto11p = zeros(simValues.maxID,1);
%end

%% Initialize propagation
% Tx power vectors
if isfield(phyParams,'P_ERP_MHz_CV2X')
    if phyParams.FixedPdensity
        % Power density is fixed, must be scaled based on subchannels
        phyParams.P_ERP_MHz_CV2X = phyParams.P_ERP_MHz_CV2X * (phyParams.NsubchannelsBeacon/phyParams.NsubchannelsFrequency);
    end %else % Power is fixed, independently to the used bandwidth
    phyParams.P_ERP_MHz_CV2X = phyParams.P_ERP_MHz_CV2X*ones(simValues.maxID,1);
else
    phyParams.P_ERP_MHz_CV2X = -ones(simValues.maxID,1);
end
if isfield(phyParams,'P_ERP_MHz_11p')
    phyParams.P_ERP_MHz_11p = phyParams.P_ERP_MHz_11p*ones(simValues.maxID,1);
else
    phyParams.P_ERP_MHz_11p = -ones(simValues.maxID,1);
end

% Vehicles in a technology have the power to -1000 in the other; this is helpful for
% verification purposes
phyParams.P_ERP_MHz_CV2X(stationManagement.vehicleState ~= constants.V_STATE_LTE_TXRX) = -1000;
phyParams.P_ERP_MHz_11p(stationManagement.vehicleState == constants.V_STATE_LTE_TXRX) = -1000;

%% Channels
stationManagement.vehicleChannel = ones(simValues.maxID,1);
% NOTE: sinrManagement.mcoCoefficient( RECEIVER, TRANSMITTER) 
sinrManagement.mcoCoefficient = ones(simValues.maxID,simValues.maxID);
if phyParams.nChannels>1
    [stationManagement,sinrManagement,phyParams] = mco_channelInit(stationManagement,sinrManagement,simValues,phyParams);
end

% Shadowing matrix
sinrManagement.Shadowing_dB = randn(length(stationManagement.activeIDs),length(stationManagement.activeIDs))*phyParams.stdDevShadowLOS_dB;
sinrManagement.Shadowing_dB = triu(sinrManagement.Shadowing_dB,1)+triu(sinrManagement.Shadowing_dB)';

%% Management of coordinates and distances
% Init knowledge at eNodeB of nodes positions
%if simParams.technology~=2 % not only 11p
if sum(stationManagement.vehicleState(stationManagement.activeIDs)==constants.V_STATE_LTE_TXRX)>0    
    % Number of groups for position update
 	positionManagement.NgroupPosUpdate = round(simParams.Tupdate/appParams.allocationPeriod);
    % Assign update period to all vehicles (introduce a position update delay)
    positionManagement.posUpdateAllVehicles = randi(positionManagement.NgroupPosUpdate,simValues.maxID,1);
else
    positionManagement.NgroupPosUpdate = -1;
end

% Copy real coordinates into estimated coordinates at eNodeB (no positioning error)
positionManagement.XvehicleEstimated = positionManagement.XvehicleReal;
positionManagement.YvehicleEstimated = positionManagement.YvehicleReal;

% Call function to compute distances
[positionManagement] = computeDistance (positionManagement);

% Position Delay
% timetables of old positions
n_vehicles = length(positionManagement.XvehicleReal);
positionManagement.XvehicleHistory = cell(n_vehicles, 1);
positionManagement.YvehicleHistory = cell(n_vehicles, 1);
for i = 1:n_vehicles
    positionManagement.XvehicleHistory{i} = timetable(Size=[0 1], VariableTypes={'double'}, TimeStep=seconds(simParams.positionTimeResolution));
    positionManagement.YvehicleHistory{i} = timetable(Size=[0 1], VariableTypes={'double'}, TimeStep=seconds(simParams.positionTimeResolution));
end


% Save positionManagement.distance matrix
positionManagement.XvehicleRealOld = positionManagement.XvehicleReal;
positionManagement.YvehicleRealOld =  positionManagement.YvehicleReal;
positionManagement.distanceRealOld = positionManagement.distanceReal;
positionManagement.angleOld = zeros(length(positionManagement.XvehicleRealOld),1);

% Computation of the channel gain
% 'dUpdate': vector used for the calculation of correlated shadowing
dUpdate = zeros(0, 0);
[sinrManagement,simValues.Xmap,simValues.Ymap,phyParams.LOS] = computeChannelGain(sinrManagement,stationManagement,positionManagement,phyParams,simParams,dUpdate);

% Update of the neighbors
[positionManagement,stationManagement] = computeNeighbors(stationManagement,positionManagement,phyParams);

% The variable 'timeManagement.timeNextPosUpdate' is used for updating the positions
timeManagement.timeNextPosUpdate = round(simParams.positionTimeResolution, 10);
positionManagement.NposUpdates = 1;

% Number of neighbors
[outputValues,~,~,~] = updateAverageNeighbors(simParams,stationManagement,outputValues,phyParams);

% Init of matrixes counting vehicles in range
if outParams.printUpdateDelay && outParams.printWirelessBlindSpotProb
    outputValues.enteredInRangeLTE = -1 * ones(simValues.maxID,simValues.maxID,length(phyParams.Raw));
    for iRaw = 1:length(phyParams.Raw)
        valuesEnteredInRange = outputValues.enteredInRangeLTE(:,:,iRaw);
        % fixme: when using tracefile, there may not be consecutive
        % activeIDs (e.g. max ID in 140 cars is 150). But distanceReal has
        % the number of activesIDs' rows and columns
        valuesEnteredInRange(stationManagement.activeIDsCV2X,stationManagement.activeIDsCV2X) = (positionManagement.distanceReal(stationManagement.activeIDsCV2X,stationManagement.activeIDsCV2X)<=phyParams.Raw(iRaw))-1;
        outputValues.enteredInRangeLTE(:,:,iRaw) = valuesEnteredInRange - diag(diag(valuesEnteredInRange+1));        
    end
    outputValues.enteredInRange11p = -1 * ones(simValues.maxID,simValues.maxID,length(phyParams.Raw));
    for iRaw = 1:length(phyParams.Raw)
        valuesEnteredInRange = outputValues.enteredInRange11p(:,:,iRaw);
        valuesEnteredInRange(stationManagement.activeIDs11p,stationManagement.activeIDs11p) = (positionManagement.distanceReal(stationManagement.activeIDs11p,stationManagement.activeIDs11p)<=phyParams.Raw(iRaw))-1;
        outputValues.enteredInRange11p(:,:,iRaw) = valuesEnteredInRange - diag(diag(valuesEnteredInRange+1));        
    end
end

% Floor coordinates for PRRmap creation (if enabled)
if simParams.typeOfScenario==constants.SCENARIO_TRACE && outParams.printPRRmap % Only traffic traces
    simValues.XmapFloor = floor(simValues.Xmap);
    simValues.YmapFloor = floor(simValues.Ymap);
end

%% Initialization of variables related to transmission in IEEE 802.11p
% 'timeNextTxRx11p' stores the instant of the next backoff or
% transmission end, if the station is 11p - not used in LTE and therefore
% init to inf in all cases
timeManagement.timeNextTxRx11p = Inf * ones(simValues.maxID,1);
%
if sum(stationManagement.vehicleState(stationManagement.activeIDs)~=constants.V_STATE_LTE_TXRX)>0
% if not only LTE
    % When a node senses the medium as busy and goes to State RX, the
    % transmitting node is saved in 'idFromWhichRx'
    % Note that once a node starts receiving a signal, it will not be able to
    % synchronize to a different signal, thus there is no reason to change this
    % value before exiting from State RX
    % 'idFromWhichRx' is set to the id of the node if the node is not receiving
    % (a number must be set in order to avoid exceptions running the code that follow)
    sinrManagement.idFromWhichRx11p = (1:simValues.maxID)';

    % Possible events: A) New packet, B) Backoff ends, C) Transmission end;
    % A - 'timeNextPacket' stores the instant of the next message generation; the
    % first instant is randomly chosen within 0-Tbeacon
    %timeManagement.timeNextGeneration11p = timeManagement.timeNextPacket;
    timeManagement.cbr11p_timeStartBusy = -1 * ones(simValues.maxID,1); % needed for the calculation of the CBR
    timeManagement.cbr11p_timeStartMeasInterval = -1 * ones(simValues.maxID,1); % needed for the calculation of the CBR

    % Total power being received from nodes are transmitting
    sinrManagement.rxPowerInterfLast11p = zeros(simValues.maxID,1);
    sinrManagement.rxPowerUsefulLast11p = zeros(simValues.maxID,1);
 
    % Instant when the power store in 'PrTot' was calculated; it will remain
    % constant until a new calculation will be performed
    %sinrManagement.instantThisPrStarted11p = Inf;
    sinrManagement.instantThisSINRstarted11p = ones(simValues.maxID,1)*Inf;

    % Average SINR - This parameter is irrelevant if the node is not in state V_STATE_11P_RX
    sinrManagement.sinrAverage11p = zeros(simValues.maxID,1);
    sinrManagement.interfAverage11p = zeros(simValues.maxID,1);

    % Instant when the average SINR of a node in State V_STATE_11P_RX was initiated - This
    % parameter is irrelevant if the node is not in State V_STATE_11P_RX
    sinrManagement.instantThisSINRavStarted11p = Inf * ones(simValues.maxID,1);

    % Number of slots for the backoff - Set to '-1' when not initiated
    stationManagement.nSlotBackoff11p = -1 * ones(simValues.maxID,1);
    % Init of AIFS and CW per station
    stationManagement.CW_11p = ones(simValues.maxID,1) * phyParams.CW;
    stationManagement.tAifs_11p = ones(simValues.maxID,1) * phyParams.tAifs;
    % Removal from struct to avoid mistakes
    %phyParams = rmfield( phyParams , 'CW' );
    %phyParams = rmfield( phyParams , 'AifsN' );
    phyParams = rmfield( phyParams , 'tAifs' );
    if appParams.nRSUs>0 && ~strcmpi(appParams.RSU_pckTypeString,'CAM')
        if strcmpi(appParams.RSU_pckTypeString,'hpDENM')
            % High priority DENM: CWmax=3, AIFS=58us
            stationManagement.CW_11p(end-appParams.nRSUs+1:end) = 3;
            stationManagement.tAifs_11p(end-appParams.nRSUs+1:end) = 58e-6;
        elseif strcmpi(appParams.RSU_pckTypeString,'DENM')
            % DENM: CWmax=7, AIFS=71us
            stationManagement.CW_11p(end-appParams.nRSUs+1:end) = 7;
            stationManagement.tAifs_11p(end-appParams.nRSUs+1:end) = 71e-6;
        else
            error('Something wrong with the packet type of RSUs');
        end
    end
    
    % Prepare matrix for update delay computation (if enabled)
    if outParams.printUpdateDelay
        % Reset update time of vehicles that are outside the scenario
        allIDOut = setdiff(1:simValues.maxID,stationManagement.activeIDs);
        simValues.updateTimeMatrix11p(allIDOut,:) = -1;
        simValues.updateTimeMatrix11p(:,allIDOut) = -1;
    end

    % Prepare matrix for data age computation (if enabled)
    if outParams.printDataAge
        % Reset update time of vehicles that are outside the scenario
        allIDOut = setdiff(1:simValues.maxID,stationManagement.activeIDs);
        simValues.dataAgeTimestampMatrix11p(allIDOut,:) = -1;
        simValues.dataAgeTimestampMatrix11p(:,allIDOut) = -1;
    end
    
    % Initialization of a matrix containing the duration the channel has
    % been sensed as busy, if used
    % Note: 11p CBR is calculated over a fixed number of beacon periods; 
    % this implies that if they are not all the same among vehciles, then 
    % the duration of the sensing interval is not the same
    %if outParams.printCBR || (simParams.technology==4 && simParams.coexMethod~=0 && simParams.coex_slotManagement==2 && simParams.coex_cbrTotVariant==2)
    %    stationManagement.channelSensedBusyMatrix11p = zeros(ceil(simParams.cbrSensingInterval/appParams.averageTbeacon),simValues.maxID);        
    %else
    %    % set to empty if not used
    %    stationManagement.channelSensedBusyMatrix11p = [];
    %end

    % Conversion of sensing power threshold when hidden node probability is active
    if outParams.printHiddenNodeProb
        %% TODO - needs update
        error('Not updated in v5');
        %if outParams.Pth_dBm==1000
        %    outParams.Pth_dBm = 10*log10(phyParams.gammaMin*phyParams.PnBW*(appParams.RBsBeacon/2))+30;
        %end
        %outParams.Pth = 10^((outParams.Pth_dBm-30)/10);
    end

    % Initialize vector containing variable beacon periodicity
    if simParams.technology==constants.TECH_ONLY_11P && appParams.variableBeaconSize
        % Generate a random integer for each vehicle indicating the period of
        % transmission (1 corresponds to the transmission of a big beacon)
        stationManagement.variableBeaconSizePeriodicity = randi(appParams.NbeaconsSmall+1,simValues.maxID,1);
    else
        stationManagement.variableBeaconSizePeriodicity = 0;
    end

end % end of not only LTE

%% Coexistence
% Settings of Coexistence must be before BR assignment initialization
timeManagement.coex_timeNextSuperframe = inf * ones(simValues.maxID,1);
sinrManagement.coex_virtualInterference = zeros(simValues.maxID,1);
sinrManagement.coex_averageTTIinterfFrom11pToLTE = zeros(simValues.maxID,1);
if simParams.technology==constants.TECH_COEX_STD_INTERF 
    if simParams.coexMethod~=constants.COEX_METHOD_NON
        [timeManagement,stationManagement,sinrManagement,simParams,phyParams] = mainInitCoexistence(timeManagement,stationManagement,sinrManagement,simParams,simValues,phyParams,appParams);
    end

    % Initialization of the matrix coex_correctSCIhistory
    sinrManagement.coex_correctSCIhistory = zeros(appParams.NbeaconsT*appParams.NbeaconsF,simValues.maxID);
end

% vector sensedPowerByLteNo11p created (might remain void)
sinrManagement.sensedPowerByLteNo11p = [];


%% Initialization of variables related to transmission in IEEE 802.11p
% Initialize the beacon resource used by each vehicle
stationManagement.BRid = -2*ones(simValues.maxID,phyParams.cv2xNumberOfReplicasMax);
stationManagement.BRid(stationManagement.activeIDs,:) = -1;
%
% Initialize next LTE event to inf
timeManagement.timeNextCV2X = inf;

% if not only 11p
if ismember(constants.V_STATE_LTE_TXRX, stationManagement.vehicleState)
   % Initialization of resouce allocation algorithms in LTE-V2X
   if ismember(simParams.BRAlgorithm, [constants.REASSIGN_BR_REUSE_DIS_SCHEDULED_VEH,...
           constants.REASSIGN_BR_MAX_REUSE_DIS, constants.REASSIGN_BR_MIN_REUSE_POW])
        % Number of groups for scheduled resource reassignment (BRAlgorithm=2, 7 or 10)
        stationManagement.NScheduledReassignLTE = round(simParams.Treassign/appParams.allocationPeriod);

        % Assign update period to vehicles (BRAlgorithm=2, 7 or 10)
        stationManagement.scheduledReassignLTE = randi(stationManagement.NScheduledReassignLTE,simValues.maxID,1);
    end

    if simParams.BRAlgorithm == constants.REASSIGN_BR_STD_MODE_4
        % Find min and max values for random counter (BRAlgorithm=18)
        [simParams.minRandValueMode4,simParams.maxRandValueMode4] = findRCintervalAutonomous(appParams.allocationPeriod,simParams);

        % timeManagement.timeOfResourceAllocationLTE is for possible use in the future
        % Inizialization of instant when the reselection is evaluated
        %timeManagement.timeOfResourceAllocationLTE = -1*ones(simValues.maxID,1);
        %timeManagement.timeOfResourceAllocationLTE(stationManagement.activeIDsCV2X) = timeManagement.timeNextPacket(stationManagement.activeIDsCV2X);

        % Initialize reselection counter (BRAlgorithm=18)
        stationManagement.resReselectionCounterCV2X = Inf*ones(simValues.maxID,1);
        stationManagement.resReselectionCounterCV2X(stationManagement.activeIDs) = (simParams.minRandValueMode4-1) + randi((simParams.maxRandValueMode4-simParams.minRandValueMode4)+1,1,length(stationManagement.activeIDs));
        % COMMENTED: Set value 0 to vehicles that are blocked
        % stationManagement.resReselectionCounterCV2X(stationManagement.BRid==-1)=0;
        % Sets the Reselection counter to 1 for all vehicles when dynamic scheduling is active
        if simParams.dynamicScheduling == true
            stationManagement.resReselectionCounterCV2X(stationManagement.activeIDs) = ones(simValues.maxID,1);
        end

        % Initialize newDataIndicator vector for resource re-evaluation (BRAlgorithm=18)
        stationManagement.newDataIndicator = ones(simValues.maxID,1);

        % Initialization of sensing matrix (BRAlgorithm=18)
        stationManagement.sensingMatrixCV2X = zeros(ceil(simParams.TsensingPeriod/appParams.allocationPeriod),appParams.Nbeacons,simValues.maxID);
        stationManagement.knownUsedMatrixCV2X = zeros(appParams.Nbeacons,simValues.maxID);

        % First random allocation 
        %[stationManagement.BRid,~] = BRreassignmentRandom(simValues.IDvehicle,stationManagement.BRid,simParams,sinrManagement,appParams);
        %[stationManagement.BRid(stationManagement.activeIDs,1),~] = BRreassignmentRandom(stationManagement.activeIDs,simParams,timeManagement,sinrManagement,stationManagement,phyParams,appParams);
        for j=1:phyParams.cv2xNumberOfReplicasMax
            % From v5.4.16, when HARQ is active, n random
            % resources are selected, one per each replica 
            [stationManagement.BRid(stationManagement.activeIDs,j),~] = BRreassignmentRandom(simParams.T1autonomousModeTTIs,simParams.T2autonomousModeTTIs,stationManagement.activeIDs,simParams,timeManagement,sinrManagement,stationManagement,phyParams,appParams);
        end      
        % Must be ordered with respect to the packet generation instant
        % (Vittorio 5.5.3)
        % subframeGen = ceil(timeManagement.timeNextPacket/phyParams.Tsf);
        TTIGen = ceil(timeManagement.timeNextPacket(stationManagement.activeIDs)/phyParams.TTI);
        TTI_BR = ceil(stationManagement.BRid(stationManagement.activeIDs)/appParams.NbeaconsF);
        stationManagement.BRid(stationManagement.activeIDs) = stationManagement.BRid(stationManagement.activeIDs) + (TTI_BR<=TTIGen) * appParams.Nbeacons;
        stationManagement.BRid(stationManagement.activeIDs) = sort(stationManagement.BRid(stationManagement.activeIDs),2);
        stationManagement.BRid(stationManagement.activeIDs) = stationManagement.BRid(stationManagement.activeIDs) - (stationManagement.BRid(stationManagement.activeIDs)>appParams.Nbeacons) * appParams.Nbeacons;
        
        % vector correctSCImatrixCV2X created
        stationManagement.correctSCImatrixCV2X = [];
    end

    % if simParams.BRAlgorithm==101
        % The random allocation is performed when the packet is generated
        % Therefore nothing needs to be done here
    % end

    % FD exploitation initialization
    % [stationManagement] = FDinit(simParams,stationManagement,phyParams,simValues);
    
    % Initialization of lambda: SINR threshold for BRAlgorithm 9
    if simParams.BRAlgorithm == constants.REASSIGN_BR_POW_CONTROL
        stationManagement.lambdaLTE = phyParams.sinrThresholdCV2X_LOS;
    end

    % Conversion of sensing power threshold when hidden node probability is active
    if outParams.printHiddenNodeProb
        %% TODO - needs update
        error('Not updated in v5');
        %if outParams.Pth_dBm==1000
        %    outParams.Pth_dBm = 10*log10(phyParams.gammaMin*phyParams.PnRB*(appParams.RBsBeacon/2))+30;
        %end
        %outParams.Pth = 10^((outParams.Pth_dBm-30)/10);
        %outParams.PthRB = outParams.Pth/(appParams.RBsBeacon/2);
    end
    
    % The next instant in C-V2X will be the beginning
    % of the first TTI in 0
    timeManagement.timeNextCV2X = 0;
    timeManagement.ttiCV2Xstarts = true;

    % The channel busy ratio of C-V2X is initialized
    sinrManagement.cbrCV2X = zeros(simValues.maxID,1);
    sinrManagement.cbrLTE_coexLTEonly = zeros(simValues.maxID,1);
end % end of if simParams.technology ~= 2 % not only 11p

% if CBR is active, set the next CBR instant - else set to inf
if simParams.cbrActive
    
    if simParams.technology == constants.TECH_COEX_STD_INTERF && simParams.coexMethod == constants.COEX_METHOD_A
        if mod(simParams.coex_superFlength/simParams.cbrSensingInterval, 1) ~= 0 && ...
           mod(simParams.cbrSensingInterval/simParams.coex_superFlength, 1) ~= 0
            error('coex, Method A, cbrSensingInterval must be a multiple or a divisor of coex_superFlength');
        end
    end   
    
    timeManagement.timeNextCBRupdate = simParams.cbrSensingInterval/simParams.cbrSensingIntervalDesynchN;
    stationManagement.cbr_subinterval = randi(simParams.cbrSensingIntervalDesynchN,simValues.maxID,1);
    
    timeManagement.cbr11p_timeStartMeasInterval(stationManagement.activeIDs11p) = 0;
    timeManagement.cbr11p_timeStartBusy = -1 * ones(simValues.maxID,1);
%     if simParams.technology==4 && simParams.coexMethod==1
%         timeManagement.cbr11p_timeStartBusy(stationManagement.activeIDs .* timeManagement.coex_superframeThisIsLTEPart(stationManagement.activeIDs)) = -1;
%     end    
    if simParams.technology~=constants.TECH_ONLY_CV2X % Not only C-V2X
        stationManagement.channelSensedBusyMatrix11p = zeros(ceil(simParams.cbrSensingInterval/appParams.allocationPeriod),simValues.maxID);        
    end
    
    nCbrIntervals = ceil(simParams.simulationTime/simParams.cbrSensingInterval);
    stationManagement.cbr11pValues = -1 * ones(simValues.maxID,nCbrIntervals); 
    stationManagement.cbrCV2Xvalues = -1 * ones(simValues.maxID,nCbrIntervals);     
    stationManagement.coex_cbrLteOnlyValues = -1 * ones(simValues.maxID,nCbrIntervals); 

%     %% =========
%     % Plot figs of related paper, could be commented in other case.
%     % Please check .../codeForPaper/Zhuofei2023Repetition/fig6
%     % Only for IEEE 802.11p, highway scenario. 
%     stationManagement.ITSReplicasLog = zeros(simValues.maxID,nCbrIntervals);
%     stationManagement.positionLog = zeros(simValues.maxID,nCbrIntervals);
%     %% =========
else
    timeManagement.timeNextCBRupdate = inf;
end

% BRid set to -1 for non-LTE
stationManagement.BRid(stationManagement.vehicleState~=constants.V_STATE_LTE_TXRX,:)=-3;

% Temporary
% %% INIT FOR MCO
% if simParams.mco_nVehInterf>0
%     sinrManagement.mco_shadowingInterferers_dB = [];
%     % mco_perceivedInterference is a matrix with one line per position update step
%     % and one column per interferer
%     outputValues.mco_perceivedInterferenceIndex = 1;
%     outputValues.mco_perceivedInterference = -1*ones(10000,simParams.mco_nVehInterf+1);
%     [sinrManagement,positionManagement,outputValues] = mco_interfVehiclesCalculate(timeManagement,stationManagement,sinrManagement,positionManagement,phyParams,appParams,outputValues,simParams);
% end

%% Initialization of time variables
% Stores the instant of the next event among all possible events;
% initially set to the first packet generation
timeManagement.timeNextEvent = Inf * ones(simValues.maxID,1);
timeManagement.timeNextEvent(stationManagement.activeIDs) = timeManagement.timeNextPacket(stationManagement.activeIDs);
