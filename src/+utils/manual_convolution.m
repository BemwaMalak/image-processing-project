function result = manual_convolution(img, kernel)
    [rows, cols] = size(img);
    [krows, kcols] = size(kernel);
    rpad = floor(krows/2);
    cpad = floor(kcols/2);
    
    padded = utils.padarray(img, [rpad cpad]);
    result = zeros(rows, cols);
    
    for r = 1:rows
        for c = 1:cols
            region = padded(r:r+krows-1, c:c+kcols-1);
            result(r,c) = sum(sum(region .* kernel));
        end
    end
end