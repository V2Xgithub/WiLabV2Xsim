function [Nwalls,Nsteps,granularity] = computeGrid(X1,Y1,X2,Y2,StepMap,GridMap,channelModel)
% Function to compute the number of walls crossed by the signal (Nwalls)
% and the number of steps inside the buildings (Nsteps)

granularity = 5;                              % Meters for each step
StepSize = granularity/StepMap;              % Step used for computation

% Initialize output parameters
Nwalls = 0;
Nsteps = 0;

% Check if vehicles are on the road, otherwise return an error
if ~GridMap(floor(Y1),floor(X1)) || ~GridMap(floor(Y2),floor(X2))
    error('Vehicle is where the road is missing. Impossible!\n');
end

% Find the difference between the coordinates
Xdiff = abs(X2-X1);
Ydiff = abs(Y2-Y1);

if Xdiff>=Ydiff && Xdiff && Ydiff
    % Start the smallest coordinate
    if X1<X2
        Xstart = X1;
        Ystart = Y1;
        Xend = X2;
        Yend = Y2;
    else
        Xstart = X2;
        Ystart = Y2;
        Xend = X1;
        Yend = Y1;
    end
    % Initialize propagation pixel condition
    LastPixelWasRoad = 1;
    % Start computation along the path
    for X = (Xstart+StepSize):StepSize:Xend
        % Find Y coordinate on the line that connects the two points
        Y = (((X-Xstart)/(Xend-Xstart))+(Ystart/(Yend-Ystart)))*(Yend-Ystart);
        % If there is a building
        if ~GridMap(floor(Y),floor(X))
            if channelModel==0 %winnerModel
                Nwalls = 1;
                return;
            end
            % If previous pixel was road
            if LastPixelWasRoad
                % Increment number of walls
                Nwalls = Nwalls+1;
            end
                % Increment steps inside building
                Nsteps = Nsteps+1;
                % Update last pixel with building
                LastPixelWasRoad = 0;
        else
            % If previous pixel was building
            if ~LastPixelWasRoad
                % Increment number of walls
                Nwalls = Nwalls+1;
            end
        end
    end
elseif Xdiff<Ydiff && Xdiff && Ydiff
    % Start from the smallest coordinate
    if Y1<Y2
        Xstart = X1;
        Ystart = Y1;
        Xend = X2;
        Yend = Y2;
    else
        Xstart = X2;
        Ystart = Y2;
        Xend = X1;
        Yend = Y1;
    end
    % Initialize propagation pixel condition
    LastPixelWasRoad = 1;
    % Start computation along the path
    for Y = (Ystart+StepSize):StepSize:Yend
        % Find X coordinate on the line that connects the two points
        X = (((Y-Ystart)/(Yend-Ystart))+(Xstart/(Xend-Xstart)))*(Xend-Xstart);
        % If there is a building
        if ~GridMap(floor(Y),floor(X))
            if channelModel==0 %winnerModel
                Nwalls = 1;
                return;
            end
            % If previous pixel was road
            if LastPixelWasRoad
                % Increment number of walls
                Nwalls = Nwalls+1;
            end
                % Increment steps inside building
                Nsteps = Nsteps+1;
                % Update last pixel with building
                LastPixelWasRoad = 0;
        else
            % If previous pixel was building
            if ~LastPixelWasRoad
                % Increment number of walls
                Nwalls = Nwalls+1;
            end
        end
    end
elseif Xdiff && ~Ydiff
    % Start from the center of the smallest coordinate
    if X1<X2
        Xstart = X1;
        Ystart = Y1;
        Xend = X2;
    else
        Xstart = X2;
        Ystart = Y2;
        Xend = X1;
    end
    % Initialize propagation pixel condition
    LastPixelWasRoad = 1;
    % Start computation along the path
    for X = (Xstart+StepSize):StepSize:Xend
        % Find Y coordinate on the line that connects the two points
        Y = Ystart;
        % If there is a building
        if ~GridMap(floor(Y),floor(X))
            if channelModel==0 %winnerModel
                Nwalls = 1;
                return;
            end
            % If previous pixel was road
            if LastPixelWasRoad
                % Increment number of walls
                Nwalls = Nwalls+1;
            end
                % Increment steps inside building
                Nsteps = Nsteps+1;
                % Update last pixel with building
                LastPixelWasRoad = 0;
        else
            % If previous pixel was building
            if ~LastPixelWasRoad
                % Increment number of walls
                Nwalls = Nwalls+1;
            end
        end
    end
elseif ~Xdiff && Ydiff
    % Start from the center of the smallest coordinate
    if Y1<Y2
        Xstart = X1;
        Ystart = Y1;
        Yend = Y2;
    else
        Xstart = X2;
        Ystart = Y2;
        Yend = Y1;
    end
    % Initialize propagation pixel condition
    LastPixelWasRoad = 1;
    % Start computation along the path
    for Y = (Ystart+StepSize):StepSize:Yend
        % Find X coordinate on the line that connects the two points
        X = Xstart;
        % If there is a building
        if ~GridMap(floor(Y),floor(X))
            if channelModel==0 %winnerModel
                Nwalls = 1;
                return;
            end
            % If previous pixel was road
            if LastPixelWasRoad
                % Increment number of walls
                Nwalls = Nwalls+1;
            end
                % Increment steps inside building
                Nsteps = Nsteps+1;
                % Update last pixel with building
                LastPixelWasRoad = 0;
        else
            % If previous pixel was building
            if ~LastPixelWasRoad
                % Increment number of walls
                Nwalls = Nwalls+1;
            end
        end
    end
end

end