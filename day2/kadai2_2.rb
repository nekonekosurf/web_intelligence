require "open-uri"
require "json"
# そもそこのやりかたあってる分からない
def get_adrress(id)
  baseidURL = id
  target= baseidURL.gsub(/^http:/,"https:")
  target= target+".json"
  open(target){|f|
    hash = JSON.load(f)
    p hash["@graph"][0]["v:adr"]["v:label"]
  }
end

# baseidURL=ARGV.shift or exit
key_w=ARGV.shift or exit
baseidURL = "https://ci.nii.ac.jp/ncid/"+key_w+".json"
target= baseidURL.gsub(/^http:/,"https:")
file = File.open('result.json', "w");
open(target){|f|
  hash = JSON.load(f)
  i = 1
  for n in hash["@graph"][0]["bibo:owner"] do
    puts i
    puts n["foaf:name"]
    get_adrress(n["@id"])
    puts
    i +=1
  end
}
