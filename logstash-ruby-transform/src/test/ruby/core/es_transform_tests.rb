require_relative "../event_type_tests"

module EsTransform
  
  # Enumerate all the class in EsTransform::Tests and execute the methods starting with test_
  $totalTestsPassed = 0
  $totalTestsFailed = 0

  EsTransform::Tests.constants.select do |test_class|
    if EsTransform::Tests.const_get(test_class).is_a? Class
      
      puts ''
      puts 'Executing tests in ' + test_class.to_s
      test_class_instance = EsTransform::Tests.const_get(test_class).new()
      test_class_instance.methods.each do |method_name|
        
        if method_name.to_s.start_with?('test_')
          puts '    ' + method_name.to_s
          begin
            test_class_instance.method(method_name).call()
            $totalTestsPassed += 1
          rescue => e
            $totalTestsFailed += 1
            STDERR.puts()
            STDERR.puts('Test failed: ' + test_class.to_s + '::' + method_name.to_s)
            STDERR.puts("Error: #{$!}")
            STDERR.puts("Stack:\n\t#{e.backtrace.join("\n\t")}")
            STDERR.puts()
          end 
        end
      end
    end
  end    
  
  totalTestsExecuted = $totalTestsPassed + $totalTestsFailed
  puts '-------------------------------------------------------------------------------'
  puts "Tests run: #{totalTestsExecuted}, Passed: #{$totalTestsPassed}, Failed: #{$totalTestsFailed}"    
  puts '-------------------------------------------------------------------------------'
  
  raise Insist::Failure.new("#{$totalTestsFailed} of #{totalTestsExecuted} tests failed.") if $totalTestsFailed > 0      
end
