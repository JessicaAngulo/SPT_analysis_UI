function MaskSegmentation(app)
%MASKSEGMENTATION Represents I2, the overlay of the mask regions, over the
%original image, on the UIAxes_2. 
%   19.01.2022 Jessica Angulo
v = app.videoname.Value;
f = round(app.FrameSlider_Ch2.Value);
if app.save_session.(v).Channel2Type == 1
    g = 1; % there is only one mask image and label matrix
else
    ch2_rate = app.save_session.(v).Frequency;
    g = ceil(f/ch2_rate); %group that the frame belongs to
end
I2 = app.Analysis.Channel2Mask.By_video.(v).Overlay;
imshow(I2(:,:,:,g),'Parent',app.UIAxes_2)
if app.ShowlocalizationsCheckBox.Value == 1
    hold(app.UIAxes_2,'on')
    v_x = app.Loaded_files.video_file{1,4}(:,f);
    v_y = app.Loaded_files.video_file{1,5}(:,f);
    %apply track filters
    v_x(app.save_session.(v).FilteredTracks.Filter == 0,:) = NaN;
    v_y(app.save_session.(v).FilteredTracks.Filter == 0,:) = NaN;
    scatter(v_x,v_y,'rx','Parent',app.UIAxes_2)
    hold(app.UIAxes_2,'off')
end
end