# frozen_string_literal: true

# Set encoding to utf-8
# encoding: UTF-8

#
# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/
#
# Copyright (c) 2019 BigBlueButton Inc. and by respective authors (see below).
#
require_relative 'util.rb'
require 'net/http'
require 'uri'
require 'json'

module SpeechToText
  module SpeechmaticsS2T # rubocop:disable Style/Documentation
    include Util

    # rubocop:disable Naming/UncommunicativeMethodParamName
    # rubocop:disable Naming/VariableName
    # rubocop:disable Metrics/ParameterLists
    def self.create_job(audio_file_path, audio_name, audio_content_type, userID, authKey, model, jobID_json_file)
      # rubocop:enable Metrics/ParameterLists
      # rubocop:enable Naming/VariableName
      upload_audio = "curl -F data_file=@#{audio_file_path}/#{audio_name}.#{audio_content_type} -F model=#{model} \"https://api.speechmatics.com/v1.0/user/#{userID}/jobs/?auth_token=#{authKey}\" > #{jobID_json_file}"
      system(upload_audio.to_s)
      file = File.open(jobID_json_file)
      data = JSON.load file
      jobID = data['id'] # rubocop:disable Naming/VariableName
      jobID
    end
    # rubocop:enable Naming/UncommunicativeMethodParamName

    # check status of specific jobid
    # rubocop:disable Naming/UncommunicativeMethodParamName
    # rubocop:disable Naming/VariableName
    def self.check_job(userID, jobID, authKey)
      # rubocop:enable Naming/VariableName
      uri = URI.parse("https://api.speechmatics.com/v1.0/user/#{userID}/jobs/#{jobID}/?auth_token=#{authKey}")
      response = Net::HTTP.get_response(uri)
      job_data = JSON.load response.body
      wait_time = job_data['job']['check_wait']
      # job_status = job_data["job"]["job_status"]
      wait_time
    end
    # rubocop:enable Naming/UncommunicativeMethodParamName

    # rubocop:disable Naming/UncommunicativeMethodParamName
    # rubocop:disable Naming/VariableName
    def self.get_transcription(userID, jobID, authKey)
      # rubocop:enable Naming/VariableName
      uri = URI.parse("https://api.speechmatics.com/v1.0/user/#{userID}/jobs/#{jobID}/transcript?auth_token=#{authKey}")
      response = Net::HTTP.get_response(uri)
      data = JSON.load response.body
      data
    end
    # rubocop:enable Naming/UncommunicativeMethodParamName

    def self.create_array_speechmatic(data) # rubocop:disable Metrics/AbcSize
      myarray = []
      i = 0
      while i != data['words'].length
        myarray.push(data['words'][i]['time'].to_f)
        myarray.push(data['words'][i]['time'].to_f + data['words'][i]['duration'].to_f)
        myarray.push(data['words'][i]['name'])
        i += 1
      end
      myarray
    end
  end
end
