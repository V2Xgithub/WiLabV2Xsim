function [F,X]=ecdf(h,Y)
% ECDF empirical cumulative function  
%  NaN's are considered Missing values and are ignored. 
%
%  [F,X] = ecdf(Y)
%	calculates empirical cumulative distribution functions (i.e Kaplan-Meier estimate)
%  ecdf(Y)
%  ecdf(gca,Y)
%	without output arguments plots the empirical cdf, in axis gca. 
%
% Y 	input data
%	must be a vector or matrix, in case Y is a matrix, the ecdf for every column is computed. 
%
% see also: HISTO2, HISTO3, PERCENTILE, QUANTILE


%	$Id: ecdf.m 5814 2009-05-13 16:38:06Z schloegl $
%	Copyright (C) 2009 by Alois Schloegl <a.schloegl@ieee.org>	
%       This function is part of the NaN-toolbox
%       http://www.dpmi.tu-graz.ac.at/~schloegl/matlab/NaN/

%    This program is free software; you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation; either version 3 of the License, or
%    (at your option) any later version.
%
%    This program is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with this program; If not, see <http://www.gnu.org/licenses/>.

if ~isscalar(h) || ~ishandle(h) || isstruct(h),
	Y = h; 
	h = []; 
end; 	

DIM = [];

        SW = isstruct(Y);
        if SW, SW = isfield(Y,'datatype'); end;
        if SW, SW = strcmp(Y.datatype,'HISTOGRAM'); end;
        if SW,                 
                [yr,yc]=size(Y.H);
                if ~isfield(Y,'N');
                        Y.N = sum(Y.H,1);
                end;
		f = [zeros(1,yc);cumsum(Y.H,1)];
		for k=1:yc,
			f(:,k)=f(:,k)/Y.N(k); 
		end; 		
		t = [Y.X(1,:);Y.X]; 

        elseif isnumeric(Y),
		sz = size(Y);
		if isempty(DIM),
		        DIM = min(find(sz>1));
		        if isempty(DIM), DIM = 1; end;
		end;
		if DIM==2, Y=Y.'; DIM = 1; end;		
		
		t = sort(Y,1); 
		t = [t(1,:);t]; 	
		N = sum(~isnan(Y),1); 
		for k=1:size(Y,2),
			f(:,k)=[0:size(Y,1)]'/N(k); 
		end; 		
	end; 
	
	if nargout<1, 
		if  ~isempty(h), axes(h); end; 
		stairs(t,f);
	else 
		F = f;
		X = t; 	
	end; 			
