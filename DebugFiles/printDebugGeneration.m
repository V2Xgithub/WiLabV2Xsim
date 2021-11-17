function printDebugGeneration(timeManagement,idEvent,positionManagement,outParams)

%if Time<4 || Time>4.2
%if Time>0.2
return;
%end

if idEvent>0
    
    filename = sprintf('%s/_DebugGen_%d.xls',outParams.outputFolder,outParams.simID);

    fid = fopen(filename,'a');

    fprintf(fid,'%f\t%d\t%f\t%f\n',timeManagement.timeNow,idEvent,positionManagement.XvehicleReal(idEvent),timeManagement.timeNextPacket(idEvent));

    fclose(fid);

end