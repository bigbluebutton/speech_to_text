# Set encoding to utf-8
# encoding: UTF-8
#
# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/
#
# Copyright (c) 2019 BigBlueButton Inc. and by respective authors (see below).
#
require_relative "util.rb"
require 'net/http'
require 'uri'
require 'json'

module SpeechToText
	module SpeechmaticsS2T
		include Util

		def self.create_job(audio_file_path,audio_name,audio_content_type,userID,authKey,model,jobID_json_file)
			upload_audio = "curl -F data_file=@#{audio_file_path}/#{audio_name}.#{audio_content_type} -F model=#{model} \"https://api.speechmatics.com/v1.0/user/#{userID}/jobs/?auth_token=#{authKey}\" > #{jobID_json_file}"
		  system("#{upload_audio}")
			file = File.open(jobID_json_file)
			data = JSON.load file
			jobID = data["id"]
			return jobID
		end

		#check status of specific jobid
		def self.check_job(userID,jobID,authKey)
				uri = URI.parse("https://api.speechmatics.com/v1.0/user/#{userID}/jobs/#{jobID}/?auth_token=#{authKey}")
				response = Net::HTTP.get_response(uri)
				job_data = JSON.load response.body
				wait_time = job_data["job"]["check_wait"]
				#job_status = job_data["job"]["job_status"]
				return wait_time
		end

		def self.get_transcription(userID,jobID,authKey)
			uri = URI.parse("https://api.speechmatics.com/v1.0/user/#{userID}/jobs/#{jobID}/transcript?auth_token=#{authKey}")
			response = Net::HTTP.get_response(uri)
			data = JSON.load response.body
			return data
		end

		def self.create_array_speechmatic data
      myarray = []
      i=0
      while i!=data["words"].length
      	myarray.push(data["words"][i]["time"].to_f)
      	myarray.push(data["words"][i]["time"].to_f + data["words"][i]["duration"].to_f )
      	myarray.push(data["words"][i]["name"])
        i=i+1
      end
    	return myarray
    end

	end
end
