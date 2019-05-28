# rkit: Windows Portable Resource Kit
rkit portable: Windows portable Resource Kit folder with UNIX-like commands

This batch will operate in the folder it is placed in, or the folder passed as parameter.

# Presentation
This batch purpose is to create a portable Resource Kit folder with UNIX-like commands for your convenience.
It features mostly command line tools including busybox, SysinternalsSuite, Rkit2003 and 7zip among other things.
Nirsoft tools are mostly GUI and therefore not included but you can easily modify this batch to include them.

## Disclaimer
Many tools included (such as password recovery/sniffer and even Pskill.exe from Microsoft) are considered 
harmful/unwanted by exaggerated/mental AVs/services such as Sophos, and will shoot false positives.
Prepare yourself to explain these alerts to your IT bff.

This batch wil not delete any file on your system other than the one it downloads.

# Execution
## Execution Warning
Warning: starting this batch with ADMIN rights will alter SYSTEM settings. Read carefully what it does.

## Compatibility
This batch *should* be compatible from Windows XP SP3 Pro and beyond.

## Requisites: 
* setx
* powershell
* mklink (will be circumvented at disk cost)

## What is downloaded?
- 7zip 19.00
- gawk
- wget
- busybox
- SysinternalsSuite
- Windows Server 2003 Resource Kit Tools

## What is installed?
+ install 7zip 19.00
+ add 7zip file associations for local user  (/!\ ==> or ALL USERS   if started as ADMIN!)
+ update PATH variable for local user        (/!\ ==> or SYSTEM PATH if started as ADMIN!)

# TODO List
[ ] use 7zip portable instead
[ ] curl
[ ] dig
[ ] detect UNC path because symlink won't work
[ ] Please be my guest
