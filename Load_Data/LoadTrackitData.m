function [video_file] = LoadTrackitData(app,v)
%LOADDATA Imports and processes the tiff video, and loads the Trackmate 
%data as a 2D matrix (trajectory number vs frame)
%   28.04.22 Jessica Angulo Capel
%% Video import and processing
p_file = app.save_session.(v).path;
load(p_file{1,1}); %loads trackedPar from previously given path
pre_file{1,1} = trackedPar;
% Frame rate of the video
for i = 1:length(pre_file{1,1})
    if length(pre_file{1,1}(i).TimeStamp) > 1
        f_rate = abs(pre_file{1,1}(i).TimeStamp(2,1)) - abs(pre_file{1,1}(i).TimeStamp(1,1));
        break
    else
        continue
    end
end %i is the first trajectory with more than one time point
if length(pre_file{1,1}(i).TimeStamp) < 2
    prompt = 'It is not possible to extract the frame rate from your data. Please, introduce the frame rate in [s]';
    f_rate = inputdlg(prompt);
    f_rate = str2double(f_rate);
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
Idouble = im2double(ch1(:,:,3));
M = max(Idouble, [], 'all');
m = min(Idouble, [], 'all');
[~,~,n_frames] = size(ch1);
for i = 1:n_frames
    if M<= 0 %checkpoint if there is a mistake
        return
    end
    ch1(:,:,i) = imadjust(ch1(:,:,i),[m M],[]);
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
n_frames = length(video_file{1,3});
n_traj = length(pre_file{1,1});
preview_file_x = NaN(n_traj,n_frames);
preview_file_y = NaN(n_traj,n_frames);
for j = 1:length(pre_file{1,1}) %j=traj number
    for k = 1:length(pre_file{1,1}(j).Frame) %k=frame
        frame = pre_file{1,1}(j).Frame(k,1);
        if frame <= n_frames
            preview_file_x(j,frame) = abs((pre_file{1,1}(j).xy(k,1))*a) + 0.5; %x_value, in pixels, and normalized for proper representation (+0.5)
            preview_file_y(j,frame) = abs((pre_file{1,1}(j).xy(k,2))*b) + 0.5; %y_value
        end
    end
    %Loading bar Cancel check point
    if app.preview_bar.CancelRequested
        return
    end
end
%Loading bar Cancel check point
if app.preview_bar.CancelRequested
    return
end
app.preview_bar.Value = app.preview_bar.Value + ...
    (0.8*(1/length(video_file{1,2})));
% Track/frame 
log = ~isnan(preview_file_x(:,:));
num_frame = sum(log,1);
%% Save all important data
% Resolution
if video_file{1,2}(1).XResolution ~= 1
    app.save_session.(v).px_size_x = ...
        (video_file{1,2}(1).Width/video_file{1,2}(1).XResolution)/...
        video_file{1,2}(1).Width;
    app.save_session.(v).px_size_y = ...
        (video_file{1,2}(1).Height/video_file{1,2}(1).YResolution)/...
        video_file{1,2}(1).Height;
end
% Video_file
video_file{1,4} = preview_file_x;
video_file{1,5} = preview_file_y;
app.Loaded_files.video_file = video_file;
% Tracks/frame (max_text)
max_text = max(num_frame); %max number of tracks per frame
app.save_session.(v).max_text = max_text;
% Number of frames
app.save_session.(v).num_frames = width(video_file{1,4});
end