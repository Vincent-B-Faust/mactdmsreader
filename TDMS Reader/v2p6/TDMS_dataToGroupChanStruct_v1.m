function output = TDMS_dataToGroupChanStruct_v1(inputStruct,varargin)
%TDMS_dataToGroupChanStruct_v1  
%
%   output = TDMS_dataToGroupChanStruct_v1(inputStruct)
%
%   See Also: TDMS_genvarname2

REPLACE_STR = '_';
PREPEND_STR = 'v';
ALWAYS_PREPEND = false;

for i = 1:2:length(varargin)
    switch upper(varargin{i})
        case 'REPLACE_STR'
            REPLACE_STR = varargin{i+1};
        case 'PREPEND_STR'
            PREPEND_STR = varargin{i+1};
        case 'ALWAYS_PREPEND'
            ALWAYS_PREPEND = varargin{i+1};
        otherwise
            error('Unrecognized option: %s',varargin{i});
    end
end


propNames    = inputStruct.propNames;
propValues   = inputStruct.propValues;
groupIndices = inputStruct.groupIndices;
groupNames   = inputStruct.groupNames;
chanIndices  = inputStruct.chanIndices;
chanNames    = inputStruct.chanNames;
rootIndex    = inputStruct.rootIndex;
data         = inputStruct.data;

output = struct('props',...
    struct('name',{propNames{rootIndex}},'value',{propValues{rootIndex}})); %#ok<*CCAT1>

for iGroup = 1:length(groupIndices)
    curGroupIndex = groupIndices(iGroup);
    curChanIndices = chanIndices{iGroup};
    curChanNames   = chanNames{iGroup};
    groupStruct = struct('name',groupNames(iGroup),'props',...
        struct('name',{propNames{curGroupIndex}},...
        'value',{propValues{curGroupIndex}}));
    for iChan = 1:length(curChanIndices)
        curChanIndex = curChanIndices(iChan);
        chanStruct =  struct('name',curChanNames{iChan},'props',...
            struct('name',{propNames{curChanIndex}},...
            'value',{propValues{curChanIndex}}),...
            'data',[]);
        chanStruct.data = data{curChanIndex};
        %NOTE: I had a case statement in case the data type was a string,
        %which would change the interpretation of the struct input
        groupStruct.(TDMS_genvarname2(chanStruct.name,...
            REPLACE_STR,PREPEND_STR,ALWAYS_PREPEND)) = chanStruct;
    end
    output.(TDMS_genvarname2(groupStruct.name,...
        REPLACE_STR,PREPEND_STR,ALWAYS_PREPEND)) = groupStruct;
end
