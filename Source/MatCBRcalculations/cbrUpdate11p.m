function [timeManagement,stationManagement,CBRvalue] = cbrUpdate11p(timeManagement,vehiclesToConsider,stationManagement,simParams,phyParams,outParams)

CBRvalue = zeros(length(vehiclesToConsider),1);

for i = 1:length(vehiclesToConsider)
    
    idCBR = vehiclesToConsider(i);
    cbrNull = false;
    
    if timeManagement.cbr11p_timeStartMeasInterval(idCBR) < 0
        error('Should not enter here. To check');
    end

    % Update last CBR
    if timeManagement.cbr11p_timeStartBusy(idCBR)~=-1
        stationManagement.channelSensedBusyMatrix11p(1,idCBR) = stationManagement.channelSensedBusyMatrix11p(1,idCBR) + (timeManagement.timeNow-timeManagement.cbr11p_timeStartBusy(idCBR));
        timeManagement.cbr11p_timeStartBusy(idCBR) = timeManagement.timeNow;
    end               
    
    % Calculate the new CBR
    stationManagement.channelSensedBusyMatrix11p(1,idCBR) = stationManagement.channelSensedBusyMatrix11p(1,idCBR)/(timeManagement.timeNow-timeManagement.cbr11p_timeStartMeasInterval(idCBR));
    timeManagement.cbr11p_timeStartMeasInterval(idCBR) = timeManagement.timeNow;
    % Average out
    nnzSBM = nnz(stationManagement.channelSensedBusyMatrix11p(:,idCBR));
    if nnzSBM>0
        CBRvalue(i) = sum(stationManagement.channelSensedBusyMatrix11p(:,idCBR))/(nnzSBM);
    end
    
    if simParams.technology==4 && simParams.coexMethod==1 && ~simParams.coexA_withLegacyITSG5
        % 1. In Method A, a portion of the superframe (including guardTimeBefore
        % and guardTimeAfter) is reserved to LTE Should be removed - considering
        % that the LTE slot is sensed as idle (new method, CBR start timing only
        % if the preamble is detected and the SINR larger than the threshold) 
        % 2. If timeManagement.timeNow < simParams.cbrSensingInterval, due to
        % the edge effect, revised CBRvalue could be negative. And the
        % CBRvalue calculated within simParams.cbrSensingInterval should be
        % discarded
         if timeManagement.timeNow >= simParams.cbrSensingInterval && mod(simParams.cbrSensingInterval/simParams.coex_superFlength, 1) == 0
             portionOfLTE = (simParams.coex_knownEndOfLTE(idCBR) + simParams.coex_guardTimeBefore +...
                 simParams.coex_guardTimeAfter)/...
                 simParams.coex_superFlength;
             CBRvalue(i) = CBRvalue(i) / (1-portionOfLTE);
         elseif timeManagement.timeNow >= simParams.cbrSensingInterval && mod(simParams.coex_superFlength/simParams.cbrSensingInterval, 1) == 0
             % If this is the end of an interval within the LTE slot I must
             % set -1
             % one microsecond of margin is used to cope with floating
             % points
             instantCheck = mod(timeManagement.timeNow,simParams.coex_superFlength);
             if instantCheck>1e-6 && instantCheck<simParams.coex_knownEndOfLTE(idCBR)+1e-6
                 CBRvalue(i) = -1;
                 cbrNull = true;
             end
         end
    end
    
    % Managing issues with rounding of doubles
    % Granularity set to 1/1e4
    CBRvalue(i) = round( CBRvalue(i), 4);
    
    if (CBRvalue(i)<0 || CBRvalue(i)>1) && ~cbrNull
        % In the first superframe with desynch error, it might happen that
        % the CBR value is <0; in such case it is set to 0 and the error
        % is skipped
        if CBRvalue(i)<0 && simParams.technology==4 && simParams.coexMethod==1 && ...
                timeManagement.timeNow < simParams.coex_superFlength && ...
                simParams.coexA_desynchError > 0
            CBRvalue(i) = 0;
        else
            error('CBRvalue(i) = %f !!!',CBRvalue(i));
        end
    end
    
    %% retransmission impact by CBR
    if phyParams.retransType == constants.RETRANS_DETERMINISTIC
        % with fixed threshold
        if CBRvalue(i) <= phyParams.ITSReplicasThreshold1
            stationManagement.ITSNumberOfReplicas(idCBR) = 4;
        elseif CBRvalue(i) <= phyParams.ITSReplicasThreshold2
            stationManagement.ITSNumberOfReplicas(idCBR) = 3;
        elseif CBRvalue(i) <= phyParams.ITSReplicasThreshold3
            stationManagement.ITSNumberOfReplicas(idCBR) = 2;
        else
            stationManagement.ITSNumberOfReplicas(idCBR) = 1;
        end
    elseif phyParams.retransType == constants.RETRANS_PROBABILISTIC
        % with probability
        new_thre1 = 0.5*(phyParams.ITSReplicasThreshold1-phyParams.ITSReplicasThreshold2)+phyParams.ITSReplicasThreshold1;
        new_thre2 = -0.5*(phyParams.ITSReplicasThreshold1-phyParams.ITSReplicasThreshold2)+phyParams.ITSReplicasThreshold1;
        new_thre3 = -0.5*(phyParams.ITSReplicasThreshold2-phyParams.ITSReplicasThreshold3)+phyParams.ITSReplicasThreshold2;
        new_thre4 = -1.5*(phyParams.ITSReplicasThreshold2-phyParams.ITSReplicasThreshold3)+phyParams.ITSReplicasThreshold2;
        if CBRvalue(i) <= new_thre1
            stationManagement.ITSNumberOfReplicas(idCBR) = 4;
        elseif CBRvalue(i) <= new_thre2
            p4 = (CBRvalue(i)-new_thre1)/(new_thre1-new_thre2)+1;
            if rand < p4
                stationManagement.ITSNumberOfReplicas(idCBR) = 4;
            else
                stationManagement.ITSNumberOfReplicas(idCBR) = 3;
            end
        elseif CBRvalue(i) <= phyParams.ITSReplicasThreshold2
            p3 = 0.5*(CBRvalue(i)-new_thre2)/(new_thre2-phyParams.ITSReplicasThreshold2)+1;
            if rand < p3
                stationManagement.ITSNumberOfReplicas(idCBR) = 3;
            else
                stationManagement.ITSNumberOfReplicas(idCBR) = 2;
            end
        elseif CBRvalue(i) <= new_thre3
            p3 = 0.5*(CBRvalue(i)-phyParams.ITSReplicasThreshold2)/(phyParams.ITSReplicasThreshold2-new_thre3)+0.5;
            if rand < p3
                stationManagement.ITSNumberOfReplicas(idCBR) = 3;
            else
                stationManagement.ITSNumberOfReplicas(idCBR) = 2;
            end
        elseif CBRvalue(i) <= new_thre4
            p2 = (CBRvalue(i)-new_thre3)/(new_thre3-new_thre4)+1;
            if rand < p2
                stationManagement.ITSNumberOfReplicas(idCBR) = 2;
            else
                stationManagement.ITSNumberOfReplicas(idCBR) = 1;
            end
        else
            stationManagement.ITSNumberOfReplicas(idCBR) = 1;
        end
    end

    % Shift of the matrix
    stationManagement.channelSensedBusyMatrix11p(:,idCBR) = circshift(stationManagement.channelSensedBusyMatrix11p(:,idCBR),1);
    stationManagement.channelSensedBusyMatrix11p(1,idCBR) = 0;
end

if simParams.dcc_active && timeManagement.timeNow >= simParams.cbrSensingInterval
    % Toff = Ton x ( 4000 x (CBR-0.62)/CBR - 1)
    % Tinterval = Toff + Ton = ...
    index = CBRvalue > 0.62;
    timeManagement.dcc_minInterval(vehiclesToConsider(index)) = min(1,phyParams.tPck11p * 1e3 * 4 .* (CBRvalue(index)-0.62)./CBRvalue(index));

    % move dcc trigger to mainV2X.m, because the random part of generation
    % interval would change value if they appear at different places
end
