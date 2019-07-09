# Set encoding to utf-8
# encoding: UTF-8
#
# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/
#
# Copyright (c) 2019 BigBlueButton Inc. and by respective authors (see below).

require "speech_to_text"
require("ibm_watson/speech_to_text_v1")
require_relative "util.rb"

module SpeechToText
	module IbmWatsonS2T
		include Util

		#create new job on watson server by uploading audio
		#function returns 2 variables IBMWatson::SpeechToTextV1 object and jobid
	  def self.create_job(published_files,recordID,apikey)
	    speech_to_text = IBMWatson::SpeechToTextV1.new(iam_apikey: apikey)
	    audio_file = File.open("#{published_files}/#{recordID}/#{recordID}.flac")
	    service_response = speech_to_text.create_job(audio: audio_file,content_type: "audio/flac", timestamps: true)
	    job_id = service_response.result["id"]
	    return speech_to_text,job_id
	  end

		#functions checks the status of specific jobid
		#pass array of 2 variables as argumanet [IBMWatson::SpeechToTextV1 object, jobid]
	  def self.check_job(params)
	    status = "processing"
			speech_to_text = params[0]
			job_id = params[1]
	    while(status != "completed")
	      service_response = speech_to_text.check_job(id: job_id)
	      status = service_response.result["status"]
	      sleep 10
	    end
			return service_response.result["results"][0]
	  end

		#create array from json file
		def self.create_array_watson data
		  k = 0
		  myarray = []
			while k!= data["results"].length
		    j = 0
		    while j!= data["results"][k]["alternatives"].length
		      i = 0
		      while i!= data["results"][k]["alternatives"][j]["timestamps"].length
		        first = data["results"][k]["alternatives"][j]["timestamps"][i][1]
		        last = data["results"][k]["alternatives"][j]["timestamps"][i][2]
		        transcript = data["results"][k]["alternatives"][j]["timestamps"][i][0]

		        if transcript.include? "%HESITATION"
		            transcript["%HESITATION"] = ""
		        end
		        myarray.push(first)
		        myarray.push(last)
		        myarray.push(transcript)
		        i+=1
		      end
		      confidence = data["results"][k]["alternatives"][j]["confidence"]
		      myarray[myarray.length-2] = myarray[myarray.length-2] + confidence
		    j+=1
		    end
		  k+=1
		  end
		  return myarray
		end

		#ibm speech to text main function
		def self.ibm_speech_to_text(published_files,recordID,apikey)
			params = create_job(published_files,recordID,apikey)
			data = check_job(params)
			myarray = create_array_watson data
		  Util.write_to_webvtt(published_files,recordID,myarray)
		end
	end
end
