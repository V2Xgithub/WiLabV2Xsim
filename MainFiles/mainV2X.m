function [simValues,outputValues,appParams,simParams,phyParams,sinrManagement,outParams,stationManagement] = mainV2X(appParams,simParams,phyParams,outParams,simValues,outputValues,positionManagement)
% Core function where events are sorted and executed

%% Initialization
[appParams,simParams,phyParams,outParams,simValues,outputValues,...
    sinrManagement,timeManagement,positionManagement,stationManagement] = mainInit(appParams,simParams,phyParams,outParams,simValues,outputValues,positionManagement);


% The variable 'timeNextPrint' is used only for printing purposes
timeNextPrint = 0;

% The variable minNextSuperframe is used in the case of coexistence
minNextSuperframe = min(timeManagement.coex_timeNextSuperframe);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Simulation Cycle
% The simulation ends when the time exceeds the duration of the simulation
% (not really used, since a break inside the cycle will stop the simulation
% earlier)

% Start stopwatch
tic

fprintf('Simulation ID: %d\nMessage: %s\n',outParams.simID, outParams.message);
fprintf('Simulation Time: ');
reverseStr = '';
while timeManagement.timeNow < simParams.simulationTime

    % The instant and node of the next event is obtained
    % indexEvent is the index of the vector IDvehicle
    % idEvent is the ID of the vehicle of the current event
    [timeEvent, indexEvent] = min(timeManagement.timeNextEvent(stationManagement.activeIDs));
    idEvent = stationManagement.activeIDs(indexEvent);

    % If the next C-V2X event is earlier than timeEvent, set the time to the
    % C-V2X event
    if timeEvent >= timeManagement.timeNextCV2X - 1e-9
        timeEvent = timeManagement.timeNextCV2X;
        %fprintf('LTE subframe %.6f\n',timeEvent);
    end

    % If the next superframe event (coexistence, method A) is earlier than timeEvent, set the time to the
    % this event
    if timeEvent >= minNextSuperframe  - 1e-9
        timeEvent = minNextSuperframe;
    end
        
    % If timeEvent is later than the next CBR update, set the time
    % to the CBR update
    if timeEvent >= (timeManagement.timeNextCBRupdate - 1e-9) 
        timeEvent = timeManagement.timeNextCBRupdate;
        %fprintf('CBR update%.6f\n',timeEvent);
    end
        
    % If timeEvent is later than the next position update, set the time
    % to the position update
    % With LTE, it must necessarily be done after the end of a subframe and
    % before the next one
    if timeEvent >= (timeManagement.timeNextPosUpdate-1e-9) && ...
        (isempty(stationManagement.activeIDsCV2X) || (isfield(timeManagement, "ttiCV2Xstarts") && timeManagement.ttiCV2Xstarts==true))
        timeEvent = timeManagement.timeNextPosUpdate;
    end
    
    % to avoid vechile go out of scenario right before CV2X Tx ending or CBR update
    % special case: timeManagement.timeNextPosUpdate == timeManagement.timeNextCV2X
    if (isfield(timeManagement, "ttiCV2Xstarts") && timeManagement.ttiCV2Xstarts==false) ||...
            timeManagement.timeNextPosUpdate == timeManagement.timeNextCBRupdate
        delayPosUpdate = true;
    else
        delayPosUpdate = false;
    end

    % if the CV2X ending transmission time equals to the timeNextCBRupdate,
    % end the transmission first
    if timeManagement.timeNextCBRupdate == timeManagement.timeNextCV2X &&...
            (isfield(timeManagement, "ttiCV2Xstarts") && timeManagement.ttiCV2Xstarts==false)
        delayCBRupdate = true;
    else
        delayCBRupdate = false;
    end

    % if the CV2X ending transmission time equals to the minNextSuperframe,
    % end the transmission first
    if minNextSuperframe == timeManagement.timeNextCV2X &&...
            (isfield(timeManagement, "ttiCV2Xstarts") && timeManagement.ttiCV2Xstarts==false)
        delay_minNextSuperframe = true;
    else
        delay_minNextSuperframe = false;
    end
    if timeEvent < timeManagement.timeNow
        % error log
        fid_error = fopen(fullfile(outParams.outputFolder,...
            sprintf("error_log_%d.txt",outParams.simID)), "at");
        fprintf(fid_error, sprintf("Time goes back! Stop and check!\nSeed=%d, timeNow=%f, timeEvent=%f\n",...
            simParams.seed, timeManagement.timeNow, timeEvent));
        fclose(fid_error);
    end
    % update timenow, timenow do not go back, deal with float-point-related
    % cases.
    % fixme: need to check
    timeManagement.timeNow = max(timeEvent, timeManagement.timeNow);
    
    % If the time instant exceeds or is equal to the duration of the
    % simulation, the simulation is ended
    if round(timeManagement.timeNow, 10) >= round(simParams.simulationTime, 10)
        break;
    end

    %%
    % Print time to video
    while timeManagement.timeNow > timeNextPrint  - 1e-9
        reverseStr = printUpdateToVideo(timeManagement.timeNow,simParams.simulationTime,reverseStr);
        timeNextPrint = timeNextPrint + simParams.positionTimeResolution;
    end

    %% Action
    % The action at timeManagement.timeNow depends on the selected event
    % POSITION UPDATE: positions of vehicles are updated
    if timeEvent == timeManagement.timeNextPosUpdate && ~delayPosUpdate
        % DEBUG EVENTS
        % printDebugEvents(timeEvent,'position update',-1);
        
        if isfield(timeManagement,'ttiCV2Xstarts') && timeManagement.ttiCV2Xstarts==false
            % During a position update, some vehicles can enter or exit the
            % scenario; this is not managed if it happens during one
            % subframe
            error('A position update is occurring during the subframe; not allowed by implementation.');
        end
            
        [appParams,simParams,phyParams,outParams,simValues,outputValues,timeManagement,positionManagement,sinrManagement,stationManagement] = ...
              mainPositionUpdate(appParams,simParams,phyParams,outParams,simValues,outputValues,timeManagement,positionManagement,sinrManagement,stationManagement);
        
        % DEBUG IMAGE
        % printDebugImage('position update',timeManagement,stationManagement,positionManagement,simParams,simValues);

        % Set value of next position update
        timeManagement.timeNextPosUpdate = round(timeManagement.timeNextPosUpdate + simParams.positionTimeResolution, 10);
        positionManagement.NposUpdates = positionManagement.NposUpdates+1;

    elseif timeEvent == timeManagement.timeNextCBRupdate && ~delayCBRupdate
        % Part dealing with the channel busy ratio calculation
        % Done for every station in the system, if the option is active
        %
        thisSubInterval = mod(ceil((timeEvent-1e-9)/(simParams.cbrSensingInterval/simParams.cbrSensingIntervalDesynchN))-1,simParams.cbrSensingIntervalDesynchN)+1;
        %
        % ITS-G5
        % CBR and DCC (if active)
        if ~isempty(stationManagement.activeIDs11p)
            vehiclesToConsider = stationManagement.activeIDs11p(stationManagement.cbr_subinterval(stationManagement.activeIDs11p)==thisSubInterval);        
            [timeManagement,stationManagement,stationManagement.cbr11pValues(vehiclesToConsider,ceil(timeEvent/simParams.cbrSensingInterval-1e-9))] = ...
                cbrUpdate11p(timeManagement,vehiclesToConsider,stationManagement,simParams,phyParams,outParams);
%             %% =========
%             % Plot figs of related paper, could be commented in other case.
%             % Please check .../codeForPaper/Zhuofei2023Repetition/fig6
%             % Only for IEEE 802.11p, highway scenario. 
%             % log number of replicas
%             stationManagement.ITSReplicasLog(vehiclesToConsider,ceil(timeEvent/simParams.cbrSensingInterval-1e-9)) = stationManagement.ITSNumberOfReplicas(vehiclesToConsider);
%             stationManagement.positionLog(vehiclesToConsider,ceil(timeEvent/simParams.cbrSensingInterval-1e-9)) = positionManagement.XvehicleReal(vehiclesToConsider);
%             %% =========
        end
        % In case of Mitigation method with dynamic slots, also in LTE nodes
        if simParams.technology==constants.TECH_COEX_STD_INTERF && simParams.coexMethod~=constants.COEX_METHOD_NON && simParams.coex_slotManagement==constants.COEX_SLOT_DYNAMIC && simParams.coex_cbrTotVariant==2
            vehiclesToConsider = stationManagement.activeIDsCV2X(stationManagement.cbr_subinterval(stationManagement.activeIDsCV2X)==thisSubInterval);
            [timeManagement,stationManagement,sinrManagement.cbrLTE_coex11ponly(vehiclesToConsider)] = ...
                cbrUpdate11p(timeManagement,vehiclesToConsider,stationManagement,simParams,phyParams,outParams);
        end
        
        % LTE-V2X
        % CBR and DCC (if active)
        if ~isempty(stationManagement.activeIDsCV2X)
            vehiclesToConsider = stationManagement.activeIDsCV2X(stationManagement.cbr_subinterval(stationManagement.activeIDsCV2X)==thisSubInterval);
            [timeManagement,stationManagement,sinrManagement,stationManagement.cbrCV2Xvalues(vehiclesToConsider,ceil(timeEvent/simParams.cbrSensingInterval)),stationManagement.coex_cbrLteOnlyValues(vehiclesToConsider,ceil(timeEvent/simParams.cbrSensingInterval))] = ...
                cbrUpdateCV2X(timeManagement,vehiclesToConsider,stationManagement,positionManagement,sinrManagement,appParams,simParams,phyParams,outParams,outputValues);
        end
        
        timeManagement.timeNextCBRupdate = round(timeManagement.timeNextCBRupdate + (simParams.cbrSensingInterval/simParams.cbrSensingIntervalDesynchN), 10);

    elseif timeEvent == minNextSuperframe && ~delay_minNextSuperframe
        % only possible in coexistence with mitigation methods
        if simParams.technology~=constants.TECH_COEX_STD_INTERF || simParams.coexMethod==constants.COEX_METHOD_NON
            error('Superframe is only possible with coexistence, Methods A, B, C, F');
        end
        
        % coexistence Methods, superframe boundary
        [timeManagement,stationManagement,sinrManagement,outputValues] = ...
            superframeManagement(timeManagement,stationManagement,simParams,sinrManagement,phyParams,outParams,simValues,outputValues);
                    
        minNextSuperframe=min(timeManagement.coex_timeNextSuperframe(stationManagement.activeIDs));

        % CASE C-V2X
    elseif abs(timeEvent-timeManagement.timeNextCV2X)<1e-8    % timeEvent == timeManagement.timeNextCV2X

        if timeManagement.ttiCV2Xstarts
            % DEBUG EVENTS
            %printDebugEvents(timeEvent,'LTE subframe starts',-1);
            %fprintf('Starts\n');
 
            if timeManagement.timeNow>0
                [phyParams,simValues,outputValues,sinrManagement,stationManagement,timeManagement] = ...
                    mainCV2XttiEnds(appParams,simParams,phyParams,outParams,simValues,outputValues,timeManagement,positionManagement,sinrManagement,stationManagement);
            end
            
            [sinrManagement,stationManagement,timeManagement,outputValues] = ...
                mainCV2XttiStarts(appParams,phyParams,timeManagement,sinrManagement,stationManagement,simParams,simValues,outParams,outputValues);

            % DEBUG TX-RX
            % if isfield(stationManagement,'IDvehicleTXLTE') && ~isempty(stationManagement.transmittingIDsLTE)
            %     printDebugTxRx(timeManagement.timeNow,'LTE subframe starts',stationManagement,sinrManagement);
            % end

            % DEBUG TX
            % printDebugTx(timeManagement.timeNow,true,-1,stationManagement,positionManagement,sinrManagement,outParams,phyParams);

            timeManagement.ttiCV2Xstarts = false;
            timeManagement.timeNextCV2X = round(timeManagement.timeNextCV2X + (phyParams.TTI - phyParams.TsfGap), 10);

            % DEBUG IMAGE
            % if isfield(stationManagement,'IDvehicleTXLTE') && ~isempty(stationManagement.transmittingIDsLTE)
            %     printDebugImage('LTE subframe starts',timeManagement,stationManagement,positionManagement,simParams,simValues);
            % end
        else
            % DEBUG EVENTS
            % printDebugEvents(timeEvent,'LTE subframe ends',-1);
            % fprintf('Stops\n');

            [phyParams,simValues,outputValues,sinrManagement,stationManagement,timeManagement] = ...
                mainCV2XtransmissionEnds(appParams,simParams,phyParams,outParams,simValues,outputValues,timeManagement,positionManagement,sinrManagement,stationManagement);

            % DEBUG TX-RX
            % if isfield(stationManagement,'IDvehicleTXLTE') && ~isempty(stationManagement.transmittingIDsLTE)
            %     printDebugTxRx(timeManagement.timeNow,'LTE subframe ends',stationManagement,sinrManagement);
            % end

            timeManagement.ttiCV2Xstarts = true;
            timeManagement.timeNextCV2X = round(timeManagement.timeNextCV2X + phyParams.TsfGap, 10);

            % DEBUG IMAGE
            % if isfield(stationManagement,'IDvehicleTXLTE') && ~isempty(stationManagement.transmittingIDsLTE)
            %     printDebugImage('LTE subframe ends',timeManagement,stationManagement,positionManagement,simParams,simValues);
            % end
        end
     
    % CASE A: new packet is generated
    elseif abs(timeEvent-timeManagement.timeNextPacket(idEvent))<1e-8   % timeEvent == timeManagement.timeNextPacket(idEvent)

        % printDebugReallocation(timeEvent,idEvent,positionManagement.XvehicleReal(indexEvent),'gen',-1,outParams);

        if stationManagement.vehicleState(idEvent)==constants.V_STATE_LTE_TXRX % is LTE
            % DEBUG EVENTS
            %printDebugEvents(timeEvent,'New packet, LTE',idEvent);
       
            stationManagement.pckBuffer(idEvent) = stationManagement.pckBuffer(idEvent)+1;
%             %% From version 6.2, the following corrects a bug
%             %The buffer may include a packet that is being transmitted
%             %If the buffer already includes a packet, this needs to be
%             %checked at the end of this subframe
%             %If this is not the case, the pckNextAttempt must be reset
            if stationManagement.pckBuffer(idEvent)<=1
                stationManagement.pckNextAttempt(idEvent) = 1; 
            end
            
            % DEBUG IMAGE
            %printDebugImage('New packet LTE',timeManagement,stationManagement,positionManagement,simParams,simValues);
        else % is not LTE
            % DEBUG EVENTS
            %printDebugEvents(timeEvent,'New packet, 11p',idEvent);
            
            % In the case of 11p, some processing is necessary
            [timeManagement,stationManagement,sinrManagement,outputValues] = ...
                newPacketIn11p(idEvent,indexEvent,outParams,simParams,positionManagement,...
                phyParams,timeManagement,stationManagement,sinrManagement,outputValues,appParams);
   
            % DEBUG TX-RX
            % printDebugTxRx(timeManagement.timeNow,idEvent,'11p packet generated',stationManagement,sinrManagement,outParams);
            % printDebugBackoff11p(timeManagement.timeNow,'11p backoff started',idEvent,stationManagement,outParams)

            % DEBUG IMAGE
            %printDebugImage('New packet 11p',timeManagement,stationManagement,positionManagement,simParams,simValues);
        end

        % printDebugGeneration(timeManagement,idEvent,positionManagement,outParams);
        
        % from version 5.6.2 the 3GPP aperiodic generation is also supported. The generation interval is now composed of a
        % deterministic part and a random part. The random component is active only when enabled.
        generationInterval = timeManagement.generationIntervalDeterministicPart(idEvent) + exprnd(appParams.generationIntervalAverageRandomPart);
        if generationInterval >= timeManagement.dcc_minInterval(idEvent)
            timeManagement.timeNextPacket(idEvent) = round(timeManagement.timeNow + generationInterval, 10);
        else
            timeManagement.timeNextPacket(idEvent) = round(timeManagement.timeNow + timeManagement.dcc_minInterval(idEvent), 10);
            if ismember(idEvent, stationManagement.activeIDs11p)
                stationManagement.dcc11pTriggered(stationManagement.vehicleChannel(idEvent)) = true;
            elseif ismember(idEvent, stationManagement.activeIDsCV2X)
                stationManagement.dccLteTriggered(stationManagement.vehicleChannel(idEvent)) = true;
            end
        end
        
        timeManagement.timeLastPacket(idEvent) = timeManagement.timeNow-timeManagement.addedToGenerationTime(idEvent);
        
        if simParams.technology==constants.TECH_COEX_STD_INTERF && simParams.coexMethod==constants.COEX_METHOD_A && simParams.coexA_improvements>0
            timeManagement = coexistenceImprovements(timeManagement,idEvent,stationManagement,simParams,phyParams);
        end                
         
        % CASE B+C: either a backoff or a transmission concludes
    else % txrxevent-11p
        % A backoff ends
        if stationManagement.vehicleState(idEvent)==constants.V_STATE_11P_BACKOFF % END backoff
            % DEBUG EVENTS
            %printDebugEvents(timeEvent,'backoff concluded, tx start',idEvent);
            
            [timeManagement,stationManagement,sinrManagement,outputValues] = ...
                endOfBackoff11p(idEvent,indexEvent,simParams,simValues,phyParams,timeManagement,stationManagement,sinrManagement,appParams,outParams,outputValues);
 
            % DEBUG TX-RX
            % printDebugTxRx(timeManagement.timeNow,idEvent,'11p Tx started',stationManagement,sinrManagement,outParams);
            % printDebugBackoff11p(timeManagement.timeNow,'11p tx started',idEvent,stationManagement,outParams)
 
            % DEBUG TX
            % printDebugTx(timeManagement.timeNow,true,idEvent,stationManagement,positionManagement,sinrManagement,outParams,phyParams);
            
            % DEBUG IMAGE
            %printDebugImage('11p TX starts',timeManagement,stationManagement,positionManagement,simParams,simValues);
 
            % A transmission ends
        elseif stationManagement.vehicleState(idEvent)==constants.V_STATE_11P_TX % END tx
            % DEBUG EVENTS
            %printDebugEvents(timeEvent,'Tx concluded',idEvent);
            
            [simValues,outputValues,timeManagement,stationManagement,sinrManagement] = ...
                endOfTransmission11p(idEvent,indexEvent,positionManagement,phyParams,outParams,simParams,simValues,outputValues,timeManagement,stationManagement,sinrManagement,appParams);
            
            % DEBUG IMAGE
            %printDebugImage('11p TX ends',timeManagement,stationManagement,positionManagement,simParams,simValues);

            % DEBUG TX-RX
            % printDebugTxRx(timeManagement.timeNow,idEvent,'11p Tx ended',stationManagement,sinrManagement,outParams);
            % printDebugBackoff11p(timeManagement.timeNow,'11p tx ended',idEvent,stationManagement,outParams)

        else
            fprintf('idEvent=%d, state=%d\n',idEvent,stationManagement.vehicleState(idEvent));
            error('Ends unknown event...')
        end
    end
    
    % The next event is selected as the minimum of all values in 'timeNextPacket'
    % and 'timeNextTxRx'
    timeManagement.timeNextEvent = min(timeManagement.timeNextPacket,timeManagement.timeNextTxRx11p);
    if min(timeManagement.timeNextEvent(stationManagement.activeIDs)) < timeManagement.timeNow-1e-8 % error check
        format long
        fprintf('next=%f, now=%f\n',min(timeManagement.timeNextEvent(stationManagement.activeIDs)),timeManagement.timeNow);
        error('An event is schedule in the past...');
    end
    
end

% Print end of simulation
msg = sprintf('%.1f / %.1fs',simParams.simulationTime,simParams.simulationTime);
fprintf([reverseStr, msg]);

% Number of position updates
simValues.snapshots = positionManagement.NposUpdates;

% Stop stopwatch
outputValues.computationTime = toc;

end
