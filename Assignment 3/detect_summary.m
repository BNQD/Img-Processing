
disp ("Student A: Bao Doan 500733516");
disp ("Student B: Li Ne Li 500722909");

fprintf ("The detection summary was first done with one scale. Afterwards, testing had been done on individual scales." + ...
    "To ensure that the best predictions were taken first, over any overlapping predictions, with each pass through " + ...
    "an image of differing scale's features will be scanned and the corresponding boxes with the confidence levels " + ... 
    "recorded. After all scales had been scanned, the resulting boxes will be sorted by confidence. After which " + ... 
    "the boxes will be selected in order of confidence. If there is an overlap, the box is skipped and the next " + ...
    "box will be checked for over lapping. After reaching a predetermined threshold value, the process of going " + ...
    "through boxes is complete.");

fprintf ("To improve the accuracy of the detection, the threshold value was changed with a final value of 1.5 for " + ...
    "detecting the test_images, and for class images, the threshold value was determined to be 1.8. To further " + ...
    "the accuracy of the detection, the lambda value was changed from 0.0001");


