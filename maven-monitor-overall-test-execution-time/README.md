# Monitor Overall Test Execution Time
We are using the [GMavenPlus Plugin](http://groovy.github.io/GMavenPlus/) to capture the start and end time of test execution. The flow  is as follows:
* During the __test-compile__ phase capture the current time in project property.
* During the __test__ phase capture the current time.
* Now, get the time difference and if the difference is more than the expected time then throw an exception to cause a build break.

Refer the __gmavenplus-plugin__ section in [pom.xml](pom.xml).