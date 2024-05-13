R_filtering = app.EnablefilteringbyROICheckBox_2.Value;
L_filtering = app.FilterbytracklengthCheckBox_2.Value;
Imm_filtering = app.ExcludeimmobilefractionCheckBox_2.Value;
Mob_filtering = app.ExcludemobilefractionCheckBox_2.Value;
First_filtering = app.OnlyspotsfromthefirstframeCheckBox_2.Value;
length_list = [];
n_traj = [];
video = fieldnames(app.save_session);
for i = 1:numel(video)
    v = video{i};
    %Load from disk
    dir = what('temp');
    filename = string(dir.path) + "\" + v + ".mat";
    load(filename);
    app.Loaded_files = var1;
    clear var1
    %Filtering
    if L_filtering == 1
        min_frame = app.save_session.(v).FilteredTracks.min_frame;
    else
        min_frame = 0;
    end
    if Imm_filtering == 1
        D_imm = app.save_session.(v).FilteredTracks.D_imm;
    else
        D_imm = NaN;
    end
    if Mob_filtering == 1
        D_mob = app.save_session.(v).FilteredTracks.D_mob;
    else
        D_mob = NaN;
    end
    FilterTracks(app,v,R_filtering,L_filtering,min_frame,...
    Imm_filtering,D_imm,Mob_filtering,D_mob,First_filtering);
    [r,~] = size(app.Loaded_files.video_file{1,4});
    log = ~isnan(app.Loaded_files.video_file{1,4}(:,:));
    l = sum(log,2,'omitnan'); %length of each traj in frames
    length_list = [length_list;l];
    m_l = mean(l);
    app.save_session.(v).traj_length = l;
    app.save_session.(v).mean_traj_length = m_l;
    n = length(l);
    n_traj = [n_traj;n];
end