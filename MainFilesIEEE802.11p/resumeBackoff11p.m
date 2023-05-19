function timeNextTxRx = resumeBackoff11p(timeNow,nSlotBackoff,tAifs,tSlot)
% The backoff is resumed after having been freezed

timeNextTxRx = round(timeNow + tAifs + nSlotBackoff * tSlot, 10);

end