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