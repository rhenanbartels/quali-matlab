function imageCoreInfo =  openDicoms(imagePath)
    folderElements = dir([imagePath filesep '*.dcm']);
    
    % If .dcm files were found
    if ~isempty(folderElements)
        [dicomFileNames, dicomMetadata] = getDicomFileNames(imagePath,...
            folderElements);
    else
    % Maybe dicom files don't have .dcm extension.
        [dicomFileNames, dicomMetadata] = discoverDicomFileNames(imagePath);
    end
    
    rawImageMatrix = getDicomImages(dicomFileNames, dicomMetadata);
    
    [sortedDicomMetadata, sortedImageMatrix, sortedIndexes] = ...
        sortSlices(dicomMetadata, rawImageMatrix);
    
    imageCoreInfo.fileNames = dicomFileNames;
    imageCoreInfo.metadata = sortedDicomMetadata;
    imageCoreInfo.matrix = sortedImageMatrix;
    imageCoreInfo.sortedIndexes = sortedIndexes;
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
    
    for index = 1:nSlices
        sliceLocations(index) = dicomMetadata{index}.SliceLocation;
    end
    
    [~, sortedIndexes] = sort(sliceLocations);
    sortedDicomMetadata = dicomMetadata(sortedIndexes);
    sortedImageMatrix = rawImageMatrix(:, :, sortedIndexes);
end