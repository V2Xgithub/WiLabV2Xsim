function [timeManagement,stationManagement,sinrManagement,outputValues] = coexistenceAtLTEsubframeEnd(timeManagement,stationManagement,sinrManagement,simParams,simValues,phyParams,outParams,outputValues)

% 1. The average SINR of 11p is updated
sinrManagement = updateSINR11p(timeManagement,sinrManagement,stationManagement,phyParams);

% 2. The inteference from LTE is reset
sinrManagement.coex_InterfFromLTEto11p = zeros(simValues.maxID,1);

% 3. 11p nodes might sense the channel as free and resume a
% possibly freezed backoff
[timeManagement,stationManagement,sinrManagement,outputValues] = checkVehiclesStopReceiving11p(timeManagement,stationManagement,sinrManagement,simParams,phyParams,outParams,outputValues);
