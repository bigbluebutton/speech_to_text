# frozen_string_literal: true

# Set encoding to utf-8
# encoding: UTF-8

#
# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/
#
# Copyright (c) 2019 BigBlueButton Inc. and by respective authors (see below).
#
require 'aws-sdk-transcribestreamingservice'
require 'aws-sdk'
require 'json'
require 'open-uri'
require_relative 'util.rb'

module SpeechToText
  module AmazonS2T
    include Util

    def self.set_credentials(aws_key, aws_secret)
      Aws.config.update({
        region: 'us-east-2',
        credentials: Aws::Credentials.new(aws_key, aws_secret)
      })
    end

    def self.upload_audio(bucket_name, s3_audio_name, audio_file)
      s3 = Aws::S3::Resource.new
      obj = s3.bucket(bucket_name).object(s3_audio_name)
      obj.upload_file(audio_file)
    end

    def self.create_job(transcription_job_name, language_code, audio_format, s3_audio_uri)
      client = Aws::TranscribeService::Client.new
      resp = client.start_transcription_job({
        transcription_job_name: transcription_job_name,
        language_code: language_code,
        media_format: audio_format,
        media: {
          media_file_uri: s3_audio_uri
        }
      })
    end

    def self.checkstatus(transcription_job_name)
      client = Aws::TranscribeService::Client.new
      resp = client.get_transcription_job({
        transcription_job_name: transcription_job_name
      })

      status = resp['transcription_job']['transcription_job_status']
      return status
    end

    def self.get_words(transcription_job_name, json_file)
      client = Aws::TranscribeService::Client.new
      resp = client.get_transcription_job({
        transcription_job_name: transcription_job_name
      })

      uri = resp['transcription_job']['transcript']['transcript_file_uri']
      File.open(json_file, 'wb') do |file|
         file.write open(uri).read
      end

      file = File.open(json_file,'r')
      data = JSON.load file
      return data
    end

    def self.create_amazon_array(data) # rubocop:disable Metrics/AbcSize
      if data.nil?
        puts "no json data found"
        return
      end

      i = 0
      myarray = []
      while (i < data['results']['items'].length)
        unless data['results']['items'][i]['start_time'].nil?
          myarray.push(data['results']['items'][i]['start_time'].to_f)
          myarray.push(data['results']['items'][i]['end_time'].to_f)
          myarray.push(data['results']['items'][i]['alternatives'][0]['content'])
        end
        i = i + 1
      end
      return myarray
    end

    def self.delete_audio(bucket_name, s3_audio_name, transcription_job_name)
      s3 = Aws::S3::Resource.new
      obj = s3.bucket(bucket_name).object(s3_audio_name)
      obj.delete

      client = Aws::TranscribeService::Client.new
      resp = client.delete_transcription_job({
        transcription_job_name: transcription_job_name
      })
    end
    
  end
end
