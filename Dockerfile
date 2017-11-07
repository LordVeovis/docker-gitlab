FROM alpine:3.6

ARG GITLAB_SOURCE=https://gitlab.com/gitlab-org/gitlab-ce.git
ARG VERSION=10-1-stable

COPY veovis-59b4837b.rsa.pub /etc/apk/keys/
COPY docker-entrypoint.sh /

RUN echo -e 'http://alpine.kveer.fr/3.6/main\nhttp://alpine.kveer.fr/3.6/kveer' >> /etc/apk/repositories && \
    apk add --no-cache runit nginx \
        git go nodejs yarn redis sudo tzdata

RUN apk add --no-cache ruby2.3 ruby2.3-bigdecimal ruby2.3-irb ruby2.3-io-console && \
    gem install bundler --no-ri --no-rdoc --version 1.15.4 && \
    adduser -g Gitlab -s /bin/false -D git && \
    mkdir /config

RUN cd /home/git && \
    sudo -u git -H git clone ${GITLAB_SOURCE} -b ${VERSION} gitlab && \
    cd gitlab && \
    chown -R git log/ && \
    chown -R git tmp/ && \
    chmod -R u+rwX,go-w log/ && \
    chmod -R u+rwX tmp/ && \
    chmod -R u+rwX tmp/pids/ && \
    chmod -R u+rwX tmp/sockets/ && \
    sudo -u git -H mkdir public/uploads/ && \
    chmod 0700 public/uploads && \
    chmod -R u+rwX builds/ && \
    chmod -R u+rwX shared/artifacts/ && \
    chmod -R ug+rwX shared/pages/ && \
    sudo -u git -H git config --global core.autocrlf input && \
    sudo -u git -H git config --global gc.auto 0 && \
    sudo -u git -H git config --global repack.writeBitmaps true

RUN apk add -t _build alpine-sdk coreutils go ruby2.3-dev zlib-dev icu-dev libffi-dev cmake mariadb-dev linux-headers libre2-dev && \
    cd /home/git/gitlab && \
    sudo -u git -H BUNDLE_FORCE_RUBY_PLATFORM=1 bundle install --deployment --without development test postgres aws kerberos && \
    cp config/database.yml.mysql config/database.yml && \
    cp config/gitlab.yml.example config/gitlab.yml && \
    sudo -u git -H bundle exec rake gitlab:shell:install REDIS_URL=unix:/var/run/redis/redis.sock RAILS_ENV=production SKIP_STORAGE_VALIDATION=true && \
    rm -R /home/git/gitlab-shell/go /home/git/gitlab-shell/go_build && \
    sudo -u git -H bundle exec rake "gitlab:workhorse:install[/home/git/gitlab-workhorse]" RAILS_ENV=production && \
    rm -R /home/git/gitlab-workhorse/_build && \
    sudo -u git -H bundle exec rake "gitlab:gitaly:install[/home/git/gitaly]" RAILS_ENV=production && \
    chmod 0700 /home/git/gitlab/tmp/sockets/private && \
    chown git /home/git/gitlab/tmp/sockets/private && \
    sudo -u git -H bundle exec rake gettext:pack RAILS_ENV=production && \
    sudo -u git -H bundle exec rake gettext:po_to_json RAILS_ENV=production && \
    sudo -u git -H yarn install --production --pure-lockfile && \
    sudo -u git -H bundle exec rake gitlab:assets:compile RAILS_ENV=production NODE_ENV=production && \
    apk del _build

COPY services /etc/sv
ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD [ "runsvdir", "-P", "/etc/sv" ]