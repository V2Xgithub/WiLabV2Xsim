function printDebugBRofMode4(timeManagement,idvehicle,BR,outParams)

%if timeManagement.timeNow<10
   return;
%end

filename = sprintf('%s/_DebugBRofMode4_%d.xls',outParams.outputFolder,outParams.simID);
fid = fopen(filename,'a');

fprintf(fid,'%f\t%d\t%d\n',timeManagement.timeNow,idvehicle,BR);

fclose(fid);