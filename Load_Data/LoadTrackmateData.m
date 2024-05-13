function [video_file] = LoadTrackmateData(app,v)
%LOADDATA Imports and processes the tiff video, and loads the Trackmate 
%data as a 2D matrix (trajectory number vs frame)
%   28.04.22 Jessica Angulo Capel
%% Tracking Parameters Import
p_file = app.save_session.(v).path;
try
    trackDatastore = fileDatastore(p_file{1,1},'ReadFcn',@importTrackMate);
catch
    video_file = [];
    return
end
pre_file = readall(trackDatastore); %read out of the track file
pre_file{1,1} = sortrows(pre_file{1,1},'FRAME','ascend');
no_track = ~isnan(pre_file{1,1}.TRACK_ID);
pre_file{1,1} = pre_file{1,1}(no_track,:); %erase spots not assigned to any track
% Frame rate of the video
if any(pre_file{1,1}.FRAME(:) == 1)
    f_rate = pre_file{1,1}(pre_file{1,1}.FRAME == 1,:);
    m = min(f_rate.TRACK_ID);
    f_rate = f_rate.POSITION_T(f_rate.TRACK_ID == m);
elseif any(pre_file{1,1}.FRAME(:) == 2)
    f_rate = pre_file{1,1}(pre_file{1,1}.FRAME == 2,:);
    m = min(f_rate.TRACK_ID);
    f_rate = (f_rate.POSITION_T(f_rate.TRACK_ID == m))/2;
end
app.save_session.(v).f_rate = f_rate;
%% Video Import and Processing
% The following lines import the image from the given path
videoDataStore = datastore(p_file{1,2},'ReadFcn',@imfinfo);
video_file = readall(videoDataStore);
[image,image_n] = LoadTiffFast(video_file);
% Processing for 2 chanel tif files
if app.save_session.(v).Time_lapse == 1
    ch2_rate = app.save_session.(v).Frequency;
    if app.preview_bar.CancelRequested
        return
    end
    %Selecting the frames of ch1
    list = 1:((ch2_rate)*2+2):image_n;
    if list(1,end) + ((ch2_rate)*2+2) ~= image_n %if there are missing frames
        image_n = list(1,end); %eliminate last set of frames
        list = list(1:end-1);
    end
    count = 0;
    for j = list
        for k = 2:2:(ch2_rate)*2
            count = count + 1;
            ch1(:,:,count) = image(:,:,j+k);
        end
    end
    ch1(:,:,count+1) = image(:,:,j+1); %blank frame in the end
    %Selecting the frames of ch2
    count = 0;
    for j = list
        for k = 1:ch2_rate
            count = count + 1;
            ch2(:,:,count) = image(:,:,j+1);
        end
    end
    ch2(:,:,count+1) = image(:,:,list(end)); %last mask frame
    Idouble = im2double(ch2(:,:,1));
    M = max(Idouble, [], 'all');
    [~,~,n_frames] = size(ch2);
    for i = 1:n_frames
        ch2(:,:,i) = imadjust(ch2(:,:,i),[0 M],[]);
    end
    ch2 = uint8(ch2/256); %compresses the image to 8 bit
    app.Loaded_files.Channel2 = ch2; %saving channel 2
    app.save_session.(v).Channel2Type = 0; %channel 2 is not a single image
else
    ch1 = image;
end
% Intensity histogram adjust for contrast enhancement
Idouble = im2double(ch1(:,:,1));
M = max(Idouble, [], 'all');
[~,~,n_frames] = size(ch1);
for i = 1:n_frames
    if M<= 0 %checkpoint if there is a mistake
        return
    end
    ch1(:,:,i) = imadjust(ch1(:,:,i),[0 M],[]);
end
ch1 = uint8(ch1/256); %compresses the image to 8 bit
%Saving channel 1
video_file{1,2} = ch1; %brings the whole matrix into the cell video_file
video_file = [pre_file,video_file];

if app.preview_bar.CancelRequested
    return
end
app.preview_bar.Value = 0.01;

%% Localizations data: used for the representation of the localization points, 
%trajetories, ID of the spots... 
a = video_file{1,2}(1).XResolution; %for scaling x
b = video_file{1,2}(1).YResolution; %for scaling y
[~,~,n_frames] = size(video_file{1,3});
traj_id = unique(video_file{1,1}.TRACK_ID);
preview_file_x = NaN(length(traj_id),n_frames);
preview_file_y = NaN(length(traj_id),n_frames);
temp_video = video_file{1,1}; %temporal video_file{1,1}
num_frame = zeros(1,n_frames);
for f = 1:n_frames
    while true
        track_frame = temp_video(temp_video.FRAME == f-1,:);
        temp_video(1:height(track_frame),:) = [];
        track_frame(isnan(track_frame.TRACK_ID) == 1,:) = []; %remove non tagged spots
        num_frame(1,f) = height(track_frame); %number of tracks per frame
        for t = 1:height(track_frame)
            track = table2array(track_frame(t,1));
            x_coord = track_frame.POSITION_X(track_frame.TRACK_ID == track);
            x_coord = ((x_coord*a))+0.5; %scaling to the UI axis
            y_coord = track_frame.POSITION_Y(track_frame.TRACK_ID == track);
            y_coord = ((y_coord*b))+0.5;
            preview_file_x(track+1,f) = x_coord;
            preview_file_y(track+1,f) = y_coord;
        end
        if height(temp_video) == 0
            break
        elseif temp_video.FRAME(1) ~= f-1
            break
        end
    end
    %Loading bar Cancel check point
    if app.preview_bar.CancelRequested
        return
    end
    app.preview_bar.Value = app.preview_bar.Value + ...
        (0.8*(1/length(video_file{1,2})));
end
if video_file{1,2}(1).XResolution ~= 1
    app.save_session.(v).px_size_x = ...
        (video_file{1,2}(1).Width/video_file{1,2}(1).XResolution)/...
        video_file{1,2}(1).Width;
    app.save_session.(v).px_size_y = ...
        (video_file{1,2}(1).Height/video_file{1,2}(1).YResolution)/...
        video_file{1,2}(1).Height;
end
video_file{1,4} = preview_file_x;
video_file{1,5} = preview_file_y;
app.Loaded_files.video_file = video_file;
max_text = max(num_frame); %max number of tracks per frame
app.save_session.(v).max_text = max_text;
end