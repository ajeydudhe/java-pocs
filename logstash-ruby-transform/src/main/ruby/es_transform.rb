# encoding: utf-8

require "logstash/filters/mutate"
require "logstash/filters/date"
require "logstash/logging/logger"

def register(params)
	$LOG = LogStash::Logging::Logger.new('es_transform_script')
	@transformation = EsTransformation.new
end

def filter(event)
	@transformation.process(event)
	return [event]
end

class EsTransformation

	# Adding as static method since class cannot directly access global methods while executing in logstash
	def self.create_filter(filter_class, parameters)
		instance = filter_class.new(parameters)
		instance.register()
		return instance
	end

	# To add event type specific configuration add a method with name starting with configure_event* e.g. configure_event_4096 as follows.
	def configure_event_1234()

	    For.event(1234)
  		   .convert_to_int('category_id')
  		   .rename({'ruleId' => 'rule_id', 'ruleVersion' => 'rule_version'})
  		   .build(@filters_by_type)
	end	
	
	# Or add everything in single method
	def configure_event_all()
		
	end 
	
	# Other initializations
	def initialize()

		@common_filters = [EsSetEventTypeFilter.new()]
	    @filters_by_type = {}

	    # To configure each event type add a method with name as configure_event_<event_id> e.g. configure_event_1234
	    self.methods.each do |method_name|

	    	if method_name.to_s.start_with?('configure_event_') 
		    	self.method(method_name).call()
		    	$LOG.info('Invoked configuration method: ' + method_name.to_s)
		    end	
	    end
	end
	
	def process(event)
    	errors_during_processing = !process_filters(event, @common_filters)
    
		event_filters = @filters_by_type[event.get('event_id')]
		errors_during_processing |= !process_filters(event, event_filters)
		
		$LOG.error('Error(s) occurred while transforming event. Raising exception.') if errors_during_processing
		# TODO: Check the logstash behavior if it supresses the event processing or continues with event upload with whatever transformation is being done !
		raise 'Error(s) occurred while transforming event.' if errors_during_processing	
	end	

	def process_filters(event, filters)
	  no_errors = true
		if filters
			filters.each do |event_filter| 
  				begin
  					event_filter.filter(event)
  				rescue => e
            no_errors = false
  					$LOG.error('An error occurred while executing filter on event.',
                       :error_message => e.message,
                       :class => e.class.name,
                       :backtrace => e.backtrace,
                       :event => event.to_json) # Should we log event?
  				end
			end
		end
    return no_errors
	end	
end	

class EsTransformFilterBuilder

	def initialize(key)
		@key_name = key
	end

	def rename(keys_to_rename)
		@mutate_rename_config = keys_to_rename
		return self
	end	

	def convert_to_int(*key_names)
		@mutate_convert_config ||= {}

		key_names.each { |key| @mutate_convert_config[key] = 'integer'}

		return self
	end	

	def date(*key_names)
		@date_filter_configurations ||= []

		key_names.each do |key| 
	
			config_template = {'match' => ['my_dummy_field', "ISO8601", "yyyy-MM-dd'T'HH:mm:ss", "EEE, dd MMM yyyy HH:mm:ss ZZZ", "EEE, dd MMM yyyy HH:mm:ss"]}
			config_template['match'][0] = key
			config_template['target'] = key
			config_template['timezone'] = 'GMT'

			@date_filter_configurations.push(config_template)
		end

		return self
	end	

	def remove(*keys_to_remove)
		@mutate_remove_config = keys_to_remove
		return self
	end

	def remove_if_empty(*keys_to_remove)
		@remove_if_empty_config = keys_to_remove
		return self
	end
	
    def rename_array_fields(fields)
        @rename_fields_in_array = fields
        return self
    end
        
	def build(filters)
		filters_for_key = []

		add_mutate_filter(filters_for_key)
		add_date_filters(filters_for_key)
		add_remove_if_empty_filters(filters_for_key)
		
		filters[@key_name] = filters_for_key
	end

	def add_mutate_filter(filters_for_key)
		mutate_filter_config = {}

		append_filter_config('rename', @mutate_rename_config, mutate_filter_config)
		append_filter_config('convert', @mutate_convert_config, mutate_filter_config)
		append_filter_config('remove_field', @mutate_remove_config, mutate_filter_config)

		if not mutate_filter_config.empty?
			filters_for_key.push(EsTransformation::create_filter(LogStash::Filters::Mutate, mutate_filter_config))
		end
	end

	def add_date_filters(filters_for_key)
		if @date_filter_configurations
			@date_filter_configurations.each do |config| 
				filters_for_key.push(EsTransformation::create_filter(LogStash::Filters::Date, config))
			end
		end	
	end

	def add_remove_if_empty_filters(filters_for_key)
		if @remove_if_empty_config
			@remove_if_empty_config.each do |key| 
				filters_for_key.push(EsRemoveIfEmptyFilter.new(key))	
			end
		end	
	end

	def append_filter_config(action_name, action_config, filter_config)
		if action_config
			filter_config[action_name] = action_config
		end	
	end	
end	

class For < EsTransformFilterBuilder
	def initialize(event_type)
		super(event_type)
	end

	def self.event(event_type)
		return For.new(event_type)
	end	
end

class EsRemoveIfEmptyFilter
	def initialize(key_name)
		@key_name = key_name
		remove_field_config = {}
		remove_field_config['remove_field'] = [key_name]
		@remove_field = EsTransformation::create_filter(LogStash::Filters::Mutate, remove_field_config)
	end	
	def filter(event)
		value = event.get(@key_name)
		if not value.nil? and value.blank?
			@remove_field.filter(event)
		end	
	end	
end

class EsSetEventTypeFilter
	def filter(event)
		value = event.get('[@metadata][_index]')

		if value.start_with?('users_')
			event.set('[type]', 'user')	
		elsif value.start_with?('files_')
			event.set('[type]', 'file')	
		else
			event.set('[type]', 'event')	
		end	
					
	end	
end