function timeManagement = coexistenceImprovements(timeManagement,idEvent,stationManagement,simParams,phyParams)

activeLTE = [];
active11p = [];
if idEvent==-1
    activeLTE = stationManagement.activeIDsCV2X;
    active11p = stationManagement.activeIDs11p;
else
    if stationManagement.vehicleState(idEvent)==100
        activeLTE = idEvent;      
    else
        active11p = idEvent;
    end
end

%if isfield(timeManagement,'timeNow') && timeManagement.timeNow>1.6 && idEvent==4
%    STOPHERE=1;
%end

timeNextPacketBefore = timeManagement.timeNextPacket;

if simParams.technology==constants.TECH_COEX_STD_INTERF && simParams.coexMethod==constants.COEX_METHOD_A && simParams.coexA_improvements>0
    %%
    % My version
    %delta = mod(timeManagement.timeNextPacket,simParams.coex_superFlength)/simParams.coex_superFlength;
    %superframeStart = timeManagement.timeNextPacket - mod(timeManagement.timeNextPacket,simParams.coex_superFlength);
    %
    %timeManagement.timeNextPacket(activeLTE) = ...
    %    superframeStart(activeLTE) + (delta(activeLTE) * simParams.coex_endOfLTE) - phyParams.Tsf;
    %
    %timeManagement.timeNextPacket(active11p) = ...
    %    superframeStart(active11p) + simParams.coex_endOfLTE + (delta(active11p) * (simParams.coex_superFlength-simParams.coex_endOfLTE-phyParams.tPck11p));
    
    timeOriginal = timeNextPacketBefore-timeManagement.addedToGenerationTime;
    
    if simParams.coexA_improvements == 1
        %%
        % Qualcomm version - ignoring simParams.coex_guardTimeBefore
        % t original time
        t = timeOriginal(active11p);
        % tA time start of LTE slot
        tA = simParams.coex_superFlength * floor(timeOriginal(active11p)/simParams.coex_superFlength);
        % TA duration of the LTE slot
        TA = simParams.coex_knownEndOfLTE(active11p);
        % TB duration of the LTE slot       
        TB = simParams.coex_superFlength - simParams.coex_knownEndOfLTE(active11p);
        % tB time start of LTE slot
        tB = tA + TA;
        % if in the LTE slot
        ifInLTEslot = (t-tA) < simParams.coex_endOfLTE;
        % tNEW is the new time, added only during the LTE slot
        timeManagement.timeNextPacket(active11p) = ...
            round(timeOriginal(active11p) .* ~ifInLTEslot + ...
            (tB + (t-tA) .* TB./TA) .* ifInLTEslot, 10);

    elseif simParams.coexA_improvements == 2 || simParams.coexA_improvements == 3
        %%
        % My version
        t_x = mod(timeOriginal(active11p)+simParams.coex_guardTimeBefore,simParams.coex_superFlength);
        t_2 = simParams.coex_superFlength - simParams.coex_knownEndOfLTE(active11p) - simParams.coex_guardTimeBefore - simParams.coex_guardTimeAfter;
        t_y = t_x .* t_2 ./ simParams.coex_superFlength;
        timeManagement.timeNextPacket(active11p) = round(timeOriginal(active11p) - t_x + simParams.coex_knownEndOfLTE(active11p) + simParams.coex_guardTimeBefore + simParams.coex_guardTimeAfter + t_y, 10);       
    else
        error('coexA_improvements not allowed');
    end
end

timeNextPacketAfter = timeManagement.timeNextPacket;

timeManagement.addedToGenerationTime(active11p) = round(timeManagement.addedToGenerationTime(active11p) + timeNextPacketAfter(active11p)-timeNextPacketBefore(active11p), 10);
