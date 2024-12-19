function img = normalize_to_uint8_range(img)
    img_min = min(img(:));
    img_max = max(img(:));
    if img_max > img_min
        img = (img - img_min) * (255 / (img_max - img_min));
    else
        img = img - img_min;
    end
end