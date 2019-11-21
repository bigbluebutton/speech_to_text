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
                             myarray:,
                             start_time:)

      start_time = start_time.to_i
      filename = "#{vtt_file_path}/#{vtt_file_name}"
      file = File.open(filename, 'w')
      file.puts "WEBVTT\n\n"

      i = 0
      while i < myarray.length

        file.puts i / 30 + 1
        if i + 28 < myarray.length
          file.puts "#{seconds_to_timestamp (myarray[i] + start_time).to_i} --> #{seconds_to_timestamp (myarray[i + 28] + start_time).to_i}"
          file.puts "#{myarray[i + 2]} #{myarray[i + 5]} #{myarray[i + 8]} #{myarray[i + 11]} #{myarray[i + 14]}"
          file.puts "#{myarray[i + 17]} #{myarray[i + 20]} #{myarray[i + 23]} #{myarray[i + 26]} #{myarray[i + 29]}\n\n"
        else
          remainder = myarray.length - i
          file.puts "#{seconds_to_timestamp (myarray[i] + start_time).to_i} --> #{seconds_to_timestamp (myarray[myarray.length - 2] + start_time).to_i}"
          count = 0
          flag = true
          while count < remainder
            file.print "#{myarray[i + 2]} "
            if flag # rubocop:disable Metrics/BlockNesting
              # rubocop:disable Metrics/BlockNesting
              if count > 9
                file.print "\n"
                flag = false
              end
              # rubocop:enable Metrics/BlockNesting
            end
            i += 3
            count += 3
          end
        end
        i += 30
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
