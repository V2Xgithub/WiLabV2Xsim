function [timeManagement,stationManagement,sinrManagement,Nreassign] = BRreassignment3GPPautonomous(timeManagement,stationManagement,positionManagement,sinrManagement,simParams,phyParams,appParams,outParams)
% Sensing-based autonomous resource reselection algorithm (3GPP MODE 4)
% as from 3GPP TS 36.321 and TS 36.213
% Resources are allocated for a Resource Reselection Period (SPS)
% Sensing is performed in the last 1 second
% Map of the received power and selection of the best 20% transmission hypothesis
% Random selection of one of the M best candidates
% The selection is rescheduled after a random period, with random
% probability controlled by the input parameter 'probResKeep'

% Starting from version 5.6.1 also 5G-Mode2 is supported

% Number of TTIs per beacon period
NbeaconsT = appParams.NbeaconsT;
% Number of possible beacon resources in one TTI
NbeaconsF = appParams.NbeaconsF;
% Number of beacons per beacon period
Nbeacons = NbeaconsT*NbeaconsF;

% Calculate current T within the NbeaconsT
currentT = mod(timeManagement.elapsedTime_TTIs-1,NbeaconsT)+1; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FIRST PART is checking the stations that need reselection

% LTE vehicles that are active
activeIDsCV2X = stationManagement.activeIDsCV2X;

% 1: check if a reselection is commanded by the PHY layer - i.e., in the case 
% the resource is not available in the interval T1-T2
% 2: check if (a) the reselection counter goes to zero and (b) reselection is
% commanded depending on p_keep

%if timeManagement.timeNow>7.00292
%    STOPHERE = 0;
%end

%% 1 - check reallocation commanded due to non available resource
%% Until version 5.4.16
% identify those vehicles having a new packet and no scheduled resource in
% the next T1-T2 interval
% subframeNextResource = ceil(stationManagement.BRid(:,1)/appParams.NbeaconsF);
% subframesToNextAlloc = (subframeNextResource>currentT).*(subframeNextResource-currentT)+(subframeNextResource<=currentT).*(subframeNextResource+appParams.NbeaconsT-currentT);
% scheduledID_PHY = activeIDsCV2X(timeManagement.timeLastPacket(activeIDsCV2X) > timeManagement.timeNow-phyParams.Tsf-1e-8 & (subframesToNextAlloc(activeIDsCV2X) < simParams.subframeT1Mode4 | subframesToNextAlloc(activeIDsCV2X)>simParams.subframeT2Mode4));
% scheduledID_PHY(timeManagement.timeLastPacket(scheduledID_PHY)<0) = [];
%% From version 5.4.16
% identify those vehicles having a new packet at its first attempt and no scheduled resource in
% the next T1-T2 interval
% %% Focusing only on first transmission (not replicas)
% subframeNextResource = zeros(length(stationManagement.BRid(:,1)),phyParams.cv2xNumberOfReplicasMax);
% for j=1:phyParams.cv2xNumberOfReplicasMax
%     subframeNextResource(:,j) = ceil(stationManagement.BRid(:,j)/appParams.NbeaconsF);
% end
% subframesToNextAlloc = (subframeNextResource(:,1)>currentT).*(subframeNextResource(:,1)-currentT)+(subframeNextResource(:,1)<=currentT).*(subframeNextResource(:,1)+appParams.NbeaconsT-currentT);
% scheduledID_PHY = activeIDsCV2X(timeManagement.timeLastPacket(activeIDsCV2X) > timeManagement.timeNow-phyParams.Tsf-1e-8 ...
%     & (subframesToNextAlloc(activeIDsCV2X,1) < simParams.subframeT1Mode4 | subframesToNextAlloc(activeIDsCV2X,1)>simParams.subframeT2Mode4));
% 
% scheduledID_PHY(timeManagement.timeLastPacket(scheduledID_PHY)<0) = [];
% scheduledID_PHY(stationManagement.pckNextAttempt(scheduledID_PHY) > 1) = [];
%% Focusing on all transmissions (including replicas)
subframeNextResource = ceil(stationManagement.BRid/appParams.NbeaconsF);
subframesToNextAlloc = zeros(length(stationManagement.BRid(:,1)),phyParams.cv2xNumberOfReplicasMax);
allConditionsMet = false(length(activeIDsCV2X),phyParams.cv2xNumberOfReplicasMax); 
for j=1:phyParams.cv2xNumberOfReplicasMax    
    subframesToNextAlloc(:,j) = (subframeNextResource(:,j)>currentT).*(subframeNextResource(:,j)-currentT)+(subframeNextResource(:,j)<=currentT).*(subframeNextResource(:,j)+appParams.NbeaconsT-currentT);
    % A means this replica ('j') is allowed by 'cv2xNumberOfReplicas'
    A = stationManagement.cv2xNumberOfReplicas(activeIDsCV2X) >= j;
    % B means that there is a resource allocated
    B = stationManagement.BRid(activeIDsCV2X,j)>0;
    % C means that the resource is ouside T1,T2
    C = (subframesToNextAlloc(activeIDsCV2X,j) < simParams.T1autonomousModeTTIs | subframesToNextAlloc(activeIDsCV2X,j)>simParams.T2autonomousModeTTIs);
    % D means that resource of replica j comes after that of replica j-1
    % (not allowed and reselection commanded)
    if j>1
        D = subframesToNextAlloc(activeIDsCV2X,j) < subframesToNextAlloc(activeIDsCV2X,j-1);
    else
        D = false;
    end
    allConditionsMet(:,j) = A & B & (C | D) ;
    %scheduledID_PHYmatrix(:,j) = activeIDsCV2X(timeManagement.timeLastPacket(activeIDsCV2X) > timeManagement.timeNow-phyParams.Tsf-1e-8 ...
    %    & stationManagement.cv2xNumberOfReplicas(activeIDsCV2X) >= j ...
    %    & stationManagement.BRid(activeIDsCV2X,j)~=-1 ...
    %    & (subframesToNextAlloc(activeIDsCV2X,j) < simParams.subframeT1Mode4 | subframesToNextAlloc(activeIDsCV2X,j)>simParams.subframeT2Mode4));
end
% A means one packet was generated in this slot
hasNewPacketThisTbeacon = (timeManagement.timeLastPacket(activeIDsCV2X) > (timeManagement.timeNow-phyParams.TTI-1e-8));

% The operand 'any' implies that if any replica is outside T1, T2, then a
% reallocation is performed
scheduledID_PHY = activeIDsCV2X(hasNewPacketThisTbeacon & any(allConditionsMet,2));
scheduledID_PHY(timeManagement.timeLastPacket(scheduledID_PHY)<0) = [];

% Following line for debug purposes - allows to remove PHY commanded reallocations
%scheduledID_PHY = [];

%% 2a - reselection counter to 0
% Evaluates which vehicles have the counter reaching zero

%% Until version 5.4.16
% LTE vehicles that have a resource allocated in this subframe
%haveResourceThisTbeacon(activeIDsCV2X) = subframeNextResource(activeIDsCV2X)==currentT;
%% From version 5.4.16
% % LTE vehicles that have the resource allocated for the last replica in this subframe
% haveResourceOfLastReplicaThisTbeacon = false(length(stationManagement.BRid(:,1)),1);
% for j=1:length(activeIDsCV2X)
%     if subframeNextResource(activeIDsCV2X(j),stationManagement.cv2xNumberOfReplicas(activeIDsCV2X(j))) == currentT
%         haveResourceOfLastReplicaThisTbeacon(activeIDsCV2X(j)) = true;
%     end
% end
%% Modified into
hasFirstResourceThisTbeacon = (subframeNextResource(activeIDsCV2X,1)==currentT);
% Update of next allocation for the vehicles that have a resource allocated in this slot

% timeManagement.timeOfResourceAllocationLTE is for possible future use
%timeManagement.timeOfResourceAllocationLTE(haveResourceThisTbeacon>0) = timeManagement.timeOfResourceAllocationLTE(haveResourceThisTbeacon>0) + appParams.averageTbeacon;

% Update resReselectionCounter
% Reduce the counter by one to all those that have a packet generated in this slot
%stationManagement.resReselectionCounterCV2X(activeIDsCV2X) = stationManagement.resReselectionCounterCV2X(activeIDsCV2X)-haveResourceOfLastReplicaThisTbeacon(activeIDsCV2X);
stationManagement.resReselectionCounterCV2X(activeIDsCV2X) = stationManagement.resReselectionCounterCV2X(activeIDsCV2X)-hasFirstResourceThisTbeacon;

%% 2b - p_keep check
% Among them, those that have reached RC=1 need to evaluate if they will
% perform the reselection. In case they don't need to select a new resource, they update the RC before
% it reaches 0. In case UEs need to perform reselection, the reselection is
% done at the next packet arrival and the last transmission before the change don't reserve
% any resource (transmission with RRI=0)

% Calculate IDs of vehicles which perform reselection
%scheduledID_MAC = find ( timeManagement.timeLastPacket );

% Detects the UEs that have transmitted in this slot whose RC has reached 1
keepCheck_MAC = activeIDsCV2X( hasFirstResourceThisTbeacon ...
    & (stationManagement.resReselectionCounterCV2X(activeIDsCV2X)==1));

updateCounter_MAC =[];
if simParams.probResKeep>0
    keepRand = rand(1,length(keepCheck_MAC));
    % Update the vehicles which don't perform reselection and update the RC
    updateCounter_MAC = keepCheck_MAC(keepRand < simParams.probResKeep);
end
% Update the RC for those UEs that do not perform reselection due to pkeep
stationManagement.resReselectionCounterCV2X(updateCounter_MAC) = stationManagement.resReselectionCounterCV2X(updateCounter_MAC) + (simParams.minRandValueMode4-1) + randi((simParams.maxRandValueMode4-simParams.minRandValueMode4)+1,1,length(updateCounter_MAC))';
% stationManagement.resReselectionCounterCV2X(updateCounter_MAC) = (simParams.minRandValueMode4-1) + randi((simParams.maxRandValueMode4-simParams.minRandValueMode4)+1,1,length(updateCounter_MAC));


% Sensed power by transmitting nodes in their BR
if phyParams.Ksi < Inf && phyParams.testSelfIRemove < Inf
    [stationManagement] = FDaidedReselection(stationManagement,phyParams);
end

% Detects the UEs that need to perform reselection
% The reselection is triggered when RC=0 and the UE has a packet to transmit
scheduledID_MAC = activeIDsCV2X( hasNewPacketThisTbeacon ...
    & (stationManagement.resReselectionCounterCV2X(activeIDsCV2X)<=0));


%if ~isempty(scheduledID_MAC)
%    STOPHERE=0;
%end

% FOR DEBUG
% fid = fopen('temp.xls','a');
% for i=1:length(resReselectionCounter)
%     fprintf(fid,'%d\t',resReselectionCounter(i));
% end
% fprintf(fid,'\n');
% fclose(fid);

%% For the nodes with the counter reaching zero or with enforced reselection restart the reselection counter
% Calculate new resReselectionCounter for scheduledID
needReselectionCounterRestart = union(scheduledID_PHY,scheduledID_MAC);
stationManagement.resReselectionCounterCV2X(needReselectionCounterRestart) = (simParams.minRandValueMode4-1) + randi((simParams.maxRandValueMode4-simParams.minRandValueMode4)+1,1,length(needReselectionCounterRestart));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SECOND PART is performing the reselection
% Merge the scheduled IDs
scheduledID = union(scheduledID_PHY,scheduledID_MAC);
Nscheduled = length(scheduledID);

% Reset number of successfully reassigned vehicles
Nreassign = 0;

for indexSensingV = 1:Nscheduled

    %if scheduledID(indexSensingV)==87
    %    STOPHERE = 0;
    %end

    if appParams.resourceSelection5G == 0% 4G procedure
        % Select the sensing matrix only for those vehicles that perform reallocation
        % and calculate the average of the measured power over the sensing window
        sensingMatrixScheduled = sum(stationManagement.sensingMatrixCV2X(:,:,scheduledID(indexSensingV)),1)/length(stationManagement.sensingMatrixCV2X(:,1,1));
        % "sensingMatrixScheduled" is a '1 x NbeaconIntervals' vector
    elseif appParams.resourceSelection5G == 1
        % Select the sensing matrix only for those vehicles that perform reallocation
        % Selects only the first row, which includes the slots relative to
        % the last 'averageTbeacon'
        % In 5G the average process is removed and the senging is
        % performed only on the basis of the decoded SCIs.
        
        sensingMatrixScheduled = stationManagement.sensingMatrixCV2X(1,:,scheduledID(indexSensingV));
        
    end

    % With intrafrequency coexistence, any coexistence method
    % (simParams.coexMethod==1,2,3,6) might forbid LTE using some subframes
    if simParams.technology==4 && simParams.coexMethod~=0
        %if simParams.coexMethod==1 || simParams.coexMethod==2 || simParams.coexMethod==3 || simParams.coexMethod==6
        %MBest = ceil(Nbeacons * (sinrManagement.coex_NtsLTE(activeIDsCV2X(indexSensingV))/simParams.coex_superframeSF) * simParams.ratioSelectedMode4);
        for block = 1:ceil(NbeaconsT/simParams.coex_superframeSF)
            sensingMatrixScheduled(...
                (block-1)*simParams.coex_superframeSF*NbeaconsF + ...
                ((((sinrManagement.coex_NtsLTE(activeIDsCV2X(indexSensingV)))*NbeaconsF)+1):(simParams.coex_superframeSF*NbeaconsF))...
                ) = inf;
        end            
    end

    % Check T1 and T2 and in case set the subframes that are not acceptable to
    % Since the currentT can be at any point of beacon resource matrix,
    % the calculations depend on where T1 and T2 are placed
    % Note: phyParams.TsfGap is needed in the calculation because this
    % function is performed before the gap and not at the end of the
    % subframe
    timeStartingT = timeManagement.timeLastPacket(scheduledID(indexSensingV));
    startingT = mod(floor((timeStartingT+phyParams.TsfGap+1e-7)/phyParams.TTI),NbeaconsT)+1; 
    % IF Both T1 and T2 are within this beacon period
    if (startingT+simParams.T2autonomousModeTTIs+1)<=NbeaconsT
        sensingMatrixScheduled([1:((startingT+simParams.T1autonomousModeTTIs-1)*NbeaconsF),((startingT+simParams.T2autonomousModeTTIs)*NbeaconsF+1):Nbeacons]) = inf;
    % IF Both are beyond this beacon period
    elseif (startingT+simParams.T1autonomousModeTTIs-1)>NbeaconsT
        sensingMatrixScheduled([1:((startingT+simParams.T1autonomousModeTTIs-1-NbeaconsT)*NbeaconsF),((startingT+simParams.T2autonomousModeTTIs-NbeaconsT)*NbeaconsF+1):Nbeacons]) = inf;
    % IF T1 within, T2 beyond
    else
        sensingMatrixScheduled(((startingT+simParams.T2autonomousModeTTIs-NbeaconsT)*NbeaconsF+1):((startingT+simParams.T1autonomousModeTTIs-1)*NbeaconsF)) = inf;
    end 

%     figure(1)
%     hold off
%     bar(isinf(sensingMatrixScheduled))
%     hold on

    % The best 20% (parameter that can be changed) is selected inside the pool as in TS 36.213
    % The pool of available resources is obtained as those that are not set
    % to infty
    nPossibleAllocations = sum(isfinite(sensingMatrixScheduled));
    MBest = ceil(nPossibleAllocations * simParams.ratioSelectedMode4);
    if MBest<=0
        error('Mbest must be a positive scalar (it is %d)',MBest);
    end

    % The knownUsedMatrix of the scheduled users is obtained
    knownUsedMatrixScheduled = stationManagement.knownUsedMatrixCV2X(:,scheduledID(indexSensingV))';

    % Create random permutation of the column indexes of sensingMatrix in
    % order to avoid the ascending order on the indexes of cells with the
    % same value (sort effect) -> minimize the probability of choosing the same
    % resource
    rpMatrix = randperm(Nbeacons);

    % Build matrix made of random permutations of the column indexes
    % Permute sensing matrix
    sensingMatrixPerm = sensingMatrixScheduled(rpMatrix);
    knownUsedMatrixPerm = knownUsedMatrixScheduled(rpMatrix);

    % Now perform sorting and relocation taking into account the threshold on RSRP
    % Please note that the sensed power is on a per MHz resource basis,
    % whereas simParams.powerThresholdAutonomous is on a resource element (15 kHz) basis, 
    % The cycle is stopped internally; a max of 100 is used to avoid
    % infinite loops in case of bugs
    powerThreshold = simParams.powerThresholdAutonomous;
    while powerThreshold < 100
        % If the number of acceptable BRs is lower than MBest,
        % powerThreshold is increased by 3 dB
        usableBRs = ((sensingMatrixPerm*0.015)<powerThreshold) | ((sensingMatrixPerm<inf) & (knownUsedMatrixPerm<1));

        if sum(usableBRs) < MBest
            powerThreshold = powerThreshold * 2;
        else
            break;
        end
    end            
    
    % To mark unacceptable RB as occupied, their power is set to Inf
    sensingMatrixPerm = sensingMatrixPerm + (1-usableBRs) * max(phyParams.P_ERP_MHz_CV2X);
    
    % Sort sensingMatrix in ascending order
    [~, bestBRPerm] = sort(sensingMatrixPerm);

    % Reorder bestBRid matrix
    bestBR = rpMatrix(bestBRPerm);
    
    % 5G procedure mode2 which admits all resources that are not HD or
    % reserved with an RSRP level above threshold
    % L2 is removed in mode2
    if appParams.resourceSelection5G == 1 
        % Find number of remaining resources
        %
        %testMBest_5G is left to test the possibility to reintroduce L2 
        % if testMBest_5G is removed, set MBest to sum(usableBRs)
        MBest = ceil(nPossibleAllocations * simParams.testMBest_5G);
        MBest=min(MBest,sum(usableBRs));
    end
    
    % Keep the best M canditates
    bestBR = bestBR(1:MBest);

    % Reassign, selecting a random BR among the bestBR
    BRindex = randi(MBest);
    BR = bestBR(BRindex);
    printDebugReallocation(timeManagement.timeNow,scheduledID(indexSensingV),positionManagement.XvehicleReal(stationManagement.activeIDs==scheduledID(indexSensingV)),'reall',BR,outParams);

    stationManagement.BRid(scheduledID(indexSensingV),1)=BR;
    Nreassign = Nreassign + 1;
    

    %% From v 5.4.16
    % Executes HARQ allocation if enabled
    if phyParams.cv2xNumberOfReplicasMax>1
        % Check on max number of retransmissions supported
        if phyParams.cv2xNumberOfReplicasMax>2
            error('HARQ with more than 1 retransmission not implemented');
        end
        % INPUT:
        % currentT is the current subframe in resource grid
        % bestBR is the set of best resources passed to MAC
        % BR is the resource selected for the first transmission
        % THEN: add Nbeacons to all resources before current
% plot(bestBR,'.b')  
% hold on
% ylim([0 300]);
% plot([0 length(bestBR)],[BR BR], '-b');
% plot([0 length(bestBR)],[BR+15*NbeaconsF BR+15*NbeaconsF], ':k');
% plot([0 length(bestBR)],[BR-15*NbeaconsF BR-15*NbeaconsF], ':k');
% plot([0 length(bestBR)],[(currentT-1)*NbeaconsF+1 (currentT-1)*NbeaconsF+1], '--r');
% plot([0 length(bestBR)],[(currentT-1)*NbeaconsF+3 (currentT-1)*NbeaconsF+3], '--r');
        bestSubframe = ceil(bestBR/NbeaconsF);
        bestSubframe(bestSubframe<=currentT) = bestSubframe(bestSubframe<=currentT) + NbeaconsT;
        % identify subframe of BR
        subframe_BR = ceil(BR/NbeaconsF);
        subframe_BR(subframe_BR<=currentT) = subframe_BR + NbeaconsT;
        % remove resources in subframe_x
        bestBR(bestSubframe==subframe_BR) = -1;
% plot(bestBR,'*b')  
        % remove resources before Now+T1
        bestBR(bestSubframe<currentT+simParams.T1autonomousModeTTIs) = -1;
% plot(bestBR,'*r')  
        if appParams.resourceSelection5G == 0
            % remove resources before x-15
            bestBR(bestSubframe<subframe_BR-15) = -1;
        elseif appParams.resourceSelection5G == 1
            % remove resources before x-31
            bestBR(bestSubframe<subframe_BR-31) = -1;
        end
% plot(bestBR,'pb')  
        % remove resources after Now+T2
        bestBR(bestSubframe>currentT+simParams.T2autonomousModeTTIs) = -1;
% plot(bestBR,'pr')  
        if appParams.resourceSelection5G == 0
            % remove resources after x+15
            bestBR(bestSubframe>subframe_BR+15) = -1;
        elseif appParams.resourceSelection5G == 1
            % remove resources after x+31
            bestBR(bestSubframe>subframe_BR+31) = -1;
        end
% plot(bestBR,'pk') 

        bestBR(bestBR==-1) = [];

        if length(bestBR)>1
            % Reassign, selecting a random BR among the remaining bestBR
            BRindex2 = randi(length(bestBR));
            BR2 = bestBR(BRindex2);  
            % In case, BR and BR2 might need to be switched
            subframe_BR2 = ceil(BR2/NbeaconsF);
            subframe_BR2(subframe_BR2<=currentT) = subframe_BR2 + NbeaconsT;
            if subframe_BR2 < subframe_BR
                stationManagement.BRid(scheduledID(indexSensingV),1) = BR2;
                BR2 = BR;
            end           
        else
            BR2 = -1;
        end
            
        stationManagement.BRid(scheduledID(indexSensingV),2) = BR2;
    end

    %if scheduledID(indexSensingV)==39
    %    fp = fopen('Temp.txt','a');
    %    fprintf(fp,'T=%f: reselection, BR1=%d + BR2=%d\n',timeManagement.timeNow,BR,BR2);
    %    fclose(fp);
    %end
    
    printDebugBRofMode4(timeManagement,scheduledID(indexSensingV),BR,outParams);
end



end

