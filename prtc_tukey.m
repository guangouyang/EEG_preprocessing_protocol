function f = prtc_tukey(n,r,varargin)


    t = linspace(0,1,n)';
    % Defines period of the taper as 1/2 period of a sine wave.
    per = r/2; 
    tl = floor(per*(n-1))+1;
    th = n-tl+1;
    % Window is defined in three sections: taper, constant, taper
    f = [ ((1+cos(pi/per*(t(1:tl) - per)))/2);  ones(th-tl-1,1); ((1+cos(pi/per*(t(th:end) - 1 + per)))/2)];

    if ~isempty(varargin)
        if varargin{1} == 1
            f = [ ones(tl,1);  ones(th-tl-1,1); ((1+cos(pi/per*(t(th:end) - 1 + per)))/2)];
        end
        if varargin{1} == 2
            f = [ ((1+cos(pi/per*(t(1:tl) - per)))/2);  ones(th-tl-1,1); ones(n-th+1,1)];
        end
    end
    


    if n==1 f = 1;end









% [EOF]
