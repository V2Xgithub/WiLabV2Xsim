function printSpeedToFile(time,IDvehicle,speedNow,maxID,outParams)

if ~isempty(IDvehicle)
    
    filename = sprintf('%s/speed_stats_%d.xls',outParams.outputFolder,outParams.simID);

    fid = fopen(filename,'a');
    
    fprintf(fid,'%f',time);

    speedToPrint = zeros(1,maxID);    
    speedToPrint(IDvehicle) = speedNow;
    
    for i=1:length(speedToPrint)
        fprintf(fid,'\t%.2f',speedToPrint*3.6);
    end
    fprintf(fid,'\n');
    fclose(fid);

end