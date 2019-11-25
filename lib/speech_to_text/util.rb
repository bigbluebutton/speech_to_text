# frozen_string_literal: true

# Set encoding to utf-8
# encoding: UTF-8

#
# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/
#
# Copyright (c) 2019 BigBlueButton Inc. and by respective authors (see below).
#
require 'open3'

module SpeechToText
  module Util # rubocop:disable Style/Documentation
    # function to convert the time to a timestamp
    # rubocop:disable Metrics/MethodLength
    def self.seconds_to_timestamp(number) # rubocop:disable Metrics/AbcSize
      hh = (number / 3600).floor
      number = number % 3600
      mm = (number / 60).floor
      ss = (number % 60).round(3)
      ss = "0#{ss}" if ss < 10
      parts = ss.to_s.split('.')
      if parts.length > 1
        1.upto(3 - parts[1].length) { parts[1] = parts[1].concat('0') }
        ss = "#{parts[0]}.#{parts[1]}"
      else
        ss = parts[0].concat('.000')
      end
      mm = "0#{mm}" if mm < 10
      hh = "0#{hh}" if hh < 10
      "#{hh}:#{mm}:#{ss}"
    end
    # rubocop:enable Metrics/MethodLength
    # create and write the webvtt file
    # rubocop:disable Metrics/MethodLength
    def self.write_to_webvtt(vtt_file_path:, # rubocop:disable Metrics/AbcSize
                             vtt_file_name:,
                             text_array:,
                             start_time:)
      # Array format 
      # text_array = [start_timestamp, end_timestamp, word, start_time, end_time, word, ...]
      
      # if we cut first few minutes from the audio then 
      # start time will be replaced instead of 0
      start_time = start_time.to_i 

      filename = "#{vtt_file_path}/#{vtt_file_name}"
      file = File.open(filename, 'w')
      file.print "WEBVTT"

      i = block_number = 0
      
      #all the words are at position [2,5,8,11...]
      word_index = 2  

      # one block will give total 10 words on screen at a time
      # which contains total 30 index 
      # each word has 3 indexes in text_array [start_timestamp, end_timestamp, word,...]
      block_size = 30

      # each block contains 10 words index range o to 29
      # last end time will be at index = 28
      end_timestamp = 28

      # we need new lines after every 5 words so 6th word will be at index = 17 (6*3 - 1) 
      line_space_index = 17 

      while i < text_array.length
       
        if i%3 == word_index  #if index has word then print word
          if i%block_size == line_space_index # if this is 6th word then print new line
            file.puts
          end
          file.print "#{text_array[i]} "
        elsif i%block_size == 0  #if index is 0,30,60... means starting a new block
          block_number += 1
          file.puts "\n\n"
          file.puts block_number  #print block number 
          file.print "#{seconds_to_timestamp(text_array[i] + start_time)} "  #print start timestamps
          if i + end_timestamp < text_array.length  # End timestamp will be at 28th index in block of 30 indexes (10 words)
            file.puts "--> #{seconds_to_timestamp(text_array[i+end_timestamp] + start_time)}"
          else  # For last block, there will not be total 30 indexes, so end timestamp will be second last index
            file.puts "--> #{seconds_to_timestamp(text_array[text_array.length - 2] + start_time)}"
          end
        else          
        end
        i += 1
      end

      file.close
    end
    # rubocop:enable Metrics/MethodLength

    # rubocop:disable Naming/UncommunicativeMethodParamName
    def self.captions_json(file_path:,
                           file_name:,
                           # rubocop:disable Naming/VariableName
                           localeName:,
                           # rubocop:enable Naming/VariableName
                           locale:)
      captions_file_name = "#{file_path}/#{file_name}"
      captions_file = File.open(captions_file_name, 'w')
      line = "[{\"localeName\": \"#{localeName}\", \"locale\": \"#{locale}\"}]"
      captions_file.puts line
      captions_file.close
    end
    # rubocop:enable Naming/UncommunicativeMethodParamName

    # rubocop:disable Metrics/MethodLength
    def self.recording_json(file_path:,
                            record_id:,
                            timestamp:,
                            language:)
      filename = "#{file_path}/#{record_id}-#{timestamp}-track.json"
      file = File.open(filename, 'w')
      file.puts '{'
      file.puts "\"record_id\": \"#{record_id}\","
      file.puts '"kind": "subtitles",'
      file.puts "\"lang\": \"#{language}\","
      file.puts '"label": "English",'
      file.puts "\"original_filename\": \"caption_#{language}.vtt\","
      file.puts "\"temp_filename\": \"#{record_id}-#{timestamp}-track.txt\""
      file.puts '}'
      file.close
    end

    # rubocop:enable Metrics/MethodLength
    # def video_to_audio
    # rubocop:disable Metrics/ParameterLists
    def self.video_to_audio(video_file_path:,
                            video_name:,
                            video_content_type:,
                            audio_file_path:,
                            audio_name:,
                            audio_content_type:,
                            **duration)
      # rubocop:enable Metrics/ParameterLists
      video_to_audio_command = ''
      if duration.empty?
        video_to_audio_command = "ffmpeg -y -i #{video_file_path}/#{video_name}.#{video_content_type} -ac 1 -ar 16000 #{audio_file_path}/#{audio_name}.#{audio_content_type}"
      elsif duration[:start_time].nil? && duration[:end_time] != nil
        video_to_audio_command = "ffmpeg -y -ss #{0.to_i} -i #{video_file_path}/#{video_name}.#{video_content_type} -t #{duration[:end_time]} -ac 1 -ar 16000 #{audio_file_path}/#{audio_name}.#{audio_content_type}"
      elsif duration[:end_time].nil? && duration[:start_time] != nil
        video_to_audio_command = "ffmpeg -y -ss #{duration[:start_time]} -i #{video_file_path}/#{video_name}.#{video_content_type} -ac 1 -ar 16000 #{audio_file_path}/#{audio_name}.#{audio_content_type}"
      else
        video_to_audio_command = "ffmpeg -y -t #{duration[:end_time]} -i #{video_file_path}/#{video_name}.#{video_content_type} -ss #{duration[:start_time]} -ac 1 -ar 16000 #{audio_file_path}/#{audio_name}.#{audio_content_type}"
      end  

        Open3.popen2e(video_to_audio_command) do |stdin, stdout_err, wait_thr|
          while line = stdout_err.gets
            puts "#{line}"
          end

          exit_status = wait_thr.value
          unless exit_status.success?
            puts '---------------------'
            puts "FAILED to execute --> #{video_to_audio_command}"
            puts '---------------------'
          end
        end

        #Open3.popen3(video_to_audio_command.to_s) do |stdin, stdout, stderr, wait_thr|
        #  puts "stdout is:" + stdout.read
        #  puts "stderr is:" + stderr.read
        #end
    end
  end
end
