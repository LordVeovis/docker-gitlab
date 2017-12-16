#!/bin/sh

# setting the timezone
if [ "x$TIMEZONE" != 'x' -a -f /usr/share/zoneinfo/"$TIMEZONE" ]; then
    cp /usr/share/zoneinfo/$TIMEZONE /etc/localtime
    echo "$TIMEZONE" >> /etc/timezone
fi

# disabling MPROTECT on grsec kernels
# https://github.com/moby/moby/issues/35699
[ -d /proc/sys/kernel/pax/ ] && paxmark -m /usr/bin/ruby

conf_dir=/config
gitlab_home=/home/git/gitlab

[ ! -d /etc/default ] && mkdir /etc/default

cd "$gitlab_home"

if [ -d "$conf_dir" ]; then
    uninitialized_confdir=0

    if [ ! -f "$conf_dir"/gitlab.default ]; then
        uninitialized_confdir=1
        cp "$gitlab_home"/lib/support/init.d/gitlab.default.example "$conf_dir"/gitlab.default
    fi
    [ -L /etc/default/gitlab ] || ln -fs "$conf_dir"/gitlab.default /etc/default/gitlab

    if [ ! -f "$conf_dir"/database.yml ]; then
        uninitialized_confdir=1
        cp "$gitlab_home"/config/database.yml.mysql "$conf_dir"/database.yml
    fi
    [ -L "$gitlab_home"/config/database.yml ] || ln -fs "$conf_dir"/database.yml "$gitlab_home"/config/database.yml
    
    if [ ! -f "$conf_dir"/gitlab.yml ]; then
        uninitialized_confdir=1
        cp "$gitlab_home"/config/gitlab.yml.example "$conf_dir"/gitlab.yml
    fi
    [ -L "$gitlab_home"/config/gitlab.yml ] || ln -sf "$conf_dir"/gitlab.yml "$gitlab_home"/config/gitlab.yml

    if [ ! -f "$conf_dir"/secrets.yml ]; then
        uninitialized_confdir=1
        sudo -u git -H bundle exec rake gitlab:shell:generate_secrets RAILS_ENV=production
        mv "$gitlab_home"/config/secrets.yml.example "$conf_dir"/secrets.yml
        mv "$gitlab_home"/.gitlab_shell_secret "$conf_dir"/gitlab_shell_secret
    fi
    [ -L "$gitlab_home"/config/secrets.yml ] || ln -fs "$conf_dir"/secrets.yml "$gitlab_home"/config/secrets.yml
    [ -L "$gitlab_home"/.gitlab_shell_secret ] || ln -fs "$conf_dir"/gitlab_shell_secret "$gitlab_home"/.gitlab_shell_secret

    if [ ! -f "$conf_dir"/unicorn.rb ]; then
        uninitialized_confdir=1
        cp "$gitlab_home"/config/unicorn.rb.example "$conf_dir"/unicorn.rb
    fi
    [ -L "$gitlab_home"/config/unicorn.rb ] || ln -sf "$conf_dir"/unicorn.rb "$gitlab_home"/config/unicorn.rb

    if [ ! -f "$conf_dir"/rack_attack.rb ]; then
        uninitialized_confdir=1
        cp "$gitlab_home"/config/initializers/rack_attack.rb.example "$conf_dir"/rack_attack.rb
    fi
    [ -L "$gitlab_home"/config/initializers/rack_attack.rb ] || ln -sf "$conf_dir"/rack_attack.rb "$gitlab_home"/config/initializers/rack_attack.rb

    if [ ! -f "$conf_dir"/resque.yml ]; then
        uninitialized_confdir=1
        cp "$gitlab_home"/config/resque.yml.example "$conf_dir"/resque.yml
    fi
    [ -L "$gitlab_home"/config/resque.yml ] || ln -sf "$conf_dir"/resque.yml "$gitlab_home"/config/resque.yml

    if [ ! -f "$conf_dir"/gitlab-shell-config.yml ]; then
        uninitialized_confdir=1
        cp "$gitlab_home"/../gitlab-shell/config.yml.example "$conf_dir"/gitlab-shell-config.yml
    fi
    [ -L "$gitlab_home"/../gitlab-shell/config.yml ] || ln -sf "$conf_dir"/gitlab-shell-config.yml "$gitlab_home"/../gitlab-shell/config.yml

    if [ ! -f "$conf_dir"/gitaly-config.toml ]; then
        uninitialized_confdir=1
        cp /etc/gitlab/gitaly/config.toml.example "$conf_dir"/gitaly-config.toml
    fi
    [ -L etc/gitlab/gitaly/config.toml ] || ln -sf "$conf_dir"/gitaly-config.toml /etc/gitlab/gitaly/config.toml

    if [ ! -f "$conf_dir"/nginx-gitlab ]; then
        uninitialized_confdir=1
        cp "$gitlab_home"/lib/support/nginx/gitlab "$conf_dir"/nginx-gitlab
    fi
    [ -L /etc/nginx/conf.d/gitlab.conf ] || ln -sf "$conf_dir"/nginx-gitlab /etc/nginx/conf.d/gitlab.conf

    if [ $uninitialized_confdir == 1 ]; then
        echo "Gitlab has not been configured. Please configure it now before restarting again the container."
        return 0
    fi

    if [ ! -d "$conf_dir"/ssh ] || [ `ls /config/ssh/ | wc -l` == 0 ]; then
        mkdir "$conf_dir"/ssh
        ssh-keygen -A
        mv /etc/ssh/ssh_host_* "$conf_dir"/ssh
    fi
    cp -d /config/ssh/ssh_host_* /etc/ssh/
    chmod 400 /etc/ssh/ssh_host_*

    [ -f "$conf_dir"/authorized_keys ] || touch "$conf_dir"/authorized_keys
    [ -L "$gitlab_home"/../.ssh/authorized_keys ] || mkdir -p "$gitlab_home"/../.ssh && ln -sf "$conf_dir"/authorized_keys "$gitlab_home"/../.ssh/authorized_keys
fi

[ "$AUTO_UPDATE" == '1' ] && sudo -u git -H bundle exec rake db:migrate RAILS_ENV=production

# print environmental informations
sudo -u git -H bundle exec rake gitlab:env:info RAILS_ENV=production

exec $@