function fname = nullResponseFilename(runParams, opticsPostFix, PolansSubjectID)
    fname = sprintf('NullResponses_%2.0f_%2.0f_%2.0f_%2.0f_microns_coneSpecificity_%2.0f_PolansSID_%d_%s.mat', ...
            runParams.rgcMosaicPatchEccMicrons(1), runParams.rgcMosaicPatchEccMicrons(2), ...
            runParams.rgcMosaicPatchSizeMicrons(1), runParams.rgcMosaicPatchSizeMicrons(2), ...
            runParams.maximizeConeSpecificity, ...
            PolansSubjectID, opticsPostFix);
end

