# Integrate logstash ruby transform script tests with maven
[_**logstash**_](https://www.elastic.co/products/logstash) allows to transform events before sending to destination using filters. One of the powerful filter is the [_**ruby filter**_](https://www.elastic.co/guide/en/logstash/current/plugins-filters-ruby.html). You can write the transformation using the ruby script into a separate file. On top of that you can write tests which gets executed when _**logstash**_ starts. However, there is no direct way documented to achive the following:
* Use existing logstash filters like mutate, date etc. in the ruby script.
* Write tests for ruby script and execute those as part of maven build.

### Using existing logstash filters in the ruby script
The logstash filters are mostly writen in ruby itself and can be eaily referenced from the ruby script. If the filter does not have any logstash specific dependency then it can be instantiated and used. Refer to [es_transform.rb](src/main/ruby/es_transform.rb) which uses the [_**mutate**_](https://www.elastic.co/guide/en/logstash/current/plugins-filters-mutate.html) and [_**date**_](https://www.elastic.co/guide/en/logstash/current/plugins-filters-date.html) filter plugins. It simple includes the filter files as:
```ruby
require "logstash/filters/mutate"
require "logstash/filters/date"
require "logstash/logging/logger"
```
Then you can create the instance of the filter as:
```ruby
mutate_filter_config = {}

# Add configuration here like
# mutate_filter_config['rename'] = {'old_field' => 'new_field'}

instance = LogStash::Filters::Mutate.new(mutate_filter_config)
instance.register()
```
The configuration required per filter is mentioned in the documentation. Make sure to call _register_ on the filter instance as some plugins may do required initialization in this call. You need to then just call _filter(event)_ method on the filter instance.

### Writing tests for ruby filter script and integrating with the build
_**logstash**_ ruby filter allows writing [inline tests](https://www.elastic.co/guide/en/logstash/current/plugins-filters-ruby.html#_testing_the_ruby_script) to validate the transformation. These tests are run when logstash starts. While this suffices in most of the cases there are few issues:
* The tests are part of the ruby script which may become unmanageable as they grow.
* You need to install or run logstash to validate the tests.
* Becomes difficult to integrate with the build.
