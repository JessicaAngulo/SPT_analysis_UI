function [dif_far,dif_close,mss_far,mss_close,vel_far,vel_close,traj_close,traj_far,rad_close,rad_far,theta_close,theta_far] = Distance2Boundaries(app,v,imdif_yes,mss_yes,instv_yes,theta_yes,rad_yes)
%DISTANCE2BOUNDARIES classifies the trajectories of each video whether they
%are close or far to the thresholded structure boundaries. 
%   14.03.2022 Jessica Angulo Capel
%% Apply track filtering
x = app.Loaded_files.video_file{1,4};
y = app.Loaded_files.video_file{1,5};
x(app.save_session.(v).FilteredTracks.Filter == 0,:) = NaN;
y(app.save_session.(v).FilteredTracks.Filter == 0,:) = NaN;
%% Classification of the localizations
[t,f] = size(x);
close = zeros(t,f);
far = zeros(t,f);
distance = NaN(t,f);
if app.save_session.(v).Channel2Type == 1
    boundaries = app.Analysis.Channel2Mask.By_video.(v).Boundaries;
    boundaries_i = [];
    for k = 1:length(boundaries)
        boundaries_i = [boundaries_i;boundaries{k,1}(:,:)];
    end
    for j = 1:t
        traj = [x(j,:);y(j,:)];
        for k = 1:f
            loc_k = traj(:,k)';
            if ~isnan(loc_k) == 1
                [~,D] = knnsearch(boundaries_i,loc_k);
                distance(j,k) = D;
            else
                continue
            end
        end
    end
else
    ch2_rate = app.save_session.(v).Frequency;
    list = 1:(ch2_rate+1):f;
    if list(1,end)+(ch2_rate+1) > f
        n = length(list)-1;
    else 
        n = length(list);
    end
    for i = list(1,1:n)
        final = i + ch2_rate;
        boundaries = app.Analysis.Channel2Mask.By_video.(v).Boundaries.("f"+(i));
        boundaries_i = [];
        for k = 1:length(boundaries)
            boundaries_i = [boundaries_i;boundaries{k,1}(:,:)];
        end
        for j = 1:t
            traj = [x(j,:);y(j,:)];
            for k = i:final
                loc_k = traj(:,k)';
                if ~isnan(loc_k) == 1
                    [~,D] = knnsearch(boundaries_i,loc_k);
                    distance(j,k) = D;
                else
                    continue
                end
            end
        end
    end
end
%% Classification of the localizations in close and far
close = distance<=3; %we create a logical for close and far localizations
far = distance>3;
close = double(close);
if isfield(app.Analysis.Channel2Mask.By_video.(v),'group_inside')
    inside = app.Analysis.Channel2Mask.By_video.(v).group_inside;
    close = close + inside;
    close = close ~= 0;
end
% Number of localizations close and far
n_close = sum(close,"all");
n_far = sum(far,"all");
ratio_close = n_close/(n_close+n_far);
%% Classification of the trajectories
traj_pos = NaN(t,1); %the values correspond to the ratio "close" of each traj
parfor i = 1:t
    length = ~isnan(x(i,:));
    length = sum(length,"all");
    traj_pos(i,1) = sum(close(i,:),"all")/length;
end
traj_close = traj_pos>=0.5;
traj_close = sum(traj_close,'all','omitnan');
traj_far = traj_pos<0.5;
traj_far = sum(traj_far,'all','omitnan');
%% We add a negative to the distances from inside
if isfield(app.Analysis.Channel2Mask.By_video.(v),'group_inside')
    inside = app.Analysis.Channel2Mask.By_video.(v).group_inside;
    distance(inside==1) = distance(inside==1)*(-1);
end

%% Diffusion parameters
dif_far = [];
dif_close = [];
mss_far = [];
mss_close = [];
vel_far = [];
vel_close = [];
rad_close = [];
rad_far = [];
theta_close = [];
theta_far = [];
if imdif_yes == 1
    dif_i = app.Analysis.Dif_analysis.By_video.(v).ImDif(:,1);
    dif_close(:,1) = dif_i(traj_pos>=0.5,1);
    dif_close = dif_close(~isnan(dif_close));
    dif_far(:,1) = dif_i(traj_pos<0.5,1);
    dif_far = dif_far(~isnan(dif_far));
end
if mss_yes == 1
    mss_i = app.Analysis.Dif_analysis.By_video.(v).MSS(:,1);
    mss_close(:,1) = mss_i(traj_pos>=0.5,1);
    mss_close = mss_close(~isnan(mss_close));
    mss_far(:,1) = mss_i(traj_pos<0.5,1);
    mss_far = mss_far(~isnan(mss_far));
end
if instv_yes == 1
    close = logical(close);
    far = logical(far);
    vel_i = app.Analysis.Dif_analysis.By_video.(v).InstantV;
    close = logical(close);
    vel_close(:,:) = vel_i(close);
    far = logical(far);
    vel_far(:,:) = vel_i(far);
end
if rad_yes == 1
    Rad_i = app.Analysis.Dif_analysis.By_video.(v).Dif_radius;
    rad_close = Rad_i(traj_pos>=0.5,1);
    rad_close = rad_close(~isnan(rad_close));
    rad_far = Rad_i(traj_pos<0.5,1);
    rad_far = rad_far(~isnan(rad_far));
end
if theta_yes == 1
    theta_i = app.Analysis.Dif_analysis.By_video.(v).Angle;
    theta_close = theta_i(traj_pos>=0.5,1);
    theta_close = theta_close(~isnan(theta_close));
    theta_far = theta_i(traj_pos<0.5,1);
    theta_far = theta_far(~isnan(theta_far));
end
%% Save data
app.Analysis.Channel2Mask.By_video.(v).Distance2Boundaries = distance;
app.Analysis.Channel2Mask.By_video.(v).group_close = close;
app.Analysis.Channel2Mask.By_video.(v).group_far = far;
app.Analysis.Channel2Mask.By_video.(v).ratio_close = ratio_close;
app.Analysis.Channel2Mask.By_video.(v).n_traj_close = traj_close;
app.Analysis.Channel2Mask.By_video.(v).n_traj_far = traj_far;
app.Analysis.Channel2Mask.By_video.(v).ratio_close_traj = traj_pos;
% if imdif_yes == 1
%     app.Analysis.Channel2Mask.By_video.(v).Dif_far = dif_far;
%     app.Analysis.Channel2Mask.By_video.(v).Dif_close = dif_close;
% end
% if mss_yes == 1
%     app.Analysis.Channel2Mask.By_video.(v).mss_far = mss_far;
%     app.Analysis.Channel2Mask.By_video.(v).mss_close = mss_close;
% end
% if instv_yes == 1
%     app.Analysis.Channel2Mask.By_video.(v).Vel_far = vel_far;
%     app.Analysis.Channel2Mask.By_video.(v).Vel_close = vel_close;
% end
% if rad_yes == 1
%     app.Analysis.Channel2Mask.By_video.(v).Dif_rad_far = rad_far;
%     app.Analysis.Channel2Mask.By_video.(v).Dif_rad_close = rad_close;
% end
% if theta_yes == 1
%     app.Analysis.Channel2Mask.By_video.(v).Angle_far = theta_far;
%     app.Analysis.Channel2Mask.By_video.(v).Angle_close = theta_close;
% end
end