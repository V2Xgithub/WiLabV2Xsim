function [minRandValue,maxRandValue] = findRCintervalAutonomous(Tbeacon,simParams)
% The min and max values for the random counter are set as in TS 36.321

if Tbeacon>=0.1
    minRandValue = 5;
    maxRandValue = 15;
elseif Tbeacon>=0.05
    minRandValue = 10;
    maxRandValue = 30;
else
    minRandValue = 25;
    maxRandValue = 75;
end

if simParams.minRandValueMode4~=-1
    minRandValue = simParams.minRandValueMode4;
end
if simParams.maxRandValueMode4~=-1
    maxRandValue = simParams.maxRandValueMode4;
end
if maxRandValue <= minRandValue 
    error('Error: in 3GPP Mode 4, "maxRandValue" must be larger than "minRandValue"');
end

end