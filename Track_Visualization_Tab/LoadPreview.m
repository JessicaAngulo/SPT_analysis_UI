function [video_file] = LoadPreview(app)
%% LOAD PREVIEW: Code to load the data (track file and
% video file) of the sample to be previewed in the GUI 
%(Track Visualization Tab). It preprocesses the data 
% for visualization. 
% Jessica Angulo, 28.12.2020
%% Data and video import
v = string(app.showing_video);
if app.save_session.(v).Source == 1
    [video_file] = LoadTrackmateData(app,v);
elseif app.save_session.(v).Source == 2
    [video_file] = LoadTrackitData(app,v);
end
if exist('video_file') == 0
    return
end
[r,c] = size(video_file{1,5});
app.save_session.(v).FilteredTracks.Filter = ones(r,1);
%% Video display into the app.UIAxes
imshow(video_file{1,3}(:,:,1),'Parent',app.UIAxes);%loads the first frame
%into the UIAxes
bit = (2^8)-1;
app.save_session.(v).Contrast = [0 bit]; % default contrast
app.c_ax.XLim = [0 bit]; %limits of the contrast 2 knob slider
app.c_l.Position(:,2) = [0;0]; %y position of the knobs
app.c_l.Position(:,1) = [0;bit];%x position of the knobs
app.c_ax.XTick = app.c_ax.XLim ; %ticks on the slider
caxis(app.UIAxes,[app.save_session.(v).Contrast]); %change contrast of the UIAxes

%% AppUIAxes Children: In order to load quicker in each frame, we create
%all the children now as empty objects of a certain type. Then, lMoving can
%just symply change the data of each plot. 
hold(app.UIAxes,'on')
% Scatter (localizations)
scatter([],[],'Marker',...
    '.','MarkerEdgeColor','r','Parent',app.UIAxes);
% Track IDs
max_text = app.save_session.(v).max_text;
for i = 1:max_text
    text(100,100,'a','Color','r','Parent',app.UIAxes,'Visible','off');
end
% Trajectories
for i = 1:max_text
    plot(nan(1,length(video_file{1,2})),nan(1,length(video_file{1,2})),...
        'Parent',app.UIAxes,'Visible','off','LineWidth',1);
end
hold(app.UIAxes,'off')
app.preview_bar.Value = 1;