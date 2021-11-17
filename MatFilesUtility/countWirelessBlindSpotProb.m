function wirelessBlindSpotCounter = countWirelessBlindSpotProb(updateTimeMatrix,enteredInRange,wirelessBlindSpotCounter,elapsedTime,phyParams)
% Function to store delay events for wireless blind spot computation

% For every time interval (multiples of Tbeacon)
NupdateDelayEvents = length(wirelessBlindSpotCounter(:,1,1));
    %fp = fopen('temp.xls','a');    
for iRaw = 1:length(phyParams.Raw)
    % Build timeDiff matrix
    timeDiffMatrix = updateTimeMatrix(:,:,iRaw);
    timeDiffMatrix(timeDiffMatrix>0) = elapsedTime-timeDiffMatrix(timeDiffMatrix>0);

    for i = 1:NupdateDelayEvents
        
        % Count number of delay events larger or equal than time interval
        wirelessBlindSpotCounter(i,iRaw,2) = wirelessBlindSpotCounter(i,iRaw,2) + sum(timeDiffMatrix(:)>=wirelessBlindSpotCounter(i,iRaw,1)) + sum(sum(timeDiffMatrix()<0 & enteredInRange(:,:,iRaw)>=0 & (elapsedTime-enteredInRange(:,:,iRaw))>wirelessBlindSpotCounter(i,iRaw,1)));
        % Count number of delay events shorter than time interval
        wirelessBlindSpotCounter(i,iRaw,3) = wirelessBlindSpotCounter(i,iRaw,3) + sum(timeDiffMatrix(:)>0 & timeDiffMatrix(:)<wirelessBlindSpotCounter(i,iRaw,1));
        
        %if iRaw == length(phyParams.Raw) && i==NupdateDelayEvents
        %    fprintf(fp,'%f\t%f\t%f\t%f\t',elapsedTime,wirelessBlindSpotCounter(i,iRaw,2),sum(timeDiffMatrix(:)>=wirelessBlindSpotCounter(i,iRaw,1)),sum(sum(timeDiffMatrix()<0 & enteredInRange(:,:,iRaw)>=0 & (elapsedTime-enteredInRange(:,:,iRaw))>wirelessBlindSpotCounter(i,iRaw,1))));
        %end
        
    end
    %if iRaw == length(phyParams.Raw) 
    %    fprintf(fp,'\n');
    %end
end
%fclose(fp);

%% Before version 5.4.1
% % Build timeDiff matrix
% timeDiffMatrix = updateTimeMatrix;
% timeDiffMatrix(timeDiffMatrix>0) = elapsedTime-timeDiffMatrix(timeDiffMatrix>0);
% 
% % For every time interval (multiples of Tbeacon)
% for i = 1:length(wirelessBlindSpotCounter)
%     % Count number of delay events larger or equal than time interval
%     wirelessBlindSpotCounter(i,2) = wirelessBlindSpotCounter(i,2) + sum(timeDiffMatrix(:)>=wirelessBlindSpotCounter(i,1));
%     % Count number of delay events shorter than time interval
%     wirelessBlindSpotCounter(i,3) = wirelessBlindSpotCounter(i,3) + sum(timeDiffMatrix(:)>0 & timeDiffMatrix(:)<wirelessBlindSpotCounter(i,1));
% end
