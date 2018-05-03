function openMasks(maskPath)
    if strfind(maskPath, 'hdr')
        masks = analyze75read(maskPath);
    else
        masks = nrrd_read(maskPath);
    end
end