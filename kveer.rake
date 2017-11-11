namespace :gitlab do
  namespace :shell do
      desc "GitLab | Generates the secrets.yml file"
      task :generate_secrets, [:repo] => :environment do |t, args|
        warn_user_is_not_gitlab

        Gitlab::Shell.ensure_secret_token!
      end
  end
end