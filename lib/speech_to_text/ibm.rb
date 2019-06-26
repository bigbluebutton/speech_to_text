# Set encoding to utf-8
# encoding: UTF-8
#
# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/
#
# Copyright (c) 2019 BigBlueButton Inc. and by respective authors (see below).
#
require_relative "util.rb"

module SpeechToText
	module IbmWatsonS2T
		include Util
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
			require 'json'
		  jsonfile_path = "#{published_files}/#{recordID}/#{recordID}.json"
		  watson_command = "curl -X POST -u \"apikey:#{apikey}\" --header \"Content-Type: audio/flac\" --data-binary @#{published_files}/#{recordID}/#{recordID}.flac \"https://stream.watsonplatform.net/speech-to-text/api/v1/recognize?timestamps=true\" > #{jsonfile_path}"
		  system("#{watson_command}")
		  out = File.open(jsonfile_path, "r")
		  data = JSON.load out
		  myarray = create_array_watson data
		  Util.write_to_webvtt(published_files,recordID,myarray)
			out.close
			File.delete(jsonfile_path)
		end
	end
end
