function [stationManagement,sinrManagement,timeManagement] = coexistenceSetNAV_C( timeManagement, stationManagement, sinrManagement, phyParams, simParams, appParams,outParams )

% NOTE: added from version 5.4.11, taken in part from method F

%% Step 1: Select 11p nodes that are currently IDLE or Backoff
% or that have the NAV already set (in case, they might update)
nodes11pSensing = (stationManagement.vehicleState == constants.V_STATE_11P_IDLE) |...
    (stationManagement.vehicleState == constants.V_STATE_11P_BACKOFF) | ...
    (sinrManagement.coex_NAVexpiring > timeManagement.timeNow);
logicalSensing11p = nodes11pSensing(stationManagement.activeIDs11p);
indexOfSensing11p = stationManagement.indexInActiveIDs_of11pnodes(logicalSensing11p);

%% Step 2: Select LTE nodes transmitting the 11p header
% They are those that are transmitting in this subframe
%lteTxNAV = stationManagement.indexInActiveIDs_OfTxLTE;
%txLTE = stationManagement.activeIDsCV2X(logicalTxLTE);
indexOfTxLTE = stationManagement.transmittingIDsCV2X;

%% Step 3: Calculate total rx power at 11p nodes from all LTE tx NAV
totalReceivedBy11p_MHz = sum((sinrManagement.P_RX_MHz(indexOfSensing11p,indexOfTxLTE)),2);

%% LTE signals with NAV sum up

% SINR calculation
sinrCalculated = totalReceivedBy11p_MHz./...
    ( phyParams.Pnoise_MHz + sinrManagement.P_RX_MHz(indexOfSensing11p,:) * (stationManagement.vehicleState(stationManagement.activeIDs)==constants.V_STATE_11P_TX));
% Check NAV correctly received
% The SINR corresponding to PER = 90% LOS is used
%sinrThr=phyParams.sinrThreshold11p_LOS;  %LOS
%sensingNodesReceivingNAV = (sinrCalculated > sinrThr);

% The preamble check needs to be performed using the SINR threshold set for the preamble
% do we need consider packet repetition here?
sensingNodesReceivingNAV = (sinrCalculated > phyParams.sinrThreshold11p_preamble);
powerFromCV2X = sinrManagement.coex_InterfFromLTEto11p;
powerFromITS = sinrManagement.P_RX_MHz * (stationManagement.vehicleState(stationManagement.activeIDs)==constants.V_STATE_11P_TX) * phyParams.BwMHz;
higherThanThreshold = (powerFromCV2X + powerFromITS) >= phyParams.PrxSensWhenSynch;
% set the NAV  
thisTinSuperframe = mod(timeManagement.elapsedTime_TTIs-1,simParams.coex_superframeTTI)+1;
% (Vittorio 5.5.3)
timeCV2XtoTTIEnd = simParams.coex_endOfLTE-(thisTinSuperframe * phyParams.TTI);  

% In the NAV, a maximum of 32 can be advertised
% round( , 10) is added to cope with comparisons including float numbers
timeInNAV = round(timeManagement.timeNow+min(timeCV2XtoTTIEnd,simParams.coexC_maxLengthIndicated*phyParams.TTI), 10);

sinrManagement.coex_virtualInterference(indexOfSensing11p(sensingNodesReceivingNAV)) = inf;
sinrManagement.coex_NAVexpiring(indexOfSensing11p(sensingNodesReceivingNAV)) = max(sinrManagement.coex_NAVexpiring(indexOfSensing11p(sensingNodesReceivingNAV)),timeInNAV);

if simParams.cbrActive && ~isempty(stationManagement.channelSensedBusyMatrix11p)
    ifStartCBR = (timeManagement.cbr11p_timeStartBusy(indexOfSensing11p)==-1 & sensingNodesReceivingNAV & higherThanThreshold(indexOfSensing11p));
    % Time is updated
    timeManagement.cbr11p_timeStartBusy(indexOfSensing11p(ifStartCBR)) = timeManagement.timeNow;
end
