<cfcomponent extends="Model">
	<cfscript>
	
	function init() {
		belongsTo(name="Schema_Def", foreignKey="schema_def_id");		
	}
	
	</cfscript>
	
	<cffunction name="executeSQL" returnType="struct">
		<cfset var returnVal = {}>
		<cfset var resultInfo = {}>
		<cfset var ret = QueryNew("")>
		<cfset var executionPlan = QueryNew("")>
		<cfset var statement = "">
		<cfset var statementArray = []>
		<cfset var sqlBatchList = "">

		<cfif StructKeyExists(server, "railo")><!--- Annoying incompatiblity found in how ACF and Railo escape backreferences --->
			<cfset var escaped_separator = ReReplace(this.statement_separator, "([^A-Za-z0-9])", "\\1", "ALL")>
		<cfelse>
			<cfset var escaped_separator = ReReplace(this.statement_separator, "([^A-Za-z0-9])", "\\\1", "ALL")>
		</cfif>
		
		<cfif not IsDefined("this.schema_def") OR not IsDefined("this.schema_def.db_type")>
			<cfset this.schema_def = model("Schema_Def").findByKey(key=this.schema_def_id, include="DB_Type")>
		</cfif>
		
		<cfif this.schema_def.db_type.context IS "host">
			
			<cfset local.hasQuerySets = model("Query_Set").count(where="query_id=#this.id# AND schema_def_id = #this.schema_def_id#")>
			
			<cfset returnVal["sets"] = []>
			
			<cftry>
			
			<cftransaction>
		
				<cfif Len(this.schema_def.db_type.batch_separator)>
					<cfset sqlBatchList = REReplaceNoCase(this.sql, "#chr(10)##this.schema_def.db_type.batch_separator#(#chr(13)#?)#chr(10)#", '#chr(7)#', 'all')>
				<cfelse>
					<cfset sqlBatchList = this.sql>
				</cfif>

				<cfset sqlBatchList = REReplaceNoCase(sqlBatchList, "#escaped_separator#\s*(\r?\n|$)", "#chr(7)#", "all")>

					<cfif this.schema_def.db_type.simple_name IS "Oracle">
						<cfset local.defered_table = "DEFERRED_#Left(Hash(createuuid(), "MD5"), 8)#">
						<cfquery datasource="#this.schema_def.db_type_id#_#this.schema_def.short_code#">
						CREATE TABLE #local.defered_table# (val NUMBER(1) CONSTRAINT #local.defered_table#_ck CHECK(val =1) DEFERRABLE INITIALLY DEFERRED)
						</cfquery>
						<cfquery datasource="#this.schema_def.db_type_id#_#this.schema_def.short_code#">
						INSERT INTO #local.defered_table# VALUES (2)
						</cfquery>
					</cfif>

				<cftry>
	
					<cfloop list="#sqlBatchList#" index="statement" delimiters="#chr(7)#">
						<cfset local.ret = QueryNew("")>
						<cfset local.executionPlan = QueryNew("")>
						<cfset local.executionPlanRaw = QueryNew("")>
	
						<cfif Len(trim(statement))><!--- don't run empty queries --->

							<!--- if there is an execution plan mechanism available for this db type --->
							<cfif 		(
										Len(this.schema_def.db_type.execution_plan_prefix) OR
										Len(this.schema_def.db_type.execution_plan_suffix)
									) 
								>					
										
								<cfset local.executionPlanSQL = this.schema_def.db_type.execution_plan_prefix & statement & this.schema_def.db_type.execution_plan_suffix> 
								<cfset local.executionPlanSQL = Replace(local.executionPlanSQL, "##schema_short_code##", this.schema_def.short_code, "ALL")>
								<cfset local.executionPlanSQL = Replace(local.executionPlanSQL, "##query_id##", this.id, "ALL")>
	
								<cfif Len(this.schema_def.db_type.batch_separator)>
									<cfset local.executionPlanBatchList = REReplaceNoCase(local.executionPlanSQL, "#chr(10)##this.schema_def.db_type.batch_separator#(#chr(13)#?)#chr(10)#", '#chr(7)#', 'all')>
								<cfelse>
									<cfset local.executionPlanBatchList = local.executionPlanSQL>
								</cfif>

								<cfloop list="#local.executionPlanBatchList#" index="executionPlanStatement" delimiters="#chr(7)#">
								<cftry>	
									<cfquery datasource="#this.schema_def.db_type_id#_#this.schema_def.short_code#" name="executionPlan">#PreserveSingleQuotes(executionPlanStatement)#</cfquery>								
									<cfcatch>
										
									<!--- execution plan failed! Oh well, carry on.... --->
									<cfset local.executionPlan = QueryNew("")>
									
									</cfcatch>
								</cftry>								
								</cfloop>

								<cfset local.executionPlanRaw = Duplicate(local.executionPlan)>
	
								<!--- Some db types offer XML for the execution plan, which can allow for customized output --->
								<cfif 	
									IsDefined("local.executionPlan") AND 
									IsQuery(local.executionPlan) AND 
									local.executionPlan.recordCount AND
									IsXML(local.executionPlan[ListFirst(local.executionPlan.columnList)][1])>
									
									<!--- This is pretty much only for SQL Server, since only SQL Server reports when explicit commits occur. --->
									<cfif len(this.schema_def.db_type.execution_plan_check)>
										<cfset local.checkResult = XMLSearch(local.executionPlan[ListFirst(local.executionPlan.columnList)][1], this.schema_def.db_type.execution_plan_check)>       
										<cfif ArrayLen(local.checkResult)>
											<cfthrow message="Explicit commits are not allowed.">
										</cfif>
									</cfif>

									<!--- if we have xslt available for this db type, use it to transform the execution plan response --->
									<cfif Len(this.schema_def.db_type.execution_plan_xslt)>
										<cfset local.executionPlan[ListFirst(local.executionPlan.columnList)][1] = 
											XMLTransform(
												local.executionPlan[ListFirst(local.executionPlan.columnList)][1],
												this.schema_def.db_type.execution_plan_xslt
											)>								
									<cfelse>
										<!--- no XSLT, so just format it nicely --->
			
										<cfset local.executionPlan[ListFirst(local.executionPlan.columnList)][1] =
											"<pre>#XMLFormat(local.executionPlan[ListFirst(local.executionPlan.columnList)][1])#</pre>">
																				
									</cfif><!--- end if xslt is/is not available for type --->

								</cfif><!--- end if xml-based execution plan --->

							</cfif> <!--- end if execution plan --->
				

							<cfif this.schema_def.db_type.simple_name IS "SQL Server">
								<cfquery datasource="#this.schema_def.db_type_id#_#this.schema_def.short_code#">
								begin tran;
								</cfquery>
							</cfif>

			
							<!--- run the actual query --->
							<cfquery datasource="#this.schema_def.db_type_id#_#this.schema_def.short_code#" name="ret" result="resultInfo">#PreserveSingleQuotes(statement)#</cfquery>
							<cfset ArrayAppend(statementArray, statement)>

							<cfif this.schema_def.db_type.simple_name IS "Oracle">
								<!--- Just in case some sneaky person finds a way to delete the intentionally-invalid record, we put one back in after each statement that executes. --->
								<cfquery datasource="#this.schema_def.db_type_id#_#this.schema_def.short_code#">
								INSERT INTO #local.defered_table# VALUES (2)
								</cfquery>
							</cfif>
	
							<cfif IsDefined("local.ret")>
								<!--- use getMetaData to get column names instead of local.ret.columnNames csv list, since there can be valid columns in the resultset which contain commas in their names --->
								<cfset local.columnArray = getMetaData(local.ret)>								
								<!--- change null values to the string "(null)" for better display --->
								<cfloop query="local.ret">
									<cfloop array="#local.columnArray#" index="local.colObj">
										<cfset local.NullTest = local.ret.getString(local.colObj.name)>
										
										<cfif not StructKeyExists(local, "NullTest")>
											<cfset local.ret[local.colObj.name][local.ret.currentRow] = "(null)">
										<cfelse>
											<cfset structDelete(local, "NullTest")>
										</cfif>
									</cfloop>
									
								</cfloop>
								
								<cfset ArrayAppend(returnVal["sets"], {
									succeeded = true,
									results = Duplicate(ret),
									statement = statement,
									ExecutionTime = (IsDefined("resultInfo.ExecutionTime") ? resultInfo.ExecutionTime : 0),
									ExecutionPlan = ((IsDefined("local.executionPlan") AND IsQuery(local.executionPlan) AND local.executionPlan.recordCount) ? Duplicate(local.executionPlan) : []),
									ExecutionPlanRaw = ((IsDefined("local.executionPlanRaw") AND IsQuery(local.executionPlanRaw) AND local.executionPlanRaw.recordCount) ? Duplicate(local.executionPlanRaw) : [])
									})>

							<cfelse>
								<cfset ArrayAppend(returnVal["sets"], {
									succeeded = true,
									results = {"DATA" = []},
									statement = statement,
									ExecutionTime = (IsDefined("resultInfo.ExecutionTime") ? resultInfo.ExecutionTime : 0),
									ExecutionPlan = ((IsDefined("local.executionPlan") AND IsQuery(local.executionPlan) AND local.executionPlan.recordCount) ? Duplicate(local.executionPlan) : []),
									ExecutionPlanRaw = ((IsDefined("local.executionPlanRaw") AND IsQuery(local.executionPlanRaw) AND local.executionPlanRaw.recordCount) ? Duplicate(local.executionPlanRaw) : [])
									})>
							</cfif>
	
						</cfif>
						
						<cfset StructDelete(local, "executionPlan")>
						<cfset StructDelete(local, "ret")>
					</cfloop>

					<cfcatch>

						<cfset ArrayAppend(statementArray, statement)>

						<cfif 	this.schema_def.db_type.simple_name IS "Oracle" AND
							FindNoCase("ORA-02290: check constraint (USER_#UCase(this.schema_def.short_code)#.#local.defered_table#_CK) violated", cfcatch.message)>

							<cfset ArrayAppend(returnVal["sets"], {
								succeeded = false,
								errorMessage = "Explicit commits and DDL (ex: CREATE, DROP, RENAME, or ALTER) are not allowed within the query panel for Oracle.  Put DDL in the schema panel instead."
							})>

						<cfelseif this.schema_def.db_type.simple_name IS "PostgreSQL" AND
								REFindNoCase("current transaction is aborted, commands ignored until end of transaction block$", cfcatch.message)>	

							<!--- The last query statement produced an error, but the real error was hidden by PostgreSQL 
									since it was within a transaction.  Boo postgres! So, we have to run the failing query 
									again (outside of a transaction, boo again!) to get back the real message  --->

							<cfthrow type="rerunOutsideTransaction">

						<cfelseif this.schema_def.db_type.simple_name IS "MySQL" AND
								REFindNoCase("^access denied to execute", cfcatch.message)>	

							<cfset ArrayAppend(returnVal["sets"], {
								succeeded = false,
								errorMessage = "DDL and DML statements are not allowed in the query panel for MySQL; only SELECT statements are allowed. Put DDL and DML in the schema panel."
							})>

						<cfelse>

							<cfset ArrayAppend(returnVal["sets"], {
								succeeded = false,
								errorMessage = (IsDefined("cfcatch.queryError") ? (cfcatch.message & ": " & cfcatch.queryError) : cfcatch.message)
							})>

						</cfif>
						
					</cfcatch>
					<cffinally>	
						<cftransaction action="rollback" />

						<cfif this.schema_def.db_type.simple_name IS "Oracle">

							<cfquery datasource="#this.schema_def.db_type_id#_#this.schema_def.short_code#">
							DROP TABLE #local.defered_table#
							</cfquery>

						</cfif>
					</cffinally>
					
				</cftry>
	
	
			</cftransaction>

			<cfcatch type="database"><!--- Something wrong with the transaction? ---></cfcatch>

			<cfcatch type="rerunOutsideTransaction">
				<!--- All of these local variables will be valid and have the same values as the last time we tried to run a query. --->
				<cftry>
					<cfquery datasource="#this.schema_def.db_type_id#_#this.schema_def.short_code#" name="ret" result="resultInfo">#PreserveSingleQuotes(statement)#</cfquery>								
					<cfcatch>
					<cfset ArrayAppend(returnVal["sets"], {
						succeeded = false,
						errorMessage = (IsDefined("cfcatch.queryError") ? (cfcatch.message & ": " & cfcatch.queryError) : cfcatch.message)
					})>
					</cfcatch>
				</cftry>
			
			</cfcatch>
			
			</cftry>

			<cfif not local.hasQuerySets>
				<cfloop from="1" to="#ArrayLen(returnVal['sets'])#" index="i" >
					<cfset tmp= model("Query_Set").create({
						id = i,
						query_id = this.id,
						schema_def_id = this.schema_def_id,
						row_count = (StructKeyExists(returnVal["sets"][i], "results") AND IsQuery(returnVal["sets"][i].results)) ? returnVal["sets"][i].results.recordCount : 0,
						execution_time = StructKeyExists(returnVal["sets"][i], "ExecutionTime") ? returnVal["sets"][i].ExecutionTime : 0,
						execution_plan = StructKeyExists(returnVal["sets"][i], "ExecutionPlanRaw") ? SerializeJSON(returnVal["sets"][i].ExecutionPlanRaw) : "",
						succeeded = returnVal["sets"][i].succeeded ? 1 : 0,
						error_message = StructKeyExists(returnVal["sets"][i], "errorMessage") ? returnVal["sets"][i].errorMessage : "",
						sql = statementArray[i],
						columns_list = (StructKeyExists(returnVal["sets"][i], "results") AND IsQuery(returnVal["sets"][i].results)) ? Left(returnVal["sets"][i].results.columnList, 500) : ""
					})>
				</cfloop>
			</cfif>
			

		</cfif>
		
		<cfreturn returnVal>
	</cffunction>
</cfcomponent>
