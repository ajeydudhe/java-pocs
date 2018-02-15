# Integrate logstash ruby transform script tests with maven
[_**logstash**_](https://www.elastic.co/products/logstash) allows to transform events before sending to destination using filters. One of the powerful filter is the [_**ruby filter**_](https://www.elastic.co/guide/en/logstash/current/plugins-filters-ruby.html). You can write the transformation using the ruby script into a separate file. On top of that you can write tests which gets executed when _**logstash**_ starts. However, there is no direct way documented to achive the following:
* Use existing logstash filters like mutate, date etc. in the ruby script.
* Write tests for ruby script and execute those as part of maven build.

### Using exxisting logstash filters in the ruby script
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

filter = LogStash::Filters::Mutate.new(mutate_filter_config)
filter.register()
```
The configuration required per filter is mentioned in the documentation. Make sure to call _register_ on the filter instance as some plugins may do required initialization in this call.