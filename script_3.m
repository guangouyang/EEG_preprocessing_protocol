eeglab nogui;

%load and show data
EEG = pop_loadbv('your_data_path\', 'face_014_2.vhdr', [], []);
EEG = pop_chanedit(EEG, 'lookup','your_eeglab_path\eeglab2022.0\plugins\dipfit\standard_BEM\elec\standard_1005.elc');
EEG = pop_resample(EEG, 250);
EEG = pop_eegfiltnew(EEG,'hicutoff',40,'locutoff',1,'plotfreqz',0);

%we skip the visual checking and electrode interpolation for this data as
%no electrode is problematic

%remove ocular
EEG = ICA_correction(EEG);%based on the time window from around 50 s to 200 s (remember to click 'Save Data')

%remove large-amplitude artifacts
EEG = PCA_correction(EEG);

pop_saveset(EEG,'filepath','your_path\','filename','face_014_2.set');
