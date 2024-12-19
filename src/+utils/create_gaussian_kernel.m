function kernel = create_gaussian_kernel(k_size, sigma)
    half = floor(k_size/2);
    [x, y] = meshgrid(-half:half, -half:half);
    kernel = exp(-(x.^2 + y.^2)/(2*sigma^2));
    kernel = kernel / sum(kernel(:));
end