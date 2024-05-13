function LoadPrevious(app,v)
%% LOADPREVIOUS: Code to reload a video that was previously previewed
% and filtered, preserving those changes. 
% Jessica Angulo, 20.05.2020
%% Data and video import
app.video_file = app.Loaded_files.video_file;
%% Video display into the app.UIAxes
imshow(app.video_file{1,3}(:,:,1),'Parent',app.UIAxes);%loads the first frame
%into the UIAxes
% Contrast adjust
app.c_ax.XLim = app.save_session.(v).Contrast; %limits of the contrast 2 knob slider
app.c_l.Position(:,2) = [0;0]; %y position of the knobs
app.c_l.Position(:,1) = app.save_session.(v).Contrast;%x position of the knobs
app.c_ax.XTick = app.c_ax.XLim ; %ticks on the slider
caxis(app.UIAxes,[app.save_session.(v).Contrast]); %change contrast of the UIAxes
%% AppUIAxes Children: In order to load quicker in each frame, I create
%all the children now as empty objects of a certain type. Then, lMoving can
%just symply change the data of each plot. 
hold(app.UIAxes,'on')
% Scatter (localizations)
scatter([],[],'Marker',...
    '.','MarkerEdgeColor','r','Parent',app.UIAxes);
% Track IDs
max_text = app.save_session.(v).max_text; %max number of tracks per frame
for i = 1:max_text
    text(100,100,'a','Color','r','Parent',app.UIAxes,'Visible','off');
end
% Trajectories
for i = 1:max_text
    plot(nan(1,length(app.video_file{1,2})),nan(1,length(app.video_file{1,2})),...
        'Parent',app.UIAxes,'Visible','off','LineWidth',1);
end
% Bright field image
if isfield(app.Loaded_files,'BrightField') == 1 %if the BF info exists
    imshow(app.Loaded_files.BrightField(:,:),[],'Parent',app.UIAxes);%we create it
    chAxes = get(app.UIAxes,'Children');
    set(app.UIAxes,'Children',[chAxes(2:end);chAxes(1)]); %send BF image
    %to background (last position of children list)
end
% ROI polygon
if isfield(app.save_session.(v),'ROI') == 1 %if the ROI info exists
    my_vertices = app.save_session.(v).ROI;
    drawpolygon(app.UIAxes,'FaceAlpha',0,'Deletable',0,...
        'InteractionsAllowed','none','Position',my_vertices);
    chAxes = get(app.UIAxes,'Children');
    if isfield(app.Loaded_files,'BrightField') == 0
        set(app.UIAxes,'Children',[chAxes(2:end);chAxes(1)]); %we send
        %the polygon to the end of the children list
    else %if BF is the last children
        set(app.UIAxes,'Children',[chAxes(2:end-1);chAxes(1);chAxes(end)]);
        %we place it righ before the BF image
    end
end
hold(app.UIAxes,'off')
