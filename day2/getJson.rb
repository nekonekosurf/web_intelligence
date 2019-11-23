require "open-uri"
# baseidURL=ARGV.shift or exit
baseidURL = "https://ci.nii.ac.jp/opensearch/search?title=sea&format=json"
target= baseidURL.gsub(/^http:/,"https:")
# if /\.json/ !~ target
#   target += ".json"
# end

file = File.open('result.json', "w");

open(target){|f|

  file.puts f.read;
  puts f.read;

}
