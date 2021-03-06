# encoding: UTF-8
require 'json'

require 'factor/commands/base'
require 'factor/connector'

module Factor
  module Commands
    class RunCommand < Factor::Commands::Command
      def run(args, options)
        address      = args[0]
        parameters   = params(args[1..-1])

        load_settings(options)
        
        connector = load_connector(options, address, parameters)
        
        if options.verbose
          info "Running '#{address}(#{parameters})'"
          connector.add_observer(self, :events) 
        end
        response = connector.run

        success "Response:" if options.verbose
        @logger.indent options.verbose ? 1 : 0 do 
          info response
        end
      end

      def events(type, content)
        if type==:log
          @logger.indent {
            @logger.log(content[:type], content[:message])
          }
        end
      end

      def load_connector(options, address, parameters)
        service_name = address.split('::')[0]
        connector_settings = settings[service_name] || {}

        if options.connector
          info "Loading #{options.connector}" if options.verbose
          require options.connector
        end
        connector_class = Factor::Connector.get(address)
        raise ArgumentError, "Connector '#{address}' not found" unless connector_class

        info "Settings:   #{connector_settings || {}}" if options.verbose
        info "Parameters: #{parameters || {}}" if options.verbose

        connector = connector_class.new(parameters.merge(connector_settings))
        connector
      end
    end
  end
end
