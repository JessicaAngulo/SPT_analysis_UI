video = fieldnames(app.save_session);
Rad_allvideos = [];
Mean_dist_allvideos = [];
dist_last_allvideos = [];
for k = 1:numel(video)
    v = video{k};
    %Load from disk
    dir = what('temp');
    filename = string(dir.path) + "\" + v + ".mat";
    load(filename);
    app.Loaded_files = var1;
    clear var1
    if k == 1
        if isnan(app.save_session.(v).px_size_x)
            prompt = 'Your data is saved in pixel units. Please, introduce the pixel size in [um]';
            pixel_size = inputdlg(prompt);
            pixel_size = str2double(pixel_size);
            app.save_session.(v).px_size_x = pixel_size;
            app.save_session.(v).px_size_y = pixel_size;
        else
            pixel_size = app.save_session.(v).px_size_x;
        end
    end
    dt = app.save_session.(v).f_rate;
    v_x = (app.Loaded_files.video_file{1,4}).*pixel_size;
    v_y = (app.Loaded_files.video_file{1,5}).*pixel_size;
    dist = app.Analysis.Channel2Mask.By_video.(v).Distance2Boundaries; %previously calculated distance to boundaries
    dist = dist * pixel_size;
    inside = app.Analysis.Channel2Mask.By_video.(v).group_inside;
    inside = logical(inside);
    dist(inside) = dist(inside)*(-1);
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
            dist = [dist(:,1:(c-1)),extra_col,dist(:,c:end)];
        end
    end
    %% Apply track filtering
    v_x(app.save_session.(v).FilteredTracks.Filter == 0,:) = 0;
    v_y(app.save_session.(v).FilteredTracks.Filter == 0,:) = 0;
    dist(app.save_session.(v).FilteredTracks.Filter == 0,:) = 0;
    %% Calculate diffusion radius
    Rad_i = nan(h,1); %dif radius of each trajectory, in this video
    Mean_dist_i = nan(h,1); %mean distance to boundary of each traj, in this video
    dist_last_i = nan(h,1); %distance of the last localization, in this video
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
            d = (dist(j,:))';
            logi2 = find(~isnan(d));
            if ~isempty(logi2)
                N2 = (logi2(end,1)-logi(1,1))+1;
            else
                N2 = 0;
            end
            n = ceil(5/dt); % n is the number of frames we need to analyze, for analyzing 5 s with dt framerate
            if N >= n & N2 >= n %the traj length needs to be bigger or equal to the analyzed region (n)
                x = x(logi(end-n+1):logi(end),1); %we cut the last n frames of the trajectory
                x = x(~isnan(x),1); %we remove the possible NaN left (from blinking events)
                y = y(logi(end-n+1):logi(end),1);
                y = y(~isnan(y),1);
                d = d(logi(end-n+1):logi(end),1);
                %Calculation of the mean distance to boundaries
                mean_d = (sum(d(:,1),"all"))/length(d);
                dist_last_j = d(end);
                %Calculation of the mean position for that trajectory section
                mean_x = (sum(x(:,1),"all"))/length(x);
                mean_y = (sum(y(:,1),"all"))/length(y);
                %Calculation of the mean distance to the centroid position
                dx = 0;
                for m = 1:n
                    dx_m = sqrt((x(m,1) - mean_x(1,1)).^2 + (y(m,1) - mean_y(1,1)).^2);
                    dx = dx + dx_m;
                end
                dx = dx/n;
                Rad_i(j,1) = dx;
                Mean_dist_i(j,1) = mean_d;
                dist_last_i(j,1) = dist_last_j;
            end
        end
    end
    app.Analysis.Dif_analysis.By_video.(v).Dif_radius = Rad_i;
    app.Analysis.Channel2Mask.By_video.(v).Mean_Dist2Bound = Mean_dist_i;
    app.Analysis.Channel2Mask.By_video.(v).Dis_last_loc = dist_last_i;
    Rad_i = Rad_i(~isnan(Rad_i),1);
    Rad_allvideos = [Rad_allvideos;Rad_i];
    Mean_dist_i = Mean_dist_i(~isnan(Mean_dist_i),1);
    Mean_dist_allvideos = [Mean_dist_allvideos;Mean_dist_i];
    dist_last_i = dist_last_i(~isnan(dist_last_i),1);
    dist_last_allvideos = [dist_last_allvideos;dist_last_i];
end
app.Analysis.Dif_analysis.DifRad_allvideos = Rad_allvideos;
app.Analysis.Channel2Mask.Mean_Dist2Bound = Mean_dist_allvideos;
app.Analysis.Channel2Mask.Dist_last_loc = dist_last_allvideos;
%% Classification
% In vs. Out
video = fieldnames(app.save_session);
rad_in_allvideos = [];
rad_out_allvideos = [];
for k = 1:numel(video)
    v = video{k};
    traj_pos = app.Analysis.Channel2Mask.By_video.(v).ratio_in;
    Rad_i = app.Analysis.Dif_analysis.By_video.(v).Dif_radius;
    rad_out = Rad_i(traj_pos<0.5,1);
    rad_in = Rad_i(traj_pos>=0.5,1);
    rad_in_allvideos = [rad_in_allvideos;rad_in];
    rad_out_allvideos = [rad_out_allvideos;rad_out];
end
% Close vs. Far
video = fieldnames(app.save_session);
rad_close_allvideos = [];
rad_far_allvideos = [];
for k = 1:numel(video)
    v = video{k};
    traj_pos = app.Analysis.Channel2Mask.By_video.(v).ratio_close_traj;
    Rad_i = app.Analysis.Dif_analysis.By_video.(v).Dif_radius;
    rad_close = Rad_i(traj_pos>=0.5,1);
    rad_far = Rad_i(traj_pos<0.5,1);
    rad_close_allvideos = [rad_close_allvideos;rad_close];
    rad_far_allvideos = [rad_far_allvideos;rad_far];
end
%% Plotting
% Diffusion radius vs distance to boundary heat map 
histogram2(Rad_allvideos,Mean_dist_allvideos,'DisplayStyle','tile','Normalization','probability','ShowEmptyBins','on')
xlabel('Diffusion Radius [\mum]')
ylabel('mean distance to boundary [\mum]')
c = colorbar;
c.Label.String = 'Probability';

histogram2(Rad_allvideos,dist_last_allvideos,'DisplayStyle','tile','Normalization','probability','ShowEmptyBins','on')
xlabel('Diffusion Radius [\mum]')
ylabel('distance to boundary of the last localization [\mum]')
c = colorbar;
c.Label.String = 'Probability';

% Mean distance to boundaries segregated by dif radius
video = fieldnames(app.save_session);
Rad_big = []; %values for the mean distance to boundaries for traj of big dif radius
Rad_small = []; %same but for small dif radius
for k = 1:numel(video)
    v = video{k};
    Rad_i = app.Analysis.Dif_analysis.By_video.(v).Dif_radius;
    Mean_dist_i = app.Analysis.Channel2Mask.By_video.(v).Mean_Dist2Bound;
    Rad_big_i = Mean_dist_i(Rad_i>0.15);
    Rad_big_i = Rad_big_i(~isnan(Rad_big_i));
    Rad_small_i = Mean_dist_i(Rad_i<=0.15);
    Rad_small_i = Rad_small_i(~isnan(Rad_small_i));
    Rad_big = [Rad_big;Rad_big_i];
    Rad_small = [Rad_small;Rad_small_i];
end
[~,edges] = histcounts(Rad_small);
ax = axes;
histogram(Rad_small,edges,'Normalization','probability','Parent',ax,'DisplayName',"Small diffusion radius")
hold(ax,'on')
ylabel("Probability");
xlabel("Mean distance to boundaries [\mum]");
histogram(Rad_big,edges,'Normalization','probability','Parent',ax,'DisplayName',"Big diffusion radius")
legend

% Distance to boundaries (last localization) segregated by dif radius
video = fieldnames(app.save_session);
Rad_big = []; %values for the mean distance to boundaries for traj of big dif radius
Rad_small = []; %same but for small dif radius
for k = 1:numel(video)
    v = video{k};
    Rad_i = app.Analysis.Dif_analysis.By_video.(v).Dif_radius;
    dist_last_i = app.Analysis.Channel2Mask.By_video.(v).Dis_last_loc;
    Rad_big_i = dist_last_i(Rad_i>0.15);
    Rad_big_i = Rad_big_i(~isnan(Rad_big_i));
    Rad_small_i = dist_last_i(Rad_i<=0.15);
    Rad_small_i = Rad_small_i(~isnan(Rad_small_i));
    Rad_big = [Rad_big;Rad_big_i];
    Rad_small = [Rad_small;Rad_small_i];
end
[~,edges] = histcounts(Rad_small);
ax = axes;
histogram(Rad_small,edges,'Normalization','probability','Parent',ax,'DisplayName',"Small diffusion radius")
hold(ax,'on')
ylabel("Probability");
xlabel("Distance to boundaries of the last localization [\mum]");
histogram(Rad_big,edges,'Normalization','probability','Parent',ax,'DisplayName',"Big diffusion radius")
legend