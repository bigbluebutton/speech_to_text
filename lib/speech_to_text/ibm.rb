# frozen_string_literal: true

# Set encoding to utf-8
# encoding: UTF-8

#
# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/
#
# Copyright (c) 2019 BigBlueButton Inc. and by respective authors (see below).

require 'speech_to_text'
require('ibm_watson/speech_to_text_v1')
require_relative 'util.rb'

module SpeechToText
  module IbmWatsonS2T # rubocop:disable Style/Documentation
    include Util

    # create new job on watson server by uploading audio
    # function returns 2 variables IBMWatson::SpeechToTextV1 object and jobid
    def self.create_job( # rubocop:disable Metrics/MethodLength
      audio_file_path:,
      apikey:,
      audio:,
      content_type:,
      language_code: 'en-US'
    )

      job_id = 'Error! job not created'

      unless apikey.nil?
        speech_to_text = IBMWatson::SpeechToTextV1.new(iam_apikey: apikey)
      end

      if audio_file_path.nil? || audio.nil? || content_type.nil?
        puts 'audio file not found..'
        puts 'try again and be careful with file path, audio name and content type'
      else
        audio_file = File.open("#{audio_file_path}/#{audio}.#{content_type}")
        service_response = speech_to_text.create_job(audio: audio_file, content_type: "audio/#{content_type}", timestamps: true, model: "#{language_code}_BroadbandModel")
        job_id = service_response.result['id']
      end

      job_id
    end

    def self.check_job(job_id, apikey)
      if job_id.nil? || job_id == 'Error! job not created'
        puts 'job not created'
      else
        speech_to_text = IBMWatson::SpeechToTextV1.new(iam_apikey: apikey)
        service_response = speech_to_text.check_job(id: job_id)
        return service_response.result
      end
      'job not found..'
      # To create watson array pass service_response.result["results"][0]
      # myarray = create_array_watson service_response.result["results"][0]
    end

    # create array from json file
    # rubocop:disable Metrics/MethodLength
    def self.create_array_watson(data) # rubocop:disable Metrics/AbcSize
      if data != 'can not make request'
        k = 0
        myarray = []
        while k != data['results'].length
          j = 0
          while j != data['results'][k]['alternatives'].length
            i = 0
            # rubocop:disable Metrics/BlockNesting
            while i != data['results'][k]['alternatives'][j]['timestamps'].length
              first = data['results'][k]['alternatives'][j]['timestamps'][i][1]
              last = data['results'][k]['alternatives'][j]['timestamps'][i][2]
              transcript = data['results'][k]['alternatives'][j]['timestamps'][i][0]

              if transcript.include? '%HESITATION'
                transcript['%HESITATION'] = ''
              end
              myarray.push(first)
              myarray.push(last)
              myarray.push(transcript)
              i += 1
            end
            # rubocop:enable Metrics/BlockNesting
            confidence = data['results'][k]['alternatives'][j]['confidence']
            myarray[myarray.length - 2] = myarray[myarray.length - 2] + confidence
            j += 1
          end
          k += 1
        end
        myarray
      else
        'array not created'
      end
    end
    # rubocop:enable Metrics/MethodLength
  end
end
