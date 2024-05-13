function [theta_i] = TurningAngles(app,v)
%TURNINGANGLES calculates theta, the angle between consecutive
%displacements for each individual trajectory. 
%   Theta is calculated with the four-quadrant inverse tangent in degrees.
%   Taken from A. S. Hansen et al. Nature Chemical Biology (2020). 
%   30.06.2023 Jessica Angulo
dt = app.save_session.(v).f_rate;
pixel_size = app.save_session.(v).px_size_x;
v_x = (app.Loaded_files.video_file{1,4}).*pixel_size;
v_y = (app.Loaded_files.video_file{1,5}).*pixel_size;
%% Consider non-imaged frames in 2-color acquisitions
% We add 1 extra columns of NaN every "ch2_rate" frames, to calculate the right D
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

%% Calculation of the turning angle
[h,w] = size(v_x);
theta_i = [];
for j = 1:h %for each track
    if v_x(j,1) ~= 0 %if it is not a filtered track
        x = (v_x(j,:));
        y = (v_y(j,:));
        track = [x',y'];
        dxy = track(2:end,1:2)-track(1:end-1,1:2);
        U = dxy(1:end-1,:); 
        V = dxy(2:end,:);
        for k = 1:size(U,1)
            u = U(k,:); 
            v = V(k,:);
            theta = atan2d((cross([u 0],[v 0])),dot([u 0],[v 0]));
            theta_i = [theta_i; theta(3) j];
        end
    end
end

end