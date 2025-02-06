clear;

eeglab nogui;

%change below to your own data path, e.g., 'D:\dataset2_reactiontime'
data_path = 'your_data_path';
%change below to your EEGLAB path
eeglab_elec = 'your_EEGLAB_path\eeglab2022.0\plugins\dipfit\standard_BEM\elec\standard_1005.elc';
data_name1 = 'reaction time_029.vhdr';
data_name2 = 'reaction time_029.vhdr';

%ocular template
EEG1 = pop_loadbv(data_path, data_name1, [], []);
EEG1 = pop_chanedit(EEG1, 'lookup',eeglab_elec);
EEG1 = pop_resample(EEG1, 250);
EEG1 = pop_eegfiltnew(EEG1,'hicutoff',40,'locutoff',1,'plotfreqz',0);

%experiment data to clean
EEG2 = pop_loadbv(data_path, data_name2, [], []);
EEG2 = pop_chanedit(EEG2, 'lookup',eeglab_elec);
EEG2 = pop_resample(EEG2, 250);
EEG2 = pop_eegfiltnew(EEG2,'hicutoff',80,'locutoff',0.5,'plotfreqz',0);
EEG2 = pop_eegfiltnew(EEG2, 'locutoff',49,'hicutoff',51,'revfilt',1,'plotfreqz',0);

%merge
EEG = pop_mergeset(EEG1,EEG2); EEG.tplpoint = max(EEG1.times);

%channel checking and interpolation can be skipped as there is no
%problematic electrodes in this data
figure('WindowState', 'maximized');
plot(EEG.data' - ones(size(EEG.data,2),1)*[1:size(EEG.data,1)]*500);
for jj = 1:size(EEG.data,1) text(size(EEG.data,2),-500*jj,EEG.chanlocs(jj).labels);end
axis tight;axis off;

%need to interpolate channel?
EEG=pop_interp(EEG);

%remove ocular
EEG = ICA_correction(EEG);

%remove large-amplitude artifacts
EEG = PCA_correction(EEG);

%cut out the segment for training ICA?
% EEG = pop_select(EEG,'point',[fix(EEG.tplpoint*EEG.srate/1000)+1,size(EEG.data,2)]);

pop_saveset(EEG,'filepath','your_saving_path','filename','data_name.set');


