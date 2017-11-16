# PackerArchLinux
Use this command within the directory to construct a basic install of Arch Linux using VirtualBox:

$packer build linux_from_scratch.json

Dependencies:
Packer, VirtualBox, Must change the path of the "iso_location" in the file linux_from_scratch.json to either the path on your local machine where you have an ArchLinux iso or an http path where one is located.
