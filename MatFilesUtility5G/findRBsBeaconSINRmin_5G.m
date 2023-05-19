function [nSubchannelperChannel,subchannelperPacket,RBsBeacon,gammaMin_dB,NbitsHz,CR,Qm] = findRBsBeaconSINRmin_5G(phyParams,packetSizeBits)
% This function calculates the number of subchannel per packet and minimum required SINR
%  The method of calculating the required SINR could be found in paper:
%  V. Todisco, S. Bartoletti, C. Campolo, A. Molinaro, A. O. Berthet and 
%  A. Bazzi, "Performance Analysis of Sidelink 5G-V2X Mode 2 Through an 
%  Open-Source Simulator," in IEEE Access, vol. 9, pp. 145648-145661, 2021, 
%  doi: 10.1109/ACCESS.2021.3121151.

%% check if subchannel size was supported
% Vector of supported subchannel sizes for NR (3GPP TR 38.886 V16.0.0 (2020-06))
% the admitted sizes are all valid for FFT
supportedSizeSubchannel_5G = [10,12,15,20,25,50,75,100];

% Check whether the input sizeSubchannel is supported
if ~ismember(phyParams.sizeSubchannel, supportedSizeSubchannel_5G)
    error('Error the selected subchannel size is not supported');
end

%% Determination of subchannel in the overall channel

% finds the number of subchannel in the channel
nSubchannelperChannel = floor(phyParams.RBsFrequency/phyParams.sizeSubchannel);

if nSubchannelperChannel>29             % SCI1A has been set to have a fixed size of 64 bits, which leaves a maximum of 14 bits for the FRA
    error("The number of subchannel exceeds the bits of FRA")
end



%%
% sets nPRB for the TBS calculation on a subchannel base
RBperTBS=phyParams.sizeSubchannel;

% Call function to find the TBS considering one Subchannel
[TBS,nRE,R,Qm] = findTBS_5G(RBperTBS,phyParams.nDMRS_NR,phyParams.MCS_NR,phyParams.SCIsymbols,phyParams.nRB_SCI,phyParams.sizeSubchannel);


% Finds the number of subchannels required to accomodate the packet
% first it finds the number of suchannel required, then it accurately finds
% the actual number of RBs needed.
if(packetSizeBits<=TBS)
    subchannelperPacket=1;
else
    nsub=1;
    while(packetSizeBits>TBS)
        nsub=nsub+1;
        RBperTBS=nsub*phyParams.sizeSubchannel;
        [TBS,nRE,R,Qm] = findTBS_5G(RBperTBS,phyParams.nDMRS_NR,phyParams.MCS_NR,phyParams.SCIsymbols,phyParams.nRB_SCI,phyParams.sizeSubchannel);
    end
    subchannelperPacket=nsub;
end

% Check on packet size
if (subchannelperPacket > nSubchannelperChannel)
    error("The packet size exceeds the subchannels available")
end


% Evaluates the actual number of RB required to transmit one beacon
for RBperTBSmin=((subchannelperPacket-1)*phyParams.sizeSubchannel+1):(subchannelperPacket*phyParams.sizeSubchannel)
    [TBSmin,nREmin,~,Qm] = findTBS_5G(RBperTBSmin,phyParams.nDMRS_NR,phyParams.MCS_NR,phyParams.SCIsymbols,phyParams.nRB_SCI,phyParams.sizeSubchannel);
    if(packetSizeBits<=TBSmin)
        RBsBeacon = RBperTBSmin;
        break;
    end
end

% Compute the effective code rate or use the actual Code Rate
% the first option is to use the TBS by considering the subchannel used
% the second option uses the actual code rate
% the third option evaluates the code rate by only considering the RB
% necessary for the transmission instead of the whole subchannel(s)
%CR = TBS/(nRE*Qm);
%CR = R;
CR = TBSmin/(nREmin*Qm);

% Compute spectral efficiency (bits/s·Hz)
% Tslot in s
% Tslot_NR=1e-3/(phyParams.SCS_NR/15);

NbitsHz = (12*14*Qm*CR)/(phyParams.Tslot_NR*phyParams.RBbandwidth);

% Compute the minimum required SINR
% (alfa is taken from 3GPP)
alfa = 0.4;
gammaMin_dB = pow2db(2^(NbitsHz/alfa)-1);

end