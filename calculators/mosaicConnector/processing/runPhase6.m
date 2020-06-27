% Phase 6: Compute weights of cone inputs to mRGC  RF centers and surrounds
function runPhase6(runParams)

    connectivityFile = fullfile(runParams.outputDir, sprintf('%s.mat',runParams.inputFile));
    load(connectivityFile, ...
            'conePositionsMicrons', 'coneSpacingsMicrons', 'coneTypes', ...
            'RGCRFPositionsMicrons', 'RGCRFSpacingsMicrons', ...
            'desiredConesToRGCratios', 'midgetRGCconnectionMatrix');
        
    [midgetRGCconnectionMatrixCenter, midgetRGCconnectionMatrixSurround, ...
        synthesizedRFParams] = ...
        computeWeightedConeInputsToRGCCenterSurroundSubregions(...
            conePositionsMicrons, coneSpacingsMicrons, coneTypes, ...
            RGCRFPositionsMicrons, ...
            midgetRGCconnectionMatrix, ...
            runParams.patchEccDegs, runParams.patchSizeDegs);
    
    % Save cone weights to center/surround regions
    saveDataFile = sprintf('%s_inPatchAt_%2.1f_%2.1fdegs_WithSize_%2.2f_%2.2f.mat', ...
        runParams.outputFile, runParams.patchEccDegs(1), runParams.patchEccDegs(2), ...
        runParams.patchSizeDegs(1), runParams.patchSizeDegs(2));
        
    patchEccDegs = runParams.patchSizeDegs;
    patchSizeDegs = runParams.patchEccDegs;
    save(fullfile(runParams.outputDir, saveDataFile), ...
            'conePositionsMicrons', 'coneSpacingsMicrons', 'coneTypes', ...
            'RGCRFPositionsMicrons', 'RGCRFSpacingsMicrons', 'desiredConesToRGCratios', ...
            'midgetRGCconnectionMatrixCenter', 'midgetRGCconnectionMatrixSurround', ...
            'synthesizedRFParams', 'patchEccDegs', 'patchSizeDegs', '-v7.3');
end

