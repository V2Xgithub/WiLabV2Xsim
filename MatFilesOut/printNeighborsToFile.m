function printNeighborsToFile(time,positionManagement,Nvehicles,averageNeighborsRawLTE,averageNeighborsRaw11p,outParams,phyParams)
% Print number of neighbors per vehicle at each snapshot for traffic trace
% analysis (CDF plot)

filename8 = sprintf('%s/neighbors_%.0f.xls',outParams.outputFolder,outParams.simID);
fileID = fopen(filename8,'at');

fprintf(fileID,'%f\t',time);
for k = 1:length(phyParams.Raw)
    if k==1
        distanceCheck = positionManagement.distanceReal(:,:)<phyParams.Raw(1);
    else
        distanceCheck = (positionManagement.distanceReal(:,:)>=phyParams.Raw(k-1) & positionManagement.distanceReal(:,:)>phyParams.Raw(k));
    end
    avNeighborsTot = sum(sum(distanceCheck))/Nvehicles;
    fprintf(fileID,'%d\t%d\t%d',averageNeighborsRawLTE(k),averageNeighborsRaw11p(k),avNeighborsTot);
    if k<length(phyParams.Raw)
        fprintf(fileID,'\t');
    else
        fprintf(fileID,'\n');
    end
end

fclose(fileID);

end

