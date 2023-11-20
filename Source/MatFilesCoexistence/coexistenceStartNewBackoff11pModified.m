function [nSlot, timeNextTxRx] = coexistenceStartNewBackoff11pModified(timeNow,CW,tAifs,tSlot,subframeIndex,superframeLength)
% Function that performs backoff in IEEE 802.11p

CWmodified = max(1,CW*floor(10*(superframeLength-subframeIndex)/superframeLength));
nSlot = randi(CWmodified);
timeNextTxRx = round(timeNow + tAifs + nSlot * tSlot, 10);

end