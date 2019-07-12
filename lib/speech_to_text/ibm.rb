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
    def self.create_job(apikey:, 
                        audio:, 
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
                        audio_metrics: nil, 
                        content_type: nil)

      speech_to_text = IBMWatson::SpeechToTextV1.new(iam_apikey: apikey)

      service_response = speech_to_text.create_job(audio: audio, 
                                    model: model, 
                                    callback_url: callback_url, 
                                    events: events, 
                                    user_token: user_token, 
                                    results_ttl: results_ttl, 
                                    language_customization_id: language_customization_id, 
                                    acoustic_customization_id: acoustic_customization_id, 
                                    base_model_version: base_model_version, 
                                    customization_weight: customization_weight, 
                                    inactivity_timeout: inactivity_timeout, 
                                    keywords: keywords, 
                                    keywords_threshold: keywords_threshold, 
                                    max_alternatives: max_alternatives, 
                                    word_alternatives_threshold: word_alternatives_threshold, 
                                    word_confidence: word_confidence, 
                                    timestamps: timestamps, 
                                    profanity_filter: profanity_filter, 
                                    smart_formatting: smart_formatting, 
                                    speaker_labels: speaker_labels, 
                                    customization_id: customization_id, 
                                    grammar_name: grammar_name, 
                                    redaction: redaction, 
                                    processing_metrics: processing_metrics, 
                                    processing_metrics_interval: processing_metrics_interval, 
                                    audio_metrics: audio_metrics, 
                                    content_type: content_type)
      return service_response
    end

    #functions checks the status of specific jobid
    #pass array of 2 variables as argumanet [IBMWatson::SpeechToTextV1 object, jobid]
    def self.check_job(id:, apikey:)
      status = "processing"
      speech_to_text = IBMWatson::SpeechToTextV1.new(iam_apikey: apikey)
      service_response = speech_to_text.check_job(id: id)
      return service_response
    end

    def self.create_array_watson(data)
      k = 0
      myarray = []
      while k != data["results"].length
        j = 0
        while j != data["results"][k]["alternatives"].length
          i = 0
          while i != data["results"][k]["alternatives"][j]["timestamps"].length
            first = data["results"][k]["alternatives"][j]["timestamps"][i][1]
            last = data["results"][k]["alternatives"][j]["timestamps"][i][2]
            transcript = data["results"][k]["alternatives"][j]["timestamps"][i][0]

            if transcript.include? "%HESITATION"
                transcript["%HESITATION"] = ""
            end

            myarray.push(first)
            myarray.push(last)
            myarray.push(transcript)
            i += 1
          end
          confidence = data["results"][k]["alternatives"][j]["confidence"]
          myarray[myarray.length-2] = myarray[myarray.length-2] + confidence
        j += 1
        end
      k += 1
      end
      return myarray
    end
  end
end
