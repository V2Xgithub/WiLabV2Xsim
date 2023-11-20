function [stationManagement,sinrManagement] = coexistenceSetNAV_F(timeManagement, stationManagement, sinrManagement, phyParams, simParams, appParams, thisT)

% NOTE: from version 5.4.7, this function is basically new

%% Step 1: Select 11p nodes that are currently IDLE or Backoff
% or that have the NAV already set (in case, they might update)
nodes11pSensing = (stationManagement.vehicleState == constants.V_STATE_11P_IDLE) |...
    (stationManagement.vehicleState == constants.V_STATE_11P_BACKOFF) | ...
    (sinrManagement.coex_NAVexpiring > timeManagement.timeNow) ;
logicalSensing11p = nodes11pSensing(stationManagement.activeIDs11p);
sensing11p = stationManagement.activeIDs11p(logicalSensing11p);
indexOfSensing11p = stationManagement.indexInActiveIDs_of11pnodes(logicalSensing11p);

%% Step 2: Select LTE nodes transmitting the NAV
% They are those that: 
% 1) have a resource in this superframe (approx?: we do not care if they have 
%    also a packet to transmit or not); 
% 2) do not see as used one of the previous resources.
firstBRofSuperframe = (thisT-1) * appParams.NbeaconsF + 1;
superframeSizeInBR = simParams.coex_superframeTTI * appParams.NbeaconsF;
if (firstBRofSuperframe+superframeSizeInBR-1) > (appParams.NbeaconsT*appParams.NbeaconsF)
    error('Method F: resources in superframe exceeding the available resources (%d > %d)',(firstBRofSuperframe+superframeSizeInBR-1), appParams.Nbeacons);
end

lteNodesWithRBthisSuperframe = stationManagement.BRid(:,1)>=firstBRofSuperframe & ...
    stationManagement.BRid(:,1)<=(firstBRofSuperframe+superframeSizeInBR-1);

lteKnownUsedBefore = false(length(lteNodesWithRBthisSuperframe),1);
for iUser=1:length(stationManagement.BRid(:,1))
    lteKnownUsedBefore(iUser) = (sum( stationManagement.coexF_knownUsed(firstBRofSuperframe:(stationManagement.BRid(iUser,1)-1),iUser) ) > 0);
end

lteTxNAV = lteNodesWithRBthisSuperframe & (~lteKnownUsedBefore);
logicalTxLTE = lteTxNAV(stationManagement.activeIDsCV2X);
indexOfTxLTE = stationManagement.indexInActiveIDs_ofLTEnodes(logicalTxLTE);

%% Step 3: Calculate total rx power at 11p nodes from all LTE tx NAV
totalReceivedBy11p_MHz = sum(sinrManagement.P_RX_MHz(indexOfSensing11p,indexOfTxLTE), 2);

% LTE signals with NAV do not sum, but interfere
for i = 1:length(indexOfTxLTE)

    indexOfThisLTE = indexOfTxLTE(i);
    
    % Time this LTE advertise in the NAV
    timeLTEslotEnds = sinrManagement.coex_NtotSubframeLTE(indexOfThisLTE) * phyParams.Tsf;  
    timeInNAV = timeManagement.timeNow+min(timeLTEslotEnds,32*phyParams.Tsf)-1e-9;
    
    % Power received by the selected 11p nodes from this LTE node  
    usefulReceived_MHz = sinrManagement.P_RX_MHz(indexOfSensing11p,indexOfThisLTE);
    % SINR calculation
    sinrCalculated = usefulReceived_MHz ./ ( phyParams.Pnoise_MHz + (totalReceivedBy11p_MHz-usefulReceived_MHz) + (sinrManagement.P_RX_MHz(indexOfSensing11p,:) * (stationManagement.vehicleState(stationManagement.activeIDs)==3)));
    % Check NAV correctly received
    % UNTIL v5.4.10
    % The SINR corresponding to PER = 90% is used
    %sinrThr=phyParams.sinrThreshold11p_LOS.*phyParams.LOS(indexOfSensing11p,indexOfThisLTE)+...%LOS
    %    (1-phyParams.LOS(indexOfSensing11p,indexOfThisLTE)).*phyParams.sinrThreshold11p_NLOS;  %NLOS
    % FROM v5.4.11 the curve is used
    sinrThr = phyParams.LOS(indexOfSensing11p,indexOfThisLTE)'.*phyParams.sinrVector11p_LOS(randi(length(phyParams.sinrVector11p_LOS),1,length(indexOfSensing11p)))+...
        (1-phyParams.LOS(indexOfSensing11p,indexOfThisLTE)').*(phyParams.sinrVector11p_NLOS(randi(length(phyParams.sinrVector11p_NLOS),1,length(indexOfSensing11p))));
    
    sensingNodesReceivingNAV = sinrCalculated > sinrThr';
    
    %% Debug
    %if sum(sensingNodesReceivingNAV>0)
    %    STOPHERE = 0;
    %end

    % set the NAV    
    % In the NAV, a maximum of 32 can be advertised
    % -1e-9 is added to cope with comparisons including float numbers
    sinrManagement.coex_virtualInterference(sensing11p(sensingNodesReceivingNAV)) = inf;
    sinrManagement.coex_NAVexpiring(sensing11p(sensingNodesReceivingNAV)) = max(sinrManagement.coex_NAVexpiring(sensing11p(sensingNodesReceivingNAV)),timeInNAV);
end