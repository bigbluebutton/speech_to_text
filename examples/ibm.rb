
require "speech_to_text"
require("ibm_watson/speech_to_text_v1")

published_files_path = ARGV[0] 
recordID = ARGV[1] 
apikey = ARGV[2]

#SpeechToText::IbmWatsonS2T.ibm_speech_to_text(published_files_path, recordID, apikey)

# If using IAM
speech_to_text = IBMWatson::SpeechToTextV1.new(
  iam_apikey: apikey
)

# If you have username & password in your credentials use:
# speech_to_text = IBMWatson::SpeechToTextV1.new(
#   username: "YOUR SERVICE USERNAME",
#   password: "YOUR SERVICE PASSWORD"
# )

#puts JSON.pretty_generate(speech_to_text.list_models.result)

#puts JSON.pretty_generate(speech_to_text.get_model(model_id: "en-US_BroadbandModel").result)

#File.open(Dir.getwd + "/resources/test/speech.wav") do |audio_file|
#  recognition = speech_to_text.recognize(
#    audio: audio_file,
#    content_type: "audio/wav",
#    timestamps: true,
#    word_confidence: true
#  ).result
#  puts JSON.pretty_generate(recognition)
#end

audio_file = File.open(Dir.getwd + "/resources/test/speech.wav")
service_response = speech_to_text.create_job(
  audio: audio_file,
  content_type: "audio/wav"
)

puts "Create Job Result = \n" 
puts service_response.result

#{"created"=>"2019-07-05T19:50:00.692Z", "id"=>"130f8d94-9f5e-11e9-a0f3-1b7c22e37cb8", "url"=>"https://stream.watsonplatform.net/speech-to-text/api/v1/recognitions/130f8d94-9f5e-11e9-a0f3-1b7c22e37cb8", "status"=>"processing"}

job_id = service_response.result["id"]

puts "job_id=#{job_id}"
service_response = speech_to_text.check_job(id: job_id)
puts "CHECK JOB RESULT = \n"
puts service_response.result

service_response = speech_to_text.check_jobs
puts "GET JOBS RESULT = \n"
puts service_response.result


