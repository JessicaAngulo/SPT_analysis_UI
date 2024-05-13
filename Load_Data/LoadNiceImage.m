function [ch1] = LoadNiceImage(app,v,set)
%LOADNICEIMAGE loads the tiff video file in a similar manner as 
% LoadTRACKitData and LoadTrackmateData, but it keeps the initial uint
% format and doesn't apply any contrast enhancement. 
%   17.10.2023 Jessica Angulo Capel
p_file = app.save_session.(v).path;
%% Video Import and Processing
% The following lines import the image from the given path
videoDataStore = datastore(p_file{1,2},'ReadFcn',@imfinfo);
video_file = readall(videoDataStore);
[image,image_n] = LoadTiffFast(video_file);
% Processing for 2 chanel tif files
if app.save_session.(v).Time_lapse == 1
    ch2_rate = app.save_session.(v).Frequency;
    %Selecting the frames of ch1
    list = 1:((ch2_rate)*2+2):image_n;
    if list(1,end) + ((ch2_rate)*2+2) ~= image_n %if there are missing frames
        image_n = list(1,end); %eliminate last set of frames
        list = list(1:end-1);
    end
    count = 0;
    for j = list
        for k = 2:2:(ch2_rate)*2
            count = count + 1;
            ch1(:,:,count) = image(:,:,j+k);
        end
    end
    ch1(:,:,count+1) = image(:,:,j+1); %blank frame in the end
else
    ch1 = image;
end
end