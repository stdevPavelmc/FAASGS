# Initial installation steps for the accessory tools

As FAASGS relies on some extra tools I will give here a basic guide for each one.

![warning](images/warning.png) **Warning:** all the installation steps mentioned here need root privileges, typically just making a `sudo -i` in the console to gain root is enough.

- **Web server + PHP support**

You need a web server with php installed (at least version 7.x, no MySQL or MariaDB support needed), google has a lot of guides indexed, just google for "install nginx and php in [your-operating-system]"

**RaspiOS/Raspbian users**: follow this [tutorial](https://www.raspberrypi.org/documentation/remote-access/web-server/nginx.md) about how to enable php support for nginx.

**Armbian users**: can follow any tutorial for the flavour of your version (Debian 9 or Ubuntu 20.04) and you will be fine.

- **Predict**

You need to install `predict` the software to make predictions of satellite passes.

For **RaspiOS / Raspbian**:

```sh
sudo apt install predict
```

For **Armbian** you need to compile it from source, you can get it from the [Predict home page](https://www.qsl.net/kd2bd/predict.html).

After installing predict for any distro, you need to do this additional steps to make it run properly:

```sh
sudo -i
mkdir /root/.predict
cd /root/.predict
wget https://raw.githubusercontent.com/kd2bd/predict/master/default/predict.db
wget https://raw.githubusercontent.com/kd2bd/predict/master/default/predict.tle
wget https://raw.githubusercontent.com/kd2bd/predict/master/default/predict.qth
# Next step only if using a Rasberry Pi board
ln -s /root/.predict /home/pi/.predict
```

Then edit the file `predict.qth` with this command `nano /root/.predict/predict.qth` to reflect your location settings, it needs to contain something like this:

```
CO7WT
 21.xxxx
 77.xxxx
 100
```

That's the equivalent for:

- CO7WT (me, use N0CALL or your name without spaces if you are not an amateur radio operator)
- Latitude: 21.xxxx N
- Longitude: 77.xxxx W
- Altitude: 99.908 m (Above mean sea level)

**Watchout!** there is a space in front of the Lat/Lon/Alt parameters, to sign it belongs to CO7WT.

- **WXtoImage**

This wonderful piece of software was deprecated by the original authors but a group of enthusiast keep it alive in the [Restored WXtoImage](https://wxtoimgrestored.xyz/) site.

Just download it here: [WXtoImage deb package for ARM](https://www.wxtoimgrestored.xyz/beta/wxtoimg-armhf-2.11.2-beta.deb) or browse the site for other architectures.

To install it copy it to your SBC computer and run (Debian based distribution):

```sh
sudo dpkg -i wxtoimg-armhf-2.11.2-beta.deb
# [ignore errors if any]
sudo aptitude install -f
# [this will fix any dependency error listed above]
```

### registration of wxtoimg

I provided an example wxtoimgrc file with the public registration included, edit it and set the location and altitude data, then copy it to `/root/.wxtoimgrc`, just modify this part on the file:

```
Ground Station: (user's location: city, country, like: Camaguey, Cuba)
Latitude: (positive North, like: 22.xxx)
Longitude: (negative West, like -77.xxx)
Altitude: (altitude above mean sea level, like: 100)
```

See the file if in doubt.

- **Utilities**

You need at least `git` and `make`, in most linux (including SBCs) you are set by running this:

```sh
sudo apt install git make
```

- **Accurate Time source and timezone**

Yes, the prediction relies on an precise timing, usually you has your SBC/PC connected to the home internet and the OS has all the tools to sync to an internet time server pool, at least Raspbian/RaspiOS and Armbian do.

If you don't has an active internet connection you can use a RTC module on your SBC, see this [tutorial from Adafruit](https://learn.adafruit.com/adding-a-real-time-clock-to-raspberry-pi) to know more. _I'm using this way + the one below._

Or even on extreme cases you can get an GPS module to sync the SBC clock, but that's a lot more trickier.

You need to setup also your timezone, Armbian and RaspiOS has that covered with their own tools (`armbian-config` and `raspi-config`), follow the menu system to get your timezone right.

On all Debian based systems you can do `sudo dpkg-reconfigure tzdata` to accomplish that also.

You are done, get back to the README.md file and continue with the setup.
