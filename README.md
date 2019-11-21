# SpeechToText

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/speech_to_text`. To experiment with that code, run `bin/console` for an interactive prompt.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'speech_to_text'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install speech_to_text

## Usage
BigBlueButton provides various captions services.
Use following command to access the different services.

STEP 1. Video to Audio

You have to convert video to audio using following command
for example,your video is inside "/home/abc/xyz/video.mp4" and you want audio in other directory "/home/bbb/audio.mp3"
```ruby
SpeechToText::Util.video_to_audio(video_file_path:"/home/abc/xyz",
                                  video_name:"video",
                                  video_content_type: "mp4",
                                  audio_file_path:"/home/bbb",
                                  audio_name:"audio",
                                  audio_content_type:"mp3",
                                  start_time: '0',
                                  duration: '20')

#start_time and duration are optional parameters
```
STEP 2. Get array using any service given below

Then based on the service you can execute one of the following command.

=>if service = ibm, execute following commands
```ruby
#example values
audio_file_path = "/home/bbb"
apikey = "<apikey>" #provided by IBM
audio = "audio"
content_type = "mp3"
language_code = "en-US" #check this for language_code: https://github.com/silentflameCR/text-track-service
job_id = SpeechToText::IbmWatsonS2T.create_job(audio_file_path:"/home/bbb",
                                                apikey:"<apikey>",
                                                audio:"audio",
                                                content_type:"mp3",
                                                language_code:"en-US")

data = SpeechToText::IbmWatsonS2T.check_job(job_id,apikey)
myarray = SpeechToText::IbmWatsonS2T.create_array_watson(data["results"][0])
```

=>if service = google,

Execute following command in order to set environment
```ruby
SpeechToText::GoogleS2T.set_environment("<google_auth_file>")
```
After setting environment, execute following commands to get google transcription
bucket_name could be any string
```ruby
#example value
  audio_file_path = "/home/bbb"
  audio_name = "audio"
  audio_content_type = "mp3"
  bucket_name = "mybucket"
  language_code = "en-US" #check this for language_code:https://github.com/silentflameCR/text-track-service

file = SpeechToText::GoogleS2T.google_storage(audio_file_path,audio_name,audio_content_type,bucket_name)
operation_name = SpeechToText::GoogleS2T.create_job(audio_name,audio_content_type,bucket_name,language_code)
data = SpeechToText::GoogleS2T.check_status(operation_name)
myarray = SpeechToText::GoogleS2T.create_array_google(data["results"])
SpeechToText::GoogleS2T.delete_google_storage(bucket_name,audio_name,audio_content_type)
```

=>if service = mozilla_deepspeech

```ruby
#example values
 audio = "/home/bbb/audio.wav" #audio should be in wav format
 server_url = "http://localhost:4000"

#function will make a http post request to server_url/deepspeech/createjob
jobID = SpeechToText::MozillaDeepspeechS2T.create_job(audio,server_url,jobdetails_json)

#function will make a http get request to server_url/deepspeech/checkstatus/"<jobID>"
status = SpeechToText::MozillaDeepspeechS2T.checkstatus(jobID,server_url)

#only if status == "completed"
data = SpeechToText::MozillaDeepspeechS2T.order_transcript(jobID,server_url)
myarray = SpeechToText::MozillaDeepspeechS2T.create_mozilla_array(data)
```

=>if service = speechmatics

```ruby
#example values
  audio_file_path = "/home/bbb"
  audio_name = "audio"
  audio_content_type = "mp3"
  userID = "12345"  #provided by speechmetics
  authKey = "<authKey>" #provided by speechmatics
  jobID_json_file = "/home/bbb/audio/jobid.json" #method will create json file with job details
  model = "en-US" #check this for model:https://github.com/silentflameCR/text-track-service

jobID = SpeechToText::SpeechmaticsS2T.create_job(audio_file_path,audio_name,audio_content_type,userID,authKey,model,jobID_json_file)
wait_time = SpeechToText::SpeechmaticsS2T.check_job(userID,jobID,authKey)
#if wait_time is nil
data = SpeechToText::SpeechmaticsS2T.get_transcription(userID,jobID,authKey)
myarray = SpeechToText::SpeechmaticsS2T.create_array_speechmatic data
```

=>if service = 3playmedia,

```ruby
#example values,
  audio = "/home/bbb/audio.mp3"
  name = "test1"
  api_Key = "<a_id_Key>" #provided by 3playmedia
  turnaround_level_id = 5 #could be any number between 1 to 6. simply means the level of priority. 1 means lowest priority.
  output_format_id = 139 #use 139 for vtt file and 7 for srt file
  jobID_json_file = "/home/bbb/audio/jobid.json" #method will create json file with job details
  vtt_file = "/home/bbb/vttfile.vtt"

job_id = SpeechToText::ThreePlaymediaS2T.create_job(api_key,audio_file,name,jobID_json_file)
transcript_id = SpeechToText::ThreePlaymediaS2T.order_transcript(api_key,job_id,turnaround_level_id)
status = SpeechToText::ThreePlaymediaS2T.check_status(api_key,transcript_id)
SpeechToText::ThreePlaymediaS2T.get_vttfile(api_key,output_format_id,transcript_id,vtt_file)
```


Final step:
once you get the myarray, you can execute command to create vtt file

```ruby
#example values
vtt_file_path = "/home/bbb"
vtt_file_name = "vttfile.vtt"

SpeechToText::Util.write_to_webvtt(vtt_file_path: "vtt_file_path", vtt_file_name: "vtt_file_name", myarray: myarray, start_time: "5")
```

NOTE: if you choose 3playmedia then you don't need to create myarray, you will directly get the vtt file
## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

NOTE : After your changes execute this commands
1. Build your gem file : 'gem build speech_to_text.gemspec'
2. Install your gem file : 'gem install speech_to_text-0.1.2.gem'                  //replace the version number
3. 'bundle install'                                                                //optional command

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/speech_to_text.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
