function varargout = v_osBioPhysStepBriefFlashesResponses(varargin)
% Validate the biophysical model for very brief flashes on different
% pedestals.
%
% This script tests the biophysically-based outer segment model of 
% photon isomerizations to photocurrent transduction that occurs in the
% cone outer segments.
%
% 1/12/16      npc   Created after separating the relevant 
%                    components from s_coneModelValidate.

    varargout = UnitTest.runValidationRun(@ValidationFunction, nargout, varargin);
end

%% Function implementing the isetbio validation code
function ValidationFunction(runTimeParams)

    %% Init
    ieInit;
    
    % Set the simulation time interval. In general, the stimulation time interval should 
    % be set to a small enough value so as to avoid overflow errors.
    simulationTimeIntervalInSeconds = 1e-4;
    
    % create human sensor with 1 cone
    sensor = sensorCreate('human');
    sensor = sensorSet(sensor, 'size', [1 1]); % only 1 cone
    sensor = sensorSet(sensor, 'time interval', simulationTimeIntervalInSeconds);
        
    % Compute the simulation time axis
    stepOnset  = 4000;             % step onset
    stepOffset = 22000;            % step offset
    
    stimPeriod = [stepOnset stepOffset];      
    nSamples   = stepOffset+4000;

    flashTime = [stepOnset-3000 stepOnset+6000 stepOffset-3000];      % time of flashes
    flashDur = 10;                      % flash duration (bins)
    flashIntensity = 10000;             % flash intensity R*/cone/sec
    simulationTime = (1:nSamples)*simulationTimeIntervalInSeconds;
    
    nStepIntensities = 11;
    stepIntensities = 50 * 2.^(1:nStepIntensities);
    
    for stepIndex = 1:nStepIntensities
        
        % create step stimulus temporal profile
        stepStimulusPhotonRate = zeros(nSamples, 1);
        stepStimulusPhotonRate(stimPeriod(1):stimPeriod(2),1) = stepIntensities(stepIndex);
        
        % set the stimulus photon rate
        sensor = sensorSet(sensor, 'photon rate', reshape(stepStimulusPhotonRate, [1 1 size(stepStimulusPhotonRate,1)]));
            
        % create a biophysically-based outersegment model object
        osB = osBioPhys();

        % specify no noise
        noiseFlag = 0;
        osB.osSet('noiseFlag', noiseFlag);

        % compute the outer segment model's response to the step stimulus
        params.bgVolts = 0;
        osB.osCompute(sensor, params);
            
        % get the computed current
        stepCurrent(stepIndex,:) = osB.osGet('coneCurrentSignal');
        
        % create step+flash stimulus temporal profile
        % add first pulse before the onset of the light step
        stepFlashStimulusPhotonRate = stepStimulusPhotonRate;
        stepFlashStimulusPhotonRate(flashTime(1):flashTime(1)+flashDur) = stepFlashStimulusPhotonRate (flashTime(1):flashTime(1)+flashDur) + flashIntensity;
        % add second pulse (light decrement) during the light step 
        stepFlashStimulusPhotonRate(flashTime(2):flashTime(2)+flashDur) = stepFlashStimulusPhotonRate (flashTime(2):flashTime(2)+flashDur) - flashIntensity;
        % add third pulse (light increment) during the light step 
        stepFlashStimulusPhotonRate(flashTime(3):flashTime(3)+flashDur) = stepFlashStimulusPhotonRate (flashTime(3):flashTime(3)+flashDur) + flashIntensity;
    
        % set the stimulus photon rate
        sensor = sensorSet(sensor, 'photon rate', reshape(stepFlashStimulusPhotonRate , [1 1 size(stepFlashStimulusPhotonRate ,1)]));
        
        % compute the outer segment model's response to the step + flash stimulus
        osB.osCompute(sensor, params);
        
        % get the computed current
        stepFlashCurrent(stepIndex,:) = osB.osGet('coneCurrentSignal');
        
        if (runTimeParams.generatePlots)  
            if (stepIndex == 1)
                h = figure(1); clf;
                set(h, 'Position', [10 10 900 1200]);
            end
        end
        
        % plot stimulus on the left
        subplot(nStepIntensities,3,(stepIndex-1)*3+1); 
        plot(simulationTime, stepFlashStimulusPhotonRate, 'r-', 'LineWidth', 2.0);
        set(gca, 'XLim', [simulationTime(1) simulationTime(end)], 'YLim', [0 12e4], 'YTick', []);
        if (stepIndex == nStepIntensities)
            xlabel('time (sec)','FontSize',12);
        else
            set(gca, 'XTickLabel', {});
        end
        ylabel('isomer. rate','FontSize',12);
        title(sprintf('step: %d R*/sec',stepIntensities(stepIndex)), 'FontSize',12);
        
        % plot compound response in the middle
        subplot(nStepIntensities,3,(stepIndex-1)*3+2); 
        plot(simulationTime, squeeze(stepFlashCurrent(stepIndex,:)), 'k-', 'LineWidth', 2.0); hold on
        plot(simulationTime, squeeze(stepCurrent(stepIndex,:)), 'm:', 'LineWidth', 2.0);
        
        set(gca, 'XLim', [simulationTime(1) simulationTime(end)]);
        if (stepIndex == nStepIntensities)
            xlabel('time (sec)','FontSize',12);
        else
            set(gca, 'XTickLabel', {});
        end
        ylabel('pAmps','FontSize',12);
        title('compound response', 'FontSize',12);
        
        % plot flash-only response on the right
        flashOnlyCurrent = squeeze(stepFlashCurrent(stepIndex,:))-squeeze(stepCurrent(stepIndex,:));
        lightDecrementFlashAmplitude(stepIndex) = min(flashOnlyCurrent(find((simulationTime>flashTime(2)*simulationTimeIntervalInSeconds-0.2) & (simulationTime<flashTime(2)*simulationTimeIntervalInSeconds+0.2))));
        lightIncrementFlashAmplitude(stepIndex) = max(flashOnlyCurrent(find(simulationTime>1.5)));
        subplot(nStepIntensities,3,(stepIndex-1)*3+3); 
        plot(simulationTime, flashOnlyCurrent, 'k-', 'LineWidth', 2.0);
        set(gca, 'XLim', [simulationTime(1) simulationTime(end)], 'YLim', [-2.2 2.2]);
        if (stepIndex == nStepIntensities)
            xlabel('time (sec)','FontSize',12);
        else
            set(gca, 'XTickLabel', {});
        end
        ylabel('pAmps','FontSize',12);
        title('flash responses', 'FontSize',12);
        
        drawnow;
    end % stepIndex
    
    if (runTimeParams.generatePlots)  
        h = figure(2); clf;
        set(h, 'Position', [10 10 500 500]);
        hold on
        plot(stepIntensities, lightDecrementFlashAmplitude, 'ro-', 'MarkerSize', 12, 'MarkerFaceColor', [1 0.8 0.8]);
        plot(stepIntensities, lightIncrementFlashAmplitude, 'bo-', 'MarkerSize', 12, 'MarkerFaceColor', [0.8 0.8 1.0]);
        legend('light decrement', 'light increment');
        set(gca, 'XLim', [stepIntensities(1) stepIntensities(end)], 'YLim', max([max(abs(lightDecrementFlashAmplitude)) max(abs(lightIncrementFlashAmplitude))])*[-1 1], 'FontSize', 12);
        xlabel('step intensity (R*/sec)', 'FontSize', 12);
        ylabel('flash response (pAmps)','FontSize', 12);
    end
    
end
