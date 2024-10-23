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

The 