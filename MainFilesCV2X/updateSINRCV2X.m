function sinrManagement = updateSINRCV2X(timeNow,stationManagement,sinrManagement,PnoiseData,PnoiseSCI,simParams,appParams)
% Calculates the average SINR to each receiving neighbor

if isempty(stationManagement.activeIDsCV2X)
    return
else
    transmittingIDsCV2X = stationManagement.transmittingIDsCV2X;
end

%% FROM VERSION 5.3.0

% Given:
%     sinrManagement.neighPowerUsefulCV2X = zeros(Ntx,length(stationManagement.activeIDsLTE)-1);
%     sinrManagement.neighPowerInterfLTE = zeros(Ntx,length(stationManagement.activeIDsLTE)-1);
%     sinrManagement.neighborsInterfFrom11pAverageLTE = zeros(Ntx,length(stationManagement.activeIDsLTE)-1);
%     sinrManagement.neighborsSINRaverageCV2X = zeros(Ntx,length(stationManagement.activeIDsLTE)-1);
%     sinrManagement.neighborsSINRsciAverageCV2X = zeros(Ntx,length(stationManagement.activeIDsLTE)-1);
%     sinrManagement.instantThisPstartedCV2X = timeManagement.timeNow;
%     sinrManagement.instantTheSINRaverageStartedCV2X = timeManagement.timeNow;

% If coexistence, I have also to update the average interference from 11p nodes
% to LTE nodes
if simParams.technology == constants.TECH_COEX_STD_INTERF
    sinrManagement.coex_averageTTIinterfFrom11pToLTE = (sinrManagement.coex_averageTTIinterfFrom11pToLTE .* (sinrManagement.instantThisPstartedCV2X-sinrManagement.instantTheSINRaverageStartedCV2X) + ... 
        sinrManagement.coex_currentInterfFrom11pToLTE .* (timeNow-sinrManagement.instantThisPstartedCV2X)) ./ (timeNow-sinrManagement.instantTheSINRaverageStartedCV2X);
end

if ~isempty(transmittingIDsCV2X)
    % Average interference from 11p nodes, if present (otherwise will emain zero)
    neighborsInterf11p = zeros(length(transmittingIDsCV2X),length(sinrManagement.neighPowerUsefulCV2X(1,:)));
    
    if simParams.technology == constants.TECH_COEX_STD_INTERF
        % This part converts the coex_averageSFinterfFrom11pToLTE
        % to stationManagement.neighborsIDLTE
        % TODO - could be optimized
        for iLTEtx = 1:length(transmittingIDsCV2X)
            for iInterf = 1:length(stationManagement.neighborsIDLTE(1,:))     
                if stationManagement.neighborsIDLTE(stationManagement.indexInActiveIDsOnlyLTE_OfTxLTE(iLTEtx),iInterf)<=0
                    break;
                end
                neighborsInterf11p(iLTEtx,iInterf) = sinrManagement.coex_averageTTIinterfFrom11pToLTE(stationManagement.neighborsIDLTE(stationManagement.indexInActiveIDsOnlyLTE_OfTxLTE(iLTEtx),iInterf));
            end
        end
    end
    
    % The average SINR for data is updated (Vittorio)
    sinrManagement.neighborsSINRaverageCV2X = sinrManagement.neighPowerUsefulCV2X ./ ...
        ( PnoiseData + sinrManagement.neighPowerInterfDataCV2X + neighborsInterf11p);

    % The average SINR for control is updated
    sinrManagement.neighborsSINRsciAverageCV2X = sinrManagement.neighPowerUsefulCV2X ./ ...
        ( PnoiseSCI + sinrManagement.neighPowerInterfControlCV2X + (2/(appParams.RBsBeacon/2)) * neighborsInterf11p);
else
    sinrManagement.neighborsSINRaverageCV2X = [];
    sinrManagement.neighborsSINRsciAverageCV2X = [];
end

sinrManagement.instantThisPstartedCV2X = timeNow;

% %% SINCE VERSION 5.2.10
% 
% % Given:
% % sinrManagement.neighPowerUsefulLastLTE
% % sinrManagement.neighPowerInterfLastLTE
% % sinrManagement.neighborsSINRaverageCV2X
% % sinrManagement.instantThisPstartedCV2X
% % sinrManagement.instantTheSINRaverageStartedCV2X
% 
% % % This part was without interference from IEEE 802.11p
% % Without 11p interference
% % sinrLast = sinrManagement.neighPowerUsefulLastLTE ./ ( Pnoise + sinrManagement.neighPowerInterfLastLTE);
% % 
% % neighborsSINRaverageCV2X = (sinrManagement.neighborsSINRaverageCV2X .* (sinrManagement.instantThisPstartedCV2X-sinrManagement.instantTheSINRaverageStartedCV2X) + ... 
% %     sinrLast .* (timeNow-sinrManagement.instantThisPstartedCV2X)) ./ (timeNow-sinrManagement.instantTheSINRaverageStartedCV2X);
% % %
% 
% % % This is the new version to include interference form IEEE 802.11p nodes
% % TODO: is it possible to optimize?
% if ~isempty(transmittingIDsLTE)
%     sinrLast = zeros(length(transmittingIDsLTE),length(sinrManagement.neighPowerUsefulLastLTE(1,:)));
%     sinrSciLast = zeros(length(transmittingIDsLTE),length(sinrManagement.neighPowerUsefulLastLTE(1,:)));
%     for iLTEtx = 1:length(transmittingIDsLTE)
%         for iInterf = 1:length(stationManagement.neighborsIDLTE(1,:))     
% 
%             if stationManagement.neighborsIDLTE(stationManagement.indexInActiveIDsOnlyLTE_OfTxLTE(iLTEtx),iInterf)>0                
%                 % Data
%                 sinrLast(iLTEtx,iInterf) = sinrManagement.neighPowerUsefulLastLTE(iLTEtx,iInterf) ./ ( Pnoise + sinrManagement.neighPowerInterfLastLTE(iLTEtx,iInterf) + sinrManagement.coex_currentInterfFrom11pToLTE(stationManagement.neighborsIDLTE(stationManagement.indexInActiveIDsOnlyLTE_OfTxLTE(iLTEtx),iInterf)));
%                 % SCI - 11p interference must be scaled down
%                 sinrSciLast(iLTEtx,iInterf) = sinrManagement.neighPowerUsefulLastLTE(iLTEtx,iInterf) ./ ( Pnoise + sinrManagement.neighPowerInterfLastLTE(iLTEtx,iInterf) + (2/(appParams.RBsBeacon/2)) * sinrManagement.coex_currentInterfFrom11pToLTE(stationManagement.neighborsIDLTE(stationManagement.indexInActiveIDsOnlyLTE_OfTxLTE(iLTEtx),iInterf)));
% %fp = fopen('temp.xls','a');
% %fprintf(fp,'%f\n',10*log10(sinrLast(iLTEtx,iInterf)));
% %fclose(fp);
%             end
%         end
%     end
% 
%     sinrManagement.neighborsSINRaverageCV2X = (sinrManagement.neighborsSINRaverageCV2X .* (sinrManagement.instantThisPstartedCV2X-sinrManagement.instantTheSINRaverageStartedCV2X) + ... 
%         sinrLast .* (timeNow-sinrManagement.instantThisPstartedCV2X)) ./ (timeNow-sinrManagement.instantTheSINRaverageStartedCV2X);    
% 
%     sinrManagement.neighborsSINRsciAverageCV2X = (sinrManagement.neighborsSINRsciAverageCV2X .* (sinrManagement.instantThisPstartedCV2X-sinrManagement.instantTheSINRaverageStartedCV2X) + ... 
%         sinrSciLast .* (timeNow-sinrManagement.instantThisPstartedCV2X)) ./ (timeNow-sinrManagement.instantTheSINRaverageStartedCV2X);        
% else
%     sinrManagement.neighborsSINRaverageCV2X = [];
%     sinrManagement.neighborsSINRsciAverageCV2X = [];
% end
% 
% % If coexistence, I have also to update the average interference from 11p nodes
% % to LTE nodes
% if simParams.technology == 4
%     sinrManagement.coex_averageSFinterfFrom11pToLTE = (sinrManagement.coex_averageSFinterfFrom11pToLTE .* (sinrManagement.instantThisPstartedCV2X-sinrManagement.instantTheSINRaverageStartedCV2X) + ... 
%         sinrManagement.coex_currentInterfFrom11pToLTE .* (timeNow-sinrManagement.instantThisPstartedCV2X)) ./ (timeNow-sinrManagement.instantTheSINRaverageStartedCV2X);
% end
% 
% sinrManagement.instantThisPstartedCV2X = timeNow;
