function interfFromEnergySignals = coexistenceInterferenceOfEnergySignalsBeforeSuperFrame(timeManagement,stationManagement,sinrManagement,phyParams,simParams,simValues)

%% From v5.2.10
% All LTE nodes sense if the channel is busy
% If they sense the channel busy they do not transmit the energy signal

% Threshold of -94 dBm per subchannel
thresh_subchannel = 10^((-94-30)/10); % fixed in this version
thresh_perBeaconResource = thresh_subchannel * phyParams.NsubchannelsBeacon;
% Sensed power
% Note: coex_averageSFinterfFrom11pToLTE is per beacon resource
sensedPower = sinrManagement.coex_averageTTIinterfFrom11pToLTE(stationManagement.activeIDsCV2X);

% Nodes that sense the channel as idle are selected
sensedIdle = (sensedPower < thresh_perBeaconResource);

% Index of those nodes are saved in a vector and used to calculate the
% energy signal
indexOfTxEnergySignals = stationManagement.indexInActiveIDs_ofLTEnodes(sensedIdle);
interfFromEnergySignals = zeros(simValues.maxID,1);
interfFromEnergySignals(stationManagement.activeIDs) = phyParams.BwMHz_cv2xBR * sum((sinrManagement.P_RX_MHz(:,indexOfTxEnergySignals)),2);

%% Up to v5.2.9
%interfFromEnergySignals = phyParams.BwMHz_cv2xBR * sum((sinrManagement.P_RX_MHz(:,stationManagement.indexInActiveIDs_ofLTEnodes)),2);
