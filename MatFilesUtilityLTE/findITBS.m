function ITBS = findITBS(MCS)
% This function finds the corresponding Transport Block Size Index (ITBS)
% from 3GPP LTE Tables

if MCS<=10 
    ITBS = MCS;
elseif MCS>10 && MCS<=20
    ITBS = MCS-1;
elseif MCS>20 && MCS<=28
    ITBS = MCS-2; 
else 
    error('Invalid MCS');
end

end

    
    
   


