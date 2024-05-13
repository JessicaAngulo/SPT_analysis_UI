function [TCZ_video,n_stalls] = TCZ_perMovie(app,v,pixel_size)
%TCZ_PERMOVIE Takes each trajectory and inputs it to the function
%"TCZ_perTrack_nico"
%   09.06.2022 Jessica Angulo Capel
%% Video Data
dt = app.save_session.(v).f_rate;
v_x = (app.Loaded_files.video_file{1,4}).*pixel_size;
v_y = (app.Loaded_files.video_file{1,5}).*pixel_size;
[h,w] = size(app.Loaded_files.video_file{1,4});
Dif_coef = app.Analysis.Dif_analysis.By_video.(v).ImDif;
%% Apply track filtering
v_x(app.save_session.(v).FilteredTracks.Filter == 0,:) = 0;
v_y(app.save_session.(v).FilteredTracks.Filter == 0,:) = 0;
%% TCZ analysis per track
TCZ_video = NaN(h,w);
n_stalls = zeros(h,1);
for i = 1:h
    if sum(v_x(i,:),'omitnan') ~= 0
        track = [v_x(i,:)',v_y(i,:)',(1:1:w)'];
        track = track(~isnan(track(:,1)),:);
        Dif = Dif_coef(i,1);
        if Dif < 0.001
            seq = track(:,3);
            for j = seq
                TCZ_video(i,j) = 0;
            end
        elseif ~isnan(Dif)
            L_threshold = 1.5;
            segment_maximum = 10;
            minimumSegmentLength = 5;
            confinementRadius = 'fixedSize';
            DiniFixed = pi*(0.15)^2/(10*dt);
            [Final_TCZ] = TCZ_perTrack_nico(track,dt,...
            L_threshold,segment_maximum,minimumSegmentLength,confinementRadius,...
            DiniFixed,Dif);
            if ~isempty(Final_TCZ)
                seq = Final_TCZ(1:end,4);
                for j = 1:length(seq)
                    seq_j = seq(j,1);
                    TCZ_video(i,seq_j) = Final_TCZ(j,3);
                end
                n_stalls(i,1) = Final_TCZ(end,3);
            end
        end
    end
end
end