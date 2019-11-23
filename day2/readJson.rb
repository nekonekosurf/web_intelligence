require 'json'
File.open("result.json") do |file|
  hash = JSON.load(file)
  i = 1
  for n in hash["@graph"][0]["bibo:owner"] do
    puts i
    puts n["foaf:name"]
    puts
    i +=1
  end
end
