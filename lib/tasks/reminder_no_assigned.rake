desc <<-END_DESC
Available options:
  * mins     => number of mins to remind about (defaults to 60)
  * tracker  => id of tracker (defaults to all trackers)
  * project  => id or identifier of project (defaults to all projects)
  * users    => comma separated list of user/group ids who should be reminded

Example:
  rake redmine:send_reminders_no_assigned mins=60 RAILS_ENV="production"
END_DESC

namespace :redmine do
  task :send_reminders_no_assigned => :environment do
    options = {}
    options[:mins] = ENV['mins'].to_i if ENV['mins']
    options[:project] = ENV['project'] if ENV['project']
    options[:tracker] = ENV['tracker'].to_i if ENV['tracker']

    Mailer.with_synched_deliveries do
      RemindMailerNoAssigned.reminders_no_assigned(options)
    end
  end
end
