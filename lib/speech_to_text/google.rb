# frozen_string_literal: true

# Set encoding to utf-8
# encoding: UTF-8

#
# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/
#
# Copyright (c) 2019 BigBlueButton Inc. and by respective authors (see below).
#
require_relative 'util.rb'

module SpeechToText
  module GoogleS2T # rubocop:disable Style/Documentation
    require 'google/cloud/speech'
    require 'google/cloud/storage'
    include Util
    # create an array with the start time, stop time and words
    # rubocop:disable Metrics/MethodLength
    def self.create_array_google(results) # rubocop:disable Metrics/AbcSize
      data_array = []
      results.each do |result|
        result.alternatives.each do |alternative|
          alternative.words.each_with_index do |word, _i|
            start_time = word.start_time.seconds + word.start_time.nanos / 1_000_000_000.0
            end_time   = word.end_time.seconds + word.end_time.nanos / 1_000_000_000.0

            data_array.push(start_time)
            data_array.push(end_time)
            data_array.push(word.word)
          end
        end
      end
      data_array
    end
    # rubocop:enable Metrics/MethodLength

    # set environment for worker
    # rubocop:disable Naming/AccessorMethodName
    def self.set_environment(auth_file)
      ENV['GOOGLE_APPLICATION_CREDENTIALS'] = auth_file
    end

    # rubocop:enable Naming/AccessorMethodName
    # uploads audio file to a google bucket
    def self.google_storage(audio_file_path, audio_name, audio_content_type, bucket_name)
      audio_file = "#{audio_file_path}/#{audio_name}.#{audio_content_type}"
      storage = Google::Cloud::Storage.new project_id: bucket_name
      bucket  = storage.bucket bucket_name
      file = bucket.create_file audio_file, "#{audio_name}.#{audio_content_type}"
    end

    def self.create_job(audio_name, audio_content_type, bucket_name, language_code)
      speech = Google::Cloud::Speech.new(version: :v1p1beta1)

      # The audio file's encoding and sample rate
      config = {
        language_code: language_code,
        enable_word_time_offsets: true
      }
      audio = { # content: audio_file #using local audio file
        uri: "gs://#{bucket_name}/#{audio_name}.#{audio_content_type}" # using the now uploaded audio file from the bucket
      }

      operation = speech.long_running_recognize config, audio
      operation.name
    end

    def self.check_status(operation_name) # rubocop:disable Metrics/MethodLength
      # construct a new operation object from the id
      speech = Google::Cloud::Speech.new(version: :v1p1beta1)
      operation2 = speech.get_operation operation_name
      if operation2.error?
        status = 'failed'
        return status
      end

      if operation2.done?
        status = 'completed'
        return status
      end

      status = 'inProgress'
      status
    end

    def self.get_words(operation_name)
      # construct a new operation object from the id
      speech = Google::Cloud::Speech.new(version: :v1p1beta1)
      operation2 = speech.get_operation operation_name
      operation2.results
    end

    def self.delete_google_storage(bucket_name, audio_name, audio_content_type)
      storage = Google::Cloud::Storage.new project_id: bucket_name
      bucket  = storage.bucket bucket_name
      file = bucket.file "#{audio_name}.#{audio_content_type}"
      file.delete
    end
  end
end
