Sparus manual
=============

## Preliminary: Router setup for wifi acces to sparus and internet
- Connect to router oplab-net3
- IPv4 settings:
    DHCP
    DNS: 192.168.1.1, 8.8.8.8
    Routes: 192.168.1.1, 255.255.255.0, 192.168.1.1


## Connecting to Sparus
There are 2 comptuers: the sparus computer and the voyis (jetson) computer. Commands are run from the sparus computer

Log in to sparus2 comptuer: `ssh sparus2` (or `ssh sparus`, depending on the ssh config)
Or if ssh config is not set up: `ssh user@192.168.1.71` Password: iqua

Log in to jetson from sparus: `ssh voyis-jetson`
Or directly from this laptop: `ssh tguser@192.168.1.26`, Password: cc20#12tg 


## Starting architcture
Launch `byobu`
`roslaunch cola2_sparus2 start.launch`
To stop architercture: Ctrl + C
Typical errors:
INS not initialised: no need to worry: it takes 20 min or so to align (can check in browser at 192.168.10.10)


## Iquaview
double-click IQUAview on the desktop
- "Vehicle" green shows vehicle is powered
- "COLA2" green means architecture is on
- Enable the joystick using the joystick symbol
- Click on propeller symbol to enable thrusters
- Open the checklist by clicking on the "Check List" symbol. Run through checklist
- Click on "AUV Configuration Parameters" to set the limits for the joystick (+-0.25 for x, y and yaw is good in the pool, 0.5 or 0.6 in the ocean)
- Click on anker symbol to "Disable Keep Position" (important when in the tank!)
- Click on the Sparus ("cigarette") symbol ("Monitor AUV Pose") to display the Vehicle Widgets

## Running camera system
(I think the below commands are run from within the voyis camera system, i.e. ssh into the jetson)
`pyvoyis -c ~/git/pyvoyis/config/pyvoyis.yaml`
or
`pyvoyis -c ~/git/pyvoyis/config/pyvoyis_no_laser.yaml`

Sometimes it shows an error "Voyis API500 server s is not online. Retrying in 5 seconds...". This can be because the time between the jetson and the sparus PC. Restarting usually solves it.

If that happens run `sudo service loop500 restart` inside the jetson.

Note: Before interacting with the voyis system it is important to turn on the architecture, as otherwise the time signal is not sent

# Remote awareness

## Code
When downloading code, make sure to also download libbpg in ./external/libbpg (from https://github.com/miquelmassot/libbpg/)

## Running remote awareness
There is an alias in ~/.bashrc:
`alias remote_awareness='docker run --rm -it --ipc=private -e USER=$(whoami) -h $HOSTNAME --user $(id -u):$(id -g) --volume $(pwd):/data -v /etc/passwd:/etc/passwd:ro -v /etc/group:/etc/group:ro --name=georef_$(whoami)_$(date +%Y%m%d_%H%M%S) --net=host -v $HOME/.cache/matplotlib:/opt/.config/matplotlib --shm-size=16g ghcr.io/ocean-perception/remote_awareness:latest remote_awareness'`

Call `remote_awareness -h` to display the list of commands:

```
Usage: remote_awareness [OPTIONS] COMMAND [ARGS]...

Options:
  -h, --help  Show this message and exit.

Commands:
  acquisition_summary
  correct_images
  decode
  generate_metadata_csv
  inference
  pipeline
  representative_images
  sampling
```

acquisition_summary needs configurtion files, and https://github.com/miquelmassot/remote_awareness/tree/main/config has examples, but 
`find / -name "voyis_strobe_camera.yaml" 2>/dev/null`
`find / -name "smarty200.yaml" 2>/dev/null`
both return nothing.


Images are stored on the voyis system in /data (/dev/sda1 mounted to /data)
On the sparus there is as folder /mnt/voyis that I thought might be pointing to it, but it cannot be accessed ("ls: cannot access '/mnt/voyis/': Too many levels of symbolic links")

It is likely that `remote_awareness pipeline` is the what we need to run, but when run like this (version 1.0.0), it complains "INFO ▸ pipeline needs a configuration file". 

The help (`remote_awareness pipeline -h`) displays
```
INFO ▸ Running remote_awareness version 1.0.0
Usage: remote_awareness pipeline [OPTIONS]

Options:
  -c, --config FILE               Path to the YAML configuration file
  --raw-images-extension TEXT     Extension of the images  [default: png]
  --raw-images-type TEXT          Image type  [default: rgb]
  -d INTEGER                      Image bit depth  [default: 8]
  -r FLOAT                        Downsize the input image size by the ratio
                                  downsize_size = (image_size *
                                  downsize_ratio)  [default: 1.0]
  --calib FILE                    Path to the camera calibration file
  -m, --method TEXT               Correction method  [default:
                                  colour_correction]
  --metric TEXT                   Distance metric  [default: altitude]
  --mean FLOAT                    Desired brightness  [default: 30.0]
  --std FLOAT                     Desired contrast  [default: 7.0]
  --image-mean FILE               Image mean
  --image-std FILE                Image standard deviation
  --attenuation-parameters FILE   Attenuation parameters
  --correction-gains FILE         Correction gains
  --undistort / --no-undistort    Undistort  [default: no-undistort]
  --gamma-correct / --no-gamma-correct
                                  Gamma correct  [default: no-gamma-correct]
  --color-gain-matrix-rgb TEXT    Color gain matrix RGB
  --subtractors-rgb TEXT          Subtractors RGB
  --number-of-images INTEGER      Number of images to sample from the dataset
                                  [default: 1500]
  --interlace / --no-interlace    Interlace the image list (false for sorted
                                  images).   [default: no-interlace]
  --model-path FILE               Path to the trained model
  --use-full-image / --no-use-full-image
                                  Use full image instead of patches  [default:
                                  no-use-full-image]
  --crop-size INTEGER             Crop size  [default: 350]
  --patch-size INTEGER            Patch size  [default: 227]
  --latents-dim INTEGER           Latents dimension  [default: 16]
  --batch-size INTEGER            Batch size  [default: 32]
  --corrected-images-extension TEXT
                                  Extension of the corrected images  [default:
                                  png]
  --num-representative-images INTEGER
                                  Number of representative images to use
                                  [default: 16]
  --num-representative-clusters INTEGER
                                  Number of representative clusters to use
                                  [default: 4]
  -h, --help                      Show this message and exit.
```


Docker command for remote_awareness:
`docker run --rm -it --ipc=private -e USER=$(whoami) -h $HOSTNAME --user $(id -u):$(id -g) --volume $(pwd):/data -v /etc/passwd:/etc/passwd:ro -v /etc/group:/etc/group:ro --name=georef_$(whoami)_$(date +%Y%m%d_%H%M%S) --net=host -v $HOME/.cache/matplotlib:/opt/.config/matplotlib --shm-size=16g remote_awareness_image`


`remote_awareness pipeline`  runs

```
gerenate_metadata_csv
correct _images
sampling
representative_images
```


### Generate metadata CSV
```
Usage: remote_awareness generate_metadata_csv [OPTIONS]

Options:
  -c, --config FILE       Path to the YAML configuration file
  -i, --images DIRECTORY  Path to the images
  -b, --bagfiles FILE     Path to the navigation bagfile
  -o, --output FILE       Output path to the metadata CSV file  [default:
                          metadata.csv]
  -h, --help              Show this message and exit.
```

Mount data folder on Voyis PC:
`mkdir -p ~/data/voyis_data`

`sshfs -o allow_other,IdentityFile=/home/sparus/.ssh/id_rsa tguser@192.168.1.26:/data/data ~/data/voyis_data`

Below does not work unless we modif dockerfile to provide /data_voyis folder
`docker run --rm -it --ipc=private -e USER=$(whoami) -h $HOSTNAME --user $(id -u):$(id -g) -v $(pwd):/data -v ~/data/voyis_data:/data_voyis -v /etc/passwd:/etc/passwd:ro -v /etc/group:/etc/group:ro --name=georef_$(whoami)_$(date +%Y%m%d_%H%M%S) --net=host -v $HOME/.cache/matplotlib:/opt/.config/matplotlib --shm-size=16g ghcr.io/ocean-perception/remote_awareness:latest`
Workaround: run command from / (no need to modify docker alias)

Not sure if we need a config file. A default config file is in the docker image at /opt/remote_awareness/config/smarty200.yaml
(there is another one in ../src/configuration/remote_awareness.yaml but from running the code I think it picks smarty200.yaml by default)

Bag files are on sparus ~/bags/
home/user/data/voyis_data/20241105_162702_smarty200/stills/processed/

The metadata file points to the raw images. However we can use `sed` to modify the paths to point to the processed images.

#### Example on copy on laptop
```
cd ~/Documents

docker run --rm -it --ipc=private -e USER=$(whoami) -h $HOSTNAME --user $(id -u):$(id -g) -v $(pwd):/data -v /etc/passwd:/etc/passwd:ro -v /etc/group:/etc/group:ro --name=georef_$(whoami)_$(date +%Y%m%d_%H%M%S) --net=host -v $HOME/.cache/matplotlib:/opt/.config/matplotlib --shm-size=16g ghcr.io/ocean-perception/remote_awareness:latest \
remote_awareness generate_metadata_csv \
-c /opt/remote_awareness/config/smarty200.yaml \
-i plymouth2024/raw/20241105_151333_smarty200/images/20241105_151333_smarty200/ \
-b plymouth2024/raw/20241105_151333_smarty200/nav/bags/sparus2_2024-11-05-15-15-50_0.bag \
-o metadata.csv

sed -i 's/raw_/processed_/g' metadata.csv && \
sed -i 's/stills\/raw/stills\/processed/g' metadata.csv && \
sed -i 's/.tif/.jpg/g' metadata.csv
```


### Sampling

```
Usage: remote_awareness sampling [OPTIONS]

Options:
  -c, --config FILE             Path to the YAML configuration file
  --csv FILE                    Path to the metadata CSV file
  --number-of-images INTEGER    Number of images to sample from the dataset
                                [default: 1500]
  --interlace / --no-interlace  Interlace the image list (false for sorted
                                images).   [default: no-interlace]
  --output-path PATH            Output folder path
```

#### Example
```
cd ~/Documents

docker run --rm -it --ipc=private -e USER=$(whoami) -h $HOSTNAME --user $(id -u):$(id -g) -v $(pwd):/data -v /etc/passwd:/etc/passwd:ro -v /etc/group:/etc/group:ro --name=georef_$(whoami)_$(date +%Y%m%d_%H%M%S) --net=host -v $HOME/.cache/matplotlib:/opt/.config/matplotlib --shm-size=16g ghcr.io/ocean-perception/remote_awareness:latest \
remote_awareness sampling \
-c /opt/remote_awareness/config/smarty200.yaml \
--csv metadata.csv \
--output-path sampled.csv \
--number-of-images 900
```
Note: number-of-images is not documented. It is set to 1500 by default. If the dataset has fewer images it crashes (I blieve; with the version of the code on Smarty).


### Inference
Note: This is not run in the pipeline. In the pipeline representative_images is run, which also runs inference. I believe it will have a different result every time it is run, so do not mix `inference` results and `representative_images` results (or results from two different runs of `inference` (or `representative_images`), for that matter)
#### Example
```
cd ~/Documents
docker run --rm -it --ipc=private -e USER=$(whoami) -h $HOSTNAME --user $(id -u):$(id -g) -v $(pwd):/data -v /etc/passwd:/etc/passwd:ro -v /etc/group:/etc/group:ro --name=georef_$(whoami)_$(date +%Y%m%d_%H%M%S) --net=host -v $HOME/.cache/matplotlib:/opt/.config/matplotlib --shm-size=16g ghcr.io/ocean-perception/remote_awareness:latest \
remote_awareness inference \
-c /opt/remote_awareness/config/smarty200.yaml \
--metadata-csv sampled.csv \
--model-path /opt/remote_awareness/config/ae_model.pt \
--output-directory inference_output
```

### Representative images

```
Usage: remote_awareness representative_images [OPTIONS]

Options:
  -c, --config FILE               Path to the YAML configuration file
  --output-directory DIRECTORY    Path to the output directory
  --num-representative-images INTEGER
                                  Number of representative images to use
                                  [default: 16]
  --num-representative-clusters INTEGER
                                  Number of representative clusters to use
                                  [default: 4]
```

#### Example
```
cd ~/Documents
docker run --rm -it --ipc=private -e USER=$(whoami) -h $HOSTNAME --user $(id -u):$(id -g) -v $(pwd):/data -v /etc/passwd:/etc/passwd:ro -v /etc/group:/etc/group:ro --name=georef_$(whoami)_$(date +%Y%m%d_%H%M%S) --net=host -v $HOME/.cache/matplotlib:/opt/.config/matplotlib --shm-size=16g ghcr.io/ocean-perception/remote_awareness:latest \
remote_awareness representative_images \
-c /opt/remote_awareness/config/smarty200.yaml \
--output-directory inference_output
```

Problem: it crashes when it does not find the column "imagenumber" in inference_output/latents_float64.csv. But this columnn was not originally written when the file is written in inference.py. This has now been modified in the "develop_adrian" branch.
