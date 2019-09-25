# frozen_string_literal: true

# Set encoding to utf-8
# encoding: UTF-8

#
# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/
#
# Copyright (c) 2019 BigBlueButton Inc. and by respective authors (see below).
#
require 'json'
require 'net/http'
require 'uri'

module SpeechToText
  module ThreePlaymediaS2T # rubocop:disable Style/Documentation
    def self.create_job(api_key, audio_file, name, create_job_file)
      cretae_job_command = "curl -X POST -F \"source_file=@#{audio_file}\" \"https://api.3playmedia.com/v3/files?api_key=#{api_key}&language_id=1&name=#{name}\" > #{create_job_file}"
      system(cretae_job_command)
      file = File.open(create_job_file, 'r')
      response = JSON.load file
      job_id = response['data']['id']
      job_id
    end

    # rubocop:disable Metrics/MethodLength
    def self.order_transcript(api_key, job_id, turnaround_level_id)
      uri = URI.parse("https://api.3playmedia.com/v3/transcripts/order/transcription?api_key=#{api_key}&media_file_id=#{job_id}&turnaround_level_id=#{turnaround_level_id}")
      request = Net::HTTP::Post.new(uri)
      req_options = {
        use_ssl: uri.scheme == 'https'
      }

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end
      res = JSON.load response.body
      transcript_id = res['data']['id']
      transcript_id
    end
    # rubocop:enable Metrics/MethodLength

    def self.check_status(api_key, transcript_id)
      uri = URI.parse("https://api.3playmedia.com/v3/transcripts/#{transcript_id}?api_key=#{api_key}")
      response = Net::HTTP.get_response(uri)
      res = JSON.load response.body
      status = res['data']['status']
      status
    end

    def self.get_vttfile(api_key, output_format_id, transcript_id, vtt_file_path, vtt_file_name)
      uri = URI.parse("https://api.3playmedia.com/v3/transcripts/#{transcript_id}/text?api_key=#{api_key}&output_format_id=#{output_format_id}")
      response = Net::HTTP.get_response(uri)
      res = JSON.load response.body
      out = File.open("#{vtt_file_path}/#{vtt_file_name}", 'w')
      out.puts res['data']
      out.close

      captions_file_name = "#{vtt_file_path}/captions.json"
      captions_file = File.open(captions_file_name, 'w')
      captions_file.puts '[{"localeName": "English (United States)", "locale": "en-US"}]'
      captions_file.close
    end
  end
end
