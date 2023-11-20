function [timeManagement,stationManagement,sinrManagement] = updateVehicleEndingTx11p(idEvent,indexEvent,timeManagement,stationManagement,sinrManagement,phyParams,simParams,outParams)
% A transmission is concluded in IEEE 802.11p

% If the vehicle is exiting the scenario, indexEvent is set to -1
% thus shouldn't call this function
if indexEvent<=0
    error('Call to updateVehicleEndingTx11p with indexEvent<=0');
end
% The number of packets in the queue is reduced
if stationManagement.pckNextAttempt(idEvent) > stationManagement.ITSNumberOfReplicas(idEvent)
    stationManagement.pckBuffer(idEvent) = stationManagement.pckBuffer(idEvent)-1;
end
% The medium is sensed to check if it is free
% (note: 'vState(idEvent)' is set to 9 in order not to contribute
% to the sensed power)
stationManagement.vehicleState(idEvent) = constants.V_STATE_11P_RX; % rx

% Add virtual interference for coex scenario
if isfield(sinrManagement, 'coex_virtualInterference')
    P_RX_MHz = sinrManagement.P_RX_MHz(indexEvent,:) *...
        (stationManagement.vehicleState(stationManagement.activeIDs)==constants.V_STATE_11P_TX) +...
        sinrManagement.coex_virtualInterference(idEvent);
else
    P_RX_MHz = sinrManagement.P_RX_MHz(indexEvent,:) *...
        (stationManagement.vehicleState(stationManagement.activeIDs)==constants.V_STATE_11P_TX);
end
if P_RX_MHz > (phyParams.PrxSensNotSynch/phyParams.BwMHz)
    % If it is busy, State 9 with error is entered
    stationManagement.vehicleState(idEvent) = constants.V_STATE_11P_RX; % rx
    sinrManagement.idFromWhichRx11p(idEvent) = idEvent;
    sinrManagement.interfAverage11p(idEvent) = 0;
    sinrManagement.instantThisSINRavStarted11p(idEvent) = timeManagement.timeNow;
    timeManagement.timeNextTxRx11p(idEvent) = Inf;

    sinrManagement.sinrAverage11p(idEvent) = 0;
    sinrManagement.instantThisSINRstarted11p(idEvent) = timeManagement.timeNow;
else
    % If it is free, then: the idle state is entered if the queue is empty
    % otherwise a new backoff is started
    if stationManagement.pckBuffer(idEvent) == 0
        % If no other packets are in the queue, the node goes
        % in idle state
        stationManagement.vehicleState(idEvent) = constants.V_STATE_11P_IDLE; % idle
        timeManagement.timeNextTxRx11p(idEvent) = Inf;
    elseif stationManagement.pckBuffer(idEvent) >= 1
        % If there are other packets in the queue, a new
        % backoff is initialized and started
        % in this case is retransmission, because the queue only has one
        % packet
        stationManagement.vehicleState(idEvent)=constants.V_STATE_11P_BACKOFF; % backoff
        if simParams.technology ~= constants.TECH_COEX_STD_INTERF || ...
            simParams.coexMethod ~= constants.COEX_METHOD_C || ~simParams.coexCmodifiedCW
            % New NGV packet format (Tx persective), back-to-back copy, no
            % idle time [Michael Fischer, et al. Interoperable NGV PHY
            % Improvements]
            if phyParams.ITSNumberOfReplicasMax > 1
                [stationManagement.nSlotBackoff11p(idEvent), timeManagement.timeNextTxRx11p(idEvent)] =...
                    startNewBackoff11p(timeManagement.timeNow,stationManagement.CW_11p(idEvent),phyParams.ITSRetransBackoffInterval,0);
            else
                [stationManagement.nSlotBackoff11p(idEvent), timeManagement.timeNextTxRx11p(idEvent)] =...
                    startNewBackoff11p(timeManagement.timeNow,stationManagement.CW_11p(idEvent),stationManagement.tAifs_11p(idEvent),phyParams.tSlot);
            end
        else
            relativeTime = timeManagement.timeNow-simParams.coex_superFlength*floor(timeManagement.timeNow/simParams.coex_superFlength);
            subframeIndex = floor(relativeTime/phyParams.Tsf);
            [stationManagement.nSlotBackoff11p(idEvent), timeManagement.timeNextTxRx11p(idEvent)] =...
                coexistenceStartNewBackoff11pModified(...
                    timeManagement.timeNow,stationManagement.CW_11p(idEvent),...
                    stationManagement.tAifs_11p(idEvent),phyParams.tSlot,...
                    subframeIndex,simParams.coex_superframeSF);
        end        
    else
        error('Error: pckBuffer<0');
    end

    %% In both cases, the channel busy ratio is updated 
    if ~isempty(stationManagement.channelSensedBusyMatrix11p) && timeManagement.cbr11p_timeStartBusy(idEvent) ~= -1
       stationManagement.channelSensedBusyMatrix11p(1,idEvent) = stationManagement.channelSensedBusyMatrix11p(1,idEvent) + (timeManagement.timeNow-timeManagement.cbr11p_timeStartBusy(idEvent));
       timeManagement.cbr11p_timeStartBusy(idEvent) = -1;
    end
end

