function [timeManagement,stationManagement,sinrManagement,outputValues] = endOfBackoff11p(idEvent,indexEvent,simParams,simValues,phyParams,timeManagement,stationManagement,sinrManagement,appParams,outParams,outputValues)
% A backoff ends and the corresponding transmission starts

% A transmission starts:
% - The backoff counter is reset
% - The end of the transmission is set
stationManagement.vehicleState(idEvent) = 3; % tx
stationManagement.nSlotBackoff11p(idEvent) = -1;

if simParams.technology == 2 && appParams.variableBeaconSize % if ONLY 11p
    % If variable beacon size is selected, find if small or large packet is
    % currently transmitted (1 stays for large, 0 for small)
    error('This feature has not been tested in this version of the simulator.');
    %stationManagement.ifBeaconLarge = (mod(stationManagement.variableBeaconSizePeriodicity(indexEvent)+floor(timeManagement.timeNow/appParams.Tbeacon),appParams.NbeaconsSmall+1))==0;
else
    % Always large
    stationManagement.ifBeaconLarge = 1;
end

if stationManagement.ifBeaconLarge 
    % If the vehicle transmits a large packet
    timeManagement.timeNextTxRx11p(idEvent) = round(timeManagement.timeNow + phyParams.tPck11p, 10);
else
    % if only 11p and variable beacons
    % If the vehicle transmits a small packet
    timeManagement.timeNextTxRx11p(idEvent) = round(timeManagement.timeNow + phyParams.tPck11pSmall, 10);
end

% The average SINR is updated
sinrManagement = updateSINR11p(timeManagement,sinrManagement,stationManagement,phyParams);

% Check the nodes that start receiving
[timeManagement,stationManagement,sinrManagement,outputValues] = checkVehiclesStartReceiving11p(idEvent,indexEvent,timeManagement,stationManagement,sinrManagement,simParams,phyParams,outParams,outputValues);

% The present overall/useful power received and the instant of calculation are updated
% The power received must be calculated after
% 'checkVehiclesStartReceiving11p', to have the correct idFromWhichtransmitting
[sinrManagement] = updateLastPower11p(timeManagement,stationManagement,sinrManagement,phyParams,simValues);

if simParams.technology == constants.TECH_COEX_STD_INTERF % COEXISTENCE IN THE SAME BAND
    % 1. The average SINR of LTE is updated
    % Compute SINR of received beacons
    % sinrManagement = updateSINRLTE(timeManagement.timeNow,stationManagement,sinrManagement,phyParams.Pnoise_MHz*phyParams.BwMHz_cv2xBR,simParams,appParams);
    sinrManagement = updateSINRCV2X(timeManagement.timeNow,stationManagement,sinrManagement,phyParams.PnoiseData,phyParams.PnoiseSCI,simParams,appParams);

    % 2. The inteference from this 11p is added
    % only LTE vehicles are interferred (state == 100)
    % only this new 11p adds interference
    % the interference is proportional to BW-LTE
    sinrManagement.coex_currentInterfEach11pNodeToLTE(stationManagement.activeIDsCV2X,idEvent) = phyParams.BwMHz_cv2xBR * sinrManagement.P_RX_MHz(stationManagement.indexInActiveIDs_ofLTEnodes,indexEvent);    
	sinrManagement.coex_currentInterfFrom11pToLTE(stationManagement.activeIDsCV2X) = sinrManagement.coex_currentInterfFrom11pToLTE(stationManagement.activeIDsCV2X) + sinrManagement.coex_currentInterfEach11pNodeToLTE(stationManagement.activeIDsCV2X,idEvent);
    
    % For possible DEBUG
    % fprintf('Start: added id %d\n',idEvent);
    % fprintf('RXinterf 46 --> 9 is %e, %fdB\n',sinrManagement.interferingPRXfrom11p(9,46),10*log10(sinrManagement.interferingPRXfrom11p(9,46)));
    % fprintf('RXinterf 178 --> 9 is %e, %fdB\n',sinrManagement.interferingPRXfrom11p(9,178),10*log10(sinrManagement.interferingPRXfrom11p(9,178)));
    % fprintf('RXinterfFrom11pLastLTE(9) is %e, %fdB\n',sinrManagement.RXinterfFrom11pLastLTE(9),10*log10(sinrManagement.RXinterfFrom11pLastLTE(9)));
end

stationManagement.pckTxOccurring(idEvent) = stationManagement.pckNextAttempt(idEvent);
stationManagement.pckNextAttempt(idEvent) = stationManagement.pckNextAttempt(idEvent) + 1;


