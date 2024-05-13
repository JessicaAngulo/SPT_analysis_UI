function Contrast_ch2_2KnobSlider(app)
% Function to change the contrast of the displayed image. 
% Jessica Angulo 14.12.2021
%% Creating the loading bar (preview_bar)
app.fig = uifigure;
app.preview_bar = uiprogressdlg(app.fig,'Title','Changing contrast of the 2nd Channel','Cancelable','on');
drawnow
%% Saving the contrast value
app.c2_l.Position(1,1) = round(app.c2_l.Position(1,1));
app.c2_l.Position(2,1) = round(app.c2_l.Position(2,1));
v = string(app.showing_video);
old_contrast1 = app.save_session.(v).Contrast_ch2(1,1);
old_contrast2 = app.save_session.(v).Contrast_ch2(1,2);
app.save_session.(v).Contrast_ch2(1,1) = app.c2_l.Position(1,1);
app.save_session.(v).Contrast_ch2(1,2) = app.c2_l.Position(2,1);
app.preview_bar.Value = 0.1;
%% Creating the composite again
ReloadComposite(app);
if app.preview_bar.CancelRequested
    app.c2_l.Position(1,1) = old_contrast1;
    app.c2_l.Position(2,1) = old_contrast2;
    app.save_session.(v).Contrast_ch2(1,1) = old_contrast1;
    app.save_session.(v).Contrast_ch2(1,2) = old_contrast2;
    close(app.fig);
    return
end
app.preview_bar.Value = 0.9;
lMoving(app);
app.preview_bar.Value = 1;
close(app.fig);
end