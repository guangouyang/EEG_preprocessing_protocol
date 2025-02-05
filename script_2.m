clear;

eeglab nogui;

%change below to your own data path, e.g., 'D:\dataset1_face'
data_path = 'your_data_path';
%change below to your EEGLAB path
eeglab_elec = 'your_EEGLAB_path\eeglab2022.0\plugins\dipfit\standard_BEM\elec\standard_1005.elc';
data_name = 'face_010_2.vhdr';

%load data, down_sample, and filter
EEG = pop_loadbv(data_path, data_name, [], []);
EEG = pop_chanedit(EEG, 'lookup',eeglab_elec);
EEG = pop_resample(EEG, 250);
EEG = pop_eegfiltnew(EEG,'hicutoff',40,'locutoff',1,'plotfreqz',0);

%we skip the visual checking and electrode interpolation for this data as
%no electrode is problematic; you can find the code from script_1

%remove ocular
EEG = ICA_correction(EEG);

%this data does not require PCA procedure, you can directly save it:
pop_saveset(EEG,'filepath','your_saving_path','filename','face_010_2.set');


