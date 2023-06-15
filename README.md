# WingsXI Launcher

Current version of the launcher is avilable [on our website](https://www.wingsxi.com/wings/index.php?page=play): [Direct Link](https://wingsxi.com/dl/launcher/WingsXI-Installer.exe)

## Introduction

The launcher is intended to be installed after the base WingsXI install, though in the future it will orchestrate that as well. This project is to track and make public the launcher's configs for generating the actual launcher using the (licensed) software [Game Launcher Creater Version 3](https://byteboxmedia.support/docs/), then building an installer using the (freeware) software [Install Creator 2](https://www.clickteam.com/install-creator-2).

## Features
 - Custom Icon and Simplified launching of the main Ashita config
  - This allows you to add to Steam much simpler
 - Easy access to FFXI config tools: gamepad and main
 - `Check for Updates` feature is the main reason for using the launcher. This button will do 2 things:
  - Backup your current configs (FFXI `USER` folder as well as all text-based Ashita configs)
  - Check your current files for updates against the `patchlist` defined on the latest version of the Launcher
   - Note that updates are _NOT_ done automatically, and only ever when clicking the button (which performs a backup first)


## Update Process
 - Make changes to launcher, build new
 - Make changes to `patch_input` files, run `CreateInstaller.bat`
 - Generate new patch, incrementing middle value for launcher changes and 3rd value for addon changes
  - E.g. addon changes would bump 1.3.2 -> 1.3.3 and changes to the launcher would bump 1.3.2 -> 1.4.2
 - Sync `patch_output` to web server under a new folder
 - When all data is synced to web server, replace existing `patch_output` folder and update `version.txt` to cause launchers to detect an available update