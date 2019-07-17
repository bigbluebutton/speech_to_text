# Set encoding to utf-8
# encoding: UTF-8
#
# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/
#
# Copyright (c) 2019 BigBlueButton Inc. and by respective authors (see below).
#
require_relative "util.rb"

module SpeechToText
	module SpeechmaticsS2T
		require 'json'
		include Util
		#create array from json file
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

    #check status of specific jobid
    def self.check_job(userID,jobID,authKey,job_details_file)
      loop do
        job_status = "curl \"https://api.speechmatics.com/v1.0/user/#{userID}/jobs/#{jobID}/?auth_token=#{authKey}\" > #{job_details_file}"
        system("#{job_status}")
        job_json_data = File.open("#{job_details_file}","r")
        job_data = JSON.load job_json_data
        wait_time = job_data["job"]["check_wait"]
        job_status = job_data["job"]["job_status"]

        if job_status == "done" || job_status == "expired"
          break
        elsif job_status == "rejected" || job_status == "unsupported_file_format" || job_status == "could_not_align"
          puts "Job rejected..........."
          break
        else
          sleep(wait_time)
        end
      end
    end

		#speechmatics speech to text main function
    def self.speechmatics_speech_to_text(audio_file_path,audio_name,audio_content_type,userID,authKey)
      #upload audio to speechmatics
      upload_audio = "curl -F data_file=@#{audio_file_path}/#{audio_name}.#{audio_content_type} -F model=en-GB \"https://api.speechmatics.com/v1.0/user/#{userID}/jobs/?auth_token=#{authKey}\""
      system("#{upload_audio}")

      #get all jobs from speechmatics
      joblist_json = "#{audio_file_path}/#{audio_name}.json"
      get_job_list = "curl \"https://api.speechmatics.com/v1.0/user/#{userID}/jobs/?auth_token=#{authKey}\" > #{joblist_json}"
    	system("#{get_job_list}")

      job_list = File.open(joblist_json,"r")
    	jobs = JSON.load job_list
      jobID = jobs["jobs"][0]["id"]
      job_details_file = "#{audio_file_path}/#{jobID}_details.json"
      job_transcription_file = "#{audio_file_path}/#{jobID}_transcription.json"

      #get status of last job
      check_job(userID,jobID,authKey,job_details_file)

      #get transcription by passing specific jobID as a parameter
      transcription_command = "curl \"https://api.speechmatics.com/v1.0/user/#{userID}/jobs/#{jobID}/transcript?auth_token=#{authKey}\" > #{job_transcription_file}"
      system("#{transcription_command}")

      #load transcription json file
      out = File.open("#{job_transcription_file}", "r")
      data = JSON.load out

      #create speechmatics array
      speechmatics_array = create_array_speechmatic data

      #write to webvtt file
      Util.write_to_webvtt(audio_file_path,"#{audio_name}.vtt",speechmatics_array)
      File.delete(job_details_file)
      File.delete(job_transcription_file)
      File.delete(joblist_json)
    end
	end
end
