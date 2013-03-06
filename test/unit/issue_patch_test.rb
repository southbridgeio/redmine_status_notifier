# encoding: utf-8

require File.expand_path('../../test_helper', __FILE__)

class IssuePatchTest < ActiveSupport::TestCase

  fixtures :issues, :issue_statuses, :projects, :trackers, :projects_trackers,
           :enumerations, :users, :roles, :members, :member_roles

  def setup
    urgent_priority_name = if Setting['plugin_redmine_status_notifier']['critical_priority']
                             Setting['plugin_redmine_status_notifier']['critical_priority'].first
                           else
                             Setting['plugin_redmine_status_notifier']['critical_priority'] = [] << 'Alarm!'
                             'Alarm!'
                           end
    @urgent_priority = IssuePriority.new(name: urgent_priority_name)
    @user = User.find(1)
    User.current = @user
    @project = Project.find(1)
    EnabledModule.create(project: @project, name: 'Отправка уведомлений об авариях')
  end

  def test_create_urgent_issue
    Issue.any_instance.expects(:send_urgent_notification)
    Issue.create(subject: 'Some issue subject', priority: @urgent_priority, project: @project,
                 tracker: @project.trackers.first, author: @user, status: IssueStatus.default)
  end

  def test_create_not_urgent_issue
    Issue.any_instance.expects(:send_urgent_notification).never
    Issue.create(subject: 'Some issue subject', priority: IssuePriority.where(position: 1).first, project: @project,
                 tracker: @project.trackers.first, author: @user, status: IssueStatus.default)
  end

  def test_create_urgent_issue_without_permission
    user_without_permission = User.find(2)
    User.current = user_without_permission
    Issue.any_instance.expects(:send_urgent_notification).never
    Issue.create(subject: 'Some issue subject', priority: @urgent_priority, project: @project,
                 tracker: @project.trackers.first, author: user_without_permission, status: IssueStatus.default)
  end

  def test_set_urgent_status_to_issue
    issue = Issue.create(subject: 'Some issue subject', priority: IssuePriority.where(position: 1).first, project: @project,
                        tracker: @project.trackers.first, author: @user, status: IssueStatus.default)
    issue.expects(:send_urgent_notification)
    issue.priority = @urgent_priority
    issue.save
  end

  def test_set_not_urgent_status_to_issue
    issue = Issue.create(subject: 'Some issue subject', priority: IssuePriority.where(position: 1).first, project: @project,
                        tracker: @project.trackers.first, author: @user, status: IssueStatus.default)
    issue.expects(:send_urgent_notification).never
    issue.priority = IssuePriority.where(position: 2).first
    issue.save
  end

  def test_close_urgent_issue
    issue = Issue.create(subject: 'Some issue subject', priority: @urgent_priority, project: @project,
                         tracker: @project.trackers.first, author: @user, status: IssueStatus.default)
    issue.expects(:send_urgent_notification)
    issue.status = IssueStatus.where(is_closed: true).first
    issue.save
  end

  def test_close_not_urgent_issue
    issue = Issue.create(subject: 'Some issue subject', priority: IssuePriority.where(position: 1).first, project: @project,
                         tracker: @project.trackers.first, author: @user, status: IssueStatus.default)
    issue.expects(:send_urgent_notification).never
    issue.status = IssueStatus.where(is_closed: true).first
    issue.save
  end

  def test_reopen_urgent_issue
    issue = Issue.create(subject: 'Some issue subject', priority: @urgent_priority, project: @project,
                         tracker: @project.trackers.first, author: @user, status: IssueStatus.where(is_closed: true).first)
    issue.expects(:send_urgent_notification)
    issue.status = IssueStatus.default
    issue.save
  end

  def test_reopen_not_urgent_issue
    issue = Issue.create(subject: 'Some issue subject', priority: IssuePriority.where(position: 1).first, project: @project,
                         tracker: @project.trackers.first, author: @user, status: IssueStatus.where(is_closed: true).first)
    issue.expects(:send_urgent_notification).never
    issue.status = IssueStatus.default
    issue.save
  end

end