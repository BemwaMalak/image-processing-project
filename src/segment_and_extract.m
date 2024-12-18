function [segmented_image, contours] = segment_and_extract(input_image)
    ycbcr = rgb_to_ycbcr(input_image);
    
    edges = sobel_edge_detection(ycbcr(:,:,1));
    
    Cb = ycbcr(:,:,2);
    Cr = ycbcr(:,:,3);
    skin_mask = (Cb >= 77) & (Cb <= 127) & (Cr >= 133) & (Cr <= 173);
    
    combined_mask = edges & skin_mask;
    
    [rows, cols] = find(combined_mask);
    
    if ~isempty(rows) && ~isempty(cols)
        min_row = max(1, min(rows));
        max_row = min(size(combined_mask,1), max(rows));
        min_col = max(1, min(cols));
        max_col = min(size(combined_mask,2), max(cols));
        
        height = max_row - min_row;
        center_row = min_row + height * 0.45;
        center_col = (min_col + max_col) / 2;
        
        face_width = max_col - min_col;
        face_height = max_row - min_row;
        face_size = min(face_width, face_height);
        
        half_size = round(face_size * 0.4);
        
        vertical_offset = round(half_size * 0.1);
        
        bbox = round([
            max(1, center_col - half_size * 0.8), ...
            max(1, center_row - half_size - vertical_offset), ...
            min(size(combined_mask,2) - max(1, round(center_col - half_size * 0.8)), 2*half_size * 0.8), ... % width
            min(size(combined_mask,1) - max(1, round(center_row - half_size - vertical_offset)), 2*half_size)  ... % height
        ]);
        
        segmented_image = input_image;
        contours = struct('BoundingBox', {}, 'Features', {});
        
        segmented_image = draw_boundary(segmented_image, bbox);
        
        contours(1).BoundingBox = bbox;
        contours(1).Features = extract_facial_features(ycbcr(:,:,1), bbox);
    else
        segmented_image = input_image;
        contours = struct('BoundingBox', {}, 'Features', {});
    end
end

function output_image = draw_boundary(input_image, bbox)
    [rows, cols, ~] = size(input_image);
    output_image = input_image;
    
    bbox = round(bbox);
    x = bbox(1);
    y = bbox(2);
    width = bbox(3);
    height = bbox(4);
    
    color = [255, 0, 0];
    line_width = 2;
    
    for c = max(1, x-line_width):min(cols, x+width+line_width)
        for w = 0:line_width-1
            if y-w >= 1 && y-w <= rows
                output_image(y-w,c,:) = color;
            end
            if y+height+w >= 1 && y+height+w <= rows
                output_image(y+height+w,c,:) = color;
            end
        end
    end
    
    for r = max(1, y-line_width):min(rows, y+height+line_width)
        for w = 0:line_width-1
            if x-w >= 1 && x-w <= cols
                output_image(r,x-w,:) = color;
            end
            if x+width+w >= 1 && x+width+w <= cols
                output_image(r,x+width+w,:) = color;
            end
        end
    end
end

function ycbcr = rgb_to_ycbcr(rgb)
    R = double(rgb(:,:,1));
    G = double(rgb(:,:,2));
    B = double(rgb(:,:,3));
    
    Y  = 0.299*R + 0.587*G + 0.114*B;
    Cb = 128 - 0.168736*R - 0.331264*G + 0.5*B;
    Cr = 128 + 0.5*R - 0.418688*G - 0.081312*B;
    
    ycbcr = cat(3, Y, Cb, Cr);
end

function thresh_img = adaptive_threshold(img, window_size, C)
    [rows, cols] = size(img);
    thresh_img = false(rows, cols);
    pad = floor(window_size/2);
    padded = padarray(img, [pad pad], 'replicate');
    
    for i = 1:rows
        for j = 1:cols
            window = padded(i:i+window_size-1, j:j+window_size-1);
            threshold = mean(window(:)) - C;
            thresh_img(i,j) = img(i,j) > threshold;
        end
    end
end

function edges = sobel_edge_detection(img)
    Gx = [-1 0 1; -2 0 2; -1 0 1];
    Gy = [-1 -2 -1; 0 0 0; 1 2 1];
    
    gradient_x = manual_convolution(img, Gx);
    gradient_y = manual_convolution(img, Gy);
    
    magnitude = sqrt(gradient_x.^2 + gradient_y.^2);
    
    edges = magnitude > (mean(magnitude(:)) * 2);
end

function dilated = morphological_dilate(img, kernel_size)
    [rows, cols] = size(img);
    dilated = false(rows, cols);
    pad = floor(kernel_size/2);
    padded = padarray(img, [pad pad], false);
    
    for i = 1:rows
        for j = 1:cols
            window = padded(i:i+kernel_size-1, j:j+kernel_size-1);
            dilated(i,j) = any(window(:));
        end
    end
end

function eroded = morphological_erode(img, kernel_size)
    [rows, cols] = size(img);
    eroded = false(rows, cols);
    pad = floor(kernel_size/2);
    padded = padarray(img, [pad pad], true);
    
    for i = 1:rows
        for j = 1:cols
            window = padded(i:i+kernel_size-1, j:j+kernel_size-1);
            eroded(i,j) = all(window(:));
        end
    end
end

function [labeled, num_regions] = connected_components(binary_img)
    [rows, cols] = size(binary_img);
    labeled = zeros(rows, cols);
    current_label = 0;
    
    for i = 1:rows
        for j = 1:cols
            if binary_img(i,j)
                neighbors = get_neighbors(labeled, i, j);
                if isempty(neighbors)
                    current_label = current_label + 1;
                    labeled(i,j) = current_label;
                else
                    labeled(i,j) = min(neighbors);
                end
            end
        end
    end
    
    for i = 1:rows
        for j = 1:cols
            if labeled(i,j) > 0
                neighbors = get_neighbors(labeled, i, j);
                if ~isempty(neighbors)
                    labeled(i,j) = min(neighbors);
                end
            end
        end
    end
    
    unique_labels = unique(labeled);
    unique_labels = unique_labels(unique_labels > 0);
    num_regions = length(unique_labels);
    
    for i = 1:length(unique_labels)
        labeled(labeled == unique_labels(i)) = i;
    end
end

function neighbors = get_neighbors(labeled, i, j)
    neighbors = [];
    [rows, cols] = size(labeled);
    
    for di = -1:1
        for dj = -1:1
            if di == 0 && dj == 0
                continue;
            end
            ni = i + di;
            nj = j + dj;
            if ni >= 1 && ni <= rows && nj >= 1 && nj <= cols
                if labeled(ni, nj) > 0
                    neighbors = [neighbors, labeled(ni, nj)];
                end
            end
        end
    end
end

function bbox = get_bounding_box(region_mask)
    [rows, cols] = find(region_mask);
    if isempty(rows) || isempty(cols)
        bbox = [0 0 0 0];
        return;
    end
    
    min_row = min(rows);
    max_row = max(rows);
    min_col = min(cols);
    max_col = max(cols);
    
    bbox = [min_col min_row (max_col-min_col+1) (max_row-min_row+1)];
end

function valid = is_valid_face_region(aspect_ratio, region_size, image_size)
    valid_ratio = aspect_ratio >= 0.5 && aspect_ratio <= 2.0;
    valid_size = region_size >= (0.01 * image_size(1) * image_size(2)) && ...
                 region_size <= (0.6 * image_size(1) * image_size(2));
    
    valid = valid_ratio && valid_size;
end

function features = extract_facial_features(gray_image, bbox)
    face_region = gray_image(bbox(2):bbox(2)+bbox(4), ...
                            bbox(1):bbox(1)+bbox(3));
    
    [rows, cols] = size(face_region);
    
    eye_region_top = round(rows * 0.2);
    eye_region_bottom = round(rows * 0.5);
    nose_region_top = round(rows * 0.4);
    nose_region_bottom = round(rows * 0.7);
    mouth_region_top = round(rows * 0.6);
    mouth_region_bottom = round(rows * 0.9);
    
    features = struct();
    features.eye_region = [1, eye_region_top, cols, eye_region_bottom-eye_region_top];
    features.nose_region = [1, nose_region_top, cols, nose_region_bottom-nose_region_top];
    features.mouth_region = [1, mouth_region_top, cols, mouth_region_bottom-mouth_region_top];
end

function result = manual_convolution(img, kernel)
    [rows, cols] = size(img);
    [krows, kcols] = size(kernel);
    rpad = floor(krows/2);
    cpad = floor(kcols/2);
    
    padded = padarray(img, [rpad cpad], 'replicate');
    result = zeros(rows, cols);
    
    for r = 1:rows
        for c = 1:cols
            region = padded(r:r+krows-1, c:c+kcols-1);
            result(r,c) = sum(sum(region .* kernel));
        end
    end
end

function padded_img = padarray(img, padsize, method)
    rpad = padsize(1);
    cpad = padsize(2);
    [rows, cols] = size(img);
    
    if islogical(method)
        padded_img = method(ones(rows + 2*rpad, cols + 2*cpad));
        padded_img(rpad+1:rpad+rows, cpad+1:cpad+cols) = img;
    else
        top_rows = repmat(img(1,:), rpad, 1);
        bottom_rows = repmat(img(rows,:), rpad, 1);
        temp = [top_rows; img; bottom_rows];
        
        left_cols = repmat(temp(:,1), 1, cpad);
        right_cols = repmat(temp(:,end), 1, cpad);
        padded_img = [left_cols, temp, right_cols];
    end
end