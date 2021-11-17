close all
clear
clc

Data = load('Output_debug/_DebugTx_5.xls');

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

figure(1);
plot(time,tx11pCAM_X,'ob');
hold on
%plot(time,tx11pDENM_X,'pk','MarkerSize',12,'MarkerFaceColor',[0 0 0]);
%plot(time,rxOk11p_X,'.b');
%plot(time,rxErr11p_X,'xr','MarkerSize',6);
plot(time,txLTE_X,'om');
%plot(time,rxOkLTE_X,'.m');
%plot(time,rxErrLTE_X,'xm','MarkerSize',6);
%axis([1.8 1.84 0 2000]);
axis([1.5 1.7 0 2000]);
for t=0:0.01:4.2
    plot([t t],[-1 2001],'--k');
end
for t=0.005:0.01:4.2
    plot([t t],[-1 2001],':r');
end
xlabel('Time [s]');
ylabel('Position [m]');
%legend('ITS-G5, Tx CAM','ITS-G5, Rx Ok','ITS-G5, Rx Err');
%legend('ITS-G5, Tx CAM','ITS-G5, Tx DENM','ITS-G5, Rx Ok','ITS-G5, Rx Err',...
%    'LTE, Tx','LTE, Rx Ok','LTE, Rx Err');
legend('ITS-G5, Tx','LTE, Tx');

