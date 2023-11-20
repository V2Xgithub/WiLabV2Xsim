% Takes as input the index of MCS and return Modulation order (Qm), Code Rate (Rx1024),and Spectral Efficiency
% The values are taken from table Table 5.1.3.1-1: MCS index table 1 for PDSCH
% As specified in 38.214 V16.2.0 (2020-06)
% To update the table, change the txt file
% Admitted value for the MCS index are from 0 to 28, values 29,30,31 are
% reserved and not selectable

function [Qm,R,SpectralEff] = getMCS(indexMCS)

if(indexMCS >= 0) && (indexMCS <= 28) && (isnumeric(indexMCS))
    Table = load('MCS.txt');
    Qm = Table(indexMCS+1,2);
    R  = Table(indexMCS+1,3);
    SpectralEff = Table(indexMCS+1,4);
else
    error("error in indexMCS selection\n");
end

end
