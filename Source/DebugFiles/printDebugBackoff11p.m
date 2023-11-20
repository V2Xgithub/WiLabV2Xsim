function printDebugBackoff11p(Time,StringOfEvent,idEvent,stationManagement,outParams,timeManagement)
% Print of: Time, event description, then per each station:
% ID, technology, state, current SINR (if LTE, first neighbor), useful power (if LTE, first neighbor),
% interfering power (if LTE, first neighbor), interfering power from
% the other technology (if LTE, first neighbor)

return;

filename = sprintf('%s/_DebugBackoff11p_%d.xls',outParams.outputFolder,outParams.simID);
fid = fopen(filename,'r');
if fid==-1
    fid = fopen(filename,'w');
    fprintf(fid,'Time\tEvent\tVehicle\tBackoffCounter\ttimeNextTxRx11p\n');
end
fclose(fid);

fid = fopen(filename,'a');
fprintf(fid,'%3.6f\t%s\t%d\t%d\t%d\n',Time,StringOfEvent,idEvent,stationManagement.nSlotBackoff11p(idEvent),timeManagement.timeNextTxRx11p(idEvent));
fclose(fid);

