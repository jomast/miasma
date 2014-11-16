require 'miasma'

module Miasma
  # Generic Error class
  class Error < StandardError

    # Create new error instance
    #
    # @param msg [String] error message
    # @param args [Hash] optional arguments
    # @return [self]
    def initialize(msg, args={})
      super msg
    end

    # Api related errors
    class ApiError < Error

      # @return [HTTP::Response] result of bad request
      attr_reader :response
      # @return [String] response error message
      attr_reader :response_error_msg

      # Create new API error instance
      #
      # @param msg [String] error message
      # @param args [Hash] optional arguments
      # @option args [HTTP::Response] :response response from request
      def initialize(msg, args={})
        super
        @response = args.to_smash[:response]
        extract_error_message(@response)
      end

      # @return [String] provides response error suffix
      def message
        [@message, @response_error_msg].compact.join(' - ')
      end

      # Attempt to extract error message from response
      #
      # @param response [HTTP::Response]
      # @return [String, NilClass]
      def extract_error_message(response)
        begin
          begin
            content = MultiJson.load(response.body.to_s).to_smash
            msgs = content.values.map do |arg|
              arg[:message]
            end.compact
            unless(msgs.empty?)
              @response_error_msg = msgs.join(' - ')
            end
          rescue MultiJson::ParseError
            begin
              content = MultiXml.parse(response.body.to_s).to_smash
              if(content.get('ErrorResponse', 'Error'))
                @response_error_msg = "#{content.get('ErrorResponse', 'Error', 'Code')}: #{content.get('ErrorResponse', 'Error', 'Message')}"
              end
            rescue MultiXml::ParseError
              content = Smash.new
            end
          rescue
            # do nothing
          end
        end
        @response_error_msg
      end

      # Api request error
      class RequestError < ApiError; end

      # Api authentication error
      class AuthenticationError < ApiError; end

    end

    # Orchestration error
    class OrchestrationError < Error
      # Template failed to validate
      class InvalidTemplate < OrchestrationError
      end
    end

    # Invalid modification request
    class ImmutableError < Error; end

  end
end
