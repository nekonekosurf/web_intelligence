#!/usr/bin/env ruby
# frozen_string_literal: true

require 'sinatra'
require './yolp'
require 'open-uri'
require 'json'
require 'active_record'
require 'uri'
enable :sessions

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: 'sandbox.db'
)

class Library_record < ActiveRecord::Base
end

hash_count={} #図書名のw出現回数調べる

get '/' do
  erb :putInformation
end

get '/result_' do
  yolp = YOLP.new
  if yolp.coordinate(params[:address].to_s).nil? || (params[:address].to_s == '')
    redirect '/'
  end
  appid = 'jsqAbSa3aKX49y0tRjEY' # アプリケーションキー
  key_w = params[:key_word].to_s # 検索語
  @select= params[:select].to_i
  @key_word = params[:key_word].to_s
  session[:kijyun] = params[:address].to_s # sessionで基準点を使いまわし
  baseidURL = 'https://ci.nii.ac.jp/books/opensearch/' # キーワードで検索時のURL
  target = baseidURL.gsub(/^http:/, 'https:')
  key_w = key_w.encode
  target = baseidURL + 'search?title=' + URI.encode(key_w) + '&format=json&count=200&appid=' + appid

  puts 'target'
  puts target
  hash_title = {} # タイトルと住所の組み合わせのハッシュ
  begin
  open(target) do |f|
    hash = JSON.load(f)
    min = hash['@graph'][0]['opensearch:totalResults'].to_i
    if  hash['@graph'][0]['opensearch:totalResults'] == '0'
      puts '存在しません'
      redirect '/'
    else
      puts min
      if min >= 200
        (1..200).each do |n|
          if hash['@graph'][0]['items'][n - 1]['title']==nil
            next
          else
            if  hash_title.key?(hash['@graph'][0]['items'][n - 1]['title'])
              cnt = hash_count[hash['@graph'][0]['items'][n - 1]['title']]
              cnt +=1
              hash_title.store(hash['@graph'][0]['items'][n - 1]['title']+ "(" + cnt.to_s + ")", hash['@graph'][0]['items'][n - 1]['@id'])
            else
              hash_title.store(hash['@graph'][0]['items'][n - 1]['title'], hash['@graph'][0]['items'][n - 1]['@id'])
              hash_count[hash['@graph'][0]['items'][n - 1]['title']]=1
              puts n
              puts hash['@graph'][0]['items'][n - 1]['title']
             end
           end
          end
        else
          (1..min).each do |n|
            if hash['@graph'][0]['items'][n - 1]['title']==nil
              next
            else
              if  hash_title.key?(hash['@graph'][0]['items'][n - 1]['title'])
                cnt = hash_count[hash['@graph'][0]['items'][n - 1]['title']]
                cnt +=1
                hash_title.store(hash['@graph'][0]['items'][n - 1]['title']+ "(" + cnt.to_s + ")", hash['@graph'][0]['items'][n - 1]['@id'])
              else
                hash_title.store(hash['@graph'][0]['items'][n - 1]['title'], hash['@graph'][0]['items'][n - 1]['@id'])
                hash_count[hash['@graph'][0]['items'][n - 1]['title']]=1
                puts n
                puts hash['@graph'][0]['items'][n - 1]['title']
              end
            end
          end
        end
      end
  end
rescue=>e
  puts e
  redirect '/'
end
  @hash_title = hash_title
  erb :result_search
end

get '/result' do
  yolp = YOLP.new # 地図を表示させるときに使うようになる
  coord = yolp.coordinate(session[:kijyun].to_s) # 基準点の経度井戸を計算
  @basic_adress = session[:kijyun].to_s
  @ido = (coord[1]).to_s
  @keido = (coord[0]).to_s
  book_id = params[:value].to_s.delete!('http://ci.nii.ac.jp/ncid/') # valueには本のID以外にも余計なものが入っているので削除
  session[:book_id] = book_id
  hash = get_library_name(book_id) # 本のIDで図書館の名前と図書館の住所が入る
  if hash.nil?
    erb :noExist
  else
    @hash = hash
    array_order = libNmaeAdr_to_arrayOrder(hash, session[:kijyun].to_s)
    @array_order = array_order
    erb :display
end
end

# 距離のアップデート出きるに出きる毎回get書くのは適切でない気がする
get '/update_location' do          # 基準住所をアップデート
  yolp = YOLP.new                  # 地図を表示させるときに使うようになる
  coord = yolp.coordinate(params[:address_new].to_s) # 基準点の経度井戸を計算
  if coord==nil
    erb :display_error
  else
    @basic_adress = params[:address_new].to_s
    @ido = (coord[1]).to_s
    @keido = (coord[0]).to_s
    book_id = session[:book_id].to_s # valueには本のID以外にも余計なものが入っているので削除
    hash = get_library_name(book_id) # 本のIDで図書館の名前と図書館の住所が入る
    @hash = hash
    array_order = libNmaeAdr_to_arrayOrder(hash, params[:address_new].to_s)
    @array_order = array_order
    erb :display
  end
end

def libNmaeAdr_to_arrayOrder(hash, _kijyun) # 図書館の名前と住所ハッシュ基準値から距離順並べ配返す
  yolp = YOLP.new # 地図を表示させるときに使うようになる
  coord = yolp.coordinate(session[:kijyun].to_s) # 基準点の経度井戸を計算
  hash2 = Hash.new { |h, k| h[k] = {} } # hashのの情報をすべて距離計算する
  hash.each do |name, _address|
    # target_library = yolp.coordinate(address)
    lib = Library_record.find_by(library_name: name)
    dist_ = yolp.distance([coord[1], coord[0]], [lib.ido, lib.keido])
    hash2[hash[name]] = dist_ # hashとhash2の二重ハッシュ｛図書館の名前＝＞｛図書館の住所＝＞基準との距離｝｝
  end
  temp = []
  temp = hash2.sort { |(_k1, v1), (_k2, v2)| v1 <=> v2 } # 距離順でソートしたのを配列に
  array_order = []
  temp.each do |n|
    # p n[0]
    # p hash.invert[n[0]]
    array_order.push(hash.invert[n[0]]) # ソートした距離から図書館の名前を取り出している
  end

  array_order
end

def get_adrress(id)
  baseidURL = id
  target = baseidURL.gsub(/^http:/, 'https:')
  target += '.json'
  open(target) do |f|
    hash = JSON.load(f)
    p hash['@graph'][0]['v:adr']['v:label']
    return hash['@graph'][0]['v:adr']['v:label']
  end
end

def get_library_name(key_w) # 本のIDが引数として与えられる
  baseidURL = 'https://ci.nii.ac.jp/ncid/' + key_w + '.json'
  target = baseidURL.gsub(/^http:/, 'https:')
  reHash = {}
  open(target) do |f|
    hash = JSON.load(f)
    if hash['@graph'][0]['cinii:ownerCount'] == '0'
      puts 'noExist'
      return nil
    else
      puts 'Exist!!!'
      i = 1
      hash['@graph'][0]['bibo:owner'].each do |n|
        # データベース用い高速に
        # もし存在しなければ追加
        if !Library_record.where(library_name: (n['foaf:name']).to_s).exists?
          new_address = get_adrress(n['@id'])
          yolp = YOLP.new # 地図を表示させるときに使うようになる
          target_library = yolp.coordinate(new_address) # ここで緯度と経度を計算しておく
          if target_library.nil?
            puts 'nill!!!!!!!!!!'
            next
          end
          lib = Library_record.new(
            library_name: (n['foaf:name']).to_s,
            library_address: new_address,
            ido: target_library[1],
            keido: target_library[0]
          )
          lib.save
          reHash.store((n['foaf:name']).to_s, new_address) # 図書館の名前=>住所でハッシュ
        # もし存在すればデータベースから読み出し
        else
          name_address = Library_record.find_by(library_name: (n['foaf:name']).to_s)
          reHash.store((n['foaf:name']).to_s, name_address.library_address) # 図書館の名前=>住所でハッシュ
        end
        i += 1
      end
  end
  end
  reHash
end
