function [sinrVectorOut,PERout,sinr_dB_fromtable,PER_fromtable,sinr_lin_fromtable_interp,PER_interp] = readPERtable(fileName,nInterp)

if ~exist(fileName,'file')
    fprintf('Input file %s does not exist',fileName);
    error('');
end
PERtable_ori = load(fileName);
[PERtable(:,2),I]=unique(PERtable_ori(:,2),'stable');
PERtable(:,1)=PERtable_ori(I,1);

sinr_dB_fromtable = PERtable(:,1);
PER_fromtable = PERtable(:,2);


if PER_fromtable(1)~=1
    PER_fromtable = [1; PER_fromtable];
    sinr_dB_fromtable = [sinr_dB_fromtable(1)-0.01; sinr_dB_fromtable];
end

if PER_fromtable(end)==0
    PER_fromtable(end) = 1e-8;
elseif PER_fromtable(end)~=0
    PER_fromtable(end+1) = 1e-8;
    sinr_dB_fromtable(end+1) = sinr_dB_fromtable(end)+0.01;
end

% if PER_fromtable(1)~=0 || PER_fromtable(end)~=1
%     error('Extreme cases of PER to be defined');
% end


% Interpolation, with uniform steps in BLER domain
PER_step = 1/nInterp;
PER_interp = PER_step:PER_step:1;
%gamma_dB_fromtable_interp = interp1(PER_fromtable,gamma_dB_fromtable,PER_interp);
%sinr_lin_fromtable = 10.^(sinr_dB_fromtable/10);
%sinr_lin_fromtable_interp = interp1(PER_fromtable,sinr_lin_fromtable,PER_interp);

sinr_dB_fromtable_interp = interp1(10*log10(PER_fromtable),sinr_dB_fromtable,10*log10(PER_interp));
sinr_lin_fromtable_interp = 10.^(sinr_dB_fromtable_interp/10);

% % Interpolation in dB
% %BLER_fromtable_dB = 10*log10( BLER_fromtable );
% gamma_dB_fromtable_interp_step = (gamma_dB_fromtable(end)-gamma_dB_fromtable(1))/(nInterp-1);
% gamma_dB_fromtable_interp = gamma_dB_fromtable(1):gamma_dB_fromtable_interp_step:gamma_dB_fromtable(end);
% PER_fromtable_interp_dB = interp1(gamma_dB_fromtable,BLER_fromtable,gamma_dB_fromtable_interp);

PERout = PER_interp;
%gammaOut = gamma_dB_fromtable_interp;
sinrVectorOut = 10*log10(sinr_lin_fromtable_interp);

% if strcmpi(type,'logGamma')
%     gammaOut = gamma_dB_fromtable_interp;
%     BLER = 10.^(BLER_fromtable_interp_dB/10);
% elseif strcmpi(type,'linGamma')
%     % Linear conversion
%     gammaLin_fromtable_interp = 10.^(gamma_dB_fromtable_interp/10);
% 
%     % Values with constan delta in linear
%     nGamma = nInterp;
%     gammaLinStep = (gammaLin_fromtable_interp(end))/(nGamma);
%     gammaLin = 0:gammaLinStep:gammaLin_fromtable_interp(end);
%     BLER_dB = interp1([0 gammaLin_fromtable_interp],[1 BLER_fromtable_interp_dB],gammaLin);
%     gammaOut = gammaLin;
%     BLER = 10.^(BLER_dB/10);
%     BLER(BLER>1) = 1;
% else
%     error('type of readBLERtable not allowed: %s',type);
% end
 
% % Print curve to figure for DEBUG purposes
% close all
% figure(1)
% semilogy(10*log10(gammaLin),BLER);
end
    