close all
clear
clc

for iFig=1:2
    
figure(iFig)

% 1: with ITS-G5
%data = load('Output_Debug/_DebugBRofMode4_2.xls');
% 3: without ITS-G5
fileName = sprintf('Output_MethodC_Debug_600s_corrected//_DebugBRofMode4_%d.xls',iFig);
data = load(fileName);

subframeV = ceil(data(:,3)/3);
timeV = ceil(data(:,1)*10)/10;
subframeUsed = zeros(1,max(data(:,2)));

n1 = 0;
n2 = 0;
n3 = 0;

indexInTimeV = 1;
for t=0.1:0.1:600
    subframeNow = mod(t/0.1-1,100)+1;
    while timeV(indexInTimeV)<t
        subframeUsed(data(indexInTimeV,2)) = subframeV(indexInTimeV);
        indexInTimeV = indexInTimeV + 1;
    end
    nSubframeNow = sum(subframeUsed==subframeNow);
    if nSubframeNow==0
        %plot(t,subframeNow,'ok');
        hold on
        continue;
    elseif nSubframeNow==1
        plot(t,subframeNow,'pg');
        hold on
        n1 = n1+1;
    elseif nSubframeNow==2
        plot(t,subframeNow,'pb');
        hold on
        n2 = n2+2;
    else
        plot(t,subframeNow,'pr');
        hold on
        n3 = n3+nSubframeNow;
    end
end

for i=0:10:90
    for j=1:5
        plot([data(1,1) data(end,1)],[i+j i+j],':r');
    end
end

fprintf('Fig:%d\tTot = %d\nn1 = %d (%.1f%%)\nn2 = %d (%.1f%%)\nn3 = %d (%.1f%%)\n\n',iFig,n1+n2+n3,n1,100*n1/(n1+n2+n3),n2,100*n2/(n1+n2+n3),n3,100*n3/(n1+n2+n3));
end