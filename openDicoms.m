function openDicoms(imagePath)

    %imagePath = '/Users/lismariecarvalho/Documents/rhenanbartels-qctworkflow-bafdf5ca4826_2/ExampleCT/381111_BAL Kopie';
    imagePath = '/Users/lismariecarvalho/Documents/projects/matlab/qali';
    folderElements = dir([imagePath filesep '*.dcm']);
    
    % If .dcm files were found
    if ~isempty(folderElements)
        dicomFileNames = getDicomFileNames(imagePath, folderElements);
    else
    % Maybe dicom files don't have .dcm extension.
        [dicomFileNames, dicomMetadata] = discoverDicomFileNames(imagePath);
    end
end

function getDicomImages(dicomFileNames)
    nDicoms = length(dicomFileNames);
     = 
    for index = 1:nDicoms
    end
end

function dicomFileNames = getDicomFileNames(imagePath, folderElements)
    nElements = length(folderElements);
    dicomFileNames = cell(1, nElements);
    for index = 1:nElements
        dicomFileNames{index} = [imagePath filesep...
            folderElements(index).name];
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