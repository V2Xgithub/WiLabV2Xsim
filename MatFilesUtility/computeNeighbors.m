function [positionManagement,stationManagement] = computeNeighbors (stationManagement,positionManagement,phyParams)
% Function introduced in (version 5.6.0)

% NOTES
% stationManagement.activeIDs
% sinrManagement.P_RX_MHz( RECEIVER, TRANSMITTER) - activeIDs x activeIDs

% Selection of nodes with received power below a minimum
%nonNegligibleReceivedPower = sinrManagement.P_RX_MHz > phyParams.Pnoise_MHz/10;

%%
% LTE
%distanceReal_LTE = positionManagement.distanceReal(:,(stationManagement.vehicleState(stationManagement.activeIDs)==100));
if sum(stationManagement.vehicleState(stationManagement.activeIDs)==constants.V_STATE_LTE_TXRX)>0
%if simParams.technology~=2 % Not only 11p
    distanceReal_LTE = positionManagement.distanceReal;
    distanceEstimated_LTE = positionManagement.distanceEstimated;
    % Vehicles from which the received power is below a minimum are set to an infinite distance
    %distanceReal_LTE(stationManagement.activeIDs,stationManagement.activeIDs) = distanceReal_LTE(stationManagement.activeIDs,stationManagement.activeIDs)./nonNegligibleReceivedPower;
    % Vehciles that are not LTE are set to an infinite distance
    distanceReal_LTE(:,(stationManagement.vehicleState(stationManagement.activeIDs)~=100))=Inf;
    distanceEstimated_LTE(:,(stationManagement.vehicleState(stationManagement.activeIDs)~=100))=Inf;
    % The diagonal must be set to 0
    distanceReal_LTE(1:1+length(distanceReal_LTE(1,:)):end) = 0;
    distanceEstimated_LTE(1:1+length(distanceEstimated_LTE(1,:)):end) = 0;
    % sort
    [neighborsDistanceLTE, neighborsIndexLTE] = sort(distanceReal_LTE,2);
    [~, neighborsIndexLTE_Estimated] = sort(distanceEstimated_LTE,2);
    % remove the first element per each raw, which is self
    neighborsDistanceLTE(:,1) = [];
    neighborsIndexLTE(:,1) = [];
    neighborsIndexLTE_Estimated(:,1) = [];
    neighborsDistanceLTE_ofLTE = neighborsDistanceLTE(stationManagement.vehicleState(stationManagement.activeIDs)==100,:);
    neighborsIndexLTE_ofLTE = neighborsIndexLTE(stationManagement.vehicleState(stationManagement.activeIDs)==100,:);
    
    % Vehicles in order of distance
    %allNeighborsID = IDvehicle(neighborsIndexLTE);
    stationManagement.allNeighborsID = stationManagement.activeIDs(neighborsIndexLTE);
    stationManagement.allNeighborsIDEstimated = stationManagement.activeIDs(neighborsIndexLTE_Estimated);
    
    % Vehicles in the maximum awareness range
    stationManagement.neighborsIDLTE = (neighborsDistanceLTE_ofLTE < phyParams.RawMaxCV2X) .*stationManagement.activeIDs(neighborsIndexLTE_ofLTE);
    
    % Vehicles in awareness range
    if ~isempty(stationManagement.neighborsIDLTE)
        stationManagement.awarenessIDLTE = zeros(length(neighborsDistanceLTE_ofLTE(:,1)),length(neighborsDistanceLTE_ofLTE(1,:)),length(phyParams.Raw));
        for iPhyRaw=1:length(phyParams.Raw)
            stationManagement.awarenessIDLTE(:,:,iPhyRaw) = (neighborsDistanceLTE_ofLTE < phyParams.Raw(iPhyRaw)) .* stationManagement.neighborsIDLTE;
        end
    end

    % Removal of nodes that are not active
    stationManagement.neighborsIDLTE = stationManagement.neighborsIDLTE(:,1:length(stationManagement.activeIDsCV2X)-1);
    if ~isempty(stationManagement.neighborsIDLTE)
        stationManagement.awarenessIDLTE = stationManagement.awarenessIDLTE(:,1:length(stationManagement.activeIDsCV2X)-1,:);
    else
        stationManagement.awarenessIDLTE = [];
    end
    %stationManagement.neighborsDistanceLTE = stationManagement.neighborsDistanceLTE(:,1:length(stationManagement.activeIDsCV2X)-1);
    
    % LTE vehicles interfering 11p
    %if simParams.technology > 2
    %    neighborsDistanceLTE_of11p = neighborsDistanceLTE(stationManagement.vehicleState(stationManagement.activeIDs)~=100,:);
    %    neighborsIndexLTE_of11p = neighborsIndexLTE(stationManagement.vehicleState(stationManagement.activeIDs)~=100,:);
    %    %stationManagement.LTEinterfereingTo11p_ID = (neighborsDistanceLTE_of11p < phyParams.RawMaxCV2X) .*stationManagement.activeIDs(neighborsIndexLTE_of11p);
    %end
end
%%

%%
% 11p
if sum(stationManagement.vehicleState(stationManagement.activeIDs)~=constants.V_STATE_LTE_TXRX)>0
%if simParams.technology~=1 % Not only LTE    
    distanceReal_11p = positionManagement.distanceReal;
    % Vehciles that are not LTE are set to an infinite distance
    distanceReal_11p(:,(stationManagement.vehicleState(stationManagement.activeIDs)==100))=Inf;
    % The diagonal must be set to 0
    distanceReal_11p(1:1+length(distanceReal_11p(1,:)):end) = 0;
    % sort
    [neighborsDistance11p, neighborsIndex11p] = sort(distanceReal_11p,2);
    % remove the first element per each raw, which is self
    neighborsDistance11p(:,1) = [];
    neighborsIndex11p(:,1) = [];    
    neighborsDistance11p_of11p = neighborsDistance11p(stationManagement.vehicleState(stationManagement.activeIDs)~=100,:);
    neighborsIndex11p_of11p = neighborsIndex11p(stationManagement.vehicleState(stationManagement.activeIDs)~=100,:);
    
    % Vehicles in the maximum awareness range
    stationManagement.neighborsID11p = (neighborsDistance11p_of11p < phyParams.RawMax11p) .*stationManagement.activeIDs(neighborsIndex11p_of11p);

    % Vehicles in awareness range
    if ~isempty(stationManagement.neighborsID11p)
        stationManagement.awarenessID11p = zeros(length(neighborsDistance11p_of11p(:,1)),length(neighborsDistance11p_of11p(1,:)),length(phyParams.Raw));
        for iPhyRaw=1:length(phyParams.Raw)
            stationManagement.awarenessID11p(:,:,iPhyRaw) = (neighborsDistance11p_of11p < phyParams.Raw(iPhyRaw)) .* stationManagement.neighborsID11p;
        end
    end    

    % Keep only the distance of neighbors up to the maximum awareness range
    % and dealing with the technology of interest
    %stationManagement.neighborsDistance11p = (neighborsDistance11p_of11p < phyParams.RawMax11p) .* neighborsDistance11p_of11p;

    % 11p vehicles interfering LTE
    %if simParams.technology > 2
    %    neighborsDistance11p_ofLTE = neighborsDistance11p(stationManagement.vehicleState(stationManagement.activeIDs)==100,:);
    %    neighborsIndex11p_ofLTE = neighborsIndex11p(stationManagement.vehicleState(stationManagement.activeIDs)==100,:);
    %    %stationManagement.LTEinterfereingTo11p_ID = (neighborsDistance11p_ofLTE < phyParams.RawMaxCV2X) .*stationManagement.activeIDs(neighborsIndex11p_ofLTE);
    %end
end
%%

end
