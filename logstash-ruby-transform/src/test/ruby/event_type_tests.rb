require_relative "./core/es_transform_test_core"

module EsTransform
  module Tests
    class EventTypeTests < EsTransform::EsTestClassBase
      def initialize()
        super(1234, 'event-1234')
      end
      
      def test_type_event()
        raw_event = get_base_event()
        
        transformed_event = transform(raw_event)

        insist {transformed_event.get('type')} == 'event'
      end
                  
      def test_type_user()
        raw_event = get_base_event()
        
        set_event_index(raw_event, 'users-some-date')

        transformed_event = transform(raw_event)

        insist {transformed_event.get('type')} == 'user'
      end

      def test_type_file()
        raw_event = get_base_event()
        
        set_event_index(raw_event, 'files-some-date')

        transformed_event = transform(raw_event)

        insist {transformed_event.get('type')} == 'file'
      end
    end
  end
end  
