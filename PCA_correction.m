function EEG = PCA_correction(EEG)
h = figure('NumberTitle', 'off','Name','PCA Correction','Units','normalized','position',[.1,.5,.8,.3]);
eeg_plot = axes(h,'position',[.1,.35,.8,.6],'Tag','eeg_plot'); hold on;ylim('auto');
curves = plot(eeg_plot, EEG.times/1000, EEG.data','Tag','curve'); xlim tight;xlabel('Time (s)');ylabel('Potential (\muV)');
% store selections
data.selected_wins = [];
data.EEG = EEG;
guidata(h, data);
bt_select_win = uicontrol(h, 'Style', 'pushbutton', 'Units','Normalized', 'Position',...
   [0.1 .1 0.2 0.1],'String', 'Select Time Window','Callback', @select_win);
bt_pca_correct = uicontrol(h, 'Style', 'pushbutton', 'Units','Normalized', 'Position',...
   [0.3 .1 0.15 0.1],'String', 'Correct','Callback', @pca_correct);
bt_cancel_selection = uicontrol(h, 'Style', 'pushbutton', 'Units','Normalized', 'Position',...
   [0.45 .1 0.15 0.1],'String', 'Cancel Selection','Callback', @cancel_selection);
bt_resetylim = uicontrol(h,'Style','pushbutton','Units','Normalized','Position',...
   [0.6 .1 0.1 0.1],'String','Reset Ylim','Callback', @reset_ylim );
bt_save_data = uicontrol(h, 'Style', 'pushbutton', 'Units','Normalized', 'Position',...
   [0.7 .1 0.2 0.1],'String', 'Save Data','Callback', 'if ~isempty(guidata(gcf)) data = guidata(gcf); EEG = data.EEG; msgbox("saved!"); end');
% horizontal slider
slider_h = uicontrol(h, 'Style', 'slider', 'Units', 'Normalized', 'Position', ...
   [0.1, 0.01, 0.8, 0.05], 'Tag', 'slider_h', 'Callback', @slider_h_callback);

set(slider_h, 'Min', EEG.times(1)/1000, 'Max', EEG.times(end)/1000 - 5, 'Value', EEG.times(1)/1000, 'SliderStep', [0.01, 0.1]);
addlistener(slider_h, 'ContinuousValueChange', @(src, event) slider_h_callback(src, event));


% vertical slider
slider_v = uicontrol(h, 'Style', 'slider', 'Units', 'Normalized', 'Position', ...
   [0.95, 0.35, 0.02, 0.6], 'Tag', 'slider_v', 'Callback', @slider_v_callback);
ax = findobj(allchild(gcf),'Tag','eeg_plot');
ylim_values = ylim(ax);
set(slider_v, 'Min', ylim_values(1), 'Max', ylim_values(2) - 5, 'Value', ylim_values(1), 'SliderStep', [0.01, 0.1]);
addlistener(slider_v, 'ContinuousValueChange', @(src, event) slider_v_callback(src, event));


function select_win(src, event, handle)
   [x, y] = ginput(2);
   rect = fill(findobj(allchild(src.Parent),'Tag','eeg_plot'), [x(1),x(2),x(2),x(1)],...
       [findobj(allchild(src.Parent),'Tag','eeg_plot').YLim(1), findobj(allchild(src.Parent),'Tag','eeg_plot').YLim(1),...
       findobj(allchild(src.Parent),'Tag','eeg_plot').YLim(2), findobj(allchild(src.Parent),'Tag','eeg_plot').YLim(2)],...
       'cyan','EdgeColor','none','FaceAlpha',.2,'Tag','filled_rect');
   data = guidata(src);
   data.selected_wins = [data.selected_wins; rect];
   guidata(src, data);
end



function reset_ylim(src, event, handle)
   ylim(findobj(allchild(src.Parent),'Tag','eeg_plot'), 'auto');
end


function cancel_selection(src, event, handle)
   data = guidata(src);
   if ~isempty(data.selected_wins)
        delete(data.selected_wins(end));
        data.selected_wins(end) = [];
        guidata(src, data);
   end
end
function pca_correct(src, event, handle)
   data = guidata(src);
   EEG = data.EEG;
   rects = findobj(allchild(src.Parent),'Tag','filled_rect');
   idx_all = [];
   idx_list = {};
   for j = 1:length(rects)
       x1 = min(rects(j).XData);
       x2 = max(rects(j).XData);
       if isfield(EEG,'pca_wins')
           EEG.pca_wins{end+1} = [x1,x2];
       else
           EEG.pca_wins = {[x1,x2]};
       end
       temp_seg = find(EEG.times/1000 > x1 & EEG.times/1000 < x2);
       idx_all(end+1:end+length(temp_seg)) = temp_seg;
       idx_list{j} = temp_seg;
   end
   clean_win = setdiff(1:size(EEG.data,2),idx_all(:));
   clean_data = EEG.data(:,clean_win);
   for r = 1:length(rects)
       idx = idx_list{r};
       seg = fix(size(clean_data,2)/length(idx));
       win_fun = prtc_tukey(length(idx),0.2);
       std_clean = [];
       for k = 1:seg
           temp_seg = clean_data(:,1+(k-1)*length(idx):k*length(idx))';
           std_clean(k) = mean(std(temp_seg,1,2));
       end
       temp_data = EEG.data(:,idx)';
       if max(idx) >= size(EEG.data,2)-1, win_fun = prtc_tukey(length(idx),0.2,2); end
       if min(idx) <= 2, win_fun = prtc_tukey(length(idx),0.2,1); end
       for kk = 1:size(temp_data,2), temp_data(:,kk) = temp_data(:,kk); end
       [a,b,c] = pca(temp_data,'Centered',false);
       for cc = 1:length(c)
           b(:,1:cc-1) = 0;
           data_restore = (b*a');
           std_restore = mean(std(data_restore,1,2));
           if std_restore < (median(std_clean)+2*mad(std_clean,1)), break; end
       end
       ind_final = 1:(cc-1);
       b(:,ind_final) = 0;
       temp_data1 = (b*a');
       data_diff = temp_data - temp_data1;
       for kk = 1:size(data_diff,2), data_diff(:,kk) = data_diff(:,kk).*win_fun; end
       EEG.data(:,idx) = EEG.data(:,idx) - data_diff';
   end
   xl = findobj(allchild(src.Parent),'Tag','eeg_plot').XLim;
   yl = findobj(allchild(src.Parent),'Tag','eeg_plot').YLim;
   cla(findobj(allchild(src.Parent),'Tag','eeg_plot'));
   plot(findobj(allchild(src.Parent),'Tag','eeg_plot'), EEG.times/1000, EEG.data');
   xlim(xl); ylim(yl); %ylim('auto');
   data.EEG = EEG;
   guidata(src, data);
end
function slider_h_callback(src, event)
   val = get(src, 'Value');
   ax = findobj(allchild(gcf),'Tag','eeg_plot');
   window_size = diff(ax.XLim); % Get the current window size
   xlim(ax, [val, val + window_size]); % Move the window while keeping its size
end
function slider_v_callback(src, event)
   val = get(src, 'Value');
   ax = findobj(allchild(gcf),'Tag','eeg_plot');
   window_size = diff(ax.YLim); % Get the current window size
   ylim(ax, [val, val + window_size]); % Move the window while keeping its size
end
end



