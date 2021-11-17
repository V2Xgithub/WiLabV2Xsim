function [resultingList,stationManagement,sinrManagement] = elaborateFateRxCV2X(timeManagement,IDvehicleTXLTE,indexVehicleTX,neighborsID,sinrManagement,stationManagement,positionManagement,appParams,phyParams)
% Detect correctly decoded beacons and create the list of correct
% transmissions
% [ID TX, ID RX, BRid, distance]

distance = positionManagement.distanceReal(stationManagement.vehicleState(stationManagement.activeIDs)==100,stationManagement.vehicleState(stationManagement.activeIDs)==100);

Ntx = length(IDvehicleTXLTE);              % Number of tx vehicles
%resultingList = zeros(Ntx*length(neighborsID(1,:)),5);        % Initialize error matrix
resultingList = zeros(0,5);        % Initialize error matrix
indexRaw = 0;                              % Initialize number of errors

if phyParams.Ksic<1
    [sinrManagement] = successiveInterferenceCancellationicCV2X(stationManagement,sinrManagement,appParams,phyParams);
end

for i = 1:Ntx

    %if IDvehicleTXLTE(i)==39
    %    fp = fopen('Temp.txt','a');
    %    fprintf(fp,'T=%f: new tx, attemmpt %d\n',timeManagement.timeNow,stationManagement.pckTxOccurring(IDvehicleTXLTE(i)));
    %    fclose(fp);
    %end
    
    % Find indexes of receiving vehicles in neighborsID
    indexNeighborsRX = find(neighborsID(indexVehicleTX(i),:));
    
    resultingList(indexRaw+1:indexRaw+length(indexNeighborsRX),5)=0;
    
    for j = 1:length(indexNeighborsRX)
        
        IDvehicleRX = neighborsID(indexVehicleTX(i),indexNeighborsRX(j));
        
        % If this packet was already received it can be skipped
        if stationManagement.pckReceived(IDvehicleRX,IDvehicleTXLTE(i))>0
            continue;
        end

        % Update of cumulativeSINR, to account for possible Maximal Ratio
        % Combining
        sinrManagement.cumulativeSINR(IDvehicleRX,IDvehicleTXLTE(i)) = sinrManagement.cumulativeSINR(IDvehicleRX,IDvehicleTXLTE(i)) + ...
            sinrManagement.neighborsSINRaverageCV2X(i,indexNeighborsRX(j));

        % If received beacon SINR is lower than the threshold
        %if sinrManagement.neighborsSINR(i,indexNeighborsRX(j)) < phyParams.gammaMinLTE
        % randomSINRthreshold = sinrV(randi(length(sinrV)))
        sinrThreshold=(phyParams.LOS(i,indexNeighborsRX(j))*phyParams.sinrVectorCV2X_LOS(randi(length(phyParams.sinrVectorCV2X_LOS)))+... %if LOS
            (1-phyParams.LOS(i,indexNeighborsRX(j)))*phyParams.sinrVectorCV2X_NLOS(randi(length(phyParams.sinrVectorCV2X_NLOS))));  %if NLOS
        
        if sinrManagement.cumulativeSINR(IDvehicleRX,IDvehicleTXLTE(i)) >= sinrThreshold
            % CORRECT            
            indexRaw = indexRaw + 1;
            resultingList(indexRaw,1) = IDvehicleTXLTE(i);
            resultingList(indexRaw,2) = IDvehicleRX;
            resultingList(indexRaw,3) = stationManagement.BRid(IDvehicleTXLTE(i),stationManagement.pckTxOccurring(IDvehicleTXLTE(i)));
            resultingList(indexRaw,4) = distance(indexVehicleTX(i),stationManagement.activeIDsCV2X==IDvehicleRX);
            resultingList(indexRaw,5) = 1; % COLUMN 5=1 IS "CORRECT"
            % Mark that this packet has been received
            stationManagement.pckReceived(IDvehicleRX,IDvehicleTXLTE(i))=1;
%                 fid = fopen('temp.xls','a');
%                 fprintf(fid,'%d\t%d\t%.3f\t%f\t%f\t%f\n',IDvehicleRX,IDvehicleTX(i),distance(indexVehicleTX(i),IDvehicle==IDvehicleRX),...
%                     sinrManagement.neighPowerUsefulLastLTE(i,indexNeighborsRX(j)), sinrManagement.neighPowerInterfLastLTE(i,indexNeighborsRX(j)),neighborsSINRaverageCV2X(i,indexNeighborsRX(j)));
%                 fclose(fid);
        elseif stationManagement.pckTxOccurring(IDvehicleTXLTE(i))>=stationManagement.cv2xNumberOfReplicas(IDvehicleTXLTE(i))
            % ERROR IN LAST ATTEMPT
            indexRaw = indexRaw + 1;
            resultingList(indexRaw,1) = IDvehicleTXLTE(i);
            resultingList(indexRaw,2) = IDvehicleRX;
            resultingList(indexRaw,3) = stationManagement.BRid(IDvehicleTXLTE(i),stationManagement.pckTxOccurring(IDvehicleTXLTE(i)));
            resultingList(indexRaw,4) = distance(indexVehicleTX(i),stationManagement.activeIDsCV2X==IDvehicleRX);
            resultingList(indexRaw,5) = 0; % COLUMN 5=1 IS "ERROR"
        elseif ~isinf(phyParams.Ksi) || isempty(find(IDvehicleTXLTE == IDvehicleRX, 1))
            % ERROR IN ATTEMPT (NOT THE LAST ONE) AND THE RECEIVER IS NOT
            % TRANSMITTING
            %if IDvehicleRX==11 && IDvehicleTXLTE(i)==39
            %    fp = fopen('Temp.txt','a');
            %    fprintf(fp,'T=%f: pckReceived incr. (now %d)\n',timeManagement.timeNow,-stationManagement.pckReceived(IDvehicleRX,IDvehicleTXLTE(i))+1);
            %    fclose(fp);
            %end
            % An additional attempt is recorded by decrementing 'stationManagement.pckReceived'
            stationManagement.pckReceived(IDvehicleRX,IDvehicleTXLTE(i)) = stationManagement.pckReceived(IDvehicleRX,IDvehicleTXLTE(i))-1;
            if stationManagement.pckReceived(IDvehicleRX,IDvehicleTXLTE(i))<-(phyParams.cv2xNumberOfReplicasMax-1)
                error('Too many errors in the packet transmission');
            end
        else
            % ERROR IN ATTEMPT (NOT THE LAST ONE) AND THE RECEIVER IS TRANSMITTING
            % No correct reception recorded
            % No wrong reception recorded
            % No attempt recorded
        end
    end
end

delIndex = resultingList(:,1)==0;
%if sum(delIndex)>0
%    error('Error strange here...');
%end
resultingList(delIndex,:) = [];

end
