  
/*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
-- Revision 6.50  Last Update: 2009-09-11  Jeff Jaeger  
--  
-- This SP works with the template RptCvtgCL.xlt. The SP provides 5 or 6   
-- different result sets, depending on the value of the @BYSummary parameter.    
-- Configuration report parameters are:  
  
-- @StartTime  DateTime   -- Beginning period for the data.  
-- @ENDTime   DateTime   -- ENDing period for the data.  
-- @Display_id  VARCHAR(8000)  
-- @BYSummary  int    -- adds additional result set if results are not BY summary  
  
2003-01-13 VMK  Modified result sets to be in line with reporting in template.  Removed product  
       Specific result set.  Modified template  
       to report without breaking out data in new sheets BY product.  
  
2003-01-14  VMK  SP is returning variables that are within specs as out.  Modified code WHERE result  
       is being compared to upper AND lower reject values.  The columns are nVARCHAR AND  
       the comparison was not working as expected.  I added code to convert each of this  
       columns to FLOAT for the comparison.  
  
2003-01-17  Jeff Jaeger  
  - Corrected the way that @ENDtime is being calculated.  I also modified the various temp  
    TABLEs to include the most recent instance of all tests in the total completed, regardless   
    of being type Pass/Fail or whether limits are set.  Compliance is still determined based   
    only on tests with numeric results.  
  
2003-02-17 Jeff Jaeger  
  - added use of @BYSummary back into the sp  
  
2003-02-18 Jeff Jaeger  
  - updated names according to stANDards  
  
2003-02-19 Jeff Jaeger  
  - added Raw Data result set  
  
2003-02-19 Jeff Jaeger  
  - updated header block to be similar to spLocal_CvtgDDSStops  
  
2003-02-21 Jeff Jaeger  
  - CREATEd burn copy of sp, per request of Vince King  
  - added prod_id check to update of #test upper reject, lower reject, AND target.  
  
2003-02-25 Jeff Jaeger  
  - added setting of permissions to burn script  
  
2003-02-27 Jeff Jaeger  
  - made corrections to the update of product information in #test  
  
2003-03-03 Jeff Jaeger  
  - converted the syntax of this sp to use joins  
  
2003-03-07 Jeff Jaeger  
  - removed unused parameters @Time_Factor, @Prod_Factor  
  
2003-10-10 Jeff Jaeger  
  - Moved the input validations to before any temp TABLEs are CREATEd.  
    This prevents TABLEs FROM being CREATEd before the parameters are validated.  
    If an error occurs, no TABLEs need to be DROPped.  
  
2003-10-14 Jeff Jaeger  
  - updated the parameter validations to display better error messages.  
  
2003-10-21 Jeff Jaeger  
  - Added a variable to store the local language, AND the query to get that value.  
  - Added addition flow control to the result sets.  If the local language is German,   
    results will have German headers.  ELSE, the results will have English headers.  
    This format can be expANDed for other languages, but the header values will be   
    determined on the fly, once the language translation TABLE is put into place.  
  - Modified the VARCHAR lengths of names for displays, products, variables, AND units to be  
    100 instead of 50, because some of the German names are pretty long, AND END up truncated.  
  
2003-10-23 Jeff Jaeger  
  - Moved all ALTER  TABLE statements to the top of the script.    
  - Placed the parameter validation checks after that.  
  - Made sure all TABLEs are DROPped at the END of the script.  Took the DROP statements out of the IF.  
  - These changes were made to conform to the approach that Matt Wells has discussed using.  
  
2004-MAR-29 Langdon Davis  Rev5.4  
  - Added check for exceeding 65000 records on the raw data results set.  
  
2004-APR-15 Langdon Davis Rev5.6  
     Modified results set SELECTion to use English headers for local language = US English, Spanish,  
    French, or Italian.  Previously, if the local language was other than US English or German,  
    nothing was returned.  
  
2004-APR-29 Jeff Jaeger  Rev 5.7  
  -  Added ScheduleUnit AND CS_association to the #AuditPUID TABLE.  
  -  Added the pu_id column to #Tests.  
  -  Added pu_id to the #Tests INSERT statement.  
  -  Updated INSERT to #AuditPUID to use a call to fnLocal_GlblParseInfo to populate ScheduleUnit  
     AND to assign a default of 0 to CS_association.   
  -  Modified the update to #test team AND shift to get values FROM crew_schedule according to pu_id if   
     all the pu_ids have an association to that TABLE through ScheduleUnit.  Values will be assigned FROM   
     crew_schedule according to time range if there is no association for any of the pu_ids.  If some   
     have associations AND some do not, then an error will be returned.  
  
2004-APR-30  Jeff Jaeger  Rev 5.8  
  -  Added addition check to update of team/shift info in #Test.  This extra check will confirm that   
     only one pu_id is in crew_schedule for the report window before updating #Tests based solely on   
     the time range.  
  
2004-APR-30  Langdon Davis Rev5.81  
  -  Shortened the error message re missing 'ScheduleUnit=' information to fit within Excel's 256   
     character limit.  
  
2004-APR-30  Langdon Davis Rev5.82  
  - Fixed several logic issues with the crew schedule association.  
  
2004-MAY-14  Langdon Davis Rev5.83  
  - Changed Team AND Shift data types to VARCHAR(10) to match the types in the DB for crew_desc  
    AND shift_desc.  
  - Modified logic around INSERTs to #tests_in AND #tests_out to account for instances of all 3   
    of the target,URL, LRL being NULL AND/or target being NULL.  
  
2004-Jun-09  Simon Poon  Rev5.84 (Modification works with Excel Template Rev5.65)  
  a. Bring all limits back in the RawData Resultset - Entry, Reject, Warning, User  
  b. Align all limits references/acronyms in the headers with Proficy Terminology  
  c. Summary WorkSheet   
     Split the Out-Of-Limits to 'Warning Limits' AND 'Reject Limits'  
     Split the Total-Limits-Not-Set to 'Total Warn Limits Not Set' AND 'Total Reject Limits Not Set'  
     Split the Percent Compliant to '% Warning Compliance' AND '% Reject Compliance'  
  d. Add a resultset for 'Variables Outside Warning'  
  e. Change the logic such that the test result can match multiple 'fail descriptions'  
   e.g. @Fail_Val = 'Fail|No|Crap|....'  
    
  A jpg file has been sent to Langdon to describe the Defintion of Limits at different scenarios  
  
2004-Jun-22  Simon Poon  Rev5.85 (Modification works with Excel Template Rev5.65)  
  WHEN the Dynamic Row of the display is 'ON', take out the variables with NoSpecs  
  This logic only affect the NUmbers of the TotalWarningLimitNotSet AND TotalRejectLimitNotSet   
  
2004-Nov-10  Jeff Jaeger  Rev5.90  
  - Brought this sp up to specs with Checklist 110804...  
  - Added the @UserName parameter  
  - Changed the names of some temp TABLEs to simply them while still reflecting the data that they hold.    
  - Added summary temp TABLEs AND related code, to be used in returning result sets.  
  - WHERE appropriate, temp TABLEs have been converted to TABLE variables.  
  - Removed @LocalLanguageDesc AND related code.  
  - Removed hard-coded German translations AND added stANDard language translation code.  
  - Added translation code for the error message generated if Crew_Schedule cannot be associated with   
    #tests.  
  - Removed unused code.  
  - A possible opportunity:  WHEN building the result sets, it may not be necessary to poplate   
  separate temp TABLEs in every CASE.  It may be possible to draw the data directly FROM the underlying   
  temp TABLE.  note this sould require changing some field names, AND allowing all fields in the   
  underlying TABLE to be displayed.  
  
2005-JAN-18  Langdon Davis Rev5.91  
  - First results set had a mixture of English AND German headers.  Cleaned up AND modified the two   
    about 'Total Outside xxx Limits'.  
  
2005-MAR-31  Vince King  Rev5.92  
  - %Compliance for Warning AND Rejects was not being calculated correctly WHEN no warning limits existed.  
    Made modifications to capturing the #InLimits rows FROM the #Tests TABLE to ensure that the correct  
    tests were being captured based on the Report Scope Definition.  
  - Added Comments to Raw Data Result Sheet.  
  - In ORDER to reduce recompiles:   
   - Moved all CREATE TABLE statements for temporary TABLEs to one section.  
   - Added SET @i = (SELECT COUNT(*) FROM #TABLEname) for each temp TABLE.  
   - Added dbo. prefix for all database objects.  
  
2005-APR-04  Vince King  Rev5.93  
  - %Compliance for Warning AND Rejects was still not working for some instances where Limits were missing.  
  - Removed tables #InLimits, #Rejects and #Warnings.  Added tables #OutRejects and #OutWarnings.    
  - Added logic to determine if test is within limits (0), out of limits (1) or no limits assigned (NULL).  
    These values are assigned to the columns OutReject (#OutRejects table) and OutWarning (#OutWarning table).  
  - Modified %Compliance Warning and %Compliance Reject calculations to be based on OutWarning and OutReject,   
    respectively.  
  - Added columns TotalRejects and TotalWarning to various tables for %Compliant calculations.  
  - Added comment to Attibutes Out Result Set and Variables Outside of Reject Limits result set and  
    Variables Outside of Warning Limits result set.  
  
2005-APR-05  Vince King  Rev5.93  
  - Added additional columns to Summary results sets for data used in calculations.  
  
2005-APR-06  Vince King  Rev5.94  
  - Modified #SummaryBySingle and #SummaryByDispProdTmShft tables, [Total With Warn Limits] and [Total With Rej Limits], to   
    return NULL when no tests with limits are found (0).  
  
2005-APR-11  Langdon Davis Rev5.95  
  -  Modified #TeamResultsSummary to split 'TotalRequired' out into 'Total Required' and   
   similary for 'TotCompRegardlessOfLimits'.  
  
2005-04-14 Jeff Jaeger   Rev6.00  
  -  added the object owner to references for objects.  Many of these already had the reference, but many   
   (such as temporary tables) did not.   
  -  reformatted a lot of code that was hard to read because of how it was spread all over the place.  
  -  converted #Results, #ShiftResults, and #TeamResults into table variables.  
  -  appended ORDER BY clauses to @SQL definitions.  
  
2005-04-18 Jeff Jaeger   Rev6.10  
  -  removed #OutRejects and #OutWarnings.  
  -  added the fields OutReject and OutWarnings to #Tests, along with related code updates.  
  
2005-06-01  Vince King   Rev6.11  
  -  Moved code to UPDATE countvar column in @Displays table to be below DELETE where DynamicRows = 1.  
  -  The Total Required field was including variables that should not be included when Dynamic Rows was turned on.   
     The countvar column is used to SUM for Total Required.  
  
2005-06-01  Vince King   Rev6.12   
  -  Modified the code in Rev6.11 to limit variable count based on Audit PUIds.  Did not take this into account  
  -  when I updated countvar.  
  
2005-06-02 Vince King   Rev6.13  
  -  The update for countvar was picking up additional variables which were causing the total required to be  
     incorrect.  Modified the UPDATE so that it gets the count from the #Tests table AFTER it has been modified  
     based on the Dynamic Rows flag.  
  
2006-04-21 Namho Kim   Rev6.14  
  -  Total of Team summary is added.  
  
2006-06-06 Langdon Davis  Rev6.15  
  - To support use of this report on Perfect Parent Roll Displays, added 'AND t.result <> 'Perfect'' to the   
   WHERE clause in the population of AttributesOut.  This is necessitated by the fact that the fail value   
   is 'Not Perfect' and the pass value is 'Perfect'.  
  
2007-MAY-31 Langdon Davis  Rev6.16  
  - Added code to calculate 2 new metrics: % Warning Complete-Compliant and % Reject Complete-Compliant.  These  
   metrics assume that all tests NotDone are outside of the respective limits.  
  
2007-DEC-11 Langdon Davis   Rev6.20   
  -  Modified approach to determine total required.  
  - Added attributes into the Reject Analysis.  
  
2008-MAY-06 Langdon Davis  Rev6.30  
  -  Added AND WHERE Data_Type = 'VARIABLE' to the Variables Out result set selection.  Made necessary not that both   
   variables and attributes have values for OutReject.  
  - Modified the selection for the Attributes Out results set to be exactly the same as for VAriables Out, only   
   with AND WHERE Data_Type = 'ATTRIBUTE'.  This makes this sheet consistent with the OutReject analysis.  
  - Given the above, the @Fail_Val parameter was no longer needed.  Removed it.  
  - Added Data_Type to the Raw Data results set.  
  - Added error handling to catch type conversion errors and still dump the contents of the Tests table in Raw Data.  
    
2008-MAY-07 Langdon Davis  Rev6.31  
  -  Changed to basing tests extraction off of the column result_on's in Sheet_Columns.  
  - Addded determination of tests NotDone with Warning Limits and tests NotDone with Reject Limits and then used  
   these values in the respective calculations of Overall Complete-Compliance.  Before, with just use of the   
   overall NotDone value, it was wrongly assuming that all NotDone tests had limits specified.  
  -  Corrected a bug with respect to determination of number missing warning and/or reject limits [it was counting   
   all tests NotDone as missing limits even if they had limits].   
  
2008-MAY-07 Langdon Davis  Rev6.42  
  - Removed the @AuditPUIdList parameter as it really isn't necessary since the pu_id can be identified by  
   querying the variables table for the variables defined for the display[s].  This removes the possibility for   
   there to be an error in configuring the report type/definitions.   
  - Modified the population of TestsNotDone to eliminate a bug with it creating "not done" records for times   
   where tests WERE done if there was one or more times where the given test was not done.  
  - Removed the set @i statements because testing with other reports had shown them to be inefficient.  
  - In the population of @BaseResults, pulled prod_id out of #Tests versus another query on dbo.Products.  
  - Similarly, prod_id in @ResultsByDispProdTmShft is now coming from @BaseResults.  
  - In the population of @BaseResults and @ResultsByDispProdTmShft, added product restriction to the WHERE clauses of the 'TotReq'  
   calculations, using prod_id.  Replaced the product restrictions that were using prod_name with prod_id  
   on other calculations.   
  -  Added dbo. and WITH(NOLOCK) to all SELECT's and JOIN's.    
  - Renamed tables to make their use more clear and the naming convention more standard.  
  -  Standardized the results set content.  
  - Added code to create results sets for:  
    Results by Display  
    Results by Product  
    Results by Display and Product  
    Results by Display and Team  
    Results by Display, Product and Team  
   Previously, we were only creating results sets for by Team, Overall, and by Display, Product, Team and   
   Shift.  THe code for the bottom 3 in the above list is commented out at this point because I didn't have   
   the time to modify things on the .xlt side to handle them.  
  
2008-MAY-07 Langdon Davis  Rev6.43  
 - Updated the logic around the crew association to not return an error if we have a mixed bag [some pu_id's with  
  associations and some without] AND we only have one crew schedule for the report's time period.  
  
2008-MAY-07 Langdon Davis  Rev6.44  
 -  Modified 'countvar' variable name in @Displays to 'VarConfigCount' to be more descriptive of what it   
  represents--the count of variables configured for the display.  This isn't used in the code anywhere:  It  
  is simply handy information to have when troubleshooting questions re Total Required.  
 - Changed the population of 'VarConfigCount' to be based on the data in Sheet_Variables versus that in the   
  #Tests table.  
 - Added a 'MasterUnit' field to the @AuditPUID table and populated it with the MasterUnit information  
  from the Prod_Units table [applicable only to slave units].  This information is necessary/then used  
  to identify the products being run since slave units don't have production events.  
 - Also utilized the MasterUnit field to populate the ScheduleUnit field in @@AuditPUID in cases where  
  the slave unit has no ScheduleUnit configuration.  
  
2008-MAY-07 Langdon Davis Rev6.45  
 - Added the dynamic row flag back in.  Modified logic as follows:  If the variable has no result value AND   
  no limits AND dynamic rows is turned on, assume that it was not required [since with dynamic rows turned   
  on and no limits, there is no way for someone to have entered a value since it wouldn’ appear in the   
  display].  Otherwise, if dynamic rows is turned off for the display, assume everything on the display was   
  required every time, regardless of whether or not it had any limits or a target.  
 - Added HaveWarning and HaveReject fields to #Tests and modified the OutReject and OutWarning logic to   
  utilize them, as well as TotReqWithWarning, TotReqWithReject, TotCompWithWarning, TotCompWithReject,  
  TotalWarningLimitNotSet and TotalRejectLimitNotSet.  
 - Modified the OutReject logic for attributes to address issues observed in validation.  
 - Added to the OutWarning logic a condition that sets it to 0 if we have a value, warning limits and OutReject = 1  
  
2008-JUN-18 Langdon Davis Rev6.46  
 - The change to using Sheet_Columns for populating @Displays caused use of this report on  
  PPR displays to return no data.  This is because PPR displays are production event  
  based versus time -ased:  Only time-based displays get entries in Sheet_Columns.  Modified  
  the code to pull in Sheet_Type and established two separate inserts into @Displays:  One  
  for time-based using Sheet_Columns and one for production event based that uses the data  
  from Tests similar to before.  
  
  
2009-04-07 Jeff Jaeger Rev6.47  
 - Added DevComment to #Tests, #TestsNotDone and @Display for use in testing.  
 - Added the @DisplayInputs and @ProductionStarts tables along with related code.  @DisplayInputs is   
  used to hold Display ID values parsed from the input parameter.  
 - Modified the insert to @Display and the insert to #Tests.  
 - Changed the assignment of Product and Prod_ID in #Tests and the Limit related updates to #Tests.  
 - Changed the definitions of PercOverallWarningCompliance and PercOverallRejectCompliance.  
  
2009-04-08 Jeff Jaeger Rev6.48  
 - added "with (nolock)" to Product and Prod_ID assignments in #Tests.  
  
2009-04-13 Jeff Jaeger Rev6.49  
 - changed the index on #Tests back to what it was before the rev6.47 changes.    
  
2009-09-11 Jeff Jaeger Rev6.50  
 - removed the "where tst.result is not null" restriction from the initial  
  population of #Tests.  
  
  
-----------------------------------------------------------------------------------------------------------------------  
*/  
  
CREATE        PROCEDURE dbo.spLocal_RptCvtgCL  
--DECLARE  
 @StartTime  DATETIME,  -- Beginning period for the data.  
 @ENDTime   DATETIME,  -- ENDing period for the data.  
 @Display_id  VARCHAR(8000),  
 @BYSummary  INTEGER,   -- adds additional result set if results are not BY summary  
 @UserName  VARCHAR(30)  
  
AS  
  
-------------------------------------------------------------------------------  
-- Assign Report Parameters for SP testing locally.  
-------------------------------------------------------------------------------  
  
--AT13-14  
-- SELECT  @StartTime = '2008-05-08 07:30:00',  
--    @ENDTime = '2008-05-08 19:30:00',  
--    @Display_id = '1787', --'398|399|431|432|402|435|1604|1625|380|1787|1786|1954|1955|1957|1958',      
--    @BYSummary = 1  
  
-- SELECT  @StartTime = '2009-09-02 18:00:00',  
--    @ENDTime = '2009-09-03 06:00:00',  
--    @Display_id = '1230|1228|1229|2967|1295|2965|3116|3340',      
--    @BYSummary = 1  
  
  
SET ANSI_WARNINGS OFF  
SET NOCOUNT ON  
  
--print 'Create tables ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-------------------------------------------------------------------------------  
-- CREATE temporary Error Messages AND ResultSet TABLEs.  
-------------------------------------------------------------------------------  
  
CREATE TABLE dbo.#Tests   
 (  
 test_id   int identity,  
 Var_id   INTEGER,  
 Data_Type  VARCHAR(50),  
 Result_on  DATETIME,  
 Display   INTEGER,  
 Display_Name VARCHAR(100),  
 DynamicRowFlag INTEGER,   
 Team    VARCHAR(10),  
 Shift_id   INTEGER,  
 Shift    VARCHAR(10),  
 pu_id    INTEGER,  
 prod_id   INTEGER,  
 Product   VARCHAR(100),  
 Variable_name VARCHAR(100),  
 Unit    VARCHAR(100),  
 Result   VARCHAR(50),  
 LowerEntry  VARCHAR(50),    
 LowerReject  VARCHAR(50),  
 LowerWarning VARCHAR(50),    
 LowerUser  VARCHAR(50),    
 Target   VARCHAR(50),  
 UpperUser  VARCHAR(50),    
 UpperWarning VARCHAR(50),    
 UpperReject  VARCHAR(50),  
 UpperEntry  VARCHAR(50),  
 HaveReject  INTEGER,  
 HaveWarning  INTEGER,    
 OutReject  INTEGER,  
 OutWarning  INTEGER,  
 Comment   VARCHAR(3000),  
 DevComment  varchar(100)   
-- primary key (var_id, result_on)  
 )   
  
CREATE CLUSTERED INDEX t_var_prod_resulton  
ON dbo.#tests (var_id, result_on)  
  
  
CREATE TABLE dbo.#TestsNotDone   
 (  
 Var_id   INTEGER,  
 Data_Type  VARCHAR(50),  
 Result_on  DATETIME,  
 Display   INTEGER,  
 Display_Name VARCHAR(100),  
 DynamicRowFlag INTEGER,   
 Team    VARCHAR(10),  
 Shift_id   INTEGER,  
 Shift    VARCHAR(10),  
 pu_id    INTEGER,  
 prod_id   INTEGER,  
 Product   VARCHAR(100),  
 Variable_name VARCHAR(100),  
 Unit    VARCHAR(100),  
 Result   VARCHAR(50),  
 LowerEntry  VARCHAR(50),    
 LowerReject  VARCHAR(50),  
 LowerWarning VARCHAR(50),    
 LowerUser  VARCHAR(50),    
 Target   VARCHAR(50),  
 UpperUser  VARCHAR(50),    
 UpperWarning VARCHAR(50),    
 UpperReject  VARCHAR(50),  
 UpperEntry  VARCHAR(50),    
 HaveReject  INTEGER,  
 HaveWarning  INTEGER,    
 OutReject  INTEGER,  
 OutWarning  INTEGER,  
 Comment   VARCHAR(3000),  
 DevComment  varchar(100)   
 )   
  
CREATE TABLE dbo.#AttributesOut (  
 [Time Out]   DATETIME,   
 [Proficy Display] VARCHAR(100),   
 [Team]    VARCHAR(10),   
 [Shift]    VARCHAR(10),   
 [Product]   VARCHAR(100),   
 [Variable]   VARCHAR(100),   
 [Units]    VARCHAR(50),   
 [Result]    VARCHAR(50),   
 [L_Reject]   VARCHAR(50),  
 [Target]    VARCHAR(50),  
 [U_Reject]   VARCHAR(50),  
 [Comment]   VARCHAR(3000) )  
  
CREATE TABLE dbo.#RawData (  
 [Test Timestamp] DATETIME,   
 [Proficy Display] VARCHAR(100),   
 [Team]    VARCHAR(10),   
 [Shift]    VARCHAR(10),  
 [Product]   VARCHAR(100),   
 [Variable]   VARCHAR(100),  
 [Data Type]   VARCHAR (10),  
 [Units]    VARCHAR(100),   
 [Result]    VARCHAR(50),   
 [L_Entry]   VARCHAR(50),   
 [L_Reject]   VARCHAR(50),   
 [L_Warning]   VARCHAR(50),   
 [L_User]    VARCHAR(50),   
 [Target]    VARCHAR(50),   
 [U_User]    VARCHAR(50),   
 [U_Warning]   VARCHAR(50),   
 [U_Reject]   VARCHAR(50),   
 [U_Entry]   VARCHAR(50),  
 [Comment]   VARCHAR(3000) )  
  
CREATE TABLE dbo.#SummaryBySingle (  
 [ ]          VARCHAR(100),  
 [Total Required]      INTEGER,  
 [Total Completed]      INTEGER,  
 [% Complete]       FLOAT,  
 [Total With Warn Limits]   INTEGER,   
 [Total Outside Warning]    INTEGER,  
 [% Warning Compliant]    FLOAT,  
 [% Warning Complete-Compliant] FLOAT,   
 [Total With Rej Limits]    INTEGER,   
 [Total Outside Reject]    INTEGER,  
 [% Reject Compliant]     FLOAT,  
 [% Reject Complete-Compliant]  FLOAT,   
 [Total Not Done]      INTEGER,  
 [Total Warn Limits Not Set]  INTEGER,   
 [Total Rej Limits Not Set]   INTEGER )  
  
CREATE TABLE dbo.#SummaryByDispProdTmShft (  
 [Proficy Display]      VARCHAR(100),   
 [Product]        VARCHAR(100),   
 [Team]         VARCHAR(10),   
 [Shift]         VARCHAR(10),  
 [Total Required]      INTEGER,     
 [Total Completed]      INTEGER,      
 [% Complete]       FLOAT,   
 [Total With Warn Limits]   INTEGER,     
 [Total Outside Warning]    INTEGER,  
 [% Warning Compliant]    FLOAT,  
 [% Warning Complete-Compliant] FLOAT,     
 [Total With Rej Limits]    INTEGER,     
 [Total Outside Reject]    INTEGER,  
 [% Reject Compliant]     FLOAT,  
 [% Reject Complete-Compliant]  FLOAT,     
 [Total Not Done]      INTEGER,  
 [Total Warn Limits Not Set]  INTEGER,   
 [Total Rej Limits Not Set]   INTEGER )  
  
/*  
CREATE TABLE dbo.#SummaryByDispProdTm (  
 [Proficy Display]      VARCHAR(100),   
 [Product]        VARCHAR(100),   
 [Team]         VARCHAR(10),   
 [Total Required]      INTEGER,     
 [Total Completed]      INTEGER,      
 [% Complete]       FLOAT,   
 [Total With Warn Limits]   INTEGER,     
 [Total Outside Warning]    INTEGER,  
 [% Warning Compliant]    FLOAT,  
 [% Warning Complete-Compliant] FLOAT,     
 [Total With Rej Limits]    INTEGER,     
 [Total Outside Reject]    INTEGER,  
 [% Reject Compliant]     FLOAT,  
 [% Reject Complete-Compliant]  FLOAT,     
 [Total Not Done]      INTEGER,  
 [Total Warn Limits Not Set]  INTEGER,   
 [Total Rej Limits Not Set]   INTEGER )  
  
CREATE TABLE dbo.#SummaryByDispProd (  
 [Proficy Display]      VARCHAR(100),   
 [Product]        VARCHAR(100),   
 [Total Required]      INTEGER,     
 [Total Completed]      INTEGER,      
 [% Complete]       FLOAT,   
 [Total With Warn Limits]   INTEGER,     
 [Total Outside Warning]    INTEGER,  
 [% Warning Compliant]    FLOAT,  
 [% Warning Complete-Compliant] FLOAT,     
 [Total With Rej Limits]    INTEGER,     
 [Total Outside Reject]    INTEGER,  
 [% Reject Compliant]     FLOAT,  
 [% Reject Complete-Compliant]  FLOAT,     
 [Total Not Done]      INTEGER,  
 [Total Warn Limits Not Set]  INTEGER,   
 [Total Rej Limits Not Set]   INTEGER )  
  
CREATE TABLE dbo.#SummaryByDispTm (  
 [Proficy Display]      VARCHAR(100),   
 [Team]         VARCHAR(10),   
 [Total Required]      INTEGER,     
 [Total Completed]      INTEGER,      
 [% Complete]       FLOAT,   
 [Total With Warn Limits]   INTEGER,     
 [Total Outside Warning]    INTEGER,  
 [% Warning Compliant]    FLOAT,  
 [% Warning Complete-Compliant] FLOAT,     
 [Total With Rej Limits]    INTEGER,     
 [Total Outside Reject]    INTEGER,  
 [% Reject Compliant]     FLOAT,  
 [% Reject Complete-Compliant]  FLOAT,     
 [Total Not Done]      INTEGER,  
 [Total Warn Limits Not Set]  INTEGER,   
 [Total Rej Limits Not Set]   INTEGER )  
  
CREATE TABLE dbo.#SummaryByDisp (  
 [Proficy Display]      VARCHAR(100),   
 [Total Required]      INTEGER,     
 [Total Completed]      INTEGER,      
 [% Complete]       FLOAT,   
 [Total With Warn Limits]   INTEGER,     
 [Total Outside Warning]    INTEGER,  
 [% Warning Compliant]    FLOAT,  
 [% Warning Complete-Compliant] FLOAT,     
 [Total With Rej Limits]    INTEGER,     
 [Total Outside Reject]    INTEGER,  
 [% Reject Compliant]     FLOAT,  
 [% Reject Complete-Compliant]  FLOAT,     
 [Total Not Done]      INTEGER,  
 [Total Warn Limits Not Set]  INTEGER,   
 [Total Rej Limits Not Set]   INTEGER )  
  
CREATE TABLE dbo.#SummaryByProd (  
 [Product]        VARCHAR(100),   
 [Total Required]      INTEGER,     
 [Total Completed]      INTEGER,      
 [% Complete]       FLOAT,   
 [Total With Warn Limits]   INTEGER,     
 [Total Outside Warning]    INTEGER,  
 [% Warning Compliant]    FLOAT,  
 [% Warning Complete-Compliant] FLOAT,     
 [Total With Rej Limits]    INTEGER,     
 [Total Outside Reject]    INTEGER,  
 [% Reject Compliant]     FLOAT,  
 [% Reject Complete-Compliant]  FLOAT,     
 [Total Not Done]      INTEGER,  
 [Total Warn Limits Not Set]  INTEGER,   
 [Total Rej Limits Not Set]   INTEGER )  
*/  
  
CREATE TABLE dbo.#WarningSummary (  
 [Time Out]   DATETIME,   
 [Proficy Display] VARCHAR(100),   
 [Team]    VARCHAR(10),   
 [Shift]    VARCHAR(10),   
 [Product]   VARCHAR(100),   
 [Variable]   VARCHAR(100),   
 [Units]    VARCHAR(50),   
 [Result]    VARCHAR(50),   
 [L_Warning]   VARCHAR(50),  
 [Target]    VARCHAR(50),  
 [U_Warning]   VARCHAR(50),  
 [Comment]   VARCHAR(3000) )  
  
CREATE TABLE dbo.#RejectSummary (  
 [Time Out]   DATETIME,   
 [Proficy Display] VARCHAR(100),   
 [Team]    VARCHAR(10),   
 [Shift]    VARCHAR(10),   
 [Product]   VARCHAR(100),   
 [Variable]   VARCHAR(100),   
 [Units]    VARCHAR(50),   
 [Result]    VARCHAR(50),   
 [L_Reject]   VARCHAR(50),  
 [Target]    VARCHAR(50),  
 [U_Reject]   VARCHAR(50),  
 [Comment]   VARCHAR(3000) )  
  
  
--print 'declare table vars ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
DECLARE @AuditPUID TABLE (  
 PU_Id    INTEGER,  
 ScheduleUnit INTEGER,  
 MasterUnit  INTEGER,  
 CS_association INTEGER )  
  
DECLARE @Display TABLE   
 (  
 Dis_id   INTEGER,  
 Dis_name   VARCHAR(100),  
 Dis_Type   INTEGER, --NEW with Rev6.46!!!  
 DynamicRowFlag INTEGER,  
 VarConfigCount INTEGER,  
 Column_on  DATETIME,  
 DevComment  varchar(100)   
 )  
  
DECLARE @ErrorMessages TABLE (  
 ErrMsg VARCHAR(300) )  
  
DECLARE @TestsTimes TABLE (  
 Result_on  DATETIME,  
 Display   INTEGER )  
  
declare @BaseResults table (  
 Dis_name       VARCHAR(100),  
 Prod_id       INTEGER,  
 Prod_Name      VARCHAR(100),  
 Team        VARCHAR(10),  
 Shift_id       INTEGER,  
 Shift        VARCHAR(10),  
 TotCompRegardlessOfLimits INTEGER,  
 TotCompWithWarning   INTEGER,  
 TotCompWithReject    INTEGER,  
 TotalWarning     INTEGER,   
 TotalOutWarningLimits  INTEGER,  
 TotalReject      INTEGER,  
 TotalOutRejectLimits   INTEGER,  
 TotalWarningLimitNotSet  INTEGER,  
 TotalRejectLimitNotSet  INTEGER,  
 TotReqRegardlessOfLimits INTEGER,  
 TotReqWithWarning    INTEGER,  
 TotReqWithReject    INTEGER,  
 NotDone       INTEGER,  
 NotDoneWarning     INTEGER,  
 NotDoneReject     INTEGER )  
  
declare @ResultsByDispProdTmShft table (  
 Dis_name        VARCHAR(100),  
 Prod_id        VARCHAR(100),  
 Prod_Name       VARCHAR(100),  
 Team         VARCHAR(10),  
 Shift         VARCHAR(10),  
 TotCompRegardlessOfLimits  INTEGER,  
 TotCompWithWarning    INTEGER,  
 TotCompWithReject     INTEGER,  
 PercComplete      FLOAT,  
 PercInWarningCompliance   FLOAT,  
 PercOverallWarningCompliance FLOAT,    
 PercInRejectCompliance   FLOAT,  
 PercOverallRejectCompliance FLOAT,    
 TotalWarning      INTEGER,  
 TotalOutWarningLimits   INTEGER,  
 TotalReject       INTEGER,   
 TotalOutRejectLimits    INTEGER,  
 TotReqRegardlessOfLimits  INTEGER,  
 TotReqWithWarning     INTEGER,  
 TotReqWithReject     INTEGER,   
 NotDone        INTEGER,  
 NotDoneWarning      INTEGER,  
 NotDoneReject      INTEGER,  
 TotalWarningLimitNotSet   INTEGER,  
 TotalRejectLimitNotSet   INTEGER )  
  
/*  
declare @ResultsByDispProdTm table (  
 Dis_name        VARCHAR(100),  
 Prod_id        VARCHAR(100),  
 Prod_Name       VARCHAR(100),  
 Team         VARCHAR(10),  
 TotCompRegardlessOfLimits  INTEGER,  
 TotCompWithWarning    INTEGER,  
 TotCompWithReject     INTEGER,  
 PercComplete      FLOAT,  
 PercInWarningCompliance   FLOAT,  
 PercOverallWarningCompliance FLOAT,    
 PercInRejectCompliance   FLOAT,  
 PercOverallRejectCompliance FLOAT,    
 TotalWarning      INTEGER,  
 TotalOutWarningLimits   INTEGER,  
 TotalReject       INTEGER,   
 TotalOutRejectLimits    INTEGER,  
 TotReqRegardlessOfLimits  INTEGER,  
 TotReqWithWarning     INTEGER,  
 TotReqWithReject     INTEGER,   
 NotDone        INTEGER,  
 NotDoneWarning      INTEGER,  
 NotDoneReject      INTEGER,  
 TotalWarningLimitNotSet   INTEGER,  
 TotalRejectLimitNotSet   INTEGER )  
  
declare @ResultsByDispTm table (  
 Dis_name        VARCHAR(100),  
 Team         VARCHAR(10),  
 TotCompRegardlessOfLimits  INTEGER,  
 TotCompWithWarning    INTEGER,  
 TotCompWithReject     INTEGER,  
 PercComplete      FLOAT,  
 PercInWarningCompliance   FLOAT,  
 PercOverallWarningCompliance FLOAT,    
 PercInRejectCompliance   FLOAT,  
 PercOverallRejectCompliance FLOAT,    
 TotalWarning      INTEGER,  
 TotalOutWarningLimits   INTEGER,  
 TotalReject       INTEGER,   
 TotalOutRejectLimits    INTEGER,  
 TotReqRegardlessOfLimits  INTEGER,  
 TotReqWithWarning     INTEGER,  
 TotReqWithReject     INTEGER,   
 NotDone        INTEGER,  
 NotDoneWarning      INTEGER,  
 NotDoneReject      INTEGER,  
 TotalWarningLimitNotSet   INTEGER,  
 TotalRejectLimitNotSet   INTEGER )  
  
declare @ResultsByDispProd table (  
 Dis_name        VARCHAR(100),  
 Prod_id        VARCHAR(100),  
 Prod_Name       VARCHAR(100),  
 TotCompRegardlessOfLimits  INTEGER,  
 TotCompWithWarning    INTEGER,  
 TotCompWithReject     INTEGER,  
 PercComplete      FLOAT,  
 PercInWarningCompliance   FLOAT,  
 PercOverallWarningCompliance FLOAT,    
 PercInRejectCompliance   FLOAT,  
 PercOverallRejectCompliance FLOAT,    
 TotalWarning      INTEGER,  
 TotalOutWarningLimits   INTEGER,  
 TotalReject       INTEGER,   
 TotalOutRejectLimits    INTEGER,  
 TotReqRegardlessOfLimits  INTEGER,  
 TotReqWithWarning     INTEGER,  
 TotReqWithReject     INTEGER,   
 NotDone        INTEGER,  
 NotDoneWarning      INTEGER,  
 NotDoneReject      INTEGER,  
 TotalWarningLimitNotSet   INTEGER,  
 TotalRejectLimitNotSet   INTEGER )  
*/  
  
declare @ResultsByDisp table (  
 Dis_name        VARCHAR(100),  
 TotCompRegardlessOfLimits  INTEGER,  
 TotCompWithWarning    INTEGER,  
 TotCompWithReject     INTEGER,  
 PercComplete      FLOAT,  
 PercInWarningCompliance   FLOAT,  
 PercOverallWarningCompliance FLOAT,    
 PercInRejectCompliance   FLOAT,  
 PercOverallRejectCompliance FLOAT,    
 TotalWarning      INTEGER,  
 TotalOutWarningLimits   INTEGER,  
 TotalReject       INTEGER,   
 TotalOutRejectLimits    INTEGER,  
 TotReqRegardlessOfLimits  INTEGER,  
 TotReqWithWarning     INTEGER,  
 TotReqWithReject     INTEGER,   
 NotDone        INTEGER,  
 NotDoneWarning      INTEGER,  
 NotDoneReject      INTEGER,  
 TotalWarningLimitNotSet   INTEGER,  
 TotalRejectLimitNotSet   INTEGER )  
  
declare @ResultsByProd table (  
 Prod_id        VARCHAR(100),  
 Prod_Name       VARCHAR(100),  
 TotCompRegardlessOfLimits  INTEGER,  
 TotCompWithWarning    INTEGER,  
 TotCompWithReject     INTEGER,  
 PercComplete      FLOAT,  
 PercInWarningCompliance   FLOAT,  
 PercOverallWarningCompliance FLOAT,    
 PercInRejectCompliance   FLOAT,  
 PercOverallRejectCompliance FLOAT,    
 TotalWarning      INTEGER,  
 TotalOutWarningLimits   INTEGER,  
 TotalReject       INTEGER,   
 TotalOutRejectLimits    INTEGER,  
 TotReqRegardlessOfLimits  INTEGER,  
 TotReqWithWarning     INTEGER,  
 TotReqWithReject     INTEGER,   
 NotDone        INTEGER,  
 NotDoneWarning      INTEGER,  
 NotDoneReject      INTEGER,  
 TotalWarningLimitNotSet   INTEGER,  
 TotalRejectLimitNotSet   INTEGER )  
  
declare @ResultsByTeam table (  
 Team         VARCHAR(10),  
 TotCompRegardlessOfLimits  INTEGER,  
 TotCompWithWarning    INTEGER,  
 TotCompWithReject     INTEGER,  
 PercComplete      FLOAT,  
 PercInWarningCompliance   FLOAT,  
 PercOverallWarningCompliance FLOAT,    
 PercInRejectCompliance   FLOAT,  
 PercOverallRejectCompliance FLOAT,    
 TotalWarning      INTEGER,  
 TotalOutWarningLimits   INTEGER,  
 TotalReject       INTEGER,   
 TotalOutRejectLimits    INTEGER,  
 TotReqRegardlessOfLimits  INTEGER,  
 TotReqWithWarning     INTEGER,  
 TotReqWithReject     INTEGER,   
 NotDone        INTEGER,  
 NotDoneWarning      INTEGER,  
 NotDoneReject      INTEGER,  
 TotalWarningLimitNotSet   INTEGER,  
 TotalRejectLimitNotSet   INTEGER )  
  
declare @ResultsTotal table (  
 Total         VARCHAR(10),  
 TotReqRegardlessOfLimits  INTEGER,  
 TotReqWithWarning     INTEGER,  
 TotReqWithReject     INTEGER,  
 TotCompRegardlessOfLimits  INTEGER,  
 TotCompWithWarning    INTEGER,  
 TotCompWithReject     INTEGER,  
 TotalWarning      INTEGER,   
 TotalOutWarningLimits   INTEGER,  
 TotalReject       INTEGER,   
 TotalOutRejectLimits    INTEGER,  
 TotalWarningLimitNotSet   INTEGER,  
 TotalRejectLimitNotSet   INTEGER,  
 PercComplete      FLOAT,  
 PercInWarningCompliance   FLOAT,  
 PercOverallWarningCompliance FLOAT,    
 PercInRejectCompliance   FLOAT,  
 PercOverallRejectCompliance FLOAT,    
 NotDone        INTEGER,  
 NotDoneWarning      INTEGER,  
 NotDoneReject      INTEGER )  
  
  
declare @DisplayInputs table  
 (  
 DisplayID  int  
 )  
  
  
declare @ProductionStarts table  
 (  
 Var_ID   int,  
 Prod_Id   int,  
 Prod_Desc  varchar(100),  
 PU_Id    int,  
 Start_Time  datetime,  
 End_Time   datetime   
 primary key (var_id, start_time)  
 )  
  
  
--print 'Get program variables ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-------------------------------------------------------------------------------  
-- Variable Declarations  
-------------------------------------------------------------------------------  
  
DECLARE    
@CS_Association_Error INTEGER,  
@CS_Associations   INTEGER,  
@NumberOfSchedules  INTEGER,  
@AssocErrMsg    VARCHAR(355),  
@LanguageId     INTEGER,  
@UserId      INTEGER,  
@LanguageParmId   INTEGER,  
@NoDataMsg      VARCHAR(50),  
@TooMuchDataMsg    VARCHAR(50),  
@SQL        VARCHAR(8000),  
@ErrorVar     INTEGER,  
  
@DisplayIDList varchar(8000),  
@NewDisplayID varchar(10)   
  
  
SELECT @ErrorVar = 0  
  
--print 'validate input parms ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-------------------------------------------------------------------------------  
-- Check Input Parameters.  
-------------------------------------------------------------------------------  
  
IF IsDate(@StartTime) <> 1  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@StartTime is not a Date.')  
 GOTO ReturnResultSets  
END  
  
IF IsDate(@ENDTime) <> 1  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@ENDTime is not a Date.')  
 GOTO ReturnResultSets  
END  
  
IF @Display_id IS NULL  
BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@Display_id is not valid.')  
 GOTO ReturnResultSets  
END  
  
--print 'Get local language ' + CONVERT(VARCHAR(20), GetDate(), 120)  
------------------------------------------------------------------------------  
-- Get language information  
------------------------------------------------------------------------------  
  
SELECT  @LanguageParmID  = 8,  
   @LanguageId   = NULL  
  
SELECT  @UserId = User_Id  
FROM   dbo.Users WITH(NOLOCK)  
WHERE  UserName = @UserName  
  
SELECT  @LanguageId =   
 CASE   
 WHEN isnumeric(ltrim(rtrim(Value))) = 1   
 THEN convert(FLOAT, ltrim(rtrim(Value)))  
 ELSE NULL  
 END  
FROM   dbo.User_Parameters WITH(NOLOCK)  
WHERE  User_Id = @UserId  
AND   Parm_Id = @LanguageParmId  
  
IF @LanguageId IS NULL  
 SELECT @LanguageId =   
  CASE   
  WHEN isnumeric(ltrim(rtrim(Value))) = 1   
  THEN convert(FLOAT, ltrim(rtrim(Value)))  
  ELSE NULL  
  END  
 FROM dbo.Site_Parameters WITH(NOLOCK)  
 WHERE Parm_Id = @LanguageParmId  
  
IF @LanguageId IS NULL  
 SELECT @LanguageId = 0  
  
SELECT @NoDataMsg   = GBDB.dbo.fnLocal_GlblTranslation('NO DATA meets the given criteria', @LanguageId)  
SELECT @TooMuchDataMsg  = GBDB.dbo.fnLocal_GlblTranslation('There are more results than can be displayed', @LanguageId)  
SELECT @AssocErrMsg   = 'Report could not associate a crew schedule with one or more of the audit production units it is reporting on.  This is due to incomplete configuration of these units.  Contact your SSO.'  
  
--print 'AuditPUID ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-------------------------------------------------------------------------------  
-- Fill the temporary TABLE with the pu_id information.  ScheduleUnit will be   
-- used to get team AND shift info from crew_schedule.  CS_association   
-- determines if the ScheduleUnit exists as a PU_ID in crew_schedule  
-------------------------------------------------------------------------------  
  
INSERT  @AuditPUID (pu_id)  
SELECT  DISTINCT pu_id FROM dbo.variables v WITH(NOLOCK)  
JOIN   dbo.sheet_variables sv WITH(NOLOCK) on sv.var_id = v.var_id  
WHERE  charindex('|' + convert(VARCHAR, sv.sheet_id) + '|', '|' + @Display_id + '|') > 0  
  
UPDATE ap SET  
 scheduleunit = GBDB.dbo.fnLocal_GlblParseInfo(extended_info,'ScheduleUnit='),  
 cs_association = 0,  
 MasterUnit = pu.master_unit  
FROM @AuditPUID ap  
JOIN dbo.prod_units pu WITH(NOLOCK) on pu.pu_id = ap.pu_id  
  
UPDATE ap SET  
 scheduleunit = GBDB.dbo.fnLocal_GlblParseInfo(extended_info,'ScheduleUnit=')  
FROM @AuditPUID ap  
JOIN dbo.prod_units pu WITH(NOLOCK) on pu.pu_id = ap.MasterUnit  
WHERE scheduleunit IS NULL  
  
update  ap set  
   cs_association = 1  
FROM   @AuditPUID ap  
join   dbo.crew_schedule cs WITH(NOLOCK)  
on   cs.pu_id = ap.scheduleunit  
WHERE  (@starttime < END_time or END_time is null)  
AND   (@ENDtime > start_time)   
  
--print 'Display ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-------------------------------------------------------------------------------  
-- Fill the temporary table with the Display information and the timestamps  
-- of the columns/audits done for each display during the report window.  
-------------------------------------------------------------------------------  
  
select @DisplayIDList = '|' + @Display_ID + '|'  
select @DisplayIDList = replace(@DisplayIDList, '||', '|')  
select @DisplayIDList = right(@DisplayIDList, len(@DisplayIDList) - 1)  
  
  
while (len(@DisplayIDList) > 1)  
begin  
  
 select @NewDisplayID = left(@DisplayIDList,charindex('|',@DisplayIDList)-1)  
  
 insert @DisplayInputs select @NewDisplayID  
  
 select @DisplayIDList = right(@DisplayIDList, len(@DisplayIDList) - charindex('|',@DisplayIDList))  
  
 if (len(@DisplayIDList) > 1)  
  continue  
 else  
  break  
  
end  
  
  
--print 'Display 2 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
 INSERT @Display   
    (  
    Dis_Id,   
    Dis_Name,  
    Dis_Type,      --NEW with Rev6.46!!!  
    DynamicRowFlag,   
    VarConfigCount,  
    Column_on,  
    DevComment  
    )   
  
 SELECT SH.Sheet_id,   
    sheet_desc,  
    sheet_type,     --NEW with Rev6.46!!!  
    Dynamic_Rows,   
    0,   
    sc.result_on,  
    'Column Input'  
-- FROM  dbo.Sheets SH WITH(NOLOCK)   
-- join   dbo.Sheet_Variables SV  WITH(NOLOCK)on sh.sheet_id = sv.sheet_id  
-- join  dbo.Variables va  WITH(NOLOCK)on va.var_id = sv.var_id  
-- join   dbo.sheet_columns sc  WITH(NOLOCK)on sc.sheet_id = sh.sheet_id  
-- join  @AuditPUID ap on ap.pu_id = va.pu_id  
-- join  @DisplayInputs di on di.displayid = sh.sheet_id   
  
 from  @DisplayInputs di   
 join  dbo.Sheets SH WITH(NOLOCK) on di.displayid = sh.sheet_id    
 join   dbo.Sheet_Variables SV  WITH(NOLOCK)on sh.sheet_id = sv.sheet_id  
 join  dbo.Variables va  WITH(NOLOCK)on va.var_id = sv.var_id  
 join  @AuditPUID ap on ap.pu_id = va.pu_id  
 join   dbo.sheet_columns sc  WITH(NOLOCK)on sc.sheet_id = sh.sheet_id  
  
 WHERE  Sheet_type IN (1,16)  --NEW with Rev6.46!!!  
-- AND   EXISTS (SELECT PU_Id FROM @AuditPUID WHERE PU_ID = va.pu_id)   
-- AND  charindex('|' + convert(VARCHAR, sh.sheet_id) + '|', '|' + @Display_id + '|') > 0  
 AND   sc.result_on >= @StartTime  
 AND   sc.result_on < @ENDTime  
 GROUP BY SH.Sheet_id, sheet_desc, sheet_type, SH.Dynamic_Rows, sc.result_on --NEW with Rev6.46!!!  
  
  
--print 'Display 3 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
 INSERT @Display   
    (  
    Dis_Id,   --NEW with Rev6.46!!!  
    Dis_Name,     --NEW with Rev6.46!!!  
    Dis_Type,      --NEW with Rev6.46!!!  
    DynamicRowFlag,    --NEW with Rev6.46!!!  
    VarConfigCount,    --NEW with Rev6.46!!!  
    Column_on,  
    DevComment  
    )      --NEW with Rev6.46!!!  
  
 SELECT SH.Sheet_id,     --NEW with Rev6.46!!!  
    sheet_desc,     --NEW with Rev6.46!!!  
    sheet_type,     --NEW with Rev6.46!!!  
    Dynamic_Rows,     --NEW with Rev6.46!!!  
    0,        --NEW with Rev6.46!!!  
    t.result_on,     --NEW with Rev6.46!!!  
    'Test Input'  
-- FROM  dbo.Sheets SH WITH(NOLOCK) --NEW with Rev6.46!!!  
-- join   dbo.Sheet_Variables SV  WITH(NOLOCK)on sh.sheet_id = sv.sheet_id --NEW with Rev6.46!!!  
-- join  dbo.Variables va  WITH(NOLOCK)on va.var_id = sv.var_id --NEW with Rev6.46!!!  
-- join   dbo.tests t WITH(NOLOCK)on t.var_id = va.var_id --NEW with Rev6.46!!!  
  
 from  @DisplayInputs di   
 join  dbo.Sheets SH WITH(NOLOCK) on di.displayid = sh.sheet_id    
 join   dbo.Sheet_Variables SV  WITH(NOLOCK)on sh.sheet_id = sv.sheet_id  
 join  dbo.Variables va  WITH(NOLOCK)on va.var_id = sv.var_id  
 join  @AuditPUID ap on ap.pu_id = va.pu_id  
 join   dbo.tests t WITH(NOLOCK)on t.var_id = va.var_id --NEW with Rev6.46!!!  
-- join   dbo.sheet_columns sc  WITH(NOLOCK)on sc.sheet_id = sh.sheet_id  
  
 WHERE  Sheet_type = 2    --NEW with Rev6.46!!!  
-- AND  EXISTS (SELECT PU_Id FROM @AuditPUID WHERE PU_ID = va.pu_id)  --NEW with Rev6.46!!!  
-- AND  charindex('|' + convert(VARCHAR, sh.sheet_id) + '|', '|' + @Display_id + '|') > 0   --NEW with Rev6.46!!!  
-- AND   t.result_on IN (select distinct(tt.result_on)   --NEW with Rev6.46!!!  
--         from dbo.tests tt WITH(NOLOCK)   --NEW with Rev6.46!!!  
--         where tt.result_on >= @StartTime  --NEW with Rev6.46!!!  
--         AND tt.result_on < @ENDTime group by tt.result_on) --NEW with Rev6.46!!!  
 and t.result_on >= @StartTime  
 AND t.result_on < @ENDTime   
 GROUP BY SH.Sheet_id,sheet_desc, sheet_type, SH.Dynamic_Rows, t.result_on  --NEW with Rev6.46!!!  
  
  
--print 'Update Display ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
UPDATE @Display SET  
 VarConfigCount = (SELECT COUNT(DISTINCT var_id)   
     FROM dbo.Sheet_Variables SV  WITH(NOLOCK)  
     WHERE Dis_Id = sv.sheet_id  
     AND var_id IS NOT NULL)  
  
  
--print 'tests ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
INSERT dbo.#Tests   
    (  
    Var_id,  
    Data_Type,  
    Result_on,  
    Display,  
    Display_name,  
    DynamicRowFlag,  
    Result,   
    variable_name,   
    unit,   
    pu_id,   
    Comment,   
    HaveReject,   
    HaveWarning,  
    OutReject,   
    OutWarning,  
    DevComment  
    )  
SELECT  distinct   
    sv.Var_id,   
    NULL,   
    tst.Result_on,   
    dis.Dis_id,   
    dis.dis_name,  
    dis.DynamicRowFlag,   
    tst.Result,   
    va.Var_desc,   
    va.Eng_units,   
    va.pu_id,   
    CONVERT(VARCHAR(3000), c.Comment_Text),   
    NULL,  
    NULL,  
    NULL,   
    NULL,  
    dis.DevComment   
  FROM  dbo.Variables va WITH(NOLOCK)   
  join dbo.sheet_variables SV WITH(NOLOCK) on va.var_id = sv.var_id  
  join @Display dis on SV.Sheet_id = dis.Dis_id   
  join @AuditPUID ap on ap.pu_id = va.pu_id  
  left join dbo.Tests tst WITH(NOLOCK) on tst.var_id = va.var_id     
      AND  tst.result_on = dis.Column_on  
--      AND  tst.result is not null  ---?????  
  left join dbo.Comments c WITH(NOLOCK) ON tst.Comment_Id = c.Comment_Id        
--  WHERE EXISTS(SELECT PU_Id FROM @AuditPUID WHERE PU_ID = va.pu_id  )   
--  where tst.result is not null  ---?????  
  
  
insert  @TestsTimes   
select  distinct result_on, display  
from   dbo.#Tests WITH(NOLOCK)  
WHERE  result_on is NOT NULL  
Group By result_on, display  
  
  
--print 'TestsNotDone ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
insert #TestsNotDone   
   (  
   Var_id,  
   Data_Type,  
   Result_on,  
   Display,  
   Display_Name,  
   DynamicRowFlag,  
   Team,  
   Shift_id,  
   Shift,  
   pu_id,  
   prod_id,  
   Product,  
   Variable_name,  
   Unit,  
   Result,  
   LowerEntry,  
   LowerReject,  
   LowerWarning,  
   LowerUser,  
   Target,  
   UpperUser,  
   UpperWarning,  
   UpperReject,  
   UpperEntry,   
   HaveReject,   
   HaveWarning,  
   OutReject,  
   OutWarning,  
   Comment,  
   DevComment  
   )  
select   
   tt.Var_id,  
   tt.Data_Type,  
   tt.Result_on,  
   tt.Display,  
   tt.Display_Name,  
   tt.DynamicRowFlag,  
   tt.Team,  
   tt.Shift_id,  
   tt.Shift,  
   tt.pu_id,  
   tt.prod_id,  
   tt.Product,  
   tt.Variable_name,  
   tt.Unit,  
   tt.Result,  
   tt.LowerEntry,  
   tt.LowerReject,  
   tt.LowerWarning,  
   tt.LowerUser,  
   tt.Target,  
   tt.UpperUser,  
   tt.UpperWarning,  
   tt.UpperReject,  
   tt.UpperEntry,   
   tt.HaveReject,  
   tt.HaveWarning,  
   tt.OutReject,  
   tt.OutWarning,  
   tt.Comment,  
   tt.DevComment  
from  
 (  
 select distinct  
   t1.Var_id,  
   t1.Data_Type,  
   tt1.Result_on,  
   t1.Display,  
   t1.Display_Name,  
   t1.DynamicRowFlag,  
   t1.Team,  
   t1.Shift_id,  
   t1.Shift,  
   t1.pu_id,  
   t1.prod_id,  
   t1.Product,  
   t1.Variable_name,  
   t1.Unit,  
   t1.Result,  
   t1.LowerEntry,  
   t1.LowerReject,  
   t1.LowerWarning,  
   t1.LowerUser,  
   t1.Target,  
   t1.UpperUser,  
   t1.UpperWarning,  
   t1.UpperReject,  
   t1.UpperEntry,  
   t1.HaveReject,  
   t1.HaveWarning,   
   t1.OutReject,  
   t1.OutWarning,  
   t1.Comment,  
   t1.DevComment  
 from  dbo.#Tests t1  WITH(NOLOCK)  
 left JOIN @TestsTimes tt1   
 on  tt1.display = t1.display  
 where t1.result_on IS NULL  
 ) tt  
left join dbo.#tests t WITH(NOLOCK)  
on  tt.var_id = t.var_id  
and  tt.result_on = t.result_on  
where t.result_on is null  
  
delete from dbo.#Tests  
where result_on IS NULL  
  
INSERT dbo.#Tests  
SELECT * FROM dbo.#TestsNotDone WITH(NOLOCK)  
  
   
--print 'CS_Association ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-- Use @CS_Association_Error to determine if we need to return an error message.  Start off assuming we don't [=0].  
SELECT @CS_Association_Error = 0  
  
SELECT @CS_Associations = sum(cs_association) FROM @AuditPUID  
  
--print 'CS_Association 2 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
SELECT @NumberOfSchedules =  (SELECT count(distinct pu_id) FROM dbo.crew_schedule WITH(NOLOCK)   
          WHERE (@starttime < END_time or END_time is null)  
          AND (@ENDtime > start_time))  
  
  
--print 'CS_Association 3 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
IF @CS_Associations = (SELECT COUNT(DISTINCT pu_id) FROM @AuditPUID) --All the pu_id's have crew associations...  
 BEGIN  
 UPDATE  dbo.#tests SET    
    Team =  coalesce(crew_desc,''), Shift_id = coalesce(cs_id,''), Shift = coalesce(shift_desc,'')    
 FROM  @AuditPUID ap  
 join   dbo.crew_schedule cs WITH(NOLOCK) on ap.ScheduleUnit = cs.pu_id   
 WHERE  cs.Start_time <= result_on   
 AND    (cs.END_time > result_on or cs.END_time is null)  
 AND   dbo.#tests.pu_id = ap.pu_id  
 END  
ELSE   
 IF @NumberOfSchedules = 1   --None or some of the pu_id's are missing crew associations, but it doesn't   
           --matter because there is only one schedule in effect for the time period.  
 BEGIN  
 UPDATE  dbo.#Tests SET    
    Team =  coalesce(crew_desc,''), Shift_id = coalesce(cs_id,''), Shift = coalesce(shift_desc,'')  
 FROM   dbo.crew_schedule cs WITH(NOLOCK)   
 WHERE  cs.Start_time <= result_on   
 AND    (cs.END_time > result_on or cs.END_time is null)  
 END  
ELSE SELECT @CS_Association_Error = 1 --None or some of the pu_id's are missing crew associations and there  
             --multiple crew schedules so we can't assume anything.  Return an error.  
  
 if  @CS_Association_Error = 1  
  begin  
   INSERT @ErrorMessages (ErrMsg)  
   VALUES   
   (  
   @AssocErrMsg  
   )  
   GOTO ReturnResultSets  
  END  
    
  
--print 'limits ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
/*  
  UPDATE dbo.#Tests SET   
   product =  (  
     SELECT  top 1 prod_desc + ' (' + prod_code + ')'  
     FROM  dbo.Production_starts ps WITH(NOLOCK)  
     join dbo.products p WITH(NOLOCK) on ps.prod_id = p.prod_id  
     JOIN  @AuditPUID ap on COALESCE(ap.masterunit,ap.pu_id) = ps.pu_id   
     join dbo.variables v WITH(NOLOCK) on ap.pu_id = v.pu_id    
     join (  
      SELECT var_id, result_on FROM dbo.#tests WITH(NOLOCK)  
      ) tq  
     on ps.Start_time <= tq.result_on   
     AND  (ps.END_time > tq.result_on OR ps.END_time IS NULL)   
     AND tq.var_id = v.var_id   
     WHERE  dbo.#tests.var_id = tq.var_id  
     AND dbo.#tests.result_on = tq.result_on   
     ORDER BY ps.start_time desc  
     ),  
   prod_id =  (  
     SELECT  top 1 p.prod_id  
     FROM  dbo.Production_starts ps WITH(NOLOCK)  
     join dbo.products p WITH(NOLOCK) on ps.prod_id = p.prod_id  
     JOIN  @AuditPUID ap on COALESCE(ap.masterunit,ap.pu_id) = ps.pu_id    
     join dbo.variables v WITH(NOLOCK) on ap.pu_id = v.pu_id    
     join (  
      SELECT var_id, result_on FROM dbo.#tests WITH(NOLOCK)  
      ) tq   
     on ps.Start_time <= tq.result_on   
     AND   (ps.END_time > tq.result_on OR ps.END_time IS NULL)  
     AND tq.var_id = v.var_id   
     WHERE  dbo.#tests.var_id = tq.var_id  
     AND dbo.#tests.result_on = tq.result_on   
     ORDER BY ps.start_time desc  
     )    
*/  
  
insert @ProductionStarts  
 (  
 Var_ID,  
 Prod_Id,  
 Prod_Desc,  
 PU_Id,  
 Start_Time,  
 End_Time   
 )  
select distinct  
 v.Var_ID,  
 ps.Prod_Id,  
 p.prod_desc + ' (' + p.prod_code + ')',  
 ps.PU_Id,  
 ps.Start_Time,  
 ps.End_Time   
FROM  dbo.Production_starts ps WITH(NOLOCK)  
join dbo.products p WITH(NOLOCK) on ps.prod_id = p.prod_id  
JOIN  @AuditPUID ap on COALESCE(ap.masterunit,ap.pu_id) = ps.pu_id   
join dbo.variables v WITH(NOLOCK) on ap.pu_id = v.pu_id    
join dbo.#tests tq  
on tq.var_id = v.var_id   
where tq.result_on >= ps.Start_Time   
AND  (tq.result_on < ps.END_time OR ps.END_time IS NULL)   
--WHERE  dbo.#tests.var_id = tq.var_id  
--AND dbo.#tests.result_on = tq.result_on   
  
   
  
  UPDATE t SET   
  
   product =  (  
     SELECT  top 1 ps.prod_desc --+ ' (' + prod_code + ')'  
     FROM  @Productionstarts ps --WITH(NOLOCK)  
     join dbo.#tests tq with (nolock)  
     on ps.var_id = tq.var_id   
     --and ps.prod_id = tq.prod_id  
     and ps.Start_time <= tq.result_on   
     AND  (ps.END_time > tq.result_on OR ps.END_time IS NULL)  
     where  tq.test_id = t.test_id  
     ORDER BY ps.var_id desc, ps.start_time desc  
     ),  
   prod_id =  (  
     SELECT  top 1 ps.prod_id  
     FROM  @Productionstarts ps --WITH(NOLOCK)  
     join dbo.#tests tq with (nolock)  
     on ps.var_id = tq.var_id   
     --and ps.prod_id = tq.prod_id  
     and ps.Start_time <= tq.result_on   
     AND  (ps.END_time > tq.result_on OR ps.END_time IS NULL)  
     where  tq.test_id = t.test_id  
     ORDER BY ps.var_id desc, ps.start_time desc  
     )    
  
   from dbo.#Tests t  
  
  
   update  dbo.#tests set  
     lowerentry = vs.l_entry,  
     lowerreject = vs.l_reject,   
     lowerwarning = vs.l_warning,   
     loweruser = vs.l_user,   
     target = vs.target,  
     upperuser = vs.u_user,   
     upperwarning = vs.u_warning,  
     upperreject = vs.u_reject,   
     upperentry = vs.u_entry  
--   FROM  dbo.var_specs vs WITH(NOLOCK)  
--   join dbo.#tests t WITH(NOLOCK) on vs.effective_date <= t.result_on  
--   AND  (vs.expiration_date > t.result_on or vs.expiration_date is NULL )  
--   AND  vs.var_id = t.var_id  
--   AND  vs.prod_id = t.prod_id  
   FROM  dbo.var_specs vs WITH(NOLOCK)  
   join dbo.#tests t WITH(NOLOCK)   
   on  vs.var_id = t.var_id  
   AND  vs.prod_id = t.prod_id  
   and  vs.effective_date <= t.result_on  
   AND  (vs.expiration_date > t.result_on or vs.expiration_date is NULL )  
  
  
--  If there is no result value, limits or target, and the dynamic row flag is on, the test is not required.  Otherwise  
--  assume that it is.  
--/*  
  
DELETE FROM dbo.#Tests   
WHERE (DynamicRowFlag = 1   AND    
  Result    IS NULL  AND  
  lowerentry   IS NULL  AND  
  lowerreject  IS NULL  AND   
  lowerwarning  IS NULL  AND   
  loweruser   IS NULL  AND  
  target    IS NULL  AND  
  upperuser   IS NULL  AND   
  upperwarning  IS NULL  AND  
  upperreject  IS NULL  AND   
  upperentry  IS NULL)  
--*/  
  
  
Update dbo.#Tests  
 SET Data_Type =   
      (  
      CASE  
      WHEN (ISNUMERIC(ltrim(rtrim(Result))) +   
        ISNUMERIC(ltrim(rtrim(lowerentry)))+   
        ISNUMERIC(ltrim(rtrim(lowerreject))) +  
        ISNUMERIC(ltrim(rtrim(lowerwarning))) +  
        ISNUMERIC(ltrim(rtrim(loweruser))) +  
        ISNUMERIC(ltrim(rtrim(target))) +  
        ISNUMERIC(ltrim(rtrim(upperuser))) +  
        ISNUMERIC(ltrim(rtrim(upperwarning))) +  
        ISNUMERIC(ltrim(rtrim(upperreject))) +  
        ISNUMERIC(ltrim(rtrim(upperentry)))) >= 1  
      THEN 'VARIABLE'  
      ELSE 'ATTRIBUTE'  
      END)  
  
 SELECT @ErrorVar =  ( SELECT COUNT (VAR_ID) FROM #Tests  
         WHERE Data_Type = 'VARIABLE'   
         AND (   
           (ISNUMERIC(ltrim(rtrim(Result))) <> 1 AND Result IS NOT NULL)  
         OR  (ISNUMERIC(ltrim(rtrim(lowerreject))) <> 1 AND lowerreject IS NOT NULL)  
         OR  (ISNUMERIC(ltrim(rtrim(lowerwarning))) <> 1 AND lowerwarning IS NOT NULL)  
         OR  (ISNUMERIC(ltrim(rtrim(upperwarning))) <> 1 AND upperwarning IS NOT NULL)  
         OR  (ISNUMERIC(ltrim(rtrim(upperreject))) <> 1 AND upperreject IS NOT NULL)  
           )  
        )  
       
 IF @ErrorVar <> 0  
   BEGIN  
   INSERT @ErrorMessages (ErrMsg)  
   VALUES ('Report failed due to a mixture of numeric and non-numeric values between the result and the Reject and/or Warning Limits on one or more variables.  Go to Raw Data worksheet, filter on Data Type = VARIABLE and look for non-numeric Result, Upper
 or Lower Reject or Warning values to identify offending variables.')  
   --IMPORTANT NOTE: If the above text in the portion of 'Report failed due to a mixture of numeric and   
   --      non-numeric' is changed, you MUST corresponsingly update Case 1 in RptCLCreate of the   
   --      .xlt's VB code.  
   GOTO ReturnResultSets  
   END  
  
--print 'rejects & warnings ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
 update dbo.#tests set  
  HaveReject = 1  
  WHERE (LowerReject IS NOT NULL OR UpperReject IS NOT NULL)  
    
 update dbo.#tests set  
  HaveWarning = 1  
  WHERE (LowerWarning IS NOT NULL OR UpperWarning IS NOT NULL) AND Data_Type = 'VARIABLE'   
  
 update dbo.#tests set  
  OutReject =   
   (  
   CASE  
   WHEN  (lowerreject IS NOT NULL   
      AND  upperreject IS NOT NULL)   
     AND ((CONVERT(FLOAT, result) < CONVERT(FLOAT, lowerreject)   
      OR CONVERT(FLOAT, result) > CONVERT(FLOAT, upperreject)))   
   THEN 1  
   WHEN (CONVERT(FLOAT, lowerreject) IS NOT NULL   
     AND  CONVERT(FLOAT, upperreject) IS NULL   
     AND  CONVERT(FLOAT, result) < CONVERT(FLOAT, lowerreject))  
   THEN 1  
   WHEN (CONVERT(FLOAT, upperreject) IS NOT NULL   
     AND  CONVERT(FLOAT, lowerreject) IS NULL   
     AND CONVERT(FLOAT, result) > CONVERT(FLOAT, upperreject))  
   THEN 1  
   WHEN  (lowerreject IS NOT NULL   
      AND  upperreject IS NOT NULL)   
     AND ((CONVERT(FLOAT, result) > CONVERT(FLOAT, lowerreject)   
       AND  CONVERT(FLOAT, result) < CONVERT(FLOAT, upperreject)))   
   THEN 0  
   WHEN  ((CONVERT(FLOAT, lowerreject) IS NOT NULL   
      AND  CONVERT(FLOAT, upperreject) IS NULL    
      AND CONVERT(FLOAT, result) > CONVERT(FLOAT, lowerreject))              
     OR (CONVERT(FLOAT, upperreject) IS NOT NULL   
      AND  CONVERT(FLOAT, lowerreject) IS NULL       
      AND CONVERT(FLOAT, result) < CONVERT(FLOAT, upperreject))             
     OR (CONVERT(FLOAT, lowerreject) IS NOT NULL   
      AND  CONVERT(FLOAT, result) = CONVERT(FLOAT, lowerreject))   
     OR (CONVERT(FLOAT, upperreject) IS NOT NULL   
      AND  CONVERT(FLOAT, result) = CONVERT(FLOAT, upperreject)))  
   THEN 0  
   ELSE NULL  
   END  
   )  
  WHERE Data_Type = 'VARIABLE' AND  result IS NOT NULL AND HaveReject = 1  
  
update dbo.#tests set  
  OutReject =   
   (  
   CASE  
   WHEN  result = target   
   THEN 0  
   END  
   )  
  WHERE Data_Type = 'ATTRIBUTE' AND  Target IS NOT NULL    
  
update dbo.#tests set  
  OutReject =   
   (  
   CASE  
   WHEN  (result = lowerreject OR  result = upperreject)   
   THEN 1  
   ELSE 0  --Intended to 'pass' entries for initials-type variables.  
   END  
   )  
  WHERE Data_Type = 'ATTRIBUTE' AND result IS NOT NULL AND HaveReject = 1  
  
  
 update dbo.#tests set      
  OutWarning =   
   (  
   CASE  
   WHEN  (OutReject IS NULL OR OutReject = 0)   
     AND (lowerwarning IS NOT NULL AND upperwarning IS NOT NULL)   
     AND ((CONVERT(FLOAT, result) < CONVERT(FLOAT, lowerwarning)   
        OR CONVERT(FLOAT, result) > CONVERT(FLOAT, upperwarning)))   
   THEN 1  
   WHEN ((OutReject IS NULL OR OutReject = 0)   
     AND CONVERT(FLOAT, lowerwarning) IS NOT NULL   
     AND  CONVERT(FLOAT, upperwarning) IS NULL   
     AND CONVERT(FLOAT, result) < CONVERT(FLOAT, lowerwarning))  
   THEN 1  
   WHEN ((OutReject IS NULL OR OutReject = 0)   
     AND CONVERT(FLOAT, upperwarning) IS NOT NULL   
     AND  CONVERT(FLOAT, lowerwarning) IS NULL   
     AND CONVERT(FLOAT, result) > CONVERT(FLOAT, upperwarning))  
   THEN 1  
   WHEN  (lowerwarning IS NOT NULL AND upperwarning IS NOT NULL)   
     AND ((CONVERT(FLOAT, result) > CONVERT(FLOAT, lowerwarning)   
        AND  CONVERT(FLOAT, result) < CONVERT(FLOAT, upperwarning)))   
   THEN 0  
   WHEN  ((CONVERT(FLOAT, lowerwarning) IS NOT NULL   
      AND  CONVERT(FLOAT, upperwarning) IS NULL   
      AND CONVERT(FLOAT, result) > CONVERT(FLOAT, lowerwarning))             
   OR  (CONVERT(FLOAT, upperwarning) IS NOT NULL   
      AND  CONVERT(FLOAT, lowerwarning) IS NULL     
      AND CONVERT(FLOAT, result) < CONVERT(FLOAT, upperwarning))   
   OR  (CONVERT(FLOAT, lowerwarning) IS NOT NULL   
      AND  CONVERT(FLOAT, result) = CONVERT(FLOAT, lowerwarning))   
   OR  (CONVERT(FLOAT, upperwarning) IS NOT NULL   
      AND  CONVERT(FLOAT, result) = CONVERT(FLOAT, upperwarning)))  
   THEN 0  
   WHEN OutReject = 1  
   THEN 0  
   ELSE NULL  
   END  
   )  
  WHERE Data_Type = 'VARIABLE' AND  result IS NOT NULL  AND HaveWarning = 1  
  
  
--print 'BaseResults ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-- Build a table of summary information by display, product, team and shift.  
  
 INSERT @BaseResults (   
  Dis_name,   
  Prod_id,  
  Prod_Name,   
  Team,   
  shift_id,  
  Shift,  
  TotalOutWarningLimits,  
  TotalOutRejectLimits,  
  TotalWarningLimitNotSet,  
  TotalRejectLimitNotSet  
   )  
 SELECT  distinct   
  display_name,  
  prod_id,  
  product,  
  team,  
  shift_id,   
  shift,   
  0,  
  0,  
  0,  
  0  
 FROM  dbo.#tests t WITH(NOLOCK)  
   
 Update sr set  
  TotReqRegardlessOfLimits =  (  
     SELECT count(Var_ID)  
     FROM  dbo.#tests t WITH(NOLOCK)  
     WHERE  t.display_name = sr.dis_name  
     AND  t.prod_id = sr.prod_id  
     AND  t.team = sr.team  
     AND   t.shift_id = sr.shift_id  
     ),  
  TotReqWithWarning =  (  
     SELECT count(Var_ID)  
     FROM  dbo.#tests t WITH(NOLOCK)  
     WHERE  t.display_name = sr.dis_name  
     AND  t.prod_id = sr.prod_id  
     AND  t.team = sr.team  
     AND   t.shift_id = sr.shift_id  
     AND  t.HaveWarning = 1  
     ),  
  TotReqWithReject =  (  
     SELECT count(Var_ID)  
     FROM  dbo.#tests t WITH(NOLOCK)  
     WHERE  t.display_name = sr.dis_name  
     AND  t.prod_id = sr.prod_id  
     AND  t.team = sr.team  
     AND   t.shift_id = sr.shift_id  
     AND  t.HaveReject = 1  
     ),  
  TotalWarning = (  
     SELECT count(OutWarning)  
     FROM  dbo.#tests t WITH(NOLOCK)  
     WHERE  t.display_name = sr.dis_name  
     AND  t.prod_id = sr.prod_id  
     AND  t.team = sr.team  
     AND   t.shift_id = sr.shift_id  
     AND  t.OutWarning IS NOT NULL  
     ),  
  TotalOutWarningLimits =  (       
     SELECT  SUM(OutWarning)  
     FROM   dbo.#Tests t WITH(NOLOCK)  
     WHERE  t.display_name = sr.dis_name  
     AND  t.prod_id = sr.prod_id  
     AND  t.team = sr.team  
     AND   t.shift_id = sr.shift_id  
     ),  
  TotalReject  =  (  
     SELECT  COUNT(OutReject)  
     FROM   dbo.#Tests t WITH(NOLOCK)  
     WHERE  t.display_name = sr.dis_name  
     AND  t.prod_id = sr.prod_id  
     AND  t.team = sr.team  
     AND   t.shift_id = sr.shift_id  
     AND  t.OutReject IS NOT NULL  
     ),  
  TotalOutRejectLimits =  (  
     SELECT  SUM(OutReject)  
     FROM   dbo.#Tests t WITH(NOLOCK)  
     WHERE  t.display_name = sr.dis_name  
     AND  t.prod_id = sr.prod_id  
     AND  t.team = sr.team  
     AND   t.shift_id = sr.shift_id  
     ),  
  TotCompRegardlessOfLimits =  (  
     SELECT count(Result)  
     FROM  dbo.#tests t WITH(NOLOCK)  
     WHERE  t.display_name = sr.dis_name  
     AND  t.prod_id = sr.prod_id  
     AND  t.team = sr.team  
     AND   t.shift_id = sr.shift_id  
     AND   t.Result IS NOT NULL  
     ),  
  TotCompWithWarning =  (  
     SELECT count(Result)  
     FROM  dbo.#tests t WITH(NOLOCK)  
     WHERE  t.display_name = sr.dis_name  
     AND  t.prod_id = sr.prod_id  
     AND  t.team = sr.team  
     AND   t.shift_id = sr.shift_id  
     AND   t.Result IS NOT NULL  
     AND   t.HaveWarning = 1  
     ),  
  TotCompWithReject =  (  
     SELECT count(Result)  
     FROM  dbo.#tests t WITH(NOLOCK)  
     WHERE  t.display_name = sr.dis_name  
     AND  t.prod_id = sr.prod_id  
     AND  t.team = sr.team  
     AND   t.shift_id = sr.shift_id  
     AND   t.Result IS NOT NULL  
     AND   t.HaveReject = 1  
     ),  
  TotalWarningLimitNotSet = (  
     SELECT  COUNT(*)  
     FROM  dbo.#Tests t WITH(NOLOCK)  
     WHERE  t.HaveWarning IS NULL  
     AND   t.display_name = sr.dis_name  
     AND  t.prod_id = sr.prod_id  
     AND  t.team = sr.team  
     AND   t.shift_id = sr.shift_id  
     AND   Data_Type = 'VARIABLE'  
     ),  
  TotalRejectLimitNotSet = (  
     SELECT  COUNT(*)  
     FROM  dbo.#Tests t WITH(NOLOCK)  
     WHERE  t.HaveReject IS NULL  
     AND   t.display_name = sr.dis_name  
     AND  t.prod_id = sr.prod_id  
     AND  t.team = sr.team  
     AND   t.shift_id = sr.shift_id  
     )  
 from @BaseResults sr  
  
 update @BaseResults set   
  NotDone    = TotReqRegardlessOfLimits - TotCompRegardlessOfLimits,  
  NotDoneWarning = TotReqWithWarning - TotCompWithWarning,  
  NotDoneReject = TotReqWithReject - TotCompWithReject   
  
--print 'ResultsByDispProdTmShft ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-- Build a table of result summary information by Display, Product, Team and Shift.  
  
 INSERT  @ResultsByDispProdTmShft (  
    Dis_name,   
    Prod_id,  
    Prod_Name,   
    Team,   
    Shift,  
    TotalOutWarningLimits,  
    TotalOutRejectLimits,  
    TotalWarningLimitNotSet,  
    TotalRejectLimitNotSet,  
    PercComplete,  
    PercInWarningCompliance,  
    PercOverallWarningCompliance,   
    PercInRejectCompliance,  
    PercOverallRejectCompliance   
   )  
 SELECT  distinct   
    dis_name,  
    prod_id,   
    prod_name,  
    team,  
    shift,   
    0,0,0,0,0,0,0,0,0       
 FROM   @BaseResults sr  
  
 Update r set  
  TotReqRegardlessOfLimits =  (  
     SELECT  sum(TotReqRegardlessOfLimits)   
     FROM  @BaseResults sr  
     WHERE  sr.dis_name = r.dis_name  
     AND  sr.prod_id = r.prod_id  
     AND  sr.team = r.team  
     AND  sr.shift = r.shift  
     ),  
  TotReqWithWarning =  (  
     SELECT  sum(TotReqWithWarning)   
     FROM  @BaseResults sr  
     WHERE  sr.dis_name = r.dis_name  
     AND  sr.prod_id = r.prod_id  
     AND  sr.team = r.team  
     AND  sr.shift = r.shift  
     ),  
  TotReqWithReject =  (  
     SELECT  sum(TotReqWithReject)   
     FROM  @BaseResults sr  
     WHERE  sr.dis_name = r.dis_name  
     AND  sr.prod_id = r.prod_id  
     AND  sr.team = r.team  
     AND  sr.shift = r.shift  
     ),  
  TotalWarning = (  
     SELECT  sum(TotalWarning)  
     FROM   @BaseResults sr  
     WHERE  sr.dis_name = r.dis_name  
     AND  sr.prod_id = r.prod_id  
     AND  sr.team = r.team  
     AND  sr.shift = r.shift  
     ),  
  TotalOutWarningLimits =  (  
     SELECT  sum(TotalOutWarningLimits)  
     FROM   @BaseResults sr  
     WHERE  sr.dis_name = r.dis_name  
     AND  sr.prod_id = r.prod_id  
     AND  sr.team = r.team  
     AND  sr.shift = r.shift  
     ),  
  TotalReject =   (  
     SELECT  sum(TotalReject)  
     FROM   @BaseResults sr  
     WHERE  sr.dis_name = r.dis_name  
     AND  sr.prod_id = r.prod_id  
     AND  sr.team = r.team  
     AND  sr.shift = r.shift  
     ),  
  TotalOutRejectLimits =  (  
     SELECT  sum(TotalOutRejectLimits)  
     FROM   @BaseResults sr  
     WHERE  sr.dis_name = r.dis_name  
     AND  sr.prod_id = r.prod_id  
     AND  sr.team = r.team  
     AND  sr.shift = r.shift  
     ),  
  TotCompRegardlessOfLimits =  (  
     SELECT  sum(TotCompRegardlessOfLimits)  
     FROM   @BaseResults sr  
     WHERE  sr.dis_name = r.dis_name  
     AND  sr.prod_id = r.prod_id  
     AND  sr.team = r.team  
     AND  sr.shift = r.shift  
     ),  
  TotCompWithWarning =  (  
     SELECT  sum(TotCompWithWarning)  
     FROM   @BaseResults sr  
     WHERE  sr.dis_name = r.dis_name  
     AND  sr.prod_id = r.prod_id  
     AND  sr.team = r.team  
     AND  sr.shift = r.shift  
     ),  
  TotCompWithReject =  (  
     SELECT  sum(TotCompWithReject)  
     FROM   @BaseResults sr  
     WHERE  sr.dis_name = r.dis_name  
     AND  sr.prod_id = r.prod_id  
     AND  sr.team = r.team  
     AND  sr.shift = r.shift  
     ),  
  TotalWarningLimitNotSet =  (  
     SELECT  sum(TotalWarningLimitNotSet)   
     FROM   @BaseResults sr  
     WHERE  sr.dis_name = r.dis_name  
     AND  sr.prod_id = r.prod_id  
     AND  sr.team = r.team  
     AND  sr.shift = r.shift  
     ),  
  TotalRejectLimitNotSet =  (  
     SELECT  sum(TotalRejectLimitNotSet)   
     FROM   @BaseResults sr  
     WHERE  sr.dis_name = r.dis_name  
     AND  sr.prod_id = r.prod_id  
     AND  sr.team = r.team  
     AND  sr.shift = r.shift  
     ),  
  NotDone =   (  
     SELECT  sum(NotDone)   
     FROM   @BaseResults sr  
     WHERE  sr.dis_name = r.dis_name  
     AND  sr.prod_id = r.prod_id  
     AND  sr.team = r.team  
     AND  sr.shift = r.shift  
     ),  
  NotDoneWarning =   (  
     SELECT  sum(NotDoneWarning)   
     FROM   @BaseResults sr  
     WHERE  sr.dis_name = r.dis_name  
     AND  sr.prod_id = r.prod_id  
     AND  sr.team = r.team  
     AND  sr.shift = r.shift  
     ),  
  NotDoneReject =   (  
     SELECT  sum(NotDoneReject)   
     FROM   @BaseResults sr  
     WHERE  sr.dis_name = r.dis_name  
     AND  sr.prod_id = r.prod_id  
     AND  sr.team = r.team  
     AND  sr.shift = r.shift  
     )  
 from @ResultsByDispProdTmShft r  
    
 Update r set   
  PercInWarningCompliance = (  
   CASE   
   WHEN TotalWarning > 0  
   THEN 1.0 - (TotalOutWarningLimits / CONVERT(FLOAT, TotalWarning))  
   ELSE NULL   
   END  
     ),  
  PercOverallWarningCompliance = (  
   CASE   
   WHEN TotReqWithWarning > 0 --TotalWarning > 0  
   THEN 1.0 - ((TotalOutWarningLimits + NotDoneWarning) / CONVERT(FLOAT, TotReqWithWarning)) --TotalWarning))  
   ELSE NULL   
   END  
     ),  
  PercInRejectCompliance = (  
   CASE   
   WHEN TotalReject > 0  
   THEN 1.0 - (TotalOutRejectLimits / CONVERT(FLOAT, TotalReject))  
   ELSE NULL   
   END  
     ),  
  PercOverallRejectCompliance = (  
   CASE   
   WHEN TotReqWithReject > 0 --TotalReject > 0  
   THEN 1.0 - ((TotalOutRejectLimits + NotDoneReject) / CONVERT(FLOAT, TotReqWithReject)) --TotalReject))  
   ELSE NULL   
   END  
     ),  
  PercComplete = (  
   CASE   
   WHEN TotReqRegardlessOfLimits > 0   
   THEN TotCompRegardlessOfLimits / convert(FLOAT,TotReqRegardlessOfLimits)  
   ELSE NULL   
   END  
    )  
 from @ResultsByDispProdTmShft r  
  
/*  
-- Build a table of result summary information by Display, Product and Team.  
  
 INSERT @ResultsByDispProdTm  
  (  
  Dis_name,   
  Prod_id,  
  Prod_Name,   
  Team,   
  TotReqRegardlessOfLimits,  
  TotReqWithWarning,  
  TotReqWithReject,  
  TotCompRegardlessOfLimits,  
  TotCompWithWarning,  
  TotCompWithReject,   
  TotalWarning,  
  TotalOutWarningLimits,   
  TotalReject,   
  TotalOutRejectLimits,   
  TotalWarningLimitNotSet,   
  TotalRejectLimitNotSet,  
  PercComplete,   
  PercInWarningCompliance,   
  PercOverallWarningCompliance,   
  PercInRejectCompliance,  
  PercOverallRejectCompliance,   
  NotDone,  
  NotDoneWarning,  
  NotDoneReject  
  )  
 SELECT  rs.Dis_name,  
  rs.Prod_id,  
  rs.Prod_name,  
  rs.team,  
  SUM(rs.TotReqRegardlessOfLimits),   
  SUM(rs.TotReqWithWarning),  
  SUM(rs.TotReqWithReject),  
  sum(rs.TotCompRegardlessOfLimits),  
  sum(rs.TotCompWithWarning),   
  sum(rs.TotCompWithReject),  
  SUM(rs.TotalWarning),  
  SUM(rs.TotalOutWarningLimits),  
  SUM(rs.TotalReject),   
  SUM(rs.TotalOutRejectLimits),  
  sum(rs.TotalWarningLimitNotSet),  
  sum(rs.TotalRejectLimitNotSet),   
  0,  
  0,  
  0,  
  0,   
  0,   
  SUM(rs.notdone),  
  SUM(rs.NotDoneWarning),  
  SUM(rs.NotDoneReject)  
 FROM @ResultsByDispProdTmShft rs  
 group BY rs.Dis_name, rs.Prod_id, rs.Prod_name, rs.team  
  
 Update @ResultsByDispProdTm set   
  PercInWarningCompliance = (  
   CASE   
   WHEN TotalWarning > 0  
   THEN 1.0 - (TotalOutWarningLimits / CONVERT(FLOAT, TotalWarning))  
   ELSE NULL   
   END  
     ),  
  PercOverallWarningCompliance = (  
   CASE   
   WHEN TotReqWithWarning > 0 --TotalWarning > 0  
   THEN 1.0 - ((TotalOutWarningLimits + NotDoneWarning) / CONVERT(FLOAT, TotReqWithWarning)) --TotalWarning))  
   ELSE NULL   
   END  
     ),  
  PercInRejectCompliance = (  
   CASE   
   WHEN TotalReject > 0  
   THEN 1.0 - (TotalOutRejectLimits / CONVERT(FLOAT, TotalReject))  
   ELSE NULL   
   END  
     ),  
  PercOverallRejectCompliance = (  
   CASE   
   WHEN TotReqWithReject > 0 --TotalReject > 0  
   THEN 1.0 - ((TotalOutRejectLimits + NotDoneReject) / CONVERT(FLOAT, TotReqWithReject)) --TotalReject))  
   ELSE NULL   
   END  
     ),  
  PercComplete =  (  
   CASE   
   WHEN TotReqRegardlessOfLimits > 0   
   THEN TotCompRegardlessOfLimits / convert(FLOAT,TotReqRegardlessOfLimits)  
   ELSE NULL   
   END  
    )  
  
-- Build a table of result summary information by Display and Product.  
  
 INSERT @ResultsByDispProd  
  (  
  Dis_name,   
  Prod_id,  
  Prod_Name,   
  TotReqRegardlessOfLimits,  
  TotReqWithWarning,  
  TotReqWithReject,  
  TotCompRegardlessOfLimits,  
  TotCompWithWarning,  
  TotCompWithReject,   
  TotalWarning,  
  TotalOutWarningLimits,   
  TotalReject,   
  TotalOutRejectLimits,   
  TotalWarningLimitNotSet,   
  TotalRejectLimitNotSet,  
  PercComplete,   
  PercInWarningCompliance,   
  PercOverallWarningCompliance,   
  PercInRejectCompliance,  
  PercOverallRejectCompliance,   
  NotDone,  
  NotDoneWarning,  
  NotDoneReject  
  )  
 SELECT  rs.Dis_name,  
  rs.Prod_id,  
  rs.Prod_name,  
  SUM(rs.TotReqRegardlessOfLimits),   
  SUM(rs.TotReqWithWarning),  
  SUM(rs.TotReqWithReject),  
  sum(rs.TotCompRegardlessOfLimits),  
  sum(rs.TotCompWithWarning),   
  sum(rs.TotCompWithReject),  
  SUM(rs.TotalWarning),  
  SUM(rs.TotalOutWarningLimits),  
  SUM(rs.TotalReject),   
  SUM(RS.TotalOutRejectLimits),  
  sum(rs.TotalWarningLimitNotSet),  
  sum(rs.TotalRejectLimitNotSet),   
  0,  
  0,  
  0,  
  0,   
  0,   
  SUM(rs.notdone),  
  SUM(rs.NotDoneWarning),  
  SUM(rs.NotDoneReject)  
 FROM @ResultsByDispProdTm rs  
 group BY rs.Dis_name, rs.Prod_id, rs.Prod_name  
   
 Update @ResultsByDispProd set   
  PercInWarningCompliance = (  
   CASE   
   WHEN TotalWarning > 0  
   THEN 1.0 - (TotalOutWarningLimits / CONVERT(FLOAT, TotalWarning))  
   ELSE NULL   
   END  
     ),  
  PercOverallWarningCompliance = (  
   CASE   
   WHEN TotReqWithWarning > 0 --TotalWarning > 0  
   THEN 1.0 - ((TotalOutWarningLimits + NotDoneWarning) / CONVERT(FLOAT, TotReqWithWarning)) --TotalWarning))  
   ELSE NULL   
   END  
     ),  
  PercInRejectCompliance = (  
   CASE   
   WHEN TotalReject > 0  
   THEN 1.0 - (TotalOutRejectLimits / CONVERT(FLOAT, TotalReject))  
   ELSE NULL   
   END  
     ),  
  PercOverallRejectCompliance = (  
   CASE   
   WHEN TotReqWithReject > 0 --TotalReject > 0  
   THEN 1.0 - ((TotalOutRejectLimits + NotDoneReject) / CONVERT(FLOAT, TotReqWithReject)) --TotalReject))  
   ELSE NULL   
   END  
     ),  
  PercComplete =  (  
   CASE   
   WHEN TotReqRegardlessOfLimits > 0   
   THEN TotCompRegardlessOfLimits / convert(FLOAT,TotReqRegardlessOfLimits)  
   ELSE NULL   
   END  
    )  
  
-- Build a table of result summary information by Display and Team.  
  
 INSERT @ResultsByDispTm  
  (  
  Dis_name,   
  Team,  
  TotReqRegardlessOfLimits,  
  TotReqWithWarning,  
  TotReqWithReject,  
  TotCompRegardlessOfLimits,  
  TotCompWithWarning,  
  TotCompWithReject,   
  TotalWarning,  
  TotalOutWarningLimits,   
  TotalReject,   
  TotalOutRejectLimits,   
  TotalWarningLimitNotSet,   
  TotalRejectLimitNotSet,  
  PercComplete,   
  PercInWarningCompliance,   
  PercOverallWarningCompliance,   
  PercInRejectCompliance,  
  PercOverallRejectCompliance,   
  NotDone,  
  NotDoneWarning,  
  NotDoneReject  
  )  
 SELECT  rs.Dis_name,  
  rs.Team,  
  SUM(rs.TotReqRegardlessOfLimits),   
  SUM(rs.TotReqWithWarning),  
  SUM(rs.TotReqWithReject),  
  sum(rs.TotCompRegardlessOfLimits),  
  sum(rs.TotCompWithWarning),   
  sum(rs.TotCompWithReject),  
  SUM(rs.TotalWarning),  
  SUM(rs.TotalOutWarningLimits),  
  SUM(rs.TotalReject),   
  SUM(RS.TotalOutRejectLimits),  
  sum(rs.TotalWarningLimitNotSet),  
  sum(rs.TotalRejectLimitNotSet),   
  0,  
  0,  
  0,  
  0,   
  0,   
  SUM(rs.notdone),  
  SUM(rs.NotDoneWarning),  
  SUM(rs.NotDoneReject)  
 FROM @ResultsByDispProdTm rs  
 group BY rs.Dis_name, rs.Team  
  
 Update @ResultsByDispTm set   
  PercInWarningCompliance = (  
   CASE   
   WHEN TotalWarning > 0  
   THEN 1.0 - (TotalOutWarningLimits / CONVERT(FLOAT, TotalWarning))  
   ELSE NULL   
   END  
     ),  
  PercOverallWarningCompliance = (  
   CASE   
   WHEN TotReqWithWarning > 0 --TotalWarning > 0  
   THEN 1.0 - ((TotalOutWarningLimits + NotDoneWarning) / CONVERT(FLOAT, TotReqWithWarning)) --TotalWarning))  
   ELSE NULL   
   END  
     ),  
  PercInRejectCompliance = (  
   CASE   
   WHEN TotalReject > 0  
   THEN 1.0 - (TotalOutRejectLimits / CONVERT(FLOAT, TotalReject))  
   ELSE NULL   
   END  
     ),  
  PercOverallRejectCompliance = (  
   CASE   
   WHEN TotReqWithReject > 0 --TotalReject > 0  
   THEN 1.0 - ((TotalOutRejectLimits + NotDoneReject) / CONVERT(FLOAT, TotReqWithReject)) --TotalReject))  
   ELSE NULL   
   END  
     ),  
  PercComplete =  (  
   CASE   
   WHEN TotReqRegardlessOfLimits > 0   
   THEN TotCompRegardlessOfLimits / convert(FLOAT,TotReqRegardlessOfLimits)  
   ELSE NULL   
   END  
    )  
*/  
  
--print 'ResultByDisp ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-- Build a table of result summary information by Display.  
  
 INSERT @ResultsByDisp  
  (  
  Dis_name,   
  TotReqRegardlessOfLimits,  
  TotReqWithWarning,  
  TotReqWithReject,  
  TotCompRegardlessOfLimits,  
  TotCompWithWarning,  
  TotCompWithReject,   
  TotalWarning,  
  TotalOutWarningLimits,   
  TotalReject,   
  TotalOutRejectLimits,   
  TotalWarningLimitNotSet,   
  TotalRejectLimitNotSet,  
  PercComplete,   
  PercInWarningCompliance,   
  PercOverallWarningCompliance,   
  PercInRejectCompliance,  
  PercOverallRejectCompliance,   
  NotDone,  
  NotDoneWarning,  
  NotDoneReject  
  )  
 SELECT  rs.Dis_name,  
  SUM(rs.TotReqRegardlessOfLimits),   
  SUM(rs.TotReqWithWarning),  
  SUM(rs.TotReqWithReject),  
  sum(rs.TotCompRegardlessOfLimits),  
  sum(rs.TotCompWithWarning),   
  sum(rs.TotCompWithReject),  
  SUM(rs.TotalWarning),  
  SUM(rs.TotalOutWarningLimits),  
  SUM(rs.TotalReject),   
  SUM(RS.TotalOutRejectLimits),  
  sum(rs.TotalWarningLimitNotSet),  
  sum(rs.TotalRejectLimitNotSet),   
  0,  
  0,  
  0,  
  0,   
  0,   
  SUM(rs.notdone),  
  SUM(rs.NotDoneWarning),  
  SUM(rs.NotDoneReject)  
 FROM @ResultsByDispProdTmShft rs  
 group BY rs.Dis_name  
  
 Update @ResultsByDisp set   
  PercInWarningCompliance = (  
   CASE   
   WHEN TotalWarning > 0  
   THEN 1.0 - (TotalOutWarningLimits / CONVERT(FLOAT, TotalWarning))  
   ELSE NULL   
   END  
     ),  
  PercOverallWarningCompliance = (  
   CASE   
   WHEN TotReqWithWarning > 0 --TotalWarning > 0  
   THEN 1.0 - ((TotalOutWarningLimits + NotDoneWarning) / CONVERT(FLOAT, TotReqWithWarning)) --TotalWarning))  
   ELSE NULL   
   END  
     ),  
  PercInRejectCompliance = (  
   CASE   
   WHEN TotalReject > 0  
   THEN 1.0 - (TotalOutRejectLimits / CONVERT(FLOAT, TotalReject))  
   ELSE NULL   
   END  
     ),  
  PercOverallRejectCompliance = (  
   CASE   
   WHEN TotReqWithReject > 0 --TotalReject > 0  
   THEN 1.0 - ((TotalOutRejectLimits + NotDoneReject) / CONVERT(FLOAT, TotReqWithReject)) --TotalReject))  
   ELSE NULL   
   END  
     ),  
  PercComplete =  (  
   CASE   
   WHEN TotReqRegardlessOfLimits > 0   
   THEN TotCompRegardlessOfLimits / convert(FLOAT,TotReqRegardlessOfLimits)  
   ELSE NULL   
   END  
    )  
  
--print 'ResultsByProd ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-- Build a table of result summary information by Product.  
  
 INSERT @ResultsByProd  
  (  
  Prod_id,  
  Prod_name,   
  TotReqRegardlessOfLimits,  
  TotReqWithWarning,  
  TotReqWithReject,  
  TotCompRegardlessOfLimits,  
  TotCompWithWarning,  
  TotCompWithReject,   
  TotalWarning,  
  TotalOutWarningLimits,   
  TotalReject,   
  TotalOutRejectLimits,   
  TotalWarningLimitNotSet,   
  TotalRejectLimitNotSet,  
  PercComplete,   
  PercInWarningCompliance,   
  PercOverallWarningCompliance,   
  PercInRejectCompliance,  
  PercOverallRejectCompliance,   
  NotDone,  
  NotDoneWarning,  
  NotDoneReject  
  )  
 SELECT  rs.Prod_id,  
  rs.Prod_name,  
  SUM(rs.TotReqRegardlessOfLimits),   
  SUM(rs.TotReqWithWarning),  
  SUM(rs.TotReqWithReject),  
  sum(rs.TotCompRegardlessOfLimits),  
  sum(rs.TotCompWithWarning),   
  sum(rs.TotCompWithReject),  
  SUM(rs.TotalWarning),  
  SUM(rs.TotalOutWarningLimits),  
  SUM(rs.TotalReject),   
  SUM(RS.TotalOutRejectLimits),  
  sum(rs.TotalWarningLimitNotSet),  
  sum(rs.TotalRejectLimitNotSet),   
  0,  
  0,  
  0,  
  0,   
  0,   
  SUM(rs.notdone),  
  SUM(rs.NotDoneWarning),  
  SUM(rs.NotDoneReject)  
 FROM @ResultsByDispProdTmShft rs  
 group BY rs.Prod_id, rs.Prod_name  
  
 Update @ResultsByProd set   
  PercInWarningCompliance = (  
   CASE   
   WHEN TotalWarning > 0  
   THEN 1.0 - (TotalOutWarningLimits / CONVERT(FLOAT, TotalWarning))  
   ELSE NULL   
   END  
     ),  
  PercOverallWarningCompliance = (  
   CASE   
   WHEN TotReqWithWarning > 0 --TotalWarning > 0  
   THEN 1.0 - ((TotalOutWarningLimits + NotDoneWarning) / CONVERT(FLOAT, TotReqWithWarning)) --TotalWarning))  
   ELSE NULL   
   END  
     ),  
  PercInRejectCompliance = (  
   CASE   
   WHEN TotalReject > 0  
   THEN 1.0 - (TotalOutRejectLimits / CONVERT(FLOAT, TotalReject))  
   ELSE NULL   
   END  
     ),  
  PercOverallRejectCompliance = (  
   CASE   
   WHEN TotReqWithReject > 0 --TotalReject > 0  
   THEN 1.0 - ((TotalOutRejectLimits + NotDoneReject) / CONVERT(FLOAT, TotReqWithReject)) --TotalReject))  
   ELSE NULL   
   END  
     ),  
  PercComplete =  (  
   CASE   
   WHEN TotReqRegardlessOfLimits > 0   
   THEN TotCompRegardlessOfLimits / convert(FLOAT,TotReqRegardlessOfLimits)  
   ELSE NULL   
   END  
    )  
  
--print 'ResultsByTeam ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-- Build a table of result summary information by Team.  
  
 INSERT @ResultsByTeam  
  (  
  Team,   
  TotReqRegardlessOfLimits,  
  TotReqWithWarning,  
  TotReqWithReject,  
  TotCompRegardlessOfLimits,  
  TotCompWithWarning,  
  TotCompWithReject,   
  TotalWarning,  
  TotalOutWarningLimits,   
  TotalReject,   
  TotalOutRejectLimits,   
  TotalWarningLimitNotSet,   
  TotalRejectLimitNotSet,  
  PercComplete,   
  PercInWarningCompliance,   
  PercOverallWarningCompliance,   
  PercInRejectCompliance,  
  PercOverallRejectCompliance,   
  NotDone,  
  NotDoneWarning,  
  NotDoneReject  
  )  
 SELECT  rs.team,  
  SUM(rs.TotReqRegardlessOfLimits),   
  SUM(rs.TotReqWithWarning),  
  SUM(rs.TotReqWithReject),  
  sum(rs.TotCompRegardlessOfLimits),  
  sum(rs.TotCompWithWarning),   
  sum(rs.TotCompWithReject),  
  SUM(rs.TotalWarning),  
  SUM(rs.TotalOutWarningLimits),  
  SUM(rs.TotalReject),   
  SUM(RS.TotalOutRejectLimits),  
  sum(rs.TotalWarningLimitNotSet),  
  sum(rs.TotalRejectLimitNotSet),   
  0,  
  0,  
  0,  
  0,   
  0,   
  SUM(rs.notdone),  
  SUM(rs.NotDoneWarning),  
  SUM(rs.NotDoneReject)  
 FROM @ResultsByDispProdTmShft rs  
 group BY rs.team  
   
 Update @ResultsByTeam set   
  PercInWarningCompliance = (  
   CASE   
   WHEN TotalWarning > 0  
   THEN 1.0 - (TotalOutWarningLimits / CONVERT(FLOAT, TotalWarning))  
   ELSE NULL   
   END  
     ),  
  PercOverallWarningCompliance = (  
   CASE   
   WHEN TotReqWithWarning > 0 --TotalWarning > 0  
   THEN 1.0 - ((TotalOutWarningLimits + NotDoneWarning) / CONVERT(FLOAT, TotReqWithWarning)) --TotalWarning))  
   ELSE NULL   
   END  
     ),  
  PercInRejectCompliance = (  
   CASE   
   WHEN TotalReject > 0  
   THEN 1.0 - (TotalOutRejectLimits / CONVERT(FLOAT, TotalReject))  
   ELSE NULL   
   END  
     ),  
  PercOverallRejectCompliance = (  
   CASE   
   WHEN TotReqWithReject > 0 --TotalReject > 0  
   THEN 1.0 - ((TotalOutRejectLimits + NotDoneReject) / CONVERT(FLOAT, TotReqWithReject)) --TotalReject))  
   ELSE NULL   
   END  
     ),  
  PercComplete =  (  
   CASE   
   WHEN TotReqRegardlessOfLimits > 0   
   THEN TotCompRegardlessOfLimits / convert(FLOAT,TotReqRegardlessOfLimits)  
   ELSE NULL   
   END  
    )  
  
 INSERT @ResultsTotal  
  (  
  Total,   
  TotReqRegardlessOfLimits,   
  TotReqWithWarning,  
  TotReqWithReject,  
  TotCompRegardlessOfLimits,  
  TotCompWithWarning,  
  TotCompWithReject,   
  TotalWarning,  
  TotalOutWarningLimits,   
  TotalReject,   
  TotalOutRejectLimits,   
  TotalWarningLimitNotSet,   
  TotalRejectLimitNotSet,  
  PercComplete,   
  PercInWarningCompliance,  
  PercOverallWarningCompliance,   
  PercInRejectCompliance,  
  PercOverallRejectCompliance,   
  NotDone,  
  NotDoneWarning,  
  NotDoneReject  
  )  
 SELECT 'Total',  
  SUM(rs.TotReqRegardlessOfLimits),   
  SUM(rs.TotReqWithWarning),  
  SUM(rs.TotReqWithReject),  
  sum(rs.TotCompRegardlessOfLimits),  
  sum(rs.TotCompWithWarning),   
  sum(rs.TotCompWithReject),  
  SUM(rs.TotalWarning),  
  SUM(RS.TotalOutWarningLimits),  
  SUM(rs.TotalReject),   
  SUM(RS.TotalOutRejectLimits),  
  sum(rs.TotalWarningLimitNotSet),  
  sum(rs.TotalRejectLimitNotSet),   
  0,  
  0,  
  0,  
  0,   
  0,   
  SUM(RS.notdone),  
  SUM(rs.NotDoneWarning),  
  SUM(rs.NotDoneReject)  
 FROM @ResultsByDispProdTmShft RS  
  
 Update @ResultsTotal set   
  PercInWarningCompliance = (  
   CASE   
   WHEN TotalWarning > 0  
   THEN 1.0 - (TotalOutWarningLimits / CONVERT(FLOAT, TotalWarning))  
   ELSE NULL   
   END  
     ),  
  PercOverallWarningCompliance = (  
   CASE   
   WHEN TotReqWithWarning > 0 --TotalWarning > 0  
   THEN 1.0 - ((TotalOutWarningLimits + NotDoneWarning) / CONVERT(FLOAT, TotReqWithWarning)) --TotalWarning))  
   ELSE NULL   
   END  
     ),  
  PercInRejectCompliance = (  
   CASE   
   WHEN TotalReject > 0  
   THEN 1.0 - (TotalOutRejectLimits / CONVERT(FLOAT, TotalReject))  
   ELSE NULL   
   END  
     ),  
  PercOverallRejectCompliance = (  
   CASE   
   WHEN TotReqWithReject > 0 --TotalReject > 0  
   THEN 1.0 - ((TotalOutRejectLimits + NotDoneReject) / CONVERT(FLOAT, TotReqWithReject)) --TotalReject))  
   ELSE NULL   
   END  
     ),  
  PercComplete =  (  
   CASE   
   WHEN TotReqRegardlessOfLimits > 0   
   THEN TotCompRegardlessOfLimits / convert(FLOAT,TotReqRegardlessOfLimits)  
   ELSE NULL   
   END  
    )  
  
  
--print 'Return Results ' + CONVERT(VARCHAR(20), GetDate(), 120)  
ReturnResultSets:  
  
--select 'ps', * from @ProductionStarts ps  
--order by var_id, Prod_ID, start_time  
  
--select 't', * from #tests t  
--where display_name = 'MT54 CL Winder Shiftly'  
--and result is null  
--order by var_id, prod_id, result_on  
  
--select 'tnd', * from dbo.#TestsNotDone  
--order by var_id, prod_id, result_on  
  
--select 'BaseResults', * from @BaseResults  
--select 'ResultsTotal', * from @ResultsTotal  
--select 'by DispProdTmShft', * from @ResultsByDispProdTmShft  
  
 ----------------------------------------------------------------------------------------------------  
 -- Error Messages.  
 ----------------------------------------------------------------------------------------------------  
  
 -- if there are errors FROM the parameter validation, then return them AND skip the rest of the results  
  
 if (SELECT count(*) FROM @ErrorMessages) > 0  
  
 begin  
  SELECT ErrMsg  
  FROM @ErrorMessages  
   
  if @ErrorVar <> 0  
  begin  
   INSERT  dbo.#RawData  
   SELECT Result_on [Test Timestamp],   
      Display_name [Proficy Display],   
      Team [Team],   
      Shift [Shift],  
      Product [Product],   
      Variable_name [Variable],  
      Data_Type [Data Type],   
      Unit [Units],   
      result [Result],   
      LowerEntry [L_Entry],  
      LowerReject [L_Reject],  
      LowerWarning [L_Warning],  
      LowerUser [L_User],  
      Target [Target],  
      UpperUser [U_User],  
      UpperWarning [U_Warning],  
      UpperReject [U_Reject],  
      UpperEntry [U_Entry],  
      replace(coalesce([Comment],''), char(13)+char(10), ' ') [Comment]    
   FROM dbo.#tests WITH(NOLOCK)  
   ORDER BY Product, Result_on   
  
   SELECT @SQL =   
   CASE  
   WHEN (SELECT count(*) FROM dbo.#RawData WITH(NOLOCK)) > 65000 then   
   'SELECT ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
   WHEN (SELECT count(*) FROM dbo.#RawData WITH(NOLOCK)) = 0 then   
   'SELECT ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
   ELSE GBDB.dbo.fnLocal_RptTABLETranslation('#RawData', @LanguageId)  
   END  
  
   if charindex(@TooMuchDataMsg,@SQL)=0 and charindex(@NoDataMsg,@SQL)=0    
    select @SQL = @SQL + ' order by [Product], [Test Timestamp]'    
  
   Exec (@SQL)   
  
   END  
  
 END  
  
 ELSE  
  
 begin  
 -------------------------------------------------------------------------------  
 -- Result sets  
 -------------------------------------------------------------------------------  
  
 SELECT ErrMsg  
 FROM @ErrorMessages  
  
 -- summary 1  result set 2   
 insert  dbo.#SummaryBySingle  
 select 'Summary by Team...' [ ],   
  NULL [Total Required],    
  NULL [Total Complete],    
  NULL [% Complete],   
  NULL [Total With Warning Limits],  
  NULL [Total Outside Warning Limits],  
  NULL [% Within Warning Limit],  
  NULL [% Warning Complete-Compliant],    
  NULL [Total With Reject Limits],  
  NULL [Total Outside Reject Limits],   
  NULL [% Within Reject Limit],  
  NULL [% Reject Complete-Compliant],   
  NULL [Total Not Done],  
  NULL [Total Warning Limits Not Set],   
  NULL [Total Reject Limits Not Set]    
  
 INSERT  dbo.#SummaryBySingle  
 SELECT  Team [ ],   
  TotReqRegardlessOfLimits [Total Required],    
  TotCompRegardlessOfLimits [Total Complete],    
  PercComplete [% Complete],   
  (  
   CASE   
   WHEN TotalWarning = 0  
   THEN NULL  
    ELSE TotalWarning   
   END  
  ) [Total With Warning Limits],  
  TotalOutWarningLimits [Total Outside Warning Limits],  
  PercInWarningCompliance [% Within Warning Limit],  
  PercOverallWarningCompliance [% Warning Complete-Compliant],   
  (  
   CASE   
   WHEN TotalReject = 0  
   THEN NULL  
    ELSE TotalReject   
   END  
  ) [Total With Reject Limits],  
  TotalOutRejectLimits [Total Outside Reject Limits],   
  PercInRejectCompliance [% Within Reject Limit],  
  PercOverallRejectCompliance [% Reject Complete-Compliant],  
  NotDone [Total Not Done],   
  TotalWarningLimitNotSet [Total Warning Limits Not Set],   
  TotalRejectLimitNotSet [Total Reject Limits Not Set]   
 FROM @ResultsByTeam  
 ORDER BY Team    
  
 insert  dbo.#SummaryBySingle  
 select NULL [ ],   
  NULL [Total Required],    
  NULL [Total Complete],    
  NULL [% Complete],   
  NULL [Total With Warning Limits],  
  NULL [Total Outside Warning Limits],  
  NULL [% Within Warning Limit],  
  NULL [% Warning Complete-Compliant],    
  NULL [Total With Reject Limits],  
  NULL [Total Outside Reject Limits],   
  NULL [% Within Reject Limit],  
  NULL [% Reject Complete-Compliant],   
  NULL [Total Not Done],  
  NULL [Total Warning Limits Not Set],   
  NULL [Total Reject Limits Not Set]   
  
 insert  dbo.#SummaryBySingle  
 select 'Summary by Proficy Display...' [ ],   
  NULL [Total Required],    
  NULL [Total Complete],    
  NULL [% Complete],   
  NULL [Total With Warning Limits],  
  NULL [Total Outside Warning Limits],  
  NULL [% Within Warning Limit],  
  NULL [% Warning Complete-Compliant],    
  NULL [Total With Reject Limits],  
  NULL [Total Outside Reject Limits],   
  NULL [% Within Reject Limit],  
  NULL [% Reject Complete-Compliant],   
  NULL [Total Not Done],  
  NULL [Total Warning Limits Not Set],   
  NULL [Total Reject Limits Not Set]    
  
 INSERT  dbo.#SummaryBySingle  
 SELECT  Dis_name [ ],   
  TotReqRegardlessOfLimits [Total Required],    
  TotCompRegardlessOfLimits [Total Complete],    
  PercComplete [% Complete],   
  (  
   CASE   
   WHEN TotalWarning = 0  
   THEN NULL  
    ELSE TotalWarning   
   END  
  ) [Total With Warning Limits],  
  TotalOutWarningLimits [Total Outside Warning Limits],  
  PercInWarningCompliance [% Within Warning Limit],  
  PercOverallWarningCompliance [% Warning Complete-Compliant],   
  (  
   CASE   
   WHEN TotalReject = 0  
   THEN NULL  
    ELSE TotalReject   
   END  
  ) [Total With Reject Limits],  
  TotalOutRejectLimits [Total Outside Reject Limits],   
  PercInRejectCompliance [% Within Reject Limit],  
  PercOverallRejectCompliance [% Reject Complete-Compliant],  
  NotDone [Total Not Done],   
  TotalWarningLimitNotSet [Total Warning Limits Not Set],   
  TotalRejectLimitNotSet [Total Reject Limits Not Set]   
 FROM @ResultsByDisp  
 ORDER BY Dis_name  
  
 insert  dbo.#SummaryBySingle  
 select NULL [ ],   
  NULL [Total Required],    
  NULL [Total Complete],    
  NULL [% Complete],   
  NULL [Total With Warning Limits],  
  NULL [Total Outside Warning Limits],  
  NULL [% Within Warning Limit],  
  NULL [% Warning Complete-Compliant],    
  NULL [Total With Reject Limits],  
  NULL [Total Outside Reject Limits],   
  NULL [% Within Reject Limit],  
  NULL [% Reject Complete-Compliant],   
  NULL [Total Not Done],  
  NULL [Total Warning Limits Not Set],   
  NULL [Total Reject Limits Not Set]   
  
 insert  dbo.#SummaryBySingle  
 select 'Summary by Product...' [ ],   
  NULL [Total Required],    
  NULL [Total Complete],    
  NULL [% Complete],   
  NULL [Total With Warning Limits],  
  NULL [Total Outside Warning Limits],  
  NULL [% Within Warning Limit],  
  NULL [% Warning Complete-Compliant],    
  NULL [Total With Reject Limits],  
  NULL [Total Outside Reject Limits],   
  NULL [% Within Reject Limit],  
  NULL [% Reject Complete-Compliant],   
  NULL [Total Not Done],  
  NULL [Total Warning Limits Not Set],   
  NULL [Total Reject Limits Not Set]    
  
 INSERT  dbo.#SummaryBySingle  
 SELECT  Prod_name [ ],   
  TotReqRegardlessOfLimits [Total Required],    
  TotCompRegardlessOfLimits [Total Complete],    
  PercComplete [% Complete],   
  (  
   CASE   
   WHEN TotalWarning = 0  
   THEN NULL  
    ELSE TotalWarning   
   END  
  ) [Total With Warning Limits],  
  TotalOutWarningLimits [Total Outside Warning Limits],  
  PercInWarningCompliance [% Within Warning Limit],  
  PercOverallWarningCompliance [% Warning Complete-Compliant],   
  (  
   CASE   
   WHEN TotalReject = 0  
   THEN NULL  
    ELSE TotalReject   
   END  
  ) [Total With Reject Limits],  
  TotalOutRejectLimits [Total Outside Reject Limits],   
  PercInRejectCompliance [% Within Reject Limit],  
  PercOverallRejectCompliance [% Reject Complete-Compliant],  
  NotDone [Total Not Done],   
  TotalWarningLimitNotSet [Total Warning Limits Not Set],   
  TotalRejectLimitNotSet [Total Reject Limits Not Set]   
 FROM @ResultsByProd  
 ORDER BY Prod_name    
  
 insert  dbo.#SummaryBySingle  
 select NULL [ ],   
  NULL [Total Required],    
  NULL [Total Complete],    
  NULL [% Complete],   
  NULL [Total With Warning Limits],  
  NULL [Total Outside Warning Limits],  
  NULL [% Within Warning Limit],  
  NULL [% Warning Complete-Compliant],    
  NULL [Total With Reject Limits],  
  NULL [Total Outside Reject Limits],   
  NULL [% Within Reject Limit],  
  NULL [% Reject Complete-Compliant],   
  NULL [Total Not Done],  
  NULL [Total Warning Limits Not Set],   
  NULL [Total Reject Limits Not Set]   
  
 insert  dbo.#SummaryBySingle  
 select 'Summary Overall...' [ ],   
  NULL [Total Required],    
  NULL [Total Complete],    
  NULL [% Complete],   
  NULL [Total With Warning Limits],  
  NULL [Total Outside Warning Limits],  
  NULL [% Within Warning Limit],  
  NULL [% Warning Complete-Compliant],    
  NULL [Total With Reject Limits],  
  NULL [Total Outside Reject Limits],   
  NULL [% Within Reject Limit],  
  NULL [% Reject Complete-Compliant],   
  NULL [Total Not Done],  
  NULL [Total Warning Limits Not Set],   
  NULL [Total Reject Limits Not Set]    
  
 insert  dbo.#SummaryBySingle  
 select 'Total' [ ],   
  TotReqRegardlessOfLimits [Total Required],    
  TotCompRegardlessOfLimits [Total Complete],    
  PercComplete [% Complete],   
  (  
   CASE   
   WHEN TotalWarning = 0  
   THEN NULL  
    ELSE TotalWarning   
   END  
  ) [Total With Warning Limits],  
  TotalOutWarningLimits [Total Outside Warning Limits],  
  PercInWarningCompliance [% Within Warning Limit],  
  PercOverallWarningCompliance [% Warning Complete-Compliant],    
  (  
   CASE   
   WHEN TotalReject = 0  
   THEN NULL  
    ELSE TotalReject   
   END  
  ) [Total With Reject Limits],  
  TotalOutRejectLimits [Total Outside Reject Limits],   
  PercInRejectCompliance [% Within Reject Limit],  
  PercOverallRejectCompliance [% Reject Complete-Compliant],   
  NotDone [Total Not Done],  
  TotalWarningLimitNotSet [Total Warning Limits Not Set],   
  TotalRejectLimitNotSet [Total Reject Limits Not Set]    
 FROM @ResultsTotal  
  
 SELECT @SQL =   
 CASE  
 WHEN (SELECT count(*) FROM dbo.#SummaryBySingle WITH(NOLOCK)) > 65000 then   
 'SELECT ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 WHEN (SELECT count(*) FROM dbo.#SummaryBySingle WITH(NOLOCK)) = 0 then   
 'SELECT ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 ELSE GBDB.dbo.fnLocal_RptTABLETranslation('#SummaryBySingle', @LanguageId)  
 END  
  
 if charindex(@TooMuchDataMsg,@SQL)=0 and charindex(@NoDataMsg,@SQL)=0    
  select @SQL = @SQL    
  
 Exec (@SQL)   
  
  
 -- summary 2  result set 3  
  
 INSERT  dbo.#SummaryByDispProdTmShft  
 SELECT  Dis_name [Proficy Display],   
  Prod_name [Product],  
  Team [Team],   
  Shift [Shift],   
  TotReqRegardlessOfLimits [Total Required],  
  TotCompRegardlessOfLimits [Total Completed],  
  PercComplete [% Complete],   
  (  
   CASE   
   WHEN TotalWarning = 0  
   THEN NULL  
    ELSE TotalWarning   
   END  
  ) [Total With Warning Limits],  
  TotalOutWarningLimits [Outside Warning],  
  PercInWarningCompliance [% Warning Compliant],  
  PercOverallWarningCompliance [% Warning Complete-Compliant],   
  (  
   CASE   
   WHEN TotalReject = 0  
   THEN NULL  
    ELSE TotalReject   
   END  
  ) [Total With Reject Limits],  
  TotalOutRejectLimits [Outside Reject],   
  PercInRejectCompliance [% Reject Compliant],  
  PercOverallRejectCompliance [% Reject Complete-Compliant],   
  NotDone [Total Not Done],   
  TotalWarningLimitNotSet [Total Warning Limits Not Set],   
  TotalRejectLimitNotSet [Total Reject Limits Not Set]    
 FROM @ResultsByDispProdTmShft r  
 ORDER BY Team, shift, Dis_name, prod_name  
  
 SELECT @SQL =   
 CASE  
 WHEN (SELECT count(*) FROM dbo.#SummaryByDispProdTmShft WITH(NOLOCK)) > 65000 then   
 'SELECT ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 WHEN (SELECT count(*) FROM dbo.#SummaryByDispProdTmShft WITH(NOLOCK)) = 0 then   
 'SELECT ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 ELSE GBDB.dbo.fnLocal_RptTABLETranslation('#SummaryByDispProdTmShft', @LanguageId)  
 END  
  
 if charindex(@TooMuchDataMsg,@SQL)=0 and charindex(@NoDataMsg,@SQL)=0    
  select @SQL = @SQL + ' order by [Team], [Shift], [Proficy Display], [Product]'    
  
 Exec (@SQL)   
  
  
 -- variables outside warning  result set 4  
  
 INSERT  dbo.#WarningSummary  
 SELECT Result_on [Time Out],   
  Display_name [Proficy Display],   
  Team [Team],   
  Shift [Shift],   
  Product [Product],   
  Variable_name [Variable],   
  Unit [Units],   
  result [Result],   
  LowerWarning [L_Warning],    
  Target [Target],  
  UpperWarning [U_Warning],    
  replace(coalesce([Comment],''), char(13)+char(10), ' ') [Comment]       
 FROM dbo.#Tests w WITH(NOLOCK)       
 WHERE w.OutWarning = 1  
 ORDER BY Product, Result_on    
  
  
 SELECT @SQL =   
 CASE  
 WHEN (SELECT count(*) FROM dbo.#WarningSummary WITH(NOLOCK)) > 65000 then   
 'SELECT ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 WHEN (SELECT count(*) FROM dbo.#WarningSummary WITH(NOLOCK)) = 0 then   
 'SELECT ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 ELSE GBDB.dbo.fnLocal_RptTABLETranslation('#WarningSummary', @LanguageId)  
 END  
  
 if charindex(@TooMuchDataMsg,@SQL)=0 and charindex(@NoDataMsg,@SQL)=0    
  select @SQL = @SQL + ' order by [Product], [Time Out]'    
  
 Exec (@SQL)   
  
  
 -- variables outside reject  result set 5  
  
 INSERT  dbo.#RejectSummary  
 SELECT Result_on [Time Out],   
  Display_name [Proficy Display],   
  Team [Team],   
  Shift [Shift],   
  Product [Product],   
  Variable_name [Variable],   
  Unit [Units],   
  result [Result],   
  LowerReject [L_Reject],   
  Target [Target],  
  UpperReject [U_Reject],  
  replace(coalesce([Comment],''), char(13)+char(10), ' ') [Comment]       
 FROM dbo.#Tests r WITH(NOLOCK)  
 WHERE r.OutReject = 1 AND Data_Type = 'VARIABLE'  
 ORDER BY Product, Display_name, Result_on, Team  
  
  
 SELECT @SQL =   
 CASE  
 WHEN (SELECT count(*) FROM dbo.#RejectSummary WITH(NOLOCK)) > 65000 then   
 'SELECT ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 WHEN (SELECT count(*) FROM dbo.#RejectSummary WITH(NOLOCK)) = 0 then   
 'SELECT ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 ELSE GBDB.dbo.fnLocal_RptTABLETranslation('#RejectSummary', @LanguageId)  
 END  
  
 if charindex(@TooMuchDataMsg,@SQL)=0 and charindex(@NoDataMsg,@SQL)=0    
  select @SQL = @SQL + ' order by [Product], [Time Out]'    
  
 Exec (@SQL)   
  
  
 -- attributes out  result set 6  
 INSERT  dbo.#AttributesOut  
 SELECT Result_on [Time Out],   
  Display_name [Proficy Display],   
  Team [Team],   
  Shift [Shift],   
  Product [Product],   
  Variable_name [Variable],   
  Unit [Units],   
  result [Result],   
  LowerReject [L_Reject],   
  Target [Target],  
  UpperReject [U_Reject],  
  replace(coalesce([Comment],''), char(13)+char(10), ' ') [Comment]      
 FROM dbo.#Tests r  
 WHERE r.OutReject = 1 AND Data_Type = 'ATTRIBUTE'  
 ORDER BY Product, Display_name, Result_on, Team  
  
  
 SELECT @SQL =   
 CASE  
 WHEN (SELECT count(*) FROM dbo.#AttributesOut WITH(NOLOCK)) > 65000 then   
 'SELECT ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 WHEN (SELECT count(*) FROM dbo.#AttributesOut WITH(NOLOCK)) = 0 then   
 'SELECT ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 ELSE GBDB.dbo.fnLocal_RptTABLETranslation('#AttributesOut', @LanguageId)  
 END  
  
 if charindex(@TooMuchDataMsg,@SQL)=0 and charindex(@NoDataMsg,@SQL)=0    
  select @SQL = @SQL + ' order by [Product], [Proficy Display], [Time Out], [Team]'    
  
 Exec (@SQL)   
  
 -- Raw Data   result set 7  
 if @BYSummary = 1 OR @ErrorVar <> 0  
 -------------------------------------------------------------------------------  
 -- If the dataset has more than 65000 records, then sEND an error message AND  
 -- suspEND processing.  This is because Excel can not hANDle more than 65536 rows  
 -- in a spreadsheet.  
 -------------------------------------------------------------------------------  
  
 begin  
  
 INSERT  dbo.#RawData  
 SELECT Result_on [Test Timestamp],   
  Display_name [Proficy Display],   
  Team [Team],   
  Shift [Shift],  
  Product [Product],   
  Variable_name [Variable],  
  Data_Type [Data Type],   
  Unit [Units],   
  result [Result],   
  LowerEntry [L_Entry],  
  LowerReject [L_Reject],  
  LowerWarning [L_Warning],  
  LowerUser [L_User],  
  Target [Target],  
  UpperUser [U_User],  
  UpperWarning [U_Warning],  
  UpperReject [U_Reject],  
  UpperEntry [U_Entry],  
  replace(coalesce([Comment],''), char(13)+char(10), ' ') [Comment]  -- 2005-MAR-31 VMK Rev5.92  
 FROM dbo.#tests WITH(NOLOCK)  
 ORDER BY Product, Result_on  
  
 SELECT @SQL =   
 CASE  
 WHEN (SELECT count(*) FROM dbo.#RawData WITH(NOLOCK)) > 65000 then   
 'SELECT ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 WHEN (SELECT count(*) FROM dbo.#RawData WITH(NOLOCK)) = 0 then   
 'SELECT ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 ELSE GBDB.dbo.fnLocal_RptTABLETranslation('#RawData', @LanguageId)  
 END  
  
 if charindex(@TooMuchDataMsg,@SQL)=0 and charindex(@NoDataMsg,@SQL)=0    
  select @SQL = @SQL + ' order by [Product], [Test Timestamp], [Variable]'  
  
 Exec (@SQL)   
  
 END  
 END  
  
-- DROP TABLEs  
DropTables:  
  
DROP TABLE dbo.#Tests  
DROP  TABLE dbo.#TestsNotDone  
DROP TABLE dbo.#SummaryBySingle  
DROP TABLE dbo.#SummaryByDispProdTmShft  
DROP TABLE dbo.#WarningSummary  
DROP TABLE dbo.#RejectSummary  
DROP TABLE dbo.#AttributesOut  
DROP TABLE dbo.#RawData  
  
--print 'done ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
