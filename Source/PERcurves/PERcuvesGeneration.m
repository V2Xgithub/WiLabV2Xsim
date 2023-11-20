PERstructure = load('PER_table.mat');

for i = 1:length(PERstructure.PER_table)
    x = PERstructure.PER_table(i);
    scenario = x{1}.scenario;
    folderNameOut = sprintf('%s',scenario);
    if ~exist(folderNameOut, 'dir')
       mkdir(folderNameOut)
    end
    for j=1:length(x{1}.data)
        name = x{1}.data{j}.config;
        [~, n] = size(name);
        for iStr=1:n
            if name(iStr) == ' '  
                name(iStr) = '_';
            end
        end
        fileName = sprintf('%s//%s.txt',folderNameOut,name);
        fp = fopen(fileName,'w');        
        data = x{1}.data{j}.PER_vs_SNR;
        while data(end,2)==0
            if data(end-1,2)==0
                data(end,:) = [];
            else
                break;
            end
        end
        for iData = 1:length(data(:,1))
            fprintf(fp,'%f\t%f\n',data(iData,1),data(iData,2));
        end
        fclose(fp);
    end
end