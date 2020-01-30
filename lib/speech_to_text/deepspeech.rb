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
require 'open3'
require_relative 'util.rb'

module SpeechToText
  module MozillaDeepspeechS2T # rubocop:disable Style/Documentation
    include Util

    def self.create_job(audio, server_url, jobdetails_json, api_key)
      request = "curl -F \"file=@#{audio}\" \"#{server_url}/deepspeech/createjob/#{api_key}\" > #{jobdetails_json}"
      
      Open3.popen2e(request) do |stdin, stdout_err, wait_thr|
        while line = stdout_err.gets
          puts "#{line}"
        end

        exit_status = wait_thr.value
        unless exit_status.success?
          puts '---------------------'
          puts "FAILED to execute --> #{request}"
          puts '---------------------'
        end
      end

      file = File.open(jobdetails_json, 'r')
      data = JSON.load file
      data['job_id']
    end

    def self.checkstatus(job_id, server_url, api_key)
      uri = URI.parse("#{server_url}/deepspeech/checkstatus/#{job_id}/#{api_key}")
      request = Net::HTTP::Post.new(uri)

      req_options = {
        use_ssl: uri.scheme == "https",
      }

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end
      data = JSON.load response.body
      data['status']
    end

    def self.order_transcript(job_id, server_url, api_key)
      uri = URI.parse("#{server_url}/deepspeech/transcript/#{job_id}/#{api_key}")
      request = Net::HTTP::Post.new(uri)

      req_options = {
        use_ssl: uri.scheme == "https",
      }

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end
      data = JSON.load response.body
      data
    end

    # used by deepspeech server only
    def self.generate_transcript(audio, json_file, model_path)
      #deepspeech_command = "#{model_path}/deepspeech --model #{model_path}/models/output_graph.pbmm --alphabet #{model_path}/models/alphabet.txt --lm #{model_path}/models/lm.binary --trie #{model_path}/models/trie -e --audio #{audio} > #{json_file}"
      deepspeech_command = "deepspeech --json --model #{model_path}/deepspeech-0.6.1-models/output_graph.pbmm --lm #{model_path}/deepspeech-0.6.1-models/lm.binary --trie #{model_path}/deepspeech-0.6.1-models/trie --audio #{audio} > #{json_file}"
      Open3.popen2e(deepspeech_command) do |stdin, stdout_err, wait_thr|
        while line = stdout_err.gets
          puts "#{line}"
        end

        exit_status = wait_thr.value
        unless exit_status.success?
          puts '---------------------'
          puts "FAILED to execute --> #{deepspeech_command}"
          puts '---------------------'
        end
      end

    end

    # rubocop:disable Metrics/MethodLength
    def self.create_mozilla_array_old(data) # rubocop:disable Metrics/AbcSize
      i = 0
      myarray = []
      while i < data['words'].length
        myarray.push(data['words'][i]['time'].to_f)
        endtime = if i == data['words'].length - 1
                    data['file']['duration'].to_f
                  else
                    data['words'][i + 1]['time'].to_f
                  end
        myarray.push(endtime)
        myarray.push(data['words'][i]['word'])
        i += 1
      end
      myarray
    end


    def self.create_mozilla_array(data) # rubocop:disable Metrics/AbcSize
      i = 0
      myarray = []
      while i < data['words'].length
        myarray.push(data['words'][i]['start_time'].to_f)
        endtime = data['words'][i]['start_time'].to_f + data['words'][i]['duration'].to_f
        myarray.push(endtime)
        myarray.push(data['words'][i]['word'])
        i += 1
      end
      myarray
    end
    # rubocop:enable Metrics/MethodLength
  end
end
