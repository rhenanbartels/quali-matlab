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
        'Resize', 'Off',...
        'WindowButtonMotionFcn', @mouseMove,...
        'WindowScrollWheelFcn', @refreshSlicePosition);
    
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
        'Position', [0.11, 0.13, 0.78, 0.78],...
        'Color', [0, 0, 0],...
        'XTickLabel', [],...
        'YTickLabel', [],...
        'Xcolor', [0, 0, 0],...
        'Ycolor', [0, 0, 0],...
        'Tag', 'imageAxes');

    
    startAxesMetadataInfo(informationAxes);
    mainMenu = uimenu('parent', mainFig,...
        'Label', 'File');
    importMenu = uimenu('Parent', mainMenu,...
        'Label', 'Import');
    
    uimenu('Parent', importMenu,...
        'Label', 'Dicom',...
        'Callback', @openImage);
    
    uimenu('Parent', importMenu,...
        'Label', 'Mask',...
        'Tag', 'importMaskButton',...
        'Callback', @openMask);
    
    uicontrol('Parent', mainFig,...
        'Units', 'Normalized',...
        'Position', [0.92, 0.95, 0.05, 0.05],...
        'Style', 'Check',...
        'String', 'Show Mask',...
        'Fontsize', 14,....
        'Fontweight', 'bold',...
        'BackGroundColor', [0.1, 0.1, 0.1],...
        'ForeGroundColor', [1, 1, 1],...
        'Tag', 'showMaskCheck',...
        'Enable', 'Off',...
        'Callback', @showMask)
    
    uicontrol('Parent', mainFig,...
        'Style', 'slider',...
        'Units', 'Normalized',...
        'Visible', 'Off',...
        'Min',1,...
        'Max',1,...
        'Value', 1,...
        'Position', [0.25, 0.01, 0.5, 0.1],...
        'Callback', @moveSlicer,...
        'Tag', 'slicer');
    
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
function moveSlicer(hObject, ~)
    handles = guidata(hObject);
    imageMatrix = handles.data.imageCoreInfo.matrix;
    nSlices = size(imageMatrix, 3);
    
    currentSlicePosition = round(get(handles.gui.slicer, 'Value'));
    axesChildren = get(handles.gui.imageAxes,'children');
    set(axesChildren,'cdata',...
        squeeze(imageMatrix(:, :, currentSlicePosition, :)))
        
    % Check show mask state
    showMaskCheckState = get(handles.gui.showMaskCheck, 'Value');
    if showMaskCheckState
        createMaskOverlay(handles)
    end
    
    updateSliceNumberText(handles.gui.textSliceNumber,...
        currentSlicePosition, nSlices)
end

function openImage(hObject, ~)
    % Import Images
    handles = guidata(hObject);
    if isfield(handles.data, 'lastVisitedFolder')
        rootPath = uigetdir(handles.data.lastVisitedFolder,...
            'Select a folder with Dicom images');
    else
        rootPath = uigetdir('.', 'Select a folder with Dicom images');
    end
    
    if rootPath
        handles.data.lastVisitedFolder = rootPath;
        handles.data.imageCoreInfo = importDicoms(rootPath);
        
        % Check if any image was found
        if ~isempty(handles.data.imageCoreInfo)
            logFrame = createLogFrame();
            displayLog(logFrame, 'Importing Dicoms...', 0)
            
             %Calculate Window Coefficients
            [Rmin, Rmax] = windowCoeffAdj(handles.data.imageCoreInfo.matrix);
            handles.data.Rmin = Rmin;

            handles.data.Rmax = Rmax;
            % Save imported data
            guidata(hObject, handles)

            % Close log frame
            close(logFrame)
  
            % Enable controls
            set(handles.gui.importMaskButton, 'Enable', 'On')
            firstPosition = startSlicer(handles.gui.slicer,...
                handles.data.imageCoreInfo);

            %Show first Slice
            showImageSlice(handles.gui.imageAxes,...
                handles.data.imageCoreInfo.matrix(:, :, firstPosition),...
                handles.data.Rmin, handles.data.Rmax);
            
            % Show metadata on the screen
            startScreenMetadata(handles,...
                handles.data.imageCoreInfo.metadata{1},...
                firstPosition)
        end
        
    end
end

function openMask(hObject, ~)
    handles = guidata(hObject);
    if isfield(handles.data, 'lastVisitedFolder')
        [fileName, pathName] = uigetfile('*.hdr;*.nrrd',...
            'Select the file containing the masks',...
            handles.data.lastVisitedFolder);
    else
        [fileName, pathName] = uigetfile('*.hdr;*.nrrd',...
            'Select the file containing the masks');
    end
    
    if ~isempty(fileName)
        logFrame = createLogFrame();
        displayLog(logFrame, 'Importing masks...', 0)
        
        rootPath = [pathName fileName];
        handles.data.imageCoreInfo.masks = importMasks(rootPath);
        handles.data.lastVisitedFolder = rootPath;
               
        close(logFrame);
        
        % Enable show mask checkbox
        set(handles.gui.showMaskCheck, 'Enable', 'On')
        
        % Save imported mask
        guidata(hObject, handles)
    end
    
end

function mouseMove(hObject, ~)
    handles = guidata(hObject);
    if isfield(handles.data, 'imageCoreInfo')
        imageAxes = handles.gui.imageAxes;
        refreshPixelPositionInfo(handles, imageAxes);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                             UTILS                                
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function firstPosition = startSlicer(slicerObject, imageCoreInfo)
    nSlices = size(imageCoreInfo.matrix, 3);
    firstPosition = round(nSlices / 2);
    set(slicerObject, 'Visible', 'On',...
        'Min', 1,...
        'Max', nSlices,...
        'SliderStep', [1  / (nSlices - 1) 10 / (nSlices - 1)],...
        'Value', firstPosition);
end

function showImageSlice(axisObject, imageSlice, Rmin, Rmax)
    axesChildren = get(axisObject, 'children');
    if ~isempty(axesChildren)
        set(axesChildren, 'cdata', imageSlice);  
    else
        axes(axisObject)
        imshow(imageSlice, [Rmin, Rmax])
    end
    colormap(gray)
    set(axisObject, 'XtickLabel', [])
    set(axisObject, 'YtickLabel', [])
    
end

function updateSliceNumberText(textObject, sliceNumber, nSlices)
    set(textObject, 'String', sprintf('%d / %d', sliceNumber, nSlices));
end

function updateSliceLocationText(textObject, metadata,  sliceIndex)
    if sliceIndex > 0
        metadata = metadata{sliceIndex};
    end
    if isfield(metadata, 'SliceLocation')
        set(textObject, 'String', sprintf('Slice Location: %.2f',...
            metadata.sliceLocation));
    end
end

function startScreenMetadata(handles, metadata, firstPosition)
    % Show Slice Number
    updateSliceNumberText(handles.gui.textSliceNumber, firstPosition,...
        size(handles.data.imageCoreInfo.matrix, 3))
        
    updateSliceLocationText(handles.gui.textSliceLocation,...
        metadata, -1)
        
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

function refreshPixelPositionInfo(handles, mainAxes)

if isfield(handles, 'data')
    C = get(mainAxes,'currentpoint');

    xlim = get(mainAxes,'xlim');
    ylim = get(mainAxes,'ylim');

    row = round(C(1));
    col = round(C(1, 2));

    %Check if pointer is inside Navigation Axes.
    outX = ~any(diff([xlim(1) C(1,1) xlim(2)])<0);
    outY = ~any(diff([ylim(1) C(1,2) ylim(2)])<0);
    if outX && outY && row && col
        %Get the current Slice
        currentSlicePositionString = get(handles.gui.textSliceNumber,...
            'String');
        tempSlicePosition = regexp(currentSlicePositionString, '/',...
            'split');
        slicePosition = str2double(tempSlicePosition(1));

        currentSlice = handles.data.imageCoreInfo.matrix(:, :,...
            slicePosition);

        pixelValue = currentSlice(col, row);

        set(handles.gui.textPixelValue, 'String',...
            sprintf('Pixel Value = %.2f', double(pixelValue)))
    else
        set(handles.gui.textPixelValue, 'String',...
            sprintf('Pixel Value = -'))
    end

end
end

function newSlicePosition = getSlicePosition(slicePositionString, direction)
    tempSlicePosition = regexp(slicePositionString, '/', 'split');
    
    if nargin == 1
        direction = NaN;
    end

    if isnan(direction)
        newSlicePosition = str2double(tempSlicePosition(1));
    elseif direction > 0
        newSlicePosition = str2double(tempSlicePosition(1)) + 1;
    else
        newSlicePosition = str2double(tempSlicePosition(1)) - 1;
    end
end

function refreshSlicePosition(hObject, eventdata)

slicePositionPlaceHolder = '%d / %d';

handles = guidata(hObject);

if ~isempty(handles.data)

    nSlices = size(handles.data.imageCoreInfo.matrix, 3);

    currentSlicePosition = get(handles.gui.textSliceNumber, 'String');

    %Get the new slice position based on the displayed values using regexp
    if isprop(eventdata, 'VerticalScrollCount')
        newSlicePosition = getSlicePosition(currentSlicePosition,...
            eventdata.VerticalScrollCount);
    else
        newSlicePosition = getSlicePosition(currentSlicePosition);
    end
       
    %Make sure that the slice number return to 1 if it is bigger than the
    %number of slices
    newSlicePosition = mod(newSlicePosition, nSlices);

    %Make sure that the slice number return to nSlices if it is smaller than the
    %number of slices
    if ~newSlicePosition && eventdata.VerticalScrollCount < 0
        newSlicePosition = nSlices;
    elseif ~newSlicePosition && eventdata.VerticalScrollCount >= 0 %%% -- INFO -- matlab has some hard time with the scroll of my laptop, in this case VerticalScrollCount == 0, it get an error latter in this function and this is error realy I need to restart matlab. I changed > to >=
        newSlicePosition = 1;
    end

    %Refresh slice position information.
    set(handles.gui.textSliceNumber, 'String',...
        sprintf(slicePositionPlaceHolder, newSlicePosition, nSlices));
  
    showImageSlice(handles.gui.imageAxes,...
        squeeze(handles.data.imageCoreInfo.matrix(:, :, newSlicePosition, :)),...
        handles.data.Rmin, handles.data.Rmax);
    

    %Refresh pixel value information.
    refreshPixelPositionInfo(handles, handles.gui.imageAxes)
    
    %Refresh Slice Location information.
   updateSliceLocationText(handles.gui.textSliceLocation,...
        handles.data.imageCoreInfo.metadata, newSlicePosition);
    
    %Refresh slider value
    set(handles.gui.slicer, 'Value', newSlicePosition);

    % Check show mask state
    showMaskCheckState = get(handles.gui.showMaskCheck, 'Value');
    if showMaskCheckState
        createMaskOverlay(handles)
    end
    
    guidata(hObject, handles)
end
end

function showMask(hObject, eventdata)
    handles = guidata(hObject);
    set(handles.gui.imageAxes, 'NextPlot', 'Replace')
    showMaskCheckState = get(handles.gui.showMaskCheck, 'Value');
    if showMaskCheckState
        createMaskOverlay(handles)
    else
        % Delete maskOverlay object to make navigation faster
        delete(findobj(handles.gui.imageAxes, 'Tag', 'maskOverlay'))
        refreshSlicePosition(hObject, eventdata)
    end   
end

 function createMaskOverlay(handles)
    slicePositionString = get(handles.gui.textSliceNumber, 'String');
    currentSlicePosition = getSlicePosition(slicePositionString);
    mask = handles.data.imageCoreInfo.masks(:, :, currentSlicePosition);
    lungDim = size(mask, 1);
    mask = mask >= 1;
 
    
    overlayColor = [0 1 0];
    defaultOpacity = 0.5;

%     switch overlayColor
%         case {'y','yellow'}
%             overlayColor = [1 1 0];
%         case {'m','magenta'}
%             overlayColor = [1 0 1];
%         case {'c','cyan'}
%             overlayColor = [0 1 1];
%         case {'r','red'}
%             overlayColor = [1 0 0];
%         case {'g','green'}
%             overlayColor = [0 1 0];
%         case {'b','blue'}
%             overlayColor = [0 0 1];
%         case {'w','white'}
%             overlayColor = [1 1 1];            
%         case {'k','black'}
%             overlayColor = [0 0 0];
%     end
    
    colorMask = cat(3, overlayColor(1) * ones(lungDim),...
        overlayColor(2) * ones(lungDim),...
        overlayColor(3) * ones(lungDim));

    delete(findobj(handles.gui.imageAxes, 'Tag', 'maskOverlay'))
    hold on
    h = imshow(colorMask);
    set(h, 'AlphaData', mask * defaultOpacity, 'tag', 'maskOverlay');   
    hold off
 end

 function [Rmin, Rmax] = windowCoeffAdj(Img)
 MinV = 0;
 MaxV = max(Img(:));
 LevV = (double( MaxV) + double(MinV)) / 2;
 Win = double(MaxV) - double(MinV);
 WLAdjCoe = (Win + 1)/1024;
 FineTuneC = [1 1/16];    % Regular/Fine-tune mode coefficients
 
 if isa(Img,'uint8')
     MaxV = uint8(Inf);
     MinV = uint8(-Inf);
     LevV = (double( MaxV) + double(MinV)) / 2;
     Win = double(MaxV) - double(MinV);
     WLAdjCoe = (Win + 1)/1024;
 elseif isa(Img,'uint16')
     MaxV = uint16(Inf);
     MinV = uint16(-Inf);
     LevV = (double( MaxV) + double(MinV)) / 2;
     Win = double(MaxV) - double(MinV);
     WLAdjCoe = (Win + 1)/1024;
 elseif isa(Img,'uint32')
     MaxV = uint32(Inf);
     MinV = uint32(-Inf);
     LevV = (double( MaxV) + double(MinV)) / 2;
     Win = double(MaxV) - double(MinV);
     WLAdjCoe = (Win + 1)/1024;
 elseif isa(Img,'uint64')
     MaxV = uint64(Inf);
     MinV = uint64(-Inf);
     LevV = (double( MaxV) + double(MinV)) / 2;
     Win = double(MaxV) - double(MinV);
     WLAdjCoe = (Win + 1)/1024;
 elseif isa(Img,'int8')
     MaxV = int8(Inf);
     MinV = int8(-Inf);
     LevV = (double( MaxV) + double(MinV)) / 2;
     Win = double(MaxV) - double(MinV);
     WLAdjCoe = (Win + 1)/1024;
 elseif isa(Img,'int16')
     MaxV = int16(Inf);
     MinV = int16(-Inf);
     LevV = (double( MaxV) + double(MinV)) / 2;
     Win = double(MaxV) - double(MinV);
     WLAdjCoe = (Win + 1)/1024;
 elseif isa(Img,'int32')
     MaxV = int32(Inf);
     MinV = int32(-Inf);
     LevV = (double( MaxV) + double(MinV)) / 2;
     Win = double(MaxV) - double(MinV);
     WLAdjCoe = (Win + 1)/1024;
 elseif isa(Img,'int64')
     MaxV = int64(Inf);
     MinV = int64(-Inf);
     LevV = (double( MaxV) + double(MinV)) / 2;
     Win = double(MaxV) - double(MinV);
     WLAdjCoe = (Win + 1)/1024;
 elseif isa(Img,'logical')
     MaxV = 0;
     MinV = 1;
     LevV =0.5;
     Win = 1;
     WLAdjCoe = 0.1;
 end    

 [Rmin, Rmax] = WL2R(Win, LevV);
 end
 
 function [Rmn Rmx] = WL2R(W,L)
    Rmn = L - (W/2);
    Rmx = L + (W/2);
    if (Rmn >= Rmx)
        Rmx = Rmn + 1;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                             LOG FRAME                            
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function figObject = createLogFrame()
    %disply calculation log.
    figObject = figure('Units', 'Normalized',...
        'Position', [0.3, 0.4, 0.4, 0.2],...
        'Toolbar', 'None',...
        'Menubar', 'None',...
        'Color', 'black',...
        'Name', 'Log',...
        'NumberTitle', 'Off',...
        'WindowStyle', 'Modal',...
        'Resize', 'Off');
end

function displayLog(figObj, msg, clearAxes)
   if clearAxes
       cla
   else
       ax = axes('Parent', figObj, 'Visible', 'Off');
       axes(ax)
    end

    text(0.5, 0.5, msg, 'Color', 'white', 'HorizontalAlignment',...
    'center', 'FontSize', 14)

    drawnow
end