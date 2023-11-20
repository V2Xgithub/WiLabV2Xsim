close all
clear 
clc

nInterp = 1000;

figure1 = figure(1);
data = load('G5-HighwayLOS/PER_11p_MCS0_350B.txt');
semilogy(data(:,1),data(:,2),'-k','lineWidth',2);
hold on
grid on
data = load('G5-HighwayLOS/PER_11p_MCS2_350B.txt');
semilogy(data(:,1),data(:,2),'-b','lineWidth',2);
data = load('G5-HighwayLOS/PER_11p_MCS4_350B.txt');
semilogy(data(:,1),data(:,2),'-r','lineWidth',2);
ylim([1e-3 1]);
xlabel('SINR [dB]');
ylabel('Packet error rate');

% figure(1)
% [~,~,~,~,sinr_lin_interp,PER_interp] = readPERtable('PER_11p_MCS0_350B.txt',nInterp);
% semilogy(10*log10(sinr_lin_interp),PER_interp,'-k');
% hold on
% grid on
% [~,~,~,~,sinr_lin_interp,PER_interp] = readPERtable('PER_11p_MCS2_350B.txt',nInterp);
% semilogy(10*log10(sinr_lin_interp),PER_interp,'-b');
% [~,~,~,~,sinr_lin_interp,PER_interp] = readPERtable('PER_11p_MCS4_350B.txt',nInterp);
% semilogy(10*log10(sinr_lin_interp),PER_interp,'-r');
% 

% Create line
annotation(figure1,'line',[0.3125 0.341071428571429],...
    [0.670428571428572 0.695238095238096]);

% Create line
annotation(figure1,'line',[0.471428571428571 0.5],...
    [0.691857142857145 0.716666666666669]);

% Create line
annotation(figure1,'line',[0.699999999999998 0.728571428571427],...
    [0.703761904761908 0.728571428571432]);

% Create textbox
annotation(figure1,'textbox',...
    [0.501785714285714 0.707333333333335 0.0892857142857143 0.0535714285714286],...
    'String',{'MCS 2','6 Mb/s'},...
    'FitBoxToText','off',...
    'EdgeColor','none');

% Create textbox
annotation(figure1,'textbox',...
    [0.724999999999999 0.724000000000003 0.0892857142857143 0.0535714285714286],...
    'String',{'MCS 4','12 Mb/s'},...
    'FitBoxToText','off',...
    'EdgeColor','none');

% Create textbox
annotation(figure1,'textbox',...
    [0.244642857142857 0.647809523809526 0.0892857142857143 0.0535714285714286],...
    'String',{'MCS 0','3 Mb/s'},...
    'FitBoxToText','off',...
    'EdgeColor','none');

%print('Figure_SINRvsPER_11p','-djpeg')

figure1 = figure(2);
data = load('G5-HighwayLOS/PER_LTE_MCS4_350B.txt');
semilogy(data(:,1),data(:,2),'-k','lineWidth',2);
hold on
grid on
data = load('G5-HighwayLOS/PER_LTE_MCS5_350B.txt');
semilogy(data(:,1),data(:,2),'-m','lineWidth',2);
data = load('G5-HighwayLOS/PER_LTE_MCS7_350B.txt');
semilogy(data(:,1),data(:,2),'-b','lineWidth',2);
data = load('G5-HighwayLOS/PER_LTE_MCS11_350B.txt');
semilogy(data(:,1),data(:,2),'-r','lineWidth',2);
ylim([1e-3 1]);
xlabel('SINR [dB]');
ylabel('Packet error rate');


% figure(2)
% [~,~,~,~,sinr_lin_interp,PER_interp] = readPERtable('PER_LTE_MCS4_350B_40RBP.txt',nInterp);
% semilogy(10*log10(sinr_lin_interp),PER_interp,'-k');
% hold on
% grid on
% [~,~,~,~,sinr_lin_interp,PER_interp] = readPERtable('PER_LTE_MCS5_350B_36RBP.txt',nInterp);
% semilogy(10*log10(sinr_lin_interp),PER_interp,'-m');
% [~,~,~,~,sinr_lin_interp,PER_interp] = readPERtable('PER_LTE_MCS7_350B_27RBP.txt',nInterp);
% semilogy(10*log10(sinr_lin_interp),PER_interp,'-b');
% [~,~,~,~,sinr_lin_interp,PER_interp] = readPERtable('PER_LTE_MCS11_350B_18RBP.txt',nInterp);
% semilogy(10*log10(sinr_lin_interp),PER_interp,'-r');
% 
% 

% Create line
annotation(figure1,'line',[0.344642857142857 0.373214285714286],...
    [0.687095238095238 0.711904761904762]);

% Create line
annotation(figure1,'line',[0.67142857142857 0.699999999999998],...
    [0.741857142857146 0.76666666666667]);

% Create textbox
annotation(figure1,'textbox',...
    [0.271428571428571 0.662095238095239 0.135714285714286 0.0535714285714286],...
    'String',{'MCS 4','5 subch.'},...
    'FitBoxToText','off',...
    'EdgeColor','none');

% Create textbox
annotation(figure1,'textbox',...
    [0.444642857142856 0.695428571428576 0.0892857142857142 0.0535714285714286],...
    'String',{'MCS 5','4 subch.'},...
    'FitBoxToText','off',...
    'EdgeColor','none');

% Create line
annotation(figure1,'line',[0.441071428571428 0.469642857142857],...
    [0.656142857142858 0.680952380952381]);

% Create textbox
annotation(figure1,'textbox',...
    [0.592857142857142 0.635904761904768 0.0892857142857143 0.0535714285714286],...
    'String',['MCS 7',newline,'3 subch.'],...
    'FitBoxToText','off',...
    'EdgeColor','none');

% Create line
annotation(figure1,'line',[0.591071428571427 0.619642857142855],...
    [0.594238095238098 0.619047619047622]);

% Create textbox
annotation(figure1,'textbox',...
    [0.699999999999998 0.774000000000006 0.0991071428571428 0.0535714285714286],...
    'String',['MCS 11',newline,'2 subch.'],...
    'FitBoxToText','off',...
    'EdgeColor','none');

%print('Figure_SINRvsPER_LTE','-djpeg')
