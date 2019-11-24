#!/usr/bin/env ruby
# coding: utf-8
require 'sinatra'
require './yolp'

get '/' do
  erb :putInformation
end


get '/result' do
  yolp = YOLP.new
	coord = yolp.coordinate("#{params[:address]}")
	@ido = "#{coord[1]}"
	@keido ="#{coord[0]}"
  @dist="#{yolp.distance([coord[1],coord[0]],[43.5,135.5])}"

  # @library_name=get_library_name("BB21074902")
  hash=get_library_name("BB21074902")
  puts hash["公立はこだて未来大学 情報ライブラリー"]
  @hash_name ="#{hash["公立はこだて未来大学 情報ライブラリー"]}"


  erb :display
end




require "open-uri"
require "json"
def get_adrress(id)
  baseidURL = id
  target= baseidURL.gsub(/^http:/,"https:")
  target= target+".json"
  open(target){|f|
    hash = JSON.load(f)
    p hash["@graph"][0]["v:adr"]["v:label"]
    return hash["@graph"][0]["v:adr"]["v:label"]
  }
end

def get_library_name(key_w)
  baseidURL = "https://ci.nii.ac.jp/ncid/"+key_w+".json"
  target= baseidURL.gsub(/^http:/,"https:")
  file = File.open('result.json', "w");
  reHash={}
  open(target){|f|
    hash = JSON.load(f)
    i = 1
    for n in hash["@graph"][0]["bibo:owner"] do
      puts i
      puts n["foaf:name"]
      # reHash[n["foaf:name"]]= get_adrress(n["@id"])
      reHash.store("#{n["foaf:name"]}", get_adrress(n["@id"]))
      puts reHash
      # get_adrress(n["@id"])
      puts
      i +=1
    end
  }
  return reHash
end
