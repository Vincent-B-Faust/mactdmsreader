function data_size = TDMS_getDataSize(data_type)
%TDMS_getDataSize  Returns data size in bytes
%
%   This function is used to return the size of raw data for predicting the
%   # of chunks of raw data
%
%   dataSize = TDMS_getDataSize(dataType)
%
%   Inputs
%   ------
%   dataType : Labview dataType
%   
%   Outputs
%   -------
%   dataSize : size in bytes 
%
%   CALLED BY:
%   - TDMS_preprocessFile
%   - TDMS_handleGetDataOption
%
%   See Also
%   --------
%   TDMS_getPropValue
%   TDMS_getDataTypeName

%https://www.ni.com/en-us/support/documentation/supplemental/07/tdms-file-format-internal-structure.html

%   tdsDataType enum
switch data_type
    case 1 %int8
        data_size = 1;
    case 2 %int16
        data_size = 2;
    case 3 %int32
        data_size = 4;
    case 4 %int64
        data_size = 8;
    case 5 %uint8
        data_size = 1;
    case 6 %uint16
        data_size = 2;
    case 7 %uint32
        data_size = 4;
    case 8 %uint64
        data_size = 8;
    case 9 %Single
        data_size = 4;
    case 10 %Double
        data_size = 8;
    case 25 %Single with unit
        %hex2dec('19')
        data_size = 4;
    case 26 %Double with unit
        data_size = 8;
    case 32
        error('The size of strings is variable, this shouldn''t be called')
    case 33 %logical
        data_size = 1;
    case 68 %timestamp => uint64, int64
        data_size = 16;
    case 524300 %complex single float
        %hex2dec('8000c')
        data_size = 8;
    case 1048589 %complex double float
        %hex2dec('10000d')
        data_size = 16;
%     case intmax('uint32')
%         %DAQmx
%         dataSize = 2; %Will need to be changed
%         %keyboard
    otherwise
        switch data_type
            case 0
                unhandled_type = 'Void';
            case 11
                unhandled_type = 'Extended float';
                %SIZE: 12 bytes
            case 27
                unhandled_type = 'Extended float with unit';
                %SIZE: 12 bytes
            case 79
                %What's the binary footprint of this?
                unhandled_type = 'Fixed Point';
            case intmax('uint32')
                unhandled_type = 'DAQmx';
                %size?
                %Unfortunately they won't say so I can't just skip it ...
            otherwise
                error('Unrecognized unhandled data type : %d',data_type)
        end
        error('Unhandled property type: %s',unhandled_type)
        %IMPROVEMENT:
        %We could fail silently and document this in the
        %structure (how to read DAQmx (how big to skip?)
end