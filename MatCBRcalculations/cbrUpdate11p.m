function [timeManagement,stationManagement,CBRvalue] = cbrUpdate11p(timeManagement,vehiclesToConsider,stationManagement,simParams,phyParams)

CBRvalue = zeros(length(vehiclesToConsider),1);

for i = 1:length(vehiclesToConsider)
    
    idCBR = vehiclesToConsider(i);
    cbrNull = false;
    
    if timeManagement.cbr11p_timeStartMeasInterval(idCBR) < 0
        error('Should not enter here. To check');
        timeManagement.cbr11p_timeStartMeasInterval(idCBR) = timeManagement.timeNow;
        if timeManagement.cbr11p_timeStartBusy(idCBR)~=-1
            timeManagement.cbr11p_timeStartBusy(idCBR) = timeManagement.timeNow;
        end
        continue
        % return
    end

    % Update last CBR
    if timeManagement.cbr11p_timeStartBusy(idCBR)~=-1
        stationManagement.channelSensedBusyMatrix11p(1,idCBR) = stationManagement.channelSensedBusyMatrix11p(1,idCBR) + (timeManagement.timeNow-timeManagement.cbr11p_timeStartBusy(idCBR));
        
        if sum(  ((timeManagement.timeNow-timeManagement.cbr11p_timeStartBusy(idCBR)))<0 ) >0
            error('error here');
        end
        
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
        % In Method A, a portion of the superframe is reserved to LTE
        % Should be removed - considering that the LTE slot is sensed as
        % busy - 
         if mod(simParams.cbrSensingInterval/simParams.coex_superFlength, 1) == 0
             portionOfLTE = simParams.coex_knownEndOfLTE(idCBR)/simParams.coex_superFlength;
             CBRvalue(i) = (CBRvalue(i) - portionOfLTE) / (1-portionOfLTE);
         elseif mod(simParams.coex_superFlength/simParams.cbrSensingInterval, 1) == 0
             % If this is the end of an interval within the LTE slot I must
             % set -1
             % one microsecond of margin is used to cope with floating
             % points
             instantCheck = mod(timeManagement.timeNow,simParams.coex_superFlength);
             if instantCheck>1e-6 && instantCheck<simParams.coex_knownEndOfLTE(idCBR)+1e-6
                 CBRvalue(i) = -1;
                 cbrNull = true;
             end
         else
             error('This error was already checked in the init...');
         end
    end
    
    % Managing issues with rounding of doubles
    % Granularity set to 1/1e4
    CBRvalue(i) = round( CBRvalue(i)*1e4 )/1e4;
    
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
    
    %% REMOVED since version 5.2.9
%     %print - only if print is active - only 11p
%     if outParams.printCBR && timeManagement.timeNow>simParams.cbrSensingInterval && stationManagement.vehicleState(idCBR)~=100    
%         printCBRToFile(CBRvalue(i),outParams,false);
%     end
    %%

    % Shift of the matrix
    stationManagement.channelSensedBusyMatrix11p(:,idCBR) = circshift(stationManagement.channelSensedBusyMatrix11p(:,idCBR),1);
    stationManagement.channelSensedBusyMatrix11p(1,idCBR) = 0;
end

if simParams.dcc_active
    % Toff = Ton x ( 4000 x (CBR-0.62)/CBR - 1)
    % Tinterval = Toff + Ton = ...
    timeManagement.dcc_minInterval(vehiclesToConsider) = min(1,phyParams.tPck11p * 1e3 * 4 * (CBRvalue-0.62)./(CBRvalue));
    if timeManagement.dcc_minInterval(vehiclesToConsider)>timeManagement.generationIntervalDeterministicPart(vehiclesToConsider)
        stationManagement.dcc11pTriggered(stationManagement.vehicleChannel(vehiclesToConsider)) = true;
    end
end

