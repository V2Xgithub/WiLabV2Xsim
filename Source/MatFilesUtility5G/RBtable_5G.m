function [nRB]=RBtable_5G(ChannelBandwidth,SCS)
% Given SCS and ChannelBandwidth return the number of RB in the channel
% If returns 0 the value selected is not determined
% Values are taken as specified in table 5.3.2-1 in 3GPP 38.101-1 V16.4.0 (2020-06)


Table = load('RBperChannel.txt');

scs=[15,30,60]';    % admitted values for SCS [kHz]
bandwidth=[5,10,15,20,25,30,40,50,60,70,80,90,100];     %admitted values for Bandwidth [MHz]

i1=find(scs==SCS);
i2=find(bandwidth==ChannelBandwidth);

if(isempty(i1)||isempty(i2))
    error("Wrong value selection of Band/SCS\n");
end

nRB=Table(i1,i2);

if(nRB==0)
    error("The nRB value selected by Band/SCS is N/A");
end