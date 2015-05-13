require 'uri'
require 'net/http'
require 'net/https'
require 'net/http/post/multipart'

USERAGENT = "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/523.10.6 (KHTML, like Gecko) Version/3.0.4 Safari/523.10.6"
BOUNDARY = "sercancelenk1234"
CONTENT_TYPE = "multipart/form-data; boundary=#{ BOUNDARY }"
HEADER = { "Content-Type" => CONTENT_TYPE, "User-Agent" => USERAGENT }



url = URI.parse('http://www.example.com/upload')
req = Net::HTTP::Post::Multipart.new (url.path, "file1" => UploadIO.new(File.new("./image.jpg"), "image/jpeg", "image.jpg"),"file2" => UploadIO.new(File.new("./image2.jpg"), "image/jpeg", "image2.jpg"))
res = Net::HTTP.start(url.host, url.port) do |http|
  http.request(req)
end

