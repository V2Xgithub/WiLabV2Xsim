function createMap(backGround,fuzzyValues,imageFileName)
% CREATEMAP creates and saves an image to represent the values in
% 'fuzzyValues'
%
% --Inputs--
% backGround: a matrix describing the scenario, with 1=gray and 0=white
% fuzzyValues: a matrix with the values to be used in the range 0-1, where
% 1 is cyan and 0 is black (intermediate colors are shown in a legend added
% on the left of the image
% imageFileName: the output file; the extension of the file determines its
% format (e.g., .bmp or .png)
%
% --Outputs--
% image: is a matrix containing the rgb output values
%
% --Notes--
% backGround and fuzzyValues must be matrices of the same size

% Initialize
nRows = size(backGround,1);
nCol = size(backGround,2);
image=ones(nRows,nCol+10,3); 

% Check that the matrices are of the smae size
if size(fuzzyValues,1)~=nRows || size(fuzzyValues,2)~=nCol
   fprintf('Error creating a bitmap: "backGround" and "fuzzyValues" must be of the same size\n');
   fprintf('"backGround" is a %d x %d matrix\n',nRows,nCol);
   fprintf('"fuzzyValues" is a %d x %d matrix\n',size(fuzzyValues,1),size(fuzzyValues,2));
   error('');
end

% Create the legend
% Color the left bar
A = (1:nRows)/nRows;
legend = repmat(A',1,8);
image(:,1:8,1) = min(max(min((legend/0.25),((0.75-legend)/0.25)),0),1);
image(:,1:8,2) = min(max((legend-0.25)/0.25,0),1);
image(:,1:8,3) = max((legend-0.75)/0.25,0);
% Add thicks at multiples of 10%
image(1:2,1:4,1) = 0;
image(1:2,1:4,2) = 0;
image(1:2,1:4,3) = 0;
for i=1:10
    iRow = floor( (nRows*i/10) );
    if i<5
        image(iRow:iRow+1,1:4,1) = 0;
        image(iRow:iRow+1,1:4,2) = 0;
        image(iRow:iRow+1,1:4,3) = 0;
    else
        image(iRow-1:iRow,1:4,1) = 0;
        image(iRow-1:iRow,1:4,2) = 0;
        image(iRow-1:iRow,1:4,3) = 0;
    end
end

% Set background
streetfileScaled = 1-backGround*0.2;
image(:,11:end,1) = streetfileScaled;
image(:,11:end,2) = streetfileScaled;
image(:,11:end,3) = streetfileScaled;

% Add colors based on the input values
image(:,11:end,1) = image(:,11:end,1).*(fuzzyValues<0) + min(max(min((fuzzyValues/0.25),((0.75-fuzzyValues)/0.25)),0),1);
image(:,11:end,2) = image(:,11:end,2).*(fuzzyValues<0) + min(max((fuzzyValues-0.25)/0.25,0),1);
image(:,11:end,3) = image(:,11:end,3).*(fuzzyValues<0) + max((fuzzyValues-0.75)/0.25,0);

imwrite(image,imageFileName);

end

