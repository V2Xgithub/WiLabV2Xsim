function nSlotBackoff = freezeBackoff11p(timeNow,timeNextTxRx,tSlot,nSlotBackoff)
% The backoff counter is freezed

% a small interval of -1e-9 is added for the problems with floating point
% numbers

nSlotBackoff = max( min(ceil((timeNextTxRx-timeNow-1e-9)/tSlot),nSlotBackoff) ,0);
