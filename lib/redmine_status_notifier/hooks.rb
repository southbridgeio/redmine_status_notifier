module RedmineStatusNotifier
  class Hooks < Redmine::Hook::ViewListener

    def controller_issues_edit_after_save(context={ })
      return '' unless sending_on?(context)
      @issue = context[:issue]
      @journal = context[:journal]
      if @issue and (urgent_assigned? or urgent_finished? or urgent_reopened?)
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

    def previous_value_for(prop)
      c = @journal.details.detect {|detail| detail.prop_key == prop}
      c ? c.old_value : nil
    end

    def urgent_priority?
      Setting["plugin_redmine_status_notifier"]["critical_priority"].include? @issue.priority.name
    end

    def urgent_assigned?
      priority_changed? and urgent_priority?
    end

    def priority_changed?
      if (previous_priority_id = previous_value_for("priority_id"))
        @issue.priority_id != previous_priority_id
      end
    end

    def urgent_finished?
      urgent_priority? and was_opened? and closed?
    end

    def closed?
      @issue.status.is_closed
    end

    def urgent_reopened?
      urgent_priority? and was_closed? and opened?
    end

    def was_closed?
      if (status = previous_status)
        status.is_closed
      end
    end

    def was_opened?
      if (status = previous_status)
        !status.is_closed
      end
    end

    def previous_status
      if (status_id = previous_value_for("status_id"))
        IssueStatus.find(status_id)
      end
    end

    def opened?
      !@issue.status.is_closed
    end

    def sending_on?(context = {})
      User.current.allowed_to?(:send_on_urgent, context[:issue].project)
    end

    def shell_call
      system("#{Setting["plugin_redmine_status_notifier"]["script"]} #{closed? ? "done" : "active"} #{@issue.id} #{@issue.project.identifier} \"#{@issue.subject}\"")
    end
  end
end
