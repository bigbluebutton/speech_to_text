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
	  def self.create_job(
			audio_file_path:,
      apikey:,
      audio:,
      content_type:,
			language_code:"en-US",
      model: nil,
      callback_url: nil,
      events: nil,
      user_token: nil,
      results_ttl: nil,
      language_customization_id: nil,
      acoustic_customization_id: nil,
      base_model_version: nil,
      customization_weight: nil,
      inactivity_timeout: nil,
      keywords: nil,
      keywords_threshold: nil,
      max_alternatives: nil,
      word_alternatives_threshold: nil,
      word_confidence: nil,
      timestamps: nil,
      profanity_filter: nil,
      smart_formatting: nil,
      speaker_labels: nil,
      customization_id: nil,
      grammar_name: nil,
      redaction: nil,
      processing_metrics: nil,
      processing_metrics_interval: nil,
      audio_metrics: nil)

			job_id = "Error! job not created"

			if(!apikey.nil?)
	    	speech_to_text = IBMWatson::SpeechToTextV1.new(iam_apikey: apikey)
			end

		if(audio_file_path.nil? || audio.nil? || content_type.nil?)
				puts "audio file not found.."
				puts "try again and be careful with file path, audio name and content type"
		else
	    	audio_file = File.open("#{audio_file_path}/#{audio}.#{content_type}")
				service_response = speech_to_text.create_job(audio: audio_file,content_type: "audio/#{content_type}", timestamps: true, model: "#{language_code}_BroadbandModel")
				job_id = service_response.result["id"]
		end

			return job_id
	  end

	  def self.check_job(job_id,apikey)
			if(job_id.nil? || job_id == "Error! job not created")
				puts "job not created"
			else
				speech_to_text = IBMWatson::SpeechToTextV1.new(iam_apikey: apikey)
	      service_response = speech_to_text.check_job(id: job_id)
				return service_response.result
			end
			return "job not found.."
			#To create watson array pass service_response.result["results"][0] as argument as shown below
			#myarray = create_array_watson service_response.result["results"][0]
	  end

		#create array from json file
		def self.create_array_watson data
			if(data!="can not make request")
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
			else
				return "array not created"
			end
		end
	end
end
