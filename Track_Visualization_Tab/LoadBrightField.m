function LoadBrightField(app)
% Function to select and import a bright field image to app.Loaded_files. 
% Jessica Angulo 08.04.2021
%% Path of the bright field image
v = string(app.showing_video);
p_file = app.save_session.(v).path;
[bf_name,bf_path] = uigetfile(p_file{1,2},'*.*'); 
bf_path = string(bf_path) + string(bf_name); %final string with the path
%% Image import as a matrix
warning('off','all') % Suppress all the tiff warnings
ImageDataStore = datastore(bf_path,'ReadFcn',@imfinfo);
bf_file = readall(ImageDataStore);
% The following lines save image properties of this video file
image_w = bf_file{1,1}.Width;
image_h = bf_file{1,1}.Height;
image_n=length(bf_file{1,1});
BitDepth = bf_file{1,1}.BitDepth;
% The following creates an empty matrix with the previous image properties
if BitDepth == 8
    image=zeros(image_h,image_w,image_n,'uint8');
elseif BitDepth == 16
    image=zeros(image_h,image_w,image_n,'uint16');
else
    image=zeros(image_h,image_w,image_n,'double');
end
% Read tiff file from pathway
tim  = Tiff(bf_file{1,1}.Filename,'r'); 
% Loading into the image object
image(:,:) = read(tim);
warning('on','all')
%% Saving into app.Loaded_files
v = "video_" + strrep(string(app.VideoSelectionListBox.Value),"-","_");
app.Loaded_files.BrightField = image(:,:);
%% Save original loaded files in disk
dir = what('temp');
filename = string(dir.path) + "\" + v + ".mat";
var1 = app.Loaded_files; %re-save the variable after new data was loaded
save(filename,'var1','-v7.3')
clear var1
end
