require "open-uri"
require "json"
def get_adrress(id)
  baseidURL = id
  target= baseidURL.gsub(/^http:/,"https:")
  target= target+".json"
  open(target){|f|
    hash = JSON.load(f)
    p hash["@graph"][0]["v:adr"]["v:label"]
  }
end

key_w=ARGV.shift or exit
baseidURL = "https://ci.nii.ac.jp/ncid/"+key_w+".json"
target= baseidURL.gsub(/^http:/,"https:")
file = File.open('result.json', "w");
begin
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
rescue => e
puts e
end
