# Fully Automatic Amateur Satellite Ground Station

A setup to build an amateur satellite ground stations that can tune, record and generate images for APT weather satellites and record audio from Amateur ones.

This is the software recipe, in the hardware part I used an [Orange Pi Prime Board](http://www.orangepi.org/OrangePiPrime/) (Similar to Raspi 3B+) with [Armbian](https://www.armbian.com/) but you can use any [Single Board Computer](https://en.wikipedia.org/wiki/Single-board_computer), including Raspberry Pis, O-droids and even a normal PC or Server.

The only advice is to use one with a multiple cores and at least 1GB of RAM as some task are resource intensive.

A sample of the main view:

![Main view of the page](images/main.png)

A sample view of a pass of PO-101 DIWATA-2B (FM sat):

![Main view of the page](images/sat.png)

A sample view of a pass of a NOAA weather APT satellite:

![Main view of the page](images/sat_noaa.png)

## Inspiration

This project is inspired and heavily based on the work of [Luick Klippel](https://github.com/luickk) and his work on his [NOAA Satellite Station](https://github.com/luickk/noaa_satellite_ground_station) repository.

## Features

- Web interface to see the next passes, the recorded ones, and details for it.
- Receive any satellite in FM mode *(no SSB by now, as we can't do doppler correction yet)*
- Record the satellite pass and keep the audio for later.
  - APT WX audio is preserved in wav format and 22050 hz of sampling *(the format [wximage](https://wxtoimgrestored.xyz/) needs to work with)*
  - FM audio satellites is preserved in .mp3 mode but with high quality settings, and other tricks:
    - The spectrogram of the audio is embedded as album art *(see below)*.
    - The pass details and receiving station data are stored in the mp3 tags.
- Automatic decode APT images from WX sats (NOAA 15, 18 and 19)
- For the voice FM sats we craft a spectrogram and embed the metadata of the pass on the image.
- **NEW** selection for audio processing schema: streamed or step by step (first is good on fast or dedicated systems, the former on slow or multitasking ones) see users.conf while installing for more details.

## Future features?

- Rotor control via [Hamlib](https://hamlib.github.io/).
- Doppler control to allow for SSB/CW. 
- New UI (web) to allow for user authentication, etc.

## Initial setup before the install

This soft uses a few other apps to work and they need some configuration, take a peek on the [initial setup page](INITIAL_SETUP.md) to know the details.

## Installation

The installation is split on tree phases and all them depends on the initial setup that must be done before.

### Phase 1: Install the soft

- Login in your into SBC and clone this repository `git clone https://github.com/stdevPavelmc/FAASGS`.
- Change to the created folder `cd FAASGS`.
- Gain root access via `sudo -i`
- Run configuration steps `make cconf`.

### Phase 2: Configuring the soft

After the configure step you need to modify your local data, you callsign (use N0NE if you are not a ham radio operator), name, locator (use [this tool](https://www.iz3mez.it/maps.google/ww-loc.html) if you are in doubt), coordinates (use locator tool to check the coordinates too), QTH and the satellites you want to capture.

Just go to `/etc/sat_data` and edit a file named `user.conf` with the command `sudo nano user.conf` to fill your data.

You will find a proxy setting there to, if you don't use a proxy just leave it as is, if you use a proxy then follow the comments.

Next step is to select the satellites you want to monitor, the file is named `sats.json` and it has a very common web format, you can add or remove satellites as your need.

Use `sudo nano sats.json` to edit the file, it came by default with all the working NOAA satellites and the working VHF ones, but if you have a dual-band antenna you can introduce some UHF FM sats also.

Please note that the satellites has a name and a nickname, the name refers to the one that appears in the TLE file and the nickname is a friendly name for us (and must not contain spaces, parenthesis, slashes, etc)

### Phase 3: test and make the soft permanent

- Run install script `make install`.
- Execute it by hand to check if all works `sats.sh`.
  -  Go to your IP address and check this:
    - Your personal data is shown on the header of the page.
    - There is some data on the 'Next Satellites Passes' panel.
- If all gone ok, run the schedule script to make it run for good `make permanent`

And you are done.

## Upgrading

This software is designed to be upgradeable with little efforts, just follow this steps:

- Login into your SBC and change to the folder you cloned the repository in the past.
- Gain root access via `sudo -i`
- Update the software with this command `git pull` if there is an update you will be notified about the files that has changed.
  - If you get a warning about it can merge the data because there are some locally modified files, just do this `git reset --hard` that will reset the tree from local changes then repeat the `git pull`. 
- Clean the workspace with this command `make clean`
- Make a backup of your user settings `cp /etc/sat_data/user.conf ~/`
- Install the new version of the software `make install`.
- Review and update the file `/etc/sat_data/user.conf` from your backup in `~/user.conf`, as some times new options are added, if you simply overwrite the new with the old you may lose the new options)
- Test it: run on the console `sats.sh` and you must see the schedule for upcoming passes.
- Make it permanent with `make permanent`.

## Removing

If you need to remove the software there is a command for that `make remove`, but all the collected data will be preserved in the `/var/www/html/sat` folder, you will be warned about it.

## A word about the RF part: Antennas!

I have not spoken about antennas and RF in this document because that relies on your expertice, I will mentioned my experience with some and I trust your internet skills to find them

- A 2m J-pole: normal for voice FM sats, bad for APT images (the image of PO-101 above was taken with just a  J-pole + 12m of RG-8X)
- A horizontal 120 degrees V for APT satellites (137 Mhz): better for APT, regular-to-bad for voice FM satellites
- A 1/4 wave 2m ground plane (120 degrees elements) regular for 2m voice, regular for APT and regular-good for 70cm sats (yes, it works on 70cm too)
- The mentioned V + a custom VHF wide LNA (about +8 dB on 137 and 145 Mhz): very good for APT, normal-to-good for voice FM sats *(actual antenna I'm using now)*

As usual, the higher and un-obstructed view for the antenna the better, also for coax: top quality ones and as short as possible.

## RTL-SDR Calibration

Almost all RTL-SDR dongles has a clock source deviation from the desired frequency (even the ones that advertise a TXCO with `0,5 ppm error`, it's small but is there), that deviation is measured in ppm (parts per million) and is particular of each device.

The FM mode (mostly used for now) is not very picky with an error of a few kHz (and we have doppler that drift the signal continuously), but as many of you may want to use the ppm correction there is an option in the `user.conf` file to set your device ppm error.

### How to calculate the ppm error of my RTL-SDR?

There is a few good sources of info out there, here list some of them:

- Get ballpark values with [this method](https://davidnelson.me/?p=371), let it run for a few minutes and left the PC alone, use the value after `cumulative PPM:`
- Calculate it manually against a FM commercial station in the 88-108 MHz band, see [this video](https://www.youtube.com/watch?v=gFXMbr1dgng), pick one with people chatting as you will see the center peak better; that will give you a best that a ballpark value.
- Get a very accurate measurement by using [this extra tool](http://www.satsignal.eu/raspberry-pi/acars-decoder.html), seek to the **Using Kalibrate** and follow the instructions for Linux or Windows.

## This is FREE SOFTWARE!

Free as in freedom, no payment are needed, see the LICENCE file for details.

If this is software is of any utility to you; please consider to make a donation to keep me improving it, see [Contributing](Contributing.md) file for details.

## Contributing

You can improve the software, appoint bugs or fails, donate equipment or money, top up my cell phone, or just share your impressions on social media; details for all of that in the [Contributing](Contributing.md) file.

Any kind of contribution is welcomed.
