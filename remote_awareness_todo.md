remote_awareness software ToDo
==============================

## General
- get it to work on processed images (not sure if we should implement that)
- Provide better help for CLI (e.g. point out if parameters are only needed in certain modes; if there are are certaint values to pick from indicate those)
- output warning if images are too big for compression within 2kB
- don't write index when outputting csv files
- fix various deprecation errors
- inference and get_representative_images use independent numbers of images and clusters. If the imges hould correpsond to the table thats not ideal. Also even if they are the same numbers, if the processing is run twice, need to make sure if it comes up with the same clustering each time. If not, it would lead to non-corresponding results, i.e. the images not corresponding to the numbering in the table. Or maybe we only need to run one of the two? Check how it is done in the pipeline.
- It looks like it is not really designed to run it command by command (as some necessary parameters could not be passed on the command line). Try running things with the pipeline.

## generate_metadata_csv
- Fix "/usr/local/lib/python3.10/dist-packages/remote_awareness/generate_metadata_csv.py:147: FutureWarning: DataFrame.interpolate with object dtype is deprecated and will raise in a future version. Call obj.infer_objects(copy=False) before interpolating instead.
  .interpolate()"
- Add info when things are done ("... x is done")
- use info/warning etc from console message class

## sampling
- Use image number when checking size to avoid "WARNING: The dataset is too small: 983 images before filtering." if setting is != 1500
- Make it work with voyis corrected images. Either modify code, or edit metadata.csv file output by generate_metadata_csv. However, the images also need to be resized. To modify metadata.csv run
```bash
sed -i 's/raw_/processed_/g' metadata.csv && \
sed -i 's/stills\/raw/stills\/processed/g' metadata.csv && \
sed -i 's/.tif/.jpg/g' metadata.csv
```

## correct_images
- output error if downsize_ratio (-r) in correct_images is > 1
- fix error that happens if downsize_ratio leads to non-integer numbers which when rounded lead to different sizes (e.g. for 0.15)

## inference / representative_images
I noted that the pipeline is not running inference (and also that inference makes the same type of computations as representative_images, but that probably yields different results every time), but when I try to run representative_iamges without having run inference before it misses a file. Double check if infernece really isn't run in the pipeline, and if this is the case, how they go around the missing file issue.
