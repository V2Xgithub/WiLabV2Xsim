function [timeManagement,stationManagement,sinrManagement,outputValues] = superframeManagement(timeManagement,stationManagement,simParams,sinrManagement,phyParams,outParams,simValues,outputValues)

vehiclesLTEstart = stationManagement.activeIDs((~timeManagement.coex_superframeThisIsLTEPart(stationManagement.activeIDs)) & (timeManagement.coex_timeNextSuperframe(stationManagement.activeIDs)==timeManagement.timeNow));
vehiclesITSG5start = stationManagement.activeIDs((timeManagement.coex_superframeThisIsLTEPart(stationManagement.activeIDs)) & (timeManagement.coex_timeNextSuperframe(stationManagement.activeIDs)==timeManagement.timeNow));

% Coexistence Methods 'A' and 'B'
%if ~timeManagement.coex_superframeThisIsLTEPart
%% First portion: starts LTE
timeManagement.coex_superframeThisIsLTEPart(vehiclesLTEstart) = true;

if simParams.coexMethod~=constants.COEX_METHOD_F && simParams.coexMethod~=constants.COEX_METHOD_C %% Method C added here in v5.4.11
    if simParams.coexMethod==constants.COEX_METHOD_A %|| (simParams.coexMethod==3 && simParams.coexC_timegapVariant==2)
        sinrManagement.coex_virtualInterference(vehiclesLTEstart) = inf;
    elseif simParams.coexMethod==constants.COEX_METHOD_B
        % Energy signals in Method B before the superframe
        % Function with sensing added in v5.2.10
        sinrManagement.coex_InterfFromLTEto11p = coexistenceInterferenceOfEnergySignalsBeforeSuperFrame(timeManagement,stationManagement,sinrManagement,phyParams,simParams,simValues);            
    else
        error('Not yet implemented');
    end

    % Check the nodes that start receiving
    if ~isempty(stationManagement.activeIDs11p)
        [timeManagement,stationManagement,sinrManagement,outputValues] = checkVehiclesStartReceiving11p(-1,-1,timeManagement,stationManagement,sinrManagement,simParams,phyParams,outParams,outputValues);
    end
end

timeManagement.coex_timeNextSuperframe(vehiclesLTEstart) = round(timeManagement.coex_timeNextSuperframe(vehiclesLTEstart) + simParams.coex_knownEndOfLTE(vehiclesLTEstart) + simParams.coex_guardTimeBefore + simParams.coex_guardTimeAfter, 10);

%else % ~timeManagement.coex_superframeThisIsLTEPart
%% Second portion: 11p

timeManagement.coex_superframeThisIsLTEPart(vehiclesITSG5start) = false;

if simParams.coexMethod~=constants.COEX_METHOD_F && simParams.coexMethod~=constants.COEX_METHOD_C %% Method C added here in v5.4.11
    sinrManagement.coex_virtualInterference(vehiclesITSG5start) = 0;

    % Check the nodes that stop receiving
    if ~isempty(stationManagement.activeIDs11p)
        [timeManagement,stationManagement,sinrManagement,outputValues] = checkVehiclesStopReceiving11p(timeManagement,stationManagement,sinrManagement,simParams,phyParams,outParams,outputValues);
    end
end

timeManagement.coex_timeNextSuperframe(vehiclesITSG5start) = round(timeManagement.coex_timeNextSuperframe(vehiclesITSG5start) + (simParams.coex_superFlength - simParams.coex_knownEndOfLTE(vehiclesITSG5start) - simParams.coex_guardTimeBefore - simParams.coex_guardTimeAfter), 10);

%end
