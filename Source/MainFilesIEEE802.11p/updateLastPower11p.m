function [sinrManagement] = updateLastPower11p(timeManagement,stationManagement,sinrManagement,phyParams,simValues)
% rxPowerTotLast, rxPowerUsefulLast, and instantThisPrStarted are updated
% They will be used to compute the average SINR when the next transmission
% will start or end

%IDvehicle = stationManagement.activeIDs;
activeIDs11p = stationManagement.activeIDs11p;
rxPowerBW = (sinrManagement.P_RX_MHz(stationManagement.indexInActiveIDs_of11pnodes,stationManagement.indexInActiveIDs_of11pnodes)*phyParams.BwMHz);

sinrManagement.rxPowerUsefulLast11p = zeros(simValues.maxID,1);
rxPowerTotLast = zeros(simValues.maxID,1);
sinrManagement.rxPowerInterfLast11p= zeros(simValues.maxID,1);

%rxPowerTotLast(IDvehicle) = (rxPowerBW * (stationManagement.vehicleState(IDvehicle)==3));
rxPowerTotLast(activeIDs11p) = (rxPowerBW * (stationManagement.vehicleState(activeIDs11p)==3));
%for indexV = 1:length(IDvehicle)
for indexV = 1:length(activeIDs11p)
    % if not LTE and not receiving from self, the useful needs to be
    % updated
    idReceiving = activeIDs11p(indexV);
    %if stationManagement.vehicleState(IDvehicle(indexV))~=100 && sinrManagement.idFromWhichRx11p(IDvehicle(indexV))~=IDvehicle(indexV)
    if sinrManagement.idFromWhichRx11p(idReceiving) ~= idReceiving
        % the index of the node from which this node is receiving is computed
        %indexFromWhichRx = find(IDvehicle==sinrManagement.idFromWhichRx11p(IDvehicle(indexV)),1);
        indexFromWhichRx = find(activeIDs11p==sinrManagement.idFromWhichRx11p(idReceiving),1);
        % if indexFromWhichRx is empty, something is wrong: the vehicle from
        % which this node is receiving is not in the scenario
        % unless it has a freezed backoff due to LTE transmissions
        if isempty(indexFromWhichRx)
            error('is empty indexFromWhichRx, IDvehicle(indexV)=%d',idReceiving);
        end
        % the useful rx power is calculated
        %sinrManagement.rxPowerUsefulLast11p(IDvehicle(indexV)) = rxPowerBW(indexV,indexFromWhichRx);
        sinrManagement.rxPowerUsefulLast11p(idReceiving) = rxPowerBW(indexV,indexFromWhichRx);
        % if the useful rx power is larger then the total rx power there is
        % something wrong, unless the node is just sensing the medium as busy; in such case, it should 
        % be receiving by 'itself'
        if sinrManagement.rxPowerUsefulLast11p(idReceiving) > rxPowerTotLast(idReceiving)
            error('useful rx power > total rx power, vehicle=%d (state=%d) rx from=%d (state=%d)',idReceiving,stationManagement.vehicleState(idReceiving),sinrManagement.idFromWhichRx11p(idReceiving),stationManagement.vehicleState(sinrManagement.idFromWhichRx11p(idReceiving)));
        end
        %if sinrManagement.rxPowerUsefulLast11p(IDvehicle(indexV)) > rxPowerTotLast(IDvehicle(indexV)) && ...
        %        sinrManagement.idFromWhichRx11p(IDvehicle(indexV))~=IDvehicle(indexV)
        %    error('useful rx power > total rx power, vehicle=%d (state"%d) rx from=%d (state=%d)',IDvehicle(indexV),stationManagement.vehicleState(IDvehicle(indexV)),sinrManagement.idFromWhichRx11p(IDvehicle(indexV)),stationManagement.vehicleState(sinrManagement.idFromWhichRx11p(IDvehicle(indexV))));
        %end
    end
end
%sinrManagement.rxPowerInterfLast11p(IDvehicle) = rxPowerTotLast(IDvehicle)-sinrManagement.rxPowerUsefulLast11p(IDvehicle);
sinrManagement.rxPowerInterfLast11p(activeIDs11p) = rxPowerTotLast(activeIDs11p)-sinrManagement.rxPowerUsefulLast11p(activeIDs11p);
%sinrManagement.instantThisPrStarted11p = timeManagement.timeNow;
