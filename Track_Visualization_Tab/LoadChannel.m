function LoadChannel(app)
% Function to select and import a 2nd channel image to app.save_session. 
% Jessica Angulo 10.01.2022
%% Path of the 2nd channel image sequence (TIFF)
v = string(app.showing_video);
p_file = app.save_session.(v).path;
[name,path] = uigetfile(p_file{1,2},'*.*');
path = string(path) + string(name); %final string with the path
app.save_session.(v).Ch2path = path;
figure(app.UIFigure) % avoids UI to end up in background
%% Image import as a matrix
warning('off','all')
ImageDataStore = datastore(path,'ReadFcn',@imfinfo);
file = readall(ImageDataStore);
image_w = file{1,1}.Width;
image_h = file{1,1}.Height;
image_n=length(file{1,1});
BitDepth = file{1,1}.BitDepth;
if BitDepth == 8
    image=zeros(image_h,image_w,image_n,'uint8');
elseif BitDepth == 16
    image=zeros(image_h,image_w,image_n,'uint16');
else
    image=zeros(image_h,image_w,image_n,'double');
end
tstack  = Tiff(path,'r'); % read tiff file from pathway
image(:,:,1)  = tstack.read(); % creates empty matrix with the image properties
if app.preview_bar.CancelRequested
    app.save_session.(v) = rmfield(app.save_session.(v),'Ch2path');
    return
end
%load rest of frames
if image_n < size(app.Loaded_files.video_file{1,3},3) & image_n ~= 1
    ch2_rate = round(size(app.Loaded_files.video_file{1,3},3)/image_n);
    count = 1;
    for n = 1:image_n
        for k = 1:ch2_rate
            image(:,:,count) = tstack.read();
            count = count + 1;
        end
        if n ~= image_n
            tstack.nextDirectory()
        end
    end
else
    for n = 2:image_n %loads every frame into the image object
        tstack.nextDirectory()
        image(:,:,n) = tstack.read();
        app.preview_bar.Value = app.preview_bar.Value + (0.3*(1/(image_n-1)));
        if app.preview_bar.CancelRequested
            return
        end
    end
    warning('on','all')
    if app.preview_bar.CancelRequested
        app.save_session.(v) = rmfield(app.save_session.(v),'Ch2path');
        return
    end
end
%% Saving the imported channel 2 file
image = uint8(image/256); %compresses the image to 8 bit
if image_n == 1
    rep = size(app.Loaded_files.video_file{1,3},3);
    image = repmat(image,[1,1,rep]);
    app.save_session.(v).Channel2Type = 1;
elseif image_n < size(app.Loaded_files.video_file{1,3},3)
    app.save_session.(v).Time_lapse = 1;
    app.save_session.(v).Frequency = size(app.Loaded_files.video_file{1,3},3)/image_n;
    app.save_session.(v).Non_imaged_frame = 0;
    app.save_session.(v).Channel2Type = 0; %channel 2 is not a single image
else
    app.save_session.(v).Channel2Type = 0;
end
app.Loaded_files.Channel2 = image;
%Loading bar
if app.preview_bar.CancelRequested
    app.Loaded_files = rmfield(app.Loaded_files,'Channel2');
    app.save_session.(v) = rmfield(app.save_session.(v),'Channel2Type');
    app.save_session.(v) = rmfield(app.save_session.(v),'Ch2path');
    return
end
%% Save original loaded files in disk
dir = what('temp');
filename = string(dir.path) + "\" + v + ".mat";
var1 = app.Loaded_files; %re-save the variable after new data was loaded
save(filename,'var1','-v7.3')
clear var1
end