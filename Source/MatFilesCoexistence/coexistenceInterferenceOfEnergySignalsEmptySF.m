function interfFromEnergySignals = coexistenceInterferenceOfEnergySignalsEmptySF(timeManagement,stationManagement,sinrManagement,phyParams,appParams,simParams,simValues)

% Same as calculated for the CBR
thresh_subchannel = 10^((-94-30)/10); % fixed in this version
thresh_PerRB = thresh_subchannel/phyParams.sizeSubchannel;

% Current TTI
current_TTI_in_superframe = floor(mod(timeManagement.timeNow+1e-7,simParams.coex_superFlength)/phyParams.TTI)+1;

% Inizialization of the output
interfFromEnergySignals = zeros(simValues.maxID,1);

%% Find IDs of vehicles that are currently sensing the channel as idle;
% Sense the channel - the following matrix is NbeaconsF x nVehicles
sinrManagement.sensedPowerByLteNo11p = sensedPowerCV2X(stationManagement,sinrManagement,appParams,phyParams);
sensedPower = sinrManagement.sensedPowerByLteNo11p + repmat((sinrManagement.coex_averageTTIinterfFrom11pToLTE(stationManagement.activeIDsCV2X))',appParams.NbeaconsF,1);
% Check if the channel is sensed as idle
sensedBusy = sum(( sensedPower > thresh_PerRB),1);

% Check if in the LTE part
ifInLTEpart = current_TTI_in_superframe <= sinrManagement.coex_NtotTTILTE(stationManagement.activeIDsCV2X);

if sum(sensedBusy==0)>0
    
    if simParams.coexB_allToTransmitInEmptySF
        idTxEnergySignals = stationManagement.activeIDsCV2X((sensedBusy==0)' & ifInLTEpart);
    else
        % Only those nodes that will transmit in the remaining LTE slot
        BRidT = ceil((stationManagement.BRid(:,1))/appParams.NbeaconsF);
        BRidT(stationManagement.BRid(:,1)<=0) = 0;
        BRidInSuperframe = mod(BRidT-1,simParams.coex_superframeTTI)+1; 
        idTxEnergySignals = stationManagement.activeIDsCV2X(...
                (sensedBusy==0)' & ifInLTEpart &...
                (BRidInSuperframe(stationManagement.activeIDsCV2X)>current_TTI_in_superframe)...
            );
    end
    indexTxEnergySignals = zeros(length(idTxEnergySignals),1);
    for i=1:length(idTxEnergySignals)
        indexTxEnergySignals(i) = find(stationManagement.activeIDs==idTxEnergySignals(i));
    end    
    interfFromEnergySignals(stationManagement.activeIDs) = phyParams.BwMHz_cv2xBR * (sum(sinrManagement.P_RX_MHz(:,indexTxEnergySignals),2));
    % the interference is not relevant for LTE nodes...
    % those sending the signal must consider this channel as free
    % if there are others, they are assumed not to sense the sent energy signal
    interfFromEnergySignals(stationManagement.activeIDsCV2X)=inf;
end