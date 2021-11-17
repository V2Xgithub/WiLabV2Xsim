function [sinrManagement] = initLastPowerCV2X(timeManagement,stationManagement,sinrManagement,simParams,appParams,phyParams)

% If coexistence, I have to initialize the value of averageInterfFrom11pToLTE
if simParams.technology == 4
    sinrManagement.coex_averageSFinterfFrom11pToLTE = sinrManagement.coex_currentInterfFrom11pToLTE;
    % note: the following two parameters might be overwritten later, but with the same values 
    sinrManagement.instantThisPstartedCV2X = timeManagement.timeNow;
    sinrManagement.instantTheSINRaverageStartedCV2X = timeManagement.timeNow;
end

% If there is at least one C-V2X station transmitting, I have to initialize
% SINR values
if ~isempty(stationManagement.transmittingIDsCV2X)     
    RXpower_MHz_ofLTE = sinrManagement.P_RX_MHz(stationManagement.indexInActiveIDs_ofLTEnodes,stationManagement.indexInActiveIDs_ofLTEnodes);

    % Number of vehicles transmitting in the current subframe
    Ntx = length(stationManagement.transmittingIDsCV2X);

    % Initialization of SINRmanagement
    sinrManagement.neighPowerUsefulCV2X = zeros(Ntx,length(stationManagement.activeIDsCV2X)-1);
    sinrManagement.neighPowerInterfDataCV2X = zeros(Ntx,length(stationManagement.activeIDsCV2X)-1);
    sinrManagement.neighPowerInterfControlCV2X = zeros(Ntx,length(stationManagement.activeIDsCV2X)-1);
    sinrManagement.neighborsInterfFrom11pAverageLTE = zeros(Ntx,length(stationManagement.activeIDsCV2X)-1);
    sinrManagement.neighborsSINRaverageCV2X = zeros(Ntx,length(stationManagement.activeIDsCV2X)-1);
    sinrManagement.neighborsSINRsciAverageCV2X = zeros(Ntx,length(stationManagement.activeIDsCV2X)-1);
    sinrManagement.instantThisPstartedCV2X = timeManagement.timeNow;
    sinrManagement.instantTheSINRaverageStartedCV2X = timeManagement.timeNow;

    % Find not assigned BRid
    %indexNOT = (stationManagement.BRid(:,1)<=0);

    % Calculate BRidT = vector of BRid in the time domain
    %BRidT = ceil(stationManagement.BRid(:,1)/appParams.NbeaconsF);
    %BRidT(indexNOT) = -1;

    % Calculate BRidF = vector of BRid in the frequency domain
    %BRidF = mod(stationManagement.BRid(:,1)-1,appParams.NbeaconsF)+1;
    %BRidF(indexNOT) = -1;

    for i_tx = 1:Ntx

        % Find BRT and BRF in use by tx vehicle i
        %BRTtx = BRidT(stationManagement.transmittingIDsCV2X(i_tx));
        %BRFtx = BRidF(stationManagement.transmittingIDsCV2X(i_tx));       
        BRFtx = stationManagement.transmittingFusedLTE(i_tx);
        
        % Find neighbors of vehicle i
        indexNeighborOfVehicleTX = find(stationManagement.neighborsIDLTE(stationManagement.indexInActiveIDsOnlyLTE_OfTxLTE(i_tx),:));

        for j_neigh = indexNeighborOfVehicleTX

            % ID rx vehicle
            IDrx = stationManagement.neighborsIDLTE(stationManagement.indexInActiveIDsOnlyLTE_OfTxLTE(i_tx),j_neigh);
            RxPowerIDrx = RXpower_MHz_ofLTE(stationManagement.activeIDsCV2X==IDrx,stationManagement.indexInActiveIDsOnlyLTE_OfTxLTE);

            % Find BRT in use by rx vehicle j
            %BRTrx = BRidT(IDrx);

            % Useful received power by vehicle j
            C = RxPowerIDrx(i_tx);
            %C = RXpower_MHz_ofLTE(stationManagement.activeIDsCV2X==IDrx,stationManagement.indexInActiveIDsOnlyLTE_OfTxLTE(i_tx));

            % Initialize interfering power sums vector
            Isums = zeros(appParams.NbeaconsF,1);

            % Interference computation
            % Find other vehicles transmitting in the same subframe of
            % tx vehicle i
            if Ntx > 1 % otherwise there is only one transmitter - no interference
                for k = 1:Ntx %length(stationManagement.indexInActiveIDsOnlyLTE_OfTxLTE)
                    % If interferer is different from tx vehicle i and
                    % different from receiving vehicle j
                    if k~=i_tx && stationManagement.transmittingIDsCV2X(k)~=IDrx
                        % Find which BRF is used by the interferer k
                        %BRFInt = BRidF(stationManagement.transmittingIDsCV2X(k));
                        BRFInt = stationManagement.transmittingFusedLTE(k);
                        
                        % Find power from interfering vehicle k received
                        % by receiving vehicle j         
                        I = RxPowerIDrx(k);
                        %I = RXpower_MHz_ofLTE(stationManagement.activeIDsCV2X==IDrx,stationManagement.indexInActiveIDsOnlyLTE_OfTxLTE(k));
                        % Sum interference in that BRF
                        Isums(BRFInt,1) = Isums(BRFInt,1) + I;% THIS LINE
                    end
                end
            end

            % Find total interference using IBE
            ItotData = phyParams.IBEmatrixData(BRFtx,:)*Isums;
            ItotControl = phyParams.IBEmatrixControl(BRFtx,:)*Isums;

            % Check if the receiver j is transmitting on the same BRT
            % of transmitter i
            %if BRTtx==BRTrx
            if nnz(stationManagement.transmittingIDsCV2X==IDrx)                
                % Self-interference
                selfI = phyParams.Ksi*phyParams.P_ERP_MHz_CV2X(stationManagement.transmittingIDsCV2X(i_tx)); % does not include Gr
            else
                % No self-interference
                selfI = 0;
            end

            %% FROM VERSION 5.3.0
            % Interference from 11p, if present
            sinrManagement.neighborsInterfFrom11pAverageLTE(i_tx,j_neigh) = sinrManagement.coex_currentInterfFrom11pToLTE(IDrx);

            % SINR computation
            %SINR(i,j) = C / (PnRB + selfI + Itot);
            sinrManagement.neighPowerUsefulCV2X(i_tx,j_neigh) = C * phyParams.BwMHz_cv2xBR;
            sinrManagement.neighPowerInterfDataCV2X(i_tx,j_neigh) = (selfI + ItotData) * phyParams.BwMHz_cv2xBR;
            sinrManagement.neighPowerInterfControlCV2X(i_tx,j_neigh) = (selfI + ItotControl) * phyParams.BwMHz_cv2xBR;
                       
%             %% UP TO VERSION 5.2.10
%             % Interference from 11p, if present
%             Ifrom11p = sinrManagement.coex_currentInterfFrom11pToLTE(IDrx);
% 
%             % SINR computation
%             %SINR(i,j) = C / (PnRB + selfI + Itot);
%             sinrManagement.neighPowerUsefulLastLTE(i_tx,j_neigh) = C * phyParams.BwMHz_cv2xBR;
%             sinrManagement.neighPowerInterfLastLTE(i_tx,j_neigh) = (selfI + Itot) * phyParams.BwMHz_cv2xBR + Ifrom11p;
        end
    end
end