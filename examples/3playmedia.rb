require 'json'

#method will create job and retun job_id
#Note that it will not generate captions automatically
#you have to tell 3playmedia to generate captions depending on turnaround_level_id(could be anything between 1 to 6 depending on urgency level)
#turnaround_level_id = 6 mean highest priority and minimum amout of time
def create_job(api_key,audio_file,name,create_job_file)
  cretae_job_command = "curl -X POST -F \"source_file=@#{audio_file}\" \"https://api.3playmedia.com/v3/files?api_key=#{api_key}&language_id=1&name=#{name}\" > #{create_job_file}"
  system(cretae_job_command)
  file = File.open(create_job_file, "r")
  response = JSON.load file
  job_id = response["data"]["id"]
  return job_id
end

#get transcription id so you can check status of transcription
def order_transcript(api_key,job_id,turnaround_level_id,order_transcript_file)
  order_transcript_commad = "curl -X POST \"https://api.3playmedia.com/v3/transcripts/order/transcription?api_key=#{api_key}&media_file_id=#{job_id}&turnaround_level_id=#{turnaround_level_id}\" >#{order_transcript_file}"
  system(order_transcript_commad)
  file = File.open(order_transcript_file, "r")
  response = JSON.load file
  transcript_id = response["data"]["id"]
  return transcript_id
end

def check_status(api_key,transcript_id,status_file)
  check_status_command = "curl \"https://api.3playmedia.com/v3/transcripts/#{transcript_id}?api_key=#{api_key}\">#{status_file}"
  system(check_status_command)
  file = File.open(status_file, "r")
  response = JSON.load file
  status = response["data"]["status"]
  return status
end

def download_transcript(api_key,output_format_id,transcript_id,trascript_json_file)
download_transcript_command = "curl \"https://api.3playmedia.com/v3/transcripts/#{transcript_id}/text?api_key=#{api_key}&output_format_id=#{output_format_id}\" > #{trascript_json_file}"
system(download_transcript_command)
end

def create_vttfile(trascript_json_file,vtt_file)
  file = File.open(trascript_json_file,"r")
  response = JSON.load file
  data = response["data"]
  file.close
  out = File.open(vtt_file,"w")
  out.puts data
  out.close
end

def deleteFiles(create_job_file,order_transcript_file,status_file,trascript_json_file)
  File.delete(create_job_file)
  File.delete(order_transcript_file)
  File.delete(status_file)
  File.delete(trascript_json_file)
end
#---------------------
#main code starts here
#---------------------

api_key = ARGV[0]
audio_file = ARGV[1] #full audio path /home/a/b/audio.flac
name = ARGV[2] #anything to identify job (can be duplicate doesn't really matter)
turnaround_level_id = ARGV[3] #could be anything between 1 to 6 (1 means lowest priority)
output_format_id = ARGV[4] # output format could be anything, i.e plain text, srt file, vttfile etc..  use 139 for vtt_file and 7 for srt file

#json file list
create_job_file = ARGV[5] #/home/a/b/xyz.json
order_transcript_file = ARGV[6] #/home/a/b/abc.json
status_file = ARGV[7] #/home/a/b/mn.json
trascript_json_file = ARGV[8] #/home/a/b/xxx.json

#vtt file list
vtt_file = ARGV[9] #/home/a/b/vttfile.vtt

job_id = create_job(api_key,audio_file,name,create_job_file)
transcript_id = order_transcript(api_key,job_id,turnaround_level_id,order_transcript_file)
status = check_status(api_key,transcript_id,status_file)
second = 0 #remove me
while (status!="complete")
  status = check_status(api_key,transcript_id,status_file)
  puts status
  puts second
  if(status == "cancelled")
    break
  end
  sleep(30)
  second += 31  #remove me, it is just to check time
end

if(status == "complete")
  download_transcript(api_key,output_format_id,transcript_id,trascript_json_file)
  create_vttfile(trascript_json_file,vtt_file)
  deleteFiles(create_job_file,order_transcript_file,status_file,trascript_json_file)
end
