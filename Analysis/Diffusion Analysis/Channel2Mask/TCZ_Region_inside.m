function [n_stalls_in,n_stalls_out] = TCZ_Region_inside(v,app)
%TCZ_REGION_INSIDE classifies the already found TCZ into inside or outside
%of the detected regions. 
%   08/07/2022 Jessica Angulo
%% Previous data
inside = app.Analysis.Channel2Mask.By_video.(v).group_inside;
traj_pos = app.Analysis.Channel2Mask.By_video.(v).ratio_in;
TCZ_video = app.Analysis.Dif_analysis.By_video.(v).TCZ_logical;
[h,w] = size(TCZ_video);
n_stalls = app.Analysis.Dif_analysis.By_video.(v).n_stalls;
%% Classification
%Number of stalls in trajectories classified as in and out. I. e.
%trajectories that stay inside or outside more than half of the steps. 
% stalls_traj_in = n_stalls(traj_pos>=0.5,1);
% stalls_traj_in = sum(stalls_traj_in);
% stalls_traj_out = n_stalls(traj_pos<0.5,1);
% stalls_traj_out = sum(stalls_traj_out);
%Classification of the stalls as inside or outside
stalls_in_log = zeros(h,w);
stalls_out_log = zeros(h,w);
n_stalls_in = 0;
n_stalls_out = 0;
for i = 1:h
    track = TCZ_video(i,:);
    if n_stalls(i,1) > 0
        in = logical(inside(i,:));
        for j = 1:n_stalls(i,1)
            track_j = (track == j);
            CZ_length = sum(track_j);
            CZ_in = track_j(1,in);
            CZ_in = sum(CZ_in);
            CZ_ratio_in = CZ_in/CZ_length;
            if CZ_ratio_in >= 0.5
                stalls_in_log(i,track_j) = 1;
                n_stalls_in = n_stalls_in + 1;
            else
                stalls_out_log(i,track_j) = 1;
                n_stalls_out = n_stalls_out + 1;
            end
        end
    end
end
%% Save data
app.Analysis.Channel2Mask.By_video.(v).stalls_in_log = stalls_in_log;
app.Analysis.Channel2Mask.By_video.(v).stalls_out_log = stalls_out_log;
app.Analysis.Channel2Mask.By_video.(v).n_stalls_in = n_stalls_in;
app.Analysis.Channel2Mask.By_video.(v).n_stalls_out = n_stalls_out;
end
%% Ploting
% I2 = app.Analysis.Channel2Mask.By_video.(v).Overlay;
% TCZ_video = ~isnan(TCZ_video);
% imshow(I2(:,:,:,1))
% hold on
% for i=1:57
% plot(b.video_d220224_s1_c3.video_file{1,4}(i,:),b.video_d220224_s1_c3.video_file{1,5}(i,:),'b');
% end
% plot(b.video_d220224_s1_c3.video_file{1,4}(i,TCZ_video(i,:)),b.video_d220224_s1_c3.video_file{1,5}(i,TCZ_video(i,:)),'y');
% for i=1:57
% plot(b.video_d220224_s1_c3.video_file{1,4}(i,TCZ_video(i,:)),b.video_d220224_s1_c3.video_file{1,5}(i,TCZ_video(i,:)),'y');
% end
% for i=1:57
% plot(b.video_d220224_s1_c3.video_file{1,4}(i,stalls_in_log(i,:)==1),b.video_d220224_s1_c3.video_file{1,5}(i,stalls_in_log(i,:)==1),'m');
% end