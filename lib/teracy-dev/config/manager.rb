require_relative '../logging'
require_relative '../util'

module TeracyDev
  module Config
    # Manage the vagrant configuration from the provided settings hash object
    class Manager
      @@instance = nil

      def initialize
        if !!@@instance
          raise "TeracyDev::Config::Manager can only be initialized once"
        end
        @@instance = self

        @logger = TeracyDev::Logging.logger_for(self.class.name)
        @configurators = []
      end

      def register(configurator, weight)
        if !configurator.respond_to?(:configure)
          @logger.warn("configurator #{configurator} must implement configure method, ignored")
          return
        end

        unless weight.is_a? Integer and (0..9).include?(weight)
          @logger.warn("#{configurator}'s weight must be integer and have value in range 0.. 9, otherwise weight will be set to default (5)")
          weight = 5
        end

        @configurators << { configurator: configurator, id: @configurators.length, weight: weight }
        # @logger.warn("configurators before: #{@configurators.to_yaml}")
        @logger.debug("configurator: #{configurator} registered")
      end

      def configure(settings, config, type:)
        @logger.debug("configure #{type}: #{config} with #{settings}")

        TeracyDev::Util.multi_sort(@configurators, weight: :desc, id: :asc).each do |configurator|
          configurator[:configurator].configure(settings, config, type: type)
        end
      end

    end
  end
end
