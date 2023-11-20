function Nbps = findModulation(MCS)
% This function takes the modulation and coding scheme (MCS) as 
% the input parameter and based on table 8-6-1-1 of 3GPP TS 36.213 V14.0.0 
% finds the number of bits per symbol

if MCS<=10
   Nbps = 2;
elseif MCS>=11 && MCS<=20
   Nbps = 4;
elseif MCS>=21 && MCS<=28
   Nbps = 6;
else 
    error('Invalid MCS');
end

end
