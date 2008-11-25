function [report]=seizmocheck(data,varargin)
%SEIZMOCHECK    Validate SEIZMO data structure
%
%    Description: SEIZMOCHECK(DATA) returns an appropriate error message 
%     structure if the input variable fails certain SEIZMO data structure 
%     requirements.  The output structure contains the fields 'identifier'
%     and 'message' following Matlab error report standards.
%
%     SEIZMOCHECK(DATA,FIELD1,...,FIELDN) allows more fields to be required
%     in addition to the default ones.  FIELD must be a string.
%
%    Notes:
%     - Current SEIZMO Structure Requirements
%       - Fields: location, name, filetype, version, 
%                 byteorder, hasdata, head
%       - All default fields must be nonempty
%       - All default fields must be valid
%     - Non-default fields are not required to be nonempty or valid
%     - See examples for non-default field uses
%
%    Tested on: Matlab r2007b
%
%    Usage:    error(seizmocheck(data))
%              error(seizmocheck(data,'requiredfield',...,'requiredfield'))
%
%    Examples:
%     Most functions require records have data stored in the field 'dep'.
%     This will perform a regular check as well as assure the field exists:
%      error(seizmocheck(data,'dep')
%
%    See also: isseizmo, seizmodef

%     Version History:
%        Feb. 28, 2008 - initial version
%        Mar.  2, 2008 - require nonempty data structure
%        Mar.  4, 2008 - fix error statement
%        Apr. 18, 2008 - fixed isfield to work with R14sp1
%        June 12, 2008 - doc update
%        Sep. 14, 2008 - doc update, input checks, return on first issue
%        Sep. 25, 2008 - checks versions are valid
%        Oct. 15, 2008 - data no longer required to be vector; require the
%                        name, endian, and hasdata fields by default now; 
%                        require that fields name, endian, version, hasdata
%                        and head are not empty and are valid for each
%                        record
%        Oct. 17, 2008 - require new fields DIR and FILETYPE
%        Oct. 27, 2008 - LOCATION field replaces DIR field, vectorized
%                        using cellfun, global SEIZMO allows skipping check
%        Oct. 30, 2008 - little simpler code for checking required fields
%        Nov. 13, 2008 - renamed from SEISCHK to SEIZCHK
%        Nov. 15, 2008 - update for the new name scheme (now SEIZMOCHECK),
%                        change endian to byteorder, .dep special handling
%
%     Written by Garrett Euler (ggeuler at wustl dot edu)
%     Last Updated Nov. 15, 2008 at 18:50 GMT

% todo:

% check input
report=[];
if(nargin<1)
    error('seizmo:seizmocheck:notEnoughInputs','Not enough input arguments.');
elseif(nargin>1)
    if(~iscellstr(varargin))
        error('seizmo:seizmocheck:badInput',...
            'Additional arguments must be strings!');
    end
end

% check SEIZMO global for quick exit
global SEIZMO
try
    if(~SEIZMO.SEIZMOCHECK.ON); return; end
catch
    % checks data below
end

% check data structure
if(~isstruct(data))
    report.identifier='seizmo:seizmocheck:dataNotStruct';
    report.message='SEIZMO data must be in a structure!';
    return;
elseif(isempty(data))
    report.identifier='seizmo:seizmocheck:dataEmpty';
    report.message='SEIZMO struct must not be empty!';
    return;
else
    defreqfields={'location' 'name' 'filetype'...
        'version' 'byteorder' 'hasdata' 'head'};
    reqfields=sort([defreqfields varargin]);
    fields=sort(fieldnames(data).');
    
    % check that all required fields are present
    if(~isempty(setdiff(reqfields,fields)))
        i=setdiff(reqfields,fields);
        report.identifier='seizmo:seizmocheck:reqFieldNotFound';
        report.message=sprintf(...
            'SEIZMO data structure must have field ''%s''!',i{1});
        return;
    end
    
    % compile into cell arrays
    locations={data.location};
    names={data.name};
    endians={data.byteorder};
    versions={data.version};
    filetypes={data.filetype};
    hasdatas={data.hasdata};
    headers={data.head};
    
    % check each using cellfun
    if(any(cellfun('isempty',locations)) || ~iscellstr(locations))
        report.identifier='seizmo:seizmocheck:nameBad';
        report.message=['SEIZMO struct LOCATION field must be a '...
            'nonempty string!'];
    elseif(any(cellfun('isempty',names)) || ~iscellstr(names))
        report.identifier='seizmo:seizmocheck:dirBad';
        report.message=['SEIZMO struct NAME field must be a '...
            'nonempty string!'];
    elseif(any(cellfun('isempty',endians)) || ~iscellstr(endians) ||...
            ~all(strcmpi(endians,'ieee-be') | strcmpi(endians,'ieee-le')))
        report.identifier='seizmo:seizmocheck:endianBad';
        report.message=['SEIZMO struct BYTEORDER field must be '...
            '''ieee-le'' or ''ieee-be''!'];
    elseif(any(cellfun('isempty',hasdatas)) ||...
            ~all(cellfun('islogical',hasdatas)))
        report.identifier='seizmo:seizmocheck:hasdataBad';
        report.message='SEIZMO struct HASDATA field must be a logical!';
    elseif(any(cellfun('isempty',filetypes)) || ~iscellstr(filetypes)...
            || any(cellfun('prodofsize',versions)~=1)...
            || any(cellfun('isempty',cellfun(@(x,y)intersect(x,y),...
            cellfun(@(x)validseizmo(x),filetypes,'UniformOutput',false),...
            versions,'UniformOutput',false))))
        report.identifier='seizmo:seizmocheck:versionBad';
        report.message=['SEIZMO struct FILETYPE and VERSION fields '...
            'must be valid!'];
    elseif(any(cellfun('size',headers,1)~=302)...
            || any(cellfun('size',headers,2)~=1)...
            || any(cellfun('ndims',headers)~=2))
        report.identifier='seizmo:seizmocheck:headerBad';
        report.message='SEIZMO struct HEAD field must be 302x1';
    end
    
    % special handling of dep field
    if(any(strcmpi(reqfields,'dep')))
        if(any(~[data.hasdata]))
            report.identifier='seizmo:seizmocheck:needData';
            report.message='All records must have data read in!';
        end
    end
end

end