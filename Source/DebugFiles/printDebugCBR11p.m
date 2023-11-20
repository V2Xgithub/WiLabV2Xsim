function printDebugCBR11p(Time,StringOfEvent,idEvent,outParams)
% Print of: Time, event description, then per each station:
% ID, technology, state, current SINR (if LTE, first neighbor), useful power (if LTE, first neighbor),
% interfering power (if LTE, first neighbor), interfering power from
% the other technology (if LTE, first neighbor)


filename = sprintf('%s/_DebugCBR11p_%d.xls',outParams.outputFolder,outParams.simID);
fid = fopen(filename,'r');
if fid==-1
    fid = fopen(filename,'w');
    fprintf(fid,'Time\tEvent\tVehicle\n');
end
fclose(fid);
if ismember(187,idEvent)
    index = idEvent==187;
    fid = fopen(filename,'a');
    
    fprintf(fid,'%3.6f\t%s\t%d\n',Time,StringOfEvent,idEvent(index));
    
    fclose(fid);
end
