function timeNextTxRx = resumeBackoff11p(timeNow,nSlotBackoff,tAifs,tSlot)
% The backoff is resumed after having been freezed

timeNextTxRx = timeNow + tAifs + nSlotBackoff * tSlot;

end