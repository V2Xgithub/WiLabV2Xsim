function printCBRToFileITSG5(stationManagement,simParams,outParams,phyParams)
% Print CBR statistics

% I remove the first 10 values of CBR to consider a minimum of transitory
if length(stationManagement.cbr11pValues(1,:))>10
   stationManagement.cbr11pValues(:,1:10) = [];
end

for iChannel=1:phyParams.nChannels
    
    if sum(stationManagement.vehicleChannel==iChannel)==0
        continue;
    end
    
    if phyParams.nChannels==1
        cbrOutputFileName = sprintf('%s/CBRstatistic_%.0f_11p.xls',outParams.outputFolder,outParams.simID);
    else
        cbrOutputFileName = sprintf('%s/CBRstatistic_%.0f_11p_C%d.xls',outParams.outputFolder,outParams.simID,iChannel);
    end

    cbrVector = stationManagement.cbr11pValues(stationManagement.vehicleChannel==iChannel,:);
    cbrVector = reshape(cbrVector,[],1);
    values = cbrVector(cbrVector>=0);
    [F,X] = ecdf(values);
    fileID = fopen(cbrOutputFileName,'w');
    for i=1:length(F)
        fprintf(fileID,'%f\t%f\n',X(i),F(i));
    end
    fclose(fileID);
end

if ~isempty(stationManagement.activeIDs11p)    
    idTest = stationManagement.activeIDs11p(1);

    cbrOutputFileName = sprintf('%s/CBRofGenericVehicle_%.0f_11p.xls',outParams.outputFolder,outParams.simID);
    values = stationManagement.cbr11pValues(idTest,:);
    time = (10+(1:length(values))) * simParams.cbrSensingInterval;
    fileID = fopen(cbrOutputFileName,'w');
    for i=1:length(values)
        if values(i)>=0
            fprintf(fileID,'%f\t%f\n',time(i),values(i));
        end
    end
    fclose(fileID);
end
