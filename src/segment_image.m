function [segmented_image, contour] = segment_image(input_image)
    ycbcr = utils.rgb_to_ycbcr(input_image);
    
    edges = utils.sobel_edge_detection(ycbcr(:,:,1));
    
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
        contour = struct('BoundingBox', bbox);
        
        segmented_image = draw_boundary(segmented_image, bbox);
    else
        segmented_image = input_image;
        contour = struct('BoundingBox', []);
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