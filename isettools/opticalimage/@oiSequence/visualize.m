function [uData, hFig] = visualize(obj,varargin)
% Visualize aspects of the OI sequence
%
% Parameter/value
%  format - {weights, movie, montage}
%
% NP/BW ISETBIO Team, 2016

%% Interpret parameter values
p = inputParser;

p.addRequired('obj');
p.addParameter('format','movie',@ischar);

p.parse(obj,varargin{:});
format = p.Results.format;

%%  Show the oiSequence in one of the possible formats
uData = [];
switch format
    case 'weights'
        % Graph the weights'
        hFig = vcNewGraphWin;
        plot(obj.oiTimeAxis, obj.modulationFunction);
        xlabel('Time (ms)'); ylabel('Modulation');
        title(sprintf('Composition: %s',obj.composition));
    case 'movie'
        % Show the oi as an illuminance movie
        wgts     = obj.modulationFunction;
        illFixed = oiGet(obj.oiFixed,'illuminance');
        illMod   = oiGet(obj.oiModulated,'illuminance');
        hFig = vcNewGraphWin; colormap(gray(256));
        axis image; axis off;
        
        mx1 = max(illFixed(:)); mx2 = max(illMod(:));
        mx = max(mx1,mx2);
        d = zeros([size(illFixed),length(obj.oiTimeAxis)]);
        
        switch obj.composition
            case 'blend'
                illFixed = 256*illFixed/mx; illMod = 256*illMod/mx;
                for ii=1:length(wgts)
                    d(:,:,ii) = illFixed*(1-wgts(ii)) + illMod*wgts(ii);
                    % To make a video, we should do this type of thing
                end                
                % d = ieScale(d,0,1) .^ 0.5;
                % mind = min(d(:)); maxd = max(d(:));
                for ii=1:length(wgts)
                    image(d(:,:,ii)); axis image; drawnow;
                    % if save,  F = getframe; writeVideo(vObj,F); end
                end
                % ieMovie(d);  % Scales stuff in the wrong way
                
            case 'add'
                for ii=1:length(wgts)
                    imagesc(illFixed + illMod*(wgts(ii)));
                    pause(0.1);
                end
            otherwise
                error('Unknown composition %s\n',obj.composition);
        end
        
    case 'montage'
        % Window with snapshots
        colsNum = round(1.3*sqrt(obj.length));
        rowsNum = ceil(obj.length/colsNum);
        subplotPosVectors = NicePlot.getSubPlotPosVectors(...
            'rowsNum', rowsNum, ...
            'colsNum', colsNum+1, ...
            'heightMargin',   0.07, ...
            'widthMargin',    0.02, ...
            'leftMargin',     0.04, ...
            'rightMargin',    0.00, ...
            'bottomMargin',   0.03, ...
            'topMargin',      0.03);
        
        XYZmax = 0;
        for oiIndex = 1:obj.length
            currentOI = obj.frameAtIndex(oiIndex);
            XYZ = oiGet(currentOI, 'xyz');
            if (max(XYZ(:)) > XYZmax)
                XYZmax = max(XYZ(:));
            end
        end
        % Do not exceed XYZ values of 0.5 (for correct rendering)
        XYZmax = 2*XYZmax;
        
        hFig = figure();
        set(hFig, 'Color', [1 1 1], 'Position', [10 10 1700 730]);
        
        for oiIndex = 1:obj.length
            if (oiIndex == 1)
                % Plot the modulation function
                subplot('Position', subplotPosVectors(1,1).v);
                stairs(1:obj.length, obj.modulationFunction, 'r', 'LineWidth', 1.5);
                set(gca, 'XLim', [1 obj.length], 'FontSize', 12);
                title(sprintf('composition: ''%s''', obj.composition));
                xlabel('frame index');
                ylabel('modulation');
            end
            
            % Ask theOIsequence to return the oiIndex-th frame
            currentOI = obj.frameAtIndex(oiIndex);
            support = oiGet(currentOI, 'spatial support', 'microns');
            [~, meanIlluminance] = oiCalculateIlluminance(currentOI);
            xaxis = support(1,:,1);
            yaxis = support(:,1,2);
            row = 1+floor((oiIndex)/(colsNum+1));
            col = 1+mod((oiIndex),(colsNum+1));
            
            subplot('Position', subplotPosVectors(row,col).v);
            rgbImage = xyz2srgb(oiGet(currentOI, 'xyz')/XYZmax);
            imagesc(xaxis, yaxis, rgbImage, [0 1]);
            axis 'image'
            if (col == 1) && (row == rowsNum)
                xticks = [xaxis(1) 0 xaxis(end)];
                yticks = [yaxis(1) 0 yaxis(end)];
                set(gca, 'XTick', xticks, 'YTick', yticks, 'XTickLabel', sprintf('%2.0f\n', xticks), 'YTickLabel', sprintf('%2.0f\n', yticks));
                ylabel('microns');
            else
                set(gca, 'XTick', [], 'YTick', [])
                xlabel(sprintf('frame %d (%2.1fms)', oiIndex, 1000*obj.oiTimeAxis(oiIndex)));
            end
            title(sprintf('mean illum: %2.1f', meanIlluminance));
            set(gca, 'FontSize', 12);
        end
    otherwise
        error('Unknown format %s\n',format);
end

end
