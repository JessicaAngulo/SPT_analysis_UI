function LoadForAnalysis(app)
%LOADFORANALYSIS It makes sure all the videos are properly loaded for
%the analysis. 
%   07.06.2021 Jessica Angulo Capel
video = fieldnames(app.save_session);
for i = 1:numel(video)
    v = video{i};
    %Loading bar Cancel check point
    if app.preview_bar.CancelRequested
        return
    end
    if app.save_session.(v).Previewed == 0
        %% Data and video import
        app.Loaded_files = [];
        if app.save_session.(v).Source == 1
            [~] = LoadTrackmateData(app,v);
        elseif app.save_session.(v).Source == 2
            [~] = LoadTrackitData(app,v);
        end
        if app.preview_bar.CancelRequested
            return
        end
        app.save_session.(v).Previewed = 1;
        %Save original loaded files in disk
        dir = what('temp');
        filename = string(dir.path) + "\" + v + ".mat";
        var1 = app.Loaded_files; %re-save the variable after new data was loaded
        save(filename,'var1','-v7.3')
        clear var1
        [r,c] = size(app.Loaded_files.video_file{1,4});
        app.save_session.(v).FilteredTracks.Filter = ones(r,c);
    end
    app.preview_bar.Value = app.preview_bar.Value + 0.9*(1/numel(v));
    %Loading bar Cancel check point
    if app.preview_bar.CancelRequested
        for j = 1:numel(v)
            app.save_session.(v{j}).Previewed = 0;
            return
        end
    end
end
for i = 1:numel(video)
    v = video{i};
    app.save_session.(v).FilteredTracks.Filter_by_length = 0;
    app.save_session.(v).FilteredTracks.Filter_by_ROI = 0;
    app.save_session.(v).FilteredTracks.Filter_by_immobile = 0;
    app.save_session.(v).FilteredTracks.Filter_by_mobile = 0;
    app.save_session.(v).FilteredTracks.First_frame = 0;
end
app.preview_bar.Value = 0.9;
end