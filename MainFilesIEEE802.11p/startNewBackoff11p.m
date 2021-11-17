function [nSlot, timeNextTxRx] = startNewBackoff11p(timeNow,CW,tAifs,tSlot)
% Function that performs backoff in IEEE 802.11p

nSlot = randi(CW);
timeNextTxRx = timeNow + tAifs + nSlot * tSlot;

end