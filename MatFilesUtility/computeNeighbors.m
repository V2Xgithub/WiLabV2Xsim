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
if any(stationManagement.vehicleState == constants.V_STATE_LTE_TXRX)
    % Find vehicle indices that are using LTE and in active state
    LTEIndices = find(stationManagement.vehicleState == constants.V_STATE_LTE_TXRX);
    ActiveIndices = stationManagement.activeIDs;
    ActiveLTEIndices = intersect(LTEIndices, ActiveIndices);
    n_activeLTE = numel(ActiveLTEIndices);

    if n_activeLTE ~= 0
        % distance of LTE vehicles to every other vehicle
        distanceReal_LTE = positionManagement.distanceReal(ActiveLTEIndices, ActiveIndices);
        distanceEstimated_LTE = positionManagement.distanceEstimated(ActiveLTEIndices, ActiveIndices);
    
        % sort
        [neighborsDistanceLTE, neighborsIndexLTE] = sort(distanceReal_LTE,2);
        [~, neighborsIndexLTE_Estimated] = sort(distanceEstimated_LTE,2);
        % remove the first element per each raw, which is self
        neighborsDistanceLTE(:,1) = [];
        neighborsIndexLTE(:,1) = [];
        neighborsIndexLTE_Estimated(:,1) = [];
        
        % Vehicle Indices in order of distance - LTE to everything
        stationManagement.allNeighborsID = neighborsIndexLTE;
        stationManagement.allNeighborsIDEstimated = neighborsIndexLTE_Estimated;
    
        % Vehicle Indices in order of distance - LTE to LTE
        neighborsDistanceLTE_ofLTE = neighborsDistanceLTE;
        neighborsIndexLTE_ofLTE = neighborsIndexLTE;
        neighborsIndexLTE_ofLTE_mask = ismember(neighborsIndexLTE_ofLTE, ~LTEIndices);
        neighborsIndexLTE_ofLTE(neighborsIndexLTE_ofLTE_mask) = [];
        neighborsDistanceLTE_ofLTE(neighborsIndexLTE_ofLTE_mask) = [];
        % neighborsIndexLTE_ofLTE = reshape(neighborsIndexLTE_ofLTE, n_activeLTE, n_activeLTE);
        % neighborsDistanceLTE_ofLTE = reshape(neighborsDistanceLTE_ofLTE, n_activeLTE, n_activeLTE);
    
        % Vehicles in the maximum awareness range - LTE to LTE
        stationManagement.neighborsIDLTE = (neighborsDistanceLTE_ofLTE < phyParams.RawMaxCV2X) .* neighborsIndexLTE_ofLTE;
        % Vehicles in varying awareness range - LTE to LTE
        stationManagement.awarenessIDLTE = zeros(n_activeLTE, n_activeLTE - 1, numel(phyParams.Raw));
        for iPhyRaw=1:length(phyParams.Raw)
            stationManagement.awarenessIDLTE(:,:,iPhyRaw) = (neighborsDistanceLTE_ofLTE < phyParams.Raw(iPhyRaw)) .* stationManagement.neighborsIDLTE;
        end
    else
        stationManagement.allNeighborsID = zeros(0, 0);
        stationManagement.allNeighborsIDEstimated = zeros(0, 0);
        stationManagement.neighborsIDLTE = zeros(0, 0);
        stationManagement.awarenessIDLTE = zeros(0, 0, numel(phyParams.Raw));
    end
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
