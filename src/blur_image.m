function blurred_image = blur_image(input_image, contour)
    blurred_image = input_image;
    
    if ~isempty(contour.BoundingBox)
        bbox = contour.BoundingBox;
        
        x = max(1, round(bbox(1)));
        y = max(1, round(bbox(2)));
        width = round(bbox(3));
        height = round(bbox(4));
        
        x_end = min(size(input_image, 2), x + width);
        y_end = min(size(input_image, 1), y + height);
        
        face_region = input_image(y:y_end, x:x_end, :);
        
        block_size = max(2, round(min(width, height) / 20));
        
        blurred_region = pixelate_region(face_region, block_size);
        
        blurred_image(y:y_end, x:x_end, :) = blurred_region;
    end
end

function pixelated = pixelate_region(region, block_size)
    [height, width, channels] = size(region);
    pixelated = region;
    
    for y = 1:block_size:height
        for x = 1:block_size:width
            y_end = min(y + block_size - 1, height);
            x_end = min(x + block_size - 1, width);
            
            for c = 1:channels
                block = region(y:y_end, x:x_end, c);
                avg_color = mean(block(:));
                pixelated(y:y_end, x:x_end, c) = avg_color;
            end
        end
    end
    
    kernel = utils.create_gaussian_kernel(3, 1);
    
    for c = 1:channels
        pixelated(:,:,c) = utils.manual_convolution(pixelated(:,:,c), kernel);
    end
end