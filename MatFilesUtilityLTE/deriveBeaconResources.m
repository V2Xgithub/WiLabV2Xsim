function [appParams,phyParams,varargin] = deriveBeaconResources(simParams,appParams,phyParams,fileCfg,varargin)
% Function used to derive the beacon resources

if simParams.mode5G == constants.MODE_LTE    % Calculation for 4G case
    
    % Call function to find the total number of RBs in the frequency domain per Tslot
    phyParams.RBsFrequency = RBtable(phyParams.BwMHz);

    % Number of RBs allocated to the Cooperative Awareness (V2V)
    appParams.RBsFrequencyV2V = floor(phyParams.RBsFrequency*(appParams.resourcesV2V/100));

    % % Find the total number of RBs per subframe
    phyParams.RBsSubframe = phyParams.RBsFrequency*(phyParams.Tsf/phyParams.Tslot);

    % % Number of RBs allocated to the Cooperative Awareness
    appParams.RBsSubframeBeaconing = appParams.RBsFrequencyV2V*(phyParams.Tsf/phyParams.Tslot);

    % Call function to find the number of RBs needed to carry a beacon and minimum SINR
    appParams.beaconSizeBits = appParams.beaconSizeBytes*8;
    [appParams.RBsBeacon, phyParams.sinrThresholdCV2X_LOS_dB,phyParams.NbitsHz,phyParams.R,phyParams.Qm] = findRBsBeaconSINRmin(phyParams.MCS_LTE,appParams.beaconSizeBits,phyParams.TTI, phyParams.BwMHz);

elseif simParams.mode5G == constants.MODE_5G  % Calculation for 5G case
    
    % Call function to find the total number of RBs in the frequency domain per Tslot in 5G
    phyParams.RBsFrequency = RBtable_5G(phyParams.BwMHz,phyParams.SCS_NR);
    
    % Find the total number of RBs per subframe
    % RBs are defined on a time base of a slot
    phyParams.RBsSubframe = phyParams.RBsFrequency*(phyParams.Tsf/phyParams.Tslot_NR);
    
    % Call function to find the number of subchannels needed to carry a beacon and minimum SINR
    appParams.beaconSizeBits = appParams.beaconSizeBytes*8;
    [phyParams.NsubchannelsFrequency,phyParams.NsubchannelsBeacon,...
        appParams.RBsBeacon,phyParams.sinrThreshold5G_LOS_dB,...
        phyParams.NbitsHz,phyParams.R,phyParams.Qm] = findRBsBeaconSINRmin_5G(phyParams,appParams.beaconSizeBits);
    
    % Copy value of threshold in the 4G variable
    phyParams.sinrThresholdCV2X_LOS_dB = phyParams.sinrThreshold5G_LOS_dB;
    
    % Number of RBs allocated to the Cooperative Awareness (V2V)
    appParams.RBsFrequencyV2V = floor(phyParams.RBsFrequency*(appParams.resourcesV2V/100));
    
else
    error("Wrong value on mode5G")
    
end
    
    
%% SINR
% At this point, in phyParams.gammaMinLTE_dB / phyParams.gammaMinLTE the
% automatic value is stored - it might be overwritten in the following
% lines
if phyParams.PERcurves == true
    % If PER vs. SINR curves are used, the vector of SINR thresholds must be set
    % Set the file name
    % It includes the number of resource block pairs used by the packet, to
    % cope with adjacent/non-adjacent and various suchannel sizes
    fileName = sprintf('%s/PER_%s_MCS%d_%dB.txt',phyParams.folderPERcurves,'LTE',phyParams.MCS_LTE,appParams.beaconSizeBytes);
    [phyParams.sinrVectorCV2X_LOS_dB,~,~,~,sinrInterp,perInterp] = readPERtable(fileName,10000);
    %[phyParams.sinrVectorCV2X_LOS_dB,perVectorLTE,~,~,sinrInterp,perInterp] = readPERtable(fileName,10000);
    %% DEBUG PER vs. SINR curves
    %plot(phyParams.sinrVectorCV2X_LOS_dB,perVectorLTE,'pc');
    %hold on
    %plot(10*log10(sinrInterp),perInterp,'.k');
    %
    % Calculate the sinrThreshold, corresponding to 90% PER
    phyParams.sinrThresholdCV2X_LOS_dB = 10*log10( sinrInterp(find(perInterp>=0.9,1)) );
    
    if strcmp(fileCfg,'Urban3GPP.cfg')
        %NLOS
        fileName = sprintf('%s/PER_%s_MCS%d_%dB.txt',phyParams.folderPERcurvesNLOS,'LTE',phyParams.MCS_LTE,appParams.beaconSizeBytes);
        [phyParams.sinrVectorCV2X_NLOS_dB,~,~,~,sinrInterp,perInterp] = readPERtable(fileName,10000);
        %[phyParams.sinrVectorCV2X_LOS_dB,perVectorLTE,~,~,sinrInterp,perInterp] = readPERtable(fileName,10000);
        %% DEBUG PER vs. SINR curves
        %plot(phyParams.sinrVectorCV2X_LOS_dB,perVectorLTE,'pc');
        %hold on
        %plot(10*log10(sinrInterp),perInterp,'.k');
        %
        % Calculate the sinrThreshold, corresponding to 90% PER
        phyParams.sinrThresholdCV2X_NLOS_dB = 10*log10( sinrInterp(find(perInterp>=0.9,1)) );
    else
        phyParams.sinrVectorCV2X_NLOS_dB=phyParams.sinrVectorCV2X_LOS_dB;
        phyParams.sinrThresholdCV2X_NLOS_dB=phyParams.sinrThresholdCV2X_LOS_dB;
    end
    
else
    % If PER vs. SINR curves are not used, the SINR threshold must be set
    
    % [sinrThresholdCV2X_LOS]
    % SINR threshold for CV2X LOS
    [phyParams,varargin] = addNewParam(phyParams,'sinrThresholdCV2X_LOS',-1000,'SINR threshold for error assessment [dB]','double',fileCfg,varargin{1});
    
    % -1000 means automatic setting
    if phyParams.sinrThresholdCV2X_LOS ~= -1000
        phyParams.sinrThresholdCV2X_LOS_dB = phyParams.sinrThresholdCV2X_LOS;
    else
        fprintf("SINR threshold for error assessment [dB]:\t[sinrThresholdCV2X_LOS] = %f (automatic setting)\n", phyParams.sinrThresholdCV2X_LOS_dB);
    end
    phyParams.sinrVectorCV2X_LOS_dB = phyParams.sinrThresholdCV2X_LOS_dB;
    
    phyParams.sinrVectorCV2X_NLOS_dB = phyParams.sinrVectorCV2X_LOS_dB;
    phyParams.sinrThresholdCV2X_NLOS_dB = phyParams.sinrThresholdCV2X_LOS_dB;
end
%
phyParams.sinrThresholdCV2X_LOS = 10.^(phyParams.sinrThresholdCV2X_LOS_dB/10);
phyParams.sinrVectorCV2X_LOS = 10.^(phyParams.sinrVectorCV2X_LOS_dB/10);
%
phyParams.sinrThresholdCV2X_NLOS=10.^(phyParams.sinrThresholdCV2X_NLOS_dB/10);
phyParams.sinrVectorCV2X_NLOS = 10.^(phyParams.sinrVectorCV2X_NLOS_dB/10);

%% Check on subchannels for 4G, and calculation of NB in frequency and time
if simParams.mode5G==constants.MODE_LTE
    % Check whether the beacon size (appParams.RBsBeacon) + SCI (2x 2 RBs) exceeds the number of available RBs per subframe
    appParams.RBsSubframeV2V = appParams.RBsFrequencyV2V*(phyParams.Tsf/phyParams.Tslot);
    %if ~phyParams.BLERcurveLTE
    if (appParams.RBsBeacon+4)>appParams.RBsSubframeV2V
        error('Error: "appParams.beaconSizeBytes" is too large for the selected MCS (packet cannot fit in a subframe)');
    end

    % Find NbeaconsF, subchannel sizes or multiples for LTE
    [appParams,phyParams] = calculateNB(appParams,phyParams);

    % Compute BW of subchannel
    phyParams.BwMHz_cv2xSubCH = phyParams.RBbandwidth * 1e-6 * phyParams.sizeSubchannel;
    % Compute BW of a Beacon Resource
    phyParams.BwMHz_cv2xBR = phyParams.NsubchannelsBeacon * phyParams.BwMHz_cv2xSubCH;
    % Compute BW of the SCI in LTE
    phyParams.BwMHz_SCI = phyParams.RBbandwidth * 1e-6 * 2;
    % Compute power per MHz in LTE
    phyParams.P_ERP_MHz_CV2X_dBm = (phyParams.Ptx_dBm + phyParams.Gt_dB) - 10*log10(phyParams.BwMHz_cv2xBR);
    phyParams.P_ERP_MHz_CV2X = db2pow(phyParams.P_ERP_MHz_CV2X_dBm-30);
    % Compute the Pnoise of a BR in LTE (Vittorio)
    phyParams.PnoiseData = phyParams.Pnoise_MHz*phyParams.BwMHz_cv2xBR;
    % Compute the Pnoise of the SCIs of a BR in LTE
    phyParams.PnoiseSCI  = phyParams.Pnoise_MHz*phyParams.BwMHz_SCI;
else
    % Find NbeaconsF and NbeaconsT for NR
    [appParams,phyParams] = calculateNB_5G(appParams,phyParams);

    % Compute BW of subchannel
    phyParams.BwMHz_cv2xSubCH = phyParams.RBbandwidth * 1e-6 * phyParams.sizeSubchannel;
    % Compute BW of a Beacon Resource in NR
    phyParams.BwMHz_cv2xBR = phyParams.NsubchannelsBeacon * phyParams.BwMHz_cv2xSubCH;
    % Compute BW of the SCI-1 in NR
    phyParams.BwMHz_SCI = phyParams.RBbandwidth * 1e-6 * phyParams.nRB_SCI;
    % Compute power per MHz in NR
    phyParams.P_ERP_MHz_CV2X_dBm = (phyParams.Ptx_dBm + phyParams.Gt_dB) - pow2db(phyParams.BwMHz_cv2xBR);
    phyParams.P_ERP_MHz_CV2X = db2pow(phyParams.P_ERP_MHz_CV2X_dBm-30);
    % Compute the Pnoise of a BR in 5G
    phyParams.PnoiseData = phyParams.Pnoise_MHz*phyParams.BwMHz_cv2xBR;
    % Compute the Pnoise of the SCIs of a BR in 5G
    phyParams.PnoiseSCI  = phyParams.Pnoise_MHz*phyParams.BwMHz_SCI;
end

% Compute In-Band Emission Matrix 
% (following 3GPP TS 36.101 v15.0.0) for LTE
% and 38.101-1 V17.0.0 (2020-12) for 5G
[phyParams.IBEmatrixData,phyParams.IBEmatrixControl] =...
    IBEcalculation(simParams,phyParams,appParams);

% Check how many BRs to exploit in the frequency domain
if phyParams.NumBeaconsFrequency~=-1
    if phyParams.NumBeaconsFrequency > appParams.NbeaconsF
        fprintf('Number of beacons in frequency domain in input is larger than the maximum one: set to %.0f\n\n', NbeaconsF);
    else
        appParams.NbeaconsF = phyParams.NumBeaconsFrequency;
        phyParams.IBEmatrix = phyParams.IBEmatrix(1:appParams.NbeaconsF,1:appParams.NbeaconsF);
    end
end

% Total number of beacons per beacon period = Beacon Resources (BRs)
appParams.Nbeacons = appParams.NbeaconsF*appParams.NbeaconsT;

% Error check
if appParams.Nbeacons<1
    fprintf('Number of beacons equal to %d. Error.', Nbeacons);
    error('');
end

end