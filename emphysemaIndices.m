function [huValues, voxelPerDensity, volumePerDensity, massPerDensity] = ...
    emphysemaIndices(lungImage, lungMask, voxelVolume, handles)
    
    roiAir = -1000;
    roiTissue = 50;
    
    lungImage(lungMask == 0) = [];
    
    lung = int16(lungImage);

    huValues = double(unique(lung));   
    voxelPerDensity = zeros(1, length(huValues));
    counter = 1;    
    for i = 1:length(huValues)
        hu = huValues(i);
        nVoxels = length(lung(lung == hu));
        voxelPerDensity(counter) = nVoxels;
        lung(lung == hu) = [];
        counter = counter + 1;
    end
    
    if strcmp(handles.rescaleSettings.rescaleOption, 'roi')
        massPerDensity = calculateMassPerDensityWithRoi(huValues, voxelPerDensity, voxelVolume);
    else
         massPerDensity = calculateMassPerDensity(huValues, voxelPerDensity, voxelVolume);
    end
    volumePerDensity = voxelPerDensity * voxelVolume;
end

function massPerDensity = calculateMassPerDensityWithRoi(huValues, voxelPerDensity, voxelVolume)
    massPerDensity = zeros(size(voxelPerDensity));
    idx_1000 = huValues < -1000;
    idx_50 = huValues > 50;
    n_idx = ~idx_50 & ~idx_1000;
    
    roiAir = -1000;
    roiAorta = 50;
    
    massPerDensity(idx_1000) = 0;
    massPerDensity(idx_50) = voxelPerDensity(idx_50) * voxelVolume * 1.04;
    massPerDensity(n_idx) = ((huValues(n_idx) - roiAir) / (roiAorta - roiAir))...
        * voxelVolume * 1.04 .*voxelPerDensity(n_idx);
end

function massPerDensity = calculateMassPerDensity(huValues, voxelPerDensity, voxelVolume)
    massPerDensity = (1 - (huValues / -1000)) .* voxelPerDensity * voxelVolume;
    massPerDensity(huValues < -1000) = 0;
end