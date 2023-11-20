function tPack = packetDuration11p(Nbyte,Mode,NbitsHz,BwMHz,pWithLTEPHY)
% IEEE 802.11p: find packet transmission duration

Nol = 22; % overhead at MAC in bits
%Noh = 60; % overhead above MAC in bytes
tOs = 8e-6; % OFDM symbol duration
tPreamble = 40e-6; % overhead at PHY in us

% If using 802.11p standard PHY
% From version 5.0.11, the Modes are numbered from 0 to 7
if ~pWithLTEPHY
    % MCS mode    0   1   2   3   4   5    6    7
    bpSymbol =   [24, 36, 48, 72, 96, 144, 192, 216];       % data bits per OFDM symbol
    ns = bpSymbol(Mode+1);  % ns = bits per OFDM symbol
    
    % Compute packet transmission duration (standard)
    tPack = tPreamble + ceil((Nbyte*8 + Nol)/ns)*tOs;
else
    % If using 802.11p with LTE PHY
    
    % Compute throughput (bits/s)
    thr = NbitsHz*BwMHz*1e6;
    
    % Compute packet transmission duration (11p with LTE PHY)
    tPack = tPreamble + ceil((Nbyte*8 + Nol)/(thr*tOs))*tOs;
end

end
