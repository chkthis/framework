<cfcomponent output="false"><cffunction name="fakePrivateFunction" returntype="any"><cfreturn this.invokeMockFunction( methodName="fakePrivateFunction", args=arguments ) /></cffunction></cfcomponent>
