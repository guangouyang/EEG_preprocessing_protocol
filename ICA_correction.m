
function EEG = ICA_correction(EEG)
   h = figure('NumberTitle', 'off','Name','ICA Correction','Units','normalized','position',[.1,.2,.8,.7]);
   plot_before = axes(h,'position',[.1,.6,.8,.3],'Tag','plot_before');
   title('before'); 
   hold on;
   curves = plot(plot_before, EEG.times/1000, EEG.data', 'Tag', 'curve');
   if isfield(EEG,'tplpoint') xline(EEG.tplpoint/1000,'r','linewidth',2);end
   axis(plot_before, 'tight');xlabel('Time (s)');ylabel('Potential (\muV)');
  
   plot_after = axes(h,'position',[.1,.1,.8,.3],'Tag','plot_after');
   title('after'); xlabel('Time (s)');ylabel('Potential (\muV)');
   hold on;
   all_eeg.EEG_processed = EEG;
   all_eeg.EEG_original = EEG;
   all_eeg.selected_wins = [];
   guidata(h, all_eeg);
   bt_select_win = uicontrol(h, 'Style', 'pushbutton', 'Units','Normalized', 'Tag', 'select_win', 'Position',...
       [0.1 .45 0.2 0.05],'String', 'Select Time Window', 'Callback', @select_win);
   bt_ica_correct = uicontrol(h, 'Style', 'pushbutton', 'Units','Normalized', 'Tag', 'ica_correct', 'Position',...
       [0.3 .45 0.2 0.05],'String', 'Correct', 'Callback', @ica_correct);
   bt_cancel_last_selection = uicontrol(h, 'Style', 'pushbutton', 'Units','Normalized', 'Tag', 'cancel_last_selection', 'Position',...
       [0.5 .45 0.2 0.05],'String', 'Cancel Selection', 'Callback', @cancel_last_selection);
   bt_save_data = uicontrol(h, 'Style', 'pushbutton', 'Units','Normalized', 'Tag', 'save_data', 'Position',...
       [0.7 .45 0.2 0.05],'String', 'Save Data', 'Callback', 'if ~isempty(guidata(gcf)) EEG = guidata(gcf).EEG_processed; msgbox("saved!"); end');
   
   function select_win(src, event, handle)
       delete(findobj(allchild(src.Parent), 'Tag', 'filled_rect'));
       [x, y] = ginput(2);
       
       all_eeg_temp = guidata(src);
       all_eeg_temp.selected_wins = [x(1), x(2)];
       guidata(src, all_eeg_temp);
       fill(findobj(allchild(src.Parent), 'Tag', 'plot_before'), [x(1), x(2), x(2), x(1)],...
           [findobj(allchild(src.Parent), 'Tag', 'plot_before').YLim(1), findobj(allchild(src.Parent), 'Tag', 'plot_before').YLim(1),...
           findobj(allchild(src.Parent), 'Tag', 'plot_before').YLim(2), findobj(allchild(src.Parent), 'Tag', 'plot_before').YLim(2)],...
           'cyan', 'EdgeColor', 'none', 'FaceAlpha', .2, 'Tag', 'filled_rect');
   end

   function cancel_last_selection(src, event, handle)
       all_eeg_temp = guidata(src);
       
       all_eeg_temp.selected_wins = [];
       guidata(src, all_eeg_temp);
       
       delete(findobj(allchild(src.Parent), 'Tag', 'filled_rect'));
   end

   function ica_correct(src, event, handle)
       all_eeg_temp = guidata(src);
       EEG = all_eeg_temp.EEG_original;
       if ~isempty(all_eeg_temp.selected_wins)
           win = all_eeg_temp.selected_wins;
           x1 = win(1);
           x2 = win(2);
           idx = find(EEG.times/1000 > x1 & EEG.times/1000 < x2);
           x1 = idx(1);
           x2 = idx(end);
           EEG.ica_win = [x1, x2];
           EEG_ori = EEG;
           EEG = pop_select(EEG, 'point', EEG.ica_win);
           EEG = pop_runica(EEG, 'icatype', 'runica', 'extended', 1, 'stop', 0.001, 'interrupt', 'on');
           EEG = pop_iclabel(EEG, 'default');
           %pop_selectcomps(EEG, [1:32]);
           % sorting label
           [~, maxClassIdx] = max(EEG.etc.ic_classification.ICLabel.classifications, [], 2);
           classLabels = EEG.etc.ic_classification.ICLabel.classes;
           sortedComponents = [];
           % order
           classOrder = {'Eye', 'Brain'};
           for i = 1:length(classOrder)
               currentClass = classOrder{i};
               currentClassIdx = find(strcmp(classLabels, currentClass));
               if ~isempty(currentClassIdx)
                   currentClassComponents = find(maxClassIdx == currentClassIdx);
                   [~, sortIdx] = sort(EEG.etc.ic_classification.ICLabel.classifications(currentClassComponents, currentClassIdx), 'descend');
                   sortedComponents = [sortedComponents; currentClassComponents(sortIdx)];
               end
           end
           % append the rest of the components in original order
           remainingComponents = setdiff(1:length(maxClassIdx), sortedComponents);
           sortedComponents = [sortedComponents; remainingComponents'];
           
           
           numComponents = size(EEG.icaweights, 1);
           if numComponents > 32
            sortedComponents = sortedComponents(1:32);
           end;
           numRows = ceil(numComponents / 8);
           
           
           figure('Units','normalized','position',[.1,.1,.8,.8],'Name','ICA Components Topographies');
           for j = 1:numRows
               for k = 1:8
                   idx = k + (j - 1) * 8;
                   if idx <= length(sortedComponents)
                       compIdx = sortedComponents(idx);
                       subplot(numRows, 8, idx);
                       topoplot(EEG.icawinv(:, compIdx), EEG.chanlocs, 'headrad', 'rim', 'electrodes', 'off');
                       axis([-0.65, 0.65, -0.65, 0.65]);
                      
                       [maxProb, classIdx] = max(EEG.etc.ic_classification.ICLabel.classifications(compIdx, :));
                       classLabel = classLabels{classIdx};
                       title_str = sprintf('%s', classLabel);
                       prob_str = sprintf('%.2f%%', maxProb * 100);
                       title({[num2str(idx),':',title_str], prob_str});
                   end
               end
           end
          
           EEG_ori.icaact = EEG.icaact;
           EEG_ori.icawinv = EEG.icawinv;
           EEG_ori.icasphere = EEG.icasphere;
           EEG_ori.icaweights = EEG.icaweights;
           EEG_ori.icachansind = EEG.icachansind;
           EEG_ori.etc = EEG.etc;
           
           eye_i = find(ismember(EEG_ori.etc.ic_classification.ICLabel.classes, 'Eye'));
           eye_ic = find(EEG_ori.etc.ic_classification.ICLabel.classifications(:, eye_i(1)) > .8);
           EEG_ori = pop_subcomp(EEG_ori, eye_ic, 0);
          
          
           cla(findobj(allchild(src.Parent), 'Tag', 'plot_after'));
           plot(findobj(allchild(src.Parent), 'Tag', 'plot_after'), EEG_ori.times/1000, EEG_ori.data');
           axes(findobj(allchild(src.Parent), 'Tag', 'plot_after'));
           axis(findobj(allchild(src.Parent), 'Tag', 'plot_before'), 'tight');
           xlim(findobj(allchild(src.Parent), 'Tag', 'plot_before').XLim);
           ylim(findobj(allchild(src.Parent), 'Tag', 'plot_before').YLim);
          
           axis(findobj(allchild(src.Parent), 'Tag', 'plot_before'), 'tight');
          
           all_eeg_temp.EEG_processed = EEG_ori;
           guidata(src, all_eeg_temp);
       end
   end
end
