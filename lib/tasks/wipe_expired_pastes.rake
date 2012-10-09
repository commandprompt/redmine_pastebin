desc 'Clean up expired pastes.'

namespace :redmine do
  namespace :pastes do
    task :clean => :environment do
      Paste.wipe_all_expired
    end
  end
end
