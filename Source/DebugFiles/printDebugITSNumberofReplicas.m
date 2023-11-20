function printDebugITSNumberofReplicas(outParams, time, retransType, idTx, ITSNumberOfReplicas)
filename = sprintf('%s/_DebugITSNumberofReplicas_%d.xls',outParams.outputFolder,outParams.simID);
fid = fopen(filename,'r');
if fid==-1
    fid = fopen(filename,'w');
    fprintf(fid,'Time\tretransType\tidTx\tITSNumberOfReplicas\n');
end
fclose(fid);

fid = fopen(filename,'a');
fprintf(fid,'%3.6f\t%d\t%d\t%d\n',time,retransType,idTx,ITSNumberOfReplicas);

fclose(fid);