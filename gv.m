function [version,endian]=gv(filename)
%GV    Get version and byte-order of SAClab datafile
%
%    Description: [VERSION,ENDIAN]=GV(FILENAME) determines the version 
%     VERSION and byte-order ENDIAN of a SAClab compatible file FILENAME.  
%     Currently this is solely based on the header version field validity 
%     - a 32bit signed integer occupying bytes 305 to 308.  If the datafile
%     cannot be validated (usually occurs when the file is not a SAClab 
%     datafile or cannot be opened) a warning is issued, VERSION is set to
%     0, and ENDIAN is left empty.
%
%    Notes:
%
%    System requirements: Matlab
%
%    Data requirements: single string input
%
%    Usage:    [version,endian]=gv('filename')
%
%    Examples:
%     Figure out a file's version so that we can pull up the definition:
%      version=gv('myfile')
%      def=seisdef(version)
%
%    See also:  rh, wh, seisdef, vvseis

%     Version History:
%        Jan. 27, 2008 - initial version
%        Feb. 23, 2008 - minor doc update
%        Feb. 28, 2008 - uses vvseis now, fix warnings
%        Mar.  4, 2008 - doc update, fix warnings
%        June 12, 2008 - doc update
%        Sep. 14, 2008 - minor doc update, input checks
%
%     Written by Garrett Euler (ggeuler at wustl dot edu)
%     Last Updated Sep. 14, 2008 at 17:25 GMT

% todo:

% check input
error(nargchk(1,1,nargin))
if(~ischar(filename))
    error('SAClab:gv:badInput','FILENAME must be a string!');
end

% get valid versions
valid=vvseis();

% preset version/endian to invalid
version=0; endian='';

% open file for reading
fid=fopen(filename);

% check for invalid fid (for directories etc)
if(fid<0)
    warning('SAClab:gv:badFID','File not openable, %s !',filename);
    return;
end

% seek to version field
try
    fseek(fid,304,'bof');
catch
    % seek failed
    fclose(fid);
    warning('SAClab:gv:fileTooShort','File too short, %s !',filename);
    return;
end

% at end of file
if(feof(fid))
    % seeked to eof...
    fclose(fid);
    warning('SAClab:gv:fileTooShort','File too short, %s !',filename);
    return;
end

% read in version as little-endian
endian='ieee-le';
try
    version=fread(fid,1,'int32',endian);
catch
    % read version failed - close file and warn
    fclose(fid);
    warning('SAClab:gv:readVerFail',...
        'Unable to read header version of file, %s !',filename);
    version=0;
    return;
end

% check if valid
if(isempty(version))
    % read returned nothing...
    fclose(fid);
    warning('SAClab:gv:readVerFail',...
        'Unable to read header version of file, %s !',filename);
    version=0;
    return;
elseif(~any(valid==version))
    % no good - seek back and read as big-endian
    fseek(fid,-4,'cof');
    endian='ieee-be';
    try
        version=fread(fid,1,'int32',endian);
    catch
        % read version failed - close file and warn
        fclose(fid);
        warning('SAClab:gv:readVerFail',...
            'Unable to read header version of file, %s !',filename);
        version=0;
        return;
    end
    
    % check if valid
    if(~any(valid==version))
        % no good again - close file and warn
        fclose(fid);
        warning('SAClab:gv:versionUnknown',...
            'Unknown header version for file, %s !',filename);
        version=0;
        return;
    end
end
fclose(fid);

end
