require "google/cloud/speech"
require "google/cloud/storage"


#uploads audio file to a google bucket
def google_storage(audio_file, dest_file, bucket_name)
	storage = Google::Cloud::Storage.new project_id: bucket_name
	bucket  = storage.bucket bucket_name
	file = bucket.create_file audio_file, dest_file
	return file
end

#return the results from google speech
def google_transcription(bucket_name, dest_file)
	# Instantiates a client
	speech = Google::Cloud::Speech.new

	# The audio file's encoding and sample rate
	config = {
		      language_code:     "en-US",
		      enable_word_time_offsets: true }
	audio  = { #content: audio_file #using local audio file
		        uri: "gs://#{bucket_name}/#{dest_file}" #using the now uploaded audio file from the bucket
		      }

		  # Detects speech in the audio file
		  operation = speech.long_running_recognize config, audio

		  #puts "Operation started"

		  operation.wait_until_done!

		  raise operation.results.message if operation.error?

		  results = operation.response.results
		  return results
		end


audio_file = ARGV[0]
dest_file = ARGV[1]
bucket_name = ARGV[2]
auth_file = ARGV[3] 


ENV['GOOGLE_APPLICATION_CREDENTIALS'] = auth_file
file = google_storage(audio_file, dest_file, bucket_name)

#results = google_transcription(bucket_name, dest_file)
#puts results

speech = Google::Cloud::Speech.new

	# The audio file's encoding and sample rate
	config = {
		      language_code:     "en-US",
		      enable_word_time_offsets: true }
	audio  = { #content: audio_file #using local audio file
		        uri: "gs://#{bucket_name}/#{dest_file}" #using the now uploaded audio file from the bucket
		      }

op = speech.long_running_recognize config, audio
puts op.done?
puts op.name
#puts op.metadata

# Register a callback to be run when an operation is done.
#op.on_done do |operation|
#  raise operation.results.message if operation.error?
  # process(operation.results)
#  puts operation.results
  # process(operation.metadata)
#  puts operation.metadata
#end

#op.reload!


# get the operation's id
#id = op.id #=> "1234567890"

# construct a new operation object from the id
op2 = speech.operation op.name

# verify the jobs are the same
#op.id == op2.id #=> true

#op2.done? #=> false
#op2.wait_until_done!
#op2.done? #=> true

#results = op2.results

file.delete