function [output,metaStruct] = TDMS_getStruct(filePath,structVersion,readOptions,structConvOptions)
%TDMS_getStruct  A wrapper for simplifying data retrieval from TDMS_readTDMSFile
%
%   output = TDMS_getStruct(*filePath,*structVer,*readOptions,*structConvOptions)
%
%   Optional Inputs
%   ---------------
%   filePath          : (default prompts for file)
%   structVersion     : (default 4, see code), determines which struct conversion
%                       function to use
%           Options are 1, 2, 3,or 4.
%           Essentialy, these options handle how the data are presented
%           to the user. 
%           1 - Converts data names to safe variable names
%           2 - This provides less of a structure and more iterable arrays
%           3 - Like 1, but translates data AND property names
%           4 - Gives even more fine control than 3 with renaming
%   readOptions       : (default {}), gets passed into TDMS_readTDMSFile
%   structConvOptions : (default {}), gets passed into conversion function
%
%
%   Examples
%   --------
%   %The most common usage
%   data = TDMS_getStruct(file_path)
%
%   %Use a different structure forming function
%   data = TDMS_getStruct(file_path,2)
%   
%   %Returns only properties and structure. For more advanced calls
%   %see TDMS_retrievingSubsets. Also, names the property field
%   %'Properties' instead of 'Props'
%   %[] - uses the default (4)
%   data = TDMS_getStruct(file_path,[],{'GET_DATA_OPTION','getnone'},{'prop_name','Properties'})
%   
%
%   See Also
%   --------
%   TDMS_retrievingSubsets
%   TDMS_readTDMSFile
%  	TDMS_dataToGroupChanStruct_v1
% 	TDMS_dataToGroupChanStruct_v2
% 	TDMS_dataToGroupChanStruct_v3
%  	TDMS_dataToGroupChanStruct_v4

%LOCAL CONSTANTS
DEFAULT_STRUCT_VERSION = 4;  %Feel free to change me if you'd like something different
%This is particular to my lab, although you might prefer 3
CONV_RANGE = [1 4];

%filePath input handling
if nargin < 1 || isempty(filePath)
   [filename,pathname] = uigetfile({'*.tdms'},'Choose TDMS file to read'); 
   if isequal(filename,0) || isequal(pathname,0) 
      return
   else
      filePath = fullfile(pathname,filename); 
   end
end

%structVer handling
if nargin < 2 || isempty(structVersion)
    structVersion = DEFAULT_STRUCT_VERSION;
end

%readOptions
if nargin < 3 || isempty(readOptions)
    readOptions = {};
end

%structConvOptions
if nargin < 4 || isempty(structConvOptions)
    structConvOptions = {};
end

if ~isnumeric(structVersion) || structVersion < CONV_RANGE(1) || structVersion > CONV_RANGE(2)
    error('The output structure version must be numeric and be between %d & %d',CONV_RANGE(1),CONV_RANGE(2))
end


%ACTUAL FILE READING
%==============================================================
[temp,metaStruct] = TDMS_readTDMSFile(filePath,readOptions{:});

%POST PROCESSING
%==============================================================
switch structVersion
    case 1
        output = TDMS_dataToGroupChanStruct_v1(temp,structConvOptions{:});
    case 2
        output = TDMS_dataToGroupChanStruct_v2(temp,structConvOptions{:});
    case 3
        output = TDMS_dataToGroupChanStruct_v3(temp,structConvOptions{:});
    case 4
        output = TDMS_dataToGroupChanStruct_v4(temp,structConvOptions{:});
end