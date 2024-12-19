function edges = sobel_edge_detection(img)
    Gx = [-1 0 1; -2 0 2; -1 0 1];
    Gy = [-1 -2 -1; 0 0 0; 1 2 1];
    
    gradient_x = utils.manual_convolution(img, Gx);
    gradient_y = utils.manual_convolution(img, Gy);
    
    magnitude = sqrt(gradient_x.^2 + gradient_y.^2);
    
    edges = magnitude > (mean(magnitude(:)) * 2);
end