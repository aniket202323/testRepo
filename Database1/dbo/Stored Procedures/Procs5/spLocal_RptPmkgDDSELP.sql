  /*  
**** This SP is best viewed with Tab Size = 3. (Tools/Options/Editor Tab) ****  
  
Stored Procedure: spLocal_RptPmkgDDSELP  
Date Created:  09/18/02  
  
Last Modified:  2009-03-12 Jeff Jaeger Rev8.53  
  
======================================================  
  
INPUTS: Start Time  
   End Time  
   Production Line Name (without 'TT' prefix)  
   Report Product Id:   0 or Null  - Returns summary data across all Products, with Production data grouped by Product  
          Product Id  - Returns summary data for that Product only  
  
CALLED BY:  RptPmkgDDS.xlt (Excel/VBA Template)  
  
CALLS: None  
  
Revision Change Date Who   What  
======== =========== ====   =====  
0.0  09/18/02  MKW   Created  
  
6.0  2003-10-28  Simon Poon  Modified the ResultSet such that it can be used by the   
           report.  
  
6.1  2003-OCT-31 FLD   Modified base name from spLocal_RptPmkgELP to spLocal_RptPmkgDDSELP  
           to clarify report association.  
  
6.2  2003-DEC-04 FLD   - Changed ORDER BY in selection of results set for the 'Top 5'  
             ELP to be based on loss, then number of stops, first within  
             then within Storage if <5 Fresh.  
           - Modified Fresh -- Old determination from Fresh is <24 to <=24 to be  
             consistent with definitions in other reports.  
  
6.3  2003-DEC-30 Jeff Jaeger - Added the temp table #ErrorMessages  
           - Added #ErrorMessages to result sets.  
           - Added flow control surrounding #ErrorMessages.  
           - Added validation checks for input parameters.  
  
6.4  2004-Feb-03 Jeff Jaeger - Changed all real data types to float.  
  
7.1  2004-06-17 Jeff Jaeger - Added the @UserName parameter.  
           - Added variables and related code for language translation.  
           - Added #SummaryText and #TopReasons.  I'm not sure that we need a   
              separate temp table to summarize data in text format, but since   
               there is some special formatting being done there, I thought it   
               couldn't hurt.  
           - Added checks for result sets with more than 65000 records and   
               result sets with zero records.  
           - Where Var_Desc was used to pull values from the database, I converted   
              the code to use Global Descriptions.  
           - Converted the following temporary tables to table variables:  
                   #Converters, #Roll_Times, #ELP_Sum, #ELP, #ErrorMessages.  
           - Removed unused code.  
             - Removed the cursor used to populate #ELPSummary and replaced it with   
              an initial insert statement and then an update.  
  
7.4  2004-08-27 Jeff Jaeger - Converted this report to be more in line with Cvtg ELP.  
           - Stripped out a lot of unused code... including the input parameters:   
             @GroupCauseStr, @SubSystemStr, @CatMechEquipId, @CatElectEquipId,   
             @CatProcFailId, @PRIDVarStr, @PRIDRLVarStr, @UWSVarStr, @RL1Title,    
             @RL2Title, @RL3Title, @RL4Title, @PackPUIdList  
           - Removed Language translation related code.  
   
7.5  2004-11-29 Jeff Jaeger - Removed unused code.  
           - Added final insert to #Delays.  
  
7.6  2005-01-26 Jeff Jaeger - Removed unused code.  
           - Removed parameters @DelayTypeList, @ScheduleStr, @CategoryStr,   
             @CatBlockStarvedId, @CatELPId, @SchedPRPolyId,   
             @SchedUnscheduledId, @SchedSpecialCausesId, @SchedEOProjectsId,   
             @SchedBlockedStarvedId, @DelayTypeRateLossStr.        
           - Added variables for the above parameters and code to assign values.  
  
7.70  2005-FEB-27 L. Davis  Removed the population of the comments field in #Delays.  
  
7.80  2005-MAR-08 Vince King Modified code to stream line report.  
  
7.81  2005-MAR-09 Vince King Modified the code to populate @ELPDelays table.  td.CategoryId =   
           @CatELPId was placed in CASE Statements within the SELECT.  I   
           moved td.CategoryId = @CatELPId to WHERE clause.  Also the  
           link between the DATETIME in #Delays and dbo.#PRsRun was in the CASE  
           statement.  This was moved to the JOIN statement for dbo.#PRsRun.  
  
           The runtime of the sp was improved by roughly 20 seconds.  
  
7.82  2005-MAR-10 Vince King Changed the statement that selects only DT Events with PRIDs from  
           this Paper Machine.  The PRIDs PM Prefix is not standard with the  
            Paper Machine PL_Desc.  
  
7.83  2005-MAR-22 L. Davis  Changed 'SET ANSI_NULLS OFF' to 'SET ANSI_NULLS ON'.  
  
7.84  2005-MAR-25 Vince King Modified code that populates @ELPDelays tables.  It was including ALL  
           events.  This caused non-ELP events to be reported when NO ELP occurred   
           during the time period.  
  
7.85  2005-APR-13 Vince King ELP was not showing for some of the paper machines.  It was determined  
           that the ELP was not being selected for delay events on Converting lines  
           that were receiving paper from intermediates.  The intermediates where  
           running paper from the selected paper machine.  A new section of code was  
           inserted to add rows to the @ProdLines table based on the initial entries  
           of @ProdLines, link back to PrdExec_Input_Sources using the 'Rolls' prod  
           unit for those lines.  This retrieved the production lines for the units  
           that had that 'Rolls' unit as their Input_Source.  
           Also added code to include the selection of delay events where the   
           Grand Parent PRID matched the PRID from dbo.#PRsRun.  
           And when creating @ELPDelays, compare the selected Paper machine with the  
           GrandParent PRID in addition to the already coded Parent PRID.  
  
7.86  2005-APR-14 Vince King When selecting the additional prod units that are receiving paper from  
           intermediates as defined above (Rev7.85), a Primary Key Constraint error  
           was occuring when a Production Line had a Paper Machine Prod Line as an   
           Input_Source AND an Intermediate as an Input_Source that also had the   
           Paper Machine Prod Line as an Input_Source.    
           Changed the code to select the prod lines for intermediates into a  
           different table (@ProdLinesGP), then insert from that table to @ProdLines  
           only lines that do not exist in @ProdLines.  
  
7.87  2005-Apr-14 Vince King ELP numbers not matching up with CvtgELP report.  Found where I had  
           commented out the code to select only Converters and Intermediates  
           prod units.  This was allowing additional prod units to be included in   
           the PmkgDDSELP report.  
  
7.90  2005-04-27 Jeff Jaeger  
   -  Removed the non-clustered indices from #Delays  
   -  Added a restriction that e.timestamp be within the report window when populating PRsRun.  
   -  Added temp tables #Tests, #Events, and #LTEC in an effort to reduce the reads against the database.  I haven't   
    replaced all joins to Tests with #Tests yet, because there are some errors coming up that I have to troubleshoot.  
  
7.91  2005-05-03 Jeff Jaeger  
   -  Added dbo. to references of database objects.  
  
7.92  2005-MAY-20 Langdon Davis  
   Changed 'SET ANSI_NULLS OFF' to 'SET ANSI_NULLS ON'.  WHO CHANGED IT BACK FROM MY MARCH 22nd CORRECTION?!?  
  
7.93  2005-JUL-11 Langdon Davis  
   Removed the "inspect data quality in" WHERE claus restrictions for PRConversionEndTime  
   minus PRConversionStartTime being >0 and less than 1 day.  With these in place, an elusive  
   error for converting a character value to datetime was occuring.  
  
7.94  2005-OCT-04 Vince King  
   Added EventNum to the dbo.#PRsRun table variable and Event_Num to the #Events table.  Modified code to use PUId,   
   StartTime and EventNum as Primary Index on dbo.#PRsRun.  This allows the report to run even though there are   
   may be duplicate PRIDs.  
  
7.95  2006-JAN-24 Vince King  
   Modified the sp to return additional ELP data for the Perfect Parent Roll project.  Additional calcs are:  
   ELP% on Fresh, Perfect Rolls; ELP% on Fresh, Not Perfect Rolls; ELP% on Fresh, Flagged Rolls;   
   ELP% on Fresh, Reject/Hold Rolls; Overall ELP% on All Statuses Fresh; Overall ELP% on ALL Statuses Storage;  
   ELP% on ALL Statuses.  
   Also added result sets for Top 5 ElP Causes on Fresh Paper - All Roll Statuses and  
    Top 5 ELP Causes on Storage Paper - All Roll Statuses and  
    Top 5 Causes of Less than Perfect Rolls.  
   Modified the ELP% calculation to include Total Runtime (Total Runtime - Scheduled DT) as denominator.  The   
   existing calculation was not using Total Runtime.  
   Added intRptIncludeTeam (@RptIncludeTeam) to determine if Team should be reported or not.  
  
7.96  2006-JAN-25 Vince King  
   Modified JOIN to Var_Specs table in SELECT to populate dbo.#PerfectPRTests table.  It was not picking up the   
   specs for current date/time.  
  
7.97  2006-JAN-26 Vince King  
   Tuning - Added OPTION (KEEP PLAN) to SELECT Statements.  
   Modified code for dbo.#PerfectPRTests so that where Result IS NULL, the previous NOT NULL value is used.  
   Change all %ELP calcs to use the correct Runtime based on the Numerator.  So for Fresh Perfect ELP%,   
   the denominator is the total runtime for Fresh Perfect Paper minus Scheduled DT for Fresh Perfect Paper.  
   Modified several tables to include additional columns required for ELP% calculations.  
   Changed %Loss calculations for Top 5 Causes Fresh Paper and Top 5 Causes Storage Paper to use TotalFreshRuntime  
   and TotalStorageRuntime, respectively, as denominator in calcs.  
  
8.01  2006-FEB-23 Vince King  
   Modified to capture only records with the specific papermachine for returned results in scheduled dt.  
   Removed SUM from last result set, not required since rows in @ELPSummary are already summarized as needed.  
   Added code to capture the lowest Input_Order for parent rolls with the maximum amount of Runtime.  This   
   matches how CvtgELP sp works.  
   Modified code to allow Rate Loss events to be included when summarizing Scheduled DT.  
  
8.02  2006-FEB-24 Langdon Davis  
   The way that rolls were being assigned to one of the 3 status categories [Not Perfect, Falgged, Reject/Hold]  
   in dbo.#PerfectPRTests was not taking into account that a roll that doesn't meet the warning limits [Flagged]  
   by definition doesn't meet the user limits [Not Perfect].  As a result, Flagged rolls were showing up in   
   both the Not Perfect and Flagged counts and Reject/Hold rolls in all three.  Fixed this by adding in  
   update statements to populate these three fields one by one.  
  
8.03  2006-FEB-27 Vince King  
   Rate Loss DT was being included in the minutes from a previous Rev, but it was being directly added to the   
   downtime and then the total was divided by 60 to get minutes.  The downtime is stored in seconds and the   
   rate loss downtime is stored in minutes.  This was dividing the rate loss minutes by 60 and causing the total to be  
   less than is actually should have been.  Moved the / 60.0 to be only used with downtime minutes.  This   
   caused Fresh DT and Storage DT minutes to match CvtgELP.  
   
8.04  2006-FEB-28 Vince King  
   The calculation put in place on 2006-FEB-06 were not calculating the Overall ELP% correctly.  These changes were   
   made to remove the SUM in the previous statements.  Since the data is already summarized, the SUM was not actually  
   doing anything.  I changed the code back to the original, but removed the SUM from the statements.  The data  
   is right in @ELPSummary, so no need to re-calculate.  
  
8.05  2006-MAR-10 Vince King  
   Modified code to use PaperMaking Perfect Parent Roll Status variable(s).  
   Added filter back in to remove all dbo.#PRsRun rows not related to the specified paper machine (@Line_Name).  
   Modified code to use #events table.  
   Modified code to use #tests table where possible.  Some of the data being retrieved from dbo.tests is from  
   outside of the report period and we do not know when the timestamp will be.  So we can not bring those values into  
   the temporary table.  
   Modified @ELPDelays INSERT so that we are not getting NoAssignedPRID for the Parent column.  
  
8.06  2006-MAR-29 Vince King  
   Modified dbo.#PRsRun table and added ID IDENTITY column.    
   Modified code throughout sp for JOINs to dbo.#PRsRun table to use ID IDENTITY column.  
   Added code to adjust EndTime of dbo.#PRsRun entries so that there is no overlap of events.  
  
8.07  2006-MAR-30 Vince King  
   Added an update to dbo.#PRsRun to get Perfect Parent Roll Status for INTR (intermediate) lines.  The update gets the   
   timestamp for the PRID variable in PM Rolls unit based on the PRID in dbo.#PRsRun.  Then it uses that timestamp to get  
   the Perfect Parent Roll Status value.  This value is assigned to the PerfectPRStatus column in dbo.#PRsRun.  
   Also changed the column dbo.#PRsRun.PRPLId to PRPUId since it really contained PU_Ids instead of PL_Ids  
  
8.08  2006-MAY-08 Langdon Davis  
   -  Fixed the association of the ELP to the Pmkg product.  What was being done was   
      association using the PROLL Conversion Start Time, versus the Pmkg Event Timestamp.  
   -  Cleaned out unused code/variables.  
   -  Converted some variables to hard-coding where possible due to global standard   
      configuration and there was no value-added by having a variable and then   
      assigning a value(s) to it and, in the case of a list, then having to parse this   
      value out.  An example is @DelayTypeList.   
   -  Fixed the code that was intended to identify and fix gaps and overlaps in the   
      PRsRun data.  The PEIId's had been left out of the correlated sub-queries.  Gaps   
      are now filled with NoAssignedPRID.  
   -  Modified the code to split events based on changes in papermachine.  Note that   
      since we are running this sp on a single machine, that changes in paper machine basically are changes   
    back and forth between the indicated machine and NoAssigedPRID records inserted to fill the gaps.   
   -  Modified the code to correct for gaps at the beginning or end of the report window,  
      e.g., instances where the first parent roll we have with either a start or end time within the window has   
    a start time that is after the report start time, or,instances where the last parent roll we have has an   
    end time earlier than the report end time.  
   -  Miscellaneous tuning changes to eliminate unnecessary JOINS and other processing.  
   -  Corrected an error where, if there was no ELP on a given product, it was being   
      ommitted from the ELP results set.  
   -  Corrected some errors where the COALESCE should have been inside the SUM statement  
      rather than on the final summed result.  
  
8.09  2006-MAY-08 Langdon Davis  
   I realized I had not made some of the above changes in the 'IF @RptIncludeTeam = 1'  
   section.  Corrected this oversight.  
  
8.10  2006-MAY-09 Langdon Davis  
   Corrected a bug with some missing prefixes on 'Fresh' and 'PerfectPRStatus' references  
   in the @RptIncludeTeam = 1 section.  
  
  
8.11  2006-06-15 Jeff Jaeger  
   - Convert @PRsRun to dbo.#PRsRun, due to the potential size of the table.  
   - Updated the sp to use the new events approach to building dbo.#PRsRun.  
   - Removed @uws because its not needed anymore.  
   -  Added code related to splitting downtime events, including new tables #Dimensions, #TimeSlices,  
    #SplitDowntimes, #SplitUptimes  
   -  Attempted to optimized this code through use of LTED to populate #Delays, and   
    through a broader use of #tests.  both these efforts took longer to run.  
   - The Rateloss test value is stored in minutes, but when RLMinutes was determined for @ELPDelays, it   
    was divided by 60.0 as if it were in seconds.  I've made corrections for this.  
  
   NOTE: The new approach for building dbo.#PRsRun does have an impact on the data being pulled in.    
   These issues might well alter the results that the report once would have generated.    
    -  Entry_on is now compared with the report window to determine the events to include in the result set.    
     this means that records that were originally outside of the report window might be pulled in.  
    -  Event_History is now being used to include previous runs of parent rolls.  This means there can be   
     multipe runs represented, with gaps in between.  
    -  AgeOfPR used to be determined based on ed.timestamp and e.timestamp but are now determined by   
     what was ed.timestamp and the prs starttime.  This change is due to the fact that a parent roll   
     might be in the result set more than once.  
  
8.12 2006-07-13 Jeff Jaeger  
  Added a coalesce to the initial inserts to @PMProdChanges and @PMTeamChanges.  
  
8.13 2006-07-26 Jeff Jaeger  
  - Rateloss events were being excluded by the split.  I added an update to #Splitdowntime   
   to update rateloss puid values to the corresponding reliability puid values so the split would   
   pick up those events.  
  - Made changes in @ELPReasonSums so that RL Downtime is divided by 60.0 when used in calcs.  
  
8.14 2006-09-15 Jeff Jaeger  
  - updated the initial insert to #PRsRun, so that the endtime is the next event history entry-on   
   or the event entry_on.  
  - changed the update to #PRsRun endtime to be prs1.starttime <= prs2.starttime, not just <.  
  -  changed the update of endtime to an update of the starttime.  
  
8.15 2006-10-11  Vince King  
  - Added code from CvtgELP stored procedure to handle any number of unwind stands running at a time.  
   The number of UWSs is calculated for each @PRsRun row.  For Intermediate lines, the UWS Reliability  
   unit is used to determine how many are running.  For other lines, the number of UWSs running in   
   the @PRsRun table is used.  
  - This also handles when a single UWS is used for 1-ply product.  Switching between 2-ply and 1-ply   
   product in Tissue/Towel is taken into account.  
  - Found a Primary Key Constraint error in @ProdLinesGP.  It did not occur all of the time, but was  
   intermitent.  The PLDesc was being pulled from @ProdLines which caused the Distinct SELECT to return  
   multiple rows for a single converting line.  Corrected this along with some changes to some of the   
   columns returned in that result set.  
  
8.16 2006-11-10  Vince King  
  - Added code changes to implement Runtime adjustments for Facial lines by using the UWS Reliability  
   downtime events data.  
  - All changes are commented through out the sp.  
  - Sections that will not be used until the configuration is corrected for UWS Reliability units has  
   been commented out.  Once the configuration is corrected, these sections will be uncommented and then  
   the calcs put in place for Runtime.  
  - Also made added dbo. to a temporary table reference.  
  - To find changes associated with this revision, search for "Rev8.16".  
  
8.17 2006-11-17  Vince King  
  - Added OR statement when populating #Events that checks to see if the events TimeStamp is within the  
   report period.  
  - To find changes associated with this revision, search for "Rev8.17".  
  
8.18 2006-11-22  Vince King  
  - Added CONVERT to datetime columns in code to populate #PRsRun table to truncate tenths of a second.  It was  
   causing zero runtimes.  
  -  Added dbo. to event_history table for performance.  
  - Changed > to >= in code for endtime comparison in order to capture missing rows.  
  - Added DROP TABLES dbo.#SplitDowntimes to end of sp.  
  - IN ORDER TO FIND THESE CHANGES: Search for "Rev8.18"  
  
8.19 2006-11-29 Vince King  
  - In some cases we were getting an Entry_On datetime that was equal to the report start time.  This   
   caused an extra row in #PRsRun to be created that had starttime = endtime, which was equal to the starttime   
   of the report.  
  - In order to prevent this from occuring, since it is possible to happen although not likely to happen  
   frequently, a condition was added to the WHERE clause for the #PRsRun INSERT for 'StartTime' <> 'EndTime'  
  - Comments can be found by searching on Rev8.19.  
  
8.20 2006-12-03 Vince King  
  - We were getting a divide by zero error.  Found where some rows were getting into #PRsRun with Runtime = 0.  
  - Added code to #Events and #PRsRun inserts to ensure that correct entries were being captured.  
  - Moved some code to earlier in the sp so that Endtimes are assigned more accurately.  
  - Eliminated Reject (event_status = 19) from #Events/#PRsRun tables.  
  -  Modified code that sets Endtimes for #PRsRun so that it only changes rows with EndTime = NULL.  
  
8.21 2006-12-06 Vince King  
  - There were several machines that had the report failing with an Primary Key Constraint error on @PMProdChanges  
   table.  I found where there was a different product code (Pmkg) running on the unwind stands for a line.  Since  
  - The PUId, PMProdDesc and StartTime were included as DISTINCT columns in @PMProdChanges table and PUId/Starttime  
   were the Primary Key, that combination was getting duplicated.  
  - I added PMProdDesc as part of the Primary Key for @PMProdChanges.  
  - Also, when adding the PMProdChange dimension to timeslices, there is a possibility to return more than 1 row.    
   So I added TOP 1 to that select.  Results were not effected by making these changes, but the problem described  
   above was solved.  
  
8.22 2006-12-07 Vince King  
  - Although unexpected, we have seen the same problem as described above in 8.21 except with PMTeam.  Which actually  
   makes sense, if we can have different PM Prod on UWSs, then it is possible to have different PM Teams.    
  - Added PMTeam as part of the Primary Key for @PMTeamChanges table.  
  - Added TOP 1 to SELECT for populating PMTeam dimension to timeslices.  
  
8.23  2006-12-07 Vince King  
  - We were picking up some duplicate rows in #PRsRun.  It turned out to be due to an OR statement in a JOIN in the  
   SELECT.  Changed it to use a COALESCE instead of using the OR and solved the problem.  
  
8.24  2007-01-08 Jeff Jaeger  
 - these changes can be found by searching on "Rev8.24"  
 - Completely overhauled the insert of data into #Events.  
 - Changed @ProdLines to #ProdLines for use in dynamic SQL statements used to populate #Events.  
 - Completely overhauled the insert to #PRsRun.  
 - Added PRPUID to the index on @PMChanges.  
 - Changed the primary key index on #Events to Event_ID, Entry_On.  
 - Removed the Select @i statements for each temp table.  Testing done by Langdon and myself indicates   
  that using these is actually less efficient than not using them.  
 - Changed the inserts to #PRsRun for gaps between PRIDS so that it will assign -1 or empty string values   
  instead of PRPUID and Team respectively.  Assigning values from the nearest PRID (as was done before)   
  causes incorrect changes in PM and incorrect ELP values to be calculated later in the code....     
 - Changed the update of Endtime in #PRsRun for overlap of PRIDS     
 - removed a Runtime calc for #PRsRun that was inadequate.  the better calc was already in place later   
  in the code.  
 - updated the determination of Endtime when tracking changes in PM, PMProd, and PMTeam.  
 - Added the variables @DBVersion, @SQL4EventHistory, @SQL4EventHistoryBeforeReportWindow,  
  @SQL3Events, @SQL3EventHistory, @SQL3EventHistoryBeforeReportWindow, @SQL3EventsBeforeReportWindow  
  along with all related code.  
 - In the calculation of NoOfUWSRunning in #PRsRun, there have been a number of changes:  
  1. the CASE clause of the statement has been updated to remove the coalesce.  
  2. the THEN clause has a select where the subtraction used TEDet_ID.  This has been changed to a   
  Distinct pu_id.  Also, this was an embedded CASE statement, and has been reduced to a single   
  subtraction.  
  3. The select in the THEN clause also included a subquery against #ProdLines.  This has been   
  removed and a direct join to #ProdLines is used instead.  
  4. in the ELSE clause, the join to Prod_Units has been removed because it is not needed.  
  5. also in the ELSE clause, the date range restriction has been updated to capture all overlaps.  
 - During some updates to #PRsRun, some CASE statements have been reduced to Coalesce statements,   
  because there was only one When clause that tested for a NULL value.  
 - removed some commented code that existed elsewhere in the sp.  this was done to make the code more   
  readable while troubleshooting.  
 - updated the subquery in the second insert to #PRsRun, for gaps between existing records.  the > comparison  
  needs to be >= or the insert will create duplicate entries in the table.  
 - returned the update of PMProd and PMTeam in #TimeSlices to be a simple select statement (rather than TOP 1)  
  because our changes on PM, PMProd, and PMTeam references the PrimaryUWS and so there shouldn't be multiple   
  values that can be returned.  the subquery for the "gaps" insert to #PRsRun was creating duplicate entries  
  where no valid PMProd or PMTeam was assigned (but the records from the initial #PRsRun insert did have values)  
  and I believe that these values were the cause of the multiple results being returned in the PMProd and   
  PMTeam updates to #TimeSlices.  this problem should resolved with the fix to the #PRsRun insert.  
 - replaced various count() queries with either exists or not exists, as required.  
 - readded the indices for #SplitDowntime and #TimeSlices.  
  
8.25  2007-01-18 Jeff Jaeger   
 - rewrote the overlap update to #PRsRun.  as configured before, it was not handling cases where 2 events  
  have the same start time and different end times.   
 - in the insert to #PRsRun, changed the left join for Parent PRID to use a coalesce(e1.timestamp,e.timestamp)  
  
8.26 2007-01-23 Jeff Jaeger  
 - removed the original assignment of team in #PRsRun.  
 - added an update to #PRsRun that will more adequately assign the Team.  
  
8.27 2007-01-26 Jeff Jaeger  
 - added a new update to #PRsRun to handle entries with the same event_id where there were two event entries   
  with a Running status, but no end status between them.  
 - changed the overlap update (again) so that it will update the endtime and not the starttime.  this is   
  because the code is using the Starttime (or the Running status) as the benchmark for   
  tracking events, so it is probably better not to modify that value.  
  
8.28 2007-02-05 Jeff Jaeger  
 - Removed the variables @SQL4EventHistory and @SQL4EventHistoryBeforeReportWindow along with the code   
  that populates them.    
 - Removed the IF statement used to populate #Events.  Now that table is only populated using the original   
  3.x dynamic SQL statements.  NOTE: I have tested these inserts as dynamic SQL statements and as direct   
  inserts.  The direct inserts are much slower.  
 - updated the dynamic SQL inserts to #Events from Event_History to include a check for   
  eh.entry_on < e.entry_on.  This is done so that we don't insert duplicate records when running against   
  a 4.x database.  
 - Removed the index from #PerfectPRTests.  Although its counter-intuitive, this does appear to run faster.  
  
8.29 2007-02-06 Jeff Jaeger  
 - updated the where clause in the "Running to Running" and "Overlap" updates to #PRsRun.  
  changed the comparison "prs1.StartTime < prs2.StartTime" to "prs1.StartTime <= prs2.StartTime"  
  in each update.   
  
8.30 2007-02-07 Jeff Jaeger  
 - removed the "Running to Running" update to #PRsRun.  
 - added a condition "and prs1.Endtime < prs2.endtime" to the where clause in the "Overlap" update  
  to #PRsRun.    
 - removed the condition "and prs1.eventid <> prs2.eventid" from the where clause in the "Overlap"  
  update to #PRsRun.  This new "Overlap" update should also handle the "Running to Running" conditions,  
  so two updates are not needed.    
  
8.31 2007-02-07 Jeff Jaeger  
 - added a delete to #PRsRun after the "Overlap" update.  If two events have the same starttime, the   
  overlap update will reassign the endtime of the shorter event to the starttime shared by the two   
  events.  downstream in the sp, this will begin to cause problems.    
  
8.32 2007-02-07 Jeff Jaeger  
 - added InitEndtime to #PRsRun.  
 - modified the insert to #PRsRun to populate InitEndtime instead of Endtime.  
 - modified the insert to #PRsRun to not restrict by event status when selecting the InitEndtime and EndStatus.  
 - modified the overlap update to #PRsRun again.  
  
8.33 2007-02-22 Jeff Jaeger  
 - updated the definitions of @SQL3EventHistoryBeforeReportWindow and @SQL3EventsBeforeReportWindow.  
  the purpose is to capture the most recent event prior to the start of the report window with a status   
  of "Running", for each pu, provided the event has no completion status (Complete, Partially-Run, or Reject)   
  that occurs prior to the start of the report window.  as originally written, the code would only check to   
  see if the most recent event for each pu, prior to the report window, had a status of "Running".  
  
8.34 2007-02-27 Jeff Jaeger  
 -  removed PMProdDesc and PMTeam from the list of SplitDowntime fields being update based on   
  a join by PRSEventID.  this is because updating those fields here would overwrite the   
  intended split in downtime events based on changes in those fields.  
 - added the SplitDowntime update to PM, PMProdDesc, and PMTeam based for ELP related events.  
  
8.35 2007-03-27 Jeff Jaeger  
 -- to find these changes, search for "Rev8.35".  
 ---- changes by Vince King, summarized by Jeff Jaeger  
 - added "Input_Order ASC," to the subquery order by clause when assigning PRSEventID in #SplitDowntimes,  
  to get PRsRun and Delays association to match  what is in CvtgELP.  
 - moved population of PRSEventID from #SplitDowntimes to #Delays, just prior to splitting the events.    
 - assignment of PRSEventID in #SplitDowntimes now comes from #Delays when splitting events.  
 ---- changes by Jeff Jaeger  
 -- the code to retain PM, PMProdDesc, and PMTeam across split events was not adequate.  These changes address it.  
 - added PM and PMTeam to #Delays.  
 - moved the population of PM, PMProdDesc, and PMTeam to an update of #Delays prior to splitting events.  
 - PM, PMProdDesc, and PMTeam in #SplitDowntimes now come from #Delays when splitting events.  
  
8.36 2007-04-05 Jeff Jaeger  
 - removed the "distinct" from the insert to @ELPDelays.  
 - changed the join to event_reasons in @ELPDelays to a Left Join  
  
8.37 2007-04-06 Jeff Jaeger  
 - imported changes that Langdon Davis made for Cvtg ELP:  
 - updated the insert to #PRsRun.  NOTE that fields in this table are not exactly the same between the two reports.  
 - changed all checks that use var_desc in Variables to use GlblDesc in the extended_info field.  
 - found that parsing GlblDesc from extended_info is very inefficient.  updated the code to use   
  a [VarID field in the #ProdLines table] approach to finding variables.  this then requires a join to #ProdLines   
  and a check on the appropriate VarID rather than checking on Var_Desc or Extended_Info.  
  
8.38 2007-04-10 Jeff Jaeger  
 - added a coalesc on updates to @ELPSummary updates that use a subquery to assign a value to a field.  
  this was done because if the joins in the subquery didn't match up, a null would be assigned to the value,  
  and would cause some calcs to also be null when other elements of the calcs should allow a value to be   
  returned.  
  
8.39 2008-06-23 Langdon Davis (imported by Jeff Jaeger)  
  -  Commented out all code related to "NotPerfect" status and user limits as they are not used in the PPR   
   design anymore.  
  
8.40 2008-06-23 Jeff Jaeger  
 -  Removed @ELPDelays  
 -  Added @PRDTReasons and @PRDTProducts.  These could have been one table, but it was easier to   
  troubleshoot when the data was being compiled in reason related buckets and product related buckets.  
 -  Added @PRDTReasonMetrics and @PRDTProductMetrics.  These could have been one table, but it   
  was easier to troubleshoot when the data was being compiled in reason related buckets and product   
  related buckets.  
 -  Removed PEIID from @ELPReasonSums  
 -  Removed UWS and Cvtr related fields from @ELPSummary because they are not being used.  
 -  Removed TotalUWS from #prodlines because its not used anymore.  
 -  Added the @MinEventID variable and the temp table #EventHist and made changes to the population of   
  #Events in order to optimize the population of #Events  
 -  Updated the population of #PRsRun, including the use of @NoRunningStatusTime  
 -  Removed PMProdDesc, Parent, GrandParent, PerfectPRStatus, PerfectPRStatus, Fresh, and PMTeam from   
  #delays because those fields are specific to paper events and we are no longer associating downtime   
  events with one specific paper event.  
 -  Added L2ReasonName to #delays  
 -  Removed @PrimaryUWS, @PMChanges, @PMProdChanges, @PMTeamChanges, @UWS, #Dimensions, #TimeSlices,   
  and #SplitDowntimes because they are no longer used.   
  
8.41 2008-07-08 Jeff Jaeger  
- converted @PRDTReasons to a temp table and added a nonclustered index to make the sp more efficient.  
- converted @PRDTProducts to a temp table and added a nonclustered index to make the sp more efficient.  
  
2008-07-22 Jeff Jaeger  Rev8.42  
- Removed #EventHist  
- Updated the structure of #Events to add start_time and end_time as well as remove Entry_On  
- Added @RunningStatusID code.  
- Updated the insert to #Events to use Event_Status_Transitions.  
- Updated the initial insert to #PRsRun due to changes in how #Events is populated.  
- Removed the insert to #PRsRun for completion status events.  
- Removed the use of @NoRunningStatusTime and related code.  
- Added an adjustment to prs.EndTime after the initial insert to #PRsRun and again after all inserts to #PRsRun.  
- Added a 3rd update for flavors of starttime and endtime in #PRsRun that are based on grouping criteria.  
- Updated the insert of metrics so that where ReportDowntime was being used, the actual Downtime is now used.    
 This is the  correct way to calculate downtime as applied to ELP.  
- Added tables for summing metrics grouped by Line.  
  
2008-08-20 Jeff Jaeger  Rev8.43  
- updated the index to #Events so it is a clustered index instead of a primary.  
- added the temp table #EventStatusTransitions and made it the data source for the insert to #PRsRun.  
- removed the id comparison in the secondary update to flavors of start time and end time where the   
 datediffs are compared.    
  
2008-09-23 Jeff Jaeger Rev8.44  
- added an additional update to PEIID for #PRsRun.  This is used for facial line FFF1, which has a different   
 configuration than the other lines.  
  
2008-10-08 Jeff Jaeger Rev8.45  
- (this comment updated on 2008-10-22 to reflect the work that was actually done, not the work that was   
 originally intended to be done...)  
- removed UWS1Parent, UWS1GrandParent, UWS1PMProdDesc, and UWS1PMTeam (and the code to populate them)   
 from #delays since they don't appear to be used.  
- updated the assignment of GrandParentPRID to use VarInputRollVN and VarInputPRIDVN.  
  
2008-10-10 Jeff Jaeger Rev8.46  
- Added an update on #Delays to automatically fill in the Schedule ID as Blocked/Starved if it is null [means  
 the reason level 2 was not filled out or there is no event reason category association to a 'Schedule'    
 event reason category] AND if reason level 1 contains the word 'BLOCK' or 'STARVE'.  
  
2008-10-21 Jeff Jaeger Rev8.47  
- modified the Facial FFF1 special special update to PEIID in #PRsRun so that it only runs if the site   
 executing the code is GB... this will need to be added to all of the reports.  
- added L1ReasonID to #delays, along with the code to populate it.  this will allow the Blocked/Starved   
 related update to ScheduleID in #delays to operate as intended.  
- removed the use of @CatBlockStarvedId in this report.  
- updated the comment for 2008-10-08.  while duplicating work in this report that was developed elsewhere,   
 I noted that @PRDTOutsideWindow did not need to be included here.  in fact, the fields in #delays that   
 are updated with that table are not used in this report.  however, after commenting them out, I failed   
 to change the comments that I had already inserted here.  Further, the assignment of GrandParentPRID uses   
 VarInputRollVN and VarInputPRIDVN, not VarInputRollID and VarInputRPRIDID.  although this would normally   
 be just a minor typo in the comments, they are all variables in the code and so I can see where this   
 distinction could possibly lead to some confusion.  
  
2008-11-11 Jeff Jaeger Rev8.48  
- Changed from using the “Var_Desc_Global” to get the variables that are used to populate Grand Parent PRID   
 in @PRsRun so that “GlblDesc=” is used instead.  The change was required because on FPRW the   
 “Var_Desc_Global” for these variables was set to NULL.  This has been fixed, but using "GlblDesc" is going   
 to be the standard approach with the next generation.  Also note that these variables all have the same   
 value for “GlblDesc=”.  
  
2008-12-01 Jeff Jaeger Rev8.49  
- changed #prodlines temp table to a table variable.  
  
2009-01-13 Jeff Jaeger Rev8.50  
- Added code for IncludeTeam = 2.    
- Split @ELPSumResults in @ELPSumResultsProduct and @ELPSumResultsTeam.  Modified the sp to populate both tables.  
- Split @Top5Causes into @Top5CausesProduct and @Top5CausesTeam.  Modified the sp to populate both tables.  
- Added the table #PRDTTeams and the code to populate it.  
- Removed some dead code.  
- Added “with (nolock)” to the use of temp tables.  
- Modified correlated updates to use aliases that are distinct within the relevant statement, even though they   
 might be in subqueries.  
- Modified updates to Groupby start and end times to make them more efficient.  
- Added “option (maxdop 1)” to updates of GroupBy start and end time.  
  
2009-01-15 Jeff Jaeger Rev8.51  
- added additional comments to make it easier to migrate recent changes into Next Generation.  
  
2009-02-16 Jeff Jaeger Rev8.52  
- modified the method for pulling ScheduleID, CategoryID, GroupCauseID, and SubsystemID in #delays.  
  
--2009-03-12 Jeff Jaeger Rev8.53  
--  - added z_obs restriction to the population of @produnits  
  
2009-09-02  Vince King Rev8.54  
 Added code when populating ProdLines table that captures VarParentPRIDId based on the variable name 'PRID'  
 when 'ParentPRID' does not exist.  This was put in place for the intermediate lines that only have a PRID variable.  
  
*/  
  
  
CREATE PROCEDURE [dbo].[spLocal_RptPmkgDDSELP]  
-- declare  
 @Report_Start_Time  datetime,  -- Beginning period for the data.  
 @Report_End_Time   datetime,  -- Ending period for the data.  
 @Line_Name     varchar(50), -- Collection of Prod_Lines.PL_Id for converting lines delimited by "|".  
 @RptIncludeTeam   INTEGER,   -- 0 = Summary, 1 = Include Team.  
 @UserName     varchar(50)  
  
AS  
  
  
-- SELECT            
-- @Report_Start_Time = '2009-08-19 00:00:00 ',    
-- @Report_End_Time = '2009-08-20 00:00:00 ',   
-- @Line_Name = 'FP13', --'MP5M',   
-- @RptIncludeTeam = 0,   
-- @UserName = 'ComXClient'   
  
--SELECT  
--@Report_Start_Time = '2009-02-01 05:00:00',     
--@Report_End_Time = '2009-02-03 05:00:00',    
--@Line_Name = 'PC1X', -- 'FP10', -- 'GP06', -- 'AY1A', -- 'MP5M', --   
--@RptIncludeTeam = 1,  
--@UserName = 'ComXClient'    
  
--SELECT  
--@Report_Start_Time = '2009-01-05 05:00:00',     
--@Report_End_Time = '2009-01-06 05:00:00',    
--@Line_Name = 'PC1X', -- 'FP10', -- 'GP06', -- 'AY1A', -- 'MP5M', --   
--@RptIncludeTeam = 2,  
--@UserName = 'ComXClient'    
  
  
-------------------------------------------------------------------------------  
-- Control settings  
-------------------------------------------------------------------------------  
SET ANSI_WARNINGS OFF  
SET NOCOUNT ON       
  
-------------------------------------------------------------------------------  
-- Declare program variables.  
-------------------------------------------------------------------------------  
  
--print 'build tables' + ' ' + convert(varchar(25),current_timestamp,108)  
  
DECLARE @SearchString        varchar(4000),  
 @Position           int,  
 @PartialString          varchar(4000),  
 @Now             datetime,  
 @PUDelayTypeStr         varchar(100),  
 @VarEffDowntimeVN         varchar(50),  
 @VarStartTimeVN         varchar(50),  
 @VarEndTimeVN          varchar(50),  
 @VarPRIDVN           varchar(50),  
 @VarParentPRIDVN         varchar(50),  
-- @VarGrandParentPRIDVN       varchar(50),  
 @VarUnwindStandVN         varchar(50),  
 @VarPerfectPRStatusVN       varchar(50),    
  
 --Rev8.37  
 @VarInputRollVN         varchar(50),  
 @VarInputPRIDVN         varchar(50),  
  
 @PMPerfectPRStatusVN        VARCHAR(50),    
 @RateLossPUId          int,  
 @RangeStartTime         datetime,  
 @RangeEndTime          datetime,  
 @Max_TEDet_Id          int,  
 @Min_TEDet_Id          int,  
 @Row             int,  
 @Rows             int,  
 @@StartTime           datetime,  
 @VarPaperMachineID        int,  
 @VarPaperMachinePrid        varchar(50),  
 @VarPMPRIDId          INTEGER,      
 @@PUId            int,  
 @DelayTypeList          varchar(4000),    
 @ScheduleStr          varchar(50),    
 @CategoryStr          varchar(50),    
-- @CatBlockStarvedId        int,     
 @CatELPId           int,     
 @SchedPRPolyId          int,     
 @SchedUnscheduledId        int,     
 @SchedSpecialCausesId       int,     
 @SchedEOProjectsId        int,     
 @SchedBlockedStarvedId       int,     
 @DelayTypeRateLossStr       varchar(100),  
 @PMPerfectPRStatusId        INTEGER,  
 @TotalFreshRuntime        FLOAT,  
 @TotalStorageRuntime        FLOAT,  
  
 @LinkStr            varchar(100),  
 @VarPRIDId           int,  
 @VarParentPRIDId         int,  
  
 @NoRunningStatusTime        datetime,  
  
 @RunningStatusID          int  
  
  
------------------------------------------------------------------------  
-- Declare table variables  
------------------------------------------------------------------------  
  
DECLARE @ProdLinesGP TABLE (  
 PLId       int PRIMARY KEY,  
 PLDesc      varchar(50),  
 VarEffDowntimeId   int,  
 ProdPUId      int,   
 ReliabilityPUID   int,  
 RatelossPUID    int,  
 RollsPUID     int,  
 VarStartTimeId    int,   
 VarEndTimeId    int,   
 VarPRIDId     int,  
 VarParentPRIDId   int,  
-- VarGrandParentPRIDId  int,  
 VarUnwindStandId   int,  
 VarPerfectPRStatusId  int,     
-- VarInputRollID    int,  
-- VarInputPRIDID    int,  
 VarPMPerfectPRStatusID int  
 )   
  
DECLARE @DelayTypes TABLE   
 (  
 DelayTypeDesc   varchar(100) PRIMARY KEY  
 )  
  
  
DECLARE @ProdUnits TABLE   
 (  
 PUId      int PRIMARY KEY,  
 PUDesc     varchar(100),  
 PLId      int,  
 DelayType    varchar(100),  
 ScheduleUnit   INTEGER--,  
 )  
  
DECLARE @PUsRunningPRs TABLE   
 (  
 PUId      INTEGER PRIMARY KEY,  
 PLId      INTEGER,   
 PUDesc     varchar(100)  
 )  --DIFF  
  
  
declare @PRDTReasonMetrics table  
 (  
  
 id_num             int,  
 PLID              int,  
 Product             varchar(100),  
 Team              VARCHAR(10),  
 Fresh              int,  
 Reason_Name            varchar(100),  
  
 Stops              int,  
 Minutes             float,  
 FreshPerfectELPMin         float,  
 FreshFlaggedELPMin         float,  
 FreshRejHoldELPMin         float,  
  
 Stops_FreshReasons         int,  
 Minutes_FreshReasons         float,  
 FreshPerfectELPMin_FreshReasons     float,  
 FreshFlaggedELPMin_FreshReasons     float,  
 FreshRejHoldELPMin_FreshReasons     float,  
 FreshOverallMin_FreshReasons      float,   
 StorageOverallMin_FreshReaons      float,  
  
 Stops_ProdTeamFreshReasons       int,  
 Minutes_ProdTeamFreshReasons      float,  
 FreshPerfectELPMin_ProdTeamFreshReasons  float,  
 FreshFlaggedELPMin_ProdTeamFreshReasons  float,  
 FreshRejHoldELPMin_ProdTeamFreshReasons  float--,  
  
 )  
  
  
declare @PRDTProductMetrics table  
 (  
  
 id_num             int,  
 PLID              int,  
 Product             varchar(100),  
 Team              VARCHAR(10),  
 Fresh              int,  
 Reason_Name            varchar(100),  
  
 SchedMins_Product          float,  
 FreshStops_Product         int,  
 FreshMins_Product          float,  
 StorageStops_Product         int,  
 StorageMins_Product         float,  
 FreshPerfectELPMin_Product       float,  
 FreshFlaggedELPMin_Product       float,  
 FreshRejHoldELPMin_Product       float,  
 FreshSchedDT_Product         float,  
 StorageSchedDT_Product        float,  
 FreshRuntime_Product         float,  
 StorageRuntime_Product        float,  
 OverallRuntime_Product        float,  
 FreshPerfectRuntime_Product      float,  
 FreshFlaggedRuntime_Product      float,  
 FreshRejHoldRuntime_Product      float,  
 FreshPerfectSchedDT_Product      float,  
 FreshFlaggedSchedDT_Product      float,  
 FreshRejHoldSchedDT_Product      float,  
 TotalStops_Product         int,  
 TotalMins_Product          float,  
  
 SchedMins_ProductTeam        float,  
 FreshStops_ProductTeam        int,  
 FreshMins_ProductTeam        float,  
 StorageStops_ProductTeam       int,  
 StorageMins_ProductTeam        float,  
 FreshPerfectELPMin_ProductTeam     float,  
 FreshFlaggedELPMin_ProductTeam     float,  
 FreshRejHoldELPMin_ProductTeam     float,  
 FreshSchedDT_ProductTeam       float,  
 StorageSchedDT_ProductTeam       float,  
 FreshRuntime_ProductTeam       float,  
 StorageRuntime_ProductTeam       float,  
 OverallRuntime_ProductTeam       float,  
 FreshPerfectRuntime_ProductTeam     float,  
 FreshFlaggedRuntime_ProductTeam     float,  
 FreshRejHoldRuntime_ProductTeam     float,  
 FreshPerfectSchedDT_ProductTeam     float,  
 FreshFlaggedSchedDT_ProductTeam     float,  
 FreshRejHoldSchedDT_ProductTeam     float,  
 TotalStops_ProductTeam        int,  
 TotalMins_ProductTeam        float  
  
 )  
  
--Rev8.51  
declare @PRDTTeamMetrics table  
 (  
  
 id_num             int,  
 PLID              int,  
 Team              VARCHAR(10),  
 Fresh              int,  
 Reason_Name            varchar(100),  
  
 SchedMins_Team           float,  
 FreshStops_Team          int,  
 FreshMins_Team           float,  
 StorageStops_Team          int,  
 StorageMins_Team          float,  
 FreshPerfectELPMin_Team        float,  
 FreshFlaggedELPMin_Team        float,  
 FreshRejHoldELPMin_Team        float,  
 FreshSchedDT_Team          float,  
 StorageSchedDT_Team         float,  
 FreshRuntime_Team          float,  
 StorageRuntime_Team         float,  
 OverallRuntime_Team         float,  
 FreshPerfectRuntime_Team       float,  
 FreshFlaggedRuntime_Team       float,  
 FreshRejHoldRuntime_Team       float,  
 FreshPerfectSchedDT_Team       float,  
 FreshFlaggedSchedDT_Team       float,  
 FreshRejHoldSchedDT_Team       float,  
 TotalStops_Team          int,  
 TotalMins_Team           float  
  
 )  
  
  
declare @PRDTLineMetrics table  
 (  
  
 id_num             int,  
 PLID              int,  
 prPLID             int,  
 Fresh              int,  
 Reason_Name            varchar(100),  
 SchedMins_Line           float,  
 FreshStops_Line          int,  
 FreshMins_Line           float,  
 StorageStops_Line          int,  
 StorageMins_Line          float,  
 FreshPerfectELPMin_Line        float,  
 FreshFlaggedELPMin_Line        float,  
 FreshRejHoldELPMin_Line        float,  
 FreshSchedDT_Line          float,  
 StorageSchedDT_Line         float,  
 FreshRuntime_Line          float,  
 StorageRuntime_Line         float,  
 OverallRuntime_Line         float,  
 FreshPerfectRuntime_Line       float,  
 FreshFlaggedRuntime_Line       float,  
 FreshRejHoldRuntime_Line       float,  
 FreshPerfectSchedDT_Line       float,  
 FreshFlaggedSchedDT_Line       float,  
 FreshRejHoldSchedDT_Line       float,  
 TotalStops_Line          int,  
 TotalMins_Line           float  
  
 )  
  
  
DECLARE @ELPReasonSums TABLE   
 (  
 Product      varchar(100),  
 Team       VARCHAR(10),     
 Fresh       int,  
 Reason_Name     varchar(100),  
 Stops       int,  
 Minutes      float,  
 FreshPerfectELPMin  float,     
 FreshFlaggedELPMin  float,     
 FreshRejHoldELPMin  float--,     
 )  
  
  
DECLARE @ELPSummary TABLE   
 (  
 Product      varchar(100),   
 Team       VARCHAR(10),   
 FreshStops     int,  
 FreshMins     float,  
 StorageStops    int,  
 StorageMins     float,  
 TotalStops     int,  
 TotalMins     float,  
 SchedMins     FLOAT,     
 FreshSchedDT    FLOAT,   
 StorageSchedDT    FLOAT,    
 FreshRuntime    FLOAT,    
 StorageRuntime    FLOAT,    
 OverallRuntime    FLOAT,    
 FreshPerfectELP   float,   
 FreshFlaggedELP   float,    
 FreshRejHoldELP   float,     
 FreshPerfectELPMin  FLOAT,     
 FreshFlaggedELPMin  FLOAT,     
 FreshRejHoldELPMin  FLOAT,     
 FreshPerfectRuntime  FLOAT,     
 FreshFlaggedRuntime  FLOAT,     
 FreshRejHoldRuntime  FLOAT,     
 FreshPerfectSchedDT  FLOAT,     
 FreshFlaggedSchedDT  FLOAT,     
 FreshRejHoldSchedDT  FLOAT,     
 FreshOverallELP   float,     
 StorageOverallELP   float,     
 OverallELP     float  
)  
  
DECLARE @PerfectPRVars TABLE   
 (  
 VarId     INTEGER,  
 VarDesc    VARCHAR(100),  
 PUId     INTEGER  
 PRIMARY KEY (PUId, varid)   
 )  
  
  
--Rev8.51  
DECLARE @ELPSumResultsProduct TABLE   
 (  
 SortOrder INTEGER,  
 Product  VARCHAR(100),  
 RowHdr  VARCHAR(20),  
 Fresh   VARCHAR(20),  
 Storage  VARCHAR(20)  
 )  
  
--Rev8.51  
DECLARE @ELPSumResultsTeam TABLE   
 (  
 SortOrder INTEGER,  
 Team   VARCHAR(100),  
 RowHdr  VARCHAR(20),  
 Fresh   VARCHAR(20),  
 Storage  VARCHAR(20)  
 )  
  
--Rev8.51  
DECLARE @Top5CausesProduct TABLE   
 (  
 Product    VARCHAR(100),  
 Cause     VARCHAR(100),   
 TestedRolls   INTEGER,  
 TotalFailures  INTEGER,     
 FlaggedRolls  INTEGER,  
 RejHoldRolls  INTEGER  
 )    
  
--Rev8.51  
DECLARE @Top5CausesTeam TABLE   
 (  
 Team     VARCHAR(100),  
 Cause     VARCHAR(100),   
 TestedRolls   INTEGER,  
 TotalFailures  INTEGER,     
 FlaggedRolls  INTEGER,  
 RejHoldRolls  INTEGER  
 )    
  
DECLARE @ErrorMessages TABLE (  
 ErrMsg    varchar(255) )  
  
  
/* Intermediate Rolls Units Record Set */   
DECLARE @IntUnits TABLE  
 (  
 puid int primary key  
 )  
  
  
-- 2006-11-10 VMK Rev8.16, commented out until UWS Reliability units configuration corrected.  
-- ---------------------------------------------------------------------------------------  
-- -- 2006-11-09 VMK Rev8.16, added @UWS table back in. It is used to determine Runtime  
-- --         for Facial lines by using the UWS Reliability DT events  
-- --         to determine Running / Not Running status for UWSs.  
-- ---------------------------------------------------------------------------------------   
-- 2007-01-08 JSJ Rev8.24 uncommented  
 DECLARE @UWS TABLE ( PEIId  INTEGER PRIMARY KEY,   
     InputName   VARCHAR(50),    
 --    InputOrder   INTEGER,     
     PLId     INTEGER,  
     MasterPUId   INTEGER,  
     UWSPUId    INTEGER,  
     PPPUId    INTEGER,  
     RelPUDesc   VARCHAR(50) )  
  
  
 declare @PEI table  
  (  
  pu_id   int,  
  pei_id  int,  
  Input_Order int,  
  Input_name varchar(50)  
  primary key (pu_id,input_name)  
  )  
  
  
--Rev8.51  
DECLARE @ProdLines TABLE   
--create table dbo.#ProdLines  -- 2007-01-08 JSJ Rev8.24  
 (  
 PLId       int PRIMARY KEY,  
 PLDesc      varchar(50),  
 VarEffDowntimeId   int,  
 ProdPUId      int,   
 ReliabilityPUID   int,  
 RatelossPUID    int,  
 RollsPUID     int,  
 VarStartTimeId    int,   
 VarEndTimeId    int,   
 VarPRIDId     int,  
 VarParentPRIDId   int,  
-- VarGrandParentPRIDId  int,  
 VarUnwindStandId   int,  
 VarPerfectPRStatusId  int,  
-- VarInputRollID    int,  
-- VarInputPRIDID    int,  
 VarPMPerfectPRStatusID int,  
 TotalUWS      INTEGER,   
 MinEventID     int--,  
 )   
  
  
-------------------------------------------------------------------------------  
-- Create temp tables  
-------------------------------------------------------------------------------  
  
create table dbo.#PRDTReasons   
 (  
 id_num           int primary key identity ,  
 PRs_IDNum          int,  
 puid            int,  
 plid            int,  
 Product           varchar(100),  
 Team            VARCHAR(10),  
 Fresh            int,  
 Reason_Name          varchar(100),  
 [PerfectPRStatus]        varchar(50),      
   [StartTime]          datetime,  
   [EndTime]          datetime,  
   [StartTime_FreshReasons]     datetime,  
   [EndTime_FreshReasons]      datetime,  
   [StartTime_ProdTeamFreshReasons]   datetime,  
   [EndTime_ProdTeamFreshReasons]   datetime--,  
 )  
  
CREATE nonCLUSTERED INDEX td_PUId_StartTime  
ON dbo.#PRDTReasons (PlId, StartTime, EndTime, Reason_Name, fresh, product, team)  
  
  
create table dbo.#PRDTProducts   
 (  
 id_num           int primary key identity ,  
 PRs_IDNum          int,  
 puid            int,  
 plid            int,  
 reliabilitypuid        int,  
 Product           varchar(100),  
 Team            VARCHAR(10),  
 Fresh            int,  
 [PerfectPRStatus]        varchar(50),      
   [StartTime]          datetime,  
   [EndTime]          datetime,  
   [StartTime_Product]       datetime,  
   [EndTime_Product]        datetime,  
   [StartTime_ProductTeam]      datetime,  
   [EndTime_ProductTeam]      datetime,  
 [Runtime_Product]        float,  
 [Runtime_ProductTeam]      float  
 )  
  
CREATE nonCLUSTERED INDEX td_PUId_StartTime  
ON dbo.#PRDTProducts (PlId, StartTime, EndTime, Product, id_num)  
  
  
--Rev8.51  
create table dbo.#PRDTTeams   
 (  
 id_num           int primary key identity ,  
 PRs_IDNum          int,  
 puid            int,  
 plid            int,  
 reliabilitypuid        int,  
 Team            VARCHAR(10),  
 Fresh            int,  
 [PerfectPRStatus]        varchar(50),      
   [StartTime]          datetime,  
   [EndTime]          datetime,  
   [StartTime_Team]        datetime,  
   [EndTime_Team]         datetime,  
 [Runtime_Team]         float  
 )  
  
CREATE nonCLUSTERED INDEX td_PUId_StartTime  
ON dbo.#PRDTTeams (PlId, StartTime, EndTime, Team, id_num)  
  
  
create table dbo.#PRDTLine   
 (  
 id_num           int primary key identity ,  
 PRs_IDNum          int,  
 puid            int,  
 plid            int,  
 prplid           int,  
 reliabilitypuid        int,  
 Fresh            int,  
 [PerfectPRStatus]        varchar(50),      
   [StartTime]          datetime,  
   [EndTime]          datetime,  
   [StartTime_Line]        datetime,  
   [EndTime_Line]         datetime,  
 [Runtime_Line]         float  
 )  
  
CREATE nonCLUSTERED INDEX td_PUId_StartTime  
ON dbo.#PRDTLine (PlId, StartTime, EndTime, id_num)  
  
  
create table dbo.#PRsRun   
 (   
 [ID_num]                    int primary key CLUSTERED identity ,  
 [EventID]       int,  
 [PLID]        int,  
 [PUID]        int,      
   [PUDesc]        varchar(100),  
 [PEIID]        int,  
 [Input_Order]      int,  
   [ULID]        varchar(100),  
   [GrandParentULID]     varchar(100),  
   [StartTime]       datetime,  
   [EndTime]       datetime,  
   [InitEndTime]      datetime, -- Rev8.32  
 [StartStatus]      varchar(50),  
 [EndStatus]       varchar(50),  
 [Runtime]       float,         
 [AgeOfPR]       float,  
 [Fresh]        int,  
   [ParentPRID]      varchar(25),  
   [GrandParentPRID]     varchar(25),  
 [Parent]        varchar(25),  
 [GrandParent]      varchar(25),  
   [PRPUID]        int,  
   [PRPLID]        int,  
   [ParentType]      int,  --2=intermediate and 1=Papermachine  
   [GrandParentPUID]     int,  
   [UWSRunning]      varchar(25),  
 [PerfectPRStatus]     varchar(50),      
 [EventTimestamp]     datetime,  
   [PMTimeStamp]      datetime,  
   [GrandParentTimeStamp]   datetime,  
 [PMEventId]       INTEGER,        
 [PMProdDesc]      VARCHAR(100),      
 [Team]        VARCHAR(5),  
 [PaperLineStatus]     varchar(50),  
 EHEntryON       datetime,  
 VarPMPerfectPRStatusId   int,  
 DevComment       varchar(100)--,  
 )  
  
  
create table dbo.#PerfectPRTests  
 (  
 VarId     INTEGER,  
 VarDesc    VARCHAR(100),  
 ResultOn    DATETIME,  
 Result    VARCHAR(50),  
 UpperWarning  VARCHAR(50),  
 LowerWarning  VARCHAR(50),  
 UpperReject   VARCHAR(50),  
 LowerReject   VARCHAR(50),  
 Flagged    INTEGER,  
 RejectHold   INTEGER,  
 ProdId    INTEGER,  
 ProdCode    VARCHAR(100),  
 Tested    INTEGER  
 )  
  
  
-- NOTE!!!!!!  
-- changed the idices on this table, and it runs a little faster!  
  
CREATE TABLE dbo.#Delays (  
 TEDetId    int PRIMARY KEY NONCLUSTERED,  
 PrimaryId   int,  
 PLID     int,  
 PUId     int,  
 source    int,--  
 PUDesc    varchar(100),  
 DelayType   varchar(25), --DIFF --  
 StartTime   datetime,  
 EndTime    datetime,  
 L1ReasonId   int,--  
 L2ReasonId   int,--  
 L2ReasonName  varchar(100),  
 ERTD_ID    int,  
 ScheduleId   int,  
 CategoryId   int,  
 Downtime    float,  
 ReportDownTime  float,  
 Stops     int,  
 StopsRateLoss  int,  
 ReportRLDowntime float,  
 RatelossRatio  float,  
 Team     VARCHAR(10)--,  
-- UWS1Parent   varchar(50), --  
-- UWS1GrandParent varchar(50), --  
-- UWS1PMProdDesc   varchar(100),  
-- UWS1PMTeam    varchar(10)  
)  
  
CREATE CLUSTERED INDEX td_PUId_StartTime  
ON dbo.#Delays (PUId, StartTime)  
  
  
CREATE TABLE dbo.#TECategories   
 (  
 TEC_Id  int PRIMARY KEY NONCLUSTERED IDENTITY,  
 TEDet_Id  int,  
 ERC_Id  int  
 )  
  
CREATE CLUSTERED INDEX tec_TEDetId_ERCId  
ON dbo.#TECategories (TEDet_Id, ERC_Id)  
  
  
create table dbo.#events   
 (  
 event_id     int, -- primary key,  
 source_event   int,  
 pu_id      int,  
 start_time    datetime,  
 end_time     datetime,  
 timestamp    datetime,  
 event_status   int,  
 status_desc    varchar(50),  
 event_num    varchar(50),  
 DevComment    varchar(300)  
-- primary key (Event_id, Start_Time)  
 )  
  
CREATE CLUSTERED INDEX events_eventid_StartTime  
ON dbo.#events (event_id, start_time)   
  
  
-- can we use this table more generally throughout the sp,   
-- so we don't have to keep hitting the real table?  
create table dbo.#tests   
 (  
 result_on   datetime,  
 result    varchar(100),  
 var_id    int  
 )  
  
CREATE nonCLUSTERED INDEX t_varid_resulton  
ON dbo.#tests (var_id,result_on)  
  
  
create table dbo.#ltec  
 (  
 TEDet_ID  int,  
 ERC_ID  int  
 )  
  
CREATE CLUSTERED INDEX ltec_tedetid_ercid  
ON dbo.#ltec (TEDet_ID,ERC_ID)  
  
  
create table dbo.#EventStatusTransitions  
 (  
 Event_ID   int,  
 Start_Time  datetime,  
 End_Time   datetime,  
 Event_Status int  
 )  
  
CREATE CLUSTERED INDEX est_eventid_starttime  
ON dbo.#EventStatusTransitions (event_id, start_time)  
  
  
-------------------------------------------------------------------------------  
-- Check Input Parameters.  
-------------------------------------------------------------------------------  
IF isDate(@Report_Start_Time) <> 1  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
 VALUES ('@Report_Start_Time is not a Date.')  
 GOTO ReturnResultSets  
 END  
  
IF isDate(@Report_End_Time) <> 1  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
 VALUES ('@Report_End_Time is not a Date.')  
 GOTO ReturnResultSets  
 END  
  
-- If the endtime is in the future, set it to current day.  This prevent zero records from being --printed on report.  
IF @Report_End_Time > GetDate()  
 SELECT @Report_End_Time = CONVERT(VarChar(4),YEAR(GetDate())) + '-' + CONVERT(VarChar(2),MONTH(GetDate())) + '-' +   
     CONVERT(VarChar(2),DAY(GetDate())) + ' ' + CONVERT(VarChar(2),DATEPART(hh,@Report_End_Time)) + ':' +   
     CONVERT(VarChar(2),DATEPART(mi,@Report_End_Time))+ ':' + CONVERT(VarChar(2),DATEPART(ss,@Report_End_Time))  
 OPTION (KEEP PLAN)  
  
-------------------------------------------------------------------------------  
-- Constants  
-------------------------------------------------------------------------------  
SELECT   
 @Now        = GetDate(),  
 @PUDelayTypeStr    = 'DelayType=',  
 @VarEffDowntimeVN   = 'Effective Downtime',  
 @VarStartTimeVN   = 'Roll Conversion Start Date/Time',  
 @VarEndTimeVN    = 'Roll Conversion End Date/Time',  
 @VarPRIDVN     = 'PRID',  
 @VarParentPRIDVN   = 'Parent PRID',  
-- @VarGrandParentPRIDVN = 'Grand Parent PRID',  
 @VarUnwindStandVN   = 'Unwind Stand',  
 @VarPerfectPRStatusVN = 'Parent Perfect Parent Roll Status',     
  
 @VarInputRollVN   = 'Input Roll ID',  
 @VarInputPRIDVN   = 'Input PRID',  
  
 @PMPerfectPRStatusVN  = 'Perfect Parent Roll Status',       
 @ScheduleStr     = 'Schedule',   
 @CategoryStr     = 'Category',   
-- @CatBlockStarvedId  = (select ERC_ID from dbo.Event_Reason_Catagories with (nolock) where Erc_Desc = 'Category:Blocked/Starved'),  
 @CatELPId     = (select ERC_ID from dbo.Event_Reason_Catagories with (nolock) where Erc_Desc = 'Category:Paper (ELP)'),  
 @SchedPRPolyId    = (select ERC_ID from dbo.Event_Reason_Catagories with (nolock) where Erc_Desc = 'Schedule:PR/Poly Change'),  
 @SchedUnscheduledId  = (select ERC_ID from dbo.Event_Reason_Catagories with (nolock) where Erc_Desc = 'Schedule:Unscheduled'),  
 @SchedSpecialCausesId = (select ERC_ID from dbo.Event_Reason_Catagories with (nolock) where Erc_Desc = 'Schedule:Special Causes'),  
 @SchedEOProjectsId  = (select ERC_ID from dbo.Event_Reason_Catagories with (nolock) where Erc_Desc = 'Schedule:E.O./Projects'),  
 @SchedBlockedStarvedId = (select ERC_ID from dbo.Event_Reason_Catagories with (nolock) where Erc_Desc = 'Schedule:Blocked/Starved'),  
 @DelayTypeRateLossStr  = 'RateLoss',  
 @LinkStr      = 'RollsUnit='  
  
  
declare @PL_id as int   
SELECT @PL_Id = PL_Id  
From dbo.Prod_Lines with (nolock)  
Where PL_Desc = 'TT ' + ltrim(rtrim(@Line_Name))  
OPTION (KEEP PLAN)  
  
declare @Rolls_PU_ID as int  
SELECT @Rolls_PU_Id = PU_Id  
From dbo.Prod_Units with (nolock)  
Where PU_Desc = @Line_Name + ' Rolls'  
OPTION (KEEP PLAN)  
  
select @VarPaperMachineID =  coalesce(  
--    GBDB.dbo.fnLocal_GlblGetVarId(@Rolls_PU_ID, @VarGrandParentPRIDVN),  
    GBDB.dbo.fnLocal_GlblGetVarId(@Rolls_PU_ID, @VarParentPRIDVN),  
    GBDB.dbo.fnLocal_GlblGetVarId(@Rolls_PU_ID, @VarPRIDVN)  
    )  
OPTION (KEEP PLAN)  
  
  
--Rev8.37  
select @VarPMPRIDID = GBDB.dbo.fnLocal_GlblGetVarId(@Rolls_PU_ID, @VarPRIDVN)  
  
select @VarPaperMachinePrid =   
    left((select top 1 result   
    from dbo.tests t with (nolock)  
    where var_id = @VarPaperMachineID  
    and result_on between @report_start_time and @report_end_time  
    order by result_on desc),2)  
OPTION (KEEP PLAN)  
  
set @PMPerfectPRStatusId = GBDB.dbo.fnLocal_GlblGetVarId(@Rolls_PU_ID, @PMPerfectPRStatusVN)  
  
  
Insert into @ProdLines  
 (  
 PLID,  
 PLDesc,  
 VarEffDowntimeID,  
 ProdPUID,  
 ReliabilityPUID,  
 VarStartTimeID,  
 VarEndTimeID,  
 VarPRidID,  
 VarParentPRidID,  
-- VarGrandParentPRidID,  
 VarUnwindStandID,  
 VarPerfectPRStatusId,  
-- VarInputRollID,  
-- VarInputPRIDID,  
 VarPMPerfectPRStatusID  
 )  
Select distinct  
 ppu.pl_id,  
 pl.pl_desc,  
 GBDB.dbo.fnLocal_GlblGetVarId(  
 (  
 select pu_id from dbo.prod_units tpu with (nolock)   
 where tpu.pl_id = ppu.pl_id and pu_desc like '%rate loss%'  
 ),   
 @VarEffDowntimeVN),  
 ppu.PU_Id,  
 (  
 select pu_id   
 from prod_units tpu with (nolock)   
 where tpu.pl_id = ppu.pl_id   
 and (tpu.PU_Desc LIKE '%Converter Reliability' OR tpu.PU_Desc LIKE '%INTR Reliability')  
 ) [ReliabilityPUId],   
 GBDB.dbo.fnLocal_GlblGetVarId(ppu.PU_Id, @VarStartTimeVN),  
 GBDB.dbo.fnLocal_GlblGetVarId(ppu.PU_Id, @VarEndTimeVN),  
 GBDB.dbo.fnLocal_GlblGetVarId(@Rolls_PU_ID, @VarPRIDVN),  
 -- 2009-09-02 VMK Rev8.54 Added coalesce to capture PRID for intermediate lines with variable name 'PRID'.  
 COALESCE(GBDB.dbo.fnLocal_GlblGetVarId(ppu.pu_id, @VarParentPRIDVN), GBDB.dbo.fnLocal_GlblGetVarId(ppu.PU_Id, @VarPRIDVN)),  
-- GBDB.dbo.fnLocal_GlblGetVarId(ppu.pu_id, @VarGrandParentPRIDVN),  
 GBDB.dbo.fnLocal_GlblGetVarId(ppu.pu_id, @VarUnwindStandVN),  
 GBDB.dbo.fnLocal_GlblGetVarId(ppu.pu_id, @VarPerfectPRStatusVN),  
  
-- GBDB.dbo.fnLocal_GlblGetVarId(@Rolls_PU_ID, @VarInputRollVN),  
-- GBDB.dbo.fnLocal_GlblGetVarId(@Rolls_PU_ID, @VarInputPRIDVN),    
 GBDB.dbo.fnLocal_GlblGetVarId(@Rolls_PU_ID, @PMPerfectPRStatusVN)    
  
From dbo.PrdExec_Input_Sources peis with (nolock)  
Join dbo.PrdExec_Inputs pei with (nolock)  
On pei.PEI_Id = peis.PEI_Id  
Join dbo.Prod_Units ppu with (nolock)  
On ppu.PU_Id = pei.PU_Id  
join dbo.prod_lines pl with (nolock)  
on pl.pl_id = ppu.pl_id  
Where peis.PU_Id = @Rolls_PU_Id  
OPTION (KEEP PLAN)  
  
-- Search again for production lines that are running paper from any of the  
-- previously select prod lines.  This will pick up converting lines running  
-- paper from intermediates that run paper from the selected Paper Machine.  
Insert into @ProdLinesGP      
 (  
 PLID,  
 PLDesc,  
 VarEffDowntimeID,  
 ProdPUID,  
 ReliabilityPUID,  
 VarStartTimeID,  
 VarEndTimeID,  
 VarPRidID,  
 VarParentPRidID,  
-- VarGrandParentPRidID,  
 VarUnwindStandID,  
 VarPerfectPRStatusId,  
-- VarInputRollID,  
-- VarInputPRIDID,  
 VarPMPerfectPRStatusID  
 )  
Select distinct  
 ppu.pl_id [PLId],  
 ppl.PL_Desc [PLDesc],    --pl.pldesc [PLDesc],            -- 2006-10-11 VMK Rev8.15, changed to ppl.PL_Desc  
 GBDB.dbo.fnLocal_GlblGetVarId(  
 (select pu_id from dbo.prod_units with (nolock) where pl_id = ppu.pl_id and pu_desc like '%rate loss%'),   
 @VarEffDowntimeVN) [VarEffDowntimeID],  
 ppu.PU_Id [ProdPUId],  
 -- 2006-10-11 VMK Rev8.15, modified below to pull Converter Reliability Unit.  
 (  
 select pu_id   
 from prod_units tpu with (nolock)   
 where tpu.pl_id = ppu.pl_id   
 and (tpu.PU_Desc LIKE '%Converter Reliability' OR tpu.PU_Desc LIKE '%INTR Reliability')  
 ) [ReliabilityPUId],   
 GBDB.dbo.fnLocal_GlblGetVarId(ppu.PU_Id, @VarStartTimeVN) [VarStartTimeId],  
 GBDB.dbo.fnLocal_GlblGetVarId(ppu.PU_Id, @VarEndTimeVN) [VarEndTimeId],  
 GBDB.dbo.fnLocal_GlblGetVarId(@Rolls_PU_ID, @VarPRIDVN) [VarPRIDId],  
 GBDB.dbo.fnLocal_GlblGetVarId(ppu.pu_id, @VarParentPRIDVN) [VarParentPRIDId],  
-- GBDB.dbo.fnLocal_GlblGetVarId(ppu.pu_id, @VarGrandParentPRIDVN) [VarGrandParentPRIDId],  
 GBDB.dbo.fnLocal_GlblGetVarId(ppu.pu_id, @VarUnwindStandVN) [VarUnwindStandId],  
 GBDB.dbo.fnLocal_GlblGetVarId(ppu.pu_id, @VarPerfectPRStatusVN) [VarPerfectPRStatusId],  
  
-- GBDB.dbo.fnLocal_GlblGetVarId(@Rolls_PU_ID, @VarInputRollVN),  
-- GBDB.dbo.fnLocal_GlblGetVarId(@Rolls_PU_ID, @VarInputPRIDVN),    
 GBDB.dbo.fnLocal_GlblGetVarId(@Rolls_PU_ID, @PMPerfectPRStatusVN)    
  
From @ProdLines pl   
Join dbo.PrdExec_Input_Sources peis  with (nolock)  
ON peis.PU_Id =   
 (  
 SELECT PU_Id   
 FROM dbo.Prod_Units pu with (nolock)   
 WHERE pu.PL_Id = pl.PLId   
 AND pu.PU_Desc LIKE '%Rolls%'  
 )  
Join dbo.PrdExec_Inputs pei with (nolock)  
On pei.PEI_Id = peis.PEI_Id  
Join dbo.Prod_Units ppu with (nolock) On ppu.PU_Id = pei.PU_Id  
JOIN dbo.Prod_Lines ppl with (nolock) on ppu.PL_Id = ppl.PL_Id   
WHERE COALESCE(GBDB.dbo.fnLocal_GlblGetVarId(ppu.pu_id, @VarPRIDVN), GBDB.dbo.fnLocal_GlblGetVarId(ppu.pu_id, @VarParentPRIDVN)) IS NOT NULL  
--AND GBDB.dbo.fnLocal_GlblGetVarId(ppu.pu_id, @VarGrandParentPRIDVN) IS NOT NULL  
OPTION (KEEP PLAN)  
  
  
INSERT @ProdLines  
 (  
 PLId,  
 PLDesc,  
 VarEffDowntimeId,  
 ProdPUId,  
 VarStartTimeId,  
 VarEndTimeId,  
 VarPRIDId,  
 VarParentPRIDId,  
-- VarGrandParentPRIDId,  
 VarUnwindStandId,  
 VarPerfectPRStatusId,  
-- VarInputRollID,  
-- VarInputPRIDID,  
 VarPMPerfectPRStatusID  
 )   
SELECT    
 PLID,  
 PLDesc,  
 VarEffDowntimeID,  
 ProdPUID,  
 VarStartTimeID,  
 VarEndTimeID,  
 VarPRidID,  
 VarParentPRidID,  
-- VarGrandParentPRidID,  
 VarUnwindStandID,  
 VarPerfectPRStatusId,  
-- VarInputRollID,  
-- VarInputPRIDID,  
 VarPMPerfectPRStatusID  
  
FROM @ProdLinesGP plgp  
WHERE not exists (SELECT pl.PLId FROM @ProdLines pl WHERE pl.PLId = plgp.PLId)  
  
  
IF not exists (SELECT PLId FROM @ProdLines )   
 BEGIN  
 INSERT @ProdLines (PLId)  
 SELECT PL_Id  
 FROM dbo.Prod_Lines with (nolock)  
 END  
  
INSERT INTO @DelayTypes (DelayTypeDesc)   
   SELECT 'Downtime'  
INSERT INTO @DelayTypes (DelayTypeDesc)  
  SELECT 'CvtrDowntime'  
INSERT INTO @DelayTypes (DelayTypeDesc)  
  SELECT 'RateLoss'  
  
  
update pl set  
 RollsPUId = PU_Id  
From @prodlines pl   
join dbo.Prod_Units pu with (nolock)  
on pl.plid = pu.pl_id  
and PU_Desc like '% Rolls'  
  
update pl set  
 RatelossPUId = PU_Id  
From @prodlines pl   
join dbo.Prod_Units pu with (nolock)  
on pl.plid = pu.pl_id  
and PU_Desc like '%Rate%loss%'  
  
  
-------------------------------------------------------------------------------  
-- ProdUnitList  
-------------------------------------------------------------------------------  
INSERT @ProdUnits ( PUId,  
   PUDesc,  
   PLId,  
   DelayType   
   )  
SELECT   
 pu.PU_Id,  
 pu.PU_Desc,  
 pu.PL_Id,  
 GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, @PUDelayTypeStr)   
FROM dbo.Prod_Units pu with (nolock)  
 INNER JOIN @ProdLines tpl   
 ON pu.PL_Id = tpl.PLId  
 AND tpl.PLId > 0  
 INNER JOIN dbo.Event_Configuration ec with (nolock)  
 ON  pu.PU_Id = ec.PU_Id  
 INNER JOIN @DelayTypes dt ON dt.DelayTypeDesc = GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, @PUDelayTypeStr)   
WHERE pu.Master_Unit IS NULL  
AND  ec.ET_Id = 2  
and pu_desc not like '%z_obs%'  
OPTION (KEEP PLAN)  
  
  
/* fill @IntUnits */  
INSERT INTO @IntUnits  
 (  
 puid  
 )  
SELECT    
 pu.pu_id  
FROM dbo.prod_units pu with (nolock)  
WHERE pu.pu_id > 0   
and GBDB.dbo.fnlocal_GlblParseInfo(pu.extended_info,@LinkStr) is not null  
  
  
--print 'events' + ' ' + convert(varchar(25),current_timestamp,108)  
  
select @RunningStatusID = ps.prodstatus_id   
from dbo.Production_Status ps WITH(NOLOCK)   
where UPPER(ps.prodstatus_desc) = 'RUNNING'   
  
insert dbo.#EventStatusTransitions  
 (  
 Event_ID,  
 Start_Time,  
 End_Time,  
 Event_Status  
 )  
select  
 Event_ID,  
 Start_Time,  
 End_Time,  
 Event_Status  
from dbo.event_status_transitions est with(nolock)  
where est.event_status = @RunningStatusID  
and est.start_time < @report_end_time  
and (est.start_time < est.end_time or est.end_time is null)  
and (est.end_time > @report_start_time or est.end_time is null)  
  
  
INSERT dbo.#Events  
 (  
 event_id,  
 pu_id,  
 start_time,  
 end_time,  
 timestamp,       
 event_num,  
 DevComment  
 )  
select distinct  
 est.event_id,  
 e.pu_id,  
 est.start_time,  
 coalesce(est.end_time,@report_end_time),  
 e.timestamp,  
 e.event_num,  
 'Initial Load'  
--from dbo.event_status_transitions est  
from dbo.#EventStatusTransitions est with (nolock)  
join dbo.events e with(nolock)  
on est.event_id = e.event_id  
  
  
-- 2007-01-08 JSJ Rev8.24  
-- a simplified update statement  
update e set  
 source_event = coalesce(ec.source_event_id,e.event_id)  
from dbo.#events e with (nolock)  
LEFT JOIN dbo.event_components ec with (nolock)  
ON e.event_id = ec.event_id  
  
  
--print 'PRs Run' + ' ' + convert(varchar(25),current_timestamp,108)  
  
--Rev7.6  
INSERT INTO dbo.#PRsRun  
 (   
 [EventID],  
 [PLID],  
 [puid],  
 [PUDesc],  
 [ULID], --[EventNum],  
 [StartTime],  
 [InitEndTime],  
 [PerfectPRStatus],  
 [PMTimeStamp],  
 [PRPUID],  
 EventTimestamp,  
 [PMEventID],  
 [PMProdDesc],  
 DevComment    
 )  
SELECT distinct  
 e.event_id,  
 pu.pl_id,  
 pu.pu_id,  
 pu.pu_desc [PUDesc],  
 e.event_num,  
 CONVERT(DATETIME, CONVERT(VARCHAR(20), e.start_time, 120)) [StartTime],  
 CONVERT(DATETIME, CONVERT(VARCHAR(20), e.end_time, 120)) [EndTime],  
 ppr.Result,       
 CONVERT(DATETIME, CONVERT(VARCHAR(20), e1.timestamp, 120)) [PRIDTimeStamp],   
 e1.pu_id [PRPUID],  
 e.timestamp,  
 e.source_event [PMEventID],  
 (  
 select distinct p.Prod_Desc  
 FROM dbo.Production_Starts ps with (nolock)   
 JOIN dbo.Products p with (nolock)   
 ON ps.Prod_Id = p.Prod_Id  
 WHERE CONVERT(datetime, e1.TimeStamp) >= ps.Start_Time  
 AND (CONVERT(datetime, e1.TimeStamp) < ps.End_Time OR ps.End_Time IS NULL)  
 and @Rolls_PU_Id = ps.PU_Id  
 ),  
 'Initial Running Insert'    
-- events with Running status  
from dbo.#events e with (nolock)   
JOIN @ProdLines pl   
ON (e.PU_Id = pl.ProdPUId or e.pu_id = pl.ratelosspuid)  
JOIN dbo.prod_units pu with (nolock)   
ON pu.pu_id = e.pu_id   
-- source events  
JOIN dbo.events e1 with (nolock)  
ON e1.event_id = e.source_event  
and e1.pu_id = @Rolls_PU_ID   
-- Perfect Parent Roll status  
LEFT JOIN dbo.tests ppr with (nolock)  
on ppr.Var_Id = @PMPerfectPRStatusId  
and ppr.Result_On = e1.TimeStamp    
  
  
-- ALL  
delete dbo.#prsrun   
where endtime < @report_start_time  
  
update prs set  
 starttime = @report_start_time  
from dbo.#PRsRun prs with (nolock)  
where starttime < @report_start_time  
  
update prs set  
 endtime = @report_end_time  
from dbo.#PRsRun prs with (nolock)  
where endtime > @report_end_time  
  
  
update prs set  
 [ParentPRID] = UPPER(RTRIM(LTRIM(coalesce(tprid2.result,tprid.result)))),  
 [UWSRunning] = coalesce(tuws.result,'No UWS Assigned')  
from dbo.#prsrun prs with (nolock)  
join @prodlines pl  
on prs.puid = pl.prodpuid  
-- ParentPRID  
left JOIN dbo.Tests tprid with (nolock)  
on (tprid.Var_Id = pl.VarPRIDId and tprid.result_on = prs.EventTimeStamp)  
left JOIN dbo.Tests tprid2 with (nolock)  
on (tprid2.var_id = pl.VarParentPRIDId and tprid2.result_on = prs.EventTimeStamp)  
-- Unwind Stands   
left JOIN dbo.Tests tuws with (nolock)  
on tuws.Var_Id = pl.VarUnwindStandID   
and tuws.result_on = prs.EventTimeStamp  
  
update prs set  
 peiid = pei_id,  
 Input_Order = pei.Input_Order  
from dbo.#PRsRun prs with (nolock)  
join dbo.PrdExec_Inputs pei with (nolock)  
on pei.pu_id = prs.puid   
and pei.input_name = prs.uwsrunning  
  
  
-- Line FFF1 in Facial has a different configuration than other lines.  
-- This code will pull the correct PEIID and determine a unique   
-- input_order for parent rolls on this line.  
  
--Rev8.51  
if (select value from site_parameters where parm_id = 12) = 'Green Bay'  
begin   
  
if (  
 select count(*)  
 from @prodlines pl  
 where prodpuid = 1464  
 ) > 0  
  
begin  
  
 insert @PEI  
  (  
  pu_id,  
  pei_id,  
  Input_Order,  
  Input_name  
  )  
 select distinct  
  1464, --pu_id,  
  pei_id,  
  convert(int,ltrim(replace(input_name, 'UWS', ''))),  
  input_name    
 from dbo.PrdExec_Inputs pei  
 where (  
    pei.pu_id = 1465  
   or pei.pu_id = 1466  
   or pei.pu_id = 1467  
   or pei.pu_id = 1468  
   )  
  
 UPDATE prs SET   
  PEIId   = pei.pei_id,  
  Input_Order  = pei.input_order  
 FROM dbo.#prsrun prs with (nolock)   
 JOIN @pei pei  
 ON prs.puid = pei.pu_id  
 and pei.input_name = prs.UWSRunning  
 where prs.puid = 1464  
   
--Rev8.51  
end  
  
end  
  
DELETE dbo.#PRsRun  
WHERE PEIId IS NULL  
  
  
--print 'update running' + ' ' + convert(varchar(25),current_timestamp,108)  
  
/* update [PRID Running], [PRID PUID] and [PRID TimeStamp]if the ULID of dbo.#PRsRun has a - in it */  
update prs SET   
 [ParentPRID] = coalesce(t.result,'NoAssignedPRID'),   -- 2007-01-08 JSJ Rev8.24  
 [PMTimeStamp] = e.timestamp,  
 [PRPUID] = e.pu_id  
FROM dbo.#PRsRun prs with (nolock)   
join @prodlines pl   
on prs.plid = pl.plid  
LEFT JOIN dbo.events e with (nolock)   
ON e.event_num = left(prs.ulid,20)  
LEFT JOIN dbo.variables v with (nolock)   
ON v.pu_id = e.pu_id   
and v.var_id = pl.VarPRIDID  
LEFT JOIN dbo.tests t with (nolock)   
ON t.var_id = v.var_id   
and t.result_on = e.timestamp   
LEFT JOIN dbo.prod_units pu with (nolock)   
ON pu.pu_id = e.pu_id  
WHERE pu.pu_desc LIKE '% Rolls'   
and [ParentPRID] = 'NoAssignedPRID'  
  
  
--print 'parent type' + ' ' + convert(varchar(25),current_timestamp,108)  
  
/* update dbo.#PRsRun set [PRID ParentType] */  
update prs SET   
 [ParentType] =   
  CASE   
  WHEN prs.[PRPUID] = iu.puid   
  THEN 2  
          ELSE 1  
          END  
FROM dbo.#PRsRun prs with (nolock)  
LEFT JOIN @IntUnits iu   
ON iu.puid = prs.[PRPUID]  
  
  
--print 'grand prid' + ' ' + convert(varchar(25),current_timestamp,108)  
  
/* update [Grand ULID], [Grand PRID],[GPRID PUID] and [GPRID TimeStamp] */  
  
UPDATE prs SET   
 [GrandParentPRID] = t.result--,  
-- [GrandParentPM] = UPPER(RTRIM(LTRIM(LEFT(t.Result, 2))))--,  
FROM dbo.#prsrun prs with (nolock)   
LEFT JOIN dbo.tests t with (nolock)   
ON t.result_on = prs.[PMTimestamp]   
and prs.[ParentType] = 2  
LEFT JOIN dbo.variables v with (nolock)   
ON v.var_id = t.var_id   
and v.pu_id = prs.[PRPUID]   
where v.var_id = dbo.fnLocal_GlblGetVarId(prs.PRPUID, @VarInputRollVN)  
or v.var_id = dbo.fnLocal_GlblGetVarId(prs.PRPUID, @VarInputPRIDVN)  
  
  
update prs set  
 Team =   
 SUBSTRING(UPPER(RTRIM(LTRIM(coalesce(GrandParentPRID, ParentPRID, '')))), 3, 1)  
from dbo.#PRsRun prs with (nolock)  
where ParentPRID <> 'NoAssignedPRID'  
  
  
-----------------------------------------------------------------------------------------------  
-- Now clean up any overlap of PRs running in the @PRsRun table.  In some cases when a PR is   
-- rejected, the new PR is loaded and started running, then the previous PR is set to a status   
-- of rejected. This cause the previous PR endtime to be greater than the current PR starttime,   
-- thus causing an overlap.  Adjust those PRs to have the EndTime of the rejected roll equal  
-- the StartTime of the new roll.  
-----------------------------------------------------------------------------------------------  
  
-- 2007-02-07 JSJ Rev8.32  
-- to identify overlap adjustments, query the temp table for InitEndtime <> Endtime  
UPDATE prs1 SET   
 prs1.Endtime =   
  coalesce((  
  select top 1 prs2.Starttime  
  from dbo.#PRsRun prs2 with (nolock)  
  where prs1.PUId = prs2.PUId  
  and prs1.StartTime <= prs2.StartTime   
  and prs1.InitEndTime > prs2.StartTime  
  AND prs1.PEIId = prs2.PEIId  
  and prs1.eventid <> prs2.eventid  
  order by puid, starttime  
  ), prs1.InitEndtime)  
FROM dbo.#PRsRun prs1 with (nolock)  
  
-- 2007-02-07 JSJ Rev8.31  
delete dbo.#PRsRun  
where StartTime = EndTime   
  
--/*  
-------------------------------------------------------------------------------------------  
-- 2006-11-01 VMK Rev8.16, moved this code from below so that it is before the   
--      adjust endtimes code.  
-- This fills in any gaps between existing PR's.  
-------------------------------------------------------------------------------------------  
INSERT INTO dbo.#PRsRun  
 (   
 EventId,  
 PLID,         
 PUId,  
 PUDesc,  
 PEIID,  
 [Input_Order],  
 ULID,  
 StartTime,  
 EndTime,  
 AgeOfPR,  
 Fresh,  
 ParentPRID,   
 GrandParentPRID,   
 Parent,  
 GrandParent,  
 PRPUId,         
 UWSRunning,  
 PerfectPRStatus,      
 PMTimeStamp,       
 PMEventId,        
 PMProdDesc,        
 Team,  
 DevComment  
 )     
SELECT    
 NULL,  
 prs1.plid,  
 prs1.PUId,  
 prs1.PUDesc,  
 prs1.PEIID,  
 prs1.[Input_Order],    
 NULL,  
 prs1.EndTime,  
 prs2.StartTime,  
 NULL,  
 NULL,  
 'NoAssignedPRID',  
 'NoAssignedPRID',  
 'NoAssignedPRID',  
 'NoAssignedPRID',  
 -1, --prs1.PRPUId, -- 2007-01-08 JSJ Rev8.24  
 prs1.UWSRunning,   
 'NoAssignedPRID',  
 NULL,  
 NULL,  
 'NoAssignedPRID',      
 '', --prs1.Team, -- 2007-01-08 JSJ Rev8.24  
 'Gaps Between'  
FROM dbo.#PRsRun prs1 with (nolock)  
JOIN dbo.#PRsRun prs2 with (nolock)   
ON prs1.PUId = prs2.PUId  
AND prs1.PEIId = prs2.PEIId                -- 2006-04-18 VMK Rev7.20, added  
AND prs2.StartTime =   
 (  
 SELECT TOP 1 prs.StartTime   
 FROM dbo.#PRsRun prs with (nolock)  
 WHERE prs.StartTime >= prs1.EndTime         
 AND prs.PUId = prs1.PUId  
 AND prs.PEIId = prs1.PEIId          -- 2006-04-05 VMK Rev7.16, added  
 ORDER BY prs.StartTime ASC  
 )  
WHERE prs1.EndTime <> prs2.StartTime  
OPTION (KEEP PLAN)  
--*/  
  
-- ALL  
delete dbo.#prsrun   
where endtime < @report_start_time  
  
update prs set  
 starttime = @report_start_time  
from dbo.#prsrun prs with (nolock)  
where starttime < @report_start_time  
  
update prs set  
 endtime = @report_end_time  
from dbo.#prsrun prs with (nolock)  
where endtime > @report_end_time  
  
  
--print 'update age & fresh' + ' ' + convert(varchar(25),current_timestamp,108)  
  
-- update Runtime now that EndTimes have been adjusted.  
update prs SET   
 Runtime = DATEDIFF(ss,    
    CASE   
    WHEN StartTime < @report_start_time  
    THEN @report_start_time  
    ELSE StartTime  
    END,  
    CASE   
    WHEN EndTime > @report_end_time   
    THEN @report_end_time  
    ELSE EndTime  
    END  
   )/60.00,  
 AgeOfPR = datediff(ss, pmtimestamp, prs.starttime) / 86400.0,  
 Fresh =  CASE    
    WHEN (datediff(ss, pmtimestamp, prs.starttime) / 86400.0) <=1  
    and PMTimeStamp is not null  
    THEN 1  
    WHEN (datediff(ss, pmtimestamp, prs.starttime) / 86400.0) > 1  
    and PMTimeStamp is not null  
    THEN 0  
    ELSE null  
    END  
FROM dbo.#PRsRun prs with (nolock)  
  
  
update prs set  
 Parent =  
  case  
  when ParentPRID <> 'NoAssignedPRID'  
  then left(coalesce(ParentPRID,''),2)  
  else 'NoAssignedPRID'  
  end  
from dbo.#PRsRun prs with (nolock)  
where prs.Parent is null  
  
update prs set  
 GrandParent =   
  case  
  when GrandParentPRID <> 'NoAssignedPRID'  
  then left(coalesce(GrandParentPRID,''),2)  
  else 'NoAssignedPRID'  
  end  
from dbo.#PRsRun prs with (nolock)  
where prs.GrandParent is null  
  
  
--print 'perfect PR' + ' ' + convert(varchar(25),current_timestamp,108)  
  
--------------------------------------------------------------------------------------------  
-- Capture PerfectPRStatus for INTR events by using the GrandParentPRID to get  
-- get the PPR Status from the Rolls unit of the PaperMachine.  
--------------------------------------------------------------------------------------------  
--/*  
  
select @VarPMPRIDID = GBDB.dbo.fnLocal_GlblGetVarId(@Rolls_PU_ID, @VarPRIDVN)  
  
update prs SET   
 PerfectPRStatus = t1.Result  
FROM dbo.#PRsRun prs with (nolock)  
join @prodlines pl   
on prs.plid = pl.plid  
JOIN dbo.Tests t with (nolock)   
ON t.Var_Id = @VarPMPRIDId   
AND t.Result = prs.GrandParentPRID  
JOIN dbo.Variables v with (nolock)  
ON v.PU_Id = pl.RollsPUID  --@Rolls_PU_ID  
and v.var_id = pl.VarPMPerfectPRStatusID  
JOIN dbo.Tests t1 with (nolock)  
ON t1.Var_Id = v.Var_Id  
AND t1.Result_On = t.Result_On  
WHERE prs.PerfectPRStatus IS NULL  
--*/  
  
  
--------------------------------------------------------------------------------------------  
-- Capture PerfectPRStatus for INTR events by using the GrandParentPRID to get  
-- get the PPR Status from the Rolls unit of the PaperMachine.  
--------------------------------------------------------------------------------------------  
  
--print 'perfect pr status' + ' ' + convert(varchar(25),current_timestamp,108)  
  
UPDATE prs SET   
 PerfectPRStatus = t1.Result  
FROM dbo.#PRsRun prs with (nolock)  
join @prodlines pl  
on prs.plid = pl.plid  
JOIN dbo.Tests t with (nolock)  
ON t.Var_Id = @VarPMPRIDId   
AND t.Result = prs.GrandParentPRID  
JOIN dbo.Variables v with (nolock)  
ON v.PU_Id = @Rolls_PU_ID  
and v.var_id = pl.VarPMPerfectPRStatusID  
JOIN dbo.Tests t1 with (nolock)   
ON t1.Var_Id = v.Var_Id  
AND t1.Result_On = t.Result_On  
WHERE prs.PerfectPRStatus IS NULL  
  
  
--------------------------------------------------------------------------------------------  
-- Populate the table to hold the Variables associated with Perfect PR  
--------------------------------------------------------------------------------------------  
  
--print 'perfect pr vars' + ' ' + convert(varchar(25),current_timestamp,108)  
  
INSERT INTO @PerfectPRVars  
 (  
 VarId,   
 VarDesc,   
 PUId  
 )  
SELECT --distinct  
 cid.Var_Id,   
 Var_Desc,   
 @Rolls_PU_Id  
FROM dbo.Calculation_Instance_Dependencies CID with (nolock)  
JOIN Variables v with (nolock)  
ON cid.Var_Id = v.Var_Id  
WHERE cid.result_var_id = @PMPerfectPRStatusId AND  
  cid.Calc_Dependency_NotActive = 0   
OPTION (KEEP PLAN)  
  
  
--------------------------------------------------------------------------------------------  
-- Populate the dbo.#PerfectPRTests table with tests values for the PerfectPR Variables.  
--------------------------------------------------------------------------------------------  
  
--print 'tests' + ' ' + convert(varchar(25),current_timestamp,108)  
  
-- #tests is not used at the moment, but could be used to optimize the sp.  
INSERT dbo.#Tests   
 (  
 Var_Id,   
 Result_On,   
 Result  
 )  
SELECT   
 t.Var_Id,   
 t.Result_On,   
 t.Result  
FROM dbo.Tests t with (nolock)  
INNER JOIN @PerfectPRVars ppr   
ON t.Var_Id = ppr.varid  
AND t.Result_On >= @Report_Start_Time  
AND t.Result_On <  @Report_End_Time  
OPTION (KEEP PLAN)  
  
  
-- 2007-01-08 JSJ Rev8.24  
--IF (SELECT COUNT(VarId) FROM @PerfectPRVars) > 0  
IF exists (SELECT VarId FROM @PerfectPRVars)   
BEGIN  
  
--print 'perfect pr tests' + ' ' + convert(varchar(25),current_timestamp,108)  
  
 -- Populate the table that will hold all tests values for the PPR tests.  
 -- Make sure that NULL values are replaced with the last valid test value.  
  
 -- 2007-01-08 JSJ Rev8.24  
 -- this insert accounts for more than 50% of the processing effort of this sp.  
 -- if we could simplify it, or make it more efficient, the runtime should be noticably reduced.  
 -- I believe that there might be something to be gained if we can make better use of the indices  
 -- on the tables in the joins.  
  
 INSERT INTO dbo.#PerfectPRTests (  
  VarId,  
  VarDesc,  
  ResultOn,  
  Result,  
  UpperWarning,  
  LowerWarning,  
  UpperReject,  
  LowerReject,  
  Flagged,  
  RejectHold,  
  ProdId,  
  Tested  
  )  
 SELECT  ppr.VarId,   
    ppr.VarDesc,   
    e.TimeStamp,   
    Result,   
    vsp.U_Warning,   
    vsp.L_Warning,   
    vsp.U_Reject,   
    vsp.L_Reject,  
    NULL, -- Flagged  
    NULL, -- Reject/Hold  
    ps.Prod_Id,  
    CASE WHEN t.Result IS NOT NULL THEN 1 ELSE 0 END  
 FROM @PerfectPRVars ppr   
  join dbo.Events e with (nolock)  
  ON e.PU_Id = ppr.PUId  
  AND e.TimeStamp >= @Report_Start_Time   
  AND e.TimeStamp < @Report_End_Time  
  left JOIN dbo.#Tests t with (nolock)  
  ON t.Var_Id = ppr.VarId  
  AND t.Result_On = e.TimeStamp  
  LEFT JOIN dbo.Production_Starts ps with (nolock)  
  ON ps.pu_id = ppr.PUId   
  and ps.Start_Time <= e.TimeStamp   
  AND (ps.End_Time > e.TimeStamp OR ps.End_Time IS NULL)  
  LEFT JOIN dbo.Var_Specs vsp with (nolock)  
  ON vsp.Var_Id = ppr.VarId  
  AND vsp.Prod_Id = ps.Prod_Id  
  AND vsp.Effective_Date <= e.TimeStamp    
  AND (vsp.Expiration_Date > e.TimeStamp OR Expiration_Date IS NULL)   
 OPTION (KEEP PLAN)  
  
  
 UPDATE dbo.#PerfectPRTests set  
   RejectHold =  
    CASE WHEN ISNUMERIC(Result) > 0 THEN  -- Reject/Hold  
      (CASE WHEN (LowerReject is not null AND (convert(float,Result) < convert(float,LowerReject))) OR   
          (UpperReject is not null AND (convert(float,Result) > convert(float,UpperReject)))  
      THEN 1 ELSE 0 END)  
    ELSE   
     CASE WHEN Result IS NOT NULL AND (Result = LowerReject OR Result = UpperReject) THEN  
      1  
     ELSE 0 END  
    END  
   
 UPDATE dbo.#PerfectPRTests set  
   Flagged =   
    CASE WHEN ISNUMERIC(Result) > 0 THEN  -- Flagged  
      ( CASE   
       WHEN  (RejectHold IS NULL OR RejectHold = 0) AND   
         ((LowerWarning is not null AND (convert(float,Result) < convert(float,LowerWarning))) OR   
          (UpperWarning is not null AND (convert(float,Result) > convert(float,UpperWarning))))  
       THEN 1 ELSE 0 END)  
    ELSE   
     CASE   
     WHEN   Result IS NOT NULL AND   
       (RejectHold IS NULL OR RejectHold = 0) AND  
       (Result = LowerWarning OR Result = UpperWarning)   
     THEN 1 ELSE 0 END  
    END  
   
 UPDATE ppt  
  SET Result =   COALESCE(ppt1.Result, ppt.Result),  
    Flagged =  ppt1.Flagged,  
    RejectHold =  ppt1.RejectHold,  
    UpperWarning = ppt1.UpperWarning,  
    LowerWarning = ppt1.LowerWarning,  
    UpperReject =  ppt1.UpperReject,  
    LowerReject =  ppt1.LowerReject  
 FROM dbo.#PerfectPRTests ppt with (nolock)  
 JOIN dbo.#PerfectPRTests ppt1 with (nolock)   
 ON ppt.VarId = ppt1.VarId  
 AND ppt1.ResultOn = (SELECT TOP 1 pprt.ResultOn FROM dbo.#PerfectPRTests pprt with (nolock)  
        WHERE ppt.VarId = pprt.VarId AND pprt.ResultOn < ppt.ResultOn  
        AND pprt.Result IS NOT NULL  
        ORDER BY pprt.ResultOn DESC)  
 WHERE ppt.Result IS NULL  
  
END    
  
  
--------------------------------------------------------------------------------------------  
--- Determine which PUs were running paper for this PM for the report period.  
--------------------------------------------------------------------------------------------  
  
--print 'PUsRunningPRs' + ' ' + convert(varchar(25),current_timestamp,108)  
  
INSERT @PUsRunningPRs   
 (  
 PUId,   
 PLId,   
 PUDesc  
 )  
SELECT distinct  
 pul.PU_Id,  
 pul.PL_Id,  
 pul.PU_Desc  --DIFF  
FROM dbo.#PRsRun pr with (nolock)  
JOIN dbo.Prod_Units pu with (nolock)  
ON  pr.PUId = pu.PU_Id  
JOIN dbo.Prod_Units pul with (nolock)   
ON pu.PL_Id = pul.PL_Id  
AND (  
  pul.PU_Desc LIKE '%Converter Reliability%'   
  OR  pul.PU_Desc LIKE '%Rate Loss%'   
  OR  pul.PU_Desc LIKE '%INTR Reliability%'   
  OR  pul.PU_Desc LIKE '%Intermediate Reliability%'  
  )  
GROUP BY pul.PU_Id, pul.PL_Id, pul.PU_Desc  
OPTION (KEEP PLAN)  
  
  
--------------------------------------------------------------------------------------------  
--Collect dataset filtered by report period and Production Units.  
--------------------------------------------------------------------------------------------  
  
--print 'insert delays' + ' ' + convert(varchar(25),current_timestamp,108)  
  
INSERT INTO dbo.#Delays ( TEDetId,  
   PLID,  
   PUId,  
   PUDesc,        
   DelayType,    
   source,  
   StartTime,  
   EndTime,  
   L1ReasonId,  
   L2ReasonId,  
   ERTD_ID,  
   Downtime,  
   ReportDownTime   )  
SELECT ted.TEDet_Id,  
 tpu.plid,  
 ted.PU_Id,  
 tpu.PUDesc,   
 CASE  WHEN tpu.PUDesc LIKE '%Rate Loss%'  
   THEN 'RateLoss'  
   ELSE 'Downtime'  
   END,  
 ted.source_pu_id,  
 ted.Start_Time,  
 coalesce(ted.End_Time, @Now),  
 ted.Reason_Level1,  
 ted.Reason_Level2,  
 ted.event_reason_tree_data_id,  
 DATEDIFF(ss, ted.Start_Time,COALESCE(ted.End_Time, @Report_End_Time)),  
 datediff(second, (CASE WHEN ted.Start_Time < @Report_Start_Time   
    THEN @Report_Start_Time   
    ELSE ted.Start_Time  
    END),  
   (CASE WHEN coalesce(ted.End_Time, @Now) > @Report_End_Time   
    THEN @Report_End_Time   
    ELSE coalesce(ted.End_Time, @Now)  
    END))  
FROM dbo.Timed_Event_Details ted with (nolock)  
JOIN @PUsRunningPRs tpu   
ON ted.PU_Id = tpu.PUId AND tpu.PUId > 0  
WHERE ted.Start_Time < @Report_End_Time  
AND (ted.End_Time > @Report_Start_Time OR ted.End_Time IS NULL)  
OPTION (KEEP PLAN)  
  
update d   
 SET PrimaryId = pd.TEDetId  
 FROM  dbo.#Delays d with (nolock)   
 JOIN dbo.#Delays pd with (nolock)  
  ON d.StartTime = pd.EndTime  
 AND d.PUId = pd.PUId  
 WHERE d.TEDetId <> pd.TEDetId  
  
  
/*  
-------------------------------------------------------------------------------  
-- Retrieve the Schedule, Category, GroupCause and SubSystem categories for the  
-- Timed_Event_Details row from the Local_Timed_Event_Categories table using  
-- the TEDet_Id.  
-------------------------------------------------------------------------------  
  
-- Going to only do this once b/c its really expensive (??) to query from Local_Timed_Event_Categories  
  
--print 'TECategories' + ' ' + convert(varchar(25),current_timestamp,108)  
  
INSERT INTO dbo.#TECategories   
 (   
 TEDet_Id,  
 ERC_Id  
 )  
SELECT distinct   
 tec.TEDet_Id,  
 tec.ERC_Id  
FROM dbo.#Delays td with (nolock)  
--join dbo.#ltec tec with (nolock)  
join dbo.Local_Timed_Event_Categories tec with (nolock)  
on td.TEDetID = tec.TEDet_ID  
OPTION (KEEP PLAN)  
  
update td  
SET ScheduleId = tec.ERC_Id  
FROM dbo.#Delays td with (nolock)  
 INNER JOIN dbo.#TECategories tec with (nolock)  
  ON td.TEDetId = tec.TEDet_Id  
 INNER JOIN dbo.Event_Reason_Catagories erc with (nolock)  
 ON tec.ERC_Id = erc.ERC_Id  
 AND erc.ERC_Desc LIKE @ScheduleStr + '%'  
  
UPDATE td  
SET ScheduleId = @SchedBlockedStarvedId  
FROM dbo.#Delays td with (nolock)  
JOIN dbo.Event_Reasons er with (nolock)  
on Event_Reason_ID = L1ReasonId   
WHERE ScheduleId IS NULL   
AND (Event_Reason_Name LIKE '%BLOCK%' OR Event_Reason_Name LIKE '%STARVE%')  
  
update td  
SET CategoryId = tec.ERC_Id  
FROM dbo.#Delays td with (nolock)  
 INNER JOIN dbo.#TECategories tec with (nolock)   
 ON td.TEDetId = tec.TEDet_Id  
 INNER JOIN dbo.Event_Reason_Catagories erc with (nolock)   
 ON tec.ERC_Id = erc.ERC_Id  
 AND erc.ERC_Desc LIKE @CategoryStr + '%'  
*/  
  
UPDATE td SET  
 ScheduleId = erc.ERC_Id  
FROM dbo.#Delays td with (nolock)  
JOIN dbo.event_reason_category_data ercd WITH (NOLOCK)   
ON TD.ERTD_ID = ercd.event_reason_tree_data_id   
JOIN dbo.event_reason_catagories erc WITH (NOLOCK)   
ON ercd.erc_id = erc.erc_id   
where erc.ERC_Desc LIKE @ScheduleStr + '%'  
  
  
UPDATE td  
SET ScheduleId = @SchedBlockedStarvedId  
FROM dbo.#Delays td with (nolock)  
JOIN dbo.Event_Reasons er with (nolock)  
on Event_Reason_ID = L1ReasonId   
WHERE ScheduleId IS NULL   
AND (Event_Reason_Name LIKE '%BLOCK%' OR Event_Reason_Name LIKE '%STARVE%')  
  
  
UPDATE td SET  
 CategoryId = erc.ERC_Id  
FROM dbo.#Delays td with (nolock)  
JOIN dbo.event_reason_category_data ercd WITH (NOLOCK)   
ON TD.ERTD_ID = ercd.event_reason_tree_data_id   
JOIN dbo.event_reason_catagories erc WITH (NOLOCK)   
ON ercd.erc_id = erc.erc_id   
where erc.ERC_Desc LIKE @CategoryStr + '%'  
  
  
-------------------------------------------------------------------------------  
-- Calculate the Statistics on the dataset and set NULL Uptimes to zero.  
-------------------------------------------------------------------------------  
  
--print 'stops updates' + ' ' + convert(varchar(25),current_timestamp,108)  
  
update td  
 SET Stops =   CASE WHEN td.DelayType <> @DelayTypeRateLossStr  
--      AND (td.CategoryId <> @CatBlockStarvedId OR td.CategoryId IS NULL)  
      AND (td.StartTime >= @Report_Start_Time)  
      AND (td.PrimaryId IS NULL)  
      THEN 1  
      ELSE 0  
      END,  
   ReportDowntime =  CASE WHEN td.DelayType = @DelayTypeRateLossStr   
      THEN 0   
      ELSE td.ReportDowntime   
      END  
 FROM dbo.#Delays td with (nolock)  
  
  
-- update the Rate Loss Event data for both Primary and Secondary events.  
 update td SET  
  stopsrateloss =  1,  
  ReportDowntime =  0,  
  ReportRLDowntime =  (SELECT CONVERT(float, Result) FROM dbo.Tests t WHERE td.StartTime = t.Result_On  
          AND t.Var_Id = tpl.VarEffDowntimeId) * 60.0  
 FROM dbo.#Delays td with (nolock)  
 JOIN @ProdUnits tpu ON td.PUId = tpu.PUId    
 JOIN @ProdLines tpl ON tpu.PLId = tpl.PLId    
 WHERE td.DelayType = @DelayTypeRateLossStr    
  AND (td.StartTime >= @Report_Start_Time AND td.StartTime < @Report_End_Time)  
  
 update td SET  
  ReportDowntime  = null,  
  RateLossRatio   = CONVERT(FLOAT,ReportRLDowntime) / downtime,  
  downtime    = null  
 FROM dbo.#Delays td with (nolock)  
 WHERE stopsrateloss = 1  
  
  
update td set  
 puid = pl.reliabilitypuid  
from dbo.#delays td with (nolock)  
join @prodlines pl  
on td.plid = pl.plid  
where td.puid = pl.ratelosspuid  
  
  
--print 'PRPLID' + ' ' + convert(varchar(25),current_timestamp,108)  
  
update prs set  
 prplid = (select pl_id from dbo.prod_units pu where pu_id = prs.prpuid)  
from dbo.#PRsRun prs with (nolock)   
  
  
--print 'L2ReasonName' + ' ' + convert(varchar(25),current_timestamp,108)  
  
update td set  
 L2ReasonName = coalesce(er.event_reason_name,'')  
from dbo.#delays td with (nolock)  
Join dbo.Event_Reasons er with (nolock)  
On td.L2ReasonID = er.Event_Reason_Id  
  
  
----------------------------------------------------------------------------------------------------  
-- be VERY careful in the following updates to date ranges.  
-- note that "=" is not included in the comparisons.  this is handled in the next set of updates.  
-----------------------------------------------------------------------------------------------------  
  
--print '@PRDTReasons' + ' ' + convert(varchar(25),current_timestamp,108)  
  
insert dbo.#PRDTReasons   
 (  
  
 prs_idnum,  
 puid,  
 plid,  
   [StartTime],  
   [EndTime],  
 Product,  
 Team,  
 Fresh,  
 Reason_Name,  
 [PerfectPRStatus]   
  
 )  
  
select distinct  
 prs.id_num,  
 prs.puid,  
 pl.plid,  
 prs.starttime,  
 prs.endtime,  
 prs.PMProdDesc,  
 prs.Team,  
 prs.Fresh,  
 td.L2ReasonName,  
 prs.PerfectPRStatus   
  
FROM dbo.#PRsRun prs with (nolock)   
join @prodlines pl  
on prs.puid = pl.prodpuid  
left join dbo.#delays td with (nolock)  
on (td.puid = pl.reliabilitypuid or td.puid = pl.ratelosspuid)  
and (td.starttime < prs.endtime)   
and (td.endtime > prs.starttime)   
  
  
--print 'Update reasons pdr' + ' ' + convert(varchar(25),current_timestamp,108)  
  
--Rev8.51  
update pdr set  
  
 StartTime_FreshReasons =   
  coalesce(  
  (  
  select  
   case   
   when max(pr1.EndTime) > pdr.EndTime  
   then pdr.starttime   
   else max(pr1.EndTime)  
   end     
  from dbo.#PRDTReasons pr1 with (nolock)  
  where pr1.PLID = pdr.PLID  
  and pr1.StartTime < pdr.StartTime   
  and pr1.EndTime > pdr.StartTime   
  and pr1.Reason_Name = pdr.Reason_Name  
  and pr1.Fresh = pdr.Fresh  
--  and pr.id_num <> pdr.id_num  
  ),pdr.StartTime),  
  
 EndTime_FreshReasons =   
  coalesce(  
  (  
  select  
   case   
   when min(pr2.StartTime) > pdr.StartTime  
   then pdr.endtime   
   else min(pr2.StartTime)  
   end     
  from dbo.#PRDTReasons pr2 with (nolock)  
  where pr2.PLID = pdr.PLID  
  and pr2.StartTime < pdr.EndTime   
  and pr2.EndTime > pdr.EndTime   
  and pr2.Reason_Name = pdr.Reason_Name  
  and pr2.Fresh = pdr.Fresh  
--  and pr.id_num <> pdr.id_num  
  ),pdr.EndTime),  
  
 StartTime_ProdTeamFreshReasons =   
  coalesce(  
  (  
  select  
   case   
   when max(pr3.EndTime) > pdr.EndTime  
   then pdr.starttime   
   else max(pr3.EndTime)  
   end     
  from dbo.#PRDTReasons pr3 with (nolock)  
  where pr3.PLID = pdr.PLID  
  and pr3.StartTime < pdr.StartTime   
  and pr3.EndTime > pdr.StartTime   
  and pr3.Reason_Name = pdr.Reason_Name  
  and pr3.Fresh = pdr.Fresh  
  and pr3.Product = pdr.Product   
  and pr3.Team = pdr.Team  
--  and pr.id_num <> pdr.id_num  
  ),pdr.StartTime),  
  
 EndTime_ProdTeamFreshReasons =   
  coalesce(  
  (  
  select  
   case   
   when min(pr4.StartTime) > pdr.StartTime  
   then pdr.endtime   
   else min(pr4.StartTime)  
   end     
  from dbo.#PRDTReasons pr4 with (nolock)  
  where pr4.PLID = pdr.PLID  
  and pr4.StartTime < pdr.EndTime   
  and pr4.EndTime > pdr.EndTime   
  and pr4.Reason_Name = pdr.Reason_Name  
  and pr4.Fresh = pdr.Fresh  
  and pr4.Product = pdr.Product   
  and pr4.Team = pdr.Team  
--  and pr.id_num <> pdr.id_num  
  ),pdr.EndTime)--,  
  
from dbo.#PRDTReasons pdr with (nolock)  
  
  
--print 'update reason time ranges 1' + ' ' + convert(varchar(25),current_timestamp,108)  
  
--Rev8.51  
update pdr set  
 pdr.StartTime_FreshReasons = pdr.EndTime_FreshReasons  
from dbo.#PRDTReasons pdr with (nolock)  
where pdr.StartTime_FreshReasons > pdr.EndTime_FreshReasons  
option (maxdop 1)  
  
--print 'update reason time ranges 2' + ' ' + convert(varchar(25),current_timestamp,108)  
  
--Rev8.51  
update pdr set  
 pdr.StartTime_FreshReasons = pdr.EndTime_FreshReasons  
from dbo.#PRDTReasons pdr with (nolock)  
join dbo.#PRDTReasons pr with (nolock)  
on pr.PLID = pdr.PLID  
and pdr.StartTime_FreshReasons < pdr.EndTime_FreshReasons  
and pr.StartTime_FreshReasons < pr.EndTime_FreshReasons  
where (pr.StartTime_FreshReasons = pdr.StartTime_FreshReasons   
   or pr.EndTime_FreshReasons = pdr.EndTime_FreshReasons)  
and datediff(ss,pr.StartTime_FreshReasons,pr.EndTime_FreshReasons)   
    > datediff(ss,pdr.StartTime_FreshReasons,pdr.EndTime_FreshReasons)  
and pr.Reason_Name = pdr.Reason_Name  
and pr.Fresh = pdr.Fresh  
--and pr.id_num <> pdr.id_num  
option (maxdop 1)  
  
--print 'update reason time ranges 3' + ' ' + convert(varchar(25),current_timestamp,108)  
  
--Rev8.51  
update pdr set  
 pdr.StartTime_FreshReasons = pdr.EndTime_FreshReasons  
from dbo.#PRDTReasons pdr with (nolock)  
join dbo.#PRDTReasons pr with (nolock)  
on pr.PLID = pdr.PLID  
and pdr.StartTime_FreshReasons < pdr.EndTime_FreshReasons  
and pr.StartTime_FreshReasons < pr.EndTime_FreshReasons  
where (pr.StartTime_FreshReasons = pdr.StartTime_FreshReasons   
   and pr.EndTime_FreshReasons = pdr.EndTime_FreshReasons)  
and pr.Reason_Name = pdr.Reason_Name  
and pr.Fresh = pdr.Fresh  
and pr.id_num > pdr.id_num  
option (maxdop 1)  
  
  
--Rev7.6  
  
--print 'update reason time ranges 4' + ' ' + convert(varchar(25),current_timestamp,108)  
  
--Rev8.51  
update pdr set  
 pdr.StartTime_ProdTeamFreshReasons = pdr.EndTime_ProdTeamFreshReasons  
from dbo.#PRDTReasons pdr with (nolock)  
where pdr.StartTime_ProdTeamFreshReasons > pdr.EndTime_ProdTeamFreshReasons  
option (maxdop 1)  
  
--print 'update reason time ranges 5' + ' ' + convert(varchar(25),current_timestamp,108)  
  
--Rev8.51  
update pdr set  
 pdr.StartTime_ProdTeamFreshReasons = pdr.EndTime_ProdTeamFreshReasons  
from dbo.#PRDTReasons pdr with (nolock)  
join dbo.#PRDTReasons pr with (nolock)  
on pr.PLID = pdr.PLID  
and pdr.StartTime_ProdTeamFreshReasons < pdr.EndTime_ProdTeamFreshReasons  
and pr.StartTime_ProdTeamFreshReasons < pr.EndTime_ProdTeamFreshReasons  
where (pr.StartTime_ProdTeamFreshReasons = pdr.StartTime_ProdTeamFreshReasons   
    or pr.EndTime_ProdTeamFreshReasons = pdr.EndTime_ProdTeamFreshReasons)  
and datediff(ss,pr.StartTime_ProdTeamFreshReasons,pr.EndTime_ProdTeamFreshReasons)   
    > datediff(ss,pdr.StartTime_ProdTeamFreshReasons,pdr.EndTime_ProdTeamFreshReasons)  
and pr.Product = pdr.Product   
and pr.Reason_Name = pdr.Reason_Name  
and pr.Team = pdr.Team  
and pr.Fresh = pdr.Fresh  
--and pr.id_num <> pdr.id_num  
option (maxdop 1)  
  
  
--print 'update reason time ranges 6' + ' ' + convert(varchar(25),current_timestamp,108)  
  
--Rev8.51  
update pdr set  
 pdr.StartTime_ProdTeamFreshReasons = pdr.EndTime_ProdTeamFreshReasons  
from dbo.#PRDTReasons pdr with (nolock)  
join dbo.#PRDTReasons pr with (nolock)  
on pr.PLID = pdr.PLID  
and pdr.StartTime_ProdTeamFreshReasons < pdr.EndTime_ProdTeamFreshReasons  
and pr.StartTime_ProdTeamFreshReasons < pr.EndTime_ProdTeamFreshReasons  
where (pr.StartTime_ProdTeamFreshReasons = pdr.StartTime_ProdTeamFreshReasons   
    and pr.EndTime_ProdTeamFreshReasons = pdr.EndTime_ProdTeamFreshReasons)  
and pr.Product = pdr.Product   
and pr.Reason_Name = pdr.Reason_Name  
and pr.Team = pdr.Team  
and pr.Fresh = pdr.Fresh  
and pr.id_num > pdr.id_num  
option (maxdop 1)  
  
  
--print '@PRDTProducts' + ' ' + convert(varchar(25),current_timestamp,108)  
  
insert dbo.#PRDTProducts  
 (  
  
 prs_idnum,  
 puid,  
 plid,  
 reliabilitypuid,  
   [StartTime],  
   [EndTime],  
 Product,  
 Team,  
 Fresh,  
 [PerfectPRStatus]   
  
 )  
  
select distinct  
 prs.id_num,  
 prs.puid,  
 pl.plid,  
 pl.reliabilitypuid,  
 prs.starttime,  
 prs.endtime,  
 prs.PMProdDesc,  
 prs.Team,  
 prs.Fresh,  
 prs.PerfectPRStatus   
  
FROM dbo.#PRsRun prs with (nolock)   
join @prodlines pl  
on prs.puid = pl.prodpuid  
WHERE prs.PMProdDesc <> 'NoAssignedPRID'   
  
  
--print 'update product pdr' + ' ' + convert(varchar(25),current_timestamp,108)  
  
--Rev8.51  
update pdr set  
  
 StartTime_Product =  
  coalesce(  
  (  
  select  
   case   
   when max(pr1.EndTime) > pdr.EndTime  
   then pdr.starttime   
   else max(pr1.EndTime)  
   end     
  from dbo.#PRDTProducts pr1 with (nolock)  
  where pr1.PlID = pdr.PlID  
  and pr1.StartTime < pdr.StartTime   
  and pr1.EndTime > pdr.StartTime   
  and pr1.Product = pdr.Product   
--  and pr.id_num <> pdr.id_num  
  ),pdr.StartTime),  
  
 EndTime_Product =  
  coalesce(  
  (  
  select  
   case   
   when min(pr2.StartTime) > pdr.StartTime  
   then pdr.endtime   
   else min(pr2.StartTime)  
   end     
  from dbo.#PRDTProducts pr2 with (nolock)  
  where pr2.PlID = pdr.PlID  
  and pr2.StartTime < pdr.EndTime   
  and pr2.EndTime > pdr.EndTime   
  and pr2.Product = pdr.Product   
--  and pr.id_num <> pdr.id_num  
  ),pdr.EndTime),  
  
 StartTime_ProductTeam =   
  coalesce(  
  (  
  select  
   case   
   when max(pr3.EndTime) > pdr.EndTime  
   then pdr.starttime   
   else max(pr3.EndTime)  
   end     
  from dbo.#PRDTProducts pr3 with (nolock)  
  where pr3.PlID = pdr.PlID  
  and pr3.StartTime < pdr.StartTime   
  and pr3.EndTime > pdr.StartTime   
  and pr3.Product = pdr.Product   
  and pr3.Team = pdr.Team  
--  and pr.id_num <> pdr.id_num  
  ),pdr.StartTime),  
  
 EndTime_ProductTeam =   
  coalesce(  
  (  
  select  
   case   
   when min(pr4.StartTime) > pdr.StartTime  
   then pdr.endtime   
   else min(pr4.StartTime)  
   end     
  from dbo.#PRDTProducts pr4 with (nolock)  
  where pr4.PlID = pdr.PlID  
  and pr4.StartTime < pdr.EndTime   
  and pr4.EndTime > pdr.EndTime   
  and pr4.Product = pdr.Product   
  and pr4.Team = pdr.Team  
--  and pr.id_num <> pdr.id_num  
  ),pdr.EndTime)  
  
from dbo.#PRDTProducts pdr with (nolock)  
  
--print 'update product time ranges 1' + ' ' + convert(varchar(25),current_timestamp,108)  
  
--Rev8.51  
update pdr set  
 pdr.StartTime_Product = pdr.EndTime_Product  
from dbo.#PRDTProducts pdr with (nolock)  
where pdr.StartTime_Product > pdr.EndTime_Product  
option (maxdop 1)  
  
--print 'update product time ranges 2' + ' ' + convert(varchar(25),current_timestamp,108)  
  
--Rev8.51  
update pdr set  
 pdr.StartTime_Product = pdr.EndTime_Product  
from dbo.#PRDTProducts pdr with (nolock)  
join dbo.#PRDTProducts pr with (nolock)  
on pr.PlID = pdr.PlID  
and pdr.StartTime_Product < pdr.EndTime_Product  
and pr.StartTime_Product < pr.EndTime_Product  
where (pr.StartTime_Product = pdr.StartTime_Product  
    or pr.EndTime_Product = pdr.EndTime_Product)  
and datediff(ss,pr.StartTime_Product, pr.EndTime_Product)   
    > datediff(ss,pdr.StartTime_Product, pdr.EndTime_Product)  
and pr.Product = pdr.Product   
--and pr.id_num <> pdr.id_num  
option (maxdop 1)  
  
  
--print 'update product time ranges 3' + ' ' + convert(varchar(25),current_timestamp,108)  
  
--/*  
--Rev8.51  
update pdr set  
 pdr.StartTime_Product = pdr.EndTime_Product  
from dbo.#PRDTProducts pdr with (nolock)  
join dbo.#PRDTProducts pr with (nolock)  
on pr.PlID = pdr.PlID  
and pdr.StartTime_Product < pdr.EndTime_Product  
and pr.StartTime_Product < pr.EndTime_Product  
where (pr.StartTime_Product = pdr.StartTime_Product  
    and pr.EndTime_Product = pdr.EndTime_Product)  
and pr.Product = pdr.Product   
and pr.id_num > pdr.id_num  
option (maxdop 1)  
--*/  
  
  
--print 'update product time ranges 4' + ' ' + convert(varchar(25),current_timestamp,108)  
  
--Rev8.51  
update pdr set  
 pdr.StartTime_ProductTeam = pdr.EndTime_ProductTeam  
from dbo.#PRDTProducts pdr with (nolock)  
where pdr.StartTime_ProductTeam > pdr.EndTime_ProductTeam  
option (maxdop 1)  
  
  
--print 'update product time ranges 5' + ' ' + convert(varchar(25),current_timestamp,108)  
  
--Rev8.51  
update pdr set  
 pdr.StartTime_ProductTeam = pdr.EndTime_ProductTeam  
from dbo.#PRDTProducts pdr with (nolock)  
join dbo.#PRDTProducts pr with (nolock)  
on pr.PlID = pdr.PlID  
and pdr.StartTime_ProductTeam < pdr.EndTime_ProductTeam  
and pr.StartTime_ProductTeam < pr.EndTime_ProductTeam  
where (pr.StartTime_ProductTeam = pdr.StartTime_ProductTeam  
    or pr.EndTime_ProductTeam = pdr.EndTime_ProductTeam)  
and datediff(ss,pr.StartTime_ProductTeam, pr.EndTime_ProductTeam)  
    > datediff(ss,pdr.StartTime_ProductTeam, pdr.EndTime_ProductTeam)  
and pr.Product = pdr.Product   
and pr.Team = pdr.Team  
--and pr.id_num <> pdr.id_num  
option (maxdop 1)  
  
  
--print 'update product time ranges 6' + ' ' + convert(varchar(25),current_timestamp,108)  
  
--/*  
--Rev8.51  
update pdr set  
 pdr.StartTime_ProductTeam = pdr.EndTime_ProductTeam  
from dbo.#PRDTProducts pdr with (nolock)  
join dbo.#PRDTProducts pr with (nolock)  
on pr.PlID = pdr.PlID  
and pdr.StartTime_ProductTeam < pdr.EndTime_ProductTeam  
and pr.StartTime_ProductTeam < pr.EndTime_ProductTeam  
where (pr.StartTime_ProductTeam = pdr.StartTime_ProductTeam  
    and pr.EndTime_ProductTeam = pdr.EndTime_ProductTeam)  
and pr.Product = pdr.Product   
and pr.Team = pdr.Team  
and pr.id_num > pdr.id_num  
option (maxdop 1)  
--*/  
  
  
--print '@PRDTTeams' + ' ' + convert(varchar(25),current_timestamp,108)  
  
--Rev8.51  
insert dbo.#PRDTTeams  
 (  
  
 prs_idnum,  
 puid,  
 plid,  
 reliabilitypuid,  
   [StartTime],  
   [EndTime],  
 Team,  
 Fresh,  
 [PerfectPRStatus]   
  
 )  
  
select distinct  
 prs.id_num,  
 prs.puid,  
 pl.plid,  
 pl.reliabilitypuid,  
 prs.starttime,  
 prs.endtime,  
 prs.Team,  
 prs.Fresh,  
 prs.PerfectPRStatus   
  
FROM dbo.#PRsRun prs with (nolock)   
join @prodlines pl  
on prs.puid = pl.prodpuid  
WHERE prs.PMProdDesc <> 'NoAssignedPRID'   
  
  
--print 'update product pdr' + ' ' + convert(varchar(25),current_timestamp,108)  
  
--Rev8.51  
update pdr set  
  
 StartTime_Team =   
  coalesce(  
  (  
  select  
   case   
   when max(pr1.EndTime) > pdr.EndTime  
   then pdr.starttime   
   else max(pr1.EndTime)  
   end     
  from dbo.#PRDTTeams pr1 with (nolock)  
  where pr1.PlID = pdr.PlID  
  and pr1.StartTime < pdr.StartTime   
  and pr1.EndTime > pdr.StartTime   
  and pr1.Team = pdr.Team  
--  and pr.id_num <> pdr.id_num  
  ),pdr.StartTime),  
  
 EndTime_Team =   
  coalesce(  
  (  
  select  
   case   
   when min(pr2.StartTime) > pdr.StartTime  
   then pdr.endtime   
   else min(pr2.StartTime)  
   end     
  from dbo.#PRDTTeams pr2 with (nolock)  
  where pr2.PlID = pdr.PlID  
  and pr2.StartTime < pdr.EndTime   
  and pr2.EndTime > pdr.EndTime   
  and pr2.Team = pdr.Team  
--  and pr.id_num <> pdr.id_num  
  ),pdr.EndTime)  
  
from dbo.#PRDTTeams pdr with (nolock)  
  
  
--print 'update product time ranges 1' + ' ' + convert(varchar(25),current_timestamp,108)  
  
--print 'update product time ranges 4' + ' ' + convert(varchar(25),current_timestamp,108)  
  
--Rev8.51  
update pdr set  
 pdr.StartTime_Team = pdr.EndTime_Team  
from dbo.#PRDTTeams pdr with (nolock)  
where pdr.StartTime_Team > pdr.EndTime_Team  
option (maxdop 1)  
  
  
--print 'update product time ranges 5' + ' ' + convert(varchar(25),current_timestamp,108)  
  
--Rev8.51  
update pdr set  
 pdr.StartTime_Team = pdr.EndTime_Team  
from dbo.#PRDTTeams pdr with (nolock)  
join dbo.#PRDTTeams pr with (nolock)  
on pr.PlID = pdr.PlID  
and pdr.StartTime_Team < pdr.EndTime_Team  
and pr.StartTime_Team < pr.EndTime_Team  
where (pr.StartTime_Team = pdr.StartTime_Team  
    or pr.EndTime_Team = pdr.EndTime_Team)  
and datediff(ss,pr.StartTime_Team, pr.EndTime_Team)  
    > datediff(ss,pdr.StartTime_Team, pdr.EndTime_Team)  
and pr.Team = pdr.Team  
--and pr.id_num <> pdr.id_num  
option (maxdop 1)  
  
  
--print 'update product time ranges 6' + ' ' + convert(varchar(25),current_timestamp,108)  
  
--/*  
--Rev8.51  
update pdr set  
 pdr.StartTime_Team = pdr.EndTime_Team  
from dbo.#PRDTTeams pdr with (nolock)  
join dbo.#PRDTTeams pr with (nolock)  
on pr.PlID = pdr.PlID  
and pdr.StartTime_Team < pdr.EndTime_Team  
and pr.StartTime_Team < pr.EndTime_Team  
where (pr.StartTime_Team = pdr.StartTime_Team  
    and pr.EndTime_Team = pdr.EndTime_Team)  
and pr.Team = pdr.Team  
and pr.id_num > pdr.id_num  
option (maxdop 1)  
--*/  
  
  
--print '#PRDTLine' + ' ' + convert(varchar(25),current_timestamp,108)  
  
insert dbo.#PRDTLine  
 (  
  
 prs_idnum,  
 puid,  
 plid,  
 prplid,  
 reliabilitypuid,  
   [StartTime],  
   [EndTime],  
 Fresh,  
 [PerfectPRStatus]   
  
 )  
  
select distinct  
 prs.id_num,  
 prs.puid,  
 pl.plid,  
 prs.prplid,  
 pl.reliabilitypuid,  
 prs.starttime,  
 prs.endtime,  
 prs.Fresh,  
 prs.PerfectPRStatus   
  
FROM dbo.#PRsRun prs with (nolock)   
join @prodlines pl  
on prs.puid = pl.prodpuid  
WHERE prs.PMProdDesc <> 'NoAssignedPRID'   
  
  
--Rev8.51  
update pdr set  
  
 StartTime_Line =  
  coalesce(  
  (  
  select  
   case   
   when max(pr1.EndTime) > pdr.EndTime  
   then pdr.starttime   
   else max(pr1.EndTime)  
   end     
  from dbo.#PRDTLine pr1 with (nolock)  
  where pr1.PlID = pdr.PlID  
  and pr1.prPlID = pdr.prPlID  
  and pr1.StartTime < pdr.StartTime   
  and pr1.EndTime > pdr.StartTime   
--  and pr.id_num <> pdr.id_num  
  ),pdr.StartTime),  
  
 EndTime_Line =  
  coalesce(  
  (  
  select  
   case   
   when min(pr2.StartTime) > pdr.StartTime  
   then pdr.endtime   
   else min(pr2.StartTime)  
   end     
  from dbo.#PRDTLine pr2 with (nolock)  
  where pr2.PlID = pdr.PlID  
  and pr2.prPlID = pdr.prPlID  
  and pr2.StartTime < pdr.EndTime   
  and pr2.EndTime > pdr.EndTime   
--  and pr.id_num <> pdr.id_num  
  ),pdr.EndTime)  
  
from dbo.#PRDTLine pdr with (nolock)  
  
  
--Rev8.51  
update pdr set  
 pdr.StartTime_Line = pdr.EndTime_Line  
from dbo.#PRDTLine pdr with (nolock)  
where pdr.StartTime_Line > pdr.EndTime_Line  
option (maxdop 1)  
  
--Rev8.51  
update pdr set  
 pdr.StartTime_Line = pdr.EndTime_Line  
from dbo.#PRDTLine pdr with (nolock)  
join dbo.#PRDTLine pr with (nolock)  
on pr.PlID = pdr.PlID  
and pr.prPlID = pdr.prPlID  
and pdr.StartTime_Line < pdr.EndTime_Line  
and pr.StartTime_Line < pr.EndTime_Line  
--and pr.id_num <> pdr.id_num  
where (pr.StartTime_Line = pdr.StartTime_Line  
    or pr.EndTime_Line = pdr.EndTime_Line)  
and datediff(ss,pr.StartTime_Line, pr.EndTime_Line)   
    > datediff(ss,pdr.StartTime_Line, pdr.EndTime_Line)  
option (maxdop 1)  
  
--/*  
--Rev8.51  
update pdr set  
 pdr.StartTime_Line = pdr.EndTime_Line  
from dbo.#PRDTLine pdr with (nolock)  
join dbo.#PRDTLine pr with (nolock)  
on pr.PlID = pdr.PlID  
and pr.prPlID = pdr.prPlID  
and pdr.StartTime_Line < pdr.EndTime_Line  
and pr.StartTime_Line < pr.EndTime_Line  
where (pr.StartTime_Line = pdr.StartTime_Line  
    and pr.EndTime_Line = pdr.EndTime_Line)  
and pr.id_num > pdr.id_num  
option (maxdop 1)  
--*/  
  
  
-------------------------------------------------------------------------------  
-------------------------------------------------------------------------------  
  
--print 'Reason Metrics' + ' ' + convert(varchar(25),current_timestamp,108)  
  
--Rev7.6  
insert @PRDTReasonMetrics  
 (  
  
 id_num,  
 plid,  
 Product,  
 Team,  
 Fresh,  
 Reason_Name,  
  
 Stops_FreshReasons,  
 Minutes_FreshReasons,  
 FreshPerfectELPMin_FreshReasons,  
 FreshFlaggedELPMin_FreshReasons,  
 FreshRejHoldELPMin_FreshReasons,  
 FreshOverallMin_FreshReasons,   
 StorageOverallMin_FreshReaons,  
  
 Stops_ProdTeamFreshReasons,  
 Minutes_ProdTeamFreshReasons,  
 FreshPerfectELPMin_ProdTeamFreshReasons,  
 FreshFlaggedELPMin_ProdTeamFreshReasons,  
 FreshRejHoldELPMin_ProdTeamFreshReasons--,  
  
 )  
  
select  
  
 pdr.id_num,  
 pdr.plid,  
 pdr.Product,  
 pdr.Team,  
 pdr.Fresh,  
 pdr.Reason_Name,  
  
 SUM(  
  CASE   
  when  td.Stops = 1  
  and td.starttime >= pdr.starttime_freshreasons  
  and (td.starttime < pdr.endtime_freshreasons or pdr.endtime_freshreasons is null)  
  THEN  1   
  ELSE  0   
  END  
  ) Stops_FreshReasons,  
  
 sum(  
  case  
  WHEN td.starttime >= pdr.starttime_freshreasons  
  and (td.starttime < pdr.endtime_freshreasons or pdr.endtime_freshreasons is null)  
  then (coalesce(td.Downtime,0.0) + coalesce(td.ReportRLDowntime,0.0))   
  else 0.0  
  end  
  ) / 60.0 Minutes_FreshReasons,  
  
 sum(  
  case  
  when pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Perfect' -- FreshPerfectELPMin_FreshReasons  
  and td.starttime >= pdr.starttime_freshreasons  
  and (td.starttime < pdr.endtime_freshreasons or pdr.endtime_freshreasons is null)  
  then (coalesce(td.Downtime,0.0) + coalesce(td.ReportRLDowntime,0.0))   
  else 0.0  
  end  
  ) / 60.0 FreshPerfectELPMin_FreshReasons,  
  
 sum(  
  case  
  when pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Flagged' -- FreshFlaggedELPMin_FreshReasons  
  and td.starttime >= pdr.starttime_freshreasons  
  and (td.starttime < pdr.endtime_freshreasons or pdr.endtime_freshreasons is null)  
  then (coalesce(td.Downtime,0.0) + coalesce(td.ReportRLDowntime,0.0))   
  else 0.0  
  end  
  ) / 60.0 FreshFlaggedELPMin_FreshReasons,  
  
 sum(  
  case  
  when pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Hold' -- FreshRejHoldELPMin_FreshReasons  
  and td.starttime >= pdr.starttime_freshreasons  
  and (td.starttime < pdr.endtime_freshreasons or pdr.endtime_freshreasons is null)  
  then (coalesce(td.Downtime,0.0) + coalesce(td.ReportRLDowntime,0.0))   
  else 0.0  
  end  
  ) / 60.0 FreshRejHoldELPMin_FreshReasons,  
  
 sum(  
  case  
  when pdr.Fresh = 1 -- FreshOverallMin_FreshReasons  
  and td.starttime >= pdr.starttime_freshreasons  
  and (td.starttime < pdr.endtime_freshreasons or pdr.endtime_freshreasons is null)  
  then (coalesce(td.Downtime,0.0) + coalesce(td.ReportRLDowntime,0.0))   
  else 0.0  
  end  
  ) / 60.0 FreshOverallMin_FreshReasons,   
  
 sum(  
  case  
  when pdr.Fresh = 0 -- StorageOverallMin_FreshReasons  
  and td.starttime >= pdr.starttime_freshreasons  
  and (td.starttime < pdr.endtime_freshreasons or pdr.endtime_freshreasons is null)  
  then (coalesce(td.Downtime,0.0) + coalesce(td.ReportRLDowntime,0.0))   
  else 0.0  
  end  
  ) / 60.0 StorageOverallMin_FreshReasons,  
  
 SUM(  
  CASE   
  when  td.Stops = 1  
  and td.starttime >= pdr.starttime_ProdTeamfreshreasons  
  and (td.starttime < pdr.endtime_ProdTeamfreshreasons or pdr.endtime_ProdTeamfreshreasons is null)  
  THEN  1   
  ELSE  0   
  END  
  ) Stops_ProdTeamFreshReasons,  
  
 sum(  
  case  
  WHEN td.starttime >= pdr.starttime_ProdTeamfreshreasons  
  and (td.starttime < pdr.endtime_ProdTeamfreshreasons or pdr.endtime_ProdTeamfreshreasons is null)  
  then (coalesce(td.Downtime,0.0) + coalesce(td.ReportRLDowntime,0.0))   
  else 0.0  
  end  
  ) / 60.0 Minutes_ProdTeamFreshReasons,  
  
 sum(  
  case  
  when pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Perfect' -- FreshPerfectELPMin_ProdTeamFreshReasons  
  and td.starttime >= pdr.starttime_ProdTeamFreshreasons  
  and (td.starttime < pdr.endtime_ProdTeamfreshreasons or pdr.endtime_ProdTeamfreshreasons is null)  
  then (coalesce(td.Downtime,0.0) + coalesce(td.ReportRLDowntime,0.0))   
  else 0.0  
  end  
  ) / 60.0 FreshPerfectELPMin_ProdTeamFreshReasons,  
  
 sum(  
  case  
  when pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Flagged' -- FreshFlaggedELPMin_ProdTeamFreshReasons  
  and td.starttime >= pdr.starttime_ProdTeamfreshreasons  
  and (td.starttime < pdr.endtime_ProdTeamfreshreasons or pdr.endtime_ProdTeamfreshreasons is null)  
  then (coalesce(td.Downtime,0.0) + coalesce(td.ReportRLDowntime,0.0))   
  else 0.0  
  end  
  ) / 60.0 FreshFlaggedELPMin_ProdTeamFreshReasons,  
  
 sum(  
  case  
  when pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Hold' -- FreshRejHoldELPMin_ProdTeamFreshReasons  
  and td.starttime >= pdr.starttime_ProdTeamfreshreasons  
  and (td.starttime < pdr.endtime_ProdTeamfreshreasons or pdr.endtime_ProdTeamfreshreasons is null)  
  then (coalesce(td.Downtime,0.0) + coalesce(td.ReportRLDowntime,0.0))   
  else 0.0  
  end  
  ) / 60.0 FreshRejHoldELPMin_ProdTeamFreshReasons--,  
  
FROM dbo.#PRDTReasons pdr with (nolock)  
join @prodlines pl  
on pdr.puid = pl.prodpuid  
left join dbo.#delays td with (nolock)  
on (pl.reliabilitypuid = td.puid or pl.ratelosspuid = td.puid)  
and td.starttime < pdr.endtime   
and td.endtime > pdr.starttime   
and td.L2ReasonName = pdr.Reason_Name  
and td.CategoryId = @CatELPId  
left JOIN @ProdUnits tpu   
ON td.PUId = tpu.PUId  
WHERE pdr.Product <> 'NoAssignedPRID'   
group by pdr.id_num, pdr.plid, pdr.product, pdr.team, pdr.fresh, pdr.reason_name   
  
  
--print 'Product Metrics' + ' ' + convert(varchar(25),current_timestamp,108)  
  
--Rev7.6  
insert @PRDTProductMetrics  
 (  
 id_num,  
 PLID,  
 Product,  
 Team,  
 Fresh,  
  
 SchedMins_Product,  
 FreshStops_Product,  
 FreshMins_Product,  
 StorageStops_Product,  
 StorageMins_Product,  
 FreshPerfectELPMin_Product,  
 FreshFlaggedELPMin_Product,  
 FreshRejHoldELPMin_Product,  
 FreshSchedDT_Product,  
 StorageSchedDT_Product,  
 FreshPerfectSchedDT_Product,  
 FreshFlaggedSchedDT_Product,  
 FreshRejHoldSchedDT_Product,  
 TotalStops_Product,  
 TotalMins_Product,  
  
 SchedMins_ProductTeam,  
 FreshStops_ProductTeam,  
 FreshMins_ProductTeam,  
 StorageStops_ProductTeam,  
 StorageMins_ProductTeam,  
 FreshPerfectELPMin_ProductTeam,  
 FreshFlaggedELPMin_ProductTeam,  
 FreshRejHoldELPMin_ProductTeam,  
 FreshSchedDT_ProductTeam,  
 StorageSchedDT_ProductTeam,  
 FreshPerfectSchedDT_ProductTeam,  
 FreshFlaggedSchedDT_ProductTeam,  
 FreshRejHoldSchedDT_ProductTeam,  
 TotalStops_ProductTeam,  
 TotalMins_ProductTeam  
  
 )  
  
select  
  
 pdr.id_num,  
 pdr.plid,  
 pdr.Product,  
 pdr.Team,  
 pdr.Fresh,  
  
 SUM  
  (  
  CASE   
  WHEN td.ScheduleId NOT IN   
   (  
   @SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
   @SchedEOProjectsId, @SchedBlockedStarvedId  
   )  
  AND td.scheduleid is not null   
  THEN datediff (  
       ss,  
       case   
       when td.StartTime <= pdr.StartTime_Product  
       and td.EndTime > pdr.StartTime_Product  
       then pdr.Starttime_Product  
       when td.StartTime > pdr.StartTime_Product  
       and td.StartTime < pdr.EndTime_Product  
       then td.StartTime  
       else null  
       end,  
       case   
       when td.StartTime < pdr.EndTime_Product  
       and td.EndTime >= pdr.EndTime_Product  
       then pdr.Endtime_Product  
       when td.EndTime > pdr.StartTime_Product  
       and td.EndTime < pdr.EndTime_Product  
       then td.EndTime  
       else null  
       end  
       )   
  ELSE 0.0  
  END  
  ) / 60.0 SchedMins_Product,  
  
 SUM(  
  CASE   
  when  pdr.Fresh = 1  
  and  td.Stops = 1  
  and td.starttime >= pdr.starttime_product  
  and (td.starttime < pdr.endtime_product or pdr.endtime_product is null)  
and td.CategoryId = @CatELPId  
  THEN  1   
  ELSE  0   
  END  
  ) FreshStops_Product,  
  
 sum(  
  case  
  when pdr.Fresh = 1  
  and td.starttime >= pdr.starttime_product  
  and (td.starttime < pdr.endtime_product or pdr.endtime_product is null)  
  and td.CategoryId = @CatELPId  
  then (coalesce(td.Downtime,0.0) + coalesce(td.ReportRLDowntime,0.0))   
  else 0.0  
  end  
  ) / 60.0 FreshMins_Product,  
  
 SUM(  
  CASE   
  when  pdr.Fresh = 0  
  and  td.Stops = 1  
  and td.starttime >= pdr.starttime_product  
  and (td.starttime < pdr.endtime_product or pdr.endtime_product is null)  
and td.CategoryId = @CatELPId  
  THEN  1   
  ELSE  0   
  END  
  ) StorageStops_Product,  
  
 sum(  
  case  
  when pdr.Fresh = 0  
  and td.starttime >= pdr.starttime_product  
  and (td.starttime < pdr.endtime_product or pdr.endtime_product is null)  
  and td.CategoryId = @CatELPId  
  then (coalesce(td.Downtime,0.0) + coalesce(td.ReportRLDowntime,0.0))   
  else 0.0  
  end  
  ) / 60.0 StorageMins_Product,  
  
  
 sum(  
  case  
  when pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Perfect'   
  and td.starttime >= pdr.starttime_Product  
  and (td.starttime < pdr.endtime_Product or pdr.endtime_Product is null)  
  and td.CategoryId = @CatELPId  
  then (coalesce(td.Downtime,0.0) + coalesce(td.ReportRLDowntime,0.0))   
  else 0.0  
  end  
  ) / 60.0 FreshPerfectELPMin_Product,  
  
 sum(  
  case  
  when pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Flagged'  
  and td.starttime >= pdr.starttime_Product  
  and (td.starttime < pdr.endtime_Product or pdr.endtime_Product is null)  
  and td.CategoryId = @CatELPId  
  then (coalesce(td.Downtime,0.0) + coalesce(td.ReportRLDowntime,0.0))   
  else 0.0  
  end  
  ) / 60.0 FreshFlaggedELPMin_Product,  
  
 sum(  
  case  
  when pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Hold'  
  and td.starttime >= pdr.starttime_Product  
  and (td.starttime < pdr.endtime_Product or pdr.endtime_Product is null)  
  and td.CategoryId = @CatELPId  
  then (coalesce(td.Downtime,0.0) + coalesce(td.ReportRLDowntime,0.0))   
  else 0.0  
  end  
  ) / 60.0 FreshRejHoldELPMin_Product,  
  
  SUM(  
   CASE   
   WHEN td.ScheduleId NOT IN   
     (  
     @SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
      @SchedEOProjectsId, @SchedBlockedStarvedId  
     )  
   and td.scheduleid is not null   
   and pdr.Fresh = 1  
   THEN datediff (  
        ss,  
        case   
        when td.StartTime <= pdr.StartTime_Product  
        and td.EndTime > pdr.StartTime_Product  
        then pdr.Starttime_Product  
        when td.StartTime > pdr.StartTime_Product  
        and td.StartTime < pdr.EndTime_Product  
        then td.StartTime  
        else null  
        end,  
        case   
        when td.StartTime < pdr.EndTime_Product  
        and td.EndTime >= pdr.EndTime_Product  
        then pdr.Endtime_Product  
        when td.EndTime > pdr.StartTime_Product  
        and td.EndTime < pdr.EndTime_Product  
        then td.EndTime  
        else null  
        end  
        )   
   ELSE 0.0  
   END  
   ) / 60.0 FreshSchedDT_Product,  
  
   SUM(  
   CASE   
   WHEN td.ScheduleId NOT IN   
     (  
     @SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
      @SchedEOProjectsId, @SchedBlockedStarvedId  
     )  
   and td.scheduleid is not null   
   and pdr.Fresh = 0  
   THEN datediff (  
        ss,  
        case   
        when td.StartTime <= pdr.StartTime_Product  
        and td.EndTime > pdr.StartTime_Product  
        then pdr.Starttime_Product  
        when td.StartTime > pdr.StartTime_Product  
        and td.StartTime < pdr.EndTime_Product  
        then td.StartTime  
        else null  
        end,  
        case   
        when td.StartTime < pdr.EndTime_Product  
        and td.EndTime >= pdr.EndTime_Product  
        then pdr.Endtime_Product  
        when td.EndTime > pdr.StartTime_Product  
        and td.EndTime < pdr.EndTime_Product  
        then td.EndTime  
        else null  
        end  
        )   
   ELSE 0.0  
   END  
   ) / 60.0 StorageSchedDT_Product,  
  
  SUM(  
   CASE   
   WHEN td.ScheduleId NOT IN   
     (  
     @SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
      @SchedEOProjectsId, @SchedBlockedStarvedId  
     )  
   and td.scheduleid is not null   
   and pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Perfect'  
   THEN datediff (  
        ss,  
        case   
        when td.StartTime <= pdr.StartTime_Product  
        and td.EndTime > pdr.StartTime_Product  
        then pdr.Starttime_Product  
        when td.StartTime > pdr.StartTime_Product  
        and td.StartTime < pdr.EndTime_Product  
        then td.StartTime  
        else null  
        end,  
        case   
        when td.StartTime < pdr.EndTime_Product  
        and td.EndTime >= pdr.EndTime_Product  
        then pdr.Endtime_Product  
        when td.EndTime > pdr.StartTime_Product  
        and td.EndTime < pdr.EndTime_Product  
        then td.EndTime  
        else null  
        end  
        )   
   ELSE 0.0  
   END  
   ) / 60.0 FreshPerfectSchedDT_Product,  
  
  
  SUM(  
   CASE   
   WHEN td.ScheduleId NOT IN   
     (  
     @SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
      @SchedEOProjectsId, @SchedBlockedStarvedId  
     )  
   and td.scheduleid is not null   
   and pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Flagged'  
   THEN datediff (  
        ss,  
        case   
        when td.StartTime <= pdr.StartTime_Product  
        and td.EndTime > pdr.StartTime_Product  
        then pdr.Starttime_Product  
        when td.StartTime > pdr.StartTime_Product  
        and td.StartTime < pdr.EndTime_Product  
        then td.StartTime  
        else null  
        end,  
        case   
        when td.StartTime < pdr.EndTime_Product  
        and td.EndTime >= pdr.EndTime_Product  
        then pdr.Endtime_Product  
        when td.EndTime > pdr.StartTime_Product  
        and td.EndTime < pdr.EndTime_Product  
        then td.EndTime  
        else null  
        end  
        )   
   ELSE 0.0  
   END  
   ) / 60.0 FreshFlaggedSchedDT_Product,  
  
  SUM(  
   CASE   
   WHEN td.ScheduleId NOT IN   
     (  
     @SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
      @SchedEOProjectsId, @SchedBlockedStarvedId  
     )  
   and td.scheduleid is not null   
   and pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Hold'  
   THEN datediff (  
        ss,  
        case   
        when td.StartTime <= pdr.StartTime_Product  
        and td.EndTime > pdr.StartTime_Product  
        then pdr.Starttime_Product  
        when td.StartTime > pdr.StartTime_Product  
        and td.StartTime < pdr.EndTime_Product  
        then td.StartTime  
        else null  
        end,  
        case   
        when td.StartTime < pdr.EndTime_Product  
        and td.EndTime >= pdr.EndTime_Product  
        then pdr.Endtime_Product  
        when td.EndTime > pdr.StartTime_Product  
        and td.EndTime < pdr.EndTime_Product  
        then td.EndTime  
        else null  
        end  
        )   
   ELSE 0.0  
   END  
   ) / 60.0 FreshRejHoldSchedDT_Product,  
  
 SUM(  
  CASE   
  when  td.Stops = 1  
  and td.starttime >= pdr.starttime_product  
  and (td.starttime < pdr.endtime_product or pdr.endtime_product is null)  
and td.CategoryId = @CatELPId  
  THEN  1   
  ELSE  0   
  END  
  ) TotalStops_Product,  
  
 sum(  
  case  
  when td.starttime >= pdr.starttime_product  
  and (td.starttime < pdr.endtime_product or pdr.endtime_product is null)  
  and td.CategoryId = @CatELPId  
  then (coalesce(td.Downtime,0.0) + coalesce(td.ReportRLDowntime,0.0))   
  else 0.0  
  end  
  ) / 60.0 TotalMins_Product,  
  
 SUM  
  (  
  CASE   
  WHEN td.ScheduleId NOT IN   
   (  
   @SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
   @SchedEOProjectsId, @SchedBlockedStarvedId  
   )  
  AND td.scheduleid is not null   
  THEN datediff (  
       ss,  
       case   
       when td.StartTime <= pdr.StartTime_ProductTeam  
       and td.EndTime > pdr.StartTime_ProductTeam  
       then pdr.Starttime_ProductTeam  
       when td.StartTime > pdr.StartTime_ProductTeam  
       and td.StartTime < pdr.EndTime_ProductTeam  
       then td.StartTime  
       else null  
       end,  
       case   
       when td.StartTime < pdr.EndTime_ProductTeam  
       and td.EndTime >= pdr.EndTime_ProductTeam  
       then pdr.Endtime_ProductTeam  
       when td.EndTime > pdr.StartTime_ProductTeam  
       and td.EndTime < pdr.EndTime_ProductTeam  
       then td.EndTime  
       else null  
       end  
       )   
  ELSE 0.0  
  END  
  ) / 60.0 SchedMins_ProductTeam,  
  
 SUM(  
  CASE   
  when  pdr.Fresh = 1  
  and  td.Stops = 1  
  and td.starttime >= pdr.starttime_productTeam  
  and (td.starttime < pdr.endtime_productTeam or pdr.endtime_productTeam is null)  
and td.CategoryId = @CatELPId  
  THEN  1   
  ELSE  0   
  END  
  ) FreshStops_ProductTeam,  
  
 sum(  
  case  
  when pdr.Fresh = 1  
  and td.starttime >= pdr.starttime_productTeam  
  and (td.starttime < pdr.endtime_productTeam or pdr.endtime_productTeam is null)  
  and td.CategoryId = @CatELPId  
  then (coalesce(td.Downtime,0.0) + coalesce(td.ReportRLDowntime,0.0))   
  else 0.0  
  end  
  )  / 60.0 FreshMins_ProductTeam,  
  
 SUM(  
  CASE   
  when  pdr.Fresh = 0  
  and  td.Stops = 1  
  and td.starttime >= pdr.starttime_productTeam  
  and (td.starttime < pdr.endtime_productTeam or pdr.endtime_productTeam is null)  
and td.CategoryId = @CatELPId  
  THEN  1   
  ELSE  0   
  END  
  ) StorageStops_ProductTeam,  
  
 sum(  
  case  
  when pdr.Fresh = 0  
  and td.starttime >= pdr.starttime_productTeam  
  and (td.starttime < pdr.endtime_productTeam or pdr.endtime_productTeam is null)  
  and td.CategoryId = @CatELPId  
  then (coalesce(td.Downtime,0.0) + coalesce(td.ReportRLDowntime,0.0))   
  else 0.0  
  end  
  ) / 60.0 StorageMins_ProductTeam,  
  
 sum(  
  case  
  when pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Perfect'   
  and td.starttime >= pdr.starttime_ProductTeam  
  and (td.starttime < pdr.endtime_ProductTeam or pdr.endtime_ProductTeam is null)  
  and td.CategoryId = @CatELPId  
  then (coalesce(td.Downtime,0.0) + coalesce(td.ReportRLDowntime,0.0))   
  else 0.0  
  end  
  ) / 60.0 FreshPerfectELPMin_ProductTeam,  
  
 sum(  
  case  
  when pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Flagged'  
  and td.starttime >= pdr.starttime_ProductTeam  
  and (td.starttime < pdr.endtime_ProductTeam or pdr.endtime_ProductTeam is null)  
  and td.CategoryId = @CatELPId  
  then (coalesce(td.Downtime,0.0) + coalesce(td.ReportRLDowntime,0.0))   
  else 0.0  
  end  
  ) / 60.0 FreshFlaggedELPMin_ProductTeam,  
  
 sum(  
  case  
  when pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Hold'  
  and td.starttime >= pdr.starttime_ProductTeam  
  and (td.starttime < pdr.endtime_ProductTeam or pdr.endtime_ProductTeam is null)  
  and td.CategoryId = @CatELPId  
  then (coalesce(td.Downtime,0.0) + coalesce(td.ReportRLDowntime,0.0))   
  else 0.0  
  end  
  ) / 60.0 FreshRejHoldELPMin_ProductTeam,  
  
  SUM(  
   CASE   
   WHEN td.ScheduleId NOT IN   
     (  
     @SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
      @SchedEOProjectsId, @SchedBlockedStarvedId  
     )  
   and td.scheduleid is not null   
   and pdr.Fresh = 1  
   THEN datediff (  
        ss,  
        case   
        when td.StartTime <= pdr.StartTime_ProductTeam  
        and td.EndTime > pdr.StartTime_ProductTeam  
        then pdr.Starttime_ProductTeam  
        when td.StartTime > pdr.StartTime_ProductTeam  
        and td.StartTime < pdr.EndTime_ProductTeam  
        then td.StartTime  
        else null  
        end,  
        case   
        when td.StartTime < pdr.EndTime_ProductTeam  
        and td.EndTime >= pdr.EndTime_ProductTeam  
        then pdr.Endtime_ProductTeam  
        when td.EndTime > pdr.StartTime_ProductTeam  
        and td.EndTime < pdr.EndTime_ProductTeam  
        then td.EndTime  
        else null  
        end  
        )   
   ELSE 0.0  
   END  
   ) / 60.0 FreshSchedDT_ProductTeam,  
  
   SUM(  
   CASE   
   WHEN td.ScheduleId NOT IN   
     (  
     @SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
      @SchedEOProjectsId, @SchedBlockedStarvedId  
     )  
   and td.scheduleid is not null   
   and pdr.Fresh = 0  
   THEN datediff (  
        ss,  
        case   
        when td.StartTime <= pdr.StartTime_ProductTeam  
        and td.EndTime > pdr.StartTime_ProductTeam  
        then pdr.Starttime_ProductTeam  
        when td.StartTime > pdr.StartTime_ProductTeam  
        and td.StartTime < pdr.EndTime_ProductTeam  
        then td.StartTime  
        else null  
        end,  
        case   
        when td.StartTime < pdr.EndTime_ProductTeam  
        and td.EndTime >= pdr.EndTime_ProductTeam  
        then pdr.Endtime_ProductTeam  
        when td.EndTime > pdr.StartTime_ProductTeam  
        and td.EndTime < pdr.EndTime_ProductTeam  
        then td.EndTime  
        else null  
        end  
        )   
   ELSE 0.0  
   END  
   ) / 60.0 StorageSchedDT_ProductTeam,  
  
  SUM(  
   CASE   
   WHEN td.ScheduleId NOT IN   
     (  
     @SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
      @SchedEOProjectsId, @SchedBlockedStarvedId  
     )  
   and td.scheduleid is not null   
   and pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Perfect'  
   THEN datediff (  
        ss,  
        case   
        when td.StartTime <= pdr.StartTime_ProductTeam  
        and td.EndTime > pdr.StartTime_ProductTeam  
        then pdr.Starttime_ProductTeam  
        when td.StartTime > pdr.StartTime_ProductTeam  
        and td.StartTime < pdr.EndTime_ProductTeam  
        then td.StartTime  
        else null  
        end,  
        case   
        when td.StartTime < pdr.EndTime_ProductTeam  
        and td.EndTime >= pdr.EndTime_ProductTeam  
        then pdr.Endtime_ProductTeam  
        when td.EndTime > pdr.StartTime_ProductTeam  
        and td.EndTime < pdr.EndTime_ProductTeam  
        then td.EndTime  
        else null  
        end  
        )   
   ELSE 0.0  
   END  
   ) / 60.0 FreshPerfectSchedDT_ProductTeam,  
  
  SUM(  
   CASE   
   WHEN td.ScheduleId NOT IN   
     (  
     @SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
      @SchedEOProjectsId, @SchedBlockedStarvedId  
     )  
   and td.scheduleid is not null   
   and pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Flagged'  
   THEN datediff (  
        ss,  
        case   
        when td.StartTime <= pdr.StartTime_ProductTeam  
        and td.EndTime > pdr.StartTime_ProductTeam  
        then pdr.Starttime_ProductTeam  
        when td.StartTime > pdr.StartTime_ProductTeam  
        and td.StartTime < pdr.EndTime_ProductTeam  
        then td.StartTime  
        else null  
        end,  
        case   
        when td.StartTime < pdr.EndTime_ProductTeam  
        and td.EndTime >= pdr.EndTime_ProductTeam  
        then pdr.Endtime_ProductTeam  
        when td.EndTime > pdr.StartTime_ProductTeam  
        and td.EndTime < pdr.EndTime_ProductTeam  
        then td.EndTime  
        else null  
        end  
        )   
   ELSE 0.0  
   END  
   ) / 60.0 FreshFlaggedSchedDT_ProductTeam,  
  
  SUM(  
   CASE   
   WHEN td.ScheduleId NOT IN   
     (  
     @SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
      @SchedEOProjectsId, @SchedBlockedStarvedId  
     )  
   and td.scheduleid is not null   
   and pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Hold'  
   THEN datediff (  
        ss,  
        case   
        when td.StartTime <= pdr.StartTime_ProductTeam  
        and td.EndTime > pdr.StartTime_ProductTeam  
        then pdr.Starttime_ProductTeam  
        when td.StartTime > pdr.StartTime_ProductTeam  
        and td.StartTime < pdr.EndTime_ProductTeam  
        then td.StartTime  
        else null  
        end,  
        case   
        when td.StartTime < pdr.EndTime_ProductTeam  
        and td.EndTime >= pdr.EndTime_ProductTeam  
        then pdr.Endtime_ProductTeam  
        when td.EndTime > pdr.StartTime_ProductTeam  
        and td.EndTime < pdr.EndTime_ProductTeam  
        then td.EndTime  
        else null  
        end  
        )   
   ELSE 0.0  
   END  
   ) / 60.0 FreshRejHoldSchedDT_ProductTeam,  
  
 SUM(  
  CASE   
  when  td.Stops = 1  
  and td.starttime >= pdr.starttime_productTeam  
  and (td.starttime < pdr.endtime_productTeam or pdr.endtime_productTeam is null)  
and td.CategoryId = @CatELPId  
  THEN  1   
  ELSE  0   
  END  
  ) TotalStops_ProductTeam,  
  
 sum(  
  case  
  when td.starttime >= pdr.starttime_productTeam  
  and (td.starttime < pdr.endtime_productTeam or pdr.endtime_productTeam is null)  
  and td.CategoryId = @CatELPId  
  then (coalesce(td.Downtime,0.0) + coalesce(td.ReportRLDowntime,0.0))   
  else 0.0  
  end  
  ) / 60.0 TotalMins_ProductTeam  
  
FROM dbo.#PRDTProducts pdr with (nolock)  
join @prodlines pl  
on pdr.puid = pl.prodpuid  
left join dbo.#delays td with (nolock)  
on (pl.reliabilitypuid = td.puid or pl.ratelosspuid = td.puid)  
and td.starttime < pdr.endtime   
and td.endtime > pdr.starttime   
left JOIN @ProdUnits tpu   
ON td.PUId = tpu.PUId  
WHERE pdr.Product <> 'NoAssignedPRID'   
group by pdr.id_num, pdr.plid, pdr.product, pdr.team, pdr.fresh  
  
  
--Rev8.51  
insert @PRDTTeamMetrics  
 (  
 id_num,  
 PLID,  
 Team,  
 Fresh,  
  
 SchedMins_Team,  
 FreshStops_Team,  
 FreshMins_Team,  
 StorageStops_Team,  
 StorageMins_Team,  
 FreshPerfectELPMin_Team,  
 FreshFlaggedELPMin_Team,  
 FreshRejHoldELPMin_Team,  
 FreshSchedDT_Team,  
 StorageSchedDT_Team,  
 FreshPerfectSchedDT_Team,  
 FreshFlaggedSchedDT_Team,  
 FreshRejHoldSchedDT_Team,  
 TotalStops_Team,  
 TotalMins_Team  
  
 )  
  
select  
  
 pdr.id_num,  
 pdr.plid,  
 pdr.Team,  
 pdr.Fresh,  
  
 SUM  
  (  
  CASE   
  WHEN td.ScheduleId NOT IN   
   (  
   @SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
   @SchedEOProjectsId, @SchedBlockedStarvedId  
   )  
  AND td.scheduleid is not null   
  THEN datediff (  
       ss,  
       case   
       when td.StartTime <= pdr.StartTime_Team  
       and td.EndTime > pdr.StartTime_Team  
       then pdr.Starttime_Team  
       when td.StartTime > pdr.StartTime_Team  
       and td.StartTime < pdr.EndTime_Team  
       then td.StartTime  
       else null  
       end,  
       case   
       when td.StartTime < pdr.EndTime_Team  
       and td.EndTime >= pdr.EndTime_Team  
       then pdr.Endtime_Team  
       when td.EndTime > pdr.StartTime_Team  
       and td.EndTime < pdr.EndTime_Team  
       then td.EndTime  
       else null  
       end  
       )   
  ELSE 0.0  
  END  
  ) / 60.0 SchedMins_Team,  
  
 SUM(  
  CASE   
  when  pdr.Fresh = 1  
  and  td.Stops = 1  
  and td.starttime >= pdr.starttime_Team  
  and (td.starttime < pdr.endtime_Team or pdr.endtime_Team is null)  
and td.CategoryId = @CatELPId  
  THEN  1   
  ELSE  0   
  END  
  ) FreshStops_Team,  
  
 sum(  
  case  
  when pdr.Fresh = 1  
  and td.starttime >= pdr.starttime_Team  
  and (td.starttime < pdr.endtime_Team or pdr.endtime_Team is null)  
  and td.CategoryId = @CatELPId  
  then (coalesce(td.Downtime,0.0) + coalesce(td.ReportRLDowntime,0.0))   
  else 0.0  
  end  
  )  / 60.0 FreshMins_Team,  
  
 SUM(  
  CASE   
  when  pdr.Fresh = 0  
  and  td.Stops = 1  
  and td.starttime >= pdr.starttime_Team  
  and (td.starttime < pdr.endtime_Team or pdr.endtime_Team is null)  
and td.CategoryId = @CatELPId  
  THEN  1   
  ELSE  0   
  END  
  ) StorageStops_Team,  
  
 sum(  
  case  
  when pdr.Fresh = 0  
  and td.starttime >= pdr.starttime_Team  
  and (td.starttime < pdr.endtime_Team or pdr.endtime_Team is null)  
  and td.CategoryId = @CatELPId  
  then (coalesce(td.Downtime,0.0) + coalesce(td.ReportRLDowntime,0.0))   
  else 0.0  
  end  
  ) / 60.0 StorageMins_Team,  
  
 sum(  
  case  
  when pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Perfect'   
  and td.starttime >= pdr.starttime_Team  
  and (td.starttime < pdr.endtime_Team or pdr.endtime_Team is null)  
  and td.CategoryId = @CatELPId  
  then (coalesce(td.Downtime,0.0) + coalesce(td.ReportRLDowntime,0.0))   
  else 0.0  
  end  
  ) / 60.0 FreshPerfectELPMin_Team,  
  
 sum(  
  case  
  when pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Flagged'  
  and td.starttime >= pdr.starttime_Team  
  and (td.starttime < pdr.endtime_Team or pdr.endtime_Team is null)  
  and td.CategoryId = @CatELPId  
  then (coalesce(td.Downtime,0.0) + coalesce(td.ReportRLDowntime,0.0))   
  else 0.0  
  end  
  ) / 60.0 FreshFlaggedELPMin_Team,  
  
 sum(  
  case  
  when pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Hold'  
  and td.starttime >= pdr.starttime_Team  
  and (td.starttime < pdr.endtime_Team or pdr.endtime_Team is null)  
  and td.CategoryId = @CatELPId  
  then (coalesce(td.Downtime,0.0) + coalesce(td.ReportRLDowntime,0.0))   
  else 0.0  
  end  
  ) / 60.0 FreshRejHoldELPMin_Team,  
  
  SUM(  
   CASE   
   WHEN td.ScheduleId NOT IN   
     (  
     @SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
      @SchedEOProjectsId, @SchedBlockedStarvedId  
     )  
   and td.scheduleid is not null   
   and pdr.Fresh = 1  
   THEN datediff (  
        ss,  
        case   
        when td.StartTime <= pdr.StartTime_Team  
        and td.EndTime > pdr.StartTime_Team  
        then pdr.Starttime_Team  
        when td.StartTime > pdr.StartTime_Team  
        and td.StartTime < pdr.EndTime_Team  
        then td.StartTime  
        else null  
        end,  
        case   
        when td.StartTime < pdr.EndTime_Team  
        and td.EndTime >= pdr.EndTime_Team  
        then pdr.Endtime_Team  
        when td.EndTime > pdr.StartTime_Team  
        and td.EndTime < pdr.EndTime_Team  
        then td.EndTime  
        else null  
        end  
        )   
   ELSE 0.0  
   END  
   ) / 60.0 FreshSchedDT_Team,  
  
   SUM(  
   CASE   
   WHEN td.ScheduleId NOT IN   
     (  
     @SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
      @SchedEOProjectsId, @SchedBlockedStarvedId  
     )  
   and td.scheduleid is not null   
   and pdr.Fresh = 0  
   THEN datediff (  
        ss,  
        case   
        when td.StartTime <= pdr.StartTime_Team  
        and td.EndTime > pdr.StartTime_Team  
        then pdr.Starttime_Team  
        when td.StartTime > pdr.StartTime_Team  
        and td.StartTime < pdr.EndTime_Team  
        then td.StartTime  
        else null  
        end,  
        case   
        when td.StartTime < pdr.EndTime_Team  
        and td.EndTime >= pdr.EndTime_Team  
        then pdr.Endtime_Team  
        when td.EndTime > pdr.StartTime_Team  
        and td.EndTime < pdr.EndTime_Team  
        then td.EndTime  
        else null  
        end  
        )   
   ELSE 0.0  
   END  
   ) / 60.0 StorageSchedDT_Team,  
  
  SUM(  
   CASE   
   WHEN td.ScheduleId NOT IN   
     (  
     @SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
      @SchedEOProjectsId, @SchedBlockedStarvedId  
     )  
   and td.scheduleid is not null   
   and pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Perfect'  
   THEN datediff (  
        ss,  
        case   
        when td.StartTime <= pdr.StartTime_Team  
        and td.EndTime > pdr.StartTime_Team  
        then pdr.Starttime_Team  
        when td.StartTime > pdr.StartTime_Team  
        and td.StartTime < pdr.EndTime_Team  
        then td.StartTime  
        else null  
        end,  
        case   
        when td.StartTime < pdr.EndTime_Team  
        and td.EndTime >= pdr.EndTime_Team  
        then pdr.Endtime_Team  
        when td.EndTime > pdr.StartTime_Team  
        and td.EndTime < pdr.EndTime_Team  
        then td.EndTime  
        else null  
        end  
        )   
   ELSE 0.0  
   END  
   ) / 60.0 FreshPerfectSchedDT_Team,  
  
  SUM(  
   CASE   
   WHEN td.ScheduleId NOT IN   
     (  
     @SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
      @SchedEOProjectsId, @SchedBlockedStarvedId  
     )  
   and td.scheduleid is not null   
   and pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Flagged'  
   THEN datediff (  
        ss,  
        case   
        when td.StartTime <= pdr.StartTime_Team  
        and td.EndTime > pdr.StartTime_Team  
        then pdr.Starttime_Team  
        when td.StartTime > pdr.StartTime_Team  
        and td.StartTime < pdr.EndTime_Team  
        then td.StartTime  
        else null  
        end,  
        case   
        when td.StartTime < pdr.EndTime_Team  
        and td.EndTime >= pdr.EndTime_Team  
        then pdr.Endtime_Team  
        when td.EndTime > pdr.StartTime_Team  
        and td.EndTime < pdr.EndTime_Team  
        then td.EndTime  
        else null  
        end  
        )   
   ELSE 0.0  
   END  
   ) / 60.0 FreshFlaggedSchedDT_Team,  
  
  SUM(  
   CASE   
   WHEN td.ScheduleId NOT IN   
     (  
     @SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
      @SchedEOProjectsId, @SchedBlockedStarvedId  
     )  
   and td.scheduleid is not null   
   and pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Hold'  
   THEN datediff (  
        ss,  
        case   
        when td.StartTime <= pdr.StartTime_Team  
        and td.EndTime > pdr.StartTime_Team  
        then pdr.Starttime_Team  
        when td.StartTime > pdr.StartTime_Team  
        and td.StartTime < pdr.EndTime_Team  
        then td.StartTime  
        else null  
        end,  
        case   
        when td.StartTime < pdr.EndTime_Team  
        and td.EndTime >= pdr.EndTime_Team  
        then pdr.Endtime_Team  
        when td.EndTime > pdr.StartTime_Team  
        and td.EndTime < pdr.EndTime_Team  
        then td.EndTime  
        else null  
        end  
        )   
   ELSE 0.0  
   END  
   ) / 60.0 FreshRejHoldSchedDT_Team,  
  
 SUM(  
  CASE   
  when  td.Stops = 1  
  and td.starttime >= pdr.starttime_Team  
  and (td.starttime < pdr.endtime_Team or pdr.endtime_Team is null)  
and td.CategoryId = @CatELPId  
  THEN  1   
  ELSE  0   
  END  
  ) TotalStops_Team,  
  
 sum(  
  case  
  when td.starttime >= pdr.starttime_Team  
  and (td.starttime < pdr.endtime_Team or pdr.endtime_Team is null)  
  and td.CategoryId = @CatELPId  
  then (coalesce(td.Downtime,0.0) + coalesce(td.ReportRLDowntime,0.0))   
  else 0.0  
  end  
  ) / 60.0 TotalMins_Team  
  
FROM dbo.#PRDTTeams pdr with (nolock)  
join @prodlines pl  
on pdr.puid = pl.prodpuid  
left join dbo.#delays td with (nolock)  
on (pl.reliabilitypuid = td.puid or pl.ratelosspuid = td.puid)  
and td.starttime < pdr.endtime   
and td.endtime > pdr.starttime   
left JOIN @ProdUnits tpu   
ON td.PUId = tpu.PUId  
group by pdr.id_num, pdr.plid, pdr.team, pdr.fresh  
  
  
--print 'Runtime metrics' + ' ' + convert(varchar(25),current_timestamp,108)  
  
update pdm set  
  
 FreshRuntime_Product =  
  CASE   
  WHEN pdr.Fresh = 1  
  then  
  DATEDIFF(ss,    
     CASE   
     WHEN pdr.StartTime_Product < @Report_Start_Time   
     THEN @Report_Start_Time   
     ELSE pdr.StartTime_Product  
     END,  
     CASE   
     WHEN pdr.EndTime_Product > @Report_End_Time   
     THEN @Report_End_Time   
     ELSE pdr.EndTime_Product  
     END  
    )  
  ELSE 0.0  
  END / 60.0,  
  
 StorageRuntime_Product =  
  CASE   
  WHEN pdr.Fresh = 0  
  then  
  DATEDIFF(ss,    
     CASE   
     WHEN pdr.StartTime_Product < @Report_Start_Time   
     THEN @Report_Start_Time   
     ELSE pdr.StartTime_Product  
     END,  
     CASE   
     WHEN pdr.EndTime_Product > @Report_End_Time   
     THEN @Report_End_Time   
     ELSE pdr.EndTime_Product  
     END  
    )  
  ELSE 0.0  
  END / 60.0,  
  
 OverallRuntime_Product =  
  DATEDIFF(ss,    
     CASE   
     WHEN pdr.StartTime_Product < @Report_Start_Time   
     THEN @Report_Start_Time   
     ELSE pdr.StartTime_Product  
     END,  
     CASE   
     WHEN pdr.EndTime_Product > @Report_End_Time  
     THEN @Report_End_Time   
     ELSE pdr.EndTime_Product  
     END  
    ) / 60.0,  
  
 FreshPerfectRuntime_Product =  
  CASE   
  when pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Perfect'  
  then  
  DATEDIFF(ss,    
     CASE   
     WHEN pdr.StartTime_Product < @Report_Start_Time   
     THEN @Report_Start_Time   
     ELSE pdr.StartTime_Product  
     END,  
     CASE   
     WHEN pdr.EndTime_Product > @Report_End_Time   
     THEN @Report_End_Time   
     ELSE pdr.EndTime_Product  
     END  
    )  
  ELSE 0.0  
  END / 60.0,  
  
 FreshFlaggedRuntime_Product =   
  CASE   
  when pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Flagged'  
  then  
  DATEDIFF(ss,    
     CASE   
     WHEN pdr.StartTime_Product < @Report_Start_Time   
     THEN @Report_Start_Time   
     ELSE pdr.StartTime_Product  
     END,  
     CASE   
     WHEN pdr.EndTime_Product > @Report_End_Time   
     THEN @Report_End_Time   
     ELSE pdr.EndTime_Product  
     END  
    )  
  ELSE 0.0  
  END / 60.0,  
  
 FreshRejHoldRuntime_Product =  
  CASE   
  when pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Hold'  
  then  
  DATEDIFF(ss,    
     CASE   
     WHEN pdr.StartTime_Product < @Report_Start_Time   
     THEN @Report_Start_Time   
     ELSE pdr.StartTime_Product  
     END,  
     CASE   
     WHEN pdr.EndTime_Product > @Report_End_Time   
     THEN @Report_End_Time   
     ELSE pdr.EndTime_Product  
     END  
    )  
  ELSE 0.0  
  END / 60.0,  
  
 FreshRuntime_ProductTeam =  
  CASE   
  WHEN pdr.Fresh = 1  
  then  
  DATEDIFF(ss,    
     CASE   
     WHEN pdr.StartTime_ProductTeam < @Report_Start_Time   
     THEN @Report_Start_Time   
     ELSE pdr.StartTime_ProductTeam  
     END,  
     CASE   
     WHEN pdr.EndTime_ProductTeam > @Report_End_Time   
     THEN @Report_End_Time   
     ELSE pdr.EndTime_ProductTeam  
     END  
    )  
  ELSE 0.0  
  END / 60.0,  
  
 StorageRuntime_ProductTeam =  
  CASE   
  WHEN pdr.Fresh = 0  
  then  
  DATEDIFF(ss,    
     CASE   
     WHEN pdr.StartTime_ProductTeam < @Report_Start_Time   
     THEN @Report_Start_Time   
     ELSE pdr.StartTime_ProductTeam  
     END,  
     CASE   
     WHEN pdr.EndTime_ProductTeam > @Report_End_Time   
     THEN @Report_End_Time   
     ELSE pdr.EndTime_ProductTeam  
     END  
    )  
  ELSE 0.0  
  END / 60.0,  
  
 OverallRuntime_ProductTeam =  
  DATEDIFF(ss,    
     CASE   
     WHEN pdr.StartTime_ProductTeam < @Report_Start_Time   
     THEN @Report_Start_Time   
     ELSE pdr.StartTime_ProductTeam  
     END,  
     CASE   
     WHEN pdr.EndTime_ProductTeam > @Report_End_Time   
     THEN @Report_End_Time   
     ELSE pdr.EndTime_ProductTeam  
     END  
    ) / 60.0,  
  
 FreshPerfectRuntime_ProductTeam =  
  CASE   
  when pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Perfect'  
  then  
  DATEDIFF(ss,    
     CASE   
     WHEN pdr.StartTime_ProductTeam < @Report_Start_Time   
     THEN @Report_Start_Time   
     ELSE pdr.StartTime_ProductTeam  
     END,  
     CASE   
     WHEN pdr.EndTime_ProductTeam > @Report_End_Time   
     THEN @Report_End_Time   
     ELSE pdr.EndTime_ProductTeam  
     END  
    )  
  ELSE 0.0  
  END / 60.0,  
  
  
 FreshFlaggedRuntime_ProductTeam =  
  CASE   
  when pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Flagged'  
  then  
  DATEDIFF(ss,    
     CASE   
     WHEN pdr.StartTime_ProductTeam < @Report_Start_Time   
     THEN @Report_Start_Time   
     ELSE pdr.StartTime_ProductTeam  
     END,  
     CASE   
     WHEN pdr.EndTime_ProductTeam > @Report_End_Time   
     THEN @Report_End_Time   
     ELSE pdr.EndTime_ProductTeam  
     END  
    )  
  ELSE 0.0  
  END / 60.0,  
  
 FreshRejHoldRuntime_ProductTeam =  
  CASE   
  when pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Hold'  
  then  
  DATEDIFF(ss,    
     CASE   
     WHEN pdr.StartTime_ProductTeam < @Report_Start_Time   
     THEN @Report_Start_Time   
     ELSE pdr.StartTime_ProductTeam  
     END,  
     CASE   
     WHEN pdr.EndTime_ProductTeam > @Report_End_Time   
     THEN @Report_End_Time   
     ELSE pdr.EndTime_ProductTeam  
     END  
    )  
  ELSE 0.0  
  END / 60.0   
  
from @PRDTProductMetrics pdm  
join dbo.#PRDTProducts pdr with (nolock)  
on pdm.id_num = pdr.id_num  
WHERE pdr.Product <> 'NoAssignedPRID'  
  
  
--/*  
--print 'more runtime metrics' + ' ' + convert(varchar(25),current_timestamp,108)  
  
update pdr set  
  
 Runtime_Product =  
  DATEDIFF(ss,    
     CASE   
     WHEN pdr.StartTime_Product < @Report_Start_Time   
     THEN @Report_Start_Time   
     ELSE pdr.StartTime_Product  
     END,  
     CASE   
     WHEN pdr.EndTime_Product > @Report_End_Time  
     THEN @Report_End_Time   
     ELSE pdr.EndTime_Product  
     END  
    ) / 60.0,  
  
 Runtime_ProductTeam =  
  DATEDIFF(ss,    
     CASE   
     WHEN pdr.StartTime_ProductTeam < @Report_Start_Time   
     THEN @Report_Start_Time   
     ELSE pdr.StartTime_ProductTeam  
     END,  
     CASE   
     WHEN pdr.EndTime_ProductTeam > @Report_End_Time  
     THEN @Report_End_Time   
     ELSE pdr.EndTime_ProductTeam  
     END  
    ) / 60.0  
  
from dbo.#PRDTProducts pdr with (nolock)  
WHERE pdr.Product <> 'NoAssignedPRID'  
--*/  
  
  
--print 'Runtime metrics' + ' ' + convert(varchar(25),current_timestamp,108)  
  
--Rev8.51  
update pdm set  
  
 FreshRuntime_Team =  
  CASE   
  WHEN pdr.Fresh = 1    then  
  DATEDIFF(ss,    
     CASE   
     WHEN pdr.StartTime_Team < @Report_Start_Time   
     THEN @Report_Start_Time   
     ELSE pdr.StartTime_Team  
     END,  
     CASE   
     WHEN pdr.EndTime_Team > @Report_End_Time   
     THEN @Report_End_Time   
     ELSE pdr.EndTime_Team  
     END  
    )  
  ELSE 0.0  
  END / 60.0,  
  
 StorageRuntime_Team =  
  CASE   
  WHEN pdr.Fresh = 0  
  then  
  DATEDIFF(ss,    
     CASE   
     WHEN pdr.StartTime_Team < @Report_Start_Time   
     THEN @Report_Start_Time   
     ELSE pdr.StartTime_Team  
     END,  
     CASE   
     WHEN pdr.EndTime_Team > @Report_End_Time   
     THEN @Report_End_Time   
     ELSE pdr.EndTime_Team  
     END  
    )  
  ELSE 0.0  
  END / 60.0,  
  
 OverallRuntime_Team =  
  DATEDIFF(ss,    
     CASE   
     WHEN pdr.StartTime_Team < @Report_Start_Time   
     THEN @Report_Start_Time   
     ELSE pdr.StartTime_Team  
     END,  
     CASE   
     WHEN pdr.EndTime_Team > @Report_End_Time   
     THEN @Report_End_Time   
     ELSE pdr.EndTime_Team  
     END  
    ) / 60.0,  
  
 FreshPerfectRuntime_Team =  
  CASE   
  when pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Perfect'  
  then  
  DATEDIFF(ss,    
     CASE   
     WHEN pdr.StartTime_Team < @Report_Start_Time   
     THEN @Report_Start_Time   
     ELSE pdr.StartTime_Team  
     END,  
     CASE   
     WHEN pdr.EndTime_Team > @Report_End_Time   
     THEN @Report_End_Time   
     ELSE pdr.EndTime_Team  
     END  
    )  
  ELSE 0.0  
  END / 60.0,  
  
  
 FreshFlaggedRuntime_Team =  
  CASE   
  when pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Flagged'  
  then  
  DATEDIFF(ss,    
     CASE   
     WHEN pdr.StartTime_Team < @Report_Start_Time   
     THEN @Report_Start_Time   
     ELSE pdr.StartTime_Team  
     END,  
     CASE   
     WHEN pdr.EndTime_Team > @Report_End_Time   
     THEN @Report_End_Time   
     ELSE pdr.EndTime_Team  
     END  
    )  
  ELSE 0.0  
  END / 60.0,  
  
 FreshRejHoldRuntime_Team =  
  CASE   
  when pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Hold'  
  then  
  DATEDIFF(ss,    
     CASE   
     WHEN pdr.StartTime_Team < @Report_Start_Time   
     THEN @Report_Start_Time   
     ELSE pdr.StartTime_Team  
     END,  
     CASE   
     WHEN pdr.EndTime_Team > @Report_End_Time   
     THEN @Report_End_Time   
     ELSE pdr.EndTime_Team  
     END  
    )  
  ELSE 0.0  
  END / 60.0   
  
from @PRDTTeamMetrics pdm  
join dbo.#PRDTTeams pdr with (nolock)  
on pdm.id_num = pdr.id_num  
  
  
--/*  
--print 'more runtime metrics' + ' ' + convert(varchar(25),current_timestamp,108)  
  
--Rev8.51  
update pdr set  
  
 Runtime_Team =  
  DATEDIFF(ss,    
     CASE   
     WHEN pdr.StartTime_Team < @Report_Start_Time   
     THEN @Report_Start_Time   
     ELSE pdr.StartTime_Team  
     END,  
     CASE   
     WHEN pdr.EndTime_Team > @Report_End_Time  
     THEN @Report_End_Time   
     ELSE pdr.EndTime_Team  
     END  
    ) / 60.0  
  
from dbo.#PRDTTeams pdr with (nolock)  
--*/  
  
  
  
--print 'Line metrics' + ' ' + convert(varchar(25),current_timestamp,108)  
  
insert @PRDTLineMetrics  
 (  
 id_num,  
 PLID,  
 prPLID,  
 Fresh,  
  
 SchedMins_Line,  
 FreshStops_Line,  
 FreshMins_Line,  
 StorageStops_Line,  
 StorageMins_Line,  
 FreshPerfectELPMin_Line,  
 FreshFlaggedELPMin_Line,  
 FreshRejHoldELPMin_Line,  
 FreshSchedDT_Line,  
 StorageSchedDT_Line,  
 FreshPerfectSchedDT_Line,  
 FreshFlaggedSchedDT_Line,  
 FreshRejHoldSchedDT_Line,  
 TotalStops_Line,  
 TotalMins_Line  
  
 )  
  
select  
  
 pdr.id_num,  
 pdr.plid,  
 pdr.prplid,  
 pdr.Fresh,  
  
 SUM  
  (  
  CASE   
  WHEN td.ScheduleId NOT IN   
   (  
   @SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
   @SchedEOProjectsId, @SchedBlockedStarvedId  
   )  
  AND td.scheduleid is not null   
  THEN datediff (  
       ss,  
       case   
       when td.StartTime <= pdr.StartTime_Line  
       and td.EndTime > pdr.StartTime_Line  
       then pdr.Starttime_Line  
       when td.StartTime > pdr.StartTime_Line  
       and td.StartTime < pdr.EndTime_Line  
       then td.StartTime  
       else null  
       end,  
       case   
       when td.StartTime < pdr.EndTime_Line  
       and td.EndTime >= pdr.EndTime_Line  
       then pdr.Endtime_Line  
       when td.EndTime > pdr.StartTime_Line  
       and td.EndTime < pdr.EndTime_Line  
       then td.EndTime  
       else null  
       end  
       )   
  ELSE 0.0  
  END  
  ) / 60.0 SchedMins_Line,  
  
 SUM(  
  CASE   
  when  pdr.Fresh = 1  
  and  td.Stops = 1  
  and td.starttime >= pdr.starttime_Line  
  and (td.starttime < pdr.endtime_Line or pdr.endtime_Line is null)  
and td.CategoryId = @CatELPId  
  THEN  1   
  ELSE  0   
  END  
  ) FreshStops_Line,  
  
 sum(  
  case  
  when pdr.Fresh = 1  
  and td.starttime >= pdr.starttime_Line  
  and (td.starttime < pdr.endtime_Line or pdr.endtime_Line is null)  
  and td.CategoryId = @CatELPId  
  then (coalesce(td.Downtime,0.0) + coalesce(td.ReportRLDowntime,0.0))   
  else 0.0  
  end  
  ) / 60.0 FreshMins_Line,  
  
 SUM(  
  CASE   
  when  pdr.Fresh = 0  
  and  td.Stops = 1  
  and td.starttime >= pdr.starttime_Line  
  and (td.starttime < pdr.endtime_Line or pdr.endtime_Line is null)  
and td.CategoryId = @CatELPId  
  THEN  1   
  ELSE  0   
  END  
  ) StorageStops_Line,  
  
 sum(  
  case  
  when pdr.Fresh = 0  
  and td.starttime >= pdr.starttime_Line  
  and (td.starttime < pdr.endtime_Line or pdr.endtime_Line is null)  
  and td.CategoryId = @CatELPId  
  then (coalesce(td.Downtime,0.0) + coalesce(td.ReportRLDowntime,0.0))   
  else 0.0  
  end  
  ) / 60.0 StorageMins_Line,  
  
  
 sum(  
  case  
  when pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Perfect'   
  and td.starttime >= pdr.starttime_Line  
  and (td.starttime < pdr.endtime_Line or pdr.endtime_Line is null)  
  and td.CategoryId = @CatELPId  
  then (coalesce(td.Downtime,0.0) + coalesce(td.ReportRLDowntime,0.0))   
  else 0.0  
  end  
  ) / 60.0 FreshPerfectELPMin_Line,  
  
 sum(  
  case  
  when pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Flagged'  
  and td.starttime >= pdr.starttime_Line  
  and (td.starttime < pdr.endtime_Line or pdr.endtime_Line is null)  
  and td.CategoryId = @CatELPId  
  then (coalesce(td.Downtime,0.0) + coalesce(td.ReportRLDowntime,0.0))   
  else 0.0  
  end  
  ) / 60.0 FreshFlaggedELPMin_Line,  
  
 sum(  
  case  
  when pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Hold'  
  and td.starttime >= pdr.starttime_Line  
  and (td.starttime < pdr.endtime_Line or pdr.endtime_Line is null)  
  and td.CategoryId = @CatELPId  
  then (coalesce(td.Downtime,0.0) + coalesce(td.ReportRLDowntime,0.0))   
  else 0.0  
  end  
  ) / 60.0 FreshRejHoldELPMin_Line,  
  
  SUM(  
   CASE   
   WHEN td.ScheduleId NOT IN   
     (  
     @SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
      @SchedEOProjectsId, @SchedBlockedStarvedId  
     )  
   and td.scheduleid is not null   
   and pdr.Fresh = 1  
   THEN datediff (  
        ss,  
        case   
        when td.StartTime <= pdr.StartTime_Line  
        and td.EndTime > pdr.StartTime_Line  
        then pdr.Starttime_Line  
        when td.StartTime > pdr.StartTime_Line  
        and td.StartTime < pdr.EndTime_Line  
        then td.StartTime  
        else null  
        end,  
        case   
        when td.StartTime < pdr.EndTime_Line  
        and td.EndTime >= pdr.EndTime_Line  
        then pdr.Endtime_Line  
        when td.EndTime > pdr.StartTime_Line  
        and td.EndTime < pdr.EndTime_Line  
        then td.EndTime  
        else null  
        end  
        )   
   ELSE 0.0  
   END  
   ) / 60.0 FreshSchedDT_Line,  
  
   SUM(  
   CASE   
   WHEN td.ScheduleId NOT IN   
     (  
     @SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
      @SchedEOProjectsId, @SchedBlockedStarvedId  
     )  
   and td.scheduleid is not null   
   and pdr.Fresh = 0  
   THEN datediff (  
        ss,  
        case   
        when td.StartTime <= pdr.StartTime_Line  
        and td.EndTime > pdr.StartTime_Line  
        then pdr.Starttime_Line  
        when td.StartTime > pdr.StartTime_Line  
        and td.StartTime < pdr.EndTime_Line  
        then td.StartTime  
        else null  
        end,  
        case   
        when td.StartTime < pdr.EndTime_Line  
        and td.EndTime >= pdr.EndTime_Line  
        then pdr.Endtime_Line  
        when td.EndTime > pdr.StartTime_Line  
        and td.EndTime < pdr.EndTime_Line  
        then td.EndTime  
        else null  
        end  
        )   
   ELSE 0.0  
   END  
   ) / 60.0 StorageSchedDT_Line,  
  
  SUM(  
   CASE   
   WHEN td.ScheduleId NOT IN   
     (  
     @SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
      @SchedEOProjectsId, @SchedBlockedStarvedId  
     )  
   and td.scheduleid is not null   
   and pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Perfect'  
   THEN datediff (  
        ss,  
        case   
        when td.StartTime <= pdr.StartTime_Line  
        and td.EndTime > pdr.StartTime_Line  
        then pdr.Starttime_Line  
        when td.StartTime > pdr.StartTime_Line  
        and td.StartTime < pdr.EndTime_Line  
        then td.StartTime  
        else null  
        end,  
        case   
        when td.StartTime < pdr.EndTime_Line  
        and td.EndTime >= pdr.EndTime_Line  
        then pdr.Endtime_Line  
        when td.EndTime > pdr.StartTime_Line  
        and td.EndTime < pdr.EndTime_Line  
        then td.EndTime  
        else null  
        end  
        )   
   ELSE 0.0  
   END  
   ) / 60.0 FreshPerfectSchedDT_Line,  
  
  
  SUM(  
   CASE   
   WHEN td.ScheduleId NOT IN   
     (  
     @SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
      @SchedEOProjectsId, @SchedBlockedStarvedId  
     )  
   and td.scheduleid is not null   
   and pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Flagged'  
   THEN datediff (  
        ss,  
        case   
        when td.StartTime <= pdr.StartTime_Line  
        and td.EndTime > pdr.StartTime_Line  
        then pdr.Starttime_Line  
        when td.StartTime > pdr.StartTime_Line  
        and td.StartTime < pdr.EndTime_Line  
        then td.StartTime  
        else null  
        end,  
        case   
        when td.StartTime < pdr.EndTime_Line  
        and td.EndTime >= pdr.EndTime_Line  
        then pdr.Endtime_Line  
        when td.EndTime > pdr.StartTime_Line  
        and td.EndTime < pdr.EndTime_Line  
        then td.EndTime  
        else null  
        end  
        )   
   ELSE 0.0  
   END  
   ) / 60.0 FreshFlaggedSchedDT_Line,  
  
  SUM(  
   CASE   
   WHEN td.ScheduleId NOT IN   
     (  
     @SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
      @SchedEOProjectsId, @SchedBlockedStarvedId  
     )  
   and td.scheduleid is not null   
   and pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Hold'  
   THEN datediff (  
        ss,  
        case   
        when td.StartTime <= pdr.StartTime_Line  
        and td.EndTime > pdr.StartTime_Line  
        then pdr.Starttime_Line  
        when td.StartTime > pdr.StartTime_Line  
        and td.StartTime < pdr.EndTime_Line  
        then td.StartTime  
        else null  
        end,  
        case   
        when td.StartTime < pdr.EndTime_Line  
        and td.EndTime >= pdr.EndTime_Line  
        then pdr.Endtime_Line  
        when td.EndTime > pdr.StartTime_Line  
        and td.EndTime < pdr.EndTime_Line  
        then td.EndTime  
        else null  
        end  
        )   
   ELSE 0.0  
   END  
   ) / 60.0 FreshRejHoldSchedDT_Line,  
  
 SUM(  
  CASE   
  when  td.Stops = 1  
  and td.starttime >= pdr.starttime_Line  
  and (td.starttime < pdr.endtime_Line or pdr.endtime_Line is null)  
and td.CategoryId = @CatELPId  
  THEN  1   
  ELSE  0   
  END  
  ) TotalStops_Line,  
  
 sum(  
  case  
  when td.starttime >= pdr.starttime_Line  
  and (td.starttime < pdr.endtime_Line or pdr.endtime_Line is null)  
  and td.CategoryId = @CatELPId  
  then (coalesce(td.Downtime,0.0) + coalesce(td.ReportRLDowntime,0.0))   
  else 0.0  
  end  
  ) / 60.0 TotalMins_Line  
  
FROM dbo.#PRDTLine pdr with (nolock)  
join @prodlines pl  
on pdr.puid = pl.prodpuid  
left join dbo.#delays td with (nolock)  
on (pl.reliabilitypuid = td.puid or pl.ratelosspuid = td.puid)  
and td.starttime < pdr.endtime  
and td.endtime > pdr.starttime  
left JOIN @ProdUnits tpu   
ON td.PUId = tpu.PUId  
group by pdr.id_num, pdr.plid, pdr.prplid, pdr.fresh  
  
  
update pdm set  
  
 FreshRuntime_Line =  
  CASE   
  WHEN pdr.Fresh = 1  
  then  
  DATEDIFF(ss,    
     CASE   
     WHEN pdr.StartTime_Line < @Report_Start_Time   
     THEN @Report_Start_Time   
     ELSE pdr.StartTime_Line  
     END,  
     CASE   
     WHEN pdr.EndTime_Line > @Report_End_Time   
     THEN @Report_End_Time   
     ELSE pdr.EndTime_Line  
     END  
    )  
  ELSE 0.0  
  END / 60.0,  
  
 StorageRuntime_Line =  
  CASE   
  WHEN pdr.Fresh = 0  
  then  
  DATEDIFF(ss,    
     CASE   
     WHEN pdr.StartTime_Line < @Report_Start_Time   
     THEN @Report_Start_Time   
     ELSE pdr.StartTime_Line  
     END,  
     CASE   
     WHEN pdr.EndTime_Line > @Report_End_Time   
     THEN @Report_End_Time   
     ELSE pdr.EndTime_Line  
     END  
    )  
  ELSE 0.0  
  END / 60.0,  
  
 OverallRuntime_Line =  
  DATEDIFF(ss,    
     CASE   
     WHEN pdr.StartTime_Line < @Report_Start_Time   
     THEN @Report_Start_Time   
     ELSE pdr.StartTime_Line  
     END,  
     CASE   
     WHEN pdr.EndTime_Line > @Report_End_Time  
     THEN @Report_End_Time   
     ELSE pdr.EndTime_Line  
     END  
    ) / 60.0,  
  
 FreshPerfectRuntime_Line =  
  CASE   
  when pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Perfect'  
  then  
  DATEDIFF(ss,    
     CASE   
     WHEN pdr.StartTime_Line < @Report_Start_Time   
     THEN @Report_Start_Time   
     ELSE pdr.StartTime_Line  
     END,  
     CASE   
     WHEN pdr.EndTime_Line > @Report_End_Time   
     THEN @Report_End_Time   
     ELSE pdr.EndTime_Line  
     END  
    )  
  ELSE 0.0  
  END / 60.0,  
  
 FreshFlaggedRuntime_Line =   
  CASE   
  when pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Flagged'  
  then  
  DATEDIFF(ss,    
     CASE   
     WHEN pdr.StartTime_Line < @Report_Start_Time   
     THEN @Report_Start_Time   
     ELSE pdr.StartTime_Line  
     END,  
     CASE   
     WHEN pdr.EndTime_Line > @Report_End_Time   
     THEN @Report_End_Time   
     ELSE pdr.EndTime_Line  
     END  
    )  
  ELSE 0.0  
  END / 60.0,  
  
 FreshRejHoldRuntime_Line =  
  CASE   
  when pdr.Fresh = 1 AND pdr.PerfectPRStatus = 'Hold'  
  then  
  DATEDIFF(ss,    
     CASE   
     WHEN pdr.StartTime_Line < @Report_Start_Time   
     THEN @Report_Start_Time   
     ELSE pdr.StartTime_Line  
     END,  
     CASE   
     WHEN pdr.EndTime_Line > @Report_End_Time   
     THEN @Report_End_Time   
     ELSE pdr.EndTime_Line  
     END  
    )  
  ELSE 0.0  
  END / 60.0  
  
from @PRDTLineMetrics pdm  
join dbo.#PRDTLine pdr with (nolock)  
on pdm.id_num = pdr.id_num  
WHERE pdm.plid > -1  
  
  
--/*  
update pdr set  
  
 Runtime_Line =  
  DATEDIFF(ss,    
     CASE   
     WHEN pdr.StartTime_Line < @Report_Start_Time   
     THEN @Report_Start_Time   
     ELSE pdr.StartTime_Line  
     END,  
     CASE   
     WHEN pdr.EndTime_Line > @Report_End_Time  
     THEN @Report_End_Time   
     ELSE pdr.EndTime_Line  
     END  
    ) / 60.0  
  
from dbo.#PRDTLine pdr with (nolock)  
--*/  
  
  
--print 'reason sums' + ' ' + convert(varchar(25),current_timestamp,108)  
  
--Rev8.51  
IF @RptIncludeTeam = 2  
  
Insert Into @ELPReasonSums   
 (   
 Product,  
 Team,          
 Fresh,  
 Stops,  
 Minutes,  
 FreshPerfectELPMin,  
 FreshFlaggedELPMin,  
 FreshRejHoldELPMin,  
 Reason_Name  
 )  
Select    
  
 'ALL', --pdm.Product,  
 pdm.Team,           
 pdm.Fresh,          
  
 sum(pdm.Stops_ProdTeamFreshReasons),  
 sum(pdm.Minutes_ProdTeamFreshReasons),  
 sum(pdm.FreshPerfectELPMin_ProdTeamFreshReasons),  
 sum(pdm.FreshFlaggedELPMin_ProdTeamFreshReasons),  
 sum(pdm.FreshRejHoldELPMin_ProdTeamFreshReasons),  
  
 pdm.Reason_Name  
  
FROM @PRDTReasonMetrics pdm  
Group By pdm.Team, pdm.Fresh, pdm.Reason_Name   
OPTION (KEEP PLAN)  
  
else  
  
Insert Into @ELPReasonSums   
 (   
 Product,  
 Team,          
 Fresh,  
 Stops,  
 Minutes,  
 FreshPerfectELPMin,  
 FreshFlaggedELPMin,  
 FreshRejHoldELPMin,  
 Reason_Name  
 )  
Select    
  
 pdm.Product,  
 pdm.Team,           
 pdm.Fresh,          
  
 sum(pdm.Stops_ProdTeamFreshReasons),  
 sum(pdm.Minutes_ProdTeamFreshReasons),  
 sum(pdm.FreshPerfectELPMin_ProdTeamFreshReasons),  
 sum(pdm.FreshFlaggedELPMin_ProdTeamFreshReasons),  
 sum(pdm.FreshRejHoldELPMin_ProdTeamFreshReasons),  
  
 pdm.Reason_Name  
  
FROM @PRDTReasonMetrics pdm  
Group By pdm.Product, pdm.Team, pdm.Fresh, pdm.Reason_Name   
OPTION (KEEP PLAN)  
  
--/*  
Insert Into @ELPReasonSums   
 (  
 Product,  
 Team,          
 Fresh,  
 Stops,  
 Minutes,  
 FreshPerfectELPMin,  
 FreshFlaggedELPMin,  
 FreshRejHoldELPMin,  
 Reason_Name  
 )  
Select    
 'ALL',  
 'ALL',           
 pdm.Fresh,          
 sum(pdm.Stops_FreshReasons),  
 sum(pdm.Minutes_FreshReasons),  
 sum(pdm.FreshPerfectELPMin_FreshReasons),  
 sum(pdm.FreshFlaggedELPMin_FreshReasons),  
 sum(pdm.FreshRejHoldELPMin_FreshReasons),  
 Reason_Name  
FROM @PRDTReasonMetrics pdm   
Group By pdm.Fresh, pdm.Reason_Name  
OPTION (KEEP PLAN)  
--*/  
  
--------------------------------------------------------------------------------------------  
-- Summarize the ELP by product and reason.  
--------------------------------------------------------------------------------------------  
  
 INSERT INTO @ELPSummary  
  (  
  Product,  
  Team,  
  FreshStops,  
  FreshMins,  
  StorageStops,  
  StorageMins,  
  TotalStops,  
  TotalMins,  
  SchedMins,  
  FreshSchedDT,  
  StorageSchedDT,  
  FreshRuntime,  
  StorageRuntime,  
  OverallRuntime,  
  FreshPerfectELPMin,  
  FreshFlaggedELPMin,  
  FreshRejHoldELPMin,  
  FreshPerfectRuntime,  
  FreshFlaggedRuntime,  
  FreshRejHoldRuntime,  
  FreshPerfectSchedDT,  
  FreshFlaggedSchedDT,  
  FreshRejHoldSchedDT  
  )  
 select   
  'ALL',  
  'ALL',  
  sum(FreshStops_Line),  
  sum(FreshMins_Line),  
  sum(StorageStops_Line),  
  sum(StorageMins_Line),  
  sum(TotalStops_Line),  
  sum(TotalMins_Line),  
  sum(SchedMins_Line),  
  sum(FreshSchedDT_Line),  
  sum(StorageSchedDT_Line),  
  sum(FreshRuntime_Line),  
  sum(StorageRuntime_Line),  
  sum(OverallRuntime_Line),  
  sum(FreshPerfectELPMin_Line),  
  sum(FreshFlaggedELPMin_Line),  
  sum(FreshRejHoldELPMin_Line),  
  sum(FreshPerfectRuntime_Line),  
  sum(FreshFlaggedRuntime_Line),  
  sum(FreshRejHoldRuntime_Line),  
  sum(FreshPerfectSchedDT_Line),  
  sum(FreshFlaggedSchedDT_Line),  
  sum(FreshRejHoldSchedDT_Line)  
 from @PRDTLineMetrics pdm  
 OPTION (KEEP PLAN)  
  
  
  
IF @RptIncludeTeam = 1  
  
 INSERT INTO @ELPSummary  
  (  
  Product,  
  Team,  
  FreshStops,  
  FreshMins,  
  StorageStops,  
  StorageMins,  
  TotalStops,  
  TotalMins,  
  SchedMins,  
  FreshSchedDT,  
  StorageSchedDT,  
  FreshRuntime,  
  StorageRuntime,  
  OverallRuntime,  
  FreshPerfectELPMin,  
  FreshFlaggedELPMin,  
  FreshRejHoldELPMin,  
  FreshPerfectRuntime,  
  FreshFlaggedRuntime,  
  FreshRejHoldRuntime,  
  FreshPerfectSchedDT,  
  FreshFlaggedSchedDT,  
  FreshRejHoldSchedDT  
  )  
 select   
  Product,  
  Team,  
  sum(FreshStops_ProductTeam),  
  sum(FreshMins_ProductTeam),  
  sum(StorageStops_ProductTeam),  
  sum(StorageMins_ProductTeam),  
  sum(TotalStops_ProductTeam),  
  sum(TotalMins_ProductTeam),  
  sum(SchedMins_ProductTeam),  
  sum(FreshSchedDT_ProductTeam),  
  sum(StorageSchedDT_ProductTeam),  
  sum(FreshRuntime_ProductTeam),  
  sum(StorageRuntime_ProductTeam),  
  sum(OverallRuntime_ProductTeam),  
  sum(FreshPerfectELPMin_ProductTeam),  
  sum(FreshFlaggedELPMin_ProductTeam),  
  sum(FreshRejHoldELPMin_ProductTeam),  
  sum(FreshPerfectRuntime_ProductTeam),  
  sum(FreshFlaggedRuntime_ProductTeam),  
  sum(FreshRejHoldRuntime_ProductTeam),  
  sum(FreshPerfectSchedDT_ProductTeam),  
  sum(FreshFlaggedSchedDT_ProductTeam),  
  sum(FreshRejHoldSchedDT_ProductTeam)  
 from @PRDTProductMetrics pdm  
 WHERE Product <> 'NoAssignedPRID'   
 group by Product, Team  
 order by Product, Team  
 OPTION (KEEP PLAN)  
  
else  
  
--Rev8.51  
IF @RptIncludeTeam = 2  
--/*  
 INSERT INTO @ELPSummary  
  (  
  Product,  
  Team,  
  FreshStops,  
  FreshMins,  
  StorageStops,  
  StorageMins,  
  TotalStops,  
  TotalMins,  
  SchedMins,  
  FreshSchedDT,  
  StorageSchedDT,  
  FreshRuntime,  
  StorageRuntime,  
  OverallRuntime,  
  FreshPerfectELPMin,  
  FreshFlaggedELPMin,  
  FreshRejHoldELPMin,  
  FreshPerfectRuntime,  
  FreshFlaggedRuntime,  
  FreshRejHoldRuntime,  
  FreshPerfectSchedDT,  
  FreshFlaggedSchedDT,  
  FreshRejHoldSchedDT  
  )  
 select   
  'ALL',  
  Team,  
  sum(FreshStops_Team),  
  sum(FreshMins_Team),  
  sum(StorageStops_Team),  
  sum(StorageMins_Team),  
  sum(TotalStops_Team),  
  sum(TotalMins_Team),  
  sum(SchedMins_Team),  
  sum(FreshSchedDT_Team),  
  sum(StorageSchedDT_Team),  
  sum(FreshRuntime_Team),  
  sum(StorageRuntime_Team),  
  sum(OverallRuntime_Team),  
  sum(FreshPerfectELPMin_Team),  
  sum(FreshFlaggedELPMin_Team),  
  sum(FreshRejHoldELPMin_Team),  
  sum(FreshPerfectRuntime_Team),  
  sum(FreshFlaggedRuntime_Team),  
  sum(FreshRejHoldRuntime_Team),  
  sum(FreshPerfectSchedDT_Team),  
  sum(FreshFlaggedSchedDT_Team),  
  sum(FreshRejHoldSchedDT_Team)  
 from @PRDTTeamMetrics pdm  
 group by Team  
 order by Team  
 OPTION (KEEP PLAN)  
--*/  
  
else  
  
 INSERT INTO @ELPSummary  
  (  
  Product,  
  Team,  
  FreshStops,  
  FreshMins,  
  StorageStops,  
  StorageMins,  
  TotalStops,  
  TotalMins,  
  SchedMins,  
  FreshSchedDT,  
  StorageSchedDT,  
  FreshRuntime,  
  StorageRuntime,  
  OverallRuntime,  
  FreshPerfectELPMin,  
  FreshFlaggedELPMin,  
  FreshRejHoldELPMin,  
  FreshPerfectRuntime,  
  FreshFlaggedRuntime,  
  FreshRejHoldRuntime,  
  FreshPerfectSchedDT,  
  FreshFlaggedSchedDT,  
  FreshRejHoldSchedDT  
  )  
 select   
  Product,  
  'ALL',  
  sum(FreshStops_Product),  
  sum(FreshMins_Product),  
  sum(StorageStops_Product),  
  sum(StorageMins_Product),  
  sum(TotalStops_Product),  
  sum(TotalMins_Product),  
  sum(SchedMins_Product),  
  sum(FreshSchedDT_Product),  
  sum(StorageSchedDT_Product),  
  sum(FreshRuntime_Product),  
  sum(StorageRuntime_Product),  
  sum(OverallRuntime_Product),  
  sum(FreshPerfectELPMin_Product),  
  sum(FreshFlaggedELPMin_Product),  
  sum(FreshRejHoldELPMin_Product),  
  sum(FreshPerfectRuntime_Product),  
  sum(FreshFlaggedRuntime_Product),  
  sum(FreshRejHoldRuntime_Product),  
  sum(FreshPerfectSchedDT_Product),  
  sum(FreshFlaggedSchedDT_Product),  
  sum(FreshRejHoldSchedDT_Product)  
 from @PRDTProductMetrics pdm  
 WHERE Product <> 'NoAssignedPRID'   
 group by Product  
 order by Product  
 OPTION (KEEP PLAN)  
  
  
  -- update all ELP calculations based on data accumulated in @ELPSummary table.  
  update elps set  
   FreshPerfectELP = CASE WHEN (FreshPerfectRuntime - FreshPerfectSchedDT) > 0 THEN  
          (FreshPerfectELPMin) / (FreshPerfectRuntime - FreshPerfectSchedDT)  
         ELSE 0.0 END,  
   FreshFlaggedELP = CASE WHEN (FreshFlaggedRuntime - FreshFlaggedSchedDT) > 0 THEN  
          (FreshFlaggedELPMin) / (FreshFlaggedRuntime - FreshFlaggedSchedDT)  
         ELSE 0.0 END,  
   FreshRejHoldELP = CASE WHEN (FreshRejHoldRuntime - FreshRejHoldSchedDT) > 0 THEN  
          (FreshRejHoldELPMin) / (FreshRejHoldRuntime - FreshRejHoldSchedDT)  
         ELSE 0.0 END,  
   FreshOverallELP = CASE WHEN (FreshRuntime - FreshSchedDT) > 0 THEN  
          (FreshMins) / (FreshRuntime - FreshSchedDT)  
         ELSE 0.0 END,  
   StorageOverallELP =  CASE WHEN (StorageRuntime - StorageSchedDT) > 0 THEN  
           (StorageMins) / (StorageRuntime - StorageSchedDT)  
          ELSE 0.0 END,  
   OverallELP =  CASE WHEN (FreshRuntime + StorageRuntime - FreshSchedDT - StorageSchedDT) > 0 THEN  
         (FreshMins + StorageMins) / (FreshRuntime + StorageRuntime - FreshSchedDT - StorageSchedDT)  
        ELSE 0.0 END  
  FROM @ELPSummary elps  
  
  
--print 'fresh & storage' + ' ' + convert(varchar(25),current_timestamp,108)  
  
-- Get total Fresh Runtime and total Storage Runtime to be used in Top 5 Causes %Loss calc.  
  
--Rev8.51  
IF @RptIncludeTeam = 2  
  
begin  
  
SELECT @TotalFreshRuntime = COALESCE(FreshRuntime, 0.0)  
FROM @ELPSummary  
WHERE Team = 'ALL'  
OPTION (KEEP PLAN)  
  
SELECT @TotalStorageRuntime = COALESCE(StorageRuntime, 0.0)  
FROM @ELPSummary  
WHERE Team = 'ALL'  
OPTION (KEEP PLAN)  
  
end  
  
else  
  
begin  
  
SELECT @TotalFreshRuntime = COALESCE(FreshRuntime, 0.0)  
FROM @ELPSummary  
WHERE Product = 'ALL'  
OPTION (KEEP PLAN)  
  
SELECT @TotalStorageRuntime = COALESCE(StorageRuntime, 0.0)  
FROM @ELPSummary  
WHERE Product = 'ALL'  
OPTION (KEEP PLAN)  
  
end  
  
  
--------------------------------------------------------------------------------------  
-- get results  
--------------------------------------------------------------------------------------  
  
--select * from @ELPSummary  
--select * from #PRDTProducts  
  
--select * from dbo.#PRDTTeams  
  
-- select 'prsrun',  
--  id_num, starttime, endtime, pdr.*  
-- from #prsrun pdr  
-- order by puid, starttime, endtime, peiid, input_order  
  
  
--select 'PUsRunningPRs', * from @PUsRunningPRs  
  
--select 'prodlines', * from #prodlines  
--select 'produnits', * from @produnits  
  
--select 'events', *  
--from #events  
--order by event_id  
  
--select 'PRsRun', eventid, starttime, endtime   
--from dbo.#prsrun prs  
--where endtime > '2008-05-19 05:00:00'  
--and starttime < '2008-05-20 05:00:00'  
--and PRPUID > 0  
--and eventid is not null  
--order by eventid, peiid, starttime  
  
--select * from @UWS  
--select 'dimensions', pu.pu_desc, d.*   
  
--select '#Delays', *  
--from #Delays sd  
--order by puid, starttime  
  
--select '@prodlinesGP', * from @prodlinesGP  
--select '@ELPDelays', * from @ELPDelays  
--order by parent, puid, team, fresh, minutes  
  
--select 'PRDTReasons', * from @PRDTReasons  
--order by product, fresh, team, reason_name  
  
--select 'PRDTProducts', * from @PRDTProducts  
--where product = 'Bounty Mach IV 84x101x101'  
--and starttime_product <> endtime_product  
--order by plid, starttime_product, endtime_product, fresh, team  
  
--select 'PRDTReasonMetrics', * from @PRDTReasonMetrics  
--order by product, fresh, team, reason_name  
  
--select 'PRDTProductionMetrics', * from @PRDTProductMetrics  
--where plid = 33 and team = 'A'  
--order by plid, team, product, fresh, reason_name  
  
--select 'PRDTLine', * from dbo.#PRDTLine  
--where starttime_line <> endtime_line  
--order by reliabilitypuid, starttime_line, endtime_line, fresh  
--select 'PRDTLineMetrics', * from @PRDTLineMetrics  
  
--select 'ELPReasonSums', * from @ELPReasonSums  
--order by product, fresh, team, reason_name  
  
--select plid, product, sum(datediff(ss,starttime_product,endtime_product))/60.0  
--from @PRDTProducts pdm  
--where pdm.product = 'Bounty Mach IV 84x101x101'  
--group by plid, product  
  
--select 'ELPSummary', * from @ELPSummary  
  
  
  
ReturnResultSets:      
  
-- 2007-01-08 JSJ Rev8.24  
--if (select count(*) from @ErrorMessages) > 0   
  
if exists (select * from @ErrorMessages)   
  
select * from @ErrorMessages  
  
else -- no error messages exist  
  
begin  
  
 -- Result Set 1  
 select * from @ErrorMessages  
  
  
--Rev8.51  
IF @RptIncludeTeam = 2  
  
begin  
 -- Result Set 2  
 -- ELP Summary by Age for All Roll Statuses  
  
 INSERT INTO @ELPSumResultsTeam  
   SELECT  
    1,  
    Team,  
    '#Stops' [RowHdr],  
    STR(SUM(COALESCE(FreshStops,0)),5,0)    As Fresh,  
    STR(SUM(COALESCE(StorageStops,0)),5,0)    As Storage   
   from @ELPSummary   
   group by Team  
     
 UNION  
   
   SELECT  
    2,  
    Team,  
    'Minutes' [Minutes],  
    STR(SUM(COALESCE(FreshMins,0.0)),15,3)    As FreshMins,   
    STR(SUM(COALESCE(StorageMins,0.0)),15,3)   As StorageMins   
   from @ELPSummary   
   group by Team  
      
 UNION  
   
   SELECT  
    3,  
    Team,  
    'ELP%' [ELP%],  
    STR(SUM(COALESCE(FreshOverallELP*100, 0.0)),15,3)   AS FreshOverallELP,   
    STR(SUM(COALESCE(StorageOverallELP*100, 0.0)),15,3)  AS StorageOverallELP    
   from @ELPSummary  
   group by Team  
   
 SELECT  Team,  
     RowHdr,  
    Fresh,  
    Storage  
 FROM @ELPSumResultsTeam  
 ORDER BY len(team) desc, Team, SortOrder  
 OPTION (KEEP PLAN)  
   
 -- Result Set 3  
 -- Top 5 ELP Causes on Fresh Paper  
  
 SELECT TOP 5  
  Team          [Team],   
  Reason_Name        [Reason_Name],  
  Stops          [Stops],  
  Minutes         [Minutes],  
  case   
  when @TotalFreshRuntime = 0  
  then 0  
  else (Minutes / (@TotalFreshRuntime))*100.00   
  end           [PercentLoss]  
 FROM @ELPReasonSums  
 WHERE Team = 'ALL'  
  AND Fresh = 1  
 ORDER BY [PercentLoss] DESC, Stops DESC  
 OPTION (KEEP PLAN)  
   
 -- Result Set 4  
 -- Top 5 ELP Causes on Storage Paper  
  
 SELECT TOP 5  
  Team          [Team],   
  Reason_Name        [Reason_Name],  
  Stops          [Stops],  
  Minutes         [Minutes],  
  case  
  when @TotalStorageRuntime = 0  
  then 0  
  else (Minutes / (@TotalStorageRuntime))*100.00    
  end          [PercentLoss]  
 FROM @ELPReasonSums  
 WHERE Team = 'ALL'  
  AND Fresh = 0  
 ORDER BY [PercentLoss] DESC, Stops DESC  
 OPTION (KEEP PLAN)  
  
 -- Result Set 5  
 -- Top 5 Causes of Less Than Perfect Rolls  
 INSERT INTO @Top5CausesTeam (  
  Team,  
  Cause,   
  TestedRolls,  
  TotalFailures,     
--  NotPerfectRolls,  
  FlaggedRolls,  
  RejHoldRolls)    
 SELECT  Top 5  
    'ALL',  
    VarDesc,   
    SUM(Tested)              [TestedRolls],  
    SUM(Flagged) + SUM(RejectHold) [TotalFailures],     
--    SUM(NotPerfect) + SUM(Flagged) + SUM(RejectHold) [TotalFailures],     
--    SUM(NotPerfect)            [NotPerfectRolls],  
    SUM(Flagged)              [FlaggedRolls],  
    SUM(RejectHold)             [RejHoldRolls]    
 FROM dbo.#PerfectPRTests ppr with (nolock)  
 GROUP BY VarDesc  
 ORDER BY [TotalFailures] DESC, [RejHoldRolls] DESC, [FlaggedRolls] DESC, [TestedRolls] DESC  
 OPTION (KEEP PLAN)  
   
 SELECT  Team,  
    Cause,  
    TestedRolls,  
    TotalFailures,  
--    NotPerfectRolls,  
    FlaggedRolls,  
    RejHoldRolls  
 FROM @Top5CausesTeam  
 WHERE TotalFailures > 0  
   
 -- Result Set 6  
 -- ELP Summary Data  
  SELECT   
   'ALL' Product,    
   Team,   
   STR((COALESCE(FreshPerfectELP*100, 0.0)),15,3)   AS FreshPerfectELP,     
--   STR((COALESCE(FreshNotPerfELP*100, 0.0)),15,3)  AS FreshNotPerfELP,     
   STR((COALESCE(FreshFlaggedELP*100, 0.0)),15,3)   AS FreshFlaggedELP,     
   STR((COALESCE(FreshRejHoldELP*100, 0.0)),15,3)   AS FreshRejHoldELP,     
   STR((COALESCE(FreshOverallELP*100, 0.0)),15,3)   AS FreshOverallELP,     
   STR((COALESCE(StorageOverallELP*100, 0.0)),15,3)  AS StorageOverallELP,   
   STR((COALESCE(TotalStops, 0.0)),15,3)     AS TotalStopsElP,   
   STR((COALESCE(TotalMins, 0.0)),15,3)     AS TotalMinsELP,   
   STR((COALESCE(OverallELP*100, 0.0)),15,3)     AS OverallELP    
  from @ELPSummary   
  order by len(team) desc, Team  
  OPTION (KEEP PLAN)  
   
  
end -- @RptIncludeTeam = 2  
  
else -- @RptIncludeTeam <> 2  
  
begin  
   
 -- Result Set 2  
 -- ELP Summary by Age for All Roll Statuses  
  
 INSERT INTO @ELPSumResultsProduct  
   SELECT  
    1,  
    Product,  
    '#Stops' [RowHdr],  
    STR(SUM(COALESCE(FreshStops,0)),5,0)    As Fresh,  
    STR(SUM(COALESCE(StorageStops,0)),5,0)    As Storage   
   from @ELPSummary   
   group by Product  
     
 UNION  
   
   SELECT  
    2,  
    Product,  
    'Minutes' [Minutes],  
    STR(SUM(COALESCE(FreshMins,0.0)),15,3)    As FreshMins,   
    STR(SUM(COALESCE(StorageMins,0.0)),15,3)   As StorageMins   
   from @ELPSummary   
   group by Product  
      
 UNION  
   
   SELECT  
    3,  
    Product,  
    'ELP%' [ELP%],  
    STR(SUM(COALESCE(FreshOverallELP*100, 0.0)),15,3)   AS FreshOverallELP,   
    STR(SUM(COALESCE(StorageOverallELP*100, 0.0)),15,3)  AS StorageOverallELP    
   from @ELPSummary  
   group by Product  
   
 SELECT  Product,  
     RowHdr,  
    Fresh,  
    Storage  
 FROM @ELPSumResultsProduct  
 ORDER BY Product, SortOrder  
 OPTION (KEEP PLAN)  
   
 -- Result Set 3  
 -- Top 5 ELP Causes on Fresh Paper  
  
 SELECT TOP 5  
  Product         [Product],   
  Reason_Name        [Reason_Name],  
  Stops          [Stops],  
  Minutes         [Minutes],  
  case   
  when @TotalFreshRuntime = 0  
  then 0  
  else (Minutes / (@TotalFreshRuntime))*100.00   
  end           [PercentLoss]  
 FROM @ELPReasonSums  
 WHERE Product = 'ALL'  
  AND Fresh = 1  
 ORDER BY [PercentLoss] DESC, Stops DESC  
 OPTION (KEEP PLAN)  
   
 -- Result Set 4  
 -- Top 5 ELP Causes on Storage Paper  
  
 SELECT TOP 5  
  Product         [Product],   
  Reason_Name        [Reason_Name],  
  Stops          [Stops],  
  Minutes         [Minutes],  
  case  
  when @TotalStorageRuntime = 0  
  then 0  
  else (Minutes / (@TotalStorageRuntime))*100.00    
  end          [PercentLoss]  
 FROM @ELPReasonSums  
 WHERE Product = 'ALL'  
  AND Fresh = 0  
 ORDER BY [PercentLoss] DESC, Stops DESC  
 OPTION (KEEP PLAN)  
  
 -- Result Set 5  
 -- Top 5 Causes of Less Than Perfect Rolls  
 INSERT INTO @Top5CausesProduct (  
  Product,  
  Cause,   
  TestedRolls,  
  TotalFailures,     
--  NotPerfectRolls,  
  FlaggedRolls,  
  RejHoldRolls)    
 SELECT  Top 5  
    'ALL',  
    VarDesc,   
    SUM(Tested)              [TestedRolls],  
    SUM(Flagged) + SUM(RejectHold) [TotalFailures],     
--    SUM(NotPerfect) + SUM(Flagged) + SUM(RejectHold) [TotalFailures],     
--    SUM(NotPerfect)            [NotPerfectRolls],  
    SUM(Flagged)              [FlaggedRolls],  
    SUM(RejectHold)             [RejHoldRolls]    
 FROM dbo.#PerfectPRTests ppr with (nolock)  
 GROUP BY VarDesc  
 ORDER BY [TotalFailures] DESC, [RejHoldRolls] DESC, [FlaggedRolls] DESC, [TestedRolls] DESC  
 OPTION (KEEP PLAN)  
   
 SELECT  Product,  
    Cause,  
    TestedRolls,  
    TotalFailures,  
--    NotPerfectRolls,  
    FlaggedRolls,  
    RejHoldRolls  
 FROM @Top5CausesProduct  
 WHERE TotalFailures > 0  
   
 -- Result Set 6  
 -- ELP Summary Data  
 IF @RptIncludeTeam = 1  
  SELECT   
   Product,    
   Team,   
   STR((COALESCE(FreshPerfectELP*100, 0.0)),15,3)   AS FreshPerfectELP,     
--   STR((COALESCE(FreshNotPerfELP*100, 0.0)),15,3)  AS FreshNotPerfELP,     
   STR((COALESCE(FreshFlaggedELP*100, 0.0)),15,3)   AS FreshFlaggedELP,     
   STR((COALESCE(FreshRejHoldELP*100, 0.0)),15,3)   AS FreshRejHoldELP,     
   STR((COALESCE(FreshOverallELP*100, 0.0)),15,3)   AS FreshOverallELP,     
   STR((COALESCE(StorageOverallELP*100, 0.0)),15,3)  AS StorageOverallELP,   
   STR((COALESCE(TotalStops, 0.0)),15,3)     AS TotalStopsElP,   
   STR((COALESCE(TotalMins, 0.0)),15,3)     AS TotalMinsELP,   
   STR((COALESCE(OverallELP*100, 0.0)),15,3)     AS OverallELP    
  from @ELPSummary   
  order by Product, Team  
  OPTION (KEEP PLAN)  
   
 ELSE  
   
  SELECT   
   Product,    
   'ALL' [Team],   
   STR((COALESCE(FreshPerfectELP*100, 0.0)),15,3)   AS FreshPerfectELP,     
--   STR((COALESCE(FreshNotPerfELP*100, 0.0)),15,3)  AS FreshNotPerfELP,     
   STR((COALESCE(FreshFlaggedELP*100, 0.0)),15,3)   AS FreshFlaggedELP,     
   STR((COALESCE(FreshRejHoldELP*100, 0.0)),15,3)   AS FreshRejHoldELP,     
   STR((COALESCE(FreshOverallELP*100, 0.0)),15,3)   AS FreshOverallELP,     
   STR((COALESCE(StorageOverallELP*100, 0.0)),15,3)  AS StorageOverallELP,   
   STR((COALESCE(TotalStops, 0.0)),15,3)     AS TotalStopsELP,   
   STR((COALESCE(TotalMins, 0.0)),15,3)     AS TotalMinsELP,   
   STR((COALESCE(OverallELP*100, 0.0)),15,3)    AS OverallELP    
  from @ELPSummary   
  order by Product  
  OPTION (KEEP PLAN)  
  
end -- @RptIncludeTeam <> 2  
  
end -- no error messages found  
  
  
--print 'done' + ' ' + convert(varchar(25),current_timestamp,108)  
  
  
Finished:  
  
DROP TABLE dbo.#Delays  
DROP  TABLE dbo.#TECategories  
drop  table dbo.#tests   
drop table dbo.#events  
drop  table dbo.#ltec  
drop  table dbo.#PRsRun  
drop  table dbo.#PerfectPRTests  
drop  table dbo.#PRDTReasons   
drop  table dbo.#PRDTProducts  
drop table dbo.#PRDTLine  
drop  table dbo.#EventStatusTransitions  
drop  table dbo.#PRDTTeams  
  
  
RETURN  
