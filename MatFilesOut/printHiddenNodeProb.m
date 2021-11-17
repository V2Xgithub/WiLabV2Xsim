function  printHiddenNodeProb(outputValues,outParams)
% Print to file the hidden node probability
% [distance(m) - Nevents - hidden node probability]

filename = sprintf('%s/hiddenNodeProb_%.0f_%.0f.xls',outParams.outputFolder,outParams.simID,outParams.Pth_dBm);
fileID = fopen(filename,'at');

for i = 1:length(outputValues.hiddenNodeSumProb)
    fprintf(fileID,'%.0f\t%.0f\t%.6f\n',i,outputValues.hiddenNodeProbEvents(i),outputValues.hiddenNodeSumProb(i)/outputValues.hiddenNodeProbEvents(i));
end

fclose(fileID);

end