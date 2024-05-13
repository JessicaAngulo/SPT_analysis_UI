function [msd_i,Dif_i] = MSD(app,v,pixel_size)
%Calculation of the Mean Squared Displacement. 
%The immediate diffusion coefficient (D) is the slope of the equation
%MSD = 2dDm, assuming a Browinan motion. 
%   16.06.2021 Jessica Angulo Capel
dt = app.save_session.(v).f_rate;
v_x = (app.Loaded_files.video_file{1,4}).*pixel_size;
v_y = (app.Loaded_files.video_file{1,5}).*pixel_size;
[h,w] = size(v_y);
%% Consider non-imaged frames in 2-color acquisitions
% We add extra columns of NaN, to calculate the right D
if app.save_session.(v).Time_lapse == 1
    ch2_rate = app.save_session.(v).Frequency;
    non_im = app.save_session.(v).Non_imaged_frame;
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

%% Calculate msd for each m, and fit the D(1-4)
[h,w] = size(v_y);
msd_i = nan(h,w); %rows will be each track, and columns will be m
Dif_i = nan(h,1);
for j = 1:h %for each track
    if v_x(j,1) ~= 0 %previously filtered track
        x = (v_x(j,:))';
        x = x(~isnan(x),1);
        y = (v_y(j,:))';
        y = y(~isnan(y),1);
        N = length(x);
%         if N > 12 %if we are interested only in the last frames
%             x = x(end-13:end,:);
%             y = y(end-13:end,:);
%         end
        %list of msd for each m
        for m = 0:N-1
            msd = sum(((x(1+m:end) - x(1:end-m)).^2)+(y(1+m:end) - y(1:end-m)).^2,'omitnan')/(N-m);
            msd_i(j,m+1)= msd;
        end
        if N > 12
            msd_j = msd_i(j,1:4);
            D = polyfit((4*(1:4)*dt),msd_j,1); %instant diffusion, calculated for t lag from 1 to 4.
            D = D(1,1);
            if D > 0
                Dif_i(j,1) = D;
            end
        end
    end
end