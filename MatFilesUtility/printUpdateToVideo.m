function reverseStr = printUpdateToVideo(elapsedTime,simTime,reverseStr)
% Function to print time to video and estimate end of simulation

elapsedSeconds = toc;
remainingSeconds = elapsedSeconds * (simTime-elapsedTime)/elapsedTime;
remainingDays = floor(remainingSeconds/(60*60*24));
remainingSeconds = remainingSeconds - (remainingDays*60*60*24);
remainingHours = floor(remainingSeconds/(60*60));
remainingSeconds = remainingSeconds - (remainingHours*60*60);
remainingMinutes = floor(remainingSeconds/(60));
remainingSeconds = remainingSeconds - (remainingMinutes*60);
msg = sprintf('%.1f / %.1fs, end estimated in',elapsedTime,simTime);
if remainingDays>0
    sTemp = sprintf(' %d days, %d hours',remainingDays,remainingHours);
    msg = strcat(msg,sTemp);
elseif remainingHours>0
    sTemp = sprintf(' %d hours, %d minutes',remainingHours,remainingMinutes);
    msg = strcat(msg,sTemp);
elseif remainingMinutes>0
    sTemp = sprintf(' %d minutes, %d seconds',remainingMinutes,ceil(remainingSeconds));
    msg = strcat(msg,sTemp);
else
    sTemp = sprintf(' %d seconds',ceil(remainingSeconds));
    msg = strcat(msg,sTemp);
end
fprintf([reverseStr, msg]);
reverseStr = repmat(sprintf('\b'), 1, length(msg));


