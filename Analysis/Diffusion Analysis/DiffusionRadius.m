function [Rad_i,Mean_dist_i,dist_last_i] = DiffusionRadius(app,v,pixel_size)
%DIFFUSIONRADIUS Calculates the mean distance to centroid position for each
%trajectory. 
%   03.07.2023 Jessica Angulo
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
%% Calculate diffusion radius
Rad_i = nan(h,1); %dif radius of each trajectory, in this video
for j = 1:h %for each track
    if v_x(j,1) ~= 0 %not a previously filtered track
        x = (v_x(j,:))';
        y = (v_y(j,:))';
        logi = find(~isnan(x));
        if ~isempty(logi)
            N = (logi(end,1)-logi(1,1))+1;
        else
            N = 0;
        end
        %n = ceil(5/dt); % n is the minimum number of frames we need to analyze, corresponding to 5 s 
        n = 6; %minimum number of frames is 6
        if N >= n %the traj length needs to be bigger or equal to the analyzed region (n)
            x = x(~isnan(x),1); %we remove the possible NaN left (from blinking events)
            y = y(~isnan(y),1);
            N = length(x);
            %Calculation of the mean position for that trajectory section
            mean_x = (sum(x(:,1),"all"))/length(x);
            mean_y = (sum(y(:,1),"all"))/length(y);
            %Calculation of the mean distance to the centroid position
            dx = 0;
            for m = 1:N
                dx_m = sqrt((x(m,1) - mean_x(1,1)).^2 + (y(m,1) - mean_y(1,1)).^2);
                dx = dx + dx_m;
            end
            dx = dx/N;
            Rad_i(j,1) = dx;
        end
    end
end