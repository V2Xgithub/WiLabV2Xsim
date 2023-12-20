function [sinrManagement,stationManagement,timeManagement,outputValues] = ...
            mainCV2XttiStarts(appParams,phyParams,timeManagement,sinrManagement,stationManagement,simParams,simValues,outParams,outputValues)
% a C-V2X TTI (time transmission interval) starts

% Compute the number of elapsed TTIs (Vittorio) (previously subframes)
% timeManagement.elapsedTime_subframes = floor((timeManagement.timeNow+1e-7)/phyParams.Tsf) + 1;
timeManagement.elapsedTime_TTIs = floor((timeManagement.timeNow+1e-7)/phyParams.TTI) + 1;

% %% Before v.5.4.16
% % BR adopted in the time domain (i.e., TTI)
% BRidT = ceil((stationManagement.BRid(:,1))/appParams.NbeaconsF);
% BRidT(stationManagement.BRid(:,1)<=0)=-1;
% 
% % Find IDs of vehicles that are currently transmitting
% stationManagement.transmittingIDsLTE = find(BRidT == (mod((timeManagement.elapsedTime_subframes-1),appParams.NbeaconsT)+1));
% % Remove those that do not have packets in the queue (occurs at the
% % beginning of the simulation)
% stationManagement.transmittingIDsLTE = stationManagement.transmittingIDsLTE.*(stationManagement.pckBuffer(stationManagement.transmittingIDsLTE)>0);
% stationManagement.transmittingIDsLTE(stationManagement.transmittingIDsLTE==0) = [];
% % The instant this packet was generated is saved - it is needed because a
% % new packet might be generated during this subframe and thus overwrite the
% % content of timeLastPacket - this was causing an inaccuracy in the KPIs
% stationManagement.transmittingFusedLTE = mod(stationManagement.BRid(stationManagement.transmittingIDsLTE,1)-1,appParams.NbeaconsF)+1;
% %%

%% From v.5.4.16
stationManagement.transmittingIDsCV2X = [];
stationManagement.hasTransmissionThisSlot=zeros(length(stationManagement.activeIDsCV2X),1);
iTransmitting = 1;
currentT = (mod((timeManagement.elapsedTime_TTIs-1),appParams.NbeaconsT)+1);
idLteHasPck = stationManagement.activeIDsCV2X(stationManagement.pckBuffer(stationManagement.activeIDsCV2X) >= 1);
for idLte = idLteHasPck'    
    attemptToDo = stationManagement.pckNextAttempt(idLte);
    if ceil((stationManagement.BRid(idLte,attemptToDo))/appParams.NbeaconsF)==currentT
        stationManagement.transmittingIDsCV2X(iTransmitting) = idLte;
        stationManagement.transmittingFusedLTE(iTransmitting) = mod((stationManagement.BRid(idLte,attemptToDo))-1,appParams.NbeaconsF)+1;
        iTransmitting = iTransmitting + 1;
        % DEBUG TX-RX
        % printDebugTxRx(timeManagement.timeNow,idLte,'NR Tx started',stationManagement,sinrManagement,outParams);
    end
end
% hasTransmissionThisSlot introduced from version 6.2
stationManagement.hasTransmissionThisSlot(ismember(stationManagement.activeIDsCV2X,stationManagement.transmittingIDsCV2X))=1;
%%

timeManagement.timeGeneratedPacketInTxLTE(stationManagement.transmittingIDsCV2X) = timeManagement.timeLastPacket(stationManagement.transmittingIDsCV2X);

if ~isempty(stationManagement.transmittingIDsCV2X)     
    % Find index of vehicles that are currently transmitting
    stationManagement.indexInActiveIDsOnlyLTE_OfTxLTE = zeros(length(stationManagement.transmittingIDsCV2X),1);
    stationManagement.indexInActiveIDs_OfTxLTE = zeros(length(stationManagement.transmittingIDsCV2X),1);

    [~, stationManagement.indexInActiveIDsOnlyLTE_OfTxLTE] = ismember(stationManagement.transmittingIDsCV2X, stationManagement.activeIDsCV2X);
    [~, stationManagement.indexInActiveIDs_OfTxLTE] = ismember(stationManagement.transmittingIDsCV2X, stationManagement.activeIDs);

end

% Initialization of the received power
[sinrManagement] = initLastPowerCV2X(timeManagement,stationManagement,sinrManagement,simParams,appParams,phyParams);

% COEXISTENCE IN THE SAME BAND
if simParams.technology == constants.TECH_COEX_STD_INTERF      
    [timeManagement,stationManagement,sinrManagement,outputValues] = coexistenceAtLTEsubframeStart(timeManagement,sinrManagement,stationManagement,appParams,simParams,simValues,phyParams,outParams,outputValues);    
end
    
% Remove the packet from the queue
% the packet is removed from the queue after the last transmission.
% If the last transmission is disabled (BRids=-1) the packet remains in the queue.
% At the next generation an of overflow will occur, which will bring back
% the pckBuffer to one and properly account for the correct/incorrect reception of the packet.
% This has been done to allow the possibility of allowing the possibility
% of triggering retransmissions
if ~isempty(stationManagement.transmittingIDsCV2X)
    stationManagement.pckTxOccurring(stationManagement.transmittingIDsCV2X) = stationManagement.pckNextAttempt(stationManagement.transmittingIDsCV2X);
 	stationManagement.pckNextAttempt(stationManagement.transmittingIDsCV2X) = stationManagement.pckNextAttempt(stationManagement.transmittingIDsCV2X) + 1;
    txIDlastTx = stationManagement.transmittingIDsCV2X(stationManagement.pckNextAttempt(stationManagement.transmittingIDsCV2X)>stationManagement.cv2xNumberOfReplicas(stationManagement.transmittingIDsCV2X));
    stationManagement.pckBuffer(txIDlastTx) = stationManagement.pckBuffer(txIDlastTx)-1;
    % reset of pckReceive and cumulativeSINR
    stationManagement.pckReceived(:,stationManagement.transmittingIDsCV2X(stationManagement.pckTxOccurring(stationManagement.transmittingIDsCV2X)==1)) = 0;
    sinrManagement.cumulativeSINR(:,stationManagement.transmittingIDsCV2X(stationManagement.pckTxOccurring(stationManagement.transmittingIDsCV2X)==1)) = 0;
end

