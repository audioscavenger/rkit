## rkit: Table of Contents
- [rkit Windows Portable Resource Kit](#rkit-Windows-Portable-Resource-Kit)
- [Presentation](#Presentation)
  - [Features](#Features)
  - [What is Downloaded?](#What-is-Downloaded)
  - [What is Installed?](#What-is-Installed)
  - [What is Modified?](#What-is-Modified)
  - [Disclaimer About Anti-Virus Warnings](#Disclaimer-About-Anti-Virus-Warnings)
- [Installation](#Installation)
  - [Installation Warning](#Installation-Warning)
  - [Installation in USER mode](#Installation-in-USER-mode)
  - [Installation in ADMIN mode](#Installation-in-ADMIN-mode)
  - [Uninstall](#Uninstall)
- [Compatibility](#Compatibility)
  - [Windows version](#Windows-version)
  - [Pre-Requisites](#Pre-Requisites)
- [TODO List](#TODO-List)
- [See Also](#See-Also)
- [License (is GNU GPL3)](#License-is-GNU-GPL3)

# rkit Windows Portable Resource Kit
rkit portable: Windows portable Resource Kit folder with UNIX-like commands

Do you use command Prompt that often? Are you a shortcut nerd?
Wouldn't that be awesome to have access to the most powerful command line tools in the world aka `Unix tools` in Windows??

Look no more, here it is. A simple batch that downloads all the good stuff for you without the need to install ANYTHING at all.

# Presentation
This batch purpose is to create a portable Resource Kit folder with UNIX-like commands for your convenience.
This batch will operate in the folder it is placed in, or the folder passed as parameter.
It features mostly command line tools including busybox, SysinternalsSuite, Rkit2003 and 7zip among other things.
Nirsoft tools are mostly GUI and therefore commented by default but you can easily modify this batch to include them and more.

## Features
* MSDOS only (plus a bit of powershell to download the first tools)
* Backward compatible down to windows XP SP3
* Auto-select 32 or 64 bits binaries based on your system!
* Does not need ADMIN rights
* Colors! (since Win 10)
* DLL compression with UPX

## What is downloaded?
- [x] 7zip _19.00_
- [x] apache benchmark _2.4.39_
- [x] blat mail _3.2.19_
- [x] busybox _latest_
- [x] curl _7.65_
- [x] dig  _9.15.0_
- [x] dirhash _latest_
- [x] file _5.03_
- [x] gawk _3.1.6-1_
- [x] mailsend-go _1.0.4_
- [x] netcat _1.1.1_
- [x] openSSL _1.1.1c_
- [x] SysinternalsSuite _latest_
- [x] tcpdump _latest_
- [x] upx _3.95w_
- [x] XMLStarlet _latest_
- [x] wget _1.20.3_
- [x] Windows Server 2003 Resource Kit Tools

## What is installed?
+ install 7zip

## What is Modified?
+ add/update 7zip file associations for local user  (/!\ ==> or ALL USERS   if started as ADMIN!)
+ update PATH variable for local user (prepend)     (/!\ ==> or SYSTEM PATH if started as ADMIN! (append))

## Disclaimer About Anti-Virus Warnings
Many tools included (such as password recovery/sniffer and even Pskill.exe from Microsoft) are considered 
harmful/unwanted by exaggerated/mental AVs/services such as Sophos, and will shoot false positives.
Prepare yourself to explain these alerts to your IT bff.

There is a discussion on the subject here: [antivirus-companies-cause-a-big-headache-to-small-developers](http://blog.nirsoft.net/2009/05/17/antivirus-companies-cause-a-big-headache-to-small-developers/)

This batch wil not delete any file on your system other than the one it downloads.

Long story short, you *will* receive AV false alarms on these files:
- nc.exe
- PStools:
  - PsExec.exe
  - PsExec64.exe
  - psfile.exe
  - psfile64.exe
  - PsGetsid.exe
  - PsGetsid64.exe
  - PsInfo.exe
  - PsInfo64.exe
  - pskill.exe
  - pskill64.exe
  - pslist.exe
  - pslist64.exe
  - PsLoggedon.exe
  - PsLoggedon64.exe
  - pspasswd.exe
  - pspasswd64.exe
  - psping.exe
  - psping64.exe
  - PsService.exe
  - PsService64.exe
  - psshutdown.exe
  - pssuspend.exe
  - pssuspend64.exe
  - psloglist.exe
  - psloglist64.exe
- nirsoft:
  - ChromePass.exe
  - Dialupass.exe
  - iepv.exe
  - mailpv.exe
  - mspass.exe
  - netpass.exe
  - PasswordFox.exe
  - PstPassword.exe
  - WebBrowserPassView.exe

# Installation

## Installation Warning
Warning: starting this batch with ADMIN rights will alter the SYSTEM PATH value. Read carefully what it does.

## Installation in USER mode
1. start it
2. logoff / log back in (to reload the USER PATH environment)
3. enjoy

## Installation in ADMIN mode
1. start it
2. enjoy

## Uninstall
1. Delete the folder with everything inside
2. enjoy


# Compatibility

## Windows version
This batch *should* be compatible down to:
* Windows XP SP3
* Windows Server 2000
* I didn't test it with Vista because it's crap, nobody use that.

Refer to [KB article 317949](http://support.microsoft.com/default.aspx?scid=kb;en-us;317949) if you need the gory details exactly why you must NEVER run the original Windows XP or SP1.

## Pre-Requisites
* setx (included since XP SP3)
* powershell 2.0 (KB for XP/2000: install [Windows Management Framework](https://support.microsoft.com/en-us/help/968929/))
* mklink (included since Seven - will be circumvented on XP/2000 at disk cost)


# TODO List
* [x] file magic
* [x] ab
* [x] openssl
* [x] curl
* [x] dig
* [x] base64 encore/decode
* [x] upx
* [x] XMLStarlet
* [x] dirhash
* [x] tcpdump
* [ ] JAD
* [ ] finddupe
* [ ] findhash
* [ ] hex2text
* [x] mailsend-go
* [ ] RsaConverter
* [x] netcat
* [ ] use 7zip portable instead
* [ ] Perl
* [ ] detect UNC path because symlink won't work on network folders
* [ ] blat mail 32 or 64 (only 64 now, but is it useful since )
* [ ] Please be my guest

# See Also

Linux/UX ultra complete profile [exploit](https://github.com/audioscavenger/exploit)

# License (is GNU GPL3)

                    GNU GENERAL PUBLIC LICENSE
                       Version 3, 29 June 2007

 Copyright (C) 2007 Free Software Foundation, Inc. <https://fsf.org/>
 Everyone is permitted to copy and distribute verbatim copies
 of this license document, but changing it is not allowed.

install-rkit-portable  Copyright (C) <2019>  <audioscavenger@it-cooking.com>
This program comes with ABSOLUTELY NO WARRANTY;
This is free software, and you are welcome to redistribute it
under certain conditions; https://www.gnu.org/licenses/gpl-3.0.html
