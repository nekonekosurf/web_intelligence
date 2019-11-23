#!/usr/bin/env ruby
# coding: utf-8
require 'sinatra'
require './yolp'

get '/' do
  erb :start

end

post '/search' do
  erb :search
end

post '/click' do
  erb :click
end

get 'click' do



end

get '/result' do

  yolp = YOLP.new
	coord = yolp.coordinate("#{params[:address]}")
	@coord =  "北海道札幌市北区北１２条西８丁目の座標は北緯#{coord[1]}度東経#{coord[0]}度"
	@ido = "#{coord[1]}"
	@keido ="#{coord[0]}"
	@name = "#{params[:name]}"
  erb :result_map
end
