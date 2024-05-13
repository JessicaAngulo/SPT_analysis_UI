function [SNRspots, intPeak] = calc_snr(spots, originalIm, spotRadius)
% CALC_SNR calculates the signal-to-noise ratio (SNR) of single-molecule detections
%
% Input: 
%   spots       -   2d-array containing the xy-coordinates of spots. x-coordinates 
%                   (horizontal direction) in first row and y-coordinates (vertical direction) in seconds row.
%   originalIm  -   Grayscale image where the SNR is calculated on
%   spotRadius  -   Radius in which the original image pixel values are set to zero around the spot positions to calculate the background noise
%
% Output:
%   SNRspots    -   list of SNRs
%   intPeak     -   list containing the maximum pixel value in a window of 17x17 pixels around
%                   the spot position
%
% Full function taken from the Trackit app and eddited by Jessica Angulo on
% the 23.10.2023
% Copyright (C) 2020 Timo Kuhn, Johannes Hettich and J. Christof M. Gebhardt
% timo.kuhn@uni-ulm.de, johannes.hettich@uni-ulm.de, christof.gebhardt@uni-ulm.de
% https://gitlab.com/GebhardtLab/TrackIt
% Publication:
% Timo Kuhn, Johannes Hettich, Rubina Davtyan, J. Christof M. Gebhardt
% Single molecule tracking and analysis framework including theory-predicted parameter settings
% Scientific Reports 11, 9465 (2021). doi: https://doi.org/10.1038/s41598-021-88802-7
%Half size of the window which is cut out of the original image where the SNR is be calculated
halfWindowSize = 8;

%Convert original image to double
originalIm = double(originalIm);

%Get number of spots
nSpots = size(spots,1);

%Get image dimensions
imageSize = size(originalIm);

[columnsInImage, rowsInImage] = meshgrid(1:imageSize(2), 1:imageSize(1));

%Create an image mask containing the spot positions plus a disc around each
%spot position with the radius defined by spotRadius
spotMask = false(imageSize);

%Iterate through all spots
parfor spotIdx = 1:nSpots
    if ~isnan(spots(spotIdx, 1))
        curSpotY = round(spots(spotIdx, 2));
        curSpotX = round(spots(spotIdx, 1));
        spotMask =  spotMask | (rowsInImage - curSpotY).^2 ...
            + (columnsInImage - curSpotX).^2 <= spotRadius.^2;  %1 where spots
    end
end

%Create image containing only background by setting all values in a radius
%around each spot position to 0.
bgMask = spotMask == 0;
bgIm = originalIm.*bgMask;

%Initialize array of peak intensities and SNRs
intPeak = zeros(1,nSpots);
SNRspots = zeros(1,nSpots);

%Iterate through all spots
parfor spotIdx = 1:nSpots
    if ~isnan(spots(spotIdx, 1))
        %Get coordinates of current spot
        curSpotY        = round(spots(spotIdx, 2));
        curSpotX        = round(spots(spotIdx, 1));
        
        %Get the boundaries of the window where the SNR is calculated
        xMin            = max(curSpotX - halfWindowSize, 1);
        xMax            = min(curSpotX + halfWindowSize, size(originalIm, 2));
        yMin            = max(curSpotY - halfWindowSize, 1);
        yMax            = min(curSpotY + halfWindowSize, size(originalIm, 1));
        
        %Get background image of current spot
        curSpotBgIm     = bgIm(yMin:yMax, xMin:xMax);
        
        %Define a radius around the spot position in which the pixels are
        %considered for getting the maximum and mean intensity of the spot
        spotRadius = 1;
        
        %Create a spot mask for cutting the spot out of the original image
        [columnsInSpotImage, rowsInSpotImage] = meshgrid(1:xMax-xMin+1, 1:yMax-yMin+1);
        spotMask =  (rowsInSpotImage - (yMax-yMin)/2-1).^2 ...
            + (columnsInSpotImage - (xMax-xMin)/2-1).^2 <= spotRadius.^2;
        
        %Cut out small image from the original image where only pixels inside a
        %radius around the spot position are nonzero
        curSpotIm = spotMask.*originalIm(yMin:yMax, xMin:xMax);
            
        %Get pixel values of background image
        bgPixelValues       = curSpotBgIm(curSpotBgIm~=0);
        
        %Get mean background intensity
        meanBgI             = mean(bgPixelValues);
        
        %Get standard deviation of background 
        stdBg               = std(bgPixelValues);
        
        %Get values of the pixels around the spot position
        spotPixelValues     = curSpotIm(curSpotIm ~= 0);  
        
        %Calculate mean intensity of the pixels around the spot position
        meanSpotI           = mean(spotPixelValues);
        
        %Get the pixel with the highest intensity
        intPeak(spotIdx)    = max(spotPixelValues);
        
        %Calculate the SNR
        SNRspots(spotIdx)   = round((meanSpotI - meanBgI)/stdBg,2);
        
        if SNRspots(spotIdx) == Inf
            SNRspots(spotIdx) = NaN;
        end
    else
        SNRspots(spotIdx) = NaN;
        intPeak(spotIdx) = NaN;
    end
end
end








