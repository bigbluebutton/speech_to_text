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

    def self.create_job(audio, server_url, jobdetails_json)
      request = "curl -F \"file=@#{audio}\" \"#{server_url}/deepspeech/createjob\" > #{jobdetails_json}"
      Open3.popen2e(request) do |stdin, stdout_err, wait_thr|
        while line = stdout_err.gets
          puts "#{line}"
        end

        exit_status = wait_thr.value
        unless exit_status.success?
          puts '---------------------------------------------------------------------------'
          puts "FAILED to execute --> #{request}"
          puts '---------------------------------------------------------------------------'
        end
      end
      file = File.open(jobdetails_json, 'r')
      data = JSON.load file
      data['job_id']
    end

    def self.checkstatus(job_id, server_url)
      uri = URI.parse("#{server_url}/deepspeech/checkstatus/#{job_id}")
      response = Net::HTTP.get_response(uri)
      data = JSON.load response.body
      data['status']
    end

    def self.order_transcript(job_id, server_url)
      uri = URI.parse("#{server_url}/deepspeech/transcript/#{job_id}")
      response = Net::HTTP.get_response(uri)
      data = JSON.load response.body
      data
    end

    # used by deepspeech server only
    def self.generate_transcript(audio, json_file, model_path)
      deepspeech_command = "#{model_path}/deepspeech --model #{model_path}/models/output_graph.pbmm --alphabet #{model_path}/models/alphabet.txt --lm #{model_path}/models/lm.binary --trie #{model_path}/models/trie -e --audio #{audio} > #{json_file}"
      system(deepspeech_command.to_s)
    end

    # rubocop:disable Metrics/MethodLength
    def self.create_mozilla_array(data) # rubocop:disable Metrics/AbcSize
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
    # rubocop:enable Metrics/MethodLength
  end
end
