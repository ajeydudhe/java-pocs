# Integrate logstash ruby transform script tests with maven
[_**logstash**_](https://www.elastic.co/products/logstash) allows to transform events before sending to destination using filters. One of the powerful filter is the [_**ruby filter**_](https://www.elastic.co/guide/en/logstash/current/plugins-filters-ruby.html). You can write the transformation using the ruby script into a separate file. On top of that you can write tests which gets executed when _**logstash**_ starts. However, there is no direct way documented to achive the following:
* Use existing logstash filters like mutate, date etc. in the ruby script.
* Write tests for ruby script and execute those as part of maven build.

## Using existing logstash filters in the ruby script
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

## Writing tests for ruby filter script and integrating with the build
_**logstash**_ ruby filter allows writing [inline tests](https://www.elastic.co/guide/en/logstash/current/plugins-filters-ruby.html#_testing_the_ruby_script) to validate the transformation. These tests are run when logstash starts. While this suffices in most of the cases there are few issues:
* The tests are part of the ruby script which may become unmanageable as they grow.
* You need to install or run logstash to validate the tests.
* Becomes difficult to integrate with the build.

### Approach for running tests outside logstash
The ruby filter script is just like any other ruby script. Only thing required to run it outside _logstash_ is to take care of the dependencies. The dependencies are in terms of other ruby script files (or gems) or even jar files. To see how these dependencies have been handled let's refer to [pom.xml](pom.xml). Here, we are using the [exec-maven-plugin](http://www.mojohaus.org/exec-maven-plugin) to run the ruby script. Look at the plugin with id _**Execute ES Data Transform Tests**_.
#### ruby dependencies
This can be handled by setting the _**GEM_HOME**_ environment variable. To get the same dependencies as logstash we copy the logstash folder to maven project location and refer to the gems path. The gems path will be ***<logstash_folder>/vendor/bundle/jruby/2.3.0***.
The logstash gem file uses local path for *logstash-core* and *logstash-core-plugin-api* which was not getting resolved even after specify the gem file for logstash installation. Hence, as a workaround we download the *logstash-core-plugin-api* gems which also pulls *logstash-core*.
#### jar dependencies
The jar dependencies needs to be taken care because core classes like logstash event etc. are in the *logstash-core* jar file. Also, we will need other dependencies like fasterxml jars, jruby-complete jar etc. all of these jars are available in logstash deployment folder. For executing the java application we can specify the jar file paths but java does not search for the sub-folders in the path. So the option is to specify each jar file path explicitly or have all of them in a single folder. We went ahead with second option. Refer to plugin with ID as ***Copy jars*** in [pom.xml](pom.xml). Here, we are using groovy script to copy the jar from two locations into ***local_jars*** folder.
Once the jars are available in ***local_jars*** folder we use following command to execute the ruby script:
```java
java -cp ${basedir}/local_jars org.jruby.Main ${basedir}/src/test/ruby/core/es_transform_tests.rb
```

 