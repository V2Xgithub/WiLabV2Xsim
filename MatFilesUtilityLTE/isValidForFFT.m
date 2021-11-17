function isValid = isValidForFFT(number)
% number must be a multiple only of 2, 3, and/or 5

while rem(number,2)==0
    number=number/2;
end

while rem(number,3)==0
    number=number/3;
end

while rem(number,5)==0
    number=number/5;
end

if number == 1
    isValid = true;
else
    isValid = false;
end