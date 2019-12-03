require "open-uri"
require "json"
require 'uri'
yomikomi=20
key_w=ARGV.shift or exit
baseidURL = "https://ci.nii.ac.jp/books/opensearch/"
target= baseidURL.gsub(/^http:/,"https:")
target = baseidURL+"search?title="+URI.encode(key_w)+"&format=json"
puts target
open(target){|f|
    hash = JSON.load(f)
	min =hash["@graph"][0]["opensearch:totalResults"] .to_i
	if hash["@graph"][0]["opensearch:totalResults"] == "0"
	    puts "存在しません"
	    break
	else
if min>=20
    for n in 1..yomikomi do
	title = hash["@graph"][0]["items"][n-1]["title"]
	id = hash["@graph"][0]["items"][n-1]["@id"]
      puts n
      p "タイトル:" + title
      p "ID:" + id.delete!('http://ci.nii.ac.jp/ncid/')
      puts
    end
else
    for n in 1..min do
	title = hash["@graph"][0]["items"][n-1]["title"]
	id = hash["@graph"][0]["items"][n-1]["@id"]
      puts n
      p "タイトル:" + title
      p "ID:" + id.delete!('http://ci.nii.ac.jp/ncid/')
      puts
    end
end
end
}
