require 'net/http'
require 'uri'
require 'rexml/document' 
require 'rexml/xpath'
require 'timeout'

class AdRequestHandler < ActionMailer::Base
  
  def receive(email)
    ad_request = AdRequest.new
    ad_request.requester = email.from.first
    ad_request.category = email.to.first.gsub("@adzmo.com", "")
    ad_request.phone = email.body
    ad_request.save    
    
    number = get_phone_number(ad_request.phone)  
    if(number)         
      address = get_address(number)
      if(address)
        listing = get_listings(ad_request.category, address)
        if(listing)
          
          ad_response = AdResponse.new
          ad_response.ad_request_id = ad_request.id
          ad_response.recipient = ad_request.requester
          ad_response.category = ad_request.category
          ad_response.body = listing
          ad_response.save
          
          # send ads    
          AdRequestHandler.deliver_response(ad_response)
        end
      end 
    end    
  rescue Exception => exception
    SystemNotifier.deliver_exception_notification(exception)    
  end 
    
  def response(ad_response)
    @subject = ""
    @body = ad_response.body
    @sent_on = sent_on
    @from = "adzmo@adzmo.com"
    @recipients = ad_response.recipient
    @headers = {}
  end
  
  def get_address(number)
    url = "http://www.whitepages.com/10120/search/ReversePhone?phone="+number
    page = self.get_page(url)
    @addressRE = /<div class="text">(.*?)<br>(.*?)<br>/
    @addressRetryRE = /<span style="line-height:18pt;">.*?<\/span>(.*?)<br>(.*?)<br>/    
    matches = @addressRE.match(page)    
    if(matches)
      address = matches[1] + " " + matches[2]    
    else
      matches = @addressRetryRE.match(page)    
      address = matches[1] + " " + matches[2]    
    end
  rescue
    nil
  end
  
  def get_phone_number(phone_number_text) 
    @numberRE = /(\d{3})\D*(\d{3})\D*(\d{4})$/
    matches = @numberRE.match(phone_number_text)
    number = matches[1] + matches[2] + matches[3]
  rescue 
    nil    
  end  
  
  # retrieve a page
  def get_page(url)
    resp = nil
    begin
      timeout(600) do
        resp = Net::HTTP.get(URI.parse(url))	
        resp.to_s    
      end
    rescue TimeoutError
      retry
    end
    resp.to_s    
  rescue     
    nil
  end
  
  def get_listings(category, location)
    listing = ""
    url = "http://api.local.yahoo.com/LocalSearchService/V3/localSearch?appid=msmapper&radius=1&results=3&query="+CGI::escape(category)+"&location="+CGI::escape(location)
    resp = get_page(url)
    doc = REXML::Document.new(resp)
    if(doc)
      listing += (REXML::XPath.first(doc, "/ResultSet/Result/Title")).text
      listing += "\n"
      listing += (REXML::XPath.first(doc, "/ResultSet/Result/Address")).text
      listing += "\n"
      listing += (REXML::XPath.first(doc, "/ResultSet/Result/Phone")).text    
      listing += "\n"    
      listing += (REXML::XPath.first(doc, "/ResultSet/Result/Distance")).text    
      listing += " miles"    
    end
    if(listing.length > 0)
      listing
    else
      nil
    end
  end
  
end
