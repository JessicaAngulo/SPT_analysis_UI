function [mss_results,Dif_coef_y0] = MSS(app,v,pixel_size)
%MSS Finds the Moment Scalling Spectrum slope for each trajectory. 
%   28.06.2021 Roger Pons
dt = app.save_session.(v).f_rate;
v_x = (app.Loaded_files.video_file{1,4}).*pixel_size;
v_y = (app.Loaded_files.video_file{1,5}).*pixel_size;
[h,w] = size(app.Loaded_files.video_file{1,4});

%% Consider non-imaged frames in 2-color acquisitions
% We add 2 extra columns of NaN every 165 frames, to calculate the right D
if app.save_session.(v).Time_lapse == 1
    ch2_rate = app.save_session.(v).Frequency;
    non_im = app.save_session.(v).Non_imaged_frame;
    [h,w] = size(app.Loaded_files.video_file{1,4});
    extra_col = NaN(h,non_im);
    list = 1:ch2_rate:w;
    for i = 2:(length(list))
        c = list(1,i);
        v_x = [v_x(:,1:(c-1)),extra_col,v_x(:,c:end)];
        v_y = [v_y(:,1:(c-1)),extra_col,v_y(:,c:end)];
    end
end

%% Apply track filtering
v_x(app.save_session.(v).FilteredTracks.Filter == 0,:) = 0;
v_y(app.save_session.(v).FilteredTracks.Filter == 0,:) = 0; 

%% Calculate MSS
[h,w] = size(v_x);
mss_results = NaN(h,1);
Dif_coef_y0 = NaN(h,1);
for j = 1:h
    if v_x(j,1) ~= 0 %previously filtered track
        x_t=v_x(j,:)';
        x_t(isnan(x_t)==1)=[];
        N = length(x_t);
        y_t=v_y(j,:)';
        y_t(isnan(y_t)==1)=[];
        if N>20
            mss = zeros(N,7);
            for v = 0:6 %v from 0 to 6
                for m = 0:N-1 %the loop goes from 1 to N
                    mss(m+1,v+1) = sum(sqrt(((x_t(1+m:end) - x_t(1:end-m)).^2 + ((y_t(1+m:end) - y_t(1:end-m)).^2))),'omitnan').^v/(N-m);
                end
            end
            mss(1,:) = []; %we erase the first row
            alpha = NaN(width(mss),1);
            for v = 0:6 %extract alpha for each moment (v)
                L = round(length(mss(:,v+1))/3); %v that we take
                pfit = polyfit((real(log10((1:L)).*dt))',real(log10(mss(1:L,v+1))),1);
                if pfit(1,1) >= 0 %if slope is not negative
                    if v == 2
                       dif_coef_y0 = 1/4*exp(pfit(1,2));
                       Dif_coef_y0(j,1) = dif_coef_y0;
                    end
                    alpha(v+1,1)=pfit(1,1);
                end
            end
            Smms = polyfit(0:1:6,alpha',1);
            mss_results(j,1) = Smms(1,2);
        end
    end
end
end