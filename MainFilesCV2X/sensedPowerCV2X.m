function sensedPower_MHz = sensedPowerCV2X(stationManagement,sinrManagement,appParams,phyParams)
% This function calculates the power sensed by LTE nodes in a subframe
% The output does not include the interference from 11p nodes, if present

NbeaconsF = appParams.NbeaconsF;
sensedPower_MHz = zeros(NbeaconsF,length(stationManagement.activeIDsCV2X));

if ~isempty(stationManagement.transmittingIDsCV2X)

    P_RX_MHz_LTE = sinrManagement.P_RX_MHz(stationManagement.indexInActiveIDs_ofLTEnodes,stationManagement.indexInActiveIDs_ofLTEnodes);
    activeIDsCV2X = stationManagement.activeIDsCV2X;

    % Calculate the beacon resources used in the time and frequency domains
    % Find not assigned BRid
    %idNOT = (stationManagement.BRid(:,1)<=0);
    % Calculate BRidT = vector of BRid in the time domain
    %BRidT = ceil(BRid/NbeaconsF);
    %BRidT(idNOT) = -1;
    % Calculate BRidF = vector of BRid in the frequency domain
    %BRidF = mod(stationManagement.BRid(:,1)-1,NbeaconsF)+1;
    %BRidF(idNOT) = -1;
    
    % Cycle that calculates per each vehicle the sensed power
    for indexSensingV = 1:length(activeIDsCV2X)
        % Cycle per each resource (in the current subframe)
        % Init the vector of received power in this beacon resource
        rxPsums_MHz = zeros(NbeaconsF,1);

        % Cycle over the vehicles transmitting in the same subframe
        for iTx = 1:length(stationManagement.transmittingIDsCV2X)                
        %for indexSensedV = (stationManagement.indexInActiveIDsOnlyLTE_OfTxLTE)'
            indexSensedV = stationManagement.indexInActiveIDsOnlyLTE_OfTxLTE(iTx);
            % Find which BRF is used by the interferer
            %BRFsensedV = BRidF(activeIDsCV2X(indexSensedV));
            BRFsensedV = stationManagement.transmittingFusedLTE(iTx);

            % Separate all other vehicles to itself
            if activeIDsCV2X(indexSensedV)~=activeIDsCV2X(indexSensingV)
                % If not itself, add the received power
                rxPsums_MHz(BRFsensedV) = rxPsums_MHz(BRFsensedV) + P_RX_MHz_LTE(indexSensingV,indexSensedV);
            else 
                % Including itself allows simulating full duplex devices
                % If itself, add the Tx power multiplied by Ksi (set to inf 
                %       if the devices are half duplex)
                rxPsums_MHz(BRFsensedV) = rxPsums_MHz(BRFsensedV) + phyParams.Ksi*phyParams.P_ERP_MHz_CV2X(activeIDsCV2X(indexSensingV));
            end
        end
        % Find total received power using IBE
        % Including possible interference from 11p (note: the
        % interfering power is already calculated per BR)
        for BRFi = 1:NbeaconsF
            sensedPower_MHz(BRFi,indexSensingV) = phyParams.IBEmatrixData(BRFi,:)*rxPsums_MHz; 
        end
    end
end