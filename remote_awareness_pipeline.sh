#!/bin/bash

if [ -z "$2" ]
  then
    echo "Usage: $0 IMAGING_FOLDER_PATH NAV_BAG_PATH [NUMBER_OF_IAMGES (default=1500)]"
    exit 1
fi

PARAMETER_FILE_FOLDER="Documents/remote_awareness_files/"
AE_MODEL_NAME="ae_model_lga_trained_on_20241107_151151.pt"   # "ae_model.pt"
REMOTE_AWARENESS_DOCKER="docker run --rm -it --ipc=private -e USER=$(whoami) -h $HOSTNAME --user $(id -u):$(id -g) -v $(pwd):/data -v /etc/passwd:/etc/passwd:ro -v /etc/group:/etc/group:ro --name=georef_$(whoami)_$(date +%Y%m%d_%H%M%S) --net=host -v $HOME/.cache/matplotlib:/opt/.config/matplotlib --shm-size=16g remote_awareness_image remote_awareness"
IMAGING_FOLDER="$1" 
NAV_BAG="$2"
if [ ! -z "$3" ]
  then
    NUMBER_OF_IMAGES=$3
else
    NUMBER_OF_IMAGES=1500
fi
TMP="${IMAGING_FOLDER::-1}"
SUFFIX="${TMP##*/}"
ZIP_FILE="remote_awareness_summary_${SUFFIX}.zip"

if [ ! -d "$IMAGING_FOLDER" ]; then
    echo "Error: Imaging folder does not exist."
    exit 1
fi

# Check if none of the output files or folders exist
if [ -f "corrected_images.csv" ] || \
   [ -d "corrected_images" ] || \
   [ -f "samples.csv" ] || \
   [ -f "metadata.csv" ] || \
   [ -d "remote_awareness_summary" ] || \
   [ -f "$ZIP_FILE" ]
   then
    echo "Error: Some output files or folders already exist."
    echo -n "Please remove them before running the script; i.e., any of the following: "
    echo -n "corrected_images.csv, samples.csv, metadata.csv, $ZIP_FILE, "
    echo "corrected_images/, remote_awareness_summary/"
    exit 1
fi

echo "Generate metadata"
$REMOTE_AWARENESS_DOCKER generate_metadata_csv \
-i "${IMAGING_FOLDER}" \
-b "${NAV_BAG}" \
-o metadata.csv || \
{ echo "Error in generate_metadata_csv" ; exit 1; }

echo -e "\nSampling"
$REMOTE_AWARENESS_DOCKER sampling \
--csv metadata.csv \
--number-of-images $NUMBER_OF_IMAGES \
--output-path samples.csv || \
{ echo "Error in sampling" ; exit 1; }

echo -e "\nCorrect images"
$REMOTE_AWARENESS_DOCKER correct_images \
--csv samples.csv \
-i "${IMAGING_FOLDER}stills/raw/" \
--raw-images-extension tif \
--raw-images-type rggb \
-d 16 \
-r 0.125 \
--calib mono_camera_calib_25_06_24.yaml \
--image-std "${PARAMETER_FILE_FOLDER}image_corrected_std.npy" \
--image-mean "${PARAMETER_FILE_FOLDER}image_corrected_mean.npy" \
--attenuation-parameters "${PARAMETER_FILE_FOLDER}attenuation_parameters.npy" \
--correction-gains "${PARAMETER_FILE_FOLDER}correction_gains.npy" \
--corrected-images-path corrected_images || \
{ echo "Error in correct_images" ; exit 1; }

echo -e "\nInference"
$REMOTE_AWARENESS_DOCKER inference \
--model-path "${PARAMETER_FILE_FOLDER}${AE_MODEL_NAME}" \
--metadata-csv corrected_images.csv \
--output-directory remote_awareness_summary \
--use-full-image || \
{ echo "Error in inference" ; exit 1; }

echo -e "\nRepresentative images"
$REMOTE_AWARENESS_DOCKER representative_images \
--output-directory remote_awareness_summary || \
{ echo "Error in representative_images" ; exit 1; }

echo -e "\nZipping output"
zip -r $ZIP_FILE remote_awareness_summary

echo -e "\nMoving output to new folder"
OUTPUT_FOLDER="remote_awareness_summary_files_${SUFFIX}"
COUNTER=1
while [ -d "$OUTPUT_FOLDER" ]; do
    OUTPUT_FOLDER="remote_awareness_summary_files_${SUFFIX}_${COUNTER}"
    COUNTER=$((COUNTER+1))
done

mkdir $OUTPUT_FOLDER && \
mv corrected_images.csv corrected_images samples.csv metadata.csv remote_awareness_summary "$ZIP_FILE" "$OUTPUT_FOLDER" && \
echo -e "Output saved in ${OUTPUT_FOLDER}.\nAll Done!" || \
echo "Error while attempting to move output files to ${OUTPUT_FOLDER}."
