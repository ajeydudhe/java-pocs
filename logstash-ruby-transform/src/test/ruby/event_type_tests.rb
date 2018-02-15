require_relative "./core/es_transform_test_core"

module EsTransform
  module Tests
    class EventTypeTests < EsTransform::EsTestClassBase
      def initialize()
        super(1234, 'event-1234')
      end
      
      def test_does_nothing()
        raw_event = get_base_event()
        
        transformed_event = transform(raw_event)

        insist {transformed_event.get('type')} == 'abc'
      end
                  
    end
  end
end  
