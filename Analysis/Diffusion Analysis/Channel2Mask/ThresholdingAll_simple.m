function ThresholdingAll_simple(app,R_filtering)
%THRESHOLDING creates a binary image of the whole stack and 
%   11.01.2022 Jessica Angulo
%% Selection
v = app.videoname.Value;
th = (app.th_l.Position(:,1))';
%% Binary image
image_G = app.Analysis.Channel2Mask.By_video.(v).Ch2Image_Gaus(:,:,:); %gaussian filter applied
[h,w,f] = size(image_G);
if R_filtering == 1
    if isfield(app.save_session.(v),'ROI') == 1
        vertices = cell(1,1);
        vertices{1,1} = app.save_session.(v).ROI;
        binary_roi = poly2label(vertices,1,[h,w]);
        binary_roi = repmat(binary_roi,1,1,f);
        binary_roi = logical(binary_roi);
        image_G(binary_roi==0) = 0;
    end
end
binary = image_G >= th(1,1) & image_G <= th(1,2);
image1 = app.Loaded_files.Ch2Image; %contrast adjusted, 8 bit
image1(binary == 0) = 0;
%% Find boundaries
% Common parameters
boundaries = struct;
% Analysis itself
if app.save_session.(v).Channel2Type == 1 %one single mask image
    boundaries = cell(0,0);
    image1 = image1(:,:,1);
    binary = binary(:,:,1);
    boundary = bwboundaries(binary(:,:),'noholes');
    if ~isempty(boundary) == 1
        for k = 1:length(boundary)
            if length(boundary{k,1})>3
                boundaries = [boundaries;boundary{k,1}];
            end
        end
        n_roi = size(boundaries,1);
        L = poly2label(boundaries(:,:),[1:n_roi],[w,h]);
        I2 = labeloverlay(image1(:,:),L','Colormap','hsv');
    else
        return
    end
else %for time-lapsed 2nd channel acquisition
    ch2_rate = app.save_session.(v).Frequency;
    app.fig = uifigure;
    app.preview_bar = uiprogressdlg(app.fig,'Title','Processing the video','Cancelable','off');
    drawnow
    list = 1:(ch2_rate+1):f;
    if list(1,end)+(ch2_rate+1) > f
        n = length(list)-1;
    else 
        n = length(list);
    end
    for i = list(1,1:n)
        boundaries.("f"+i) = cell(0,0);
        boundary = bwboundaries(binary(:,:,i),'noholes');
        if ~isempty(boundary) == 1
            [size_boundaries,~] = cellfun(@size,boundary,'UniformOutput',false);
            for j = 1:length(size_boundaries)
                if size_boundaries{j,1}>3
                    boundaries.("f"+i) = [boundaries.("f"+i);boundary{j,1}];
                end
            end
            n_roi = size(boundaries.("f"+i),1);
            L_i = poly2label(boundaries.("f"+i),[1:n_roi],[w,h]);
            I2_i = labeloverlay(image1(:,:,i),L_i','Colormap','hsv');
            if i == list(1,1)
                L = L_i;
                I2 = I2_i;
            else
                L = cat(3,L,L_i);
                I2 = cat(4,I2,I2_i);
            end
        else
            close(app.fig);
            return
        end
        app.preview_bar.Value = i/f;
    end
    close(app.fig);
end
%% Save Data
if ~isempty(boundary) == 1
    app.Analysis.Channel2Mask.By_video.(v).IntensityThreshold = th;
    app.Analysis.Channel2Mask.By_video.(v).Label_matrix = L;
    app.Analysis.Channel2Mask.By_video.(v).Overlay = I2;
    app.Analysis.Channel2Mask.By_video.(v).Boundaries = boundaries;
else
    return
end
% close(app.fig);