function updateCustomDataFields(iTrial)
global BpodSystem
global TaskParameters

statesThisTrial = BpodSystem.Data.RawData.OriginalStateNamesByNumber{iTrial}(BpodSystem.Data.RawData.OriginalStateData{iTrial});

%% Center port
if any(strcmp('Cin',statesThisTrial))
    if any(strcmp('stillSampling',statesThisTrial))
        BpodSystem.Data.Custom.StimDelay(iTrial) = BpodSystem.Data.RawEvents.Trial{iTrial}.States.stillSampling(1,2) - BpodSystem.Data.RawEvents.Trial{iTrial}.States.Cin(1,1);
    else
        BpodSystem.Data.Custom.StimDelay(iTrial) = diff(BpodSystem.Data.RawEvents.Trial{iTrial}.States.Cin);
    end
end
%% Side ports
if any(strcmp('Lin',statesThisTrial)) || any(strcmp('Rin',statesThisTrial))
    Sin = statesThisTrial{strcmp('Lin',statesThisTrial)|strcmp('Rin',statesThisTrial)};
    if any(strcmp('stillLin',statesThisTrial)) || any(strcmp('stillRin',statesThisTrial))
        stillSin = statesThisTrial{strcmp('stillLin',statesThisTrial)|strcmp('stillRin',statesThisTrial)};
        BpodSystem.Data.Custom.FeedbackDelay(iTrial) = BpodSystem.Data.RawEvents.Trial{iTrial}.States.(stillSin)(1,2) - BpodSystem.Data.RawEvents.Trial{iTrial}.States.(Sin)(1,1);
    elseif any(strcmp(['Early' Sin(1) 'out'],statesThisTrial))
        BpodSystem.Data.Custom.FeedbackDelay(iTrial) = BpodSystem.Data.RawEvents.Trial{iTrial}.States.(['Early' Sin(1) 'out'])(1,1) -  BpodSystem.Data.RawEvents.Trial{iTrial}.States.(Sin)(1,1);
    end
end
%%
if any(strcmp('Lin',statesThisTrial))
    BpodSystem.Data.Custom.ChoiceLeft(iTrial) = 1;
elseif any(strcmp('Rin',statesThisTrial))
    BpodSystem.Data.Custom.ChoiceLeft(iTrial) = 0;
end
BpodSystem.Data.Custom.EarlyCout(iTrial) = any(strcmp('EarlyCout',statesThisTrial));
BpodSystem.Data.Custom.EarlySout(iTrial) = any(strcmp('EarlyRout',statesThisTrial)) || any(strcmp('EarlyLout',statesThisTrial));
BpodSystem.Data.Custom.Rewarded(iTrial) = any(strncmp('water_',statesThisTrial,6));
BpodSystem.Data.Custom.RewardMagnitude(iTrial,1:2) = TaskParameters.GUI.rewardAmount;

%% Photometry

sampleRate=TaskParameters.GUI.NidaqSamplingRate;
modAmp=TaskParameters.GUI.LED1_Amp;
modFreq=TaskParameters.GUI.LED1_Freq;
duration=TaskParameters.GUI.NidaqDuration;
lowCutoff=15;
decimateFactor = TaskParameters.GUI.DecimateFactor;
isPad = 1;

winSignal = [-3,5];
dff = nan(1,diff(winSignal)*sampleRate/decimateFactor);
winBaseline = [-3,-1];
stateToZero = {'rewarded_Lin','rewarded_Rin','unrewarded_Lin','unrewarded_Rin'};

rawData = BpodSystem.Data.NidaqData{iTrial};
[ demodData, demodTime ] = nidemod( rawData(:,1),rawData(:,2),modFreq,modAmp,decimateFactor,sampleRate,lowCutoff,isPad );
refTimeBaseline = BpodSystem.Data.RawEvents.Trial{iTrial}.States.Cin(1);
refTimeSignal = [];
for iState = 1:numel(stateToZero)
    if any(strcmp(stateToZero{iState},BpodSystem.Data.RawData.OriginalStateNamesByNumber{iTrial}(BpodSystem.Data.RawData.OriginalStateData{iTrial})))
        refTimeSignal=BpodSystem.Data.RawEvents.Trial{iTrial}.States.(stateToZero{iState})(1,1);
    end
end

if ~isempty(refTimeSignal) && refTimeSignal < duration
    dff_den = mean(demodData(demodTime > winBaseline(1)+refTimeBaseline & demodTime < winBaseline(2)+refTimeBaseline));
    dff_num = demodData(demodTime > winSignal(1)+refTimeSignal & demodTime < winSignal(2)+refTimeSignal);
    if length(dff_num) < size(dff,2)
        dff_num(length(dff_num)+1:size(dff,2)) = NaN;
    end
    dff(1,:) = 100*(dff_num-dff_den)/dff_den;
end

if isempty(BpodSystem.Data.Custom.DFF)
    BpodSystem.Data.Custom.DFF = nan(iTrial,diff(winSignal)*sampleRate/decimateFactor);
end
BpodSystem.Data.Custom.DFF(iTrial,:) = dff;
BpodSystem.Data.Custom.winSignal = winSignal;

%% initialize next trial values
BpodSystem.Data.Custom.ChoiceLeft(iTrial+1) = NaN;
BpodSystem.Data.Custom.EarlyCout(iTrial+1) = false;
BpodSystem.Data.Custom.EarlySout(iTrial+1) = false;
BpodSystem.Data.Custom.Rewarded(iTrial+1) = false;
BpodSystem.Data.Custom.StimDelay(iTrial+1) = NaN;
BpodSystem.Data.Custom.FeedbackDelay(iTrial+1) = NaN;

%% Block count
nTrialsThisBlock = sum(BpodSystem.Data.Custom.BlockNumber == BpodSystem.Data.Custom.BlockNumber(iTrial));
if nTrialsThisBlock >= TaskParameters.GUI.blockLenMax
    % If current block len exceeds new max block size, will transition
    BpodSystem.Data.Custom.BlockLen(end) = nTrialsThisBlock;
end
if nTrialsThisBlock >= BpodSystem.Data.Custom.BlockLen(end)
    BpodSystem.Data.Custom.BlockNumber(iTrial+1) = BpodSystem.Data.Custom.BlockNumber(iTrial)+1;
    BpodSystem.Data.Custom.BlockLen(end+1) = drawBlockLen(TaskParameters);
    BpodSystem.Data.Custom.LeftHi(iTrial+1) = ~BpodSystem.Data.Custom.LeftHi(iTrial);
else
    BpodSystem.Data.Custom.BlockNumber(iTrial+1) = BpodSystem.Data.Custom.BlockNumber(iTrial);
    BpodSystem.Data.Custom.LeftHi(iTrial+1) = BpodSystem.Data.Custom.LeftHi(iTrial);
end

%% Baiting

if BpodSystem.Data.Custom.LeftHi(iTrial)
    pL = TaskParameters.GUI.pHi/100;
    pR = TaskParameters.GUI.pLo/100;
else
    pL = TaskParameters.GUI.pLo/100;
    pR = TaskParameters.GUI.pHi/100;
end

drawL = false;
drawR = false;

if ~BpodSystem.Data.Custom.EarlyCout(iTrial)
    if ~BpodSystem.Data.Custom.Baited.Left(iTrial) || (BpodSystem.Data.Custom.ChoiceLeft(iTrial)==1 && BpodSystem.Data.Custom.Rewarded(iTrial))
        drawL = true;
    end
    if ~BpodSystem.Data.Custom.Baited.Right(iTrial) || (BpodSystem.Data.Custom.ChoiceLeft(iTrial)==0 && BpodSystem.Data.Custom.Rewarded(iTrial))
        drawR = true;
    end
end

if drawL
    BpodSystem.Data.Custom.Baited.Left(iTrial+1) = rand<pL;
else
    BpodSystem.Data.Custom.Baited.Left(iTrial+1) = BpodSystem.Data.Custom.Baited.Left(iTrial);
end
if drawR
    BpodSystem.Data.Custom.Baited.Right(iTrial+1) = rand<pR;
else
    BpodSystem.Data.Custom.Baited.Right(iTrial+1) = BpodSystem.Data.Custom.Baited.Right(iTrial);
end

%increase sample time
%% Center port
switch TaskParameters.GUIMeta.StimDelaySelection.String{TaskParameters.GUI.StimDelaySelection}
    case 'Fix'
        TaskParameters.GUI.StimDelay = TaskParameters.GUI.StimDelayMax;
    case 'AutoIncr'
        if sum(~isnan(BpodSystem.Data.Custom.StimDelay)) >= 10
            TaskParameters.GUI.StimDelay = prctile(BpodSystem.Data.Custom.StimDelay,TaskParameters.GUI.MinCutoff);
        else
            TaskParameters.GUI.StimDelay = TaskParameters.GUI.StimDelayMin;
        end
    case 'TruncExp'
        TaskParameters.GUI.StimDelay = TruncatedExponential(TaskParameters.GUI.StimDelayMin,...
            TaskParameters.GUI.StimDelayMax,TaskParameters.GUI.StimDelayTau);
    case 'Uniform'
        TaskParameters.GUI.StimDelay = TaskParameters.GUI.StimDelayMin + (TaskParameters.GUI.StimDelayMax-TaskParameters.GUI.StimDelayMin)*rand(1);
end
TaskParameters.GUI.StimDelay = max(TaskParameters.GUI.StimDelayMin,min(TaskParameters.GUI.StimDelay,TaskParameters.GUI.StimDelayMax));

%% Side ports
switch TaskParameters.GUIMeta.FeedbackDelaySelection.String{TaskParameters.GUI.FeedbackDelaySelection}
    case 'Fix'
        TaskParameters.GUI.FeedbackDelay = TaskParameters.GUI.FeedbackDelayMax;
    case 'AutoIncr'
        if sum(~isnan(BpodSystem.Data.Custom.FeedbackDelay)) >= 10
            TaskParameters.GUI.FeedbackDelay = prctile(BpodSystem.Data.Custom.FeedbackDelay,TaskParameters.GUI.MinCutoff);
        else
            TaskParameters.GUI.FeedbackDelay = TaskParameters.GUI.FeedbackDelayMin;
        end
    case 'TruncExp'
        TaskParameters.GUI.FeedbackDelay = TruncatedExponential(TaskParameters.GUI.FeedbackDelayMin,...
            TaskParameters.GUI.FeedbackDelayMax,TaskParameters.GUI.FeedbackDelayTau);
    case 'Uniform'
        TaskParameters.GUI.FeedbackDelay = TaskParameters.GUI.FeedbackDelayMin + (TaskParameters.GUI.FeedbackDelayMax-TaskParameters.GUI.FeedbackDelayMin)*rand(1);
        TaskParameters.GUI.FeedbackDelay = max(TaskParameters.GUI.FeedbackDelayMin,min(TaskParameters.GUI.FeedbackDelay,TaskParameters.GUI.FeedbackDelayMax));
end
%% send bpod status to server
try
    BpodSystem.Data.Custom.Script = 'receivebpodstatus.php';
    %create a common "outcome" vector
    outcome = BpodSystem.Data.Custom.ChoiceLeft(1:iTrial); %1=left, 0=right
    outcome(BpodSystem.Data.Custom.EarlyCout(1:iTrial))=3; %early C withdrawal=3
    outcome(BpodSystem.Data.Custom.Jackpot(1:iTrial))=4; %jackpot=4
    outcome(BpodSystem.Data.Custom.EarlySout(1:iTrial))=5; %early S withdrawal=5
    SendTrialStatusToServer(BpodSystem.Data.Custom.Script,BpodSystem.Data.Custom.Rig,outcome,BpodSystem.Data.Custom.Subject,BpodSystem.CurrentProtocolName);
catch
end
end