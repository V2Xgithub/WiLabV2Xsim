function sinrManagement = updateSINR11p(timeManagement,sinrManagement,stationManagement,phyParams)
% The average SINR is updated

%% FROM VERSION 5.3.0

% The average interference is updatedUpdate as the weighted average
% between (i) the interference calculated from 'instantThisSINRavStarted'
% and 'instantThisPrStarted', presently saved in 'interfAverage'
% and (ii) the interference calculated since the last Pr calculation,
% i.e., from 'instantThisPrStarted', to now
% The useful power is calculated as the power received from the
% node stored in 'idFromWhichRx'
% The interfering power is calculated as the overall power
% received from the nodes with State==constants.V_STATE_11P_TX minus the useful power
% The SINR is updated each time based on the average interference

for idVehicle = stationManagement.activeIDs(stationManagement.vehicleState(stationManagement.activeIDs)==constants.V_STATE_11P_RX)'
    if sinrManagement.idFromWhichRx11p(idVehicle)==idVehicle
        sinrManagement.interfAverage11p(idVehicle) = 0;
        sinrManagement.sinrAverage11p(idVehicle) = 0;
    else   
        interfLast = sinrManagement.rxPowerInterfLast11p(idVehicle) ...
            + sinrManagement.coex_InterfFromLTEto11p(idVehicle);
        
        sinrManagement.interfAverage11p(idVehicle) = (sinrManagement.interfAverage11p(idVehicle) .* (sinrManagement.instantThisSINRstarted11p(idVehicle)-sinrManagement.instantThisSINRavStarted11p(idVehicle)) + ...
               interfLast .* (timeManagement.timeNow-sinrManagement.instantThisSINRstarted11p(idVehicle))) ...
            ./ (timeManagement.timeNow-sinrManagement.instantThisSINRavStarted11p(idVehicle));

        % The following optional part is used to take into account for
        % strong interference over a few OFDM symbols, which is strongly
        % corrupting IEEE 802.11p transmissions due to missing interleaving
        % in the time domain
        if phyParams.rilModel11p
           % RIL
            RIL_dB =  10*log10( (sinrManagement.rxPowerInterfLast11p(idVehicle) + sinrManagement.coex_InterfFromLTEto11p(idVehicle)) / sinrManagement.rxPowerUsefulLast11p(idVehicle) );        
            time_interf = (timeManagement.timeNow-sinrManagement.instantThisSINRstarted11p(idVehicle));
            % % Fitting for RIL vs time model
            % tRILthreshold_us = a*exp(b*RIL_dB)+c*exp(d*RIL_dB);
            % where a = 0.7808, b = -1.268, c = 4.017, d = -0.07585;
            tRILthreshold_us = 0.7808*exp((-1.268)*RIL_dB)+4.017*exp((-0.07585)*RIL_dB);
            if RIL_dB>0 && time_interf > tRILthreshold_us*1e-6
                % Interference is too high
                sinrManagement.interfAverage11p(idVehicle) = inf;
            end
        end
        
        sinrManagement.sinrAverage11p(idVehicle) = sinrManagement.rxPowerUsefulLast11p(idVehicle) / ...
            (phyParams.Pnoise_MHz * phyParams.BwMHz + sinrManagement.interfAverage11p(idVehicle));

        sinrManagement.instantThisSINRstarted11p(idVehicle) = timeManagement.timeNow;        
    end
end            


%% UP TO VERSION 5.2.10

% % The average SINR is updatedUpdate as the weighted average
% % between (i) the SINR calculated from 'instantThisSINRavStarted'
% % and 'instantThisPrStarted', presently saved in 'sinrAverage'
% % and (ii) the SINR calculated since the last Pr calculation,
% % i.e., from 'instantThisPrStarted', to now
% % The useful power is calculated as the power received from the
% % node stored in 'idFromWhichRx'
% % The interfering power is calculated as the overall power
% % received from the nodes with State==3 minus the useful power
% 
% for idVehicle = stationManagement.activeIDs(stationManagement.vehicleState(stationManagement.activeIDs)==9)'
%     if sinrManagement.idFromWhichRx11p(idVehicle)==idVehicle
%         sinrManagement.sinrAverage11p(idVehicle) = 0;
%     else        
%         sinrLast = sinrManagement.rxPowerUsefulLast11p(idVehicle) / ...
%             (phyParams.Pnoise_MHz * phyParams.BwMHz + ...
%             sinrManagement.rxPowerInterfLast11p(idVehicle) ...
%             + sinrManagement.coex_InterfFromLTEto11p(idVehicle) );
%         if sinrLast<0
%             error('sinrLast of vehicle=%d (state=%d), receiving from=%d (state=%d) < 0',idVehicle,stationManagement.vehicleState(idVehicle),...
%                 sinrManagement.idFromWhichRx11p(idVehicle),stationManagement.vehicleState(sinrManagement.idFromWhichRx11p(idVehicle)));
%         end
%         sinrManagement.sinrAverage11p(idVehicle) = ...
%             (sinrManagement.sinrAverage11p(idVehicle) .* (sinrManagement.instantThisSINRstarted11p(idVehicle)-sinrManagement.instantThisSINRavStarted11p(idVehicle)) + ...
%                sinrLast .* (timeManagement.timeNow-sinrManagement.instantThisSINRstarted11p(idVehicle))) ...
%             ./ (timeManagement.timeNow-sinrManagement.instantThisSINRavStarted11p(idVehicle));
% 
%         if phyParams.rilModel11p
%             % RIL
%             RIL =  10*log10( (sinrManagement.rxPowerInterfLast11p(idVehicle) + sinrManagement.coex_InterfFromLTEto11p(idVehicle)) / sinrManagement.rxPowerUsefulLast11p(idVehicle) );        
%             time_interf = (timeManagement.timeNow-sinrManagement.instantThisSINRstarted11p(idVehicle));
%             if RIL>0 && RIL>3*log2( 6e-6./ time_interf)
%                 % Interference is too high
%                 sinrManagement.sinrAverage11p(idVehicle) = -inf;            
%             end
%         end
%         
%         sinrManagement.instantThisSINRstarted11p(idVehicle) = timeManagement.timeNow;        
%     end
% end    
