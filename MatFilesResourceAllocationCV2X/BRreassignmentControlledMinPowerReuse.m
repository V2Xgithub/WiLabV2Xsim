function [BRid, Nreassign] = BRreassignmentControlledMinPowerReuse(IDvehicle,BRid,scheduledID,RXpower,Shadowing_dB,knownShadowing,NbeaconsT,NbeaconsF)
% [CONTROLLED CASE WITH MINIMUM POWER REUSE]
% Forcedly reassign BRs to the group of vehicles that have been scheduled,
% using the maximum possible distance for reuse

% Find IDs of new vehicles in the scenario (initially blocked)
newVehicleID = find(BRid==-1);

% Add new vehicles to the scheduled IDs (without repetitions)
scheduledID = unique(vertcat(scheduledID,newVehicleID));

% Number of scheduled vehicles
Nscheduled = length(scheduledID);
p = randperm(Nscheduled);

% Update vector of resources
BRid(scheduledID)=-1;

% Find not assigned BRid
indexNOT = BRid<=0;

% Calculate BRidT = vector of BRid in the time domain
BRidT = ceil(BRid/NbeaconsF);
BRidT(indexNOT) = -1;

% Calculate BRidF = vector of BRid in the frequency domain
BRidF = mod(BRid-1,NbeaconsF)+1;
BRidF(indexNOT) = -1;

if knownShadowing
    % Find matrix of estimated received power (no shadowing)
    estimatedRXpower = RXpower./(10.^(Shadowing_dB/10));    
else   
    % Find matrix of estimated received power
    estimatedRXpower = RXpower;   
end

% Assign BRs to scheduled vehicles
for i = 1:Nscheduled
    z = p(i);
    ID = scheduledID(z,1);
    % Find the correspondent index in IDvehicle
    indexVehicle = IDvehicle==ID;
    % Sort vehicles in order of descending RX power
    [~,orderedIndexes] = sort(estimatedRXpower(indexVehicle,:),'descend');
    orderedIDs = IDvehicle(orderedIndexes);
    % Initialize array of occupied BRTs
    beaconArrayT = zeros(NbeaconsT,1);
    foundT = 0;
    % Check BRidTs of all vehicles in order of received power
    for j=1:length(orderedIDs)
        BRT = BRidT(orderedIDs(j));
        if BRT > 0
            % BRT is occupied
            beaconArrayT(BRT) = 1;
            if nnz(beaconArrayT) == NbeaconsT
                % If all BRTs are occupied, choose the last one (minimum
                % RXpower) and check the occupation of BRFs
                foundT = 1;
                neighborsIndex = find(BRidT(orderedIDs)==BRT);
                % Initialize array of occupied BRFs
                beaconArrayF = zeros(NbeaconsF,1);
                foundF = 0;
                % Start searching for the best BRF (the one with less RX power)
                for k = 1:length(neighborsIndex)
                    BRF = BRidF(orderedIDs(neighborsIndex(k)));
                    % BRF is occupied
                    beaconArrayF(BRF) = 1;
                    if nnz(beaconArrayF) == NbeaconsF
                        % All BRFs are used, choose the last one
                        foundF = 1;
                        break
                    end
                end
                break
            end
        end
    end
    
    % If there are more than one free BRTs
    if ~foundT
        % Find free BRTs
        freeBRTs = find(beaconArrayT==0);
        % Choose a random BRT among the free ones
        index = randi(length(freeBRTs));
        BRT = freeBRTs(index);
        % Choose a random BRF among all NbeaconsF
        BRF = randi(NbeaconsF);
    % If there are more than one free BRFs
    elseif foundT && ~foundF
        % Find free BRFs
        freeBRFs = find(beaconArrayF==0);
        % Choose a random BRF among the free ones
        index = randi(length(freeBRFs));
        BRF = freeBRFs(index);
    end
    
    % Update BRid, BRidT and BRidF of vehicle ID
    BRid(ID) = (BRT-1)*NbeaconsF+BRF;
    BRidT(ID) = BRT;
    BRidF(ID) = BRF;
    
end

% Number of reassignments
Nreassign = Nscheduled;

end