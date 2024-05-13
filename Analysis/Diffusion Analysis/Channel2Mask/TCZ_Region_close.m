function [n_stalls_c,n_stalls_f] = TCZ_Region_close(v,app)
%TCZ_REGION_CLOSE classifies the already found TCZ into close or far
%from the detected regions. 
%   08/07/2022 Jessica Angulo
%% Previous data
close = app.Analysis.Channel2Mask.By_video.(v).group_close;
traj_pos = app.Analysis.Channel2Mask.By_video.(v).ratio_close;
TCZ_video = app.Analysis.Dif_analysis.By_video.(v).TCZ_logical;
[h,w] = size(TCZ_video);
n_stalls = app.Analysis.Dif_analysis.By_video.(v).n_stalls;
%% Classification
%Number of stalls in trajectories classified as close and far. I. e.
%trajectories that stay close or far more than half of the steps. 
% stalls_traj_c = n_stalls(traj_pos>=0.5,1);
% stalls_traj_c = sum(stalls_traj_c);
% stalls_traj_f = n_stalls(traj_pos<0.5,1);
% stalls_traj_f = sum(stalls_traj_f);
%Classification of the stalls as inside or outside
stalls_c_log = zeros(h,w);
stalls_f_log = zeros(h,w);
n_stalls_c = 0;
n_stalls_f = 0;
for i = 1:h
    track = TCZ_video(i,:);
    if n_stalls(i,1) > 0
        in = logical(close(i,:));
        for j = 1:n_stalls(i,1)
            track_j = (track == j);
            CZ_length = sum(track_j);
            CZ_in = track_j(1,in);
            CZ_in = sum(CZ_in);
            CZ_ratio_c = CZ_in/CZ_length;
            if CZ_ratio_c >= 0.5
                stalls_c_log(i,track_j) = 1;
                n_stalls_c = n_stalls_c + 1;
            else
                stalls_f_log(i,track_j) = 1;
                n_stalls_f = n_stalls_f + 1;
            end
        end
    end
end
%% Save data
app.Analysis.Channel2Mask.By_video.(v).stalls_close_log = stalls_c_log;
app.Analysis.Channel2Mask.By_video.(v).stalls_far_log = stalls_f_log;
app.Analysis.Channel2Mask.By_video.(v).n_stalls_close = n_stalls_c;
app.Analysis.Channel2Mask.By_video.(v).n_stalls_far = n_stalls_f;
end