function [seed] = getseed()
%GETSEED Summary of this function goes here
%   Detailed explanation goes here
t = clock;
tstring = string(t);
seed = "";
for i = 1:length(tstring)
    seed = seed + tstring(i);
end
seed = mod(str2double(seed)*1e4, 2^32);
seed = ceil(seed);
end

