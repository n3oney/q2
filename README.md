# q2

A repo with my Qidi Q2 klipper setup.

## What does this do?

It pulls patched Kalico from [https://github.com/n3oney/qidi-q2-klipper](n3oney/qidi-q2-klipper), adds extras to it (e.g. HappyHare, Shaketune, autopa) and sets up a release.
It requires katapult (guide in repo linked above), and lets you even set up automatic updates!

## Setup

1. Back up your printer's `~/klipper`
2. Stop klipper (`sudo systemctl stop klipper klipper-mcu`) and remove the old directory (`rm -rf ~/klipper`)
3. Download the latest release's `q2.zip` onto the printer. Extract it as `klipper` (`unzip q2.zip -d klipper`)
4. Restart services (`sudo systemctl start klipper klipper-mcu`).
5. Wait. This might take a minute, because the printer recompiles native helpers on klipper's first start.

## Auto update

1. Set up a new systemd service for the updater, called, for example q2:

```sh
# put this in /etc/systemd/system/q2.service

[Unit]
Description=Automatic firmware flasher

[Service]
Type=oneshot
User=mks
WorkingDirectory=/home/mks/klipper

ExecStartPre=+/usr/bin/systemctl stop klipper.service klipper-mcu.service

ExecStart=/usr/bin/bash /home/mks/klipper/scripts/flash-mcus.sh

ExecStartPost=+/usr/bin/systemctl start klipper.service klipper-mcu.service

TimeoutStartSec=300
```

2. Let moonraker restart that service:

```sh
echo q2 >> ~/printer_data/moonraker.asvc
```

3.

```sh
sudo systemctl daemon-reload
```

4. Add the update-manager entry to your moonraker.conf

```sh
[update_manager q2]
type: zip
channel: stable
repo: n3oney/q2
path: ~/klipper
virtualenv: /home/mks/klippy-env
requirements: scripts/klippy-requirements.txt
managed_services: q2
```

5. Restart moonraker, and you're done. You can update from the update manager. This will not only update the linux section of klipper, but also automatically flash all the MCUs. Yay!
