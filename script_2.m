clear;

eeglab nogui;

%load and show data
EEG = pop_loadbv('your_data_path\sample_data', 'face_010_2.vhdr', [], []);
EEG = pop_chanedit(EEG, 'lookup','your_eeglab_path\eeglab2022.0\plugins\dipfit\standard_BEM\elec\standard_1005.elc');
EEG = pop_resample(EEG, 250);
EEG = pop_eegfiltnew(EEG,'hicutoff',40,'locutoff',1,'plotfreqz',0);

%we skip the visual checking and electrode interpolation for this data as
%no electrode is problematic

%remove ocular
EEG = ICA_correction(EEG);

%this dataset does not require PCA procedure, you can directly save it:
pop_saveset(EEG,'filepath','your_path\','filename','face_010_2.set');


