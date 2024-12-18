function [preprocessed_image, original_size] = preprocess_image(input_image)
    input_image = double(input_image);
    
    original_size = size(input_image);
    
    target_size = [512 512];
    resized_image = resize_nearest_neighbor(input_image, target_size);
    
    R = resized_image(:,:,1);
    G = resized_image(:,:,2);
    B = resized_image(:,:,3);
    
    R = normalize_to_uint8_range(R);
    G = normalize_to_uint8_range(G);
    B = normalize_to_uint8_range(B);

    gaussian_kernel = create_gaussian_kernel(5, 1);
    R_smoothed = manual_convolution(R, gaussian_kernel);
    G_smoothed = manual_convolution(G, gaussian_kernel);
    B_smoothed = manual_convolution(B, gaussian_kernel);

    preprocessed_image = cat(3, R_smoothed, G_smoothed, B_smoothed);
        
    preprocessed_image = uint8(preprocessed_image);
end

function out_img = resize_nearest_neighbor(in_img, out_size)
    [in_rows, in_cols, in_channels] = size(in_img);
    out_rows = out_size(1);
    out_cols = out_size(2);

    row_scale = in_rows / out_rows;
    col_scale = in_cols / out_cols;
    
    out_img = zeros(out_rows, out_cols, in_channels);

    for r = 1:out_rows
        for c = 1:out_cols
            in_r = floor((r - 1)*row_scale) + 1;
            in_c = floor((c - 1)*col_scale) + 1;
            out_img(r,c,:) = in_img(in_r, in_c, :);
        end
    end
end

function img = normalize_to_uint8_range(img)
    img_min = min(img(:));
    img_max = max(img(:));
    if img_max > img_min
        img = (img - img_min) * (255 / (img_max - img_min));
    else
        img = img - img_min;
    end
end

function kernel = create_gaussian_kernel(k_size, sigma)
    half = floor(k_size/2);
    [x, y] = meshgrid(-half:half, -half:half);
    kernel = exp(-(x.^2 + y.^2)/(2*sigma^2));
    kernel = kernel / sum(kernel(:));
end

function out_img = manual_convolution(in_img, kernel)
    [rows, cols] = size(in_img);
    [krows, kcols] = size(kernel);
    rpad = floor(krows/2);
    cpad = floor(kcols/2);
    
    padded = padarray(in_img, [rpad cpad], 'replicate');
    out_img = zeros(rows, cols);
    
    for r = 1:rows
        for c = 1:cols
            region = padded(r : r + krows - 1, c : c + kcols - 1);
            out_img(r,c) = sum(sum(region .* kernel));
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
