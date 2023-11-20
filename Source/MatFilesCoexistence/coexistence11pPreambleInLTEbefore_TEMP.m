function interfFromAdditionalPreamble = coexistence11pPreambleInLTEbefore_TEMP(timeManagement,stationManagement,sinrManagement,phyParams,appParams,simValues)

% BR adopted in the time domain (i.e., TTI)
BRidT = ceil((stationManagement.BRid)/appParams.NbeaconsF);
BRidT(stationManagement.BRid<=0)=-1;

% Upcoming subframe
upcoming_subframe = (floor(timeManagement.timeNow/phyParams.Tsf)+1)+1;

% Find IDs of vehicles that are transmitting in the next subframe
IDvehicleTXLTEnextSF = find(BRidT == (mod((upcoming_subframe-1),appParams.NbeaconsT)+1), 1);

if ~isempty(IDvehicleTXLTEnextSF)
    indexVehicleTXLTEnextSF = zeros(length(IDvehicleTXLTEnextSF),1);
    for i=1:length(IDvehicleTXLTEnextSF)
        indexVehicleTXLTEnextSF(i) = find(stationManagement.activeIDs==IDvehicleTXLTEnextSF(i));
    end
	interfFromAdditionalPreamble = phyParams.BwMHz_cv2xBR * sum((sinrManagement.P_RX_MHz(:,indexVehicleTXLTEnextSF)),2);
    % The value is set to infinite for LTE nodes as it should not have impact
    % in such case
    interfFromAdditionalPreamble(stationManagement.activeIDsCV2X) = inf;
    return;
end
% If no LTE node will transmit in the next subframe, it should remain zero
interfFromAdditionalPreamble = zeros(simValues.maxID,1);
