function [dataAgeTimestampMatrix,dataAgeCounter] = countDataAge(stationManagement,iPhyRaw,timeManagement,IDvehicleTX,indexVehicleTX,awarenessID,correctRxList,elapsedTime,dataAgeTimestampMatrix,dataAgeCounter,delayResolution,simValues)
% Function to compute the update delay between received beacons
% Returns the updated updateTimeMatrix, updateDelayMatrix and updateDelayCounter

% Update updateTimeMatrix -> matrix containing the timestamp of the last received beacon
% Row index -> transmitting vehicle's ID
% Column index -> receiving vehicle's ID
Ntx = length(IDvehicleTX);
%all = 1:length(BRid);
all = 1:simValues.maxID;
delayMax = length(dataAgeCounter(1,1,:,1))*delayResolution;

% Find not assigned BRid
%indexNOT = BRid<=0;

% Calculate BRidT = vector of BRid in the time domain
%BRidT = ceil(BRid/NbeaconsF);
%BRidT(indexNOT) = -1;

for i = 1:Ntx
    % Packet type
    pckType = stationManagement.pckType(IDvehicleTX(i));
    iChannel = stationManagement.vehicleChannel(IDvehicleTX(i));
    % Vehicles inside the awareness range of vehicle IDvehicleTX(i)
    IDIn = awarenessID(indexVehicleTX(i),awarenessID(indexVehicleTX(i),:)>0);
    % ID of vehicles that are outside the awareness range of vehicle i
    IDOut = setdiff(all,IDIn);
    dataAgeTimestampMatrix(IDvehicleTX(i),IDOut,iPhyRaw)=-1;
    for j = 1:length(IDIn)
        % If the vehicle is not blocked and if there is no error in reception, update the matrix
        % with the timestamp of the received beacons
        %if BRid(IDIn(j))>0 && isempty(find(errorMatrix(:,1)==IDvehicleTX(i) & errorMatrix(:,2)==IDIn(j), 1))
        if find(correctRxList(:,1)==IDvehicleTX(i) & correctRxList(:,2)==IDIn(j), 1)>0
            % Store previous timestamp
            previousTimeStamp = dataAgeTimestampMatrix(IDvehicleTX(i),IDIn(j),iPhyRaw);
            % Compute current timestamp
            currentTimeStamp = elapsedTime;
            % If there was a previous timestamp
            if previousTimeStamp>0
                % Compute update delay, considering the subframe used for transmission (s)
                dataAge = currentTimeStamp-previousTimeStamp;
                % Check if the update delay is larger than the maximum delay value stored in the array
                if dataAge<0
                    error('Update delay < 0');
                elseif dataAge>=delayMax
                    % Increment last counter
                    dataAgeCounter(iChannel,pckType,end,iPhyRaw) = dataAgeCounter(iChannel,pckType,end,iPhyRaw) + 1;
                else
                    %if dataAge<appParams.averageTbeacon
                    %    error('The data age is too small: %f',dataAge);
                    %end                    
                    % Increment counter corresponding to the current delay
                    dataAgeCounter(iChannel,pckType,ceil(dataAge/delayResolution),iPhyRaw) = ...
                        dataAgeCounter(iChannel,pckType,ceil(dataAge/delayResolution),iPhyRaw) + 1;
                end
            end
            % Update updateTimeMatrix with the current timestamp
            dataAgeTimestampMatrix(IDvehicleTX(i),IDIn(j),iPhyRaw) = timeManagement.timeGeneratedPacketInTxLTE(IDvehicleTX(i));
        end
    end
end

end
