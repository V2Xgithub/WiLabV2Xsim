function [timeManagement,stationManagement,sinrManagement,outputValues] = newPacketIn11p(idEvent,indexEvent,outParams,simParams,positionManagement,phyParams,timeManagement,stationManagement,sinrManagement,outputValues,appParams)
% A new packet is generated in IEEE 802.11p

% The queue is updated
% If one packet is already enqueued, the old packet is removed, the
% number of errors is updated, and the number of packets discarded
% is increased by one
stationManagement.pckBuffer(idEvent) = stationManagement.pckBuffer(idEvent)+1;

%% Removed from here since version 5.2.9 - now in the main
% Part dealing with the channel busy ratio
%if ~isempty(stationManagement.channelSensedBusyMatrix11p)
%if outParams.printCBR
%    [timeManagement,stationManagement] = cbrUpdate11p(timeManagement,idEvent,stationManagement,simParams);
%end
%
%%

% Part dealing with new packets introduced in a non-empty queue
if stationManagement.pckBuffer(idEvent)>1
    % Count as a blocked transmission (previous packet is discarded)
    % Condsider only 11p
    % program not going to this "if" state, when the copy of packet has
    % been transmitted one or more times
    if stationManagement.pckTxOccurring(idEvent)==0
        if ~simParams.neighborsSelection
            allNeighbors = (stationManagement.activeIDs11p~=idEvent);
        else
            % stationManagement.activeIDs(indexEvent) -> idEvent, same
            indexEvent11p = (stationManagement.activeIDs11p == idEvent);
            allNeighbors = ismember(stationManagement.activeIDs11p,stationManagement.neighborsID11p(indexEvent11p,:));
        end
        distance11pFromTx = positionManagement.distanceReal(stationManagement.vehicleState(stationManagement.activeIDs)~=constants.V_STATE_LTE_TXRX,indexEvent);
        % remove self (or non "selected", if "neighborsSelection" is active)
        distance11pFromTx = distance11pFromTx(allNeighbors);
        % count 
        pckType = stationManagement.pckType(idEvent);
        iChannel = stationManagement.vehicleChannel(idEvent);
    
    
        for iPhyRaw = 1:length(phyParams.Raw)
            outputValues.Nblocked11p(iChannel,pckType,iPhyRaw) = outputValues.Nblocked11p(iChannel,pckType,iPhyRaw) + nnz(distance11pFromTx<phyParams.Raw(iPhyRaw));
            outputValues.NblockedTOT(iChannel,pckType,iPhyRaw) = outputValues.NblockedTOT(iChannel,pckType,iPhyRaw) + nnz(distance11pFromTx<phyParams.Raw(iPhyRaw));
        end

    
        if outParams.printPacketReceptionRatio
            %if simParams.technology==1 % only LTE
            if sum(stationManagement.vehicleState(stationManagement.activeIDs)~=constants.V_STATE_LTE_TXRX)==0
                error('Not expected to arrive here...');
                %outputValues.distanceDetailsCounterCV2X(iRaw,4) = outputValues.distanceDetailsCounterCV2X(iRaw,4) + nnz(positionManagement.distanceReal(:,indexEvent)<iRaw);
            else
                if simParams.technology == constants.TECH_ONLY_11P && appParams.variableBeaconSize % if ONLY 11p
                    % If variable beacon size is selected, find if small or large packet is
                    % currently transmitted (1 stays for large, 0 for small)
                    error('This feature has not been tested in this version of the simulator.');
                    %stationManagement.ifBeaconLarge = (mod(stationManagement.variableBeaconSizePeriodicity(indexEvent)+floor(timeManagement.timeNow/appParams.Tbeacon),appParams.NbeaconsSmall+1))==0;
                else
                    % Always large
                    stationManagement.ifBeaconLarge = 1;
                end
                
                %pckType = stationManagement.pckType(idEvent);
                %iChannel = stationManagement.vehicleChannel(idEvent);
                if stationManagement.ifBeaconLarge
                    for iRaw = 1:floor(phyParams.RawMax11p/outParams.prrResolution)
                        outputValues.distanceDetailsCounter11p(iChannel,pckType,iRaw,4) = outputValues.distanceDetailsCounter11p(iChannel,pckType,iRaw,4) + nnz(distance11pFromTx<(iRaw*outParams.prrResolution));
                    end
                else
                    for iRaw = 1:floor(phyParams.RawMax11p/outParams.prrResolution)
                        outputValues.distanceDetailsCounter11p(iChannel,pckType,iRaw,8) = outputValues.distanceDetailsCounter11p(iChannel,pckType,iRaw,8) + nnz(distance11pFromTx<(iRaw*outParams.prrResolution));
                    end
                end
            end
        end
    end
    stationManagement.pckBuffer(idEvent) = stationManagement.pckBuffer(idEvent)-1;
    %fprintf('CAM message discarded\n');
end

% Part dealing with transmission start
% If coexistence Method A during the LTE part, the vehicle must go in State 9
if simParams.technology == constants.TECH_COEX_STD_INTERF && ...
        simParams.coexMethod == constants.COEX_METHOD_A && ...
        ~simParams.coexA_withLegacyITSG5 && ...
        timeManagement.coex_superframeThisIsLTEPart(idEvent) % LTE part
    if stationManagement.vehicleState(idEvent) == constants.V_STATE_11P_IDLE % idle
        stationManagement.vehicleState(idEvent) = constants.V_STATE_11P_RX; % rx
    end
end

% If the node was in IDLE (State==1)
% NOTE: if the channel is sensed busy, the station is in State 9, so there
% is no need to freeze here
if stationManagement.vehicleState(idEvent) == constants.V_STATE_11P_IDLE % idle
    
    % % DEBUG EVENTS
    % printDebugEvents(timeEvent,'backoff starts',idEvent);

    % Start the backoff
    stationManagement.vehicleState(idEvent) = constants.V_STATE_11P_BACKOFF; % backoff
    % A new random backoff is set and the instant of its conclusion
    % is derived
    % if there is a new packet and the channel is sensed idle during AIFS,
    % the vehicle would transmite this packet immediatly after the AIFS,
    % and without the backoff process.
    if simParams.technology~=constants.TECH_COEX_STD_INTERF || simParams.coexMethod~=constants.COEX_METHOD_C || ~simParams.coexCmodifiedCW
        [stationManagement.nSlotBackoff11p(idEvent), timeManagement.timeNextTxRx11p(idEvent)] =...
            startNewBackoff11p(timeManagement.timeNow,stationManagement.CW_11p(idEvent),...
            stationManagement.tAifs_11p(idEvent),phyParams.tSlot);
    else
        relativeTime = timeManagement.timeNow-simParams.coex_superFlength*floor(timeManagement.timeNow/simParams.coex_superFlength);
        subframeIndex = floor(relativeTime/phyParams.Tsf);
        [stationManagement.nSlotBackoff11p(idEvent), timeManagement.timeNextTxRx11p(idEvent)] =...
            coexistenceStartNewBackoff11pModified(...
                timeManagement.timeNow, stationManagement.CW_11p(idEvent),...
                stationManagement.tAifs_11p(idEvent), phyParams.tSlot,...
                subframeIndex,simParams.coex_superframeSF);
    end        
%     printDebugBackoff11p(timeManagement.timeNow,'11p backoff started',idEvent,stationManagement,outParams,timeManagement);
end

% reset of pckReceive and cumulativeSINR
stationManagement.pckReceived(:,idEvent) = 0;
sinrManagement.cumulativeSINR(:,idEvent) = 0;
stationManagement.preambleAlreadyDetected(:,idEvent) = 0;
stationManagement.alreadyStartCBR(:,idEvent) = 0;

stationManagement.pckTxOccurring(idEvent) = 0;
stationManagement.pckNextAttempt(idEvent) = 1;
% reset index of activeIDs11p in the range of Raw earlier (during one packet
% and it's retransmission)
stationManagement.indexInRaw_earler(:, idEvent, :) = 0;



