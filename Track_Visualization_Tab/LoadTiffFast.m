function [image,image_n] = LoadTiffFast(video_file)
% Code to load all tiff stacks into the cell video_file. 
% Depending on the number of frames and files it can take some time. 
filename = video_file{1,1}.Filename;
stripByteCounts = video_file{1,1}.StripByteCounts;
stripOffset = video_file{1,1}.StripOffsets;
%% The following lines save image properties of this video file and loads
% all frames. 
image_w = video_file{1,1}.Width;  %ImageWidth
image_h = video_file{1,1}.Height;  %ImageLength
if length(video_file{1,1})<2
    image_n = floor(video_file{1,1}.FileSize/stripByteCounts);
else
    image_n = length(video_file{1,1});
end
BitDepth = video_file{1,1}.BitDepth;
fID = fopen (filename, 'r');
if BitDepth == 8
     image=zeros(image_h,image_w,image_n,'uint8');
elseif BitDepth == 16
     image=zeros(image_h,image_w,image_n,'uint16');
else
     image=zeros(image_h,image_w,image_n,'double');
end
% Import all frames
start_point = stripOffset(1) + (0:1:((image_n)-1)).*stripByteCounts + 1;
for i = 1:image_n
    fseek (fID, start_point(i), 'bof');
    if BitDepth==16
        A = fread(fID, [image_w image_h], 'uint16=>uint16');
    elseif BitDepth==8
        A = fread(fID, [image_w image_h], 'uint8=>uint8');
    else
        A = fread(fID, [image_w image_h], 'double=>double');
    end
    try
        image(:,:,i) = A';
    catch
        break
    end
end
end