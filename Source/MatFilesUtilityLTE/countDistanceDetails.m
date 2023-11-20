function distanceDetailsCounter = countDistanceDetails(correctRxListRawMax,errorRxListRawMax,distanceDetailsCounter,stationManagement,outParams,appParams,phyParams)
% Count events for distances up to the maximum awareness range (removing border effect)
% [distance, #Correctly received beacons, #Errors, #Blocked neighbors, #Neighbors]
% #Neighbors will be calculated in "printDistanceDetailsCounter.m" (only one call)

% Cycle over channel
for iChannel = 1:phyParams.nChannels
    
    % Cycle over packet types
    for pckType = 1:appParams.nPckTypes
        % Update array with the events vs. distance
         for i = 1:1:length(distanceDetailsCounter(iChannel,pckType,:,1))

            distance = i * outParams.prrResolution;

%             % Number of receiving neighbors at i meters
%             NrxNeighbors = nnz((neighborsID(indexVehicleTX(stationManagement.pckType(IDVehicleTX)==pckType & stationManagement.vehicleChannel(IDVehicleTX)==iChannel),:)>0).*...
%                 (neighborsDistance(indexVehicleTX(stationManagement.pckType(IDVehicleTX)==pckType & stationManagement.vehicleChannel(IDVehicleTX)==iChannel),:) < distance));
% 
            % Since v 5.4.14
%             % #Errors within i meters
%             Nerrors = nnz(errorMatrix((stationManagement.pckType(errorMatrix(:,1))==pckType & stationManagement.vehicleChannel(errorMatrix(:,1))==iChannel),4) < distance);
%             distanceDetailsCounter(iChannel,pckType,i,3) = distanceDetailsCounter(iChannel,pckType,i,3) + Nerrors;
% 
%             % #Correctly received beacons within i meters
%             NrxOK = NrxNeighbors - Nerrors;
%             distanceDetailsCounter(iChannel,pckType,i,2) = distanceDetailsCounter(iChannel,pckType,i,2) + NrxOK;

            % #Correctly received beacons within i meters
            NrxOK = nnz(correctRxListRawMax((stationManagement.pckType(correctRxListRawMax(:,1))==pckType & stationManagement.vehicleChannel(correctRxListRawMax(:,1))==iChannel),4) < distance);
            distanceDetailsCounter(iChannel,pckType,i,2) = distanceDetailsCounter(iChannel,pckType,i,2) + NrxOK;

            % #Errors within i meters             
            Nerrors = nnz(errorRxListRawMax((stationManagement.pckType(errorRxListRawMax(:,1))==pckType & stationManagement.vehicleChannel(errorRxListRawMax(:,1))==iChannel),4) < distance);
            distanceDetailsCounter(iChannel,pckType,i,3) = distanceDetailsCounter(iChannel,pckType,i,3) + Nerrors;
            
            if i>1 && distanceDetailsCounter(iChannel,pckType,i,2)<distanceDetailsCounter(iChannel,pckType,i-1,2)
                error('Error in "countDistanceDetails"');
            end
        end
    end
end

end
