# Set encoding to utf-8
# encoding: UTF-8

#
# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/
#
# Copyright (c) 2019 BigBlueButton Inc. and by respective authors (see below).
#

module SpeechToText
  module Util
    #function to convert the time to a timestamp
    def self.seconds_to_timestamp number
      ss = number
      mm = ss / 60
      hh = (number/3600).floor
      number = number % 3600
      mm = (number / 60).floor
      ss = (number % 60).round(3)
      if ss < 10
        ss = "0#{ss.to_s}"
      end
      parts = ss.to_s.split(".")
      if parts.length > 1
        1.upto (3-parts[1].length) {parts[1] = parts[1].concat("0")}
        ss = "#{parts[0]}.#{parts[1]}"
      else
            ss = parts[0].concat(".000")
      end
      if mm < 10
        mm = "0#{mm.to_s}"
      end
      if hh < 10
        hh = "0#{hh.to_s}"
      end
      return "#{hh}:#{mm}:#{ss}"
    end

    #create and write the webvtt file
    def self.write_to_webvtt(published_files,recordID,myarray)
      filename = "#{published_files}/#{recordID}/caption_en_US.vtt"
      file = File.open(filename,"w")
      file.puts ("WEBVTT\n\n")

      i = 0

      while(i < myarray.length)

        file.puts i/30 + 1
        if i + 28 < myarray.length
          file.puts "#{seconds_to_timestamp myarray[i]} --> #{seconds_to_timestamp myarray[i + 28]}"
          file.puts "#{myarray[i + 2]} #{myarray[i + 5]} #{myarray[i + 8]} #{myarray[i + 11]} #{myarray[i + 14]}"
          file.puts "#{myarray[i + 17]} #{myarray[i + 20]} #{myarray[i + 23]} #{myarray[i + 26]} #{myarray[i + 29]}\n\n"
        else
          remainder = myarray.length - i
          file.puts "#{seconds_to_timestamp myarray[i]} --> #{seconds_to_timestamp myarray[myarray.length - 2]}"
          count = 0
          flag = true
          while (count < remainder )
            file.print "#{myarray[i + 2]} "
            if flag
              if count > 9
                file.print "\n"
                flag = false
              end
            end
            i += 3
            count += 3
          end
        end
        i = i + 30
      end

      file.close

      #system(scp -v "#{$published_files}/caption_en_US.vtt" "#{$captions_inbox_path}/#{$meeting_id}-#{$current_time}-track.txt")
      captions_file_name = "#{published_files}/#{recordID}/captions.json"
      captions_file = File.open(captions_file_name,"w")
      captions_file.puts ("[{\"localeName\": \"English (United States)\", \"locale\": \"en_US\"}]")
    end

    def self.convert_video_to_audio(recordings_dir, provider)
      if provider == "google" || provider == "ibm"
        video_to_audio_command = "ffmpeg -i #{recordings_dir}/video/video.mp4 -ac 1 -ar 16000 #{recordings_dir}/audio.flac"
        system("#{video_to_audio_command}")
      elsif provider == "mozilla_deepspeech"
          video_to_audio_command = "ffmpeg -i #{recordings_dir}/video/video.mp4 -ac 1 -ar 16000 #{recordings_dir}/audio.wav"
          system("#{video_to_audio_command}")
      elsif provider == "speechmatics"
          video_to_audio_command = "ffmpeg -i #{recordings_dir}/video/video.mp4 #{recordings_dir}/audio.mp3"
          system("#{video_to_audio_command}")
      else
        # TODO:
        # Should throw exception here
          puts "No provider found....."
      end
    end
  end
end
