function ycbcr = rgb_to_ycbcr(rgb)
    R = double(rgb(:,:,1));
    G = double(rgb(:,:,2));
    B = double(rgb(:,:,3));
    
    Y  = 0.299*R + 0.587*G + 0.114*B;
    Cb = 128 - 0.168736*R - 0.331264*G + 0.5*B;
    Cr = 128 + 0.5*R - 0.418688*G - 0.081312*B;
    
    ycbcr = cat(3, Y, Cb, Cr);
end