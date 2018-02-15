# Following needs to be defined here else it throw not initialized error
require "treetop/ruby_extensions/string"
require "logstash/codecs/base"
require "logstash/instrument/namespaced_null_metric"
require "logstash/event"
require "insist"

require_relative "../../../main/ruby/es_transform"

module EsTransform
  class EsTransformScriptFilter
    def self.register_filter()
      register({})
    end
    def self.execute_filter(event)
      return filter(event)[0]
    end
  end  
  
  EsTransformScriptFilter::register_filter()
  
  class EsTestClassBase
    def initialize(event_type, index)
      @event_type = event_type
      @index = index
    end  
    
    def transform(event)
      return EsTransformScriptFilter::execute_filter(event)
    end
    
    def assert_rename(event, old_name, new_name, value)
      raise Insist::Failure.new("New field name '#{new_name}' is not present in the event after renaming from '#{old_name}'.") if !event.include?(new_name)
      
      insist {event.get(new_name)} == value
      
      raise Insist::Failure.new("Old field name '#{old_name}' is still present in the event after renaming to '#{new_name}'.") if event.include?(old_name)
    end
        
    def get_base_event()
      
      event = LogStash::Event.new({'@metadata' => {}})
      
      set_event_type(event, @event_type)
      set_event_index(event, @index)
        
      return event    
    end
    
    def set_event_type(event, type)
      event.set('[@metadata][_type]', type)
      event.set('type_id', type)
    end
    
    def set_event_index(event, index)
      event.set('[@metadata][_index]', index)
    end
          
  end
end  
