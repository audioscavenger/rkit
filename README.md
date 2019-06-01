# rkit: Windows Portable Resource Kit
rkit portable: Windows portable Resource Kit folder with UNIX-like commands

This batch will operate in the folder it is placed in, or the folder passed as parameter.


# Presentation
This batch purpose is to create a portable Resource Kit folder with UNIX-like commands for your convenience.
It features mostly command line tools including busybox, SysinternalsSuite, Rkit2003 and 7zip among other things.
Nirsoft tools are mostly GUI and therefore not included but you can easily modify this batch to include them.

## Features
* MSDOS only (plus a bit of powershell to download the first tools)
* Backward compatible down to windows XP
* Auto-select 32 or 64 bits binaries based on your system!
* Does not need ADMIN rights
* Colors! (since Win 10)

## What is downloaded?
- 7zip _19.00_
- curl _7.65_
- dig  _9.15.0_
- gawk _3.1.6-1_
- wget _1.20.3_
- busybox _latest_
- SysinternalsSuite _latest_
- Windows Server 2003 Resource Kit Tools

## What is installed?
+ install 7zip
+ add 7zip file associations for local user  (/!\ ==> or ALL USERS   if started as ADMIN!)
+ update PATH variable for local user        (/!\ ==> or SYSTEM PATH if started as ADMIN!)

## Disclaimer
Many tools included (such as password recovery/sniffer and even Pskill.exe from Microsoft) are considered 
harmful/unwanted by exaggerated/mental AVs/services such as Sophos, and will shoot false positives.
Prepare yourself to explain these alerts to your IT bff.

There is a discussion on the subject here: [antivirus-companies-cause-a-big-headache-to-small-developers](http://blog.nirsoft.net/2009/05/17/antivirus-companies-cause-a-big-headache-to-small-developers/)

This batch wil not delete any file on your system other than the one it downloads.


# Execution

## Execution Warning
Warning: starting this batch with ADMIN rights will alter the SYSTEM PATH value. Read carefully what it does.

### Installation in User mode
1. start it
2. logoff / log back in (to reload the USER PATH environment)
3. enjoy

### Installation in ADMIN
1. start it
2. enjoy


# Compatibility

## Windows version
This batch *should* be compatible down to:
* Windows XP SP3
* Windows Server 2000

* I didn't test it with Vista because it's crap, nobody use that.

## Requisites: 
* setx (included since XP SP3)
* powershell 2.0 (KB for XP/2000: install [Windows Management Framework](https://support.microsoft.com/en-us/help/968929/))
* mklink (included since Seven - will be circumvented on XP/2000 at disk cost)


# TODO List
* [ ] use 7zip portable instead
* [x] curl
* [x] dig
* [ ] detect UNC path because symlink won't work on network folders
* [ ] Please be my guest

Changelog
---------
* 1.1
  * added curl 7.65
  * added dig 9.15.0

* 1.0
  * just tested with XP, Seven and 10
  * found a way to save diskspace with mklink

