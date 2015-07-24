<cfcomponent>
	
	<cffunction name="init" returntype="CFEclipseFacade" access="public">
		<cfset variables.cfunit_location = "">
		<cfset variables.br = chr(13) />
		<cfreturn this />
	</cffunction>
	
	<cffunction name="execute" returntype="void" access="remote">
		<cfargument name="test" required="true" type="any" hint="">
		<cfset var testsuite = 0 />
		<cfset var c = 0 />
		<cfsilent>
			<cfsetting showdebugoutput="false" enablecfoutputonly="true" />
			
			<cfset init() />
			
			<cfset testsuite = CreateObject("component", "#variables.cfunit_location#TestSuite").init( arguments.test ) />
			<cfset c = testsuite.testCount() />
		</cfsilent>
	
		<cfcontent type="text/plain" reset="true">
		<cfoutput>{version=1.0:framework=cfunit:count=#trim( c )#}#variables.br#</cfoutput>
		<cfinvoke component="#variables.cfunit_location#TestRunner" method="qrun">
			<cfinvokeargument name="test" value="#testsuite#">
			<cfinvokeargument name="name" value="">	
			<cfinvokeargument name="listener" value="#this#">	
		</cfinvoke>
	</cffunction>
	
	<cffunction name="getTests" returntype="void" access="remote">
		<cfargument name="location" required="true" type="string">
		
		<cfset var directory = "" />
		<cfset var root = listChangeDelims( replaceNoCase(arguments.location, expandPath("/"), ""), ".", "\")  />
		
		<cfsilent>
			<cfsetting showdebugoutput="false" enablecfoutputonly="true" />
			
			<cfset init() />
			
			<!--- CHECK: to see if the 'location' passed in is a file --->
			<cfif fileExists( arguments.location )>
				
				<!--- Remove file extention --->
				<cfset arguments.location = listDeleteAt(arguments.location, listLen(arguments.location, "."), ".") />
				
				<!--- Convert to CFC path --->
				<cfset arguments.location = listChangeDelims( replaceNoCase(arguments.location, expandPath("/"), ""), ".", "\")  />
							
			<!--- CHECK: to see if the 'classes' passed in is a directory --->
			<cfelseif directoryExists( arguments.location )>
				<!--- Get all the CFCs whose name begin with 'Test*' --->
				<cfdirectory action="list" directory="#arguments.location#" name="directory" filter="Test*.cfc" />
			</cfif>
			
		</cfsilent>
		
		<!--- Output list of tests in the requested location --->
		<cfcontent type="text/plain" reset="true">
		<cfif isQuery( directory )>
			<cfoutput query="directory">#root#.#listFirst( directory.name, "." )##variables.br#</cfoutput>
		<cfelse>
			<cfoutput>#arguments.location#</cfoutput>			
		</cfif>
		
	</cffunction>
	
	<cffunction name="startTest" returntype="void" access="public" output="true">
		<cfargument name="test" required="Yes" type="any" hint="">
		<cfset var n = trim( arguments.test.getName() ) />
		
		<cfoutput>[#n#]#variables.br#</cfoutput>
		
		<!--- TODO: Had to remove <cfflush>	to avoid errors when the tested code uses cfcontent, cfcookie, cfform, cfheader, cfhtmlhead, cflocation, or SetLocale --->		
	</cffunction>

	<cffunction name="addMessage" returntype="void" access="public">
		<cfargument name="test" required="Yes" type="any" hint="">
		<cfargument name="thrown" required="Yes" type="any" hint="">
		<cfargument name="type" required="Yes" type="any" hint="">
			
		<cfset outputMessage( arguments.test, arguments.thrown, arguments.type ) />
		<!--- <cfdump var="#arguments#"><cfabort> --->
	</cffunction>

	<cffunction name="endTest" returntype="void" access="public" output="true">
		<cfargument name="test" required="Yes" type="any" hint="">
	</cffunction>
	

	<cffunction name="outputMessage" access="private" returntype="void" output="true">
		<cfargument name="test" required="Yes" type="any" hint="">
		<cfargument name="thrown" required="Yes" type="any" hint="">
		<cfargument name="type" required="Yes" type="any" hint="">

		<cfset var iterator = arguments.thrown.tagContext.iterator() />
		<cfset var context = 0 />
		
		<cfset var message = arguments.thrown.message />
		<cfset var dtype = arguments.type />
		<cfset var details = "" />
		
		<cfif Len(arguments.thrown.detail)>
			<cfset details = details & variables.br & HTMLEditFormat( arguments.thrown.detail ) />
		</cfif>
		
		<cfif structKeyExists(arguments.thrown, "sql")>
			<cfset details = details & variables.br & arguments.thrown.sql />
		</cfif>
		
		<cfif NOT arguments.thrown.type eq "AssertionFailedError">
			<cfset dtype = dtype & ":"& arguments.thrown.type />
			<cfloop condition="#iterator.hasNext()#">
				<cfset context = iterator.next()>
				<cfset details = details & variables.br & context.template&":"&context.line />
			</cfloop>
		</cfif>
			
		<cfoutput>#dtype##variables.br##message##details##variables.br#</cfoutput>
		
	</cffunction>
</cfcomponent>
