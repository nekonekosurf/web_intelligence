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
	@basic_adress = "#{params[:address]}"
	@ido = "#{coord[1]}"
	@keido ="#{coord[0]}"
  @dist="#{yolp.distance([coord[1],coord[0]],[43.5,135.5])}"

  # @library_name=get_library_name("BB21074902")
  hash=get_library_name("BB21074902") 		#ここで図書館の名前と住所をハッシュに入れている
																							#図書館名=>住所	
																							#{"公立はこだて未来大学 情報ライブラリー"=>"函館市亀田中野町116-2", "三重大学 附属図書館"=>"三重県津市栗真町屋町 1577", "大阪電気通信大学 図書館"=>"大阪府寝屋川市初町18-8"}																		
																							

  @hash = hash
  array_str=[]
  hash2=Hash.new { |h,k| h[k] = {} }
    hash.each{|name,address| 
     target_library = yolp.coordinate(address)
    	dist_=yolp.distance([coord[1],coord[0]],[target_library[1],target_library[0]])

		#	puts "#{name} と#{address} との距離 #{yolp.distance([coord[1],coord[0]],[target_library[1],target_library[0]])}"						 	
			array_str.push("#{name} と#{address} との距離 #{yolp.distance([coord[1],coord[0]],[target_library[1],target_library[0]])}")	
			
			
			  hash2[hash[name]]=dist_
			 # hash.store(hash,dist_)
		}
		p "ハッシュ2 ソートまえ"
		p hash2		#ハッシュ ソートまえ	
		puts
		p "ハッシュ2 ソートあと"
		p hash2.sort {|(k1, v1), (k2, v2)| v1 <=> v2 } #ここでハッシュをソート 小さい順
		puts
		temp= []
		temp=hash2.sort {|(k1, v1), (k2, v2)| v1 <=> v2 } 
		p temp[0]
		puts
		p "ハッシュ 大学を表示 "
		array_order=[]
		for n in temp do
			p n[0]
			p hash.invert[n[0]]
			array_order.push(hash.invert[n[0]])
		end
		puts

 		@array_str=array_str
 		@array_order = array_order
 	
 	
 	
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
      #puts i
      #puts n["foaf:name"]
      # reHash[n["foaf:name"]]= get_adrress(n["@id"])
      reHash.store("#{n["foaf:name"]}", get_adrress(n["@id"]))
    #  puts reHash
      # get_adrress(n["@id"])
      puts
      i +=1
    end
  }
  return reHash
end
