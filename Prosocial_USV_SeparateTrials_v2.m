%% Prosocial_USV_SeparateTrials

% Each wave file must be accompanied by the corresponding excel sheet that
% contains the event IDs and times. They must both have the same name.

% version 2 has the following adds
% display current file being read, so as to open it for manual check
% progress bar to help knowing where the script is currently running
% added functionality to go back in plot
% JHL 28/02/2019

%% Housekeeping

close all
clear
clc

%% Set Directories

loadDir = 'C:\Users\hernandez\Documents\scnd_test\dat';
saveDir = 'C:\Users\hernandez\Documents\scnd_test\trial';

%% Get the Raw Recording List

cd(loadDir)

wavFiles = dir('*.wav');
numFiles = size(wavFiles,1);
xlsFiles = dir('*.xls');

%% Separate the Trials

log = cell(numFiles,4);
for file = 1:numFiles
    disp('Start')
    cd(loadDir)
    [waveform, fs] = audioread(wavFiles(file).name);
    disp(['reading ' wavFiles(file).name])
    tmpWaveform = waveform(1:60*fs);
    window = hamming(512);
    noverlap = 384;
    nfft = 1024;
    [~,F,T,P] = spectrogram(tmpWaveform,window,noverlap,nfft,fs,'yaxis');
    
    log{file,1} = wavFiles(file).name;
    
    figure('Position',get(groot,'Screensize'))
    period = false;
    KEEP = true;
    while KEEP 
    period = period + true;   
%     period = 1:12
        
        subplot(2,1,1)
        imagesc(T,F,10*log10(P));
        ylim([0000 100000])
        set(gca,'YTick',[0 10000 20000 30000 40000 50000 60000 70000 80000 90000 100000])
        set(gca,'YTickLabels',{'0','10','20','30','40','50','60','70','80','90','100'})
        ylabel('Fq (kHz)')
        xlim([(period-1)*5 period*5])
        xlabel('Time (sec)')
        colormap(gray)
        colormap(flipud(colormap))
        set(gca,'clim',[-105 -80]);
        grid off
        box on
        set(gca,'YDir','Normal')
        
        subplot(2,1,2)
        plot((1:length(tmpWaveform))*1/fs,tmpWaveform)
        xlim([(period-1)*5 period*5])
        xlabel('Time (sec)')
        ylabel('Amplitude (a.u.)')
        
        %disp('backward arrow to go back one epoch, other key to go forward, mouse to select event')
        keyPress = waitforbuttonpress;
        value = double(get(gcf,'CurrentCharacter'));
        % value == 28 is back arrow
        % value == 29 is forward arrow
        if keyPress == 0
            [startTime,~] = ginput(1);
            disp('Event Selected')
            break
        elseif isequal(value,28)
            period = period - 2; % Go back to last epoch 
            disp('1 Epoch Back')
        else
            disp('1 Epoch Forward')
        end
    end
    close
    
    tmpTriggers = xlsread(xlsFiles(file).name);
    
    nosePokeOns = find(tmpTriggers(:,1)==3);
    tmpTriggers(:,3) = startTime+tmpTriggers(:,2)-tmpTriggers(nosePokeOns(1,1),2);
    
    nosePokes = find(tmpTriggers(:,1)==2);
    
    for trial = 1:length(nosePokes)
        progressBar(trial/length(nosePokes), 1, ['Going through trials... '])  
        if trial ~= length(nosePokes)
            if tmpTriggers(nosePokes(trial,1),3) <= 0
                tmpTrialWaveform = waveform(1:floor(tmpTriggers(nosePokes(trial+1,1),3)*fs),1);
                log{file,2} = 'The NosePoke ON (event #2) trigger in Trial 1 came before the audio recording started.';
                disp('The NosePoke ON (event #2) trigger in Trial 1 came before the audio recording started.')
            elseif floor(tmpTriggers(nosePokes(trial+1,1),3)*fs) > length(waveform)
                tmpTrialWaveform = waveform(floor(tmpTriggers(nosePokes(trial,1),3)*fs):end,1);
                log{file,4} = 'The audio recording was not long enough to contation all 24 trials.';
                disp('The audio recording was not long enough to contation all 24 trials.')
                break
            else
                tmpTrialWaveform = waveform(floor(tmpTriggers(nosePokes(trial,1),3)*fs):floor(tmpTriggers(nosePokes(trial+1,1),3)*fs),1);
            end
        elseif trial == length(nosePokes)
            if floor(tmpTriggers(end,3)*fs) > length(waveform)
                tmpTrialWaveform = waveform(floor(tmpTriggers(nosePokes(trial,1),3)*fs):floor(tmpTriggers(end-1,3)*fs),1);
                log{file,3} = 'The End Session (event #8) trigger in Trial 24 came after the audio recording ended.';
                disp('The End Session (event #8) trigger in Trial 24 came after the audio recording ended.')
            else
                tmpTrialWaveform = waveform(floor(tmpTriggers(nosePokes(trial,1),3)*fs):floor(tmpTriggers(end,3)*fs),1);
            end
        end
        cd(saveDir);
        audiowrite([wavFiles(file).name(1:end-4) '_Trial' num2str(trial) '.wav'],...
            tmpTrialWaveform,fs);
    end
end

%% Write the Log File

xlswrite('Log.xlsx',log)