# encoding: utf-8

require 'redmine'

# 'done_status_name' specifies name of status which is considered as done state for issue
# 'critical_priority' contains list of priorities which mean critical priority for issue
# 'script' defines path for script to call
SETTINGS = 
{
'critical_priority' => %w(Авария! Ахтунг!), 
'script' => '/opt/redmine/se.sh'
}

Redmine::Plugin.register :redmine_status_notifier do
  name 'Redmine Notifier plugin'
  author 'Southbridge'
  description 'Отправка уведомлений об авариях'
  version '0.0.2'
  author_url 'http://southbridge.ru'
  project_module "Отправка уведомлений об авариях" do
    permission(:send_on_urgent, {})
  end
  settings :default => SETTINGS
end

ActionDispatch::Callbacks.to_prepare do
  require_dependency 'issue_patch'
end