# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base  
  
  def page_not_found
  end
  
  def error_page
  end
    
  def rescue_action(exception)
    case exception
    when ::ActiveRecord::RecordNotFound, ::ActionController::UnknownAction
      render(:controller => 'public', :action => 'page_not_found')
    else        
      SystemNotifier.deliver_exception_notification(exception)
      render(:controller => 'public', :action => 'error_page')            
    end
  end
  
  def rescue_action_in_public(exception)
    case exception
    when ::ActiveRecord::RecordNotFound, ::ActionController::UnknownAction
      render(:controller => 'public', :action => 'page_not_found')
    else
      SystemNotifier.deliver_exception_notification(exception)
      render(:controller => 'public', :action => 'error_page')            
    end
  end
  
end