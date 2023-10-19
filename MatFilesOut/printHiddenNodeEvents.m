function [] = printHiddenNodeEvents(args)
    % Prints the hiddenNodeEvents member (of the outputValue struct) to a
    % csv file
    % Format is just n rows of events, each row corresponds to number of
    % events counted in a specified awareness range
    arguments
        args.outputFolder string
        args.simId (1, 1) double
        args.hiddenNodeEvents (:, 1) double
    end
    base_filename = sprintf("hiddennode-%d.csv", args.simId);
    outputFolder = args.outputFolder;
    if isfolder(outputFolder) == false
        mkdir(outputFolder)
    end
    writematrix(args.hiddenNodeEvents, sprintf('%s/%s', outputFolder, base_filename));
end
