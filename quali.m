function quali()
    mainInterface = startMainInterface();
end

function mainFig = startMainInterface()
    % Make program full screen
    screenSize = get(0, 'ScreenSize');
    mainInterfaceColor = [0, 0, 0];
    
    mainFig = figure('Position', screenSize,...
        'MenuBar', 'none',...
        'NumberTitle', 'off',...
        'Name', ['Qualitative Analysis of Lung Images - 0.0.0dev0 -'...
                 ' Matlab Version'],...
        'Color', mainInterfaceColor,...
        'Resize', 'Off');
    
  informationAxes = axes('Parent', mainFig,...
      'Units', 'Normalized',...
      'Position', [0, 0.06, 1, 0.85],...
      'Color', [0, 0, 0],...
      'XTickLabel', [],...
      'YTickLabel', [],...
      'Xcolor', [0, 0, 0],...
      'Ycolor', [0, 0, 0],...
      'Tag', 'informationAxes');
  
  imageAxes = axes('Parent', mainFig,...
        'Units', 'Normalized',...
        'Position', [0.15, 0.06, 0.7, 0.85],...
        'Color', [0, 0, 0],...
        'XTickLabel', [],...
        'YTickLabel', [],...
        'Xcolor', [0, 0, 0],...
        'Ycolor', [0, 0, 0],...
        'Tag', 'imageAxes');

    
    startAxesMetadataInfo(informationAxes);
    
    % Upper Panel with all options
    mainPanel = uipanel('Parent', mainFig,...
        'Units', 'Normalized',...
        'Position', [0, 0.915, 1, 0.08],...
        'Title', '',...
        'BackGroundColor', [0.1, 0.1, 0.1]);
    
    uicontrol('Parent', mainPanel,...
        'Units', 'Normalized',...
        'Position', [0.01, 0.2, 0.08, 0.6],...
        'String', 'Import Dicom',...
        'BackGroundColor', [0.1, 0.1, 0.1],...
        'ForeGroundColor', [54/255, 189/255, 1],...
        'FontWeight', 'Bold',...
        'FontSize', 14,...
        'Callback', @importImage);
    %Start data handles
    handles.data = '';
    
    handles.gui = guihandles(mainFig);
    guidata(mainFig, handles);
end

function startAxesMetadataInfo(imageAxes)
    text(imageAxes, 0.5, 0.98,...
        '',...
        'Color', 'White',...
        'HorizontalAlignment', 'center',...
        'FontSize', 14,...
        'Tag', 'patientNameTextObject');
    
    text(imageAxes, 0, 0.01,...
        '',...
        'Color', 'White',...
        'HorizontalAlignment', 'left',...
        'FontSize', 14,...
        'Tag', 'textSliceNumber');
    
        
    text(imageAxes, 0, 0.94,...
        'Image Dimensions: -',...
        'Color', 'White',...
        'HorizontalAlignment', 'left',...
        'FontSize', 14,...
        'Tag', 'textImageDimensions');
    
    text(imageAxes, 0, 0.05,...
        'Pixel Value: -',...
        'Color', 'White',...
        'HorizontalAlignment', 'left',...
        'FontSize', 14,...
        'Tag', 'textPixelValue');

    text(imageAxes, 0, 0.90,...
        'Slice Thickness',...
        'Color', 'White',...
        'HorizontalAlignment', 'left',...
        'FontSize', 14,...
        'Tag', 'textSliceThickness');
    
    text(imageAxes, 0, 0.09,...
        'Space Btw Slices: -',...
        'Color', 'White',...
        'HorizontalAlignment', 'left',...
        'FontSize', 14,...
        'Tag', 'textSpaceBetweenSlices');
    
    text(imageAxes, 0, 0.98,...
        'Slice Location: -',...
        'Color', 'White',...
        'HorizontalAlignment', 'left',...
        'FontSize', 14,...
        'Tag', 'textSliceLocation');
        
    text(imageAxes, 0.9, 0.98,...
        'Window Length: -',...
        'Color', 'White',...
        'HorizontalAlignment', 'left',...
        'FontSize', 14);   
    
    text(imageAxes, 0.9, 0.94,...
        'Window Width: -',...
        'Color', 'White',...
        'HorizontalAlignment', 'left',...
        'FontSize', 14);

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                             CALLBACKS                                
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function importImage(hObject, eventdata)
    % Import Images
    handles = guidata(hObject);
    if isfield(handles.data, 'lastVisitedFolder')
        rootPath = uigetdir(handles.data.lastVisitedFolder,...
            'Select a folder with Dicom images');
    else
        rootPath = uigetdir('.', 'Select a folder with Dicom images');
    end
    
    if ~isempty(rootPath)
        handles.data.lastVisitedFolder = rootPath;
        handles.data.imageCoreInfo = openDicoms(rootPath);
        
        %Show first Slice
        showImageSlice(handles.gui.imageAxes,...
            handles.data.imageCoreInfo.matrix(:, :, 1));
        
        startScreenMetadata(handles,...
            handles.data.imageCoreInfo.metadata{1})
        
    end
    
    guidata(hObject, handles)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                             UTILS                                
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function showImageSlice(axisObject, imageSlice)
    axes(axisObject);
    imagesc(imageSlice);
    colormap(gray)
    set(axisObject, 'XtickLabel', [])
    set(axisObject, 'YtickLabel', [])
    
end

function updateSliceNumberText(textObject, sliceNumber, nSlices)
    set(textObject, 'String', sprintf('%d / %d', sliceNumber, nSlices));
end

function updateSliceLocationText(textObject, sliceLocation)
    set(textObject, 'String', sprintf('Slice Location: %.2f',...
        sliceLocation));
end

function startScreenMetadata(handles, metadata)
    % Show Slice Number
    updateSliceNumberText(handles.gui.textSliceNumber, 1,...
        size(handles.data.imageCoreInfo.matrix, 3))
    
    updateSliceLocationText(handles.gui.textSliceLocation,...
        metadata.SliceLocation)
    
    % Show Image Dimensions
    set(handles.gui.textImageDimensions, 'String',...
        sprintf('Image Dimension: %d x %d', metadata.Rows,...
        metadata.Columns));
    
    if isfield(metadata, 'SpaceBetweenSlices')
        set(handles.gui.textSpaceBetweenSlices, 'String',...
            sprintf('Space Btw Slices: %.2f', metadata.SpaceBetweenSlices));
    end
    
    set(handles.gui.textSliceThickness, 'String',...
        sprintf('Slice Thickness: %.2f', metadata.SliceThickness));
end