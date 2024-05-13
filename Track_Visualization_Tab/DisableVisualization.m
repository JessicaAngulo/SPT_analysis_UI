function DisableVisualization(app)
%DISABLEVISUALIZATION disables the visualization option in order to avoid
%missmaches of the Loaded_files when analyzing. 
%   23.09.2022 Jessica Angulo Capel
%% Display properties
app.FrameEditFieldLabel.Enable = 'off';
app.FrameEditField.Enable = 'off'; %disables the frame edit field 
app.Contrast2ndChannelLabel.Enable = 'off';
app.AdjustcontrastrangeButton.Enable = 'off';
app.ResetcontrastButton.Enable = 'off';
app.ax.Toolbar.Visible = 'off'; %contrast 2 knob slider
app.l.Visible = 'off';
app.c_ax.Toolbar.Visible = 'off'; %contrast 2 knob slider
app.c_l.Visible = 'off';
app.DisplayedvideoTextArea.Enable = 'off';
%% Channel 2 mask
app.c2_ax.Toolbar.Visible = 'off'; %contrast 2 knob slider
app.c2_l.Visible = 'off';
%% Disabling of the different display options
app.IDnumberCheckBox.Enable = 'off';
app.LocalizationsCheckBox.Enable = 'off';
app.TrajectoriesCheckBox.Enable = 'off';
app.BrightFieldImageCheckBox.Enable = 'off';
app.BrightFieldImageCheckBox.Value = 0;
app.Channel2MaskCheckBox.Enable = 'off';
app.Channel2MaskCheckBox.Value = 0;
%% Disabling the filtering
app.FilterbyROICheckBox.Enable = 'off';
app.FilterbytracklengthCheckBox.Enable = 'off';
app.OnlyspotsfromthefirstframeCheckBox.Enable = 'off';
v = string(app.showing_video);
app.FilterbyROICheckBox.Value = 0;
app.SelectROIButton.Enable = 'off';
app.EraseROIButton.Enable = 'off';
app.ExcludemobilefractionCheckBox.Enable = 'off';
app.ExcludeimmobilefractionCheckBox.Enable = 'off';
end