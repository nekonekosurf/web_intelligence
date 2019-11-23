require "open-uri"
require "json"
yomikomi=20

# baseidURL=ARGV.shift or exit
key_w=ARGV.shift or exit
baseidURL = "https://ci.nii.ac.jp/opensearch/"
target= baseidURL.gsub(/^http:/,"https:")
target = baseidURL+"search?title="+key_w+"&format=json"
puts target

open(target){|f|
    hash = JSON.load(f)
    for n in 1..yomikomi do
      puts n
      p "タイトル:" + hash["@graph"][0]["items"][n-1]["title"]
      p "ID:" + hash["@graph"][0]["items"][n-1]["@id"]
      puts 
    end
}
