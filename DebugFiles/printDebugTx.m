function printDebugTx(Time,isThisTX,staID,stationManagement,positionManagement,sinrManagement,outParams,phyParams)
% Print of: Time, event description, then per each station:
% ID, technology, state, current SINR (if LTE, first neighbor), useful power (if LTE, first neighbor),
% interfering power (if LTE, first neighbor), interfering power from
% the other technology (if LTE, first neighbor)

%if Time<0 || Time>2
%if Time>0.2
return;
%end

alsoRx = true;

filename = sprintf('%s/_DebugTx_%d.xls',outParams.outputFolder,outParams.simID);
% fid = fopen(filename,'r');
% if fid==-1
%     fid = fopen(filename,'w');
%     fprintf(fid,'Time\tVehicle 11p TX\t');
%     if alsoRx
%         fprintf(fid,'Vehicle 11p RX OK\tVehicle 11p RX ERR\t');
%     end
%     fprintf(fid,'Vehicle LTE TX\t');
%     if alsoRx
%         fprintf(fid,'Vehicle LTE RX OK\tVehicle LTE RX ERR\t');
%     end
%     fprintf(fid,'X of Vehicle 11p TX\t');
%     if alsoRx
%         fprintf(fid,'X of Vehicle 11p RX OK\tX of Vehicle 11p RX ERR\t');
%     end
%     fprintf(fid,'X of Vehicle LTE TX');
%     if alsoRx
%         fprintf(fid,'\tX of Vehicle LTE RX OK\tX of Vehicle LTE RX ERR');
%     end
%     fprintf(fid,'\n');
% end
% fclose(fid);

fid = fopen(filename,'a');
if staID==-1
    if isfield(stationManagement,'transmittingIDsCV2X') && ~isempty(stationManagement.transmittingIDsCV2X)
        nTx = length(stationManagement.transmittingIDsCV2X);
        for index=1:nTx
            if isThisTX
                fprintf(fid,'%3.6f\t-1\t-1\t-1\t%d\t-1\t-1\t-1',Time,stationManagement.transmittingIDsCV2X(index));
                fprintf(fid,'\t-1\t-1\t%d\t-1\t-1\n',positionManagement.XvehicleReal(stationManagement.transmittingIDsCV2X(index)));
            end
            if alsoRx && ~isThisTX
                % Find indexes of receiving vehicles in neighborsID
                indexNeighborsRX = find(stationManagement.neighborsIDLTE(stationManagement.indexInActiveIDsOnlyLTE_OfTxLTE(index),:));
                for j = 1:length(indexNeighborsRX)
                    % If received beacon SINR is lower than the threshold
                    sinrThr=phyParams.LOS(index,indexNeighborsRX(j)).*phyParams.sinrThresholdCV2X_LOS+...
                            (1-phyParams.LOS(index,indexNeighborsRX(j)) ).*phyParams.sinrThresholdCV2X_NLOS;   
                    if sinrManagement.neighborsSINRaverageCV2X(index,indexNeighborsRX(j)) < sinrThr
                        fprintf(fid,'%3.6f\t-1\t-1\t-1\t-1\t-1\t%d\t-1',Time,stationManagement.neighborsIDLTE(stationManagement.indexInActiveIDsOnlyLTE_OfTxLTE(index),j));
                        fprintf(fid,'\t-1\t-1\t-1\t-1\t%d\n',positionManagement.XvehicleReal(stationManagement.neighborsIDLTE(stationManagement.indexInActiveIDsOnlyLTE_OfTxLTE(index),j)));
                    else
                        fprintf(fid,'%3.6f\t-1\t-1\t-1\t-1\t%d\t-1\t-1',Time,stationManagement.neighborsIDLTE(stationManagement.indexInActiveIDsOnlyLTE_OfTxLTE(index),j));
                        fprintf(fid,'\t-1\t-1\t-1\t%d\t-1\n',positionManagement.XvehicleReal(stationManagement.neighborsIDLTE(stationManagement.indexInActiveIDsOnlyLTE_OfTxLTE(index),j)));
                    end
                end
            end
        end
    end

else

    if isThisTX
        fprintf(fid,'%3.6f\t%d\t-1\t-1\t-1\t-1\t-1\t',Time,staID);
        fprintf(fid,'%d\t-1\t-1\t-1\t-1\t-1\n',positionManagement.XvehicleReal(staID));
    end
    if alsoRx && ~isThisTX
        indexOfstaID = find(stationManagement.activeIDs11p==staID,1);
        sinrThr=phyParams.LOS(indexOfstaID,:).*phyParams.sinrThreshold11p_LOS+...%LOS
            (1-phyParams.LOS(indexOfstaID,:)).*phyParams.sinrThreshold11p_NLOS;
        
        rxOk = (stationManagement.vehicleState(stationManagement.activeIDs11p)==9) .* (sinrManagement.idFromWhichRx11p(stationManagement.activeIDs11p)==staID)...
                .* (sinrManagement.sinrAverage11p(stationManagement.activeIDs11p) >= sinrThr);
        awarenessID11p = stationManagement.awarenessID11p(indexOfstaID,:)';
        neighborsRaw = ismember(stationManagement.activeIDs11p,awarenessID11p);
        neighbors = (stationManagement.activeIDs11p(neighborsRaw))';
        for iN=neighbors
            indexOfNeighbor=(stationManagement.activeIDs11p==iN);
            if rxOk(indexOfNeighbor)
                fprintf(fid,'%3.6f\t-1\t%d\t-1\t-1\t-1\t-1\t-1',Time,iN);
                fprintf(fid,'\t%d\t-1\t-1\t-1\t-1\n',positionManagement.XvehicleReal(iN));
            else
                fprintf(fid,'%3.6f\t-1\t-1\t%d\t-1\t-1\t-1\t-1',Time,iN);
                fprintf(fid,'\t-1\t%d\t-1\t-1\t-1\n',positionManagement.XvehicleReal(iN));
            end
        end
    end
end

fclose(fid);
