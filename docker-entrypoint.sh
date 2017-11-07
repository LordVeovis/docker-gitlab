#!/bin/sh

# setting the timezone
cp /usr/share/zoneinfo/$TIMEZONE /etc/localtime
echo "$TIMEZONE" >> /etc/timezone

conf_dir=/config
gitlab_home=/home/git/gitlab

if [ ! -f "$conf_dir"/gitlab.default ]; then
    cp "$gitlab_home"/lib/support/init.d/gitlab.default.example "$conf_dir"/gitlab.default
    ln -fs "$conf_dir"/gitlab.default /etc/default/gitlab
fi



exec runsvdir -P /etc/sv