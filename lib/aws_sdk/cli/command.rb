require "active_support"
require "active_support/core_ext"
require "dry/cli"
require "json"
require "rexml"

module AwsSdk
  module CLI
    class Command < Dry::CLI::Command
      argument :service_name, required: true
      argument :api_name, default: nil
      argument :params, default: "{}"

      def call(service_name:, api_name: nil, params: "{}", **options)
        require "aws-sdk-#{service_name}"

        service_class_name = service_name.capitalize
        target_class = Aws.const_get(service_class_name)::Client
        unless api_name
          methods = target_class.instance_methods(false).sort.map do |m|
            m.to_s.dasherize
          end
          puts methods
          exit
        end
        parsed_params = JSON.parse(params).deep_transform_keys do |key|
          case key
          in "ETag"
            :etag
          else
            key.underscore.to_sym
          end
        end
        client = target_class.new
        response = client.__send__(api_name.underscore, parsed_params)
        hash = response.to_hash.deep_transform_keys do |key|
          case key
          in :etag
            "ETag"
          else
            key.to_s.camelize
          end
        end
        puts hash.to_json
      end
    end
  end
end
