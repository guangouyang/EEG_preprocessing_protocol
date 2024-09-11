clear;

eeglab nogui;

%load data, down_sample, and filter
EEG = pop_loadbv('your_data_path\sample_data', 'sample_1.vhdr', [], []);
EEG = pop_chanedit(EEG, 'lookup','your_EEGLAB_path\eeglab2022.0\plugins\dipfit\standard_BEM\elec\standard_1005.elc');
EEG = pop_resample(EEG, 250);
EEG = pop_eegfiltnew(EEG,'hicutoff',40,'locutoff',1,'plotfreqz',0);

%check problematic channels
figure('WindowState', 'maximized');
plot(EEG.data' - ones(size(EEG.data,2),1)*[1:size(EEG.data,1)]*500);
for jj = 1:size(EEG.data,1) text(size(EEG.data,2),-500*jj,EEG.chanlocs(jj).labels);end
axis tight;axis off;

%need to interpolate channel? If yes, run below
EEG=pop_interp(EEG);
