function printDebugKPI(fid,Time,StringOfEvent,distance,idEvent,pckTxOccurring,Earlier,Now)
% Print of: Time, event description, then per each station:
% ID, technology, state, current SINR (if LTE, first neighbor), useful power (if LTE, first neighbor),
% interfering power (if LTE, first neighbor), interfering power from
% the other technology (if LTE, first neighbor)

% to active this function, the start and the end of "updateKPI11p.m" part
% should be uncomment, and the line of calling this function should be
% uncomment
fprintf(fid,'%3.6f\t%s\t%d\t%d\t%d\t%d\t%d\n',Time,StringOfEvent,distance,idEvent,pckTxOccurring,Earlier,Now);
