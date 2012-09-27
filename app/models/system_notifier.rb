require 'pathname'

class SystemNotifier < ActionMailer::Base
  SYSTEM_EMAIL_ADDRESS = %{"Error Notifier" <errors@adzmo.com>}
  EXCEPTION_RECIPIENTS = %w{admin@adzmo.com}

  def exception_notification(exception, sent_on=Time.now)
    @subject = sprintf("[ERROR] (%s) %s",
                        exception.class,
                        exception.message.inspect)
    @body = { "exception" => exception,
              "backtrace" => sanitize_backtrace(exception.backtrace),
              "rails_roots" => rails_root }
    @sent_on = sent_on
    @from = SYSTEM_EMAIL_ADDRESS
    @recipients = EXCEPTION_RECIPIENTS
    @headers = {}
  end
  
  private
  
  def sanitize_backtrace(trace)
    re = Regexp.new(/^#{Regexp.escape(rails_root)}/)
    trace.map do |line|
      Pathname.new(line.gsub(re, "[RAILS_ROOT]")).cleanpath.to_s
    end
  end
  
  def rails_root
    @rails_root ||= Pathname.new(RAILS_ROOT).cleanpath.to_s
  end
  
end
