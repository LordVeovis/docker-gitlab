![nginx 1.12](https://img.shields.io/badge/nginx-1.12-brightgreen.svg) [![License: GPL v3](https://img.shields.io/github/license/LordVeovis/docker-gitlab.svg)](https://www.gnu.org/licenses/gpl-3.0) [![](https://img.shields.io/docker/pulls/veovis/gitlab.svg)](https://hub.docker.com/r/veovis/gitlab/ 'Docker Hub') [![](https://img.shields.io/docker/build/veovis/gitlab.svg)](https://hub.docker.com/r/veovis/gitlab/builds/ 'Docker Hub')

# About

This is a docker container for Gitlab build around Alpine Linux for compacity as an alternative to the fat official Omnibus package.

# Technical stack

* alpine 3.7
* nginx 1.12
* ruby 2.3.5
* git 2.13.5
* go 1.8.4
* dillon's cron 4.5

* Gitlab 10.2.4
* gitlab Shell 5.9.3
* sidekiq 5.0.4

# Configuration

The first time the container is launched, it initializes the /config directory, then stops itself to let you review all settings according to your environment. This directory *MUST* be mapped to keep the same configuration of your gitlab environment, including the generated secrets, through the updates.

## Environment variables

* TIMEZONE: the desired timezone. Example: Europe/Paris
* GITLAB_ROOT_PASSWORD: password of the first gitlab user if it does not exists. This parameter is only used the first time the database is initialized.
* GITLAB_HOST: the schema and hostname where the website can be reachable. Example: https://gitlab.kveer.fr
* RAILS_ENV: production
* DATABASE_URL: connection string to the database. For now, only mysql is supported. Example: mysql2://gitlab_user:gitlab_pwd@mysql/gitlab
* GITLAB_EMAIL_FROM: Gitlab will sent email with this email as a sender. Example: gitlab@kveer.fr
* GITLAB_EMAIL_DISPLAY_NAME: The display name of the sender. Example: Gitlab Kveer
* GITLAB_EMAIL_SUBJECT_PREFIX: The object prefix for generated emails. Example: "[gitlab]"
* GITLAB_UNICORN_MEMORY_MAX: The maximum amount of ram unicorn can use. Example: 128M

## Volumes

* /config: contains all configuration of gitlab


