function ReloadComposite(app)
%RELOADCOMPOSITE Creates de the RGB composite
%   Detailed explanation goes here
%% Get 2 channels
channel1 = app.video_file{1,3};
v = string(app.showing_video);
channel2 = app.Loaded_files.Channel2;
%% Scaling each channel with the corresponding contrast
slope1 = (255 - app.c_l.Position(1,1))/app.c_l.Position(2,1);
channel1 = (channel1*slope1)+app.c_l.Position(1,1);
slope2 = (255 - app.c2_l.Position(1,1))/app.c2_l.Position(2,1);
channel2 = (channel2*slope2)+app.c2_l.Position(1,1);
%% Creation of the RGB composite
composite = imfuse(channel2(:,:,1),channel1(:,:,1),...
        'falsecolor','ColorChannels',[2 1 2],'Scaling','none'); %first frame
[~,~,n_frames] = size(channel2);
if app.preview_bar.CancelRequested
    return
end
for i = 2:n_frames %the following frames
    composite_f2 = imfuse(channel2(:,:,i),channel1(:,:,i),...
        'falsecolor','ColorChannels',[2 1 2],'Scaling','none');
    composite = cat(4,composite,composite_f2);
    app.preview_bar.Value = app.preview_bar.Value + (0.65*(1/(n_frames-1)));
    if app.preview_bar.CancelRequested
        return
    end
end
if app.preview_bar.CancelRequested
    return
end
%% Save new composite
app.Loaded_files.video_file{1,6} = composite;
app.video_file{1,6} = composite;
end