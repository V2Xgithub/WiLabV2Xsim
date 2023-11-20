function value = searchParamInCfgFile(filename,paramname,paramType)
% Function used to search for a given parameter in the config file

value = NaN;

fid = fopen(filename);
if fid==-1
    return    
end
[C]=textscan(fid,'%s %s','CommentStyle','%');
fclose(fid);

params = C{1};
values = C{2};
for i=1:length(params)
    parameter = char(params(i));
    if parameter(1)=='[' && parameter(end)==']' && strcmpi(parameter(2:end-1),paramname)

        if strcmpi(paramType,'integer') || strcmpi(paramType,'double')
            value = str2double(values(i));
        elseif strcmpi(paramType,'string')
            value = values{i};
        elseif strcmpi(paramType,'bool')

            if strcmpi(values(i),'true')
                value = true;
            elseif strcmpi(values(i),'false')
                value = false;
            else
             values{i}
                error('Error: parameter %s must be a boolean.',params(i));
            end
        elseif strcmpi(paramType,'integerOrArrayString')
            %if ischar(values(i))
                value = str2num(values{i});
            %else
            %    value = str2double(values(i));
            %end                
        else
            error('Error in searchParamInCfgFile: paramType can be only integer, double, string, or bool.');
        end
               
        return
    end
end
