function GUIHandles = PhotometryFigure(Data, GUIHandles)

%global nTrialsToShow %this is for convenience
% global BpodSystem
global TaskParameters
if nargin < 2 % plot initialized (either beginning of session or post-hoc analysis)
    if nargin > 0 % post-hoc analysis
        TaskParameters.GUI = Data.Settings.GUI;
    end
    
    GUIHandles = struct();
    GUIHandles.Figs.PhotoFig = figure('Position', [200, 200, 800, 800],'name','Photometry','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
    GUIHandles.Axes.RasterRwd.MainHandle = subplot(3,2,1);
    GUIHandles.Axes.AvgRwd.MainHandle = subplot(3,2,3);
    GUIHandles.Axes.RasterNoRwd.MainHandle = subplot(3,2,2);
    GUIHandles.Axes.AvgNoRwd.MainHandle = subplot(3,2,4);
    GUIHandles.Axes.LastDemod.MainHandle = subplot(3,2,5); hold on  
    GUIHandles.Axes.LastRaw.MainHandle = subplot(3,2,6);  hold on  
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
    rawData = Data.NidaqData{end};
    rawData2 = Data.Nidaq2Data{end};
    
    cla(GUIHandles.Axes.LastDemod.MainHandle)
    cla(GUIHandles.Axes.LastRaw.MainHandle)
    if ~isempty(rawData)
        [ demodData, demodTime ] = nidemod( rawData(:,1),rawData(:,2),TaskParameters.GUI.LED1_Freq,...
            TaskParameters.GUI.LED1_Amp,TaskParameters.GUI.DecimateFactor,TaskParameters.GUI.NidaqSamplingRate,15,1 );
        plot(GUIHandles.Axes.LastDemod.MainHandle,demodTime,demodData)
        plot(GUIHandles.Axes.LastRaw.MainHandle,rawData(1:400,1))
    end
    
    if ~isempty(rawData2)
        [ demodData2, demodTime2 ] = nidemod( rawData2(:,1),rawData2(:,2),TaskParameters.GUI.LED2_Freq,...
            TaskParameters.GUI.LED2_Amp,TaskParameters.GUI.DecimateFactor,TaskParameters.GUI.NidaqSamplingRate,15,1 );
        plot(GUIHandles.Axes.LastDemod.MainHandle,demodTime2,demodData2,'r')
        plot(GUIHandles.Axes.LastRaw.MainHandle,rawData2(1:400,1),'r')
    end
    
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