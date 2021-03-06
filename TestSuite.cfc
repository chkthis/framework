<!---
*** CFUnit Runner File                                         ***
*** http://cfunit.sourceforge.net                              ***

*** @verion 1.0                                                ***
***          Robert Blackburn (http://www.rbdev.net)           ***
***          Initial Creation                                  ***

A <code>TestSuite</code> is a <code>Composite</code> of Tests.
It runs a collection of test cases. Here is an example using
the dynamic test definition.
	<pre>
		<cfset suite = CreateObject("component", "TestSuite").init()>
		<cfset suite.addTest(  CreateObject("component", "MathTest").init("testAdd") )>
		<cfset suite.addTest(  CreateObject("component", "MathTest").init("testDivideByZero") )>
	</pre>
Alternatively, a TestSuite can extract the tests to be run automatically.
To do so you pass the class of your TestCase class to the
TestSuite constructor.
	<pre>
		<cfset suite = CreateObject("component", "TestSuite").init("MathTest")>
	</pre>
This constructor creates a suite with all the methods
starting with "test" that take no arguments.
<p />
A final option is to do the same for a large array of test classes.
	<pre>
		<cfset testClasses = ArrayNew(1)>
		<cfset ArrayAppend(testClasses, "MathTest")>
		<cfset ArrayAppend(testClasses, "AnotherTest")>
		<cfset suite = CreateObject("component", "net.sourceforge.cfunit.framework.TestSuite").init( testClasses )>
	</pre>
	
Based JUnit code
http://cvs.sourceforge.net/viewcvs.py/junit/junit/junit/framework/TestSuite.java?view=markup

--->

<cfcomponent extends="Assert">
 	<cfproperty name="fName" type="string" hint="The name of the test case">
	<cfproperty name="fTests" type="array" default="ArrayNew(1)">
	<cfset fTests = ArrayNew(1)>
	
	<cffunction name="init" returntype="TestSuite">
		<cfargument name="classes" required="No" type="any" hint="Classes to test. Can be a single Test class, or an array of Test classes for multiple classes.">
		<cfargument name="name" required="No" type="string">
		
		<!--- Initialize local variables --->
		<cfset var i = 0 />
		<cfset var c = 0 />
		<cfset var q = "" />
		
		<!--- CHECK: Were any classes given to initialize with? --->
		<cfif structKeyExists(ARGUMENTS, "classes")>
			<!--- CHECK: Are the classes given in an array --->
			<cfif isArray(ARGUMENTS.classes)>
			
				<!--- Mulitple classes provided, loop through each and add their methods --->
				<cfset c = arrayLen( ARGUMENTS.classes )>
				<cfloop from="1" to="#c#" index="i">
					<cfset addTestSuite( ARGUMENTS.classes[i] )>
				</cfloop>
				
			<cfelseif isSimpleValue(arguments.classes) >

				<!--- CHECK: if the string contains a slash it may be a file or directory name --->
				<cfif arguments.classes CONTAINS "/" OR arguments.classes CONTAINS "\">
					
					<!--- CHECK: to see if the 'classes' passed in is a file --->
					<cfif fileExists(arguments.classes)>
						
						<!--- Remove file extention --->
						<cfset arguments.classes = listDeleteAt(arguments.classes, listLen(arguments.classes, "."), ".") />
						
						<!--- Convert to CFC path --->
						<cfset arguments.classes = listChangeDelims( replaceNoCase(arguments.classes, expandPath("/"), ""), ".", "\")  />
						
						<cfset addTestSuite( arguments.classes )>
					
					<!--- CHECK: to see if the 'classes' passed in is a directory --->
					<cfelseif directoryExists( arguments.classes )>
						
						<!--- Get all the CFCs whose name begin with 'Test*' --->
						<cfdirectory action="list" directory="#arguments.classes#" name="q" filter="Test*.cfc" />
						
						<!--- Get CFC path root --->
						<cfset arguments.classes = listChangeDelims( replaceNoCase(arguments.classes, expandPath("/"), ""), ".", "\")  />
						
						<!--- Add each test in this directory --->
						<cfloop query="q">
							<cfset addTestSuite( arguments.classes&"."&listFirst( q.name, "." ) )>
						</cfloop>
						
					</cfif>
				<cfelse>
				
					<!--- Assume only one class was given (as a string) --->
					<cfset addTestSuite( arguments.classes )>
				</cfif>
			<cfelse>
				<!--- Assume only one class was given --->
				<cfset addTestSuite( arguments.classes )>
			</cfif>
		</cfif>
		
		<!--- CHECK: Was a name given? --->
		<cfif structKeyExists(ARGUMENTS, "name")>
			<!--- CHECK: Is the name not blank --->
			<cfif len( trim( ARGUMENTS.name ))>
				<!--- Sewt the name --->
				<cfset setName(ARGUMENTS.name)>
			</cfif>
		</cfif>
		
		<cfreturn THIS>
	</cffunction>
 
	<cffunction name="setName" access="public" returntype="void" hint="Sets the name of the suite.">
		<cfargument name="name" required="Yes" type="string" hint="The name to set">
		<cfset VARIABLES.fName = ARGUMENTS.name> 
	</cffunction>
	
	<cffunction name="getName" access="public" returntype="string" hint="Returns the name of the suite. Not all  test suites have a name and this method can return blank.">
		<cfif IsDefined("VARIABLES.fName")>
			<cfreturn VARIABLES.fName>
		<cfelse>
			<cfreturn "">
		</cfif> 
	</cffunction>
	 
	<cffunction name="addTest" access="public" returntype="void" hint="Adds a test to the suite">
		<cfargument name="test" required="Yes" type="any">
		<cfset ArrayAppend( getTests(), ARGUMENTS.test )>
	</cffunction>
	
	<cffunction name="addTestSuite" access="public" returntype="void" hint="Adds the tests from the given class to the suite">
		<cfargument name="class" required="yes" type="any">
		
		<!--- Initialize local variables --->
		<cfset var methods = arrayNew(1)>	
		<cfset var object = "">
		<cfset var className = "">
		<cfset var cd = "">
		<cfset var i = 0>
		<cfset var len = 0>
		<cfset var names = "">
		
		<cfif isSimpleValue( arguments.class )>
			<cfset object = createObject("component", arguments.class)>
		<cfelse>
			<cfset object = arguments.class />
		</cfif>
		
		<!--- Get the class's metadata --->
		<cfset cd = getMetadata( object )>
		<cfset className =  cd["NAME"]/>
		 
		<!--- CHECK: Are there any functions in this CFC --->
		<cfif structKeyExists(cd,  "FUNCTIONS")>
			
			<!--- Set the methods array to the root CFC's methods. --->
			<cfset methods = arrayConcat(methods, cd["FUNCTIONS"])>
			
			<!--- Iterate over any extended CFCs to get their methods too --->
			<cfloop condition="#structKeyExists(cd, 'EXTENDS')#">
				<!--- Reset our current metadata to the extended CFC's metadata --->
				<cfset cd = cd["EXTENDS"]>
				
				<!--- CHECK: Are there any functions in this CFC --->
				<cfif structKeyExists(cd, "FUNCTIONS")>
					<!--- Append this CFC's methods to the existing array of methods --->
					<cfset methods = arrayConcat(methods, cd["FUNCTIONS"])>
				</cfif>
			</cfloop>
			
		</cfif>
		
		<!--- Iterate over all methods found, and attempt to add them as a test --->
		<cfset len = arrayLen( methods )>
		<cfloop from="1" to="#len#" index="i">
			<cfset addTestMethod( methods[i], names, className)>
		</cfloop>
		
	</cffunction>
		
	<cffunction name="addTestMethod" access="public" returntype="void" hint="Adds the tests from the given class to the suite">
		<cfargument name="method" required="Yes" type="Any">
		<cfargument name="names" required="Yes" type="string">
		<cfargument name="testClass" required="Yes" type="string">
		
		<cfset var name = ARGUMENTS.method["name"]>
		<cfif ListFindNoCase(ARGUMENTS.names, name)>
			<cfreturn>
		</cfif>
		
		<cfif NOT isPublicTestMethod( ARGUMENTS.method )>
			<cfif NOT isTestMethod( ARGUMENTS.method )>
				<cfreturn>
			</cfif>
		</cfif>
		
		<cfset ARGUMENTS.names = listAppend(ARGUMENTS.names, name)>
		<cfset addTest( createTest( ARGUMENTS.testClass, name ) )> 
	</cffunction>
	 
	<cffunction name="isPublicTestMethod" access="private" returntype="boolean">
		<cfargument name="method" required="Yes" type="Any">
		
		<cfif isTestMethod( ARGUMENTS.method )>
			<cfif structKeyExists(ARGUMENTS.method, "access")>
				<cfif ARGUMENTS.method["access"] IS "public">
					<cfreturn true>
				<cfelse>
					<cfreturn false>
				</cfif>
			<cfelse>
				<cfreturn true>
			</cfif>
		<cfelse>
			<cfreturn false>
		</cfif>
		
	</cffunction>
	
	<cffunction name="isTestMethod" access="private" returntype="boolean">
		<cfargument name="method" required="Yes" type="Any">
		
		<cfif Left(ARGUMENTS.method["name"], 4) IS "test">
			<cfreturn true>
		<cfelse>
			<cfreturn false>
		</cfif>
	</cffunction>

	<cffunction name="createTest" access="public" returntype="any">
		<cfargument name="class" required="Yes" type="string">
		<cfargument name="name" required="Yes" type="string">
		
		<cfset var test = createObject("component", class)>
		<cfset test.setName( name ) />
				
		<cfreturn test>
	</cffunction>

	<cffunction name="run" access="public" returntype="void" hint="Runs the tests and collects their result in a TestResult.">
		<cfargument name="result" required="Yes" type="any" hint="The TestResult object to record the results in">
		
		<cfset var tests = tests() />
		<cfset var i = 0 />
		<cfset var c = arrayLen( tests ) />
		
		<cfloop from="1" to="#c#" index="i">
			<cfset runTest(tests[i], arguments.result)>
		</cfloop>
	</cffunction>
	
	<cffunction name="runTest" returntype="any" access="public">
		<cfargument name="test" required="Yes" type="any" hint="The test to execute">
		<cfargument name="result" required="Yes" type="any" hint="The TestResult object to record the results in">
		
		<cfset arguments.test.run( arguments.result )>
	</cffunction>
	
		
	<cffunction name="getTests" returntype="array" access="public">
		<cfreturn VARIABLES.fTests>	
	</cffunction>
	
	<cffunction name="tests" returntype="array" access="public" hint="Returns the tests as an array">
		<cfreturn getTests() />	
	</cffunction>
		
	<cffunction name="countTestCases" access="public" returntype="numeric" hint="Counts the number of test cases that will be run by this test.">
		<cfset var count = 0 />
		<cfset var tests = tests() />
		<cfset var i = 0 />
		<cfset var c = arrayLen( tests ) />
		
		<cfloop from="1" to="#c#" index="i">
			<cfset count = count + test[i].countTestCases()>
		</cfloop>
		
		<cfreturn count>
	</cffunction>
	
	<cffunction name="testAt" returntype="Test" access="public" hint="Returns the test at the given index">
		<cfargument name="index" required="Yes" type="numeric">
		<cfset var tests = getTests()>
		<cfreturn tests[ARGUMENTS.index]>
	</cffunction>
	
	<cffunction name="testCount" access="public" returntype="numeric" hint="Returns the number of tests in this suite">
		<cfreturn ArrayLen( getTests() )>
	</cffunction>
	
	<cffunction name="getString" access="public" returntype="string">
		<cfif getName() NEQ "">
			<cfreturn getName()>
		</cfif>
		<cfreturn SUPER.getName()>
	</cffunction>
</cfcomponent>