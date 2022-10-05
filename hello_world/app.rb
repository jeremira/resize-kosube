require 'httparty'
require 'json'
require 'aws-sdk-s3'
#require "mini_magick"
require "image_processing/mini_magick"

def lambda_handler(event:, context:)
    event = event['Records'].first
    object_name = event['s3']['object']['key']
    s3 = Aws::S3::Resource.new
    object = s3.bucket('kosube').object(object_name)
    original_file = "/tmp/#{object_name}"
    thumbnail_file = "/tmp/thu_#{object_name}"
    # low_res_file = "/tmp/low_#{object_name}"
    object.get response_target: original_file

    # image = MiniMagick::Image.open original_file
    # image.resize "100x100"
    # image.format "jpg"
    # image.quality 100
    # image.write thumbnail_file
    # ImageProcessing::MiniMagick.source(original_file).convert("jpg").saver(quality: 100).resize_to_fill(100, 100, gravity: 'Center').call(destination: thumbnail_file)
    ImageProcessing::Vips.source(original_file).convert("jpg").saver(quality: 100).resize_to_fill(100, 100, crop: :center).call(destination: thumbnail_file)
  #   ImageProcessing::Vips.source(original_file).convert("jpg").saver(quality: 95).resize_to_limit(1200, 1200).call(destination: low_res_file)
  #
    s3.bucket('kosube-thumbnail').object("thu_#{object_name}").upload_file(thumbnail_file)
  #   s3.bucket('kosube-low').object("low_#{object_name}").upload_file(low_res_file)

  {
    statusCode: 200,
    body: {object_name: object_name}.to_json
  }
end
# https://github.com/stechstudio/libvips-lambda
# script ton zip a layer
# ==============================
#   LAYER_NAME="layer-kosube-gems"
#   mkdir $LAYER_NAME && cd $_
#
#   bundle init
#   bundle add httparty --skip-install
#   bundle add json --skip-install
#   bundle add aws-sdk-s3 --skip-install
#   bundle add image_processing --skip-install
#   rm Gemfile.lock
#
# docker run --rm -v $PWD:/var/layer \
#            -w /var/layer \
#            amazon/aws-sam-cli-build-image-ruby2.7 \
#            bundle install --path=ruby
#
# sudo mv ruby/ruby ruby/gems
# zip -r layer.zip ruby
# #
# aws lambda publish-layer-version \
#            --layer-name $LAYER_NAME \
#            --region eu-west-1 \
#            --compatible-runtimes ruby2.7 \
#            --zip-file fileb://layer.zip
