#!/bin/sh

# this script allow updating the /config/authorized_keys files
# we cannot directly make a symlink from /home/git/.ssh/authorized_keys to /config/authorized_keys as the permission would be too open for openssh to accept it

cp /home/git/.ssh/authorized_keys /config/authorized_keys