function [dif_out,dif_in,mss_out,mss_in,vel_in,vel_out,traj_in,traj_out,rad_in,rad_out,theta_in,theta_out] = RegionAnalysis(app,v,imdif_yes,mss_yes,instv_yes,theta_yes,rad_yes)
%REGIONANALYSIS Classifies the D and MSS whether they are inside or
%outside of the thresholded regions found in ThresholdingAll. 
%   14.03.2022 Jessica Angulo Capel
%% Apply track filtering
x = app.Loaded_files.video_file{1,4};
y = app.Loaded_files.video_file{1,5};
x(app.save_session.(v).FilteredTracks.Filter == 0,:) = NaN;
y(app.save_session.(v).FilteredTracks.Filter == 0,:) = NaN;
L = app.Analysis.Channel2Mask.By_video.(v).Label_matrix;
%% Classification of localizations in in and out
[t,f] = size(x);
inside = zeros(t,f);
outside = zeros(t,f);
in_group = NaN(t,f);
if app.save_session.(v).Channel2Type == 1 % there is only one mask image and label matrix
    for j = 1:t
        traj = [x(j,:);y(j,:)];
        traj(1,:) = ceil(traj(1,:));
        traj(2,:) = ceil(traj(2,:));
        for k = 1:f
            loc_k = traj(:,k);
            if loc_k == 0
                loc_k = [1;1];
            end
            if ~isnan(loc_k(1,1)) == 1
                group = L(loc_k(1,1),loc_k(2,1));
                in_group(j,k) = group;
                if group ~= 0
                    outside(j,k) = 0;
                    inside(j,k) = 1;
                else
                    outside(j,k) = 1;
                    inside(j,k) = 0;
                end
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
        final = i +ch2_rate;
        g = ceil(i/(ch2_rate+1));
        parfor j = 1:t
            traj = [x(j,:);y(j,:)];
            traj(1,:) = ceil(traj(1,:));
            traj(2,:) = ceil(traj(2,:));
            for k = i:final
                loc_k = traj(:,k);
                if ~isnan(loc_k(1,1)) == 1
                    group = L(loc_k(1,1),loc_k(2,1),g);
                    in_group(j,k) = group;
                    if group ~= 0
                        outside(j,k) = 0;
                        inside(j,k) = 1;
                    else
                        outside(j,k) = 1;
                        inside(j,k) = 0;
                    end
                end
            end
        end
    end
end
%% Classification of the trajectories in in and out
traj_pos = NaN(t,1); %the values correspond to the ratio "in" of each traj
parfor i = 1:t
    length = ~isnan(x(i,:));
    length = sum(length,"all");
    traj_pos(i,1) = sum(inside(i,:),"all")/length;
end
traj_in = traj_pos>=0.5;
traj_in = sum(traj_in,'all','omitnan');
traj_out = traj_pos<0.5;
traj_out = sum(traj_out,'all','omitnan');
%% Parameter classification
dif_out = [];
dif_in = [];
mss_out = [];
mss_in = [];
vel_out = [];
vel_in = [];
if imdif_yes == 1
    dif_i = app.Analysis.Dif_analysis.By_video.(v).ImDif(:,1);
    dif_out(:,1) = dif_i(traj_pos<0.5,1);
    dif_in(:,1) = dif_i(traj_pos>=0.5,1);
end
if mss_yes == 1
    mss_i = app.Analysis.Dif_analysis.By_video.(v).MSS(:,1);
    mss_out(:,1) = mss_i(traj_pos<0.5,1);
    mss_in(:,1) = mss_i(traj_pos>=0.5,1);
end
if instv_yes == 1
    vel_i = app.Analysis.Dif_analysis.By_video.(v).InstantV(:,:);
    vel_out(:,:) = vel_i(traj_pos<0.5,:);
    vel_in(:,:) = vel_i(traj_pos>=0.5,:);
end
if rad_yes == 1
    Rad_i = app.Analysis.Dif_analysis.By_video.(v).Dif_radius;
    rad_in = Rad_i(traj_pos>=0.5,1);
    rad_out = Rad_i(traj_pos<0.5,1);
end
if theta_yes == 1
    theta_i = app.Analysis.Dif_analysis.By_video.(v).Angle;
    theta_in = theta_i(traj_pos>=0.5,1);
    theta_out = theta_i(traj_pos<0.5,1);
end
%% Save data
app.Analysis.Channel2Mask.By_video.(v).group_inside = inside;
app.Analysis.Channel2Mask.By_video.(v).group_outside = outside;
app.Analysis.Channel2Mask.By_video.(v).ratio_in = traj_pos;
app.Analysis.Channel2Mask.By_video.(v).group_region = in_group;
app.Analysis.Channel2Mask.By_video.(v).n_traj_in = traj_in;
app.Analysis.Channel2Mask.By_video.(v).n_traj_out = traj_out;
app.Analysis.Channel2Mask.By_video.(v).dif_rad_out = rad_out;
app.Analysis.Channel2Mask.By_video.(v).dif_rad_in = rad_in;
if imdif_yes == 1
    app.Analysis.Channel2Mask.By_video.(v).Dif_inside = dif_in;
    app.Analysis.Channel2Mask.By_video.(v).Dif_outside = dif_out;
end
if mss_yes == 1
    app.Analysis.Channel2Mask.By_video.(v).mss_inside = mss_in;
    app.Analysis.Channel2Mask.By_video.(v).mss_outside = mss_out;
end
if instv_yes == 1
    app.Analysis.Channel2Mask.By_video.(v).Vel_inside = vel_in;
    app.Analysis.Channel2Mask.By_video.(v).Vel_outside = vel_out;
end
if rad_yes == 1
    app.Analysis.Channel2Mask.By_video.(v).Dif_rad_inside = rad_in;
    app.Analysis.Channel2Mask.By_video.(v).Dif_rad_outside = rad_out;
end
if theta_yes == 1
    app.Analysis.Channel2Mask.By_video.(v).Angle_inside = theta_in;
    app.Analysis.Channel2Mask.By_video.(v).Angle_outside = theta_out;
end
% Plotting all results
h = axes;
h.XScale = 'log';
h.XLabel.String = 'Diff. coef. [\mum^2/s]';
h.YLabel.String = 'probability';
hold(h,'on')
[~,edges] = histcounts(log10(dif_in));
histogram(dif_out,10.^(edges(1,1):0.1:edges(1,end)),'Normalization','probability','Parent',h);
h.Children(1,1).DisplayName = 'Outside';
histogram(dif_in,10.^(edges(1,1):0.1:edges(1,end)),'Normalization','probability','Parent',h);
h.Children(1,1).DisplayName = 'Inside';
hold(h,'off')
end