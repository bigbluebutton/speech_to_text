# Set encoding to utf-8
# encoding: UTF-8
#
# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/
#
# Copyright (c) 2019 BigBlueButton Inc. and by respective authors (see below).
#
require 'json'
require_relative "util.rb"
require 'net/http'
require 'uri'


module SpeechToText
	module MozillaDeepspeechS2T
    include Util

		def self.create_job(audio,server_url,jobdetails_json)
			request = "curl -F \"file=@#{audio}\" \"#{server_url}/deepspeech/createjob\" > #{jobdetails_json}"
			system(request)
			file = File.open(jobdetails_json,"r")
			data = JSON.load file
			return data["jobID"]
		end

		def self.checkstatus(jobID,server_url)
			uri = URI.parse("#{server_url}/deepspeech/checkstatus/#{jobID}")
      response = Net::HTTP.get_response(uri)
			data = JSON.load response.body
			return data["status"]
		end

		def self.generate_transcript(audio,json_file, model_path)
			deepspeech_command = "#{model_path}/deepspeech --model #{model_path}/models/output_graph.pbmm --alphabet #{model_path}/models/alphabet.txt --lm #{model_path}/models/lm.binary --trie #{model_path}/models/trie -e --audio #{audio} > #{json_file}"
			system("#{deepspeech_command}")
		end

		def self.order_transcript(jobID,server_url)
			uri = URI.parse("#{server_url}/deepspeech/transcript/#{jobID}")
      response = Net::HTTP.get_response(uri)
			data = JSON.load response.body
			return data
		end

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

		def self.get_array(json_file)
			file = File.open(json_file,"r")
      data = JSON.load(file)
			deepspeech_array = create_mozilla_array(data)
			return deepspeech_array
		end
  end
end
