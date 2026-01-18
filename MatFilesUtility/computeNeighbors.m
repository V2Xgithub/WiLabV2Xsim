function [positionManagement,stationManagement] = computeNeighbors (stationManagement,positionManagement,phyParams)
% Function introduced in (version 5.6.0)

% NOTES
% stationManagement.activeIDs
% sinrManagement.P_RX_MHz( RECEIVER, TRANSMITTER) - activeIDs x activeIDs

% Selection of nodes with received power below a minimum
%nonNegligibleReceivedPower = sinrManagement.P_RX_MHz > phyParams.Pnoise_MHz/10;

%% preprocessing distance
if ~isempty(stationManagement.activeIDs)
    distanceReal = positionManagement.distanceReal;
    
    % vehicles with different technologies have infinite distance between each
    % other
    distanceReal(stationManagement.indexInActiveIDs_ofLTEnodes, stationManagement.indexInActiveIDs_of11pnodes)=Inf;
    distanceReal(stationManagement.indexInActiveIDs_of11pnodes, stationManagement.indexInActiveIDs_ofLTEnodes)=Inf;
    
    % The diagonal must be set to 0
    distanceReal(1:1+size(distanceReal, 2):end) = 0;
    
    % sort 
    [neighborsDistance, neighborsIndex] = sort(distanceReal,2);
    
    % remove the first element per each raw, which is self
    neighborsDistance(:,1) = [];
    neighborsIndex(:,1) = [];  
end


%% If there were active CV2X vehicles
if ~isempty(stationManagement.activeIDsCV2X)
    neighborsDistanceLTE2ALL = neighborsDistance(stationManagement.indexInActiveIDs_ofLTEnodes,:);
    neighborsIndexLTE2ALL = neighborsIndex(stationManagement.indexInActiveIDs_ofLTEnodes,:);
    
    % Vehicles in order of distance
    %allNeighborsID = IDvehicle(neighborsIndexLTE);
    stationManagement.allNeighborsID = stationManagement.activeIDs(neighborsIndex);
    
    % Vehicles within the maximum awareness range
    stationManagement.neighborsIDLTE = (neighborsDistanceLTE2ALL < phyParams.RawMaxCV2X) .* stationManagement.activeIDs(neighborsIndexLTE2ALL);
    
    % Vehicles in awareness range
    if ~isempty(stationManagement.neighborsIDLTE)
        stationManagement.awarenessIDLTE = zeros([size(neighborsDistanceLTE2ALL), length(phyParams.Raw)]);
        for iPhyRaw=1:length(phyParams.Raw)
            stationManagement.awarenessIDLTE(:,:,iPhyRaw) = (neighborsDistanceLTE2ALL < phyParams.Raw(iPhyRaw)) .* stationManagement.neighborsIDLTE;
        end
    end

    % Remove nodes that are not active CV2X
    stationManagement.neighborsIDLTE(:, length(stationManagement.activeIDsCV2X):end) = [];
    if ~isempty(stationManagement.neighborsIDLTE)
        stationManagement.awarenessIDLTE(:,length(stationManagement.activeIDsCV2X):end,:) = [];
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


%% If there were active 11p vehicles
if ~isempty(stationManagement.activeIDs11p) 
    neighborsDistance11p2ALL = neighborsDistance(stationManagement.indexInActiveIDs_of11pnodes,:);
    neighborsIndex11p2ALL = neighborsIndex(stationManagement.indexInActiveIDs_of11pnodes,:);
    
    % Vehicles in the maximum awareness range
    stationManagement.neighborsID11p = (neighborsDistance11p2ALL < phyParams.RawMax11p) .* stationManagement.activeIDs(neighborsIndex11p2ALL);

    % Vehicles in awareness range
    if ~isempty(stationManagement.neighborsID11p)
        stationManagement.awarenessID11p = zeros([size(neighborsDistance11p2ALL), length(phyParams.Raw)]);
        for iPhyRaw=1:length(phyParams.Raw)
            stationManagement.awarenessID11p(:,:,iPhyRaw) = (neighborsDistance11p2ALL < phyParams.Raw(iPhyRaw)) .* stationManagement.neighborsID11p;
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


end