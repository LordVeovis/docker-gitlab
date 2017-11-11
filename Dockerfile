FROM alpine:3.6

COPY veovis-59b4837b.rsa.pub /etc/apk/keys/

RUN apk upgrade --no-cache && \
    echo -e 'http://alpine.kveer.fr/3.6/main\nhttp://alpine.kveer.fr/3.6/kveer' >> /etc/apk/repositories && \
    apk add --no-cache runit nginx mariadb-client-libs openssh-server \
        git go nodejs yarn redis sudo tzdata icu-libs libre2

ARG GITLAB_SOURCE=https://gitlab.com/gitlab-org/gitlab-ce.git
ARG VERSION=v10.1.3
ARG GITLAB_USER=git
ARG GITLAB_HOME=/home/git/gitlab

RUN apk add --no-cache ruby2.3 ruby2.3-bigdecimal ruby2.3-irb ruby2.3-io-console && \
    gem install bundler --no-ri --no-rdoc --version 1.15.4 && \
    adduser -g Gitlab -s /bin/false -D ${GITLAB_USER} && \
    mkdir /config && \
    install -d -o ${GITLAB_USER} -g ${GITLAB_USER} -m 755 /var/log/gitlab

RUN cd /home/git && \
    sudo -u ${GITLAB_USER} -H git clone ${GITLAB_SOURCE} -b ${VERSION} gitlab && \
    cd ${GITLAB_HOME} && \
    chown -R ${GITLAB_USER} log/ && \
    chown -R ${GITLAB_USER} tmp/ && \
    chmod -R u+rwX,go-w log/ && \
    chmod -R u+rwX tmp/ && \
    chmod -R u+rwX tmp/pids/ && \
    chmod -R u+rwX tmp/sockets/ && \
    sudo -u ${GITLAB_USER} -H mkdir public/uploads/ && \
    chmod 0700 public/uploads && \
    chmod -R u+rwX builds/ && \
    chmod -R u+rwX shared/artifacts/ && \
    chmod -R ug+rwX shared/pages/ && \
    sudo -u ${GITLAB_USER} -H git config --global core.autocrlf input && \
    sudo -u ${GITLAB_USER} -H git config --global gc.auto 0 && \
    sudo -u ${GITLAB_USER} -H git config --global repack.writeBitmaps true

RUN apk add --no-cache -t _build alpine-sdk coreutils go ruby2.3-dev zlib-dev icu-dev libffi-dev cmake mariadb-dev linux-headers libre2-dev && \
    cd ${GITLAB_HOME} && \
    sudo -u ${GITLAB_USER} -H BUNDLE_FORCE_RUBY_PLATFORM=1 bundle install --deployment --without development test postgres aws kerberos && \
    cp config/database.yml.mysql config/database.yml && \
    cp config/gitlab.yml.example config/gitlab.yml && \
    sudo -u ${GITLAB_USER} -H bundle exec rake gitlab:shell:install REDIS_URL=unix:/var/run/redis/redis.sock RAILS_ENV=production SKIP_STORAGE_VALIDATION=true && \
    rm -R /home/git/gitlab-shell/go /home/git/gitlab-shell/go_build && \
    sudo -u ${GITLAB_USER} -H bundle exec rake "gitlab:workhorse:install[/home/git/gitlab-workhorse]" RAILS_ENV=production && \
    rm -R /home/git/gitlab-workhorse/_build && \
    sudo -u ${GITLAB_USER} -H bundle exec rake "gitlab:gitaly:install[/home/git/gitaly]" RAILS_ENV=production && \
    apk del _build

RUN cd ${GITLAB_HOME} && \
    chmod 0700 ${GITLAB_HOME}/tmp/sockets/private && \
    chown ${GITLAB_USER} ${GITLAB_HOME}/tmp/sockets/private && \
    sudo -u ${GITLAB_USER} -H bundle exec rake gettext:pack RAILS_ENV=production && \
    sudo -u ${GITLAB_USER} -H bundle exec rake gettext:po_to_json RAILS_ENV=production && \
    sudo -u ${GITLAB_USER} -H yarn install --production --pure-lockfile && \
    sudo -u ${GITLAB_USER} -H bundle exec rake gitlab:assets:compile RAILS_ENV=production NODE_ENV=production && \
    rm ${GITLAB_HOME}/config/secrets.yml && \
    rm ${GITLAB_HOME}/config/database.yml && \
    rm ${GITLAB_HOME}/config/gitlab.yml

COPY docker-entrypoint.sh /
COPY services /etc/sv
COPY kveer.rake "${GITLAB_HOME}"/lib/tasks

VOLUME [ "${GITLAB_HOME}/public/uploads", "${GITLAB_HOME}/builds", "${GITLAB_HOME}/shared/artifacts", "${GITLAB_HOME}/shared/public" ]
ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD [ "runsvdir", "-P", "/etc/sv" ]