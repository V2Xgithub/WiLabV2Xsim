close all
clear
clc

% 1: with ITS-G5
%data = load('Output_Debug/_DebugBRofMode4_2.xls');
% 3: without ITS-G5
data = load('Output_MethodC_Debug_600s_corrected//_DebugBRofMode4_3.xls');

plot(data(:,1),data(:,3),'p');

nF = 3;
nT = 100;

map = zeros(nT,nF);
for t = 1:nT    
    for f=1:nF
        map(t,f) = sum(data(:,3)==((t-1)*nF+f));
    end
end

% maxMap = max(map,[],'all')
% figure(1)
% for t = 1:nT    
%     for f=1:nF
%         plot(t,f,'p','Color',[1 1 1]*(1-ceil(10*map(t,f)/maxMap)/10));
%         hold on
%     end
% end

% map = sum(map');
% map = map';
% maxMap = max(map,[],'all')
% figure(2)
% for t = 1:nT   
%     if map(t,1)>0
%         if map(t,1)>0.7*maxMap
%             plot(t,1,'pk');
%         else
%             plot(t,1,'pr');
%         end
%     end
%     %plot(t,1,'p','Color',[1 1 1]*(1-ceil(10*map(t,1)/maxMap)/10));
%     hold on
% end

%
nSlotLTE = 10;
map = zeros(nSlotLTE,nF);
for t = 1:nSlotLTE    
    for f=1:nF
        map(t,f) = sum(mod(data(:,3)-1,nSlotLTE*nF)+1==((t-1)*nF+f));
    end
end    
bar(map./ sum(sum(map)))
xlabel('Subframe of the LTE slot');
ylabel('Normalized number of times it is selected');
legend('subchannels 1-3','subchannels 2-4','subchannels 3-5','Location','SouthEast');
title('Distribution of allocations of the LTE station inside the LTE slot; 5:5, 245 vehicles');

figure(2)
mapT = sum(map');
mapT = mapT / sum(mapT);
bar(mapT)
xlabel('Subframe of the LTE slot');
ylabel('Normalized number of times it is selected');
%legend('subchannels 1-3','subchannels 2-4','subchannels 3-5','Location','SouthEast');
title('Distribution of allocations of the LTE station inside the LTE slot; 5:5, 245 vehicles');
