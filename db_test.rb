# #!/usr/bin/ruby
require 'pg'
require 'link_thumbnailer'
require 'active_record'

DB_URL = 'ec2-23-23-226-24.compute-1.amazonaws.com'

# ActiveRecord::Base.establish_connection(, :hostaddr=>DB_URL, :port=>5432, :dbname=>"daatnl4p67db99", :user=>"aiguathvtgwqmm", :password=>'gdNbvhHw4c1Mnu_CndnCH8Ovbz')
ActiveRecord::Base.establish_connection(:adapter=>"postgresql",
  :host => "ec2-23-23-226-24.compute-1.amazonaws.com",
  :username => "aiguathvtgwqmm",
  :password => "gdNbvhHw4c1Mnu_CndnCH8Ovbz",
  :database => "daatnl4p67db99")

class Url < ActiveRecord::Base
end

i=0

urls = Url.all
urls.each do |url|
  # renew values
  object = ""
  image = ""
  i+=1
  begin
    object = LinkThumbnailer.generate(url.url)
    # handle image path
    if object.favicon.start_with?("http")
      image = object.favicon
    elsif !object.favicon.start_with?("/")
      object.favicon[0] = ""
      image = url.url + object.favicon
    else
      image = url.url + object.favicon
    end
    if not object.title.include? "You are being redirected..."
      begin
        if object.description.include?('Too many login failures!')
          object.description = "this is a slack file"
        end
      rescue
        object.description = ""
      end
      # puts object.description
      # puts image
      # puts object.title, object.description, url.url+object.favicon
      url.update(title: object.title,
        description: object.description, image: image)
      puts 'actually updated'
    else
      puts url.url
    end
    puts i
  rescue LinkThumbnailer::HTTPError => error
    puts error
  rescue LinkThumbnailer::RedirectLimit => error
    puts error
  end

end
