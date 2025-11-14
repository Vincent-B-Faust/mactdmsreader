function outCell = mactdmsread(filename, varargin)
% mactdmsreader.m
% Copyright (c) 2025 LiuZY
% Licensed under GNU GPLv3
%
% This function depends on "TDMS Reader" by Jim Hokanson,
% Copyright (c) 2020 Jim Hokanson
% Licensed under BSD 3-Clause License
%
% Description:
% This MATLAB function provides macOS-compatible TDMS file reading,
% specifically designed to solve the issue where "mex TDMS" cannot be
% used on Apple Silicon Macs.
%
% This function is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This function is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details:
% <https://www.gnu.org/licenses/>.

%% ========================================================================
%  Author:  LiuZY
%  Date:    2025-11-13
%  MATLAB:  R2025b (Mac, Apple Silicon)
% ========================================================================

%% 为解决Apple Silicon无法使用mex TDMS的tdmsread问题，开发的macOS兼容 TDMS 文件读取函数

p = inputParser;
addRequired(p,'filename',@(x)ischar(x)||isstring(x));
addParameter(p,'Verbose',false,@islogical);
parse(p,filename,varargin{:}); opts=p.Results;

if ~isfile(filename), error('File not found: %s',filename); end
tdms=TDMS_readTDMSFile(filename);
if isempty(tdms.groupNames), error('No valid group in file.'); end

i=1; names=tdms.chanNames{i}; data=tdms.data(tdms.chanIndices{i});
if opts.Verbose, disp('原始通道名:'); disp(names(:)); end

f=@(x)stringify(x);
names=cellfun(f,names,'uni',0);
for k=1:numel(names)
    if isempty(strtrim(names{k})), names{k}=sprintf('Channel%d',k); end
end
names=matlab.lang.makeUniqueStrings(matlab.lang.makeValidName(names));
if opts.Verbose, disp('清理后通道名:'); disp(names(:)); end

valid=cellfun(@(x)isnumeric(x)&&~isempty(x),data);
names=names(valid); data=data(valid);
if isempty(data), error('No numeric channels found.'); end

len=cellfun(@numel,data); m=min(len(len>0));
for k=1:numel(data)
    v=data{k}; if isrow(v), v=v(:); end
    v(numel(v)+1:m,1)=NaN; data{k}=v(1:m);
end
mat=cat(2,data{:});

try
    T=array2table(mat,'VariableNames',cellfun(@char,names,'uni',0));
catch
    n=size(mat,2); T=array2table(mat,'VariableNames',compose("Channel%d",1:n));
end

idx=find(contains(lower(names),'time'),1);
if ~isempty(idx)
    try, outCell={table2timetable(T,'RowTimes',T.(names{idx}))}; return; end
end
outCell={T};
end

function s=stringify(x)
if isstring(x), s=char(x);
elseif iscell(x), s=stringify(x{1}); 
elseif isnumeric(x), s=num2str(x);
elseif ischar(x), s=x; else, s=''; end
end