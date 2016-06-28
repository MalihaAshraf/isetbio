function iStim = ieStimulusGabor(varargin)
% Creates a movie/dynamic of the cone absorptions of a drifting Gabor patch 
% 
%    ieStimulusGabor(varargin)
%
% The Gabor image is created with an equal photon spectral power
% distribution.  The parameters of the Gabor are set by the input structure
% (or key/value parameters) below.
%
% Inputs: 
%   pGabor: parameter structure that defines the Gabor stimulus parameters
%           The parameters and their defaults are 
%
% 'row',              4 x Nyquist   image size
% 'col',              4 x Nyquist   We multiply 4 times fov times freq
% 'meanLuminance',  200   (cd/m2)
% 'freq',            6    Spatial frequency c/deg
% 'contrast'         1    Harmonic contrast
% 'ph',              0    Phase of the harmonic
% 'ang',             0    Angle (0 = horizontal) of the grating variation
% 'GaborFlag',       1    Std of Gaussian where 1 means min(row,col) 
% 'fov',            0.6   Field of view
% 'expTime',        0.005 Exposure time of the sensor
% 'nCycles',        4     Number of cycles through the harmonic
% 'nSteps',         15*4    Total number of steps for all the harmonic cycles
%                         There are nSteps/nCycles per each cycle.
% 'distance'        0.3   Meters from the viewing screen
%
% Outputs: 
%   iStim - a structure that contains
%     params used to create this
%     scene (first frame)
%     sceneRGB
%     optical image (first frame)
%     human cone absorptions (dynamic)
% 
% Examples:
% Coarsely stepped, pretty tight Gabor window
%   nSteps = 20; GaborFlag = 0.2; fov = .5;
%   iStim = ieStimulusGabor('nSteps',nSteps,'GaborFlag',GaborFlag,'fov',fov);
%   m = coneImageActivity(iStim.absorptions,'dFlag',true);
%   sceneShowImage(iStim.scene);
%
%  Higher spatial frequency, more steps
%   params.freq = 6; params.nSteps = 50; params.GaborFlag = 0.2;
%   iStim = ieStimulusGabor(params);
%   dFlag.vname = 'Gabor_6f';
%   dFlag.FrameRate = 30;
%   coneImageActivity(iStim.absorptions,'dFlag',dFlag);
%   sceneShowImage(iStim.scene);
%
% 3/2016 JRG (c) isetbio team

%% Parse inputs
p = inputParser;

addParameter(p,'meanLuminance',  100,   @isnumeric);
addParameter(p,'nSteps',         60,    @isnumeric);
addParameter(p,'row',             0,    @isnumeric);  
addParameter(p,'col',             0,    @isnumeric);  
addParameter(p,'freq',            6,    @isnumeric);  
addParameter(p,'contrast',        1,    @isnumeric);  
addParameter(p,'ph',              0,    @isnumeric);  
addParameter(p,'ang',             0,    @isnumeric);  
addParameter(p,'GaborFlag',       1,    @isnumeric);  
addParameter(p,'expTime',        0.005, @isnumeric);
addParameter(p,'nCycles',        4, @isnumeric);

% Viewing parameters
addParameter(p,'fov',            0.6, @isnumeric);
addParameter(p,'distance',       0.3, @isnumeric);   % Distance to screen

% Field of view
p.parse(varargin{:});
params = p.Results;
fov = params.fov;
if params.row == 0
    % Make sure we have enough row and column samples to avoid aliasing the
    % frequency.  Four is arbitrary, but twice Nyquist.
   params.row = 4*params.freq*params.fov;
   params.col = 4*params.freq*params.fov;
end

%% Compute a scene

% Set up scene parameters
scene = sceneCreate('harmonic', params);
scene = sceneSet(scene, 'h fov', fov);
% vcAddObject(scene); sceneWindow;

%% Initialize the optics and the sensor
oi  = oiCreate('wvf human');
absorptions = sensorCreate('human');
absorptions = sensorSetSizeToFOV(absorptions, fov, scene, oi);

absorptions = sensorSet(absorptions, 'exp time', params.expTime); 
% absorptions = sensorSet(absorptions, 'time interval', params.timeInterval); 

%% Compute a dynamic set of cone absorptions
%
% We produce a scene video that translates into an oi video that becomes a
% cone absorption video.
%
% We recreate a set of scenes with different phase positions and produce
% the scenes, ois, and cone absorptions by the loop. The result will be a
% time series of the cone photon absorptions.
%
% We are reluctant to make scene(:,:,:,t) because we are frightened about
% the size.  But it still might be the right thing to do.  So the code here
% is an experiment and we aren't sure how it will go.

% ieSessionSet('wait bar',true);
wFlag = ieSessionGet('wait bar');
if wFlag, wbar = waitbar(0,'Stimulus movie'); end

% Loop through frames to build movie
for t = 1 : params.nSteps
    if wFlag, waitbar(t/params.nSteps,wbar); end
        
    % All we do is update the phase of the Gabor
    params.ph = (2*pi)*params.nCycles*(t-1)/params.nSteps; % one period over nSteps
    scene = sceneCreate('harmonic', params);
    
    scene = sceneAdjustLuminance(scene,params.meanLuminance);
    scene = sceneSet(scene,'distance',params.distance);
    
    if t ==1
        sceneRGB = zeros([sceneGet(scene, 'size'), params.nSteps, 3]);
    end
    scene = sceneSet(scene, 'h fov', fov);

    % Get scene RGB data    
    sceneRGB(:,:,t,:) = sceneGet(scene,'rgb');
    
    % Compute optical image
    oi = oiCompute(oi, scene);    
    
    % Compute absorptions
    absorptions = sensorCompute(absorptions, oi);

    if t == 1
        volts = zeros([sensorGet(absorptions, 'size') params.nSteps]);
    end
    
    volts(:,:,t) = sensorGet(absorptions, 'volts');
    
    % vcAddObject(scene); sceneWindow
end

if wFlag, delete(wbar); end

% Set the stimuls into the sensor object
absorptions = sensorSet(absorptions, 'volts', volts);
% vcAddObject(sensor); sensorWindow;

% Save all the inputs to rerun 
iStim.params   = params;     % Parameters to rerun this function
iStim.scene    = scene;      % Base scene
iStim.sceneRGB = sceneRGB;   % Used for identity case.
iStim.oi       = oi;         % 
iStim.absorptions   = absorptions;
end
