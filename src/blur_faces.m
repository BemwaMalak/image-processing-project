function blurred_image = blur_faces(input_image, contours)
    blurred_image = input_image;
    
    for i = 1:length(contours)
        bbox = contours(i).BoundingBox;
        
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
    
    kernel = create_gaussian_kernel(3, 1);
    
    for c = 1:channels
        pixelated(:,:,c) = apply_gaussian_blur(pixelated(:,:,c), kernel);
    end
end

function kernel = create_gaussian_kernel(k_size, sigma)
    half = floor(k_size/2);
    [x, y] = meshgrid(-half:half, -half:half);
    kernel = exp(-(x.^2 + y.^2)/(2*sigma^2));
    kernel = kernel / sum(kernel(:));
end

function blurred = apply_gaussian_blur(img, kernel)
    [rows, cols] = size(img);
    [krows, kcols] = size(kernel);
    rpad = floor(krows/2);
    cpad = floor(kcols/2);
    
    padded = padarray(img, [rpad cpad], 'replicate');
    blurred = zeros(rows, cols);
    
    for r = 1:rows
        for c = 1:cols
            region = padded(r:r+krows-1, c:c+kcols-1);
            blurred(r,c) = sum(sum(region .* kernel));
        end
    end
end

function padded_img = padarray(img, padsize, method)
    rpad = padsize(1);
    cpad = padsize(2);
    [rows, cols] = size(img);
    
    top_rows = repmat(img(1,:), rpad, 1);
    bottom_rows = repmat(img(rows,:), rpad, 1);
    temp = [top_rows; img; bottom_rows];
    
    left_cols = repmat(temp(:,1), 1, cpad);
    right_cols = repmat(temp(:,end), 1, cpad);
    padded_img = [left_cols, temp, right_cols];
end