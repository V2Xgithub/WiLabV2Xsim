%% Calculate Coding Rate, Data Rate, and SINR of NR-V2X
% with given MCS, packet size, and other parameters

% init
clear;clc;

fullPath = fileparts(mfilename('fullpath'));
addpath(genpath(fullPath));

% parameters of NR-V2X
phyParams.BwMHz = 10;               % [MHz]
phyParams.sizeSubchannel = 12;      % number of RBs in each subchannel
phyParams.SCS_NR = 30;              % Sets the SCS for 5G (kHz)
phyParams.nDMRS_NR = 18;            % Sets the number of DMRS resource element used in each slot
phyParams.SCIsymbols = 3;           % Sets the number of symbols dedicated to the SCI-1 between 2 and 3
phyParams.nRB_SCI = 12;             % Sets the number of RBs dedicated to the SCI-1

% Call function to find the total number of RBs in the frequency domain per Tslot in 5G
phyParams.RBsFrequency = RBtable_5G(phyParams.BwMHz,phyParams.SCS_NR);

phyParams.Tslot_NR = 1e-3/(phyParams.SCS_NR/15);            % 5G Tslot [s]
phyParams.RBbandwidth = 180e3*phyParams.SCS_NR/15;          % 5G Resource Block Bandwidth [Hz]

for packetSize = [200, 1600]        % packet size [bytes]
    packetSizeBits = packetSize * 8;    % packet size [bits]
    % print column name
    fprintf("===========================================\n");
    fprintf("%d bytes\n", packetSize);
    fprintf("===========================================\n");
    fprintf("iMCS\tCR\t\tDR [Mbps]\tnRB_b\tSINR_th[dB]\n");
    % print
    for MCS_NR = 0:28
        phyParams.MCS_NR = MCS_NR;
        try
            % calculate
            % NbitsHz [bits/s/Hz]
            [nSubchannelperChannel,subchannelperPacket,nRB_b,gammaMin_dB,NbitsHz,CR,Qm] = findRBsBeaconSINRmin_5G(phyParams,packetSizeBits);
            
            % calculate data rate: 
            % eq 4 in V. Todisco et al.: Performance Analysis of Sidelink 5G-V2X Mode 2 Through Open-Source Simulator
            n_symslot = 12;         % the 1st and the last symbols are not used
            n_scpPRB = 12;          % the number of subcarriers in the frequency domain per PRB
            b_symbol_m = Qm;        % number of bits per symbol
            DR = NbitsHz * phyParams.BwMHz;  % [Mbps]
            
            fprintf("%d\t\t%.2f\t%.2f\t\t%d\t\t%.2f\n", MCS_NR, CR, DR, nRB_b, gammaMin_dB);
        catch exception
            
        end
    end
end
