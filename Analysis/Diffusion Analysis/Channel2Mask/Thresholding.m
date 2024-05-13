function Thresholding(app)
%THRESHOLDING creates a binary image of the selected frame, using an
%intensity threshold between 0 and 255. 
%   v = selected video file
%   th = 1x2 vector with the 2 threshold values
%   f = frame number
%   11.01.2022 Jessica Angulo
%% Selection
app.th_l.Position = round(app.th_l.Position);
v = app.videoname.Value;
th = (app.th_l.Position(:,1))';
f = round(app.FrameSlider_Ch2.Value);
%% Binary image
image = app.Analysis.Channel2Mask.By_video.(v).Ch2Image_Gaus(:,:,f);
binary = image >= th(1,1) & image <= th(1,2);
%% Colored image
redChannel = image;
greenChannel = image;
blueChannel = image;
redChannel(binary) = 255;
greenChannel(binary) = 0;
blueChannel(binary) = 0;
% Concatenate r, g, and b channels to form RGB image
rgbImage = cat(3, redChannel, greenChannel, blueChannel);
%% Represent in UI axes (analysis tab)
imshow(rgbImage(:,:,:),'Parent',app.UIAxes_2);
end