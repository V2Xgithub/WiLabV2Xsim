function printDelay(stationManagement,outputValues,appParams,outParams,phyParams,simParams)
% Print to file the delay occurrences
% [delay (s) - number of events - CDF]

% Update delay
if outParams.printUpdateDelay
    for iChannel = 1:phyParams.nChannels
        for pckType = 1:appParams.nPckTypes
            
            if sum(stationManagement.vehicleState==100)>0
            %if simParams.technology ~= 2 % not only 11p
                if sum(sum(outputValues.updateDelayCounterCV2X(iChannel,pckType,:,:)))==0
                    continue;
                end
                % outputValues.updateDelayCounterCV2X needs elaboration
                % Now contains values up to each awareness range value; must
                % instead include the values in each group
                for iPhyRaw=length(outputValues.updateDelayCounterCV2X(iChannel,pckType,1,:)):-1:2
                    outputValues.updateDelayCounterCV2X(iChannel,pckType,:,iPhyRaw) = outputValues.updateDelayCounterCV2X(iChannel,pckType,:,iPhyRaw)-outputValues.updateDelayCounterCV2X(iChannel,pckType,:,iPhyRaw-1);
                end
                % Now the values can be print
                filename_part1 = sprintf('%s/update_delay_%.0f_%s',outParams.outputFolder,outParams.simID,simParams.stringCV2X);
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
%                 if pckType==1
%                     filename = sprintf('%s/update_delay_%.0f_%s.xls',outParams.outputFolder,outParams.simID,'LTE');
%                 elseif pckType==2
%                     filename = sprintf('%s/update_delay_%.0f_%s_DENM.xls',outParams.outputFolder,outParams.simID,'LTE');
%                 else
%                     error('Packet type not implemented');
%                 end                
                fileID = fopen(filename,'at');
                NeventsTOT = sum(squeeze(outputValues.updateDelayCounterCV2X(iChannel,pckType,:,:)),1);
                for i = 1:length(outputValues.updateDelayCounterCV2X(iChannel,pckType,:,1))
                    fprintf(fileID,'%.3f\t',i*outParams.delayResolution);
                    for iPhyRaw=1:length(NeventsTOT)   
                        fprintf(fileID,'%d\t%.6f',outputValues.updateDelayCounterCV2X(iChannel,pckType,i,iPhyRaw),sum(squeeze(outputValues.updateDelayCounterCV2X(iChannel,pckType,1:i,iPhyRaw)))/NeventsTOT(iPhyRaw));
                        if length(NeventsTOT)>1
                            fprintf(fileID,'\t');
                        else
                            fprintf(fileID,'\n');
                        end
                    end
                    if length(NeventsTOT)>1
                        fprintf(fileID,'%d\t%.6f\n',sum(squeeze(outputValues.updateDelayCounterCV2X(iChannel,pckType,i,:))),sum(sum(squeeze(outputValues.updateDelayCounterCV2X(iChannel,pckType,1:i,:)),1))/sum(NeventsTOT(:)));
                    end
                end
                fclose(fileID);
            end
            if sum(stationManagement.vehicleState~=100)>0
            %if simParams.technology ~= 1 % not only LTE
                if sum(sum(outputValues.updateDelayCounter11p(iChannel,pckType,:,:)))==0
                    continue;
                end
                % outputValues.updateDelayCounter11p needs elaboration
                % Now contains values up to each awareness range value; must
                % instead include teh values in each group
                for iPhyRaw=length(outputValues.updateDelayCounter11p(iChannel,pckType,1,:)):-1:2
                    outputValues.updateDelayCounter11p(iChannel,pckType,:,iPhyRaw) = outputValues.updateDelayCounter11p(iChannel,pckType,:,iPhyRaw)-outputValues.updateDelayCounter11p(iChannel,pckType,:,iPhyRaw-1);
                end
                % Now the values can be print
                filename_part1 = sprintf('%s/update_delay_%.0f_%s',outParams.outputFolder,outParams.simID,'11p');
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
%                 if pckType==1
%                     filename = sprintf('%s/update_delay_%.0f_%s.xls',outParams.outputFolder,outParams.simID,'11p');
%                 elseif pckType==2
%                     filename = sprintf('%s/update_delay_%.0f_%s_DENM.xls',outParams.outputFolder,outParams.simID,'11p');
%                 else
%                     error('Packet type not implemented');
%                 end                
                fileID = fopen(filename,'at');
                NeventsTOT = sum(squeeze(outputValues.updateDelayCounter11p(iChannel,pckType,:,:)),1);
                for i = 1:length(outputValues.updateDelayCounter11p(iChannel,pckType,:,1))
                    fprintf(fileID,'%.3f\t',i*outParams.delayResolution);
                    for iPhyRaw=1:length(NeventsTOT)   
                        fprintf(fileID,'%d\t%.6f',outputValues.updateDelayCounter11p(iChannel,pckType,i,iPhyRaw),sum(squeeze(outputValues.updateDelayCounter11p(iChannel,pckType,1:i,iPhyRaw)))/NeventsTOT(iPhyRaw));
                        if length(NeventsTOT)>1
                            fprintf(fileID,'\t');
                        else
                            fprintf(fileID,'\n');
                        end
                    end
                    if length(NeventsTOT)>1
                        fprintf(fileID,'%d\t%.6f\n',sum(squeeze(outputValues.updateDelayCounter11p(iChannel,pckType,i,:))),sum(sum(squeeze(outputValues.updateDelayCounter11p(iChannel,pckType,1:i,:)),1))/sum(NeventsTOT(:)));
                    end
                end
                fclose(fileID);
            end
        end
    end

    % Wireless blind spot probability
    if outParams.printWirelessBlindSpotProb
        % Print to file the wireless blind spot probability
        % [Time interval - # delay events larger or equal than time interval - #
        % delay events shorter than time interval - wireless blind spot probability]
        
        % If there are events LTE
        if (outputValues.wirelessBlindSpotCounterCV2X(1,length(phyParams.Raw),2)+outputValues.wirelessBlindSpotCounterCV2X(1,length(phyParams.Raw),3))>0            
            filename = sprintf('%s/wireless_blind_spot_%.0f_%s.xls',outParams.outputFolder,outParams.simID,simParams.stringCV2X);
            fileID = fopen(filename,'at');
            for i = 1:length(outputValues.wirelessBlindSpotCounterCV2X)
                fprintf(fileID,'%.3f',outputValues.wirelessBlindSpotCounterCV2X(i,1,1));
                for iRaw = 1:length(phyParams.Raw)
                    fprintf(fileID,'\t%d\t%d\t%.6f',outputValues.wirelessBlindSpotCounterCV2X(i,iRaw,2),outputValues.wirelessBlindSpotCounterCV2X(i,iRaw,3),...
                        outputValues.wirelessBlindSpotCounterCV2X(i,iRaw,2)/(outputValues.wirelessBlindSpotCounterCV2X(i,iRaw,2)+outputValues.wirelessBlindSpotCounterCV2X(i,iRaw,3)));
                end
                fprintf(fileID,'\n');
            end
            fclose(fileID); 
        end
        % If there are events 11p
        if (outputValues.wirelessBlindSpotCounter11p(1,length(phyParams.Raw),2)+outputValues.wirelessBlindSpotCounter11p(1,length(phyParams.Raw),3))>0            
            filename = sprintf('%s/wireless_blind_spot_%.0f_11p.xls',outParams.outputFolder,outParams.simID);
            fileID = fopen(filename,'at');
            for i = 1:length(outputValues.wirelessBlindSpotCounter11p)
                fprintf(fileID,'%.3f',outputValues.wirelessBlindSpotCounter11p(i,1,1));
                for iRaw = 1:length(phyParams.Raw)
                    fprintf(fileID,'\t%d\t%d\t%.6f',outputValues.wirelessBlindSpotCounter11p(i,iRaw,2),outputValues.wirelessBlindSpotCounter11p(i,iRaw,3),...
                        outputValues.wirelessBlindSpotCounter11p(i,iRaw,2)/(outputValues.wirelessBlindSpotCounter11p(i,iRaw,2)+outputValues.wirelessBlindSpotCounter11p(i,iRaw,3)));
                end
                fprintf(fileID,'\n');
            end
            fclose(fileID); 
        end
    end
end

% Data Age
if outParams.printDataAge
    for iChannel = 1:phyParams.nChannels
        for pckType = 1:appParams.nPckTypes

            if sum(stationManagement.vehicleState==100)>0 % any LTE node
                if sum(sum(outputValues.dataAgeCounterCV2X(iChannel,pckType,:,:)))==0
                    continue;
                end

                % outputValues.dataAgeCounterCV2X needs elaboration
                % Now contains values up to each awareness range value; must
                % instead include teh values in each group
                for iPhyRaw=length(outputValues.dataAgeCounterCV2X(iChannel,pckType,1,:)):-1:2
                    outputValues.dataAgeCounterCV2X(iChannel,pckType,:,iPhyRaw) = outputValues.dataAgeCounterCV2X(iChannel,pckType,:,iPhyRaw)-outputValues.dataAgeCounterCV2X(iChannel,pckType,:,iPhyRaw-1);
                end
                % Now the values can be print
                filename_part1 = sprintf('%s/data_age_%.0f_%s',outParams.outputFolder,outParams.simID,simParams.stringCV2X);
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
%                 if pckType==1
%                     filename = sprintf('%s/data_age_%.0f_%s.xls',outParams.outputFolder,outParams.simID,'LTE');
%                 elseif pckType==2
%                     filename = sprintf('%s/data_age_%.0f_%s_DENM.xls',outParams.outputFolder,outParams.simID,'LTE');
%                 else
%                     error('Packet type not implemented');
%                 end                            
                fileID = fopen(filename,'at');
                NeventsTOT = sum(squeeze(outputValues.dataAgeCounterCV2X(iChannel,pckType,:,:)),1);
                for i = 1:length(outputValues.dataAgeCounterCV2X(iChannel,pckType,:,1))
                    fprintf(fileID,'%.3f\t',i*outParams.delayResolution);
                    for iPhyRaw=1:length(NeventsTOT)   
                        fprintf(fileID,'%d\t%.6f',outputValues.dataAgeCounterCV2X(iChannel,pckType,i,iPhyRaw),sum(squeeze(outputValues.dataAgeCounterCV2X(iChannel,pckType,1:i,iPhyRaw)))/NeventsTOT(iPhyRaw));
                        if length(NeventsTOT)>1
                            fprintf(fileID,'\t');
                        else
                            fprintf(fileID,'\n');
                        end
                    end
                    if length(NeventsTOT)>1
                        fprintf(fileID,'%d\t%.6f\n',sum(squeeze(outputValues.dataAgeCounterCV2X(iChannel,pckType,i,:))),sum(sum(squeeze(outputValues.dataAgeCounterCV2X(iChannel,pckType,1:i,:)),1))/sum(NeventsTOT(:)));
                    end
                end
                fclose(fileID);
            end

            if sum(stationManagement.vehicleState~=100)>0 % If any 11p node
 
                if sum(sum(outputValues.dataAgeCounter11p(iChannel,pckType,:,:)))==0
                    continue;
                end

                % outputValues.dataAgeCounter11p needs elaboration
                % Now contains values up to each awareness range value; must
                % instead include teh values in each group
                for iPhyRaw=length(outputValues.dataAgeCounter11p(iChannel,pckType,1,:)):-1:2
                    outputValues.dataAgeCounter11p(iChannel,pckType,:,iPhyRaw) = outputValues.dataAgeCounter11p(iChannel,pckType,:,iPhyRaw)-outputValues.dataAgeCounter11p(iChannel,pckType,:,iPhyRaw-1);
                end
                % Now the values can be print
                filename_part1 = sprintf('%s/data_age_%.0f_%s',outParams.outputFolder,outParams.simID,'11p');
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
%                 if pckType==1
%                     filename = sprintf('%s/data_age_%.0f_%s.xls',outParams.outputFolder,outParams.simID,'11p');
%                 elseif pckType==2
%                     filename = sprintf('%s/data_age_%.0f_%s_DENM.xls',outParams.outputFolder,outParams.simID,'11p');
%                 else
%                     error('Packet type not implemented');
%                 end                            
                fileID = fopen(filename,'at');
                NeventsTOT = sum(squeeze(outputValues.dataAgeCounter11p(iChannel,pckType,:,:)),1);
                for i = 1:length(outputValues.dataAgeCounter11p(iChannel,pckType,:,1))
                    fprintf(fileID,'%.3f\t',i*outParams.delayResolution);
                    for iPhyRaw=1:length(NeventsTOT)   
                        fprintf(fileID,'%d\t%.6f',outputValues.dataAgeCounter11p(iChannel,pckType,i,iPhyRaw),sum(squeeze(outputValues.dataAgeCounter11p(iChannel,pckType,1:i,iPhyRaw)))/NeventsTOT(iPhyRaw));
                        if length(NeventsTOT)>1
                            fprintf(fileID,'\t');
                        else
                            fprintf(fileID,'\n');
                        end
                    end
                    if length(NeventsTOT)>1
                        fprintf(fileID,'%d\t%.6f\n',sum(squeeze(outputValues.dataAgeCounter11p(iChannel,pckType,i,:))),sum(sum(squeeze(outputValues.dataAgeCounter11p(iChannel,pckType,1:i,:)),1))/sum(NeventsTOT(:)));
                    end
                end
                fclose(fileID);
            end
        end
    end
end

% Packet delay
if outParams.printPacketDelay
    for iChannel = 1:phyParams.nChannels
        for pckType = 1:appParams.nPckTypes
            if sum(stationManagement.vehicleState==100)>0
            %if simParams.technology ~= 2 % not only 11p
                if sum(sum(outputValues.packetDelayCounterCV2X(iChannel,pckType,:,:)))==0
                    continue;
                end
                % outputValues.packetDelayCounterCV2X needs elaboration
                % Now contains values up to each awareness range value; must
                % instead include teh values in each group
                for iPhyRaw=length(outputValues.packetDelayCounterCV2X(iChannel,pckType,1,:)):-1:2
                    outputValues.packetDelayCounterCV2X(iChannel,pckType,:,iPhyRaw) = outputValues.packetDelayCounterCV2X(iChannel,pckType,:,iPhyRaw)-outputValues.packetDelayCounterCV2X(iChannel,pckType,:,iPhyRaw-1);
                end
                % Now the values can be print
                filename_part1 = sprintf('%s/packet_delay_%.0f_%s',outParams.outputFolder,outParams.simID,simParams.stringCV2X);
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
%                 if pckType==1
%                     filename = sprintf('%s/packet_delay_%.0f_%s.xls',outParams.outputFolder,outParams.simID,'LTE');
%                 elseif pckType==2
%                     filename = sprintf('%s/packet_delay_%.0f_%s_DENM.xls',outParams.outputFolder,outParams.simID,'LTE');
%                 else
%                     error('Packet type not implemented');
%                 end
                fileID = fopen(filename,'at');
                NeventsTOT = sum(squeeze(outputValues.packetDelayCounterCV2X(iChannel,pckType,:,:)),1);
                for i = 1:length(outputValues.packetDelayCounterCV2X(iChannel,pckType,:,1))
                    fprintf(fileID,'%.3f\t',i*outParams.delayResolution);
                    for iPhyRaw=1:length(NeventsTOT)   
                        fprintf(fileID,'%d\t%.6f',outputValues.packetDelayCounterCV2X(iChannel,pckType,i,iPhyRaw),sum(squeeze(outputValues.packetDelayCounterCV2X(iChannel,pckType,1:i,iPhyRaw)))/NeventsTOT(iPhyRaw));
                        if length(NeventsTOT)>1
                            fprintf(fileID,'\t');
                        else
                            fprintf(fileID,'\n');
                        end
                    end
                    if length(NeventsTOT)>1
                        fprintf(fileID,'%d\t%.6f\n',sum(squeeze(outputValues.packetDelayCounterCV2X(iChannel,pckType,i,:))),sum(sum(squeeze(outputValues.packetDelayCounterCV2X(iChannel,pckType,1:i,:)),1))/sum(NeventsTOT(:)));
                    end
                end
                fclose(fileID);    
            end
            if sum(stationManagement.vehicleState~=100)>0
            %if simParams.technology ~= 1 % not only LTE
                if sum(sum(outputValues.packetDelayCounter11p(iChannel,pckType,:,:)))==0
                    continue;
                end
                % outputValues.packetDelayCounter11p needs elaboration
                % Now contains values up to each awareness range value; must
                % instead include teh values in each group
                for iPhyRaw=length(outputValues.packetDelayCounter11p(iChannel,pckType,1,:)):-1:2
                    outputValues.packetDelayCounter11p(iChannel,pckType,:,iPhyRaw) = outputValues.packetDelayCounter11p(iChannel,pckType,:,iPhyRaw)-outputValues.packetDelayCounter11p(iChannel,pckType,:,iPhyRaw-1);
                end
                % Now the values can be print
                filename_part1 = sprintf('%s/packet_delay_%.0f_%s',outParams.outputFolder,outParams.simID,'11p');
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
%                 if pckType==1
%                     filename = sprintf('%s/packet_delay_%.0f_%s.xls',outParams.outputFolder,outParams.simID,'11p');
%                 elseif pckType==2
%                     filename = sprintf('%s/packet_delay_%.0f_%s_DENM.xls',outParams.outputFolder,outParams.simID,'11p');
%                 else
%                     error('Packet type not implemented');
%                 end
                fileID = fopen(filename,'at');
                NeventsTOT = sum(squeeze(outputValues.packetDelayCounter11p(iChannel,pckType,:,:)),1);
                for i = 1:length(outputValues.packetDelayCounter11p(iChannel,pckType,:,1))
                    fprintf(fileID,'%.3f\t',i*outParams.delayResolution);
                    for iPhyRaw=1:length(NeventsTOT)   
                        fprintf(fileID,'%d\t%.6f',outputValues.packetDelayCounter11p(iChannel,pckType,i,iPhyRaw),sum(squeeze(outputValues.packetDelayCounter11p(iChannel,pckType,1:i,iPhyRaw)))/NeventsTOT(iPhyRaw));
                        if length(NeventsTOT)>1
                            fprintf(fileID,'\t');
                        else
                            fprintf(fileID,'\n');
                        end
                    end
                    if length(NeventsTOT)>1
                        fprintf(fileID,'%d\t%.6f\n',sum(squeeze(outputValues.packetDelayCounter11p(iChannel,pckType,i,:))),sum(sum(squeeze(outputValues.packetDelayCounter11p(iChannel,pckType,1:i,:)),1))/sum(NeventsTOT(:)));
                    end
                end
                fclose(fileID);    
            end
        end
    end
end

end

