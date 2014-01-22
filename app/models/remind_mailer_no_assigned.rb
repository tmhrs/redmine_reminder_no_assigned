class RemindMailerNoAssigned < Mailer
  def self.reminders_no_assigned(options={})
    mins = options[:mins] || 60
    project = options[:project] ? Project.find(options[:project]) : nil
    tracker = options[:tracker] ? Tracker.find(options[:tracker]) : nil

    scope = Issue.open.where("#{Issue.table_name}.assigned_to_id IS NULL" +
            " AND #{Project.table_name}.status = #{Project::STATUS_ACTIVE}" +
            " AND #{Issue.table_name}.created_on <= ?", (Time.now - mins * 60)
            )

    scope = scope.where(:project_id => project.id) if project
    scope = scope.where(:tracker_id => tracker.id) if tracker

    issues_by_project = scope.includes(:status, :project, :tracker).all.group_by(&:project)

    issues_by_project.each do |target_project, issues|
      member_of_project = Member.find_all_by_project_id(target_project.id)
      mail_address_list = []
      member_of_project.each do |member|
        begin
          user = User.find(member.user_id)
          mail_address_list += [user.mail] if user.is_a?(User) && user.active?
        rescue ActiveRecord::RecordNotFound
          ## メンバーにグループが含まれている場合の考慮（何もしない）
          ## ex.<ActiveRecord::RecordNotFound: Couldn't find User with id=5 [WHERE "users"."type" IN ('User', 'AnonymousUser')]>
        end
      end
      mail_address_list.each do |mail_address|
        reminder_no_assigned(target_project, mail_address, issues, mins, tracker).deliver
      end
    end
  end

  def reminder_no_assigned(project, mail_address, issues, mins, tracker)
    set_language_if_valid Setting.default_language
    @issues = issues
    @mins = mins
    @issues_url = url_for(:controller => 'issues', :action => 'index',
                          :set_filter => 1, :project_id => project.id,
                          :tracker_id => (tracker ? tracker.id : nil),
                          :assigned_to_id => '!*', :sort => 'created_on')
    mail :to => mail_address,
      :subject => l(:mail_subject_reminder_no_assigned, :project => project.name, :count => issues.size, :mins => mins)
  end
end
