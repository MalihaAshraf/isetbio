function runPhaseX(runParams)

    % Intermediate files directory
    saveDir = strrep(fileparts(which(mfilename())), 'processing', 'responseFiles');
    
    % Figure exports dir
    figExportsDir = strrep(fileparts(which(mfilename())), 'processing', 'exports');
    
    % Compute cone mosaic responses
    recomputeConeMosaicResponses = true;
    recomputeNullResponses = true;
    
    % Load/Recompute connected mosaics and the optics
    recomputeMosaicAndOptics = ~true;
    recomputeOpticsOnly = ~true;
    [theConeMosaic, theMidgetRGCmosaic, theOptics] = mosaicsAndOpticsForEccentricity(runParams, recomputeMosaicAndOptics, recomputeOpticsOnly, saveDir);

    displayPSFs = ~true;
    if (displayPSFs)
        eccDegs = WatsonRGCModel.rhoMMsToDegs(1e-3*runParams.rgcMosaicPatchEccMicrons);
        visualizePSFs(theOptics, eccDegs(1), eccDegs(2));
    end
    
    % Stimulation parameters
    LMScontrast = [0.1 0.0 0.0];
    minSF = 0.1;
    maxSF = 60;
    spatialFrequenciesCPD = logspace(log10(minSF), log10(maxSF),12);
    spatialFrequenciesCPD = spatialFrequenciesCPD(spatialFrequenciesCPD>1.8);
    
    stimulusFOVdegs = 2.0;
    minPixelsPerCycle = 10;
    stimulusPixelsNum = maxSF*stimulusFOVdegs*minPixelsPerCycle;
    temporalFrequency = 4.0;
    stimDurationSeconds = 0.5;
    instancesNum = 16;
    
    % Visualized cells
    targetRGCs = [52]; %[3 14 52];
    
    stimColor = struct(...
        'backgroundChroma', [0.3, 0.31], ...
        'meanLuminanceCdPerM2', 40, ...
        'lmsContrast', LMScontrast);
    
    stimTemporalParams = struct(...
        'temporalFrequencyHz', temporalFrequency, ...
        'stimDurationSeconds', stimDurationSeconds);
    
    stimSpatialParams = struct(...
        'type', 'driftingGrating', ...
        'fovDegs', stimulusFOVdegs,...
        'pixelsNum', stimulusPixelsNum, ...
        'gaborPosDegs', [0 0], ...
        'gaborSpatialFrequencyCPD', 0, ...
        'gaborSigmaDegs', Inf, ... %stimulusFOVdegs/(2*4), ...%Inf, ...
        'gaborOrientationDegs', 0, ...
        'deltaPhaseDegs', []);
    
    % Signal to the RGCs
    rgcInputSignal = 'isomerizations';
    %rgcInputSignal = 'photocurrents';
    
    if (recomputeConeMosaicResponses)
        computeConeResponses(runParams, ...
            stimColor,  stimTemporalParams, stimSpatialParams, ...
            theConeMosaic, theOptics, ...
            recomputeNullResponses, ...
            instancesNum, ...
            spatialFrequenciesCPD, ...
            saveDir);
    else
        visualizeAllSpatialFrequencyTuningCurves = false;
        visualizeResponseComponents = ~true;
        computeRGCresponses(runParams, theConeMosaic, theMidgetRGCmosaic, ...
            rgcInputSignal, spatialFrequenciesCPD, LMScontrast, ...
            stimSpatialParams, stimTemporalParams, targetRGCs, ...
            saveDir, figExportsDir, ...
            visualizeAllSpatialFrequencyTuningCurves, visualizeResponseComponents);
    end
end