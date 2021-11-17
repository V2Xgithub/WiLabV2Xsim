function printDebugEvents(Time,StringOfEvent,idEvent)
% Function to be used in Debug to print the main events

% return

if idEvent<=0
    fprintf('Time=%3.6f, %s\n',Time,StringOfEvent);
else
    fprintf('Time=%3.6f, %s, idEvent=%d\n',Time,StringOfEvent,idEvent);
end    
    
