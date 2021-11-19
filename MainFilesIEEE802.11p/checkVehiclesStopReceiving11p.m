function [timeManagement,stationManagement,sinrManagement,outputValues] = checkVehiclesStopReceiving11p(timeManagement,stationManagement,sinrManagement,simParams,phyParams,outParams,outputValues)
% The nodes that may stop receiving must be checked

% Variable used for easier reading
activeIDs = stationManagement.activeIDs;
if sum(stationManagement.vehicleState(activeIDs)~=100)==0
    return;
end

% Firstly, those nodes that were receiving from this node should change the
% receiving node to own, and then possibly stop receiving
% They are those that:
% 1) are currently receiving
% 2) do not have the 'idFromWhichRx' currently transmitting
% ifReceivingFromThis = logical( (stationManagement.vehicleState(activeIDs)==9) .* ...
%     (stationManagement.vehicleState(sinrManagement.idFromWhichRx11p(activeIDs))~=3) );
ifReceivingFromThis = logical( (stationManagement.vehicleState(activeIDs)==9));

sinrManagement.idFromWhichRx11p(activeIDs(ifReceivingFromThis)) = activeIDs(ifReceivingFromThis);
% Then, those that also sense the medium as idle will exit from state 9
% 3) sense a total power below the threshold

% an additional factor is used to block all 11p transmissions (used in coexistence methods)
rxPowerTotNow_PartA = (sinrManagement.P_RX_MHz*phyParams.BwMHz) * (stationManagement.vehicleState(activeIDs)==3);
rxPowerTotNow_PartB = sinrManagement.coex_InterfFromLTEto11p(activeIDs) + ...
                    sinrManagement.coex_virtualInterference(activeIDs);
rxPowerTotNow = rxPowerTotNow_PartA + rxPowerTotNow_PartB;
ifStopReceiving = ifReceivingFromThis .* (rxPowerTotNow < phyParams.PrxSensNotSynch);
% Focusing on those that stop receiving
% The 'idFromWhichRx' is reset to the own id
% State is set to either 0 or 1 depending on whether the queue
% is empty or not
% If the queue is not empty, the backoff is started; if
% 'nSlotBackoff' contains a '-1', it means that a new backoff
% should be started; otherwise, it was freezed and should be
% resumed
stationManagement.vehicleState(activeIDs((logical(ifStopReceiving .* (stationManagement.pckBuffer(activeIDs)==0))))) = 1;
stationManagement.vehicleState(activeIDs((logical(ifStopReceiving .* (stationManagement.pckBuffer(activeIDs)>0))))) = 2;
idVehicleVector=activeIDs(logical(ifStopReceiving .* (stationManagement.pckBuffer(activeIDs)>0)));
for iVehicle = idVehicleVector'
    if stationManagement.nSlotBackoff11p(iVehicle)==-1
        if simParams.technology~=4 || simParams.coexMethod~=3 || ~simParams.coexCmodifiedCW
            [stationManagement.nSlotBackoff11p(iVehicle), timeManagement.timeNextTxRx11p(iVehicle)] = startNewBackoff11p(timeManagement.timeNow,stationManagement.CW_11p(iVehicle),stationManagement.tAifs_11p(iVehicle),phyParams.tSlot);
        else
            relativeTime = timeManagement.timeNow-simParams.coex_superFlength*floor(timeManagement.timeNow/simParams.coex_superFlength);
            subframeIndex = floor(relativeTime/phyParams.Tsf);
            [stationManagement.nSlotBackoff11p(iVehicle), timeManagement.timeNextTxRx11p(iVehicle)] = coexistenceStartNewBackoff11pModified(timeManagement.timeNow,stationManagement.CW_11p(iVehicle),stationManagement.tAifs_11p(iVehicle),phyParams.tSlot,subframeIndex,simParams.coex_superframeSF);
        end
        % DEBUG BACKOFF
        printDebugBackoff11p(timeManagement.timeNow,'11p backoff start',iVehicle,stationManagement,outParams);
    else
        timeManagement.timeNextTxRx11p(iVehicle) = resumeBackoff11p(timeManagement.timeNow,stationManagement.nSlotBackoff11p(iVehicle),stationManagement.tAifs_11p(iVehicle),phyParams.tSlot);
        % DEBUG BACKOFF
        printDebugBackoff11p(timeManagement.timeNow,'11p backoff resume',iVehicle,stationManagement,outParams);
    end
end

%% The channel busy ratio should be updated 
% Taking into account that the sensing threshold might be different (-85 in ETSI EN 302 571)
%
if simParams.cbrActive && ~isempty(stationManagement.channelSensedBusyMatrix11p)
    % Identify those nodes that were perceiving the channel as busy and now
    % are not 
    
    % Nodes that are not transmitting and perceive a power below the
    % threshold do not consider the channel as busy
    nodesThatMightStop = ((stationManagement.vehicleState(activeIDs)~=3) & (stationManagement.vehicleState(activeIDs)~=100) &(rxPowerTotNow < phyParams.PrxSensWhenSynch));
    
    ifStopCBR = (nodesThatMightStop & timeManagement.cbr11p_timeStartBusy(activeIDs)>=0);

    if sum(  ((timeManagement.timeNow-timeManagement.cbr11p_timeStartBusy(activeIDs(logical(ifStopCBR)))))<-1e-9 ) >0
        error('error here');
    end
    
    stationManagement.channelSensedBusyMatrix11p(1,activeIDs(logical(ifStopCBR))) = stationManagement.channelSensedBusyMatrix11p(1,activeIDs(logical(ifStopCBR))) + (timeManagement.timeNow-timeManagement.cbr11p_timeStartBusy(activeIDs(logical(ifStopCBR)))');
    timeManagement.cbr11p_timeStartBusy(activeIDs(logical(ifStopCBR))) = -1;
end
%%

% Coexistence with dynamic slots
% Coexistence, calculation of CBR_11p: LTE nodes check if
% stopping detecting 11p signal
if simParams.technology == 4 && simParams.coexMethod~=0 && simParams.coex_slotManagement==2 && simParams.coex_cbrTotVariant==2
    % In this case, nodes must be LTE, already
    % detecting, receiving a power level below some threshold
    % 
    % The inteference is saved in sensedPowerByLteNo11p per beacon
    % resource and needs to be converted into "per subchannel"
    if ~isempty(sinrManagement.sensedPowerByLteNo11p)
        interferenceFromLTEnodesPerSubframe = (sum(sinrManagement.sensedPowerByLteNo11p)/length(sinrManagement.sensedPowerByLteNo11p(:,1)))';
    else
        interferenceFromLTEnodesPerSubframe = 0;
    end
    %fprintf('Time=%f\n',timeManagement.timeNow);
    %% Changed in version 5.2.10
    % lowSensedPower = (rxPowerTotNow_PartA(stationManagement.activeIDsCV2X) + interferenceFromLTEnodesPerSubframe ) < simParams.coex_powerStopSensing11p;
    lowSensedPower = (rxPowerTotNow_PartA(stationManagement.activeIDsCV2X) + interferenceFromLTEnodesPerSubframe ) < phyParams.PrxSensWhenSynch;
    %%
    ifStopDetecting11p = logical(sinrManagement.coex_detecting11p(stationManagement.activeIDsCV2X)...
        .* lowSensedPower);
    sinrManagement.coex_detecting11p(stationManagement.activeIDsCV2X(ifStopDetecting11p)) = false; 
    stationManagement.channelSensedBusyMatrix11p(1,stationManagement.activeIDsCV2X(ifStopDetecting11p)) = stationManagement.channelSensedBusyMatrix11p(1,stationManagement.activeIDsCV2X(ifStopDetecting11p)) + (timeManagement.timeNow-timeManagement.cbr11p_timeStartBusy(stationManagement.activeIDsCV2X(ifStopDetecting11p))');
    timeManagement.cbr11p_timeStartBusy(stationManagement.activeIDsCV2X(ifStopDetecting11p)) = -1;
    %fp = fopen('_Debug_LTE_CBR11p.xls','a');
    %fprintf(fp,'%f\t\t%d\n',timeManagement.timeNow,sum(ifStopDetecting11p));
    %fclose(fp);
end    

% Temporary
% if simParams.mco_nVehInterf>0 && outParams.mco_printInterfStatistic
%     outputValues = mco_updateInterfFromAdjacent(timeManagement,stationManagement,sinrManagement,phyParams,simParams,outputValues);
% end


