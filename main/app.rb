require 'json'
require 'aws-sdk-s3'
require "image_processing/mini_magick"

def lambda_handler(event:, context:)
  event = event['Records'].first
  object_name = event['s3']['object']['key']
  s3 = Aws::S3::Resource.new
  object = s3.bucket('kosube').object(object_name)

  original_file = "/tmp/#{object_name}"
  thumbnail_file = "/tmp/thu_#{object_name}"
  low_res_file = "/tmp/low_#{object_name}"
  object.get response_target: original_file

  ImageProcessing::MiniMagick.source(original_file).convert("jpg").saver(quality: 100).resize_to_fill(100, 100, gravity: 'Center').call(destination: thumbnail_file)
  ImageProcessing::MiniMagick.source(original_file).convert("jpg").saver(quality: 90).resize_to_limit(1200, 1200).call(destination: low_res_file)
  s3.bucket('kosube-thumbnail').object("thu_#{object_name}").upload_file(thumbnail_file)
  s3.bucket('kosube-low').object("low_#{object_name}").upload_file(low_res_file)

  File.delete(original_file) if File.exists?(original_file)
  File.delete(thumbnail_file) if File.exists?(thumbnail_file)
  File.delete(low_res_file) if File.exists?(low_res_file)
  { statusCode: 200, body: {}.to_json }
end
