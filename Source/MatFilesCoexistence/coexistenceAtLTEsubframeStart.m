function [timeManagement,stationManagement,sinrManagement,outputValues] = coexistenceAtLTEsubframeStart(timeManagement,sinrManagement,stationManagement,appParams,simParams,simValues,phyParams,outParams,outputValues)

if ~isempty(stationManagement.transmittingIDsCV2X) || simParams.coexMethod ~= constants.COEX_METHOD_A
    % In case of Coexistence Methods B, C, F must be done anyway
    
    % 1. The average SINR of 11p is updated
    if ~isempty(stationManagement.activeIDs11p)
        sinrManagement = updateSINR11p(timeManagement,sinrManagement,stationManagement,phyParams);
    end

    % 2. The inteference from LTE is updated - not need to initialize here, as it is reset at each subframe conclusion
    % only 11p vehicles are interferred (state ~= 100)
    % only active LTE interfere: those in IDvehicleTXLTE
    % they interfere fully, as LTE has always bandwidth <= 11p
    % It is obtained as the sum of P_RX_MHz of the LTE transmitters
    if ~isempty(stationManagement.transmittingIDsCV2X)
        sinrManagement.coex_InterfFromLTEto11p(stationManagement.activeIDs11p) = phyParams.BwMHz_cv2xBR * sum((sinrManagement.P_RX_MHz(stationManagement.indexInActiveIDs_of11pnodes,stationManagement.indexInActiveIDs_OfTxLTE)),2)';
    end

    switch simParams.coexMethod 
        case constants.COEX_METHOD_B
            % Coexistence Method B: possible addition of energy 
            % signals to fill the gaps
            %if (mod(timeManagement.elapsedTime_subframes-1,simParams.coex_superframeSF)+1) <= sinrManagement.coex_NtsLTE(1)
            % From v 5.2.3, the check if we are in the LTE part is done inside
            % the equation and might differ from vehicle to vehicle
            sinrManagement.coex_InterfFromLTEto11p = sinrManagement.coex_InterfFromLTEto11p + coexistenceInterferenceOfEnergySignalsEmptySF(timeManagement,stationManagement,sinrManagement,phyParams,appParams,simParams,simValues);     
        
        case constants.COEX_METHOD_C
            % Coexistence Method C: equivalent to NAV
            % The 11p nodes that have the NAV expiring are checked
            % coexistenceResetNAV()
            % Reset expired NAV and check if any 11p nodes starts transmitting 
            
            if simParams.cbrActive && ~isempty(stationManagement.channelSensedBusyMatrix11p)
                % if nodes with NAV expiring, storping their CBR timing
                nodesWithNAVExpiring = (sinrManagement.coex_virtualInterference>0) & (sinrManagement.coex_NAVexpiring <= timeManagement.timeNow);
                ifStopCBR = (nodesWithNAVExpiring & timeManagement.cbr11p_timeStartBusy(stationManagement.activeIDs)>=0);   
                stationManagement.channelSensedBusyMatrix11p(1,stationManagement.activeIDs(ifStopCBR)) = stationManagement.channelSensedBusyMatrix11p(1,stationManagement.activeIDs(ifStopCBR)) + (timeManagement.timeNow-timeManagement.cbr11p_timeStartBusy(stationManagement.activeIDs(ifStopCBR))');
                timeManagement.cbr11p_timeStartBusy(stationManagement.activeIDs(ifStopCBR)) = -1;
            end
            sinrManagement.coex_virtualInterference(sinrManagement.coex_NAVexpiring <= timeManagement.timeNow) = 0;
            [timeManagement,stationManagement,sinrManagement,outputValues] = checkVehiclesStopReceiving11p(timeManagement,stationManagement,sinrManagement,simParams,phyParams,outParams,outputValues);
    
            if ~isempty(stationManagement.transmittingIDsCV2X)
                [stationManagement,sinrManagement,timeManagement] = coexistenceSetNAV_C( timeManagement, stationManagement, sinrManagement, phyParams, simParams, appParams, outParams);
            end

        case constants.COEX_METHOD_F
            % Coexistence Method F: NAV
            % The 11p nodes that have the NAV expiring are checked
            % coexistenceResetNAV()
            % Reset expired NAV and check if any 11p nodes starts transmitting    
            sinrManagement.coex_virtualInterference(sinrManagement.coex_NAVexpiring <= timeManagement.timeNow) = 0;
            [timeManagement,stationManagement,sinrManagement,outputValues] = checkVehiclesStopReceiving11p(timeManagement,stationManagement,sinrManagement,simParams,phyParams,outParams,outputValues);
    
            % If we are in the first subframe of a superframe, the previous one should be
            % updated
            % Note: CV2XsensingProcedure is done at the end of the subframe
            thisT = mod(timeManagement.elapsedTime_TTIs-1,appParams.NbeaconsT)+1;
            if  mod(thisT, simParams.coex_superframeTTI)==1        
                % Commented from version 5.4.7 (the NAV is always sent at the beginning 
                % of the LTE slot)
                % ADDED from section 5.4.7, with coexistenceSetNAV basically rewritten
                [stationManagement,sinrManagement] = coexistenceSetNAV_F(timeManagement, stationManagement, sinrManagement, phyParams, simParams, appParams, thisT);
            end
    end
    
    % 3. 11p nodes that are in backoff might stop and freeze if the
    % sensed power is above a threshold
    if ~isempty(stationManagement.activeIDs11p)
        [timeManagement,stationManagement,sinrManagement,outputValues] = checkVehiclesStartReceiving11p(-1,-1,timeManagement,stationManagement,sinrManagement,simParams,phyParams,outParams,outputValues);
    end
    
end

% In coexistence with dynamic slots, the power sensed by all LTE nodes migth
% be needed to calculate the CBR11p 
if simParams.coexMethod~=constants.COEX_METHOD_NON && simParams.coex_slotManagement==constants.COEX_SLOT_DYNAMIC && simParams.coex_cbrTotVariant==2
    % Sense the channel - the following matrix is NbeaconsF x nVehicles
    sinrManagement.sensedPowerByLteNo11p = sensedPowerCV2X(stationManagement,sinrManagement,appParams,phyParams);
end

