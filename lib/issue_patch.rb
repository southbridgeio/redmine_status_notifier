require_dependency 'issue'

module RedmineStatusNotifier

  module IssuePatch

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.send(:after_create, :notify_urgent_issue)
      base.send(:after_update, :notify_urgent_issue)
    end

    module InstanceMethods

      private

      def notify_urgent_issue
        return unless User.current.allowed_to?(:send_on_urgent, self.project)
        if urgent_assigned? || urgent_finished? || urgent_reopened?
          send_urgent_notification
        end
      end

      def urgent_priority?
        Setting['plugin_redmine_status_notifier']['critical_priority'].include? self.priority.name
      end

      def urgent_assigned?
        self.priority_id_changed? && urgent_priority?
      end

      def urgent_finished?
        urgent_priority? && self.closing?
      end

      def urgent_reopened?
        urgent_priority? && self.reopened?
      end

      def send_urgent_notification
        system("#{Setting['plugin_redmine_status_notifier']['script']} #{self.closed? ? 'done' : 'active'} #{self.id} #{self.project.identifier} \"#{self.subject}\"")
      end

    end

  end

end

Issue.send(:include, RedmineStatusNotifier::IssuePatch)