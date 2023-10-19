function printVehiclePositionsToFile(args)
    arguments
        args.outputFolder string
        args.simID (1, 1) double {mustBeInteger}
        args.time double {mustBeNonnegative}
        args.positionX (1, :) double {mustBeReal}
        args.positionY (1, :) double {mustBeReal}
        args.vehicles (1, :) double {mustBeInteger, mustBePositive}
        args.speed (1, :) double {mustBeNonnegative, mustBeReal}
        args.heading (1, :) double
    end
    filename = sprintf("%s/positions-%d.csv", args.outputFolder, args.simID);
    if ~isfile(filename)
        f = fopen(filename, 'w');
        fprintf(f, 'Time,Vehicles,X,Y,Speed,Heading\n');
        fclose(f);
    end    
    f = fopen(filename, 'a');
    fprintf(f, '%.3f,%s,%s,%s,%s,%s\n', args.time, num2str(args.vehicles), num2str(args.positionX), num2str(args.positionY), num2str(args.speed), num2str(args.heading));
    fclose(f);
end