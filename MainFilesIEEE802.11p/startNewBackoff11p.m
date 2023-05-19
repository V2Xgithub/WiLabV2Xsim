function [nSlot, timeNextTxRx] = startNewBackoff11p(timeNow,CW,tAifs,tSlot)
% Function that performs backoff in IEEE 802.11p

nSlot = randi(CW);
timeNextTxRx = round(timeNow + tAifs + nSlot * tSlot, 10);

