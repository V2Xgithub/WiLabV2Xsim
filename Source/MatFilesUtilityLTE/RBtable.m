function RBs = RBtable(Bw)
% Find the number of available Resource Blocks in the frequency domain

if(Bw==1.4)
    RBs = 6;
elseif(Bw==5)
    RBs = 25;
elseif(Bw==10)
    RBs = 50;
elseif(Bw==20)
    RBs = 100;
else
    error('Invalid Bandwidth');
end

end