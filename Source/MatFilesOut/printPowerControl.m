function printPowerControl(outputValues,outParams)
% Print to file the power control allocation occurencies
% [Tx power (dBm) - number of events - CDF]

filename = sprintf('%s/power_control_%.0f.xls',outParams.outputFolder,outParams.simID);
fileID = fopen(filename,'at');

NeventsTOT = sum(outputValues.powerControlCounter);

for i = 1:length(outputValues.powerControlCounter)
    fprintf(fileID,'%.2f\t%d\t%.6f\n',i*outParams.powerResolution-101,outputValues.powerControlCounter(i),sum(outputValues.powerControlCounter(1:i))/NeventsTOT);
end

fclose(fileID);

end