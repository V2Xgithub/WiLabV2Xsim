function [timeManagement,stationManagement,sinrManagement,simParams,phyParams] = mainInitCoexistence(timeManagement,stationManagement,sinrManagement,simParams,simValues,phyParams,appParams)

% Enters here only: if simParams.technology==4 && simParams.coexMethod~=0

% simParams.coex_superframeSF will set the number of LTE SF in a superframe
simParams.coex_superframeSF = floor(simParams.coex_superFlength/phyParams.Tsf);
simParams.coex_superframeTTI = simParams.coex_superframeSF * (phyParams.Tsf / phyParams.TTI);
if simParams.coex_superframeTTI > appParams.NbeaconsT    
    error('Error: coex_superframeSlots > appParams.NbeaconsT (%d vs. %d)',simParams.coex_superframeTTI,appParams.NbeaconsT);
end
% The superframe duration is now set to a multiple of the subframe
% duration - if the number changes, the sim user is advised
superframeDurationSet = simParams.coex_superFlength;
simParams.coex_superFlength = simParams.coex_superframeSF * phyParams.Tsf;
if superframeDurationSet ~= simParams.coex_superFlength
    fprintf('Please note that the superframe duration has been modified from %f to %f\n',superframeDurationSet,simParams.coex_superFlength);
end

if simParams.coex_slotManagement == constants.COEX_SLOT_STATIC
    % The superframe portion for LTE is now set to a multiple of the subframe
    % duration - if the number changes, the sim user is advised
    % Minimum 5 ms per tech
    superframeLteDurationSet = max(0.005,min(simParams.coex_endOfLTE,simParams.coex_superFlength-0.005));
    simParams.coex_endOfLTE = max(1,ceil(simParams.coex_endOfLTE/phyParams.Tsf))*phyParams.Tsf;
    if superframeLteDurationSet~=simParams.coex_endOfLTE
        fprintf('Please note that the superframe LTE portion has been modified from %f to %f\n',superframeLteDurationSet,simParams.coex_endOfLTE);
    end
    % simParams.coex_NtotSubframeLTE sets the number of sub-frames of the
    % superframe available for LTE.
    % 'round' is used to manage problems with floating point numbers
    sinrManagement.coex_NtotSubframeLTE = round(simParams.coex_endOfLTE/phyParams.Tsf) * ones(simValues.maxID,1); 
    sinrManagement.coex_NtotTTILTE = sinrManagement.coex_NtotSubframeLTE * (phyParams.Tsf / phyParams.TTI);
elseif simParams.coex_slotManagement == constants.COEX_SLOT_DYNAMIC
    if simParams.coexMethod==constants.COEX_METHOD_A
        error('Coex: Method A cannot be set with dynamic management');
    end
    % Initialization of the matrix coex_correctSCIhistory
    %sinrManagement.coex_correctSCIhistory = zeros(appParams.NbeaconsT*appParams.NbeaconsF,simValues.maxID);
    % Number of subframes to be used by LTE
    % Init to the maximum of 50% by default
    sinrManagement.coex_NtotSubframeLTE = (ceil(simParams.coex_superframeSF/2)) * ones(simValues.maxID,1);
    sinrManagement.coex_NtotTTILTE = sinrManagement.coex_NtotSubframeLTE * (phyParams.Tsf / phyParams.TTI);
    % Init of specific cbr variables
    sinrManagement.cbrLTE_coexLTEonly = zeros(simValues.maxID,1);
    sinrManagement.cbrLTE_coex11ponly = zeros(simValues.maxID,1);
    % It might be that this variable is re-initialized later, with the same
    % value
    if simParams.coex_cbrTotVariant==2
        sinrManagement.coex_detecting11p = false(simValues.maxID,1);
        timeManagement.cbr11p_timeStartBusy = -1 * ones(simValues.maxID,1); % needed for the calculation of the CBR
        timeManagement.cbr11p_timeStartMeasInterval = zeros(simValues.maxID,1); % needed for the calculation of the CBR
    end
    %
    % In the case of dynamic, the end of LTE slot is conventionally set to
    % 90% of the superframe length
    simParams.coex_endOfLTE = floor(0.9*simParams.coex_superframeSF)*phyParams.Tsf;    
else
    error('Something wrong in "mainInitCoexistence"');
end
simParams.coex_knownEndOfLTE = round(simParams.coex_endOfLTE * ones(simValues.maxID,1), 10);

%% From v 5.4.11 method C is modified
if ismember(simParams.coexMethod, constants.COEX_METHODS_IMPLEMENTED)
% Coexistence Methods A, B, F, C (C from v.5.4.11)

    % Coexistence, method A
    if simParams.coexMethod==constants.COEX_METHOD_A
        if simParams.coexA_guardTime == -1
            simParams.coexA_guardTime = phyParams.tPck11p;
        end

        %OPTIONALLY - IMPROVEMENT
        if simParams.coexA_improvements == 1        
            % Setting "before" and "after" differently
            simParams.coex_guardTimeBefore = round(phyParams.tPck11p, 10);
            simParams.coex_guardTimeAfter = 0;
            % Setting "before" and "after" differently
        elseif simParams.coexA_improvements == 2
            simParams.coex_guardTimeBefore = round(phyParams.tPck11p + simParams.coexA_desynchError, 10);
            simParams.coex_guardTimeAfter = simParams.coexA_desynchError;
        elseif simParams.coexA_improvements == 3
            simParams.coex_guardTimeBefore = round(phyParams.tPck11p, 10);
            simParams.coex_guardTimeAfter = 0;
        else
            % Accurate to tenth decimal place to cope with floating numbers
            simParams.coex_guardTimeBefore = round(simParams.coexA_guardTime, 10);
            simParams.coex_guardTimeAfter = simParams.coexA_guardTime;
        end            
    elseif simParams.coexMethod==constants.COEX_METHOD_B %B

        if simParams.coexB_timeBeforeLTEstarts == -1
            simParams.coexB_timeBeforeLTEstarts = phyParams.tPck11p;
        end    
        % Accurate to tenth decimal place to cope with floating numbers
        simParams.coex_guardTimeBefore = round(simParams.coexB_timeBeforeLTEstarts, 10);
        simParams.coex_guardTimeAfter = 0;

        % The gap at the end of the transmission is reduced to 0 as it is
        % occupied by the 'energy signal'
        % This introduces an approximation in the calculation of the SINR when
        % some interference from 802.11p is present (no problems with noise or
        % LTE interferers)
        phyParams.TsfGap = 0;
        
        % The sensing threshold when the signal is not detected is moved to -85dBm
        if phyParams.CCAthr11p_notsync~=-85
            fprintf('The CCA threshold is automatically changed to -85 dBm\n');
        end
        phyParams.CCAthr11p_notsync = -85;
        phyParams.PrxSensNotSynch = 10^((phyParams.CCAthr11p_notsync-30)/10);
        %
        
    elseif simParams.coexMethod==constants.COEX_METHOD_F ... % Method F
            || simParams.coexMethod==constants.COEX_METHOD_C % Method C
        % No guard time
        simParams.coex_guardTimeBefore = 0;
        simParams.coex_guardTimeAfter = 0;

        if (simParams.coexMethod==6 && simParams.coexF_guardTime) || ...
           (simParams.coexMethod==3 && simParams.coexC_timegapVariant==2)
            simParams.coex_guardTimeBefore = round(phyParams.tPck11p, 10);
        end

        if simParams.coexMethod == constants.COEX_METHOD_F
            % Matrix of used BR
            stationManagement.coexF_knownUsed = zeros(appParams.Nbeacons,simValues.maxID);
            % Not needed from v 5.4.7
            %stationManagement.coexF_knownUsedInPrevious = zeros(appParams.Nbeacons,simValues.maxID);
        
        else %if simParams.coexMethod==constants.COEX_METHOD_C
            if simParams.coexC_moreThanOneSubframe
                simParams.coexC_maxLengthIndicated = 10;
            else
                simParams.coexC_maxLengthIndicated = 1;
            end
        end
        
        sinrManagement.coex_NAVexpiring = zeros(simValues.maxID,1);

    else
        error('Something wrong...Error #23823');
    end

    if simParams.coexMethod==constants.COEX_METHOD_A && simParams.coexA_endOfLteKnownBy11p~=-1        
        simParams.coex_knownEndOfLTE(stationManagement.vehicleState~=constants.V_STATE_LTE_TXRX) =...
            simParams.coexA_endOfLteKnownBy11p * ones(sum(stationManagement.vehicleState~=constants.V_STATE_LTE_TXRX),1);
    end
    
    % The sim starts within the LTE part
    % Thus the first superframe boundary is at the end of the 11p part
    timeManagement.coex_timeNextSuperframe(stationManagement.activeIDs) = (simParams.coex_knownEndOfLTE(stationManagement.activeIDs) + simParams.coex_guardTimeAfter) .* ones(length(stationManagement.activeIDs),1);
    timeManagement.coex_timeNextSuperframe(stationManagement.activeIDs) = timeManagement.coex_timeNextSuperframe(stationManagement.activeIDs) + ( rand(length(stationManagement.activeIDs),1) * (2*simParams.coexA_desynchError) - simParams.coexA_desynchError);
    timeManagement.coex_timeNextSuperframe(stationManagement.activeIDs) = round(timeManagement.coex_timeNextSuperframe(stationManagement.activeIDs), 10);
    timeManagement.coex_superframeThisIsLTEPart = true(simValues.maxID,1);
        
    % Coexistence, method A
    if simParams.coexMethod==constants.COEX_METHOD_A
        sinrManagement.coex_virtualInterference = inf * ones(simValues.maxID,1);
        % In the case with legacy ITS-G5, virtual intereference should be
        % zeros, since that is the variable used to identify the LTE part
        if simParams.coexA_withLegacyITSG5
            sinrManagement.coex_virtualInterference = zeros(simValues.maxID,1);
            timeManagement.coex_timeNextSuperframe(stationManagement.activeIDs) = inf * ones(simValues.maxID,1);
        end
    end
    
    % MOVED BEFORE Coexistence, method F
    %if simParams.coexMethod==6
    %    %sinrManagement.coex_virtualInterference = zeros(simValues.maxID,1);
    %    sinrManagement.coex_NAVexpiring = zeros(simValues.maxID,1);
    %end

%% THIS PART WAS METHOD C UNTIL VERSION 5.4.10
% elseif simParams.coexMethod==3
%     % The gap at the end of the transmission is reduced to almost 0 as it is
%     % virtually known as used by 11p nodes
%     % This introduces an approximation in the calculation of the SINR when
%     % some interference from 802.11p is present (no problems with noise or
%     % LTE interferers)
%     % Cannot be set to 0 because otherwise the CBR mechanism fails (CBR
%     % must be performed after the end and before the beginning of a
%     % subframe)
%     phyParams.TsfGap = 1e-6;
%     % This approach approximates the simulation of Method C, as it does not
%     % reproduces the 11p preamble added before (Variant 1) or at the beginining 
%     % (Variant 2) of the LTE subframe
%     %
%     % The sensing threshold when the signal is not detected is moved to
%     % -85dBm, given that also LTE signals are recognized as 11p at the
%     % beginning
%     if phyParams.CCAthr11p_notsync~=-85
%         fprintf('The CCA threshold is automatically changed to -85 dBm\n');
%     end
%     phyParams.CCAthr11p_notsync = -85;
%     phyParams.PrxSensNotSynch = 10^((phyParams.CCAthr11p_notsync-30)/10);
%     if simParams.coexC_ccaVariant
%         phyParams.CCAthr11p_notsync = -65;
%         phyParams.PrxSensNotSynch = 10^((phyParams.CCAthr11p_notsync-30)/10);
%     end
%     
%     %
%     if simParams.coexC_timegapVariant==2
%         simParams.coex_endOfLTE = 0;
%         simParams.coex_knownEndOfLTE = zeros(simValues.maxID,1);
%         simParams.coex_guardTimeBefore = phyParams.tPck11p + 1e-9;
%         simParams.coex_guardTimeAfter = 0;
%         timeManagement.coex_timeNextSuperframe = (simParams.coex_superFlength-simParams.coex_guardTimeBefore) * ones(simValues.maxID,1);
%         timeManagement.coex_superframeThisIsLTEPart = false(simValues.maxID,1);
%     end
%     
%     sinrManagement.coex_lteDetecting11pTx = false(simValues.maxID,1);
%     
else
    error('Implemented coexistence methods: "A", "B", "C", "F"');
end

% OPTIONALLY - IMPROVEMENT to coexistence methods
if simParams.technology==constants.TECH_COEX_STD_INTERF && simParams.coexMethod==constants.COEX_METHOD_A && simParams.coexA_improvements>0    
    timeManagement = coexistenceImprovements(timeManagement,-1,stationManagement,simParams,phyParams);
end

if simParams.technology==constants.TECH_COEX_STD_INTERF && simParams.coexMethod~=constants.COEX_METHOD_NON && simParams.coex_slotManagement==constants.COEX_SLOT_DYNAMIC
    if ~simParams.cbrActive
        error('With coexistence and dynamic slot management, CBR must be active!');
    end
end

    