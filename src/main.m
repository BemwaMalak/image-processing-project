input_image = imread('../data/raw/test.jpeg');

[processed_image, original_size] = preprocess_image(input_image);

[segmented_image, contours] = segment_and_extract(processed_image);

blurred_image = blur_faces(processed_image, contours);

figure;
subplot(2, 2, 1); imshow(input_image); title('Original Image');
subplot(2, 2, 2); imshow(processed_image); title('Processed Image');
subplot(2, 2, 3); imshow(segmented_image); title('Segmented Image');
subplot(2, 2, 4); imshow(blurred_image); title('Blurred Faces');