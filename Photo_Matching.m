function Photo_Matching
% Reproduction on Bpod of protocol used in the PatonLab, MATCHINGvFix

global BpodSystem TaskParameters nidaq

%% Task parameters
TaskParameters = BpodSystem.ProtocolSettings;
if isempty(fieldnames(TaskParameters))
    %% Center Port ("stimulus sampling")
    TaskParameters.GUI.EarlyCoutPenalty = 0;
    TaskParameters.GUI.StimDelaySelection = 4;
    TaskParameters.GUIMeta.StimDelaySelection.Style = 'popupmenu';
    TaskParameters.GUIMeta.StimDelaySelection.String = {'Fix','AutoIncr','TruncExp','Uniform'};
    TaskParameters.GUI.StimDelayMin = 0.2;
    TaskParameters.GUI.StimDelayMax = 0.5;
    TaskParameters.GUI.StimDelayTau = 0.2;
    TaskParameters.GUI.StimDelay = TaskParameters.GUI.StimDelayMin;
    TaskParameters.GUIMeta.StimDelay.Style = 'text';
    TaskParameters.GUIPanels.StimDelay = {'EarlyCoutPenalty','StimDelaySelection','StimDelayMin','StimDelayMax','StimDelayTau','StimDelay'};
    
    %% General
    TaskParameters.GUI.Ports_LMR = '123';
    TaskParameters.GUI.ITI = 1; % (s)
    TaskParameters.GUI.VI = false; % random ITI
    TaskParameters.GUIMeta.VI.Style = 'checkbox';
    TaskParameters.GUI.ChoiceDeadline = 10;
    TaskParameters.GUI.MinCutoff = 50; % New waiting time as percentile of empirical distribution
    TaskParameters.GUIPanels.General = {'Ports_LMR','ITI','VI','ChoiceDeadline','MinCutoff'};
    % Side Ports ("waiting for feedback")
    TaskParameters.GUI.EarlySoutPenalty = 1;
    TaskParameters.GUI.FeedbackDelaySelection = 2;
    TaskParameters.GUIMeta.FeedbackDelaySelection.Style = 'popupmenu';
    TaskParameters.GUIMeta.FeedbackDelaySelection.String = {'Fix','AutoIncr','TruncExp','Uniform'};
    TaskParameters.GUI.FeedbackDelayMin = 0;
    TaskParameters.GUI.FeedbackDelayMax = 1;
    TaskParameters.GUI.FeedbackDelayTau = 0.4;
    TaskParameters.GUI.FeedbackDelay = TaskParameters.GUI.FeedbackDelayMin;
    TaskParameters.GUIMeta.FeedbackDelay.Style = 'text';
    TaskParameters.GUI.Grace = 0.2;
    TaskParameters.GUIPanels.SidePorts = {'EarlySoutPenalty','FeedbackDelaySelection','FeedbackDelayMin','FeedbackDelayMax','FeedbackDelayTau','FeedbackDelay','Grace'};
    % Reward
    TaskParameters.GUI.pHi =  50; % 0-100% Higher reward probability
    TaskParameters.GUI.pLo =  12; % 0-100% Lower reward probability
    TaskParameters.GUI.blockLenMin = 50;
    TaskParameters.GUI.blockLenMax = 100;
    TaskParameters.GUI.rewardAmount = 30;
    TaskParameters.GUIPanels.Reward = {'rewardAmount','pLo','pHi','blockLenMin','blockLenMax'};
    
    TaskParameters.GUI = orderfields(TaskParameters.GUI);
    
    %%
    TaskParameters.GUI.Photometry=1;
    TaskParameters.GUIMeta.Photometry.Style='checkbox';
    TaskParameters.GUIMeta.Photometry.String='Auto';
    TaskParameters.GUI.RedChannel=0;
    TaskParameters.GUIMeta.RedChannel.Style='checkbox';
    TaskParameters.GUIMeta.RedChannel.String='Auto';    
    TaskParameters.GUIPanels.Recording={'Photometry','RedChannel'};
    
    %%
    TaskParameters.GUI.BaselineDur = 2;
    TaskParameters.GUI.PhotometryVersion=1;
    TaskParameters.GUI.Modulation=1;
    TaskParameters.GUIMeta.Modulation.Style='checkbox';
    TaskParameters.GUIMeta.Modulation.String='Auto';
	TaskParameters.GUI.NidaqDuration=10;
    TaskParameters.GUI.NidaqSamplingRate=6100;
    TaskParameters.GUI.DecimateFactor=610;
    TaskParameters.GUI.LED1_Name='Fiber1 470-A1';
    TaskParameters.GUI.LED1_Amp=0;
    TaskParameters.GUI.LED1_Freq=211;
    TaskParameters.GUI.LED2_Name='Fiber1 405 / 565';
    TaskParameters.GUI.LED2_Amp=0;
    TaskParameters.GUI.LED2_Freq=531;
    TaskParameters.GUI.LED1b_Name='Fiber2 470-mPFC';
    TaskParameters.GUI.LED1b_Amp=0;
    TaskParameters.GUI.LED1b_Freq=531;

    TaskParameters.GUIPanels.Photometry={'PhotometryVersion','Modulation','NidaqDuration',...
                            'NidaqSamplingRate','DecimateFactor','BaselineDur'...
                            'LED1_Name','LED1_Amp','LED1_Freq',...
                            'LED2_Name','LED2_Amp','LED2_Freq',...
                            'LED1b_Name','LED1b_Amp','LED1b_Freq'};
                        
%     TaskParameters.GUITabs.Photometry={'Photometry'};
end
TaskParameters.GUI.StimDelay = TaskParameters.GUI.StimDelayMin;
TaskParameters.GUI.FeedbackDelay = TaskParameters.GUI.FeedbackDelayMin;
BpodParameterGUI('init', TaskParameters);

%% Initializing data (trial type) vectors

BpodSystem.Data.Custom.Baited.Left = true;
BpodSystem.Data.Custom.Baited.Right = true;
BpodSystem.Data.Custom.BlockNumber = 1;
BpodSystem.Data.Custom.LeftHi = rand>.5;
BpodSystem.Data.Custom.BlockLen = drawBlockLen(TaskParameters);

BpodSystem.Data.Custom.ChoiceLeft = NaN;
BpodSystem.Data.Custom.EarlyCout(1) = false;
BpodSystem.Data.Custom.EarlySout(1) = false;
BpodSystem.Data.Custom.Rewarded = false;
BpodSystem.Data.Custom.StimDelay(1) = NaN;
BpodSystem.Data.Custom.FeedbackTime(1) = NaN;
BpodSystem.Data.Custom.RewardMagnitude(1,1:2) = TaskParameters.GUI.rewardAmount;

BpodSystem.Data.Custom.DFF = [];

%server data
BpodSystem.Data.Custom.Rig = getenv('computername');
[~,BpodSystem.Data.Custom.Subject] = fileparts(fileparts(fileparts(fileparts(BpodSystem.DataPath))));

BpodSystem.Data.Custom = orderfields(BpodSystem.Data.Custom);

%% Set up PulsePal
load PulsePalParamFeedback.mat
BpodSystem.Data.Custom.PulsePalParamFeedback=PulsePalParamFeedback;
BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler';
if ~BpodSystem.EmulatorMode
    ProgramPulsePal(BpodSystem.Data.Custom.PulsePalParamFeedback);
end

%% Initialize plots
temp = SessionSummary();
for i = fieldnames(temp)'
    BpodSystem.GUIHandles.(i{1}) = temp.(i{1});
end
clear temp

BpodNotebook('init');

%% NIDAQ Initialization amd Plots
if TaskParameters.GUI.Photometry
    Nidaq_photometry('ini');
    temp = PhotometryFigure();
    for i = fieldnames(temp)'
        BpodSystem.GUIHandles.(i{1}) = temp.(i{1});
    end
    clear temp
end
% if TaskParameters.GUI.Photometry
%     FigNidaq1=Online_NidaqPlot('ini','470');
%     if TaskParameters.GUI.RedChannel
%         FigNidaq2=Online_NidaqPlot('ini','channel2');
%     end
% end

%% Main loop
RunSession = true;
iTrial = 1;

while RunSession
    TaskParameters = BpodParameterGUI('sync', TaskParameters);
    
    sma = stateMatrix();
    SendStateMatrix(sma);
    %% NIDAQ Get nidaq ready to start
    if TaskParameters.GUI.Photometry
        Nidaq_photometry('WaitToStart');
    end
    %%
    RawEvents = RunStateMatrix;
    
    %% NIDAQ Stop acquisition and save data in bpod structure
    if TaskParameters.GUI.Photometry
        Nidaq_photometry('Stop');
        [PhotoData,Photo2Data]=Nidaq_photometry('Save');
        if TaskParameters.GUI.Photometry
            BpodSystem.Data.NidaqData{iTrial}=PhotoData;
            if TaskParameters.GUI.RedChannel
                BpodSystem.Data.Nidaq2Data{iTrial}=Photo2Data;
            end
        end
    end
    %%
    
    if ~isempty(fieldnames(RawEvents))
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents);
        SaveBpodSessionData;
    end
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    if BpodSystem.BeingUsed == 0
        return
    end
    
    updateCustomDataFields(iTrial)
    iTrial = iTrial + 1;
    BpodSystem.GUIHandles = SessionSummary(BpodSystem.Data, BpodSystem.GUIHandles, iTrial);
    BpodSystem.GUIHandles = PhotometryFigure(BpodSystem.Data, BpodSystem.GUIHandles);
end
end