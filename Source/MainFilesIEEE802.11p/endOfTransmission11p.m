function [simValues,outputValues,timeManagement,stationManagement,sinrManagement] = endOfTransmission11p(idEvent,indexEvent,positionManagement,phyParams,outParams,simParams,simValues,outputValues,timeManagement,stationManagement,sinrManagement,appParams)
% A transmission ends in IEEE 802.11p

% The transmitting vehicle is first updated
[timeManagement,stationManagement,sinrManagement] = updateVehicleEndingTx11p(idEvent,indexEvent,timeManagement,stationManagement,sinrManagement,phyParams,simParams,outParams);

% The average SINR of all vehicles is then updated
sinrManagement = updateSINR11p(timeManagement,sinrManagement,stationManagement,phyParams);

% DEBUG TX
printDebugTx(timeManagement.timeNow,false,idEvent,stationManagement,positionManagement,sinrManagement,outParams,phyParams);            

% Update KPIs
[simValues,outputValues,sinrManagement,stationManagement] = updateKPI11p(idEvent,indexEvent,timeManagement,stationManagement,positionManagement,sinrManagement,simParams,phyParams,outParams,simValues,outputValues);

% The nodes that may stop receiving must be checked
[timeManagement,stationManagement,sinrManagement,outputValues] = checkVehiclesStopReceiving11p(timeManagement,stationManagement,sinrManagement,simParams,phyParams,outParams,outputValues);

% The present overall/useful power received and the instant of calculation are updated
% The power received must be calculated after
% 'checkVehiclesStopReceiving11p', to have the correct idFromWhichtransmitting
[sinrManagement] = updateLastPower11p(timeManagement,stationManagement,sinrManagement,phyParams,simValues);

if simParams.technology == constants.TECH_COEX_STD_INTERF % COEXISTENCE IN THE SAME BAND
    % 1. The average SINR of LTE is updated
    % Compute SINR of received beacons
    % sinrManagement = updateSINRLTE(timeManagement.timeNow,stationManagement,sinrManagement,phyParams.Pnoise_MHz*phyParams.BwMHz_cv2xBR,simParams,appParams);
    sinrManagement = updateSINRCV2X(timeManagement.timeNow,stationManagement,sinrManagement,phyParams.PnoiseData,phyParams.PnoiseSCI,simParams,appParams);

    % 2. The inteference from this 11p is removed
    % only LTE vehicles are interferred (state == 100)
    % only this new 11p adds interference
    % the interference is proportional to BW-LTE / BW-11p
    % Note: sinrManagement.interferingPRXfrom11p is needed to
    % cope with possible variations (very small, in any case)
    % to interference caused by position update
    sinrManagement.coex_currentInterfFrom11pToLTE(stationManagement.activeIDsCV2X) = sinrManagement.coex_currentInterfFrom11pToLTE(stationManagement.activeIDsCV2X) - sinrManagement.coex_currentInterfEach11pNodeToLTE(stationManagement.activeIDsCV2X,idEvent);
    sinrManagement.coex_currentInterfEach11pNodeToLTE(stationManagement.activeIDsCV2X,idEvent) = 0;

% fprintf('End: removed id %d\n',idEvent);
% fprintf('RXinterf 46 --> 9 is %e, %fdB\n',sinrManagement.interferingPRXfrom11p(9,46),10*log10(sinrManagement.interferingPRXfrom11p(9,46)));
% fprintf('RXinterf 178 --> 9 is %e, %fdB\n',sinrManagement.interferingPRXfrom11p(9,178),10*log10(sinrManagement.interferingPRXfrom11p(9,178)));
% fprintf('RXinterfFrom11pLastLTE(9) is %e, %fdB\n',sinrManagement.RXinterfFrom11pLastLTE(9),10*log10(sinrManagement.RXinterfFrom11pLastLTE(9)));

    if (sum(sinrManagement.coex_currentInterfFrom11pToLTE(stationManagement.activeIDsCV2X)<-10^-12)) > 0
        error('Negative interference');
    end
end

