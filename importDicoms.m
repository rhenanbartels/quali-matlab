function imageCoreInfo =  importDicoms(imagePath)
    folderElements = dir([imagePath filesep '*.dcm']);
    
    % If .dcm files were found
    if ~isempty(folderElements)
        [dicomFileNames, dicomMetadata] = getDicomFileNames(imagePath,...
            folderElements);
    else
    % Maybe dicom files don't have .dcm extension.
        [dicomFileNames, dicomMetadata] = discoverDicomFileNames(imagePath);
    end
    
    imageCoreInfo = [];
    
    % Check if any Dicom was found.
    if ~isempty(dicomFileNames) && ~isempty(dicomMetadata)
        rawImageMatrix = getDicomImages(dicomFileNames, dicomMetadata);
        
        [sortedDicomMetadata, sortedImageMatrix, sortedIndexes] = ...
            sortSlices(dicomMetadata, rawImageMatrix);
        
        %Prepare image
        sortedImageMatrix = scalePixels(dicomMetadata{1},...
            sortedImageMatrix);
        
        imageCoreInfo.fileNames = dicomFileNames;
        imageCoreInfo.metadata = sortedDicomMetadata;
        imageCoreInfo.matrix = sortedImageMatrix;
        imageCoreInfo.sortedIndexes = sortedIndexes;
    end
end

function rawImageMatrix = getDicomImages(dicomFileNames, dicomMetadata)    
    nRows = dicomMetadata{1}.Rows;
    nCols = dicomMetadata{1}.Columns;
    nDicoms = length(dicomFileNames);
    rawImageMatrix = zeros(nRows, nCols, nDicoms);

    for index = 1:nDicoms
        rawImageMatrix(:, :, index) =  dicomread(dicomFileNames{index});
    end
    
end

function [dicomFileNames, dicomMetadata] = getDicomFileNames(imagePath, folderElements)
    nElements = length(folderElements);
    dicomFileNames = cell(1, nElements);
    dicomMetadata = cell(1, nElements);
    for index = 1:nElements
        dicomFileNames{index} = [imagePath filesep...
            folderElements(index).name];
        dicomMetadata{index} = dicominfo([imagePath filesep...
            folderElements(index).name]);
    end
end


function [dicomFileNames, dicomMetadata] = discoverDicomFileNames(...
    imagePath)
    % Try to open every file found in imagePath with dicominfo.
    % If it is possible to read with dicominfo we assume it is
    % a Dicom file.
    folderElements = dir(imagePath);
    nElements = length(folderElements);
    dicomFileNames = cell(1, nElements);
    dicomMetadata = cell(1, nElements);
    
    counter = 1;
    for index = 1:nElements
        if ~folderElements(index).isdir
            try
                fileName = [imagePath filesep folderElements(index).name];
                dicomMetadata{counter} =  dicominfo(fileName);
                dicomFileNames{counter} = fileName;
                counter = counter + 1;
            catch
                continue
            end
        end
    end
    
    % Remove emptie cell
    dicomFileNames = dicomFileNames(~cellfun('isempty', dicomFileNames));
    dicomMetadata = dicomMetadata(~cellfun('isempty', dicomMetadata));
end

function [sortedDicomMetadata, sortedImageMatrix, sortedIndexes] = ...
    sortSlices(dicomMetadata, rawImageMatrix)

    nSlices = size(rawImageMatrix, 3);
    sliceLocations = zeros(1, nSlices);
    
    % Check if metadata have SliceLocation
    if isfield(dicomMetadata{1}, 'SliceLocation')
        for index = 1:nSlices
            sliceLocations(index) = dicomMetadata{index}.SliceLocation;
        end
    else
        sliceLocations = 1:nSlices;
    end
    
    [~, sortedIndexes] = sort(sliceLocations);
    sortedDicomMetadata = dicomMetadata(sortedIndexes);
    sortedImageMatrix = rawImageMatrix(:, :, sortedIndexes);
end

function imageMatrix = scalePixels(metadata, imageMatrix)
    if isfield(metadata, 'RescaleSlope') &&...
            isfield(metadata, 'RescaleIntercept')
        slope = metadata.RescaleSlope;
        intercept = metadata.RescaleIntercept;
        imageMatrix = imageMatrix * slope + intercept;
    end
    imageMatrix = int16(imageMatrix);
end