function Load2chAnalysis(app,v)
%LOAD2CHANALYSIS prepares the analysis of the 2nd channel mask 
%   12.01.2022 Jessica Angulo
if isfield(app.Loaded_files,'Channel2') == 1
    app.Analysis.Channel2Mask.By_video.(v) = struct;
    app.Analysis.Channel2Mask.By_video.(v).ResetButton = 1;
    %% Frame slider
    app.FrameSlider_Ch2.Enable = 'on';
    frames = size(app.Loaded_files.video_file{1,3},3);
    app.FrameSlider_Ch2.Limits = [1 frames];
    app.FrameSlider_Ch2.Value = 1;
    %% Threshold slider
    app.th_ax.Toolbar.Visible = 'on';
    app.th_l.Visible = 'on';
    app.th_l.Position(:,1) = [0;0.4]; % when rounding in Thresholding(app), the imput values will still be 0,0
    %% Adjust contrast of the image
    channel2 = app.Loaded_files.Channel2;
    %channel2 = im2uint8(channel2); %compresses the image to 8 bit
    slope2 = (255 - app.c2_l.Position(1,1))/app.c2_l.Position(2,1);
    channel2 = (channel2*slope2)+app.c2_l.Position(1,1);
    app.Analysis.Channel2Mask.By_video.(v).Contrast = [app.c2_l.Position(1,1),app.c2_l.Position(2,1)];
    app.Loaded_files.Ch2Image = channel2;
    %% Gaussian Blur
    channel2 = imgaussfilt(channel2,1);
    app.Analysis.Channel2Mask.By_video.(v).Ch2Image_Gaus = channel2;
    %Save original loaded files in disk
    dir = what('temp');
    filename = string(dir.path) + "\" + v + ".mat";
    var1 = app.Loaded_files;
    save(filename,'var1','-v7.3')
    clear var1
    %% Show changes in UIaxes2
    Thresholding(app);
    app.AnalyzethisvideoButton.Enable = 'on';
else
    app.FrameSlider_Ch2.Enable = 'off';
    app.th_ax.Toolbar.Visible = 'off';
    app.th_l.Visible = 'off';
    app.AnalyzethisvideoButton.Enable = 'off';
end
end