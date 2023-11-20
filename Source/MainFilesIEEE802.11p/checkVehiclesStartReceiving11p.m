function [timeManagement,stationManagement,sinrManagement,outputValues] = checkVehiclesStartReceiving11p(idEvent,indexEventInActiveIDs,timeManagement,stationManagement,sinrManagement,simParams,phyParams,outParams,outputValues)

% Variable used for easier reading
activeIDs = stationManagement.activeIDs;

if idEvent==-1
    sameChannel = 1;
else
    sameChannel = (stationManagement.vehicleChannel==stationManagement.vehicleChannel(idEvent));
end

%% The nodes that start receiving are identified
% They are those that:
% A.  are in idle or in backoff (do not transmit and are not
% already receiving)
% B. do not end the backoff in the next time slot (a 1e-10
% margin is added due to problems with the representation of
% floating point numbers)
% C+D. receive this signal with sufficient quality (= (C) are able to
% decode the preamble, since SINR>SINR_min) OR (D) do not receive the
% signal with sufficient quality, but perceive the channel as
% busy
rxPowerTotNow_MHz = sinrManagement.P_RX_MHz * (stationManagement.vehicleState(activeIDs)==constants.V_STATE_11P_TX);

idleOBU = (stationManagement.vehicleState(activeIDs)==constants.V_STATE_11P_IDLE) |...
    (stationManagement.vehicleState(activeIDs)==constants.V_STATE_11P_BACKOFF);
notEndingBackoff = timeManagement.timeNextTxRx11p(activeIDs) >= (timeManagement.timeNow+phyParams.tSlot-1e-10);

alreadyReceingAnotherPreamble = ( stationManagement.vehicleState(activeIDs)==constants.V_STATE_11P_RX & ...
    ( (timeManagement.timeNow-sinrManagement.instantThisSINRstarted11p(activeIDs)) < 4e-6 ...
    | sinrManagement.idFromWhichRx11p(activeIDs) == activeIDs ) );

if indexEventInActiveIDs>0
    % Normal case - one node is transmitting

    % Approach 1: I check the SINR and if above a threshold I start decoding
    % The SINR corresponding to PER = 0.9 is used
    preambelSINR = sinrManagement.P_RX_MHz(:,indexEventInActiveIDs) ./ (phyParams.Pnoise_MHz + (rxPowerTotNow_MHz-sinrManagement.P_RX_MHz(:,indexEventInActiveIDs)) + sinrManagement.coex_InterfFromLTEto11p(activeIDs)/phyParams.BwMHz);
    
    % if preambel of the same packet was detected earlier, the following
    % preamble is automatically detected
    decodingThisPreamble = stationManagement.preambleAlreadyDetected(:,indexEventInActiveIDs) | (preambelSINR > phyParams.sinrThreshold11p_preamble);  

    % update detected preamble
    stationManagement.preambleAlreadyDetected(:,indexEventInActiveIDs) = decodingThisPreamble;

    % % Approach 2: I check that the received power is above the sensing
    % % threshold for decodable signals (-85 dBm in specs)
    % C = (sinrManagement.P_RX_MHz(:,indexEventInActiveIDs)*phyParams.BwMHz) >= phyParams.PrxSensWhenSynch;
    % - Approach 1 is used - gives significantly better performance
    %
    % From version 5.3.1, the channel check is added
    % If the channel is not the same, then C is set to 0
    decodingThisPreamble = decodingThisPreamble & sameChannel(stationManagement.activeIDs);
else
    % Only interference, with no real useful signal
    % In this case C is always 'false'
    decodingThisPreamble = zeros(length(sinrManagement.P_RX_MHz(:,1)),1);
end
% in D, an additional factor 'coex_virtualInterference' is used to block all 11p transmissions (used
% in coexistence method A) - it could be added also in C, but adding it in D
% is sufficient
receivingHighPower = (rxPowerTotNow_MHz*phyParams.BwMHz +...
    sinrManagement.coex_InterfFromLTEto11p(activeIDs) + ...
    sinrManagement.coex_virtualInterference(activeIDs)) >= phyParams.PrxSensNotSynch;

% Revised From version 5.3.2
ifStartReceiving = (alreadyReceingAnotherPreamble & decodingThisPreamble) | ...
                   (idleOBU & notEndingBackoff & (decodingThisPreamble | receivingHighPower));

%%
% Focusing on those that start receiving
% The backoff is freezed if the node was in vState==2 (backoff)
% State is set to 9 (receiving)
% SINR is reset and initial instant is set to now
% 'timeNextTxRx' is set to infinity
% The node from which receiving is set
vehiclesFreezingList=activeIDs(ifStartReceiving & (stationManagement.vehicleState(activeIDs)==constants.V_STATE_11P_BACKOFF));
for idVehicle = vehiclesFreezingList'
    stationManagement.nSlotBackoff11p(idVehicle) =...
        freezeBackoff11p(timeManagement.timeNow,timeManagement.timeNextTxRx11p(idVehicle),...
        phyParams.tSlot,stationManagement.nSlotBackoff11p(idVehicle));
    
    % DEBUG BACKOFF
%     printDebugBackoff11p(timeManagement.timeNow,'11p backoff freeze',idVehicle,stationManagement,outParams,timeManagement)
end
stationManagement.vehicleState(activeIDs(ifStartReceiving)) = constants.V_STATE_11P_RX;
sinrManagement.sinrAverage11p(activeIDs(ifStartReceiving)) = 0;
sinrManagement.interfAverage11p(activeIDs(ifStartReceiving)) = 0;
sinrManagement.instantThisSINRavStarted11p(activeIDs(ifStartReceiving)) = timeManagement.timeNow;
sinrManagement.instantThisSINRstarted11p(activeIDs(ifStartReceiving)) = timeManagement.timeNow;
timeManagement.timeNextTxRx11p(activeIDs(ifStartReceiving)) = Inf;

%% Update of idFromWhichRx11p
if idEvent>0
    sinrManagement.idFromWhichRx11p(activeIDs(ifStartReceiving)) = idEvent * sameChannel(activeIDs(ifStartReceiving)) + activeIDs(ifStartReceiving) .* (~sameChannel(activeIDs(ifStartReceiving)));
   
    % Coexistence   
    % Save 11p as detected by LTE if the SINR is above the threshold
    if simParams.technology == constants.TECH_COEX_STD_INTERF && simParams.coexMethod==constants.COEX_METHOD_C
        sinrManagement.coex_lteDetecting11pTx(activeIDs) = stationManagement.vehicleState(activeIDs)==constants.V_STATE_LTE_TXRX & decodingThisPreamble;
    end

    % Coexistence, dynamic slots, calculation of CBR_11p: LTE nodes check if
    % starting detecting an 11p message
    if simParams.technology == constants.TECH_COEX_STD_INTERF && simParams.coexMethod~=constants.COEX_METHOD_NON && simParams.coex_slotManagement==constants.COEX_SLOT_DYNAMIC && simParams.coex_cbrTotVariant==2
        % In this case, nodes must be LTE, not already
        % detecting, receiving with sufficient quality
        % 
        % The inteference is saved in sensedPowerByLteNo11p per beacon
        % resource and needs to be converted into "per subchannel"
        if ~isempty(sinrManagement.sensedPowerByLteNo11p)
            interferenceFromLTEnodesPerSubframe = (sum(sinrManagement.sensedPowerByLteNo11p)/length(sinrManagement.sensedPowerByLteNo11p(:,1)))';
        else
            interferenceFromLTEnodesPerSubframe = 0; %zeros(length(),1);
        end
%         sinrThr=phyParams.LOS(stationManagement.indexInActiveIDs_ofLTEnodes,indexEventInActiveIDs).*phyParams.sinrThreshold11p_LOS+...
%                 (1-phyParams.LOS(stationManagement.indexInActiveIDs_ofLTEnodes,indexEventInActiveIDs)).*phyParams.sinrThreshold11p_NLOS;
        % retransmission may should be considered here
        decodingThePreamble = (sinrManagement.P_RX_MHz(stationManagement.indexInActiveIDs_ofLTEnodes,indexEventInActiveIDs) ./ (phyParams.Pnoise_MHz + (rxPowerTotNow_MHz(stationManagement.activeIDsCV2X)-sinrManagement.P_RX_MHz(stationManagement.indexInActiveIDs_ofLTEnodes,indexEventInActiveIDs)) + interferenceFromLTEnodesPerSubframe) > phyParams.sinrThreshold11p_preamble);
        ifStartDetecting11p = (stationManagement.vehicleState(stationManagement.activeIDsCV2X)==constants.V_STATE_LTE_TXRX)...
            & ~sinrManagement.coex_detecting11p(stationManagement.activeIDsCV2X)...
            & decodingThePreamble;
        sinrManagement.coex_detecting11p(stationManagement.activeIDsCV2X(ifStartDetecting11p)) = true; 
        timeManagement.cbr11p_timeStartBusy(stationManagement.activeIDsCV2X(ifStartDetecting11p)) = timeManagement.timeNow;
    end    
else
    % if State 9(V_STATE_11P_RX) is due to interference, the idFromWhichRx must be set to
    % 'self'
    sinrManagement.idFromWhichRx11p(activeIDs(ifStartReceiving)) = activeIDs(ifStartReceiving);
end
%%

%% The channel busy ratio is updated 
% A different threshold (-85 dBm in ETSI EN 302 571) needs to be considered in this case
if simParams.cbrActive && ~isempty(stationManagement.channelSensedBusyMatrix11p) && idEvent>0
    % The cbr11p_timeStartBusy must be set to those that were not sensing
    % the channel as busy (cbr11p_timeStartBusy=-1) and are now sensing it
    % busy

    % First of all, E is calculated, which are those nodes transmitting
    % or perceiving interference above -85
    higherThanThreshold = (rxPowerTotNow_MHz*phyParams.BwMHz + sinrManagement.coex_InterfFromLTEto11p(activeIDs)) >= phyParams.PrxSensWhenSynch;
    
    % only count the first receiving repetition
%     nodesMightStartTiming = (stationManagement.vehicleState(activeIDs)==3) | ...
%         (decodingThisPreamble & higherThanThreshold);
    nodesMightStartTiming = (activeIDs==indexEventInActiveIDs) | ...
        (decodingThisPreamble & higherThanThreshold);

    % Then the nodes starting the channel busy are calculated
    ifStartCBR = (timeManagement.cbr11p_timeStartBusy(activeIDs)==-1 & nodesMightStartTiming);
    % only count the first time that it detect the preamble and sensing the high power at the
    % same time
    ifFirstTimeStartCBR = (ifStartCBR - stationManagement.alreadyStartCBR(:,indexEventInActiveIDs)) > 0;
    stationManagement.alreadyStartCBR(:,indexEventInActiveIDs) = stationManagement.alreadyStartCBR(:,indexEventInActiveIDs) | ifStartCBR;
    
    % Time is updated
    timeManagement.cbr11p_timeStartBusy(activeIDs(ifFirstTimeStartCBR)) = timeManagement.timeNow;
end
