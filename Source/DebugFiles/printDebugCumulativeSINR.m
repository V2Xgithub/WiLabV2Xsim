function printDebugCumulativeSINR(outParams,time,idTx,pckTxOccurring,IDRxs,cumulativePreable, cumulativeSINR, state, distance,rxOk)
% after each time transmission, print the cumulative SINR of all of the
% receiver

filename = sprintf('%s/_DebugCumulative11p_%d.xls',outParams.outputFolder,outParams.simID);
fid = fopen(filename,'r');
if fid==-1
    fid = fopen(filename,'w');
    fprintf(fid,'Time\tidTx\tpckTxOccurring\tIDRx\tcumulativePreableSINR\tcumulativeSINR\tstate\tdistance\trxOK\n');
end
fclose(fid);

fid = fopen(filename,'a');

for i = 1:length(IDRxs)
    fprintf(fid,'%3.6f\t%d\t%d\t%d\t%.2f\t%.2f\t%d\t%.2f\t%d\n',time,idTx,pckTxOccurring,IDRxs(i),cumulativePreable(IDRxs(i),idTx),cumulativeSINR(IDRxs(i), idTx),state(IDRxs(i)),distance(IDRxs(i), idTx),rxOk(i));
end
fclose(fid);