module RedmineStatusNotifier
  class Hooks < Redmine::Hook::ViewListener

    def controller_issues_edit_before_save(context={ })
      return '' unless sending_on?(context)
      @issue = context[:issue]
      if @issue and urgent_assigned? or urgent_finished?
       	shell_call
      end
    end

    def controller_issues_new_after_save(context={ })
      return '' unless sending_on?(context)
      @issue = context[:issue]
      if @issue and urgent_priority?
        shell_call
      end
    end

    def urgent_assigned?
      priority_changed? and urgent_priority?
    end

    def priority_changed?
      @issue.priority_id_changed?
    end

    def urgent_priority?
      Setting["plugin_redmine_status_notifier"]["critical_priority"].include? @issue.priority.name
    end

    def urgent_finished?
      urgent_priority? and status_changed? and done?
    end

    def status_changed?
      @issue.status_id_changed?
    end

    def done?
      @issue.status.name == Setting["plugin_redmine_status_notifier"]["done_status_name"]
    end

    def sending_on?(context = {})
      User.current.allowed_to?(:send_on_urgent, context[:issue].project)
    end

    def shell_call
      system("#{Setting["plugin_redmine_status_notifier"]["script"]} #{done? ? "done" : "active"} #{@issue.id} \"#{@issue.subject}\"")
    end
  end
end
