% This function returns the TBS in the case Ninfo<=3824
% The values of TBS are taken from table 5.1.3.2-1 from 3GPP TS 38.214 V16.2.0 (2020-06)
% In the case Ninfo<=3824, Given Ninfo, evaluates Ninfo', then the closest TBS that is not less than Ninfo' is returned
% In the case Ninfo>3824 the TBS is determined by a formula

function [TBS,Ninfo1] = fTBS_5G(Ninfo,R)

if (Ninfo<=3824)

    n=max(3,floor(log2(Ninfo))-6);              % Evaluate n
    Ninfo1=max(24,2^n*(floor(Ninfo/2^n)));      % Evaluate Ninfo'
    
    S=load("tableNinfo1_5G.mat");               % Load Table 5.1.3.2-1 from 3GPP TS 38.214 V16.2.0 (2020-06)
    tableNinfo1=S.tableNinfo1(:,2);             % Access the second column with the TBS values
 
    t=tableNinfo1-Ninfo1;         % Subtracts Ninfo' to find the value with the smallest difference
    minValue = min(t(t>=0));       % finds min non negative value
    
    TBS = minValue + Ninfo1;

else
    % Finds the TBS size for Ninfo > 3824

    n=floor(log2(Ninfo-24))-5;                         % Evaluate n
    Ninfo1=max(3840,2^n*(round((Ninfo-24)/2^n)));      % Evaluate Ninfo'
    
    if (R<=(1/4))
        
        C = ceil((Ninfo1+24)/3816);
        TBS = 8*C*ceil((Ninfo1+24)/(8*C))-24;
    
    elseif(Ninfo1>=8424)
        
        C = ceil((Ninfo1+24)/8424);
        TBS = 8*C*ceil((Ninfo1+24)/(8*C))-24;
    
    else
        
        TBS = 8*ceil((Ninfo1+24)/8)-24;
    
    end

end
end