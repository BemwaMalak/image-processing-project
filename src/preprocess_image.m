function preprocessed_image = preprocess_image(input_image)
    input_image = double(input_image);
    
    target_size = [512 512];
    resized_image = utils.resize_nearest_neighbor(input_image, target_size);
    
    R = resized_image(:,:,1);
    G = resized_image(:,:,2);
    B = resized_image(:,:,3);
    
    R = utils.normalize_to_uint8_range(R);
    G = utils.normalize_to_uint8_range(G);
    B = utils.normalize_to_uint8_range(B);

    gaussian_kernel = utils.create_gaussian_kernel(5, 1);
    R_smoothed = utils.manual_convolution(R, gaussian_kernel);
    G_smoothed = utils.manual_convolution(G, gaussian_kernel);
    B_smoothed = utils.manual_convolution(B, gaussian_kernel);

    preprocessed_image = cat(3, R_smoothed, G_smoothed, B_smoothed);
    preprocessed_image = uint8(preprocessed_image);
end