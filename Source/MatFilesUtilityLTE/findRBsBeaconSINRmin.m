function [RBsBeacon,gammaMin_dB,NbitsHz,CR,Nbps] = findRBsBeaconSINRmin(MCS,BeaconSizeBits,TTI,BwMHz)
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

% Compute spectral efficiency (bits/s/Hz)
NbitsHz = (12*14*Nbps*CR)/(1e-3*180e3);

%% Compute the minimum required SINR
% Find minimum SINR for LTE-V2X automaticly, only for 10 MHz now 
%  related method could be found in paper:
%  Wu Z, Bartoletti S, Martinez V, Bazzi A. A Methodology for Abstracting 
%  the Physical Layer of Direct V2X Communications Technologies. Sensors. 2022;
%  22(23):9330. https://doi.org/10.3390/s22239330
effective_throughput = BeaconSizeBits * 50 / (RBsBeacon/2) / TTI / (BwMHz * 1e6);

shannon_throughput = effective_throughput / constants.IMPLEMENTLOSS_CV2X;
sinr_linear = 2^(shannon_throughput)-1;
gammaMin_dB = pow2db(sinr_linear);

end