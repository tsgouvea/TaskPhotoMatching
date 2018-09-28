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
    GUIHandles.Axes.AvgRwd.MainHandle = subplot(2,2,3);
    GUIHandles.Axes.RasterNoRwd.MainHandle = subplot(2,2,2);
    GUIHandles.Axes.AvgNoRwd.MainHandle = subplot(2,2,4);
end

if nargin > 0
    clims = [min(Data.Custom.DFF(:)), max(Data.Custom.DFF(:))];
    if any(isnan(clims)), clims=[0,1]; end
    winSignal = Data.Custom.winSignal;
    isValid = ~isnan(Data.Custom.ChoiceLeft(:));
    isRwd = Data.Custom.Rewarded(:);
    dff_rwd = Data.Custom.DFF;
    dff_rwd(~isRwd|~isValid,:) = nan;
    dff_norwd = Data.Custom.DFF;
    dff_norwd(isRwd|~isValid,:) = nan;    
    
    imagesc(GUIHandles.Axes.RasterRwd.MainHandle,winSignal,[1,size(dff_rwd,1)],dff_rwd,clims)
    imagesc(GUIHandles.Axes.RasterNoRwd.MainHandle,winSignal,[1,size(dff_norwd,1)],dff_norwd,clims)
    
    xaxis = linspace(winSignal(1),winSignal(2),size(Data.Custom.DFF,2));
    plot(GUIHandles.Axes.AvgRwd.MainHandle,xaxis,nanmean(dff_rwd,1))
    plot(GUIHandles.Axes.AvgNoRwd.MainHandle,xaxis,nanmean(dff_norwd,1))
    
    set(GUIHandles.Axes.AvgNoRwd.MainHandle,'TickDir', 'out');
    GUIHandles.Axes.AvgNoRwd.MainHandle.XLabel.String='time from reward (s)';     
    set(GUIHandles.Axes.RasterRwd.MainHandle,'TickDir', 'out');
    GUIHandles.Axes.RasterRwd.MainHandle.YLabel.String= 'Trial #';
    GUIHandles.Axes.RasterRwd.MainHandle.Title.String='Rwd trials';
    set(GUIHandles.Axes.AvgRwd.MainHandle,'TickDir', 'out');
    GUIHandles.Axes.AvgRwd.MainHandle.YLabel.String= 'df/f';
    GUIHandles.Axes.AvgRwd.MainHandle.XLabel.String='time from reward (s)';
    set(GUIHandles.Axes.RasterNoRwd.MainHandle,'TickDir', 'out');
    GUIHandles.Axes.RasterNoRwd.MainHandle.Title.String='Unrwd trials'; 
end
end