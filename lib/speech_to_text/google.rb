# Set encoding to utf-8
# encoding: UTF-8

#
# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/
#
# Copyright (c) 2019 BigBlueButton Inc. and by respective authors (see below).
#
require_relative "util.rb"

module SpeechToText
	module GoogleS2T
		require "google/cloud/speech"
		require "google/cloud/storage"
		include Util
		#create an array with the start time, stop time and words
		def self.create_array_google results
			data_array = []
			results.each do |result|
				result.alternatives.each do |alternative|
					alternative.words.each_with_index do |word, i|
						start_time = word.start_time.seconds + word.start_time.nanos/1000000000.0
						end_time   = word.end_time.seconds + word.end_time.nanos/1000000000.0

						data_array.push(start_time)
						data_array.push(end_time)
						data_array.push(word.word)
					end
    		end
  		end
  		return data_array
		end

		#uploads audio file to a google bucket
		def self.google_storage(published_files,recordID,bucket_name)
			storage = Google::Cloud::Storage.new project_id: bucket_name
			bucket  = storage.bucket bucket_name
			file = bucket.create_file "#{published_files}/#{recordID}/#{recordID}.flac","#{recordID}.flac"
			return file
		end

		#return the results from google speech
		def self.google_transcription(recordID,bucket_name)
		  # Instantiates a client
		  speech = Google::Cloud::Speech.new

		  # The audio file's encoding and sample rate
		  config = { encoding:          :FLAC,
		             sample_rate_hertz: 16000,#transcoded_movie.audio_sample_rate,
		             language_code:     "en-US",
		             enable_word_time_offsets: true }
		  audio  = { #content: audio_file #using local audio file
		             #uri: "gs://bbb-accessibility/video.FLAC" #static bucket file usage
		             uri: "gs://#{bucket_name}/#{recordID}.flac" #using the now uploaded audio file from the bucket
		           }

		  # Detects speech in the audio file
		  operation = speech.long_running_recognize config, audio

		  #puts "Operation started"

		  operation.wait_until_done!

		  raise operation.results.message if operation.error?

		  results = operation.response.results
		  return results
		end

		#Google-speech-to-text function
		def self.google_speech_to_text(published_files,recordID,auth_file,bucket_name)
			ENV['GOOGLE_APPLICATION_CREDENTIALS'] = auth_file
		  file = google_storage(published_files,recordID,bucket_name)
		  results = google_transcription(recordID,bucket_name)
		  data_array = create_array_google(results)
		  Util.write_to_webvtt(published_files,recordID,data_array)
			file.delete
		end
  end
end
