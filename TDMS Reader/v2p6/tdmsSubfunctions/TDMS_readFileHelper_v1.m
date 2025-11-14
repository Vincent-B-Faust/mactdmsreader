function data = TDMS_readFileHelper_v1(fid,optionStruct,metaStruct,paramsStruct)
%TDMS_readFileHelper_v1
%
%

% Time stamps in TDMS are stored as a structure of two components:
% (i64) seconds: since the epoch 01/01/1904 00:00:00.00 UTC (using the Gregorian calendar and ignoring leap seconds)
% (u64) positive fractions: (2^-64) of a second
% Boolean values are stored as 1 byte each, where 1 represents TRUE and 0 represents FALSE.


SECONDS_IN_DAY  = paramsStruct.SECONDS_IN_DAY;
CONV_FACTOR     = paramsStruct.CONV_FACTOR;
UTC_DIFF        = paramsStruct.UTC_DIFF;
STRING_ENCODING = paramsStruct.STRING_ENCODING;

%INPUT UNPACKING
%==========================================================================
keepDataArray        = optionStruct.keepDataArray;
numValuesToGetActual = optionStruct.numValuesToGetActual;

rawDataInfo      = metaStruct.rawDataInfo;
segInfo          = metaStruct.segInfo;
numberDataPoints = metaStruct.numberDataPoints;

n_objects = length(rawDataInfo);
n_segs    = length(segInfo);

%INITIALIZATION OF OBJECTS
%==========================================================================
cur_file_index  = zeros(1,n_objects); %current # of samples read from file
cur_data_index  = zeros(1,n_objects); %current # of samples assigned to output
data          = cell(1,n_objects);  %a pointer for each channel
data_type_array = [rawDataInfo.dataType];
total_bytes_arrray = [rawDataInfo.totalSizeBytes];

propNames  = cell(1,n_objects);
propValues = cell(1,n_objects);

for iObject = 1:n_objects
    propNames{iObject}  = rawDataInfo(iObject).propNames;
    propValues{iObject} = rawDataInfo(iObject).propValues;
    if numberDataPoints(iObject) > 0 && keepDataArray(iObject)
        data{iObject} = TDMS_initData(data_type_array(iObject),numberDataPoints(iObject));
    end
end

%==================================================================
%                        RAW DATA PROCESSSING
%==================================================================

%This will be used later for fread and fseek
%Simplifies the switch statements
[precision_type, nBytes] = TDMS_getTypeSeekSizes;

%Get end of file position, seek back to beginning
fseek(fid,0,1);
eofPosition = ftell(fid);
fseek(fid,0,-1);

for iSeg = 1:n_segs
    cur_seg = segInfo(iSeg);
    %Seek to this raw position, this is needed to avoid meta data
    fseek(fid,cur_seg.rawPos,'bof');
    
    nChunksUse = cur_seg.nChunks;
    for iChunk = 1:nChunksUse
        %------------------------------------------------------------------
        %Interleaved data processing
        %------------------------------------------------------------------
        if cur_seg.isInterleaved
            obj_order  = cur_seg.objOrder;
            dataTypes = data_type_array(obj_order);
            nRead     = cur_seg.nSamplesRead;
            
            %error checking
            if any(dataTypes ~= dataTypes(1))
                error('Interleaved data is assumed to be all of the same type')
            end
            
            if any(nRead ~= nRead(1))
                error('# of values to read are not all the same')
            end
            
            %NOTE: unlike below, these are arrays that we are working with
            startI = cur_file_index(obj_order) + 1;
            endI   = cur_file_index(obj_order) + nRead(1);
            cur_file_index(obj_order) = endI;
            cur_data_index(obj_order) = endI;
            
            nChans        = length(obj_order);
            numValuesRead = nRead(1);
            switch dataTypes(1)
                case {1 2 3 4 5 6 7 8 9 10}
                    temp = fread(fid,numValuesRead*nChans,precision_type{dataTypes(1)});
                case 32
                    error('Unexpected interleaved string data')
                    %In Labview 2009, the interleaved input is ignored
                    %Not sure about other versions
                case 33
                    %This never seems to be called, shows up as uint8 :/
                    temp = logical(fread(fid,numValuesRead*nChans,'uint8'));
                case 68
                    temp = fread(fid,numValuesRead*2*nChans,'*uint64');
                    temp = (double(temp(1:2:end))/2^64 + double(typecast(temp(2:2:end),'int64')))...
                        /SECONDS_IN_DAY + CONV_FACTOR + UTC_DIFF/24;
                case 524300
                    temp = fread(fid,2*numValuesRead*nChans,'*single');
                    temp = complex(temp(1:2:end),temp(2:2:end));
                case 1048589
                    temp = fread(fid,2*numValuesRead*nChans,'*double');
                    temp = complex(temp(1:2:end),temp(2:2:end));
                otherwise
                    error('Unexpected data type: %d',dataTypes(1))
                    
            end
            
            %NOTE: When reshaping for interleaved, we must put nChans as
            %the rows, as that is the major indexing direction, we then
            %grab across columns
            %Channel 1 2 3 1  2  3
            %Data    1 2 3 11 22 33 becomes:
            %   1 11
            %   2 22    We can now grab rows to get individual channels
            %   3 33
            temp = reshape(temp,[nChans numValuesRead]);
            for iChan = 1:nChans
                if keepDataArray(obj_order(iChan))
                    data{obj_order(iChan)}(startI(iChan):endI(iChan)) = temp(iChan,:);
                end
            end
            
        else
            
            %--------------------------------------------------------------
            %NOT INTERLEAVED
            %--------------------------------------------------------------
            for iObjList = 1:length(cur_seg.objOrder)
                I_object = cur_seg.objOrder(iObjList);
                
                numValuesAvailable = cur_seg.nSamplesRead(iObjList);
                dataType = data_type_array(I_object);
                
                cur_file_index(I_object) = cur_file_index(I_object) + numValuesAvailable;
                
                %Actual reading of data (or seeking past)
                %------------------------------------------
                if ~keepDataArray(I_object)
                    if dataType == 32
                        %I don't think we need the data type check if we
                        %use this ...
                        n_string_bytes = total_bytes_arrray(I_object);
                        fseek(fid,n_string_bytes,'cof');
                    else
                        fseek(fid,numValuesAvailable*nBytes(dataType),'cof');
                    end
                else
                    startI = cur_data_index(I_object) + 1;
                    endI   = cur_data_index(I_object) + numValuesAvailable;
                    cur_data_index(I_object) = endI;
                    switch dataType
                        case {1 2 3 4 5 6 7 8 9 10}
                            data{I_object}(startI:endI) = fread(fid,numValuesAvailable,precision_type{dataType});
                        case 32
                            %Done above now ...
                            strOffsetArray = [0; fread(fid,numValuesAvailable,'uint32')];
                            offsetString = startI - 1;
                            for iString = 1:numValuesAvailable
                                offsetString = offsetString + 1;
                                temp = fread(fid,strOffsetArray(iString+1)-strOffsetArray(iString),'*uint8');
                                data{I_object}{offsetString}  = native2unicode(temp,STRING_ENCODING)'; %#ok<*N2UNI>
                            end
                            %NOTE: Even when using a subset, we
                            %will only ever have one valid read
                        case 33
                            data{I_object}(startI:endI)   = logical(fread(fid,numValuesAvailable,'uint8'));
                        case 68
                            temp = fread(fid,numValuesAvailable*2,'*uint64');
                            %First row: conversion to seconds
                            %Second row: conversion to days, and changing of reference frame
                            data{I_object}(startI:endI) = (double(temp(1:2:end))/2^64 + double(typecast(temp(2:2:end),'int64')))...
                                /SECONDS_IN_DAY + CONV_FACTOR + UTC_DIFF/24;
                        case 524300
                            temp = fread(fid,2*numValuesAvailable,'*single');
                            data{I_object}(startI:endI) = complex(temp(1:2:end),temp(2:2:end));
                        case 1048589
                            temp = fread(fid,2*numValuesAvailable,'*double');
                            data{I_object}(startI:endI) = complex(temp(1:2:end),temp(2:2:end));
                        otherwise
                            error('Unexpected type: %d', dataType)
                    end
                end
            end
        end
    end
    
    
    %Some error checking just in case
    if iSeg ~= n_segs
        Ttag = fread(fid,1,'uint8');
        Dtag = fread(fid,1,'uint8');
        Stag = fread(fid,1,'uint8');
        mtag = fread(fid,1,'uint8');
        if ~(Ttag == 84 && Dtag == 68 && Stag == 83 && mtag == 109)
            error('Catastrophic error detected, code probably has an error somewhere')
        end
    else
        if eofPosition ~= ftell(fid) && ~metaStruct.eof_error
            error('Catastrophic error detected, code probably has an error somewhere')
        end
    end
end

%ERROR CHECKING ON # OF VALUES READ
%==========================================================================
if ~isequal(numValuesToGetActual,cur_data_index)
    error('The # of requested values does not equal the # of returned values, error in code likely')
end

%END OF READING RAW DATA
%==========================================================================
fclose(fid);
