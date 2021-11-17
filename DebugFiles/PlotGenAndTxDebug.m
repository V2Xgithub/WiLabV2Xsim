close all
clear
clc

% new
Data = load('Output_Debug_A/_DebugTx_1.xls');
% without PHY reallocation
Data = load('Output_Debug_A/_DebugTx_2.xls');

Data = load('Output_Debug_A/_DebugTx_3.xls');

Data(Data<=0) = -1;

time = Data(:,1);
tx11p_ID = Data(:,2);
rxOk11p_ID = Data(:,3);
rxErr11p_ID = Data(:,4);
txLTE_ID = Data(:,5);
rxOkLTE_ID = Data(:,6);
rxErrLTE_ID = Data(:,7);
tx11p_X = Data(:,8);
rxOk11p_X = Data(:,9);
rxErr11p_X = Data(:,10);
txLTE_X = Data(:,11);
rxOkLTE_X = Data(:,12);
rxErrLTE_X = Data(:,13);

tx11pCAM_X = tx11p_X;
tx11pCAM_X(tx11p_ID<0 | tx11p_ID>245) = -1;
tx11pDENM_X = tx11p_X;
tx11pDENM_X(tx11p_ID<246) = -1;

Data = load('Output_Debug_A/_DebugReallocation_1.xls');
Data = load('Output_Debug_A/_DebugReallocation_2.xls');
Data = load('Output_Debug_A/_DebugReallocation_3.xls');

%Data(Data<=0) = -1;
timeGen = Data(:,1);
idGen = Data(:,2);
xGen = Data(:,3);
ifGen = Data(:,4);
brGen = Data(:,5);

figure(1);
%plot(time,txLTE_X,'ob');
plot(timeGen(logical(ifGen)),idGen(logical(ifGen)),'*b');
hold on
plot([-1 -1],[-1 -1],'--k');
plot(time,txLTE_ID,'ob');
%plot(time,rxOkLTE_X,'.g');
%plot(time,rxErrLTE_X,'.r','MarkerSize',6);
plot(timeGen(logical(~ifGen)),idGen(logical(~ifGen)),'pr');
for i=1:length(timeGen)
    if logical(ifGen(i))
        plot([timeGen(i) timeGen(i)+0.1],[idGen(i) idGen(i)],'--k');
    end
end
axis([2 4 0 20]);
%for t=1.8:0.005:2
%    plot([t t],[-1 2001],'--k');
%end
xlabel('Time [s]');
ylabel('Position [m]');
%legend('ITS-G5, Tx CAM','ITS-G5, Rx Ok','ITS-G5, Rx Err');
%legend('ITS-G5, Tx CAM','ITS-G5, Tx DENM','ITS-G5, Rx Ok','ITS-G5, Rx Err',...
%    'LTE, Tx','LTE, Rx Ok','LTE, Rx Err');
legend('Packet generation','Time to T2','Tx','Reallocation');

