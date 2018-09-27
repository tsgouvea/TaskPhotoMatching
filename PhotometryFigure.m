function GUIHandles = PhotometryFigure(Data, GUIHandles)

%global nTrialsToShow %this is for convenience
% global BpodSystem
global TaskParameters
if nargin < 2 % plot initialized (either beginning of session or post-hoc analysis)
    if nargin > 0 % post-hoc analysis
        TaskParameters.GUI = Data.Settings.GUI;
    end
    
    GUIHandles = struct();
    GUIHandles.Figs.PhotoFig = figure('Position', [200, 200, 400, 400],'name','Photometry','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
    GUIHandles.Axes.RasterRwd.MainHandle = subplot(2,2,1);
    set(GUIHandles.Axes.RasterRwd.MainHandle,'TickDir', 'out', 'FontSize', 16);
    ylabel 'Trial #'
    title('Rwd trials')
    
    GUIHandles.Axes.AvgRwd.MainHandle = subplot(2,2,3);
    set(GUIHandles.Axes.AvgRwd.MainHandle,'TickDir', 'out', 'FontSize', 16);
    %     xlim(winSignal)
    %     ylim([-.3,.3])
    %     xticks([winSignal(1):winSignal(2)])
    xlabel('time from reward (s)')
    ylabel 'df/f'
    
    GUIHandles.Axes.RasterNoRwd.MainHandle = subplot(2,2,2);
    set(GUIHandles.Axes.RasterNoRwd.MainHandle,'TickDir', 'out', 'FontSize', 16);
    title('Unrwd trials')
    
    GUIHandles.Axes.AvgNoRwd.MainHandle = subplot(2,2,4);
    set(GUIHandles.Axes.AvgNoRwd.MainHandle,'TickDir', 'out', 'FontSize', 16);
    xlabel('time from reward (s)')
    %     ylabel 'df/f'
end

if nargin > 0
    dff = Data.Custom.DFF;
    clims = [min(dff(:)), max(dff(:))];
    isValid = ~isnan(Data.Custom.ChoiceLeft(:));
    isRwd = Data.Custom.Rewarded(:);
    winSignal = Data.Custom.winSignal;
    
    set(GUIHandles.Axes.RasterRwd.MainHandle,'xtick',linspace(1,size(dff,2),diff(winSignal)),'xticklabel',[winSignal(1):winSignal(2)])
    set(GUIHandles.Axes.RasterNoRwd.MainHandle,'xtick',linspace(1,size(dff,2),diff(winSignal)),'xticklabel',[winSignal(1):winSignal(2)])
    
    imagesc(GUIHandles.Axes.RasterRwd.MainHandle,dff(isRwd&isValid,:),clims)
    imagesc(GUIHandles.Axes.RasterNoRwd.MainHandle,dff(~isRwd&isValid,:),clims)
    
    xaxis = linspace(winSignal(1),winSignal(2),size(dff,2));
    plot(GUIHandles.Axes.AvgRwd.MainHandle,xaxis,nanmean(dff(isRwd&isValid,:)))
    plot(GUIHandles.Axes.AvgNoRwd.MainHandle,xaxis,nanmean(dff(~isRwd&isValid,:)))
end
end