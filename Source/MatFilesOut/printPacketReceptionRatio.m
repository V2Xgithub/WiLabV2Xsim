function printPacketReceptionRatio(tag,distanceDetailsCounter,outParams,appParams,simParams,phyParams)
% Print to file Rx details vs. distance up to Raw Max

% Cycle over channels
for iChannel = 1:phyParams.nChannels
    % Cycle over packet types
    for pckType = 1:appParams.nPckTypes

        % #Neighbors within in meters
        distanceDetailsCounter(iChannel,pckType,:,5) = distanceDetailsCounter(iChannel,pckType,:,2) + distanceDetailsCounter(iChannel,pckType,:,3) + distanceDetailsCounter(iChannel,pckType,:,4);

        if sum(distanceDetailsCounter(iChannel,pckType,:,5))==0
            continue;
        end

        % If variable beacon size is selected (currently only for 11p)
        if simParams.technology==2 && appParams.variableBeaconSize
            distanceDetailsCounter(iChannel,pckType,:,9) = distanceDetailsCounter(iChannel,pckType,:,6) + distanceDetailsCounter(iChannel,pckType,:,7) + distanceDetailsCounter(iChannel,pckType,:,8);
        end

        for j=length(distanceDetailsCounter(iChannel,pckType,:,1)):-1:2
            distanceDetailsCounter(iChannel,pckType,j,2:end) = distanceDetailsCounter(iChannel,pckType,j,2:end) - distanceDetailsCounter(iChannel,pckType,j-1,2:end);
        end

        filename_part1 = sprintf('%s/packet_reception_ratio_%.0f_%s',outParams.outputFolder,outParams.simID,tag);
        if pckType==1
            filename_part2 = '';
        elseif pckType==2
            filename_part2 = '_DENM';
        else
            error('Packet type not implemented');
        end  
        if phyParams.nChannels==1
            filename_part3 = '';
        else
            filename_part3 = sprintf('_C%d',iChannel);
        end
        filename = strcat(filename_part1,filename_part2,filename_part3,'.xls');                
%         if pckType==1
%             filename = sprintf('%s/packet_reception_ratio_%.0f_%s.xls',outParams.outputFolder,outParams.simID,tag);
%         elseif pckType==2
%             filename = sprintf('%s/packet_reception_ratio_%.0f_%s_DENM.xls',outParams.outputFolder,outParams.simID,tag);
%         else
%             error('Packet type not implemented');
%         end                

        fileID = fopen(filename,'at');

        if simParams.technology==2 && appParams.variableBeaconSize
            % If variable beacon size is selected (currently only for 11p)
                for i = 1:length(distanceDetailsCounter(pckType,:,1))
                    fprintf(fileID,'%d\t%d\t%d\t%d\t%d\t%f\t%d\t%d\t%d\t%d\t%f\n',...
                        distanceDetailsCounter(iChannel,pckType,i,1),distanceDetailsCounter(iChannel,pckType,i,2),distanceDetailsCounter(iChannel,pckType,i,3),distanceDetailsCounter(iChannel,pckType,i,4),distanceDetailsCounter(iChannel,pckType,i,5),distanceDetailsCounter(iChannel,pckType,i,2)/distanceDetailsCounter(iChannel,pckType,i,5),...
                        distanceDetailsCounter(iChannel,pckType,i,6),distanceDetailsCounter(iChannel,pckType,i,7),distanceDetailsCounter(iChannel,pckType,i,8),distanceDetailsCounter(iChannel,pckType,i,9),distanceDetailsCounter(iChannel,pckType,i,6)/distanceDetailsCounter(iChannel,pckType,i,9));
                end
        else
            % If constant beacon size is selected
            for i = 1:length(distanceDetailsCounter(iChannel,pckType,:,1))
                fprintf(fileID,'%d\t%d\t%d\t%d\t%d\t%f\n',...
                    distanceDetailsCounter(iChannel,pckType,i,1),distanceDetailsCounter(iChannel,pckType,i,2),distanceDetailsCounter(iChannel,pckType,i,3),distanceDetailsCounter(iChannel,pckType,i,4),distanceDetailsCounter(iChannel,pckType,i,5),distanceDetailsCounter(iChannel,pckType,i,2)/distanceDetailsCounter(iChannel,pckType,i,5));
            end
        end

        fclose(fileID);

    end
end

end