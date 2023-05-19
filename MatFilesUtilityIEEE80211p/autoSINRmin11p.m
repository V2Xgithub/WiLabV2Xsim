function gammaMin_dB = autoSINRmin11p(mcs_index, dataSize, BwMHz)
% Find minimum SINR for IEEE 802.11p automaticly, only for 10 MHz now 
%  related method could be found in paper:
%  Wu Z, Bartoletti S, Martinez V, Bazzi A. A Methodology for Abstracting 
%  the Physical Layer of Direct V2X Communications Technologies. Sensors. 2022;
%  22(23):9330. https://doi.org/10.3390/s22239330

if BwMHz ~= 10
    error("Automaticly threshold calculatioin only for 10 MHz in this version, %d MHz is set", BwMHz);
end
%  MCS mode    0   1   2   3   4   5    6    7
bpSymbol =   [24, 36, 48, 72, 96, 144, 192, 216];       % data bits per OFDM symbol
n_symbol = ceil(8*dataSize / bpSymbol(mcs_index+1));    % number of symbols needed for the data of a packet

t_pre = 40e-6;                                          % sec. preamble duration
t_AIFS = 110e-6;                                        % sec. arbitrary inter-frame space
t_sym = 8e-6;                                           % sec. symbol duration

% bits/s/Hz
effective_throughput = 8*dataSize / (t_pre + t_AIFS + n_symbol * t_sym) / (BwMHz * 1e6);
shannon_throughput = effective_throughput / constants.IMPLEMENTLOSS_11P;
sinr_linear = 2^(shannon_throughput)-1;
gammaMin_dB = 10*log10(sinr_linear);

end
