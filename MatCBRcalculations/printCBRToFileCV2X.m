function printCBRToFileCV2X(stationManagement,simParams,outParams,phyParams)
% Print CBR statistics

%% CBR LTE statistic
% I remove the first 10 values of CBR to consider a minimum of transitory
if length(stationManagement.cbrCV2Xvalues(1,:))>10
    stationManagement.cbrCV2Xvalues(:,1:10) = [];
end

for iChannel=1:phyParams.nChannels
    
    if sum(stationManagement.vehicleChannel==iChannel)==0
        continue;
    end
    
    if phyParams.nChannels==1
        cbrOutputFileName = sprintf('%s/CBRstatistic_%.0f_%s.xls',outParams.outputFolder,outParams.simID,simParams.stringCV2X);
    else
        cbrOutputFileName = sprintf('%s/CBRstatistic_%.0f_%s_C%d.xls',outParams.outputFolder,outParams.simID,simParams.stringCV2X,iChannel);
    end

    cbrVector = stationManagement.cbrCV2Xvalues(stationManagement.vehicleChannel==iChannel,:);
    cbrVector = reshape(cbrVector,[],1);
    values = cbrVector(cbrVector>=0);
    [F,X] = ecdf(values);

    fileID = fopen(cbrOutputFileName,'w');
    for i=1:length(F)
        fprintf(fileID,'%f\t%f\n',X(i),F(i));
    end
    fclose(fileID);

    %% CBR_LTE_only
    if simParams.technology ~= 1 % not only LTE
        if length(stationManagement.coex_cbrLteOnlyValues(1,:))>10
            stationManagement.coex_cbrLteOnlyValues(:,1:10) = [];
        end
        valuesCbrLteOnly = stationManagement.coex_cbrLteOnlyValues(stationManagement.coex_cbrLteOnlyValues~=-1);
        [F2,X2] = ecdf(valuesCbrLteOnly);
        cbrOutputFileName = sprintf('%s/coex_cv2xOnly_CBRstatistic_%.0f_%s.xls',outParams.outputFolder,outParams.simID,simParams.stringCV2X);
        fileID2 = fopen(cbrOutputFileName,'w');
        for i=1:length(F2)
            fprintf(fileID2,'%f\t%f\n',X2(i),F2(i));
        end
        fclose(fileID2);
    end
end

%% Generic vehicle
if ~isempty(stationManagement.activeIDsCV2X)    
    idTest = stationManagement.activeIDsCV2X(1);
    
    cbrOutputFileName = sprintf('%s/CBRofGenericVehicle_%.0f_%s.xls',outParams.outputFolder,outParams.simID,simParams.stringCV2X);
    values = stationManagement.cbrCV2Xvalues(idTest,:);
    time = (10+(1:length(values))) * simParams.cbrSensingInterval;
    fileID = fopen(cbrOutputFileName,'w');
    for i=1:length(values)
        if values(i)>=0
            fprintf(fileID,'%f\t%f\n',time(i),values(i));
        end
    end
    fclose(fileID);
end

