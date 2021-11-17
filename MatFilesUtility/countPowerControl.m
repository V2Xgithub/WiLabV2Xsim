function powerControlCounter = countPowerControl(IDvehicleTX,P_ERP_MHz_dBm,powerControlCounter,powerResolution)
% Function to compute the power control allocation at each transmission
% Returns the updated powerControlCounter

% Number of vehicles transmitting at the current time
Ntx = length(IDvehicleTX);

% Convert power to powerControlCounter vector
P_ERP_MHz_dBm = round(P_ERP_MHz_dBm/powerResolution)+101;
maxPtx = length(powerControlCounter);

for i = 1:Ntx
    if P_ERP_MHz_dBm(IDvehicleTX(i))>=maxPtx
        powerControlCounter(end) = powerControlCounter(end) + 1;
    elseif P_ERP_MHz_dBm(IDvehicleTX(i))<=1
        powerControlCounter(1) = powerControlCounter(1) + 1;
    else
        powerControlCounter(P_ERP_MHz_dBm(IDvehicleTX(i))) = powerControlCounter(P_ERP_MHz_dBm(IDvehicleTX(i))) + 1;
    end  
end

end
