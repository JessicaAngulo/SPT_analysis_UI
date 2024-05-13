function lMoving(app)
% Function to display the video on the UI axes. It allows to choose between
% different display options.
% Jessica Angulo 08.04.2021

%% Rounding of the frame number
app.l.Position(1,1) = round(app.l.Position(1,1));
app.FrameEditField.Value = app.l.Position(1,1); %syncronization with
%the frame edit field
f = app.l.Position(1,1); % define frame number
%% Visibility control
for i = 1:length(app.UIAxes.Children)
    app.UIAxes.Children(i,1).Visible = 'off'; %everything off
end
%%  Frame display
v = string(app.showing_video);
if app.Channel2MaskCheckBox.Value == 1
    image = app.video_file{1,6}(:,:,:,f);
    app.UIAxes.CLim(1,1) = 0;
    app.UIAxes.CLim(1,2) = 255;
else
    image = app.video_file{1,3}(:,:,f);
    app.UIAxes.CLim(1,1) = app.c_l.Position(1,1);
    app.UIAxes.CLim(1,2) = app.c_l.Position(2,1);
end
% Child edit
idx =(app.save_session.(v).max_text)*2;
app.UIAxes.Children(idx+2,1).CData = image;
app.UIAxes.Children(idx+2,1).Visible = 'on';
app.c_l.Visible = 'on';
%caxis(app.UIAxes,[app.save_session.(v).Contrast]);
%% Localization display options
% General variables which are needed
tracks_frame_x = app.video_file{1,4}(:,f);
where_tracks = ~isnan(tracks_frame_x); %logical with 1 if value is not a NaN
[IDs,~] = find(where_tracks==1); %list of track IDs(+1) in that frame
% Bright Field image
if app.BrightFieldImageCheckBox.Value == 1
    if isfield(app.Loaded_files,'BrightField') == 1
        app.UIAxes.Children(end,1).Visible = 'on';
        app.UIAxes.Children(idx+2,1).Visible = 'off';
        caxis(app.UIAxes,'auto');
        app.c_l.Visible = 'off';
    end
end
% Scatter plot
if app.LocalizationsCheckBox.Value == 1
    app.UIAxes.Children(idx+1,1).XData = app.video_file{1,4}(:,f);
    app.UIAxes.Children(idx+1,1).YData = app.video_file{1,5}(:,f);
    app.UIAxes.Children(idx+1,1).Visible = 'on';
end
% Track ID plot
max_text = app.save_session.(v).max_text;
if app.IDnumberCheckBox.Value == 1
    for i = 1:length(IDs) %children position
        j = IDs(i,1); %track ID indx
        app.UIAxes.Children(max_text+i,1).Position(1,1)=...
            app.video_file{1,4}(j,f)+3;
        app.UIAxes.Children(max_text+i,1).Position(1,2)=...
            app.video_file{1,5}(j,f)+3;
        j_1 = j-1; %ID number (starts from 0)
        app.UIAxes.Children(max_text+i,1).String = string(j_1);
        app.UIAxes.Children(max_text+i,1).Visible = 'on';
    end
end
% Trajectory plot
if app.TrajectoriesCheckBox.Value == 1
    for i = 1:length(IDs) %children position
        j = IDs(i,1); %track ID indx
        app.UIAxes.Children(i,1).XData=...
            (app.video_file{1,4}(j,1:f))';
        app.UIAxes.Children(i,1).YData=...
            (app.video_file{1,5}(j,1:f))';
        app.UIAxes.Children(i,1).Visible = 'on';
    end
end
% ROI polygon
if app.FilterbyROICheckBox.Value == 1
    if isfield(app.save_session.(v),'ROI') == 1
        app.UIAxes.Children(idx+3,1).Visible = 'on';
    end
end
hold(app.UIAxes,'off')