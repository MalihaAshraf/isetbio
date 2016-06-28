function val = osGet(obj, varargin)
% Gets the isetbio outersegment object parameters.
% 
% Parameters:
%       {'patchSize'} - cone current as a function of time
%       {'timeStep'} - noisy cone current signal
%       {'rgbData'} - scene RGB data to pass to "black box" RGC GLM model.
%       {'size'} - array size of scene RGB data
% 
% osGet(adaptedOS, 'noiseFlag')
% 
% 8/2015 JRG 

% Check for the number of arguments and create parser object.
% 
% Check key names with a case-insensitive string, errors in this code are
% attributed to this function and not the parser object.
narginchk(0, Inf);
p = inputParser; p.CaseSensitive = false; p.FunctionName = mfilename;

% Make key properties that can be set required arguments.
allowableFieldsToSet = {...
    'noiseflag',...
    'rgbdata',...
    'patchsize',...
    'timestep',...
    'size'};
p.addRequired('what',@(x) any(validatestring(ieParamFormat(x),allowableFieldsToSet)));

% Parse and put results into structure p.
p.parse(varargin{:}); params = p.Results;

switch ieParamFormat(params.what);  % Lower case and remove spaces
                
    case{'patchsize'}
        val = obj.patchSize;
        
    case{'timestep'}
        val = obj.timeStep;
        
    case{'rgbdata'}
        val = obj.rgbData;
        
    case{'size'}
        val = size(obj.rgbData);
        
end

