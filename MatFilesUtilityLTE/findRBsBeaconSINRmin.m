function [RBsBeacon,gammaMin_dB,NbitsHz,CR,Nbps] = findRBsBeaconSINRmin(MCS,BeaconSizeBits)
% This function calculates RBs per beacon and minimum required SINR

% Call function to find ITBS value from MCS
ITBS = findITBS(MCS);

% Call function to find the modulation format (number of bits per symbol)
Nbps = findModulation(MCS);

% Call function to find the number of RBs per beacon
[RBsBeacon,Nbits] = findRBsBeaconNbits(ITBS,BeaconSizeBits);

% Compute the effective code rate
% CR = Nbits/((RBsBeacon/2)*9*12*Nbps);
% Nsymbols is 8 since ACG is considered mandatory (Vittorio)
CR = Nbits/((RBsBeacon/2)*8*12*Nbps);

% Compute spectral efficiency (bits/s·Hz)
NbitsHz = (12*14*Nbps*CR)/(1e-3*180e3);

% Compute the minimum required SINR
% (alfa is taken from 3GPP)
alfa = 0.4;
gammaMin_dB = 10*log10(2^(NbitsHz/alfa)-1);

end