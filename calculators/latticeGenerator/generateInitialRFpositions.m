function [rfPositions, lambdaMicrons] = generateInitialRFpositions(mosaicWidthDegs, neuronalType)

    % Instantiate a WatsonRGCModel
    WatsonOBJ = WatsonRGCModel();
    
    % Determine smallest spacing (delta)
    switch (neuronalType)
        case 'cone'
            lambdaConesMM = WatsonOBJ.coneRFSpacingAndDensityAlongMeridian(0, 'nasal meridian', 'deg', 'mm^2', ...
                'correctForMismatchInFovealConeDensityBetweenWatsonAndISETBio', false);
            lambdaMicrons = lambdaConesMM * 1000;
        case 'mRGC'
            lambdaMidgetsMM = WatsonOBJ.mRGCRFSpacingAndDensityAlongMeridian(0, 'nasal meridian', 'deg', 'mm^2', ...
                 'adjustForISETBioConeDensity', true);
            lambdaMidgetsOnOrOffMM = sqrt(2.0)*lambdaMidgetsMM;
            lambdaMicrons = lambdaMidgetsOnOrOffMM * 1000;
        otherwise
            error('Unknown neuronalType: ''%s''.', neuronalType)
    end
    
    % Determine mosaicWidth in retinal microns
    mosaicRadiusRetinalMicrons = WatsonOBJ.rhoDegsToMMs(0.5*mosaicWidthDegs)*1000;
    
    % Generate a mosaic that is 20% larger to minimize edge effects
    margin = 1.2;
    radius = margin*mosaicRadiusRetinalMicrons;
    rows = ceil(2 * radius);
    cols = rows;
    
    fprintf('Will generate regular hex grid for %s with min spacing of %2.2f microns\n', neuronalType, lambdaMicrons);
    rfPositions = generateRegularHexGrid(rows, cols, lambdaMicrons);
end

function hexLocs = generateRegularHexGrid(rows, cols, lambda)
    
    scaleF = sqrt(3) / 2;
    extraCols = round(cols / scaleF) - cols;
    rectXaxis2 = (1:(cols + extraCols));
    [X2, Y2] = meshgrid(rectXaxis2, 1:rows);

    X2 = X2 * scaleF ;
    for iCol = 1:size(Y2, 2)
        Y2(:, iCol) = Y2(:, iCol) - mod(iCol - 1, 2) * 0.5;
    end

    % Scale for lambda
    X2 = X2 * lambda;
    Y2 = Y2 * lambda;
    marginInRFPositions = 0.1;
    indicesToKeep = (X2 >= -marginInRFPositions) & ...
                    (X2 <= cols+marginInRFPositions) &...
                    (Y2 >= -marginInRFPositions) & ...
                    (Y2 <= rows+marginInRFPositions);
    xHex = X2(indicesToKeep);
    yHex = Y2(indicesToKeep);
    
    % Center central cone at (0,0)
    hexLocs = [xHex(:) - mean(xHex(:)) yHex(:) - mean(yHex(:))];
    mins = min(abs(hexLocs),[],1);
    hexLocs = bsxfun(@minus, hexLocs, [mins(1) 0]);
end