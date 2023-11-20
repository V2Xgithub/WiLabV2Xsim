function [BRid, Nreassign] = BRreassignmentRandom(T1,T2,IDvehicle,simParams,timeManagement,sinrManagement,stationManagement,phyParams,appParams)
% Benchmark Algorithm 101 (RANDOM ALLOCATION)

% T1 and T2 set the time budget
if T1==-1
    T1=1;
end
if T2==-1
    T2=appParams.NbeaconsT;
end
% Was simParams.T1autonomousModeTTIs, simParams.T2autonomousModeTTIs

Nvehicles = length(IDvehicle(:,1));   % Number of vehicles      

% This part considers various limitations
BRid = zeros(length(IDvehicle(:,1)),1);
% A cycle over the vehicles is needed
for idV=1:Nvehicles
    if stationManagement.vehicleState(IDvehicle(idV))~=constants.V_STATE_LTE_TXRX
        continue;
    end
    while BRid(idV)==0
        % A random BR is selected
        BRid(idV) = randi(appParams.Nbeacons,1,1);
        % If it is not acceptable, it is reset to zero and a new random
        % value is obtained
        
        % Case coexistence with mitigation methods - limited by
        % superframe - i.e., if in ITS-G5 slot must be changed
        if simParams.technology==constants.TECH_COEX_STD_INTERF && simParams.coexMethod~=constants.COEX_METHOD_NON
            % expressions for dynamic and static are same, because
            % sinrManagement.coex_NtotTTILTE was already set based on the
            % dynamic or static at "mainInitCoexistence.m"
            if mod(BRid(idV)-1,simParams.coex_superframeTTI*appParams.NbeaconsF)+1 > (sinrManagement.coex_NtotTTILTE(1)*appParams.NbeaconsF)
                BRid(idV) = 0;
            end
        end        
        
        % If it is outside the interval given by T1 and T2 it is not acceptable
        if T1>1 || T2<appParams.NbeaconsT
            TTILastPacket = mod(ceil(timeManagement.timeLastPacket(IDvehicle(idV))/phyParams.TTI)-1,(appParams.NbeaconsT))+1;
            Tselected = ceil(BRid(idV)/appParams.NbeaconsF); 
            % IF Both T1 and T2 are within this beacon period
            if (TTILastPacket+T2+1)<=appParams.NbeaconsT
                if Tselected<TTILastPacket+T1 || Tselected>TTILastPacket+T2
                   BRid(idV) = 0;
                end
            % IF Both are beyond this beacon period
            elseif (TTILastPacket+T1-1)>appParams.NbeaconsT
                if Tselected<TTILastPacket+T1-appParams.NbeaconsT || Tselected>TTILastPacket+T2-appParams.NbeaconsT
                   BRid(idV) = 0;
                end
            % IF T1 within, T2 beyond
            else
                if Tselected<TTILastPacket+T1 && Tselected>TTILastPacket+T2-appParams.NbeaconsT
                   BRid(idV) = 0;
                end
            end 
        end
    end
end

Nreassign = Nvehicles;

end