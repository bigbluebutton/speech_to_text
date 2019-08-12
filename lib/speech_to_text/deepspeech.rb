# Set encoding to utf-8
# encoding: UTF-8
#
# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/
#
# Copyright (c) 2019 BigBlueButton Inc. and by respective authors (see below).
#
require 'json'
require_relative "util.rb"

module SpeechToText
	module MozillaDeepspeechS2T
    include Util

    def self.create_mozilla_array(data)
    	i=0
    	myarray = []
    	while i<data["words"].length
    		myarray.push(data["words"][i]["time"].to_f)
    		if i == data["words"].length - 1
    			endtime = data["file"]["duration"].to_f
    		else
    			endtime =  data["words"][i+1]["time"].to_f
    		end
    		myarray.push(endtime)
    		myarray.push(data["words"][i]["word"])
    		i = i+1
    	end
    	return myarray
    end

		def self.create_job(audio_file,json_file, model_path )
			#audio_file = "/home/abc/audio.wav"
			#json_file = "/home/xyz/jsonfile.json"
      deepspeech_command = "#{model_path}/deepspeech --model #{model_path}/models/output_graph.pbmm --alphabet #{model_path}/models/alphabet.txt --lm #{model_path}/models/lm.binary --trie #{model_path}/models/trie -e --audio #{audio_file} > #{json_file}"
			system("#{deepspeech_command}")
		end

		def get_array(json_file)
			file = File.open(json_file,"r")
      data = JSON.load(file)
			deepspeech_array = create_mozilla_array(data)
			return deepspeech_array
		end
  end
end
