function [Dist_i,gaps_i,n_traj_i,traj_l_i] = Distancefromgap(app,v,pixel_size)
%DISTANCEFROMGAP It calculates the space distance from un frame to another
%after the molecule disappearing from some time. 
%   Jessica Angulo Capel 14.08.2023
t = app.save_session.(v).f_rate;
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
%% Calculate distance
Dist_i = nan(h,30); %rows will be each track, and columns will be each gap
gaps_i = nan(h,30); %number of gaps per traj
traj_l_i = nan(h,1); %trajectory length in ms
for j = 1:h %for each track
    x = v_x(j,:);
    y = v_y(j,:);
    if v_x(j,1) ~= 0 %not a previously filtered track
        startsStops = find(diff(isnan(x)))+1;
        if ~isnan(x(1))
            startsStops = [1 startsStops];
        end
        if ~isnan(x(end))
            startsStops = [startsStops length(x)+1];
        end
        stops = startsStops(1,2:2:end); %index of traj fragment starting
        starts = startsStops(1:2:end-1); %index of traj fragment finishing
        traj_l_i(j,1) = (stops(1,end))-(starts(1,1)); %length of the traj (including gaps)
        for k = 1:length(starts)-1
            gap = starts(k+1) - stops(k); %gap size
            gaps_i(j,k) = gap; %size of each gap (in frames)
            dx = sqrt((x(1,starts(k+1)) - x(1,(stops(k))-1)).^2 + (y(1,starts(k+1)) - y(1,(stops(k))-1)).^2); %displacement between these two points
            Dist_i(j,k) = dx;
        end
    end
end
n_traj_i = height(traj_l_i(~isnan(traj_l_i))); %number of trajectories per video