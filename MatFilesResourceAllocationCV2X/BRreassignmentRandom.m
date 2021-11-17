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
    if stationManagement.vehicleState(IDvehicle(idV))~=100
        continue;
    end
    while BRid(idV)==0
        % A random BR is selected
        BRid(idV) = randi(appParams.Nbeacons,1,1);
        % If it is not acceptable, it is reset to zero and a new random
        % value is obtained
        
        % Case coexistence with mitigation methods - limited by
        % superframe - i.e., if in ITS-G5 slot must be changed
        if simParams.technology==4 && simParams.coexMethod>0
            if ((simParams.coex_slotManagement == 1) ...
                    && mod(BRid(idV)-1,simParams.coex_superframeSF*appParams.NbeaconsF)+1 > (sinrManagement.coex_NtsLTE(1)*appParams.NbeaconsF)) || ...
                ((simParams.coex_slotManagement == 2) ...
                    && mod(BRid(idV)-1,simParams.coex_superframeSF*appParams.NbeaconsF)+1 > (ceil(simParams.coex_superframeSF/2)*appParams.NbeaconsF))
                BRid(idV) = 0;
            end
        end        
        
        % If it is outside the interval given by T1 and T2 it is not acceptable
        if T1>1 || T2<appParams.NbeaconsT
            subframeLastPacket = mod(ceil(timeManagement.timeLastPacket(IDvehicle(idV))/phyParams.TTI)-1,(appParams.NbeaconsT))+1;
            Tselected = ceil(BRid(idV)/appParams.NbeaconsF); 
            % IF Both T1 and T2 are within this beacon period
            if (subframeLastPacket+T2+1)<=appParams.NbeaconsT
                if Tselected<subframeLastPacket+T1 || Tselected>subframeLastPacket+T2
                   BRid(idV) = 0;
                end
            % IF Both are beyond this beacon period
            elseif (subframeLastPacket+T1-1)>appParams.NbeaconsT
                if Tselected<subframeLastPacket+T1-appParams.NbeaconsT || Tselected>subframeLastPacket+T2-appParams.NbeaconsT
                   BRid(idV) = 0;
                end
            % IF T1 within, T2 beyond
            else
                if Tselected<subframeLastPacket+T1 && Tselected>subframeLastPacket+T2-appParams.NbeaconsT
                   BRid(idV) = 0;
                end
            end 
        end
    end
end

Nreassign = Nvehicles;

end