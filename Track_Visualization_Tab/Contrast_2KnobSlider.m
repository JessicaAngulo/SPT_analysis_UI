function Contrast_2KnobSlider(app)
% Function to change the contrast of the displayed image. 
% Jessica Angulo 09.04.2021
app.c_l.Position(1,1) = round(app.c_l.Position(1,1));
app.c_l.Position(2,1) = round(app.c_l.Position(2,1));
v = string(app.showing_video);
%% Saving the changed value
app.save_session.(v).Contrast(1,1) = app.c_l.Position(1,1);
app.save_session.(v).Contrast(1,2) = app.c_l.Position(2,1);
%% Changing the contrast on app.UIAxes
app.UIAxes.CLim(1,1) = app.c_l.Position(1,1);
app.UIAxes.CLim(1,2) = app.c_l.Position(2,1);