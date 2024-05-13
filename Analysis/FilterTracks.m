function FilterTracks(app,v,R_filtering,L_filtering,min_frame,...
    Imm_filtering,D_imm,Mob_filtering,D_mob,First_filtering)
%FILTERTRACKS creates a filtering matrix. This matrix will be used to modify
% app.video_file in order to display a filtered video.
% It also saves the IDs of the filtered tracks on app.save_session.
%   14.05.2021 Jessica Angulo Capel
[r,~] = size(app.Loaded_files.video_file{1,4});
filtering_logical = zeros(r,1);
%% Filtering by ROI
if R_filtering == 1
    if isfield(app.save_session.(v),'ROI') == 1 %if the ROI was already drawn
        if isfield(app.save_session.(v).FilteredTracks,'ROI') == 0
            IDs = [];
            log = zeros(r,1);
            %Getting the tracks that need to be erased
            for f = 1:width(app.Loaded_files.video_file{1,4})
                xq = app.Loaded_files.video_file{1,4}(:,f); %x coordinates of all tracks in frame f
                idx_NaN = find(isnan(xq(:,1))); %position of NaN values
                yq = app.Loaded_files.video_file{1,5}(:,f); %y coordinates of all tracks in frame f
                query = [xq,yq];
                vertices = app.save_session.(v).ROI;
                %logical array saying whether the spot falls inside the
                %polygon or not (1 for localizations inside the ROI)
                in = inpolygon(query(:,1),query(:,2),vertices(:,1),vertices(:,2));
                inside = double(in);
                out = ~in;
                out = double(out);
                for i = 1:length(idx_NaN)
                    j = idx_NaN(i,1);
                    inside(j,1) = NaN;
                    out(j,1) = NaN;
                end
                idx = find(inside(:,1)==0);
                idx = idx-1;%position of the tracks that
                %fall outside the polygon
                IDs = [IDs;idx];
                s = [log,out];
                log = sum(s,2,'omitnan'); %0 for tracks that always lay inside
            end
            IDs = unique(IDs); %list of all tracks that at some point
            %fall outside the polygon
            app.save_session.(v).FilteredTracks.Filter_by_ROI = 1;
            app.save_session.(v).FilteredTracks.ROI = IDs; %ROI filtering list
            filtering_logical = filtering_logical + log;
            %0 for tracks that always lay inside
        else
            for n = 1:length(app.save_session.(v).FilteredTracks.ROI)
                track = app.save_session.(v).FilteredTracks.ROI(n,1);
                filtering_logical(track+1,1) = 1;
            end
        end
        app.save_session.(v).FilteredTracks.Filter_by_ROI = 1;
    else
        app.save_session.(v).FilteredTracks.Filter_by_ROI = 0;
    end
else
    app.save_session.(v).FilteredTracks.Filter_by_ROI = 0;
end
%% Filtering by track length
if L_filtering == 1
    if app.save_session.(v).FilteredTracks.Filter_by_length == 0
        app.save_session.(v).FilteredTracks.Filter_by_length = 1;
        length_list = zeros(r,1);
        for i = 1:r
            track_i = app.Loaded_files.video_file{1,4}(i,:);
            l = length(track_i(~isnan(track_i)));
            if l < min_frame
                length_list(i,1) = 1;
            end
        end
        idx = find(length_list(:,1)==1);
        idx = idx-1; %list of short tracks
        app.save_session.(v).FilteredTracks.Short_tracks = idx;
        filtering_logical = filtering_logical + length_list;
        app.save_session.(v).FilteredTracks.min_frame = min_frame;
    else
        for n = 1:length(app.save_session.(v).FilteredTracks.Short_tracks)
            track = app.save_session.(v).FilteredTracks.Short_tracks(n,1);
            filtering_logical(track+1,1) = 1;
        end
    end
else
    app.save_session.(v).FilteredTracks.Filter_by_length = 0;
end
%% Filtering by immobile fraction
if Imm_filtering == 1
    app.save_session.(v).FilteredTracks.Filter_by_immobile = 1;
    Dif_list = app.Analysis.Dif_analysis.By_video.(v).ImDif;
    list = Dif_list < D_imm; %1 for values < D_imm
    %% Get list of tracks to be filtered
    filtering_logical = filtering_logical + list;
else
    app.save_session.(v).FilteredTracks.Filter_by_immobile = 0;
end
%% Filtering by mobile fraction
if Mob_filtering == 1
    app.save_session.(v).FilteredTracks.Filter_by_mobile = 1;
    %% Get logical with tracks to be erased as 1
    Dif_list = app.Analysis.Dif_analysis.By_video.(v).ImDif;
    list = Dif_list > D_mob; %1 for values > D_mob
    %% Get list of tracks to be filtered
    filtering_logical = filtering_logical + list;
else
    app.save_session.(v).FilteredTracks.Filter_by_mobile = 0;
end
%% Filtering by first frame
if First_filtering == 1
    app.save_session.(v).FilteredTracks.First_frame = 1;
    list = double(isnan(app.Loaded_files.video_file{1,4}(:,1)));
    filtering_logical = filtering_logical + list;
else
    app.save_session.(v).FilteredTracks.First_frame = 0;
end
%% General filtering of the video
%Tracks that manage to keep a 0 in the filtering_logical are the ones we
%still want to show
filtering_logical(filtering_logical~=0)=1; %covert it into a proper logical
filtering_logical = ~filtering_logical; %1 for tracks that need to be kept
app.save_session.(v).FilteredTracks.Filter = filtering_logical; 
end
