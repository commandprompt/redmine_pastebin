namespace :redmine do
  namespace :pastes do
    desc 'Clean up expired pastes'
    task :clean => :environment do
      Paste.wipe_all_expired
    end
  end
end
