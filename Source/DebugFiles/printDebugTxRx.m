function printDebugTxRx(time,v_id, event, stationManagement,sinrManagement,outParams)
%PRINTDEBUGTXRX Summary of this function goes here
%   Detailed explanation goes here
filename = sprintf('%s/_DebugTxRx_%d.xls',outParams.outputFolder,outParams.simID);
fid = fopen(filename, "a");
fprintf(fid,"%f,%d,%s\n",time,v_id,event);
fclose(fid);

end

