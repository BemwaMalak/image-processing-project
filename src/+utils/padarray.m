function padded_img = padarray(img, padsize)
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