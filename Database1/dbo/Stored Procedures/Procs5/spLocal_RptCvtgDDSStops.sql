  
  
/*    
  
-- Last Changed: 2009-11-16 Jeff Jaeger Rev11.83  
  
------------------------------------------------------------------------------------------------------------------  
------------------------------------------------------------------------------------------------------------------  
This SP works with the template RptCvtgDDSStops.xlt. The SP provides as many as 14  
different result sets depending on the values of the following report parameters:  
@IncludeTeam -  Determines whether Stops and Production data on the DDS sheet  
      are broken out by Team or not.  1 = Include Team; 0 = No Team breakdown.  
@IncludeStops - Determines whether the Stops pivot table and additional Stops  sheets  
      are included in the report. 1 = Include Stops; 0 = Do not include Stops.  
@BySummary -   If @IncludeStops = 1, then this determines if the additional stops   
      sheets are included in the report. 1 = Include add'l sheets; 0 = do not include.  
------------------------------------------------------------------------------------------------------------------  
------------------------------------------------------------------------------------------------------------------  
--  Revision History:  
------------------------------------------------------------------------------------------------------------------  
2005-JUN-15 Jeff Jaeger  Rev9.99  
  Created this report as a rewrite of the existing spLocal_RptDDSStops.  The rewrite is intended to simply the code and   
  make it more efficient.  See previous versions of this stored procedure for outdated comments.  
  
2005-JUN-15 Jeff Jaeger  Rev10.00  
  1.) Removed the LineStatusList restriction from the population of LineStatus in the @Dimensions table and added that   
    restriction to the result sets, where appropriate.  
  2.) Removed the join to @Dimensions in the insert to @ActiveSpecs as it became redundant after a separate @Products  
    table was created.  
  3.) Reformatted the code to make it more readable.  
  4.) Moved the population of @UWS to ALTER  a more logical flow of activity in the procedure.  
  
2005-JUN-20 Langdon Davis Rev10.01  
  1.) Added a '/ 60.0' to all the calculations of 'PRC Downtime' to convert from seconds to minutes.  
  2.) Changed the name of the '@GroupCauseID' variable to '@PRCGroupCauseID' to be more specific/explanatory.  
  
2005-JUN-21 Jeff Jaeger  Rev10.02  
  In the result sets for #LineStops and #LineStops2, where @SQL has "order by " appended to it, the order by   
  clause has been removed.    
  
2005-JUN-23 Jeff Jaeger  Rev10.03  
  Added rounding to the calcs for ActualUnits, TargetUnits, IdealUnits, and OperationsTargetUnits.  
  
2005-JUN-27 Jeff Jaeger  Rev10.04  
  1.) Updated the assignment of TargetSpeed and IdealSpeed in @Runs.  
  2.)  Commented out all --print statements, as they end up in the error logs if an error gets generated.  
  3.) Updated the third insert to #TimedEventDetails.  As written is was inserting fields from the existing  
    #TimedEventDetails table, instead of inserting new records from outside of the report period.  
    (it was inserting from the alias ted2 instead of ted1)  
  4.) Updated the insert of LineStatus to the @Dimensions table.  It was set to select Endtimes that were   
    less than the starttime, which meant that the update to LineStatus in @runs would never select a   
    LineStatus value.  
  
2005-JUN-28 Jeff Jaeger  Rev10.05  
  Updated the definitions of PRCEvents.  As orginally written, the value was assigned a 0 or 1.  But   
  would cause a 1 to be assigned even for split events.  the correct assignment should be either 0 or  
  coalesce(stops,0).  In this way, we only assign 1 when we have an actual stop.  
  
2005-JUN-28 Jeff Jaeger  Rev10.06  
  Updated the LineStatus insert to @Dimensions to use end_datetime from the local table, instead of trying   
  to select the next start_datetime on a given unit.  
  
2005-JUN-29 Jeff Jaeger  Rev10.07  
  Updated the assignment of Average PRoll Change Time so that it is NULL instead of 0 if there is no value.  
  
2005-JUL-01 Langdon Davis Rev10.08  
  1.) Modified name of the line status list parameter to fit with convention.  
  2.) Simplified 'Uptime <2 Min. Not Holiday/Curtail' naming to just 'Stops with Uptime <2 Min'.  
  3.) Added 'Ideal Stat Cases' into the production results sets.  
  
2005-JUL-05 Langdon Davis Rev10.09  
  1.) Changed to default UWS1Parent to 'NO RUNNING PR' if there is no PRID associated with a Stop event.  This   
  makes it consistent with what is applied within Proficy to Rate Loss events.  
  2.) Added 'Line Status' changes to the comment that is applied to the artificial records to split uptime.  
  
2005-JUL-06 Langdon Davis Rev10.10  
  Changed 'Unscheduled Rpt DT' to 'Unscheduled Split DT' to be consistent with the earlier change of  
  'Reporting Downtime' to 'Split Downtime'.  
  
2005-JUL-07 Langdon Davis Rev10.11  
  Changed the COALESCE value on @LanguageID in Section 8 to -1 instead of 0.  With 0, it  
  was causing an English user's ID to get overridden by the site's language parameter value.  
  
2005-JUL-14 Langdon Davis Rev10.12  
  Incorp[orated the modifications for 4.x and modified to branch through code for Proficy  
  Version 4.x or Version 3.x depending on the App_Version value for the 'Database'   
  App_Name in the AppVersions table.  This gives us one set of code to use with either   
  4.x or 3.x.  
  
2005-JUL-22 Langdon Davis Rev10.13  
  Modified the population of Timed_Event_Details' Comments field in Section 28.  As originally written,   
  it was only pulling in comments that for events that had both a wtc_type= 1 comment AND a wtc_type=2   
  comment.  Events that had a comment for just one of the two types were getting nulled out by the NULL   
  value for the comment of the other type.  
    
2005-JUL-27 Vince King  Rev10.14  
  Neuss Hanky was not getting production data and calcs.  In Section 32 the production data from the Tests table was not  
  being loaded into the #Tests table.  Added another INSERT to pull variable data from Tests for variables in  
  the @LineProdVars table.  Once that change was made, started getting data conversion errors.    
  I found in Section 35 that the position of a COALESCE in a SELECT statement for an Update to GoodUnits in   
  the @ProdRecords table made a difference.  I had to change the position from:  
   Sum (convert(float,coalesce(Value,0))) to  Sum (coalesce(convert(float,Value), 0.0))  
  I was then not getting any data for GoodUnits and determined that the next SELECT statement which sums  
  data and adds it to the previous SELECT mentioned above was returning NULL.  SQL did not return anything  
  when this happened.  So I added a COALESCE to that SELECT and it corrected the problem.  
  
2005-AUG-18 Vince King  Rev10.15  
  DDS-Stops report for the larger plants were either taking entirely too much time or they would exceed the  
  timeout period when running for a month.  Especially for the AY AKxx DDS-Stops report for 1 month.  
  After extensive testing and trial and error, I found that there were problems related to the @Primaries table.  
  An update was being performed on @Primaries using the column TEPrimaryId in a JOIN.  TEPrimaryId was not indexed.  
  I noticed that when the SP ran, it would pause at this point and take an very long time to continue.  
  -- I changed the @Primaries table from a table variable to a temporary table and set the TEPrimaryId as a   
     clustered index.  Then I created a nonclustered index on the TEDETId.  I changed the code to reflect #Primaries  
   instead of @Primaries.  
  
2005-AUG-19 Langdon Davis Rev10.16  
  -  Changed #Primaries back to a table varialbe @Primaries, with the same indices defined on it as Vince  
   had used in #Primaries.  [Vince told me he did not know we could create indices on a table variable.]  My  
   testing showed that a table variable was slightly faster than using a temporary table with the same   
   indices.  
  - Changed method of populating @UWS to eliminate issues with a NULL UWSPUId when  
   'UWSORDER='has not been configured in the Extended_Info field of the UWS Prod_Units.  [Section 13]  
  -  Modified JOIN in the population of @UWS to be robust against there being more than 1   
   digit in the UWSOrder specification.  [Section 13]  
  - Added a parameter--RptWindowMaxDays--to enable administrative control of the maximum  
   number of days allowed in the date range specified for a given report.  [Sections 1, 3 and 4]  
  - Slightly modified the syntax and flow of the 'ELSE' for 'No report name specified'.  [Section 3]  
  
2005-10-03  Jeff Jaeger  Rev11.00  
  -  Changed the index on @RunSummary to use puid instead of plid.  
  - Added a where clause to @ProdRecords to include puid = reliabilitypuid.  
  - Removed Duration, TgtSpeedxDuration, and IdealSpeedxDuration from both @RunSummary and @ProdRecords.    
  - Replaced TgtSpeedxDuration and IdealSpeedxDuration with LineSpeedTarget and LineSpeedIdeal in the required   
   result sets.  
  - Added LineSpeedTarget and LineSpeedIdeal to the group by and order by of the required result sets.  
  - Added Target Line Speed to the indices for #ProdProduction and #ProdProduction2.  
  - I attempted to add Ideal Line Speed to the indices of #ProdProduction and #ProdProduction2, but this has null   
   values, and so cannot be added at this time.  
  - In the updates to ProdRecordsShift, I changed the rs.plid = prs.plid restriction to be rs.puid = prs.puid.  
  - Changed the index to ProdRecordsShift so that it uses puid instead of plid.  
  - Removed IF statements surrounding any code that creates temporary tables or table variables.  
  - Grouped all Create statements for temporary tables together.  
  - Added LineSpeedTarget and LineSpeedIdeal to #SplitUptime.  
  
2005-10-11 Jeff Jaeger  Rev11.01  
  - Corrected the varchar portion of the Replace statement in the insert for @WasteNTimedComments.  
   Since no length was properly defined, the text was getting truncated.  
  - Moved the code for checking input parameters to after the creation of temporary tables.  
   In cases where there was a problem with one of these parameters, the sp would crash instead of   
   returning the desired message, because it could not drop a table that had not been created.  
   This would be a new issue, arising because the flow control around creation of temp tables was   
   removed with Rev 11.0.  
  
2005-10-13 Jeff Jaeger  Rev11.02  
  -  Added a 'Converter Reliability' restriction on the calculations of Production Time in results sets #45 and 54  
   so that we didn't multiple count what amounts to the same holiday/curtail time across the PU's.  Note that the  
   changes are in both the 'Production Time' result and in the production time used in the denominator of the 'Rate  
   Loss %' result.  
  - Removed the indices for #ProdProduction and #ProdProduction2.  on some products on given lines, there   
   is no specification associated to active specs... so the target speed will be null.  this was causing an index   
   issue.    
  - Added a default value of the report endtime to the update of NextStartTime in @SplitEvents.  
  - Removed the old flow control code around the creation of temp tables and tables vars.  this has been  
   commented out for the last few revs.  
  
2005-10-13 Jeff Jaeger  Rev11.03  
  - Added a coalesce to the parameter check on the max number of days parameter.  the value will now coalesce to 0  
   before being checked.  
  
2005-10-17 Jeff Jaeger  Rev11.04  
  - changed the insert of @ProdUnitsPack to use Prod_Lines instead of @ProdLines.  This is to allow the table to be   
   populated independently of what values are assigned to @ProdLinesList.    
  - Updated the inserts to #PackProduction and #PackProduction2, so that they use Prod_Lines instead of @ProdLines.  
   This allows these tables to bring in the PLDesc, even if their lines are not in @ProdLinesList.  
  - Updated the inserts to #PackProduction and #PackProduction2, so that they use Products instead of @Products.  
   This allows these tables to bring in the PLDesc, even if their lines are not in @ProdLinesList.  
  - Changed the name of @ProdRecordsShift to @ProdRecords.  The old name was not very useful, and while the new   
   name is better, its still not great.  The change is done here because the name of the table was changed in   
   MBDTS, now called Cvtg Time Range Summary, and we want the names to be consistent.  
  
2005-10-18 Jeff Jaeger  Rev11.05  
  - Added additional SET OPTIONS  
  
2005-10-19 Jeff Jaeger  Rev11.06  
  - Moved SET OPTIONS statements to first thing inside the create statement for the stored procedure.  
  - Changed ProductID in @ProdRecords to ProdID so that it will be consistent with the corresponding field name   
   in other tables.  
  
2005-10-19 Jeff Jaeger  Rev11.07  
  - Changed the insert of @ProdUnitsPack to use @ProdLines instead of Prod_Lines.    
  - Updated the inserts to #PackProduction and #PackProduction2, so that they use @ProdLines instead of Prod_Lines.  
  - Updated the inserts to #PackProduction and #PackProduction2, so that they use @Products instead of Products.  
  
2005-10-20 Jeff Jaeger  Rev11.08  
  - Removed dimensions from the index for @ProdRecords.  
  - When rateloss updates are made to #delays, add uptime = null and downtime = null.  
  - Uncommented the insert to #delays for first events.  this was commented out during testing around rev 10.15,  
   and should have been uncommented then.  
  - Removed the default value for NextStartTime in #SplitEvents.  
  - Uncommented the third insert to #timedeventdetails for Proficy 4.0   
  - Removed the exclusion of 'No Grade' from the population of @productionstarts.  
  - Updated the use of SET options according to our latest thinking.   
  - Updated the insert of start time and end time into #stops, so that the 3rd parm for the convert is now   
   114 instead of 108.   
  - Updated the initial insert to #SplitUptime to not use the between statement  
  - Changed the update to LineStatus in #SplitUptime to not use the between statement  
  
2005-10-26 Jeff Jaeger  Rev11.09  
  - Needed to comment out a testing select statement after the result sets.  
  
2005-OCT-29 Langdon Davis Rev11.10  
  In Section 25, where multiple inserts to #TimedEventDetails are being performed, replaced 'SELECT *' with   
  SELECT <specific column names in the JOIN to the subquery on the 'real' Timed_Event_Details table.  
  
2005-DEC-02  Langdon Davis Rev11.11  
  Changed PRCEvents and PRCDowntime to key off of the PR/Poly Change Schedule ID to identify   
  them instead of 'GroupCause:Parent Roll Changes'.  This was driven by the GroupCause configuration not   
  being standard whereas the PR/Poly Change Schedule is.  A restriction on PUDesc LIKE '%Converter   
  Reliability%' is used to insure that we only get data for PR changes and not Poly.  
  
2005-DEC-15 Vince King  Rev11.12  
  Changed the PRCEvents calculation to summarize ALL events instead of just Stops.  This will take  
  into account the possibility of an operator coding a Parent Roll Change in a split event.  
  
2006-JAN-20 Namho Kim Rev11.13  
  Modified Linestatuslist value when a value of Linestatuslist is null or '', put a 'All' in value for Linestatuslist.  
    
2006-MAR-20 Langdon Davis Rev11.14  
  When specs are deleted via the Proficy Admin, the phrase '<Deleted>' shows up preceding the value.  Modified  
  the code to screen these deleted records out when selecting from Active_Specs by checking to see if the  
  value ISNUMERIC.  
  
2006-MAR-29 Vince King  Rev11.15  
  - Added @PRsRun enhancements from CvtgELP to capture missing time when PRs not loaded and assign them to  
   NoAssignedPRID.    
  - Added code to eliminate overlap of parent roll events in @PRsRun.  
  - Added Id_Num identity column to @PRsRun table and modified Primary Key to include Id_Num vs. EventId.  
  
2006-Jun-14   Namho Kim  Rev11.16  
  Added @tpunitsflag for Neuss  
  
2006-JUL-07 Jeff Jaeger  Rev11.17  
  - Restored the weighted avg on Target Speed and Ideal Speed.  
  - Added a weighted avg on LineSpeedAvg.  
  
2006-JUL-10 Langdon Davis Rev11.18  
  - Added a data integrity step to delete all 0 values for Reports Line Speed from #Tests  
   immediately after it is populated.  
  - Added a CASE statement on the time-weighted averaging of speeds to insure that we only added  
   in a denominator if there was a corresponding numerator.  
  
2006-JUL-19 Namho Kim   Rev11.19  
  Added insert to @ProductionStarts based on prod_units in the @ProdUnitsPack table.  This is   
  necessary to pick up the production starts for the pack production units that do NOT have  
  a corresponding reliability PU.  
  
2006-JUL-24 Langdon Davis Rev11.20  
  Modified the change made in Rev11.18 to protect against a rare potential for a division by zero error.  
  
2006-JUL-25 Langdon Davis Rev11.21  
  Except for the one associated with RptWindowMaxDays, changed all DATEDIFF uses to seconds UOM to be   
  more accurate.  
  
2006-08-09 Jeff Jaeger  Rev11.22  
 - Added null checks in the comparisons of team and shift during the insert to #SplitUptime for timespans  
  where no downtime events occurred.  
 - Added a check on the @ProdUnitsPack insert to @ProductionStarts to be sure that the pack puid does not   
  exist in @produnits, so there will not be duplicate records  
   
2006-08-11 Jeff Jaeger  Rev11.23  
 - REMOVED the check on the @ProdUnitsPack insert to @ProductionStarts to be sure that the pack puid does not   
  exist in @produnits... instead it is better to take the left join out of the population of @ProdUnitsPack.  
  
2006-08-14 Jeff Jaeger  Rev11.24  
 - REMOVED the checks for team is null or shift is null in joins that invovle matching on those fields.  
  this is done so that data will not be incorrectly grouped... the data flow will create an error later in the code.  
 - RESTORED the check on the @ProdUnitsPack insert to @ProductionStarts to be sure that the pack puid does not   
  exist in @produnits... this is still causing an error, and I think the inserts to @ProdUnits and @ProdUnitsPack  
  need to be researched further.  
 - Added an 'Insufficient Crew_Schedule information' error check after the population of @crewschedule.  
 - in the inserts to @ProductionStarts, uncommented the checks against 'No Grade' products.  
  
2006-08-17 Jeff Jaeger  Rev11.25  
 - Removed the restriction in the @ProductionStarts insert that screens out Products of No Grade.  
  
2006-09-14 Jeff Jaeger  Rev11.26  
 - Restored the primary key for #SplitDowntimes and #SplitUptimes  
 - Restored the original comments for inserts to #SplitDowntimes.    
 - Both these changes were originally made while working on an issue, but I never reset them.  
 - added updates to AppVersions  
  
2006-10-09 Langdon Davis Rev11.27  
 - Comments were not getting filled in under version 4.x.  The field in #Delays was simply just not  
  getting populated with the data from #TimedEventDetails.    
 - Also had to increase the size of the Cause_Comment field in #TimedEventDetails from VARCAHR(16) to VARCHAR(5000).  
  
2006-11-20 Jeff Jaeger Rev11.28  
 - updated the assignment of Product information in #tests  
 -  removed EndTime from #tests and changed the name of StartTime to SampleTime.  
 - moved the population of the variables @PacksInBundleSpecId, @SheetCountSpecId, @ShipUnitSpecId,   
  @CartonsInCaseSpecId so that it takes place before the assignment of nValue.  
 - changed the name of nValue to SheetValue, and updated the population of that field to apply specs  
  according to the #Test product information.  
 -  rewrote the population of GoodUnits and ActualUnits in @prodrecords to be more efficient.  
 -  made @LimitVariables and @PackVariables temp tables because of the amount of records they are likely to hold.  
 - removed the @i select statements.  testing that Langdon and I did has shown that this does not improve the   
  efficiency.  in fact, it appears to hamper it.  
  
2007-01-12 Jeff Jaeger Rev11.29  
 - These changes reply work done by Langdon Davis in Rev11.28.5  
 - Removed the restriction on PUDesc LIKE '%Converter Reliability%' in the calculation of stats   
  surrounding PRC events, downtime and average downtime so that they would also pick up poly changes   
  in the pack area.  
 - Changed the following results sets field names in the stops results sets:  
   'PRC Events' to 'PR/Poly Change Events'  
   'PRC Downtime' to 'PR/Poly Change Downtime'  
   'Avg PRoll Change Time' to 'Avg PR/Poly Change Time'  
 - Defaulted the above 3 fields to 'N/A' in each of the 2 results sets #5, 6, and 7 to avoid combining   
  PRoll change data with poly roll change data.  
  
 NOTE: A find on 'Rev11.29' will take you to every line comented oout or modified by the   
   above changes.  
  
2007-11-16 Vince King Rev11.30  
 - The PRID (UWS1Parent) was not getting assigned in some cases to downtime events.  I found where the   
  @PRsRun data was not correct.  There were rows being added that were duplicates as well as rows added  
  where there was already a valid PR row for that time period.  
 - Commented out the INSERT for @PRsRun and replaced with the #Events and INSERT @PRsRun from CvtgELP.  Also  
  added PEIId to the tables and used it in the SELECT statements for updating @PRsRun columns.  
  
2007-01-26 Jeff Jaeger Rev11.31  
 - search on "Rev11.31" to find these changes.  
 - changed the fields TotalUnits, GoodUnits, RejectUnits, RollsPerLog, RollsInPack, PacksInBundle,  
  CartonsInCase, SheetCount, TargetUnits, ActualUnits, OperationsTargetUnits, and IdealUnits to float   
  data types in the @ProdRecords table.  This is done to parallel the table structure in the cube feed,   
  and because the change should lead to more accurate calculation results.   
 - added the fields LineSpeedSum and SampleCount to SplitEvents and SplitDowntime, along with the code  
  to populate them.  
 - added the fields LineSpeedSum, SampleCount, and SplitUptime to @ProdRecords along with the code  
  to populate them.  
 - added the table variable @variablelist along with the code to populate it.  Updated the insert to  
  #tests.  
 - Removed Duration, TargetSpeedxDuration, and IdealSpeedxDuration from the structure of @RunSummary   
  and @ProdRecords.  
 - Updated the calculation of Line Speed Avg, Target Line Speed, and Ideal Line Speed in the result sets.  
  
2007-01-29 Jeff Jaeger Rev11.32  
 - search on "Rev11.32" to find these changes.  
 - made corrections to the calculation of Target Speed and Ideal Speed in the result sets.  
  
2007-02-16 Jeff Jaeger Rev11.33  
 - seach on "Rev11.33 to find these changes.  
 - changed the calc for ActualUnits in @ProdRecords, where BusinessType = 4, to use GoodUnits instead   
  of a subquery.  
 - added code to the final result set to convert [Total Units], [Good Units], [Reject Units],  
  [Rolls Per Log], [Rolls In Pack], [Packs In Bundle], [Cartons In Case (Facial)], [Sheet Count],  
  [Actual Stat Cases], [Reliability Target Stat Cases], [Operations Target Stat Units], and  
  [Ideal Stat Cases] to integer.  
 - Added the variables @SQL3Events, @SQL3EventHistory, @SQL3EventHistoryBeforeReportWindow, and   
  @SQL3EventsBeforeReportWindow along with the code to populate them.  
 - changed the table variable @ProdLines back to a temp table #ProdLines, along with all references to   
  the table.  this is so that it can be referenced in the dynamic SQL statements that will be used to  
  load the #Events table.  
 - changed the table variable @PRsRun back to a temp table because of the number of records it can often hold.  
  also added [StartStatus], [EndStatus], and [DevComment] to #PRsRun.  These fields are not actually required   
  to process any data, but they are extremely useful while troubleshooting during development.  
 - added the field InitEndtime to #PRsRun.  
 - removed [PrevEvent_Status] from #Events and added [Status_Desc] and [DevComment]  
 - removed the old primary key index from #Events.  
 - changed the index on #Events to use Entry_On instead of Timestamp.  Also, this index is now clustered.  
 - removed the variable @StagedStatusId and the code that populates it.  
 - completely overhauled the insert to #Events, using dynamic SQL statements.  Also modified the updates   
  to source_evenet in that table to use a simpler statement.  
 - completely overhauled the insert to #PRsRun.  This was done to apply updates to the new approach for   
  defining parent roll data.  
 - added an update to #PRsRun that will adjust the end time of a record if a successive PR record overlaps  
  with the first.  
 - removed the insert of NoAssignedPRID to the gaps between the start of the report window and the first event.   
 - removed the insert of NoAssignedPRID to the gaps between the end of the report window and the last event.   
 - removed the insert of NoAssignedPRID for the lines that have no events during the report window.  
 - added id_num back into the index for #PRsRun.  
  
2007-02-20 Jeff Jaeger Rev11.34  
 - updated the assignment of Avg Line Speed in the last result set.  
 - removed the update to LineSpeedAvg in @ProdRecords.  
  
2007-02-27 Jeff Jaeger Rev11.35  
 - in an effort to clean up the code and keep it readable, I am deleting all code that has been  
  commented out for changes in previous revisions.  in order to see these comments, previous   
  versions of this sp can be referenced through VSS.  
 - these changes can be found by searching on "Rev11.35".  
 - removed LineSpeedSum and SampleCount from #SplitEvents and #SplitUptimes, as well as the   
  code to populate these fields.  
 - updated the assignment of LineSpeedAvg in @ProdRecords to use the avg() function again.  
 - updated the definition of Line Speed Avg in all the result sets to use a weighted avg based on  
  SplitUptime.  
 - updated LineTargetSpeed and LineIdealSpeed in #SplitUptime to be a float instead of an integer.  
 - updated the definition of Target Line Speed and Ideal Line Speed in all the result sets to use  
  ProductionRuntime instead of SplitUptime.  
  
2007-03-02 Jeff Jaeger Rev11.36  
 - to find these changes, perform a search on "Rev11.36".  
 - made correction to calcs for Line Speed Avg, Target Speed, and Ideal Speed in all result sets that   
  include those values.    
  
2007-05-08 Jeff Jaeger Rev11.37  
 -  note that Rev11.37 consists of changes made by Vince King.  Search for Rev11.37 to find the changes,  
 along with his comments.  
  
2007-05-08 Jeff Jaeger Rev11.38  
 - added additional indices to #PRsRun to optimize some queries in the sp.  
 - added an order by clause to the initial insert to #TimedEventDetails.  
  
2007-05-30 Jeff Jaeger Rev11.39  
 - removed rounding from poplation of @ProdRecords.  
 - corrected the rounding for LineSpeedAvg in the result sets.  
 - Added LineSpeedAvg to #SplitUptime.    
 - Updated the assignment of LineSpeedAvg and SplitUptime in @ProdRecords.    
 - updated the assignment of PRC Stops and Avg PRC in the result sets.  
 - updated the assignment of Paper Runtime in #UnitStops.  
  
2007-JUN-01 Langdon Davis Rev11.40  
 Added a parameter check for start and end time being the same.  This avoids a bunch of processing and   
 errors on the VB side from empty/NULL results sets.  
  
2007-06-04 Jeff Jaeger Rev11.41  
 - updated the assignment of ParentPRID in #PRsRun, so that is uses the test table.  
  
2007-06-06 Jeff Jaeger Rev11.42  
 - to find these changes, search for "Rev11.42".  
 - updated the assignment of ParentPRID and GrandparentPRID in #PRsRun, so that is uses the test table.  
 - changed Runtime in #ProdLines, @TeamCounters and @TeamCounter to ProductionRuntime.  
  changed the code to populate this field.  
 - added PaperRuntime to #ProdLines, @TeamCounters and @TeamCounter, along with the code to populate the field.  
 - removed Runtime from @ShiftCounters and @ShiftCounter.  
 - updated the determination of Paper Runtime, Production Runtime, and ELP% in the result sets so that they   
  make use of the new PaperRuntime nad ProductionRuntime fields where required.  
 - could the new ProductionRuntime in @Prodlines be used to determine Production Runtime in all the result sets?  
  I'm not going to spend time right now to make these changes and test them.  
 - could there be a ShiftCount field in @TeamCounters and @TeamCounter, thus eliminating the need for   
  @ShiftCounters and @ShiftCount?  
  
2007-06-12 Jeff Jaeger Rev11.43  
 - when assigning PaperRuntime to @TeamCounters, converted NoOfUWSRunning to a float for the division.  
 - in the result set ELP % calcs, ensured that coalescing was done with 0.0, not just 0.  
 - set PaperRuntime so that it is initially measured in seconds, and then converted to minutes for the result sets.  
 - changed the population of ProductionRuntime in @TeamCounters so that the measure is in seconds, and is   
  not converted to minutes until the result sets are compiled.  this was done to make it consistant with   
  other times measures.  
  
2007-06-19 Jeff Jaeger Rev11.44  
 - removed some dead code.  
 - corrected the assignment of ParentPRID.  
  
2007-06-22 Jeff Jaeger Rev11.45  
 - to find these changes, search for "Rev11.45".  
 - added @VarLinespeedMMinVN related code.  
  
2007-06-23 Jeff Jaeger Rev11.46  
 - added a nonclustered index to #Tests.  
 - updated the insert to #PRsRun so that the joins for UWSRunning and ParentPRID will be more efficient.  
  
2007-07-03 Jeff Jaeger Rev11.47   
 - corrected the UOM of ProductionRuntime when applied to result sets.  
  
2007-JUL-09 Langdon Davis Rev11.48  
 -  Insured that all SELECT statements had 'with (nolock)' on all Proficy and temporary tables in the 'FROM' and   
  'JOIN' clause.  Probably ~80% of them already did, but there were some misses including some on the Proficy  
  Tests and Timed_Event_Details tables.  
  
2007-JUL-12 Langdon Davis Rev11.49  
 - Protected against a divide by 0 error in the calculation of Paper Runtime by defaulting NoOfUWSRunning to 1 if it   
  is zero.  This is the same approach already in use in the ELP report.  
  
2007-JUL-13 Jeff Jaeger Rev11.50  
- updated the code that adds PUDesc to #Delays.  This section of code assigns the name of the Converter Reliability  
 unit to the Rateloss unit for grouping purposes in the result sets.  Because not all lines have a "TT" designator,   
 the original code could create incorrect unit names.  
- added [Production Line] to the indices on #UnitStops, #UnitStops2, and #Stops.  this is because in Facial,   
 some production lines have units with the same names as units on pack lines.  
  
2007-10-30 Jeff Jaeger Rev11.51  
 - updated the definitions of StopsUnscheduled and SplitUnscheduledDT.  
 - added SplitUnscheduledDT to #SplitEvents, and used that field in compiling result sets instead of determining   
  the value multiple times.  This could probably be done with a few other downtime related metrics in the result sets.  
  
2007-10-30 Jeff Jaeger Rev11.52  
 - removed Stops2Min from #delays  
 - removed the CategoryID = Blocked/Starved restriction from Stops, StopsUnscheduled, StopsMinor, StopsProcessFailure and Uptime2Min  
  in #delays.  
 - included the Block/Starved related changes from StopsUnscheduled in the definitions of StopsMinor and   
  StopsProcessFailure for #delays.  
  
2007-NOV-01 Langdon Davis Rev11.53  
 - Modified the condition on StopsBlockedStarved to be based on SCHEDULEID being Blocked/  
  Starved rather than CategoryId.  
 - Modified the condition on OperationsRuntime to treat Schedule = Blocked/Starved the same as unscheduled.  
 -  Removed the Category = Blocked/Starved restriction from the calculation of ReportRLELPDowntime,  
  ReportELPDowntime and SplitUnscheduledDT.  
 -  Modified Unscheduled Stops/Shift to use the same denominator as Planned Availability and to be  
  Unscheduled Stops/Day which is a universal value.  Also added ROUND to this calculation.  
 - Eliminated @ShiftCounters and @ShiftCounter tables and references.  They are no longer needed with the above  
  change.  
 -  Added a COALESCE on Jeff's new source for Split Unscheduled DT in the results sets.  
 - Restricted Split Unscheduled DT at the Line Total level to that of the Converter Reliability Master Unit [as   
  was already being done for Split Downtime and the two Uptime values].  
 - Opportunity Noted:  We could only do the work to populate @TeamCounter if @IncludeTeam =1 except for the   
  fact that @TeamCounter is used to populate PaperRuntime in #ProdLines and that table is used regardless   
  of the @IncludeTeam value.  ALSO, I am concerned about the use of ProductionTime to update @TeamCounter's   
  PaperRuntime when it is NULL because ProductionTime already has Holiday/Curtail time subtracted and when   
  we use PaperRuntime [out of either @TeamCounter or #ProdLines] down in the results sets, we are subtracting   
  ReportELPSchedDT which also contains Holiday/Curtail downtime, i.e. we are double subtracting Holiday/Curtail   
  time.  I think this will all be fixed by reapplication of the new approach to getting paper runtime, so I   
  will leave it as is for now.  
  
2007-NOV-07 Langdon Davis Rev11.54  
 - Missed removal of the Category = Blocked/Starved restriction from an update of SplitUnscheduledDT.  
 - Eliminated the definition and population of @CatBlockedStarvedID since it is no longer used anywhere.  
 - Added 0 values initialization of Unscheduled Stops/Day in the initial insert into #LineStops and   
  #LineStops2.  Not totally necessary--the update takes care of populating these fields after the   
  insert--but wanted to be consistent with the rest of the measures.  
 - Corrected a double-insert of SplitUnscheduledDT in #LineStops and #LineStops2.  First one was wrong,   
  second was right.  
 - Where joins to @ShiftCounter had been eliminated from the results sets in Rev11.53, replaced them  
  with a join to @TeamCounter on PLID and Team.  Turns out, when you have a report that spans across lines  
  where one or more of them has no events because End_Time < @StartTime and end_time is NOT null, @TeamCounter  
  and @ShiftCounter limit the results sets to just those lines that have a record in #Delays because of the  
  join to #Delays in their population.  When the @ShiftCounter was eliminated from some of the results sets,  
  but @TeamCounter was still used in some others, the lines included in the results sets then differed.  This  
  led to Excel, as it assembled the results sets, getting them out of sync.  Putting the joins to @TeamCounter  
  in the results sets where @ShiftCounter had been eliminated is a "quick and easy" fix.  As the opportunity  
  described above in Rev11.53 is executed against, it will be necessary to consider this additional use of  
  @TeamCounter, replacing it with, perhaps, a new table that is simply a selection of the distinct PLIDs  
  from #Delays.  
  
2008-09-18 Jeff Jaeger Rev.11.55  
 - Removed the use of @DBVersion to determine the version of Proficy while building the OrgHierarchy.  
 - Made the @Dimensions table variable a temp table because of the size of the table.  
 - Retooled #Dimensions and its population to have just the fields needed to track dimension changes.  
 - Removed the use of @FirstEvents, @TeamCounter, @TeamCounters, and @Primaries.  
 - Added #SplitPRsRun and the code to populate it.  This table will allow us to associate #PRsRun data with   
  Cvtg team, product, downtime, etc.  
 - Added @SplitDT_UnitTeam, @SplitDT_Unit, and @SplitDT_Line and the code to populate them to summarize the   
  split downtime data to be associated with various groupsings of PRsRun data.  
 - Added @PRDTSums_UnitTeam, @PRDTSums_Unit, and @PRDTSums_Line to gather summarized PRsRun and Split Downtime data.  
 - Added #ELPMetrics_UnitTeam, #ELPMetrics_Unit, and #ELPMetrics_Line to summarize basic #PRsRun metrics.  
 - Added RawRateloss to #Delays and #SplitDowntime.  This field is used to determine SplitRLELPDowntime in the   
  same way that Downtime is used to determine SplitELPDowntime, because ELP metrics are not split.  
 - Added #EventStatusTransitions and the code to populate it.  This will now be used to populate #Events.    
 - Updated the population of #PRsRun to reflect the latest methodology.  
 - Removed the use of NoOfUWSRunning.  
 - Updated the population of #UnitStops, #UnitStops2, #LineStops, and #LineStops2 to use the new PRDTSums tables,   
  as appropriate.  Note that at the Unit/Team and Unit levels, the blocked/starved data is grouped with the   
  associated reliability units.  
 - Added the population of ‘NoAssignedPrid’ in #PRsRun for the start and end of the report window.  
 - Simplified the inserts to #TimedEventDetails since we now assume all sites are on the same version of Proficy.  
 - Cleaned up a lot of dead code.  
  
2008-09-23 Jeff Jaeger Rev11.56  
 - added an additional update to PEIID for #PRsRun.  This is used for facial line FFF1, which has a different   
  configuration than the other lines.  
  
2008-SEP-25 Langdon Davis Rev11.57  
 - Added an update on #Delays to automatically fill in the Schedule ID as Blocked/Starved if it is null [means  
  the reason level 2 was not filled out or there is no event reason category association to a 'Schedule'    
  event reason category] AND if reason level 1 contains the word 'BLOCK' or 'STARVE'.  
  
2008-09-26 Jeff Jaeger Rev11.58  
 - added the "CombinedPUDesc" field to @ProdUnits to represent the combined reliability and block/starved units.  
  this new field can be used in the groupings for result sets instead of the case statements originally put   
  in place combine these units.  This was done in order to strip "Reliability" out of the combined unit name.  
 - changed the stops related updates to #Delays so that where there is a restriction based on the pudesc being   
  'Converter Reliability' the same restriction will be applied with 'Blocked/Starved'.  
 - corrected the FROM clause in the update to UWS1Parent and UWS1Grandparent in #Delays.  
 - changed the definition of RawUptime in the result sets that combine the Reliability and Blocked/Starved   
  units.  the new definition sets the combined RawUptime = RawUptime for the Reliability unit -   
  SplitDowntime from the Blocked/Starved unit.  
 - changed the definition of SplitUptime in the result sets that combine the Reliability and Blocked/Starved   
  units.  the new definition sets the combined SplitUptime = SplitUptime for the Reliability unit -   
  SplitDowntime from the Blocked/Starved unit.  
  
2008-09-29 Jeff Jaeger Rev11.59  
 - adjusted the definitions of SplitUptime and RawUptime in the combined Reliability and Blocked/Starved   
  unit results so that if the result would be negative, a value of zero is assigned.  
  
2008-10-08 Jeff Jaeger Rev11.6  
 - added the @PRDTOutsideWindow table and related code to populate UWS1 and UWS2 related data in #Delays   
  for downtime events that started prior to any of the @PRsRun entries.  
 - updated the assignment of GrandParentPRID to use VarInputRollID and VarInputPRIDID.  
 - added an additional update to PEIID for #PRsRun.  This is used for facial line FFF1, which has a different   
  configuration than the other lines.  
  
2008-10-22 Jeff Jaeger Rev11.61  
- modified the Facial FFF1 special special update to PEIID in #PRsRun so that it only runs if the site   
 executing the code is GB... this will need to be added to all of the reports.  
  
2008-11-12 Jeff Jaeger Rev11.62  
- Changed the update to GrandParentPRID in @PRDTOutsideWindow to include a Timestamp check against the   
 test result_on.  
- Removed the IF clause around the use of @PRDTOutsideWindow.  the check to see if there are any UWS1Parent   
 or UWS2Parent values that are NULL before actually running that section of code was taking (much) longer   
 than is actually needed to just run the code.  
- added @DelaysOutsideWindow and the code to populate this.  this was done to reduce the size of the data set  
 being joined to in the population of @PRDTOutsideWindow.  the effect is to noticably reduce the runtime of   
 the sp.  
  
2008-11-18 Jeff Jaeger Rev11.63  
- Added sprs_id to #SplitPRsRun as a primary key, changed the existing (puid,starttime,endtime) index to   
 nonclustered, and added a (plid,starttime,endtime) index.  
- Made changes to all updates to "group by" start and end times to make them more efficient.  
  
2008-11-26 Jeff Jaeger Rev11.64  
(changes by Jeff Jaeger)  
- converted PRDTOutsideWindow, ELPMetrics_UnitTeam, ELPMetrics_Unit, ELPMetrics_Line, and ProdLines,   
 to table variables instead of temp tables.  
- added @ESTOutsideWindow and code to populate it.  this table is used to optimize the population of   
 PRDTOutsideWindow.  
- added ProdPuid and an index to @DelaysOutsideWindow.  
- optimized the population of LineSpeedAvg in #SplitUptime.  
(changes by Langdon Davis)  
- Added PUID to the primary key in @DelaysOutsideWindow.  This was necessary to avoid duplicate key errors on  
 lines where rate loss and downtime events are happening at the same time [theoretically not possible but in   
 reality, it happens given today's independent production units for these events.  
- Restricted the population of @DelaysOutsideWindow to just those events that have a start time < the start   
 of the report window.  This makes the population meet the intent of being just events that started   
 before the report window that do not yet have a parent roll association.  
  
2008-12-10 Jeff Jaeger Rev11.65  
- Changed the way that HolidayCurtailDT is determined in @PRDTSums_UnitTeam, @PRDTSums_Unit, and @PRDTSums_Line.  
 This is now done the same way as other values pulled from #SplitDowntimes.  
- added "with (nolock)" to select statements using temp tables.  
- changed correlated updates so that all instances of a table will have a unique alias, even though they are   
 used in a subquery.  our current thinking is that using the same alias when a table is referenced in multiple   
 subqueries could be causing locking issues.  
  
2008-12-15 Jeff Jaeger Rev11.66  
- removed VarStartTimeId, VarEndTimeId, VarPRIDId, VarParentPRIDId, and VarUnwindStandId from the population  
 of @VariablesList.  
  
2008-12-18 Jeff Jaeger Rev11.67  
- moved the population of @LineProdVars to before the population of @VariableList.  this was needed because  
 the population of @VariableList was recently moved to earlier in the code during efforts to optimize the sp.  
  
2009-02-05 Jeff Jaeger Rev11.68  
- modified the definition of StopsUnscheduled, StopsMinor, StopsEquipFails, and   
 StopsProcessFailures in #Delays  
  
2009-02-12 Jeff Jaeger Rev11.69  
- modified the code to determine Stops/Day.  
  
2009-02-13 Jeff Jaeger Rev11.70  
- modified the method for pulling ScheduleID, CategoryID, GroupCauseID, and SubsystemID in #delays.  
  
2009-03-02 Jeff Jaeger Rev11.71  
- modified the definition of SplitUnscheduledDT  
  
2009-03-12 Jeff Jaeger Rev11.72  
- added z_obs restriction to the population of @produnits  
- added an OrderIndex to results sets that include the PU description so that Converter Reliability   
 will be sorted at the top of the results for any given line.  
- corrected the join to @produnits in the production results, so that it is based on the updated pudesc,  
 not on the original puid.  
  
2009-03-17 Jeff Jaeger Rev11.73  
- modified the definitions of various flavors of stops in #Delays  
- modified the definition of SplitUnscheduledDT in #SplitDowntimes  
  
2009-04-09 Jeff Jaeger Rev11.74  
- added a restriction on pu_desc not like '%rate%loss%' in the definition of SplitELPSchedDT.  
  
2009-05-11 Jeff Jaeger Rev11.75  
- changed the assignment of NextStartTime in #SplitDowntimes to use a EndTime <= StartTime   
 comparison.  It seems that comparing the record ID values is not robust enough in the   
 latest version of SQL.  
  
2009-08-11 Jeff Jaeger Rev11.76  
- modified the update to ShiftStart in @Runs.  
  
2009-09-07 Vince King Rev11.77  
- Added result sets for Data Quality sheet in template.  
  
2009-09-10 Vince King Rev11.78  
- Changed clock hrs result set to use #Dimensions instead of @RunSummary.  
- Modified LineStatus result sets to only display units with 'reliability' in the desc.  
- Replaced Line with Unit in LineStatus result sets.  
  
2009-09-14 VMK Rev11.79   
- Changed code for Line Status result sets for Data Quality sheet to select units   
- based on 'Line Status' table field configuration.  
  
2009-09-16 VMK Rev11.80  
- Left off the GROUP BY and ORDER BY on the SELECT statements for the Data Quality   
- result sets.  
  
2009-09-16 VMK Rev11.81  
- Removed check to for Comment_Text <> '' in WHERE clause for Data Quality result set.  
 The result set is for details of Line Status changes and should show all entries.  
  
2009-09-25 VMK Rev11.82  
- Additional 'stream-lining' of Data Quality code.  Modifications added to pick up  
- events prior to report period when event spans report period or none are selected.  
  
2009-11-16 Jeff Jaeger Rev11.83  
- modified the insert to @ClockHrs to convert pu.pu_id to a varchar before comparing it   
 with Table_Fields_Values.Value.  this is done because not all entries in Value from   
 Table_Fields_Values are numeric.  
  
  
----------------------------------------------------------------------------------------------------------------  
------------------------------------------------------------------------------------------------------------------  
--The techniques used to optimize this SP are as follows:  
------------------------------------------------------------------------------------------------------------------  
1.  Note that optimizing stored procedures is more an art than a science.  The information listed here is only a set of   
  guidelines, not exact rules.  As different techniques are applied, the developer should test the results to see if   
  there are any gains in inefficiency.    
2.  Use SQL Profiler in Enterprise Manager (under Tools on the menu bar) to track the number of reads, the number of   
  writes, and the duration of stored procedures as efficiency enhancements are tested.  These numbers will be a better   
  benchmark then just the execution time alone.  
3.  Renamed some tables and variables to make them better reflect what they represent.  
4.  Replaced creation of #Runs and related tables with the @Dimensions table and @Runs.  Basically, puid and time ranges   
  for the various time dimensions are loaded into @Dimensions (along with a name for the dimension and its specific values).    
  Then unique puid and starttime combinations are inserted from there into @runs (without regard to the Dimensions or their   
  values).  After that, the various dimensions in the @runs table are updated according to the time ranges and values in   
  @Dimension.  This approach reduces the number of intermediary tables, and it is flexible enough to allow additional   
  dimensions to be added easily.  
5.  Removed cursors and loops wherever possible.  There are still a few small loops, but I couldn? see a way around them   
  without adding more over-head.  The biggest cursor (for populating #ProdRecordsShift) has been eliminated.  In most   
  cases, a correlated subquery or a table joined to itself can replace a cursor or loop, although this was not the case   
  with #ProdRecordsShift.  It is better (especially over a large dataset) to have an initial insert followed by some   
  general update statements,  rather than to loop through a cursor doing various inserts and/or updates one at a time.  
6.  When loading a temporary table or table variable with data from a large table in the database, it is sometimes more   
  efficient to create an intermediary table that can be populated with a tight range of data from the database.  This   
  approach is useful when the original insert statement uses joins to other tables, or there is processing of data as it   
  is loaded, or when an insert will join to the same table multiple times.  
7.  Wherever possible, use table variables instead of temporary tables.  
8.  Created additional table variables such as @ActiveSpecs, @CrewSchedule, etc.  Basically, anytime a real table in the   
  database needed to be accessed multiple times, I created a table variable so that in most cases, the real table only   
  needs to be hit once.  
9.  Updated the indices on temporary tables and table variables.  Each temporary table and table variable now has at   
  least a clustered index on the primary key (except in a few cases).  In some cases, the key is compound.  There are   
  also some cases where I defined a nonclustered index on an ID field (when other tables will commonly join with the   
  given table based on that ID).  
10. When joining tables, keep the order of where clause elements in the same sequence as the primary key sequence to   
  whatever extent is possible.  
11. Where possible, use joined tables instead of subqueries.  The need to use ?op?in the select is one case where a   
  subquery will be required.  
12. Remove any unused fields from table structures and the code that populates them.  
13. When populating temporary tables and table variables, restrict the data selected as much as possible.    
14. Eliminate any unused variables.  
15. Where possible, remove functions such as coalesce, subqueries, etc., from where clauses.  Using these will keep   
  indexes from being applied.  
16. Apply flow control where required, so that temporary tables and table variables are only created and dropped if   
  they are actually used.  
17. Use a statement like ?ET @i = (SELECT COUNT(*) FROM dbo.#table)?on all temporary tables before they are   
  populated.  
18. Use ?ption (keep plan)?with all select statements to reduce how often statistics are updated.  
19. When referencing a real table or a temporary table, be sure to define the owner in the reference?i.e. ?bo.?  
20. If an insert or update statement uses a nested subquery, try to find another way to do the update.  
21. Instead of using ?xecute?against a query string, use ?xecute sp_executesql?  
22. Run the stored procedure in query analyzer, using the Show Execution Plan option (under Query on the menu bar) to   
  identify which actions in the stored procedure are using the highest percentage of resources.  Also look for any SCANs   
  that are occurring (as opposed to SEEKs).  These two tactics will help identify the places where the most efficiency   
  could be gained.  
23. Recommendation:  about 35% of the processing time in this stored procedure is spent building and populating the   
  #Delays table.  Since this table is used in multiple reports, it might be better to replace it with a local table in   
  the database, which could be updated periodically with a scheduled DTS package.     
24. Recommendation:  GBDB.dbo.fnLocal_RptTableTranslation requires the use of a temporary table.  It should be   
  possible to write a similar function which will take as inputs the name of a table variable, and the fields that need   
  to be returned (this could all be one delimited string), and return a query string to be executed.  Then the result set   
  temporary tables could be eliminated, thus reducing the number of recompiles.  (This was not implemented in this   
  rewrite of the stored procedure because I? told that other approaches to header translation are being investigated).  
  
------------------------------------------------------------------------------------------------------------------  
------------------------------------------------------------------------------------------------------------------  
-- Calculations used in the result sets of this SP:  
------------------------------------------------------------------------------------------------------------------  
Some of the SQL code used to apply calculations gets a bit murky.  Because of this, it might be difficult   
to determine what certain calculations are intended to do.  This section will hopefully add a little clarity   
to the worst cases.  
  
ELP Losses (Mins) = ReportELPDownTime + ReportRLELPDownTime  
  
ELP % = ELP Losses (Mins) / Paper Runtime  
  
Rate Loss % = ReportRLDowntime / Production Time  
  
-- Note that how the Runtimes are derived depends on what level its being summed up at.  
  Paper Runtime = RunTime - ReportELPSchedDT  
  Production Time = Runtime - Holiday Curtail ReportDowntime  
  
-- The following calculations are carried out as updates to the result sets.  It is done this way  
 for simplicity sake:  
  Unscheduled Stops/Day = (Unscheduled Stops * 1440.0) / (Split Uptime + Unscheduled Split DT)  
  Planned Availability = Split Uptime / (Split Uptime + Unscheduled Split DT)  
  Unplanned MTBF = Split Uptime / Unscheduled Stops  
  Unplanned MTTR = Unscheduled Split DT / Unscheduled Stops  
  Avg PRoll Change Time = PRC Downtime / PRC Events  
  
 Avg Stat CLD = ActualUnits * (1440 / ProductionRuntime)  
 CVPR % = ActualUnits / TargetUnits  
 Operations Efficiency % = ActualUnits / OperationsTargetUnits  
 CVTI % = ActualUnits / IdealUnits  
  
-- For certain values in Line Summaries (specifically Unscheduled Split DT, Raw Uptime, and Split Uptime),  
 totals across multiple Master Units within a Converting Line are defined as the values for the   
 Converter Reliability Master Unit.    
  
 For totals across multiple Master Units within a Pack Area, the values are defined as the sum of the values   
 for the individual Master Units.  
  
-- Additional information re the calculations can be found on the 'Definitions' and 'Prod Factors' worksheets  
 in the RptCvtgDDSStops.xlt.  
  
------------------------------------------------------------------------------------------------------------------  
------------------------------------------------------------------------------------------------------------  
-- SP sections:  [Note that additional comments can be found in each section.]  
------------------------------------------------------------------------------------------------------------  
Section 1. Define variables for this procedure.  
Section 2: Declare the error messages table.  
Section 3: Get the input parameter values out of the database.  
Section 4: Assign constant values  
Section 5: --print the input parameters used  
Section 6: Create temp tables and table variables  
Section 7: Check Input Parameters to make sure they are valid.  
Section 8: Get local language ID  
Section 9: Initialize temporary tables.    
Section 10: Get information about the production lines  
Section 11: Parse the DelayTypeList  
Section 12: Get information for ProdUnitList  
Section 13: Populate the @UWS table.  
Section 14: Update @ProdUnits UWS columns with the appropriate prod Unit desc.  
Section 15: Populate @ProdUnitsPack  
Section 16: Populate @ProdUnitsEG  
Section 17: Get Crew Schedule information  
Section 18: Get Production Starts  
Section 19: Get Products  
Section 20: Get Active Specs  
Section 21: Get Line Production Variables     
Section 22: Get the dimensions to be used  
Section 23: Get the run times and values for each dimension  
Section 24: Populate @RunSummary  
Section 25: Get the Time Event Details  
Section 26: Get the initial set of delays for the report period  
Section 27: Get the first events for each production unit  
Section 28: Additional updates to #Delays  
Section 29: Get the Timed Event Categories for #Delays  
Section 30: Populate @Primaries  
Section 31: Calculate the Statistics for stops in the #Delays dataset  
Section 32: Get Tests  
Section 33: Populate @PRsRun and update #Delays accordingly  
Section 34: Update the Rateloss information for #Delays  
Section 35: Populate @ProdRecords  
Section 36: Get counters for Team and Shift  
Section 37: Get Pack Test values  
Section 38: Get Event_Reason and Event_Reason_Category info  
Section 39: Split the delays and calculate Split Uptime.  
Section 40: If there are Error Messages, then return them without other result sets.  
Section 41: Results Set #1 - Return the empty Error Messages.  
Section 42: Results Set #2 - Return the report parameter values.  
  
--   if @IncludeTeam = 1  
  begin  
  Section 43: Results Set #3 - Return the stops result set for Line / Master Unit / Team.    
  Section 44: Results Set #4 - Return the stops result set for totals by Line / Master Unit.  
  Section 45: Results Set #5 - Return the stops result set for the individual Line or Packloop totals.  
  Section 46: Results Set #6 - Return the stops result set for totals for Lines and Packloops.  
  Section 47: Results Set #7 - Return the stops result set for Overall.  
  Section 48: Results Set #8 - Return the production result set by Line / Team / Product.  
  Section 49: Results Set #9 - Return the production result set for Line.  
  Section 50: Results Set #10 - Return the production result set for Overall.  
  Section 51: Results Set #11 - Return the production result set for Packing Production Units [Pack Prod worksheet].  
  end  
  
--  if @IncludeTeam = 0  
  begin  
  Section 52: Results Set #3 - Return the stops result set for Line / Master Unit.  
  Section 53: Results Set #4 - Return a blank Result Set to keep the number of result sets standard.    
  Section 54: Results Set #5 - Return the stops result set for the individual Line or Packloop totals.  
  Section 55: Results Set #6 - Return the stops result set for totals for Lines and Packloops.  
  Section 56: Results Set #7 - Return the stops result set for Overall.  
  Section 57: Results Set #8 - Return the production result set by Line and Product.  
  Section 58: Results Set #9 - Return the production result set for Line.  
  Section 59: Results Set #10 - Return the production result set for Overall.  
  Section 60: Results Set #11 - Return the production result set for Packing Production Units [Pack Prod worksheet].  
  end  
  
--  if @IncludeStops = 1  
  begin  
  Section 61: Results Set #12 - Return the stops detail result set for the pivot table.  
  end  
  
--  if @BySummary = 1  
  begin  
  Section 62: Results Set #13 - Return the result set for Line/Team grouping.  
  Section 63: Results Set #14 - Return the result set for Line/Shift Type grouping.  
  Section 64: Results Set #15 - Return the result set for Line/Product grouping.  
  Section 65: Results Set #16 - Return the result set for Line/Location Type grouping.  
  Section 66: Results Set #17 - Return the result set for Line/Category grouping.  
  Section 67: Results Set #18 - Return the result set for Line/Schedule grouping.  
  Section 68: Results Set #13 if @BySummary = 0. Else, Results Set #19.  Return all from @ProdRecords.   
  end  
----------------------------------------------------------------------------------------------------------  
----------------------------------------------------------------------------------------------------------  
*/  
  
CREATE PROCEDURE dbo.spLocal_RptCvtgDDSStops  
-- declare  
  @StartTime  DATETIME,  -- Beginning period for the data.  
 @EndTime   DATETIME,  -- Ending period for the data.  
 @RptName   VARCHAR(100) -- Report_Definitions.RP_Name  
  
AS  
  
  
-------------------------------------------------------------------------------  
-- Control settings  
-------------------------------------------------------------------------------  
SET ANSI_WARNINGS OFF  
SET NOCOUNT ON  
  
  
-------------------------------------------------------------------------------  
-- Declare testing parameters.  
-------------------------------------------------------------------------------  
  
-- AZ  
-- SELECT    
-- @StartTime = '2009-11-11 07:00:00',  
-- @EndTime = '2009-11-12 07:00:00',   
-- @RptName = 'AZAL DDS-Stops MTD 00:00 - 00:00'  
-- @RptName = 'AZAL DDS-Stops 07:00 AM - 07:00 AM'  
  
  
--AY  
-- SELECT    
-- @StartTime  = '2009-07-09 00:00:00',           
-- @EndTime  ='2009-09-01 00:00:00',          --'2005-09-07 00:00:00',   
-- @RptName  = 'AT05-06 DDS - Stops 0730 0730'    -- 'AT Tissue Cvtg DDS - Stops 1st Shift to Date'     --'AKxx DDS - Stops 0630 0630'      -- 'AT07-10 DDS - Stops 0730 0730'   
  
  
-- MP  
--SELECT    
--@StartTime = '2009-02-10 00:00:00',  
--@EndTime = '2009-02-11 00:00:00',   
--@RptName = 'Perini DDS-Stops MT65-66 0600 1800'   
--@RptName = 'Bounty DDS-Stops MK70-72-74-75 - Last Month'  
--@RptName = 'Napkins DDS-Stops MNN1-5 - Last Month'  
  
  
--CAPE  
--SELECT    
--@StartTime = '2008-09-16 07:30:00',   
--@EndTime = '2008-09-17 07:30:00',   
----@RptName = 'Bounty DDS-Stops Last Month'   
--@RptName = 'Tissue April 08 DDS Stops'   
  
  
---- OX  
-- SELECT    
-- @StartTime = '2009-09-14 05:00:00', @EndTime = '2009-09-15 05:00:00', @RptName = '05:00-05:00 DDS Stops OTT1-3'  
-- @StartTime = '2009-08-06 05:00:00', --'2005-09-06 0:00:00',   
-- @EndTime = '2009-08-07 05:00:00', --'2005-09-07 00:00:00',   
-- @RptName = '00:00-00:00 DDS-Stops OTT1-3'   
---- @RptName = 'Towel DDS-Stops OKK1-3 MTD 0500'  
  
  
-- GB  
-- SELECT    
-- @StartTime = '2008-10-08 06:30:00', --'2005-09-06 0:00:00',   
-- @EndTime = '2008-10-09 06:30:00', --'2005-09-07 00:00:00',   
---- @RptName = 'FK68 DDS Last Month'  
-- @RptName =  'PP FFF1 DDS Last Month'   
-- @RptName =  'PP FFF1 DDS Last Month (New)'   
-- @RptName = 'PP FFF7 DDS Last Month'   
----    'FLD Def for Testing'   
  
/*  
-- Neuss  
 SELECT    
 @StartTime = '2007-02-19 06:00:00',   
 @EndTime = '2007-02-20 06:00:00',   
-- @RptName = 'Neuss Tissue DDS-Stops Fr 0600 - Mo 0600'  
 @RptName = 'Neuss Hanky DDS-Stops 545-546 0600 - 0600'  
*/  
  
--select  
-- @StartTime = '2007-01-09 06:00:00',   
-- @EndTime = '2007-01-10 06:00:00',   
-- @RptName = 'Neuss Hanky DDS-Stops 547-548 Frühschicht'  
  
  
-- Witz  
--SELECT  
--@StartTime = '2006-08-06 06:00:00',   
--@EndTime = '2006-08-07 06:00:00',   
--@RptName =  'WT02 DDS 6:00 - 6:00'   
  
  
----------------------------------------------------------  
-- Section 1:  Define variables for this procedure.  
----------------------------------------------------------  
  
-------------------------------------------------------------------------  
-- Report Parameters. 2005-03-16 VMK Rev8.81  
-------------------------------------------------------------------------  
DECLARE   
@ProdLineList     VARCHAR(4000),  -- Collection of Prod_Lines.PL_Id for converting lines delimited by "|".  
@DelayTypeList     VARCHAR(4000),  -- Collection of "DelayType=..." FROM Prod_Units.Extended_Info delimited by "|".  
@CatMechEquipId    INTEGER,    -- Event_Reason_Categories.ERC_Id for Category:Mechanical Equipment.  
@CatElectEquipId    INTEGER,    -- Event_Reason_Categories.ERC_Id for Category:Electrical Equipment.  
@CatProcFailId     INTEGER,    -- Event_Reason_Categories.ERC_Id for Category:Process/Operational.  
--@CatBlockStarvedId   INTEGER,    -- Event_Reason_Categories.ERC_Id for Category:Blocked/Starved. --FLD 07-NOV-2007 Rev11.54  
@CatELPId      INTEGER,    -- Event_Reason_Categories.ERC_Id for Category:Paper (ELP).  
@SchedPRPolyId     INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:PR/Poly Change.  
@SchedUnscheduledId   INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:Unscheduled.  
@SchedSpecialCausesId  INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:Special Causes.  
@SchedEOProjectsId   INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:E.O./Projects.  
@SchedBlockedStarvedId  INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:Blocked/Starved.  
@SchedChangeOverId   INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:Changeover.  
@SchedPlnInterventionId  INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:Planned Intervention.  
@SchedHolidayCurtailId  INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:Holiday/Curtail.  
@SchedHygCleaningId   INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:Planned Hygiene/Cleaning.  
@SchedCLAuditsId    INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:Centerline Checks/Audits.  
@PropCvtgProdFactorId  INTEGER,    -- Product_Properties.Prop_Id for Property containing Stat Factor           
@DefaultPMRollWidth   FLOAT,    -- Default PM Roll Width.  Used when actual PM Roll  
               -- Width's are not available through genealogy.  
@ConvertFtToMM     FLOAT,    -- Conversion to change feet to mm., i.e. value is 304.8   
               -- (12 in/ft * 2.54 cm/in * 10 mm/cm) 1 is already using metric.  
@ConvertInchesToMM   FLOAT,    -- Conversion to change inches to millimeters. Value is 25.4 to  
               -- to convert or 1 if already using metric.  
@BusinessType     INTEGER,    -- 1=Tissue/Towel, 2=Napkins, 3=Facial  
@IncludeTeam     INTEGER,    -- 1=Report Team Breakdown; 0=No Team Breakdown.  
@IncludeStops     INTEGER,    -- 0 = Do not include Stops Pivottable; 1 = Include Stops Pivottable.  
@BySummary      INTEGER,    -- 0 = Do not include additional Stops sheets; 1 = Include additional Stops sheets.  
@RL1Title      VARCHAR(100),  -- Title to be used for Reason Level 1  
@RL2Title      VARCHAR(100),  -- Title to be used for Reason Level 2  
@RL3Title      VARCHAR(100),  -- Title to be used for Reason Level 3  
@RL4Title      VARCHAR(100),  -- Title to be used for Reason Level 4  
@PackPUIdList     VARCHAR(4000),  -- List of Prod_Units.PU_Ids, FROM a 'Pack' Prod Line, to be included in the Pack Prod sheet.  
@UserName      VARCHAR(30),  -- User calling this report  
@RptTitle      VARCHAR(300),  -- Report title from Web Report.  
@RptPageOrientation   VARCHAR(50),  -- Report Page Orientation from Web Report.  
@RptPageSize     VARCHAR(50),   -- Report page Size from Web Report.  
@RptPercentZoom    INTEGER,    -- Percent Zoom from Web Report.  
@RptTimeout      VARCHAR(100),  -- Report Time from Web Report.  
@RptFileLocation    VARCHAR(300),  -- Report file location from WEb Report.  
@RptConnectionString   VARCHAR(300),  -- Connection String from Web Report.  
@RptGroupBy      INTEGER,    -- Group By parameter from Web Report.  
@LineStatusList    VARCHAR(4000),  -- List of valid Line Status values.  If NULL, use all values.  
@RptWindowMaxDays    INTEGER,    -- Maximum number of days allowed in the date range specified for a given report.  
------------------------------------------  
-- declare program variables  
------------------------------------------  
@ScheduleStr     VARCHAR(50),  -- Prefix FROM Event_Reason_Categories.ERC_Desc (portion prior to ":").  
@CategoryStr     VARCHAR(50),  -- Prefix FROM Event_Reason_Categories.ERC_Desc (portion prior to ":").  
@GroupCauseStr     VARCHAR(50),  -- Prefix FROM Event_Reason_Categories.ERC_Desc (portion prior to ":").  
@SubSystemStr     VARCHAR(50),  -- Prefix FROM Event_Reason_Categories.ERC_Desc (portion prior to ":").  
@DelayTypeRateLossStr  VARCHAR(100),  -- Prod_Units.Extended_Info string for the RateLoss Delay Type.  
  
@LanguageId      INTEGER,  
@UserId       INTEGER,  
@LanguageParmId    INTEGER,  
  
@SQL        nVARCHAR(4000),  
  
@PacksInBundleSpecDesc  VARCHAR(100),  
@SheetCountSpecDesc   VARCHAR(100),  
@CartonsInCaseSpecDesc  VARCHAR(100),  
@ShipUnitSpecDesc    VARCHAR(100),  
@StatFactorSpecDesc   VARCHAR(100),  
@RollsInPackSpecDesc   VARCHAR(100),  
@SheetWidthSpecDesc   VARCHAR(100),  
@SheetLengthSpecDesc   VARCHAR(100),  
@PacksInBundleSpecId   INTEGER,  
@SheetCountSpecId    INTEGER,  
@CartonsInCaseSpecId   INTEGER,  
@ShipUnitSpecId    INTEGER,  
@StatFactorSpecId    INTEGER,  
@RollsInPackSpecId   INTEGER,  
@SheetWidthSpecId    INTEGER,  
@SheetLengthSpecId   INTEGER,  
  
@PackOrLineStr     varchar(50),  
@VarGoodUnitsVN    varchar(50),  
@VarTotalUnitsVN    varchar(50),  
@VarPMRollWidthVN    varchar(50),  
@VarParentRollWidthVN   varchar(50),  
@VarEffDowntimeVN    varchar(50),  
@VarActualLineSpeedVN   varchar(50),  
@VarStartTimeVN    varchar(50),  
@VarEndTimeVN     varchar(50),  
@VarPRIDVN      varchar(50),  
@VarParentPRIDVN    varchar(50),  
--@VarGrandParentPRIDVN  varchar(50),  
@VarUnwindStandVN    varchar(50),  
@VarLineSpeedVN    varchar(50),  
@VarLineSpeedMMinVN   varchar(50), -- Rev11.45  
@LineProdFactorDesc    varchar(50),  
  
@PPTT        varchar(5),  
@SearchString     VARCHAR(4000),  
@Position      INTEGER,  
@PartialString     VARCHAR(4000),  
  
@PUDelayTypeStr    VARCHAR(100),  
@PUScheduleUnitStr   VARCHAR(100),  
@PULineStatusUnitStr   VARCHAR(100),  
@PRIDRLVarStr     VARCHAR(100),  
      
@VarTypeStr      VARCHAR(50),  
@ACPUnitsFlag     VARCHAR(50),  
@HPUnitsFlag     VARCHAR(50),  
@TPUnitsFlag     VARCHAR(50), --Namho  
  
@Row        int,  
@Rows        int,  
@@PUID       int,  
@@StartTime      datetime,  
--@Max_TEDet_Id      int,  
--@Min_TEDet_Id     int,   
@RangeStartTime    datetime,   
@RangeEndTime     datetime,  
  
@ScheduleUnit      int,  
  
@LineSpeedTargetSpecDesc  varchar(50),  
@LineSpeedIdealSpecDesc  varchar(50),  
  
@PUEquipGroupStr    VARCHAR(100),  
          
@NoDataMsg       VARCHAR(100),  
@TooMuchDataMsg     VARCHAR(100),  
@NoTeamInfoMsg     varchar(100),  
  
--Rev11.55  
@RunningStatusID     int,  
  
@VarInputRollVN    varchar(50),  
@VarInputPRIDVN    varchar(50),  
  
--2009-09-09 VMK Rev11.77  
@MinUptimeMinToRpt   INTEGER  
  
  
----------------------------------------------------------  
-- Section 2:  Declare the error messages table  
----------------------------------------------------------  
  
-------------------------------------------------------------------------------  
-- Error Messages  
-------------------------------------------------------------------------------  
DECLARE @ErrorMessages TABLE ( ErrMsg VARCHAR(255) )  
  
  
-------------------------------------------------------------------  
-- Section 3: Get the input parameter values out of the database  
-------------------------------------------------------------------  
  
---------------------------------------------------------------------------------------------------  
-- Retrieve parameter values FROM report definition using spCmn_GetReportParameterValue  
---------------------------------------------------------------------------------------------------   
  
IF Len(@RptName) > 0   
 BEGIN  
 --print 'Get Report Parameters.'  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptPLIdList','',      @ProdLineList OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptDlyTypeList', '',     @DelayTypeList OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'intRptPropCvtgProdFactorId','',  @PropCvtgProdFactorId OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptDefaultPMRollWidth','',   @DefaultPMRollWidth OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptConvertFtToMM', '',    @ConvertFtToMM OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptConvertInchesToMM', '',   @ConvertInchesToMM OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'intRptBusinessType', '',    @BusinessType OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'intRptIncludeTeam', '',     @IncludeTeam OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'intRptIncludeStops', '',    @IncludeStops OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'intRptSummary', '',      @BySummary OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptRL1Title', '',      @RL1Title OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptRL2Title', '',      @RL2Title OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptRL3Title', '',      @RL3Title OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptRL4Title', '',      @RL4Title OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptPackPUIdList', '',    @PackPUIdList OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'Owner', '',         @UserName OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptTitle', '',       @RptTitle OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptPageOrientation', '',   @RptPageOrientation OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptPageSize', '',      @RptPageSize OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'intRptPercentZoom', '',     @RptPercentZoom OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'ReportTimeOut', '',      @RptTimeout OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'ServerFileLocation', '',    @RptFileLocation OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptConnectionString', '',   @RptConnectionString OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'intRptGroupBy', '',      @RptGroupBy OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptLineStatusList', '',    @LineStatusList OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'intRptWindowMaxDays', '',    @RptWindowMaxDays OUTPUT  
 END  
ELSE     
 BEGIN  
 INSERT  @ErrorMessages (ErrMsg)  
  VALUES ('No Report Name specified.')  
 GOTO ReturnResultSets  
 END   
  
if (@LineStatusList IS NULL) or (@LineStatusList='')  
SELECT @LineStatusList='All'  
  
/* this is only for testing  
select  
@IncludeTeam = 1,  
@IncludeStops = 1,  
@BySummary = 1  
*/  
  
-- select @ProdLineList = '32|35|38|40|43|45|46|48|58|60|62|64' --'32'   --|156|157'  
  
--------------------------------------------------------------  
-- Section 4: Assign constant values  
--------------------------------------------------------------  
  
select  
@ScheduleStr    = 'Schedule',  
@CategoryStr    = 'Category',  
@GroupCauseStr    = 'GroupCause',  
@SubSystemStr    = 'Subsystem',  
@DelayTypeRateLossStr = 'RateLoss',  
--@CatBlockStarvedId  = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Category:Blocked/Starved'),  --FLD 07-NOV-2007 Rev11.54  
@CatELPId     = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Category:Paper (ELP)'),  
@CatMechEquipId   = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Category:Mechanical Equipment'),  
@CatElectEquipId   = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Category:Electrical Equipment'),  
@CatProcFailId    = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Category:Process/Operational'),  
@SchedPRPolyId    = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:PR/Poly Change'),  
@SchedUnscheduledId  = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:Unscheduled'),  
@SchedSpecialCausesId = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:Special Causes'),  
@SchedEOProjectsId  = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:E.O./Projects'),  
@SchedBlockedStarvedId = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:Blocked/Starved'),  
@SchedChangeOverId  = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:Changeover'),  
@SchedPlnInterventionId = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:Planned Intervention'),  
@SchedHolidayCurtailId = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:Holiday/Curtail'),  
@SchedHygCleaningId  = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:Planned Hygiene/Cleaning'),  
@SchedCLAuditsId   = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories with (nolock) WHERE Erc_Desc = 'Schedule:Centerline Checks/Audits'),  
  
@PackOrLineStr    = 'PackOrLine=',  
@VarGoodUnitsVN   = 'Good Units',  
@VarTotalUnitsVN   = 'Total Units',  
@VarPMRollWidthVN   = 'PM Roll Width',  
@VarParentRollWidthVN  = 'Parent Roll Width',  
@VarEffDowntimeVN   = 'Effective Downtime',  
@VarActualLineSpeedVN  = 'Line Actual Speed',  
@VarStartTimeVN   = 'Roll Conversion Start Date/Time',  
@VarEndTimeVN    = 'Roll Conversion End Date/Time',  
@VarPRIDVN     = 'PRID',  
@VarParentPRIDVN   = 'Parent PRID',  
--@VarGrandParentPRIDVN = 'Grand Parent PRID',  
@VarUnwindStandVN   = 'Unwind Stand',  
@VarLineSpeedVN   = 'Reports Line Speed',  
@VarLineSpeedMMinVN  = 'Reports Line Speed (m/min)',  -- Rev11.45  
@LineProdFactorDesc   = 'Production Factors',  
  
@PUDelayTypeStr    = 'DelayType=',  
@PUScheduleUnitStr  = 'ScheduleUnit=',  
@PULineStatusUnitStr  = 'LineStatusUnit=',  
@PRIDRLVarStr     = 'Rate Loss PRID',  
    
@VarTypeStr     = 'VarType=',  
@ACPUnitsFlag    = 'ACPUnits',  
@HPUnitsFlag    = 'HPUnits',  
@TPUnitsFlag    = 'TPUnits', --Namho Kim Rev11.16  
  
@StatFactorSpecDesc   = 'Stat Factor',  
@PacksInBundleSpecDesc  = 'Packs In Bundle',   
@SheetCountSpecDesc   = 'Sheet Count',  
@SheetWidthSpecDesc   = 'Sheet Width',  
@SheetLengthSpecDesc  = 'Sheet Length',  
  
@CartonsInCaseSpecDesc  =  CASE @BusinessType  
         WHEN 4   
         THEN 'Bundles In Case'   
         ELSE 'Cartons In Bundle'   
         END,  
  
@RollsInPackSpecDesc  =  CASE @BusinessType  
         WHEN 1   
         THEN 'Rolls In Pack'  
         WHEN 2   
         THEN 'Packs In Pack'  
         WHEN 3   
         THEN 'Rolls In Pack'  
         ELSE 'Rolls In Pack'   
         END,  
  
@ShipUnitSpecDesc   = 'Ship Unit',  
  
@LineSpeedTargetSpecDesc  = 'Line Speed Target',  
@LineSpeedIdealSpecDesc  = 'Line Speed Ideal',  
  
@PUEquipGroupStr   = 'EquipGroup=',  
  
@NoDataMsg = GBDB.dbo.fnLocal_GlblTranslation('NO DATA meets the given criteria', @LanguageId),  
@TooMuchDataMsg = GBDB.dbo.fnLocal_GlblTranslation('There are more results than can be displayed', @LanguageId),  
@NoTeamInfoMsg = GBDB.dbo.fnLocal_GlblTranslation('Insufficient Crew_Schedule information to generate this report...', @LanguageId),  
  
@VarInputRollVN   = 'Input Roll ID',  
@VarInputPRIDVN   = 'Input PRID',  
@MinUptimeMinToRpt  = 120              -- 2009-09-09 VMK Rev11.77 Added. Value in minutes.  
  
--Rev11.55  
--@DBVersion     = (SELECT App_Version FROM dbo.AppVersions WHERE App_Name = 'Database')  
  
IF @BusinessType = 3  
  
 select @PPTT = 'PP '  
else  
 select @PPTT = 'TT '  
  
  
----------------------------------------------------------------------------------  
----------------------------------------------------------------------------------  
-- Section 6: Create temp tables and table variables  
----------------------------------------------------------------------------------  
----------------------------------------------------------------------------------  
  
DECLARE @DelayTypes TABLE   
 (  
 DelayTypeDesc          VARCHAR(100) PRIMARY KEY  
 )  
  
  
-----------------------------------------------------------------------  
-- this table will hold Prod Units data for Converting lines  
-----------------------------------------------------------------------  
  
DECLARE @ProdUnits TABLE   
 (  
 PUId             INTEGER PRIMARY KEY,  
 OrderIndex           int,  
 PUDesc            VARCHAR(100),  
 CombinedPUDesc          VARCHAR(100),  
 PLId             INTEGER,  
 ExtendedInfo          VARCHAR(255),  
 DelayType           VARCHAR(100),  
 ScheduleUnit          INTEGER,  
 LineStatusUnit          INTEGER,  
 UWSVarId            INTEGER,  
 UWS1             VARCHAR(50),  
 UWS2             VARCHAR(50),  
 PRIDRLVarId           INTEGER,  
 RowId             INTEGER IDENTITY  
 )  
  
  
---------------------------------------------------------------  
-- this table will hold Prod Unit data for Pack lines  
--------------------------------------------------------------  
  
DECLARE @ProdUnitsPack TABLE   
 (  
 PUId             INTEGER,  
 PUDesc            varchar(100),   
 PLId             INTEGER,  
 PLDesc            VARCHAR(50),    
 GoodUnitsVarId          INTEGER,  
 ScheduleUnit          INTEGER,  
 UOM             VARCHAR(25)  
 primary key (GoodUnitsVarid, puid)  
 )  
  
  
-------------------------------------------------------------------  
-- This table will hold production variable ID data for each Line  
------------------------------------------------------------------  
  
DECLARE @LineProdVars TABLE   
 (  
 PLId             INTEGER,  
 PUId             INTEGER,  
 VarId             INTEGER,  
 VarType            VARCHAR(25)  
 PRIMARY KEY (plid, varid)  
 )  
  
  
-----------------------------------------------------------------------  
-- this table will hold data about the unwind stands  
-----------------------------------------------------------------------  
  
DECLARE @UWS TABLE   
 (   
 InputName           VARCHAR(50),  
 InputOrder           INTEGER,  
 PLId             INTEGER,  
 PEIId             INTEGER,        -- 2007-01-11 VMK Rev11.30, added  
 UWSPUId            INTEGER primary key   
 )  
  
  
----------------------------------------------------------------------  
-- @RunSummary will summarize the data from @Runs  
-- the dimensions in this table need to be the same as in @Runs  
----------------------------------------------------------------------  
  
DECLARE @RunSummary TABLE   
 (  
 PLId             INTEGER,   
 PUId             INTEGER,  
 Shift             INTEGER,  
 Team             VARCHAR(10),  
 ProdId            INTEGER,  
 TargetSpeed           float,  
 IdealSpeed           float,  
 LineStatus           varchar(50),  
 -- add any additional dimensions that are required  
 StartTime           DATETIME,  
 EndTime            DATETIME,  
 Runtime            FLOAT     -- 2007-03-22 VMK Rev11.37, Added.  
 primary key (puid, starttime)  
 )  
  
  
-------------------------------------------------------------------------------  
--  this table will hold production summaries by shift, team, and product.  
-- this information will later be used to split the downtime events.  
-------------------------------------------------------------------------------  
  
DECLARE @ProdRecords TABLE   
 (  
 PLId             INTEGER,  
 puid             integer,  
 ReliabilityPUID         int,  
 Shift             VARCHAR(50),  
 Team             VARCHAR(50),  
 ProdId            INTEGER,  
 StartTime           DATETIME,  
 EndTime            DATETIME,  
 TotalUnits           float, --INTEGER, -- Rev11.31  
 GoodUnits           float, --INTEGER, -- Rev11.31  
 RejectUnits           float, --INTEGER, -- Rev11.31  
 WebWidth            FLOAT,  
 SheetWidth           FLOAT,  
 LineSpeedIdeal          FLOAT,  
 LineSpeedTarget         FLOAT,  
 LineSpeedAvg          FLOAT,  
 TargetLineSpeed         FLOAT,    
 LineStatus           varchar(50),  
 RollsPerLog           float, --INTEGER, -- Rev11.31  
 RollsInPack           float, --INTEGER, -- Rev11.31  
 PacksInBundle          float, --INTEGER, -- Rev11.31  
 CartonsInCase          float, --INTEGER, -- Rev11.31  
 SheetCount           float, --INTEGER, -- Rev11.31  
 ShipUnit            INTEGER,  
 CalendarRuntime         FLOAT,  
 ProductionRuntime         FLOAT,  
 PlanningRuntime         FLOAT,  
 OperationsRuntime         FLOAT,  
 SheetLength           FLOAT,  
 StatFactor           FLOAT,  
 TargetUnits           float, --INTEGER, -- Rev11.31  
 ActualUnits           float, --INTEGER, -- Rev11.31  
 OperationsTargetUnits       float, --INTEGER, -- Rev11.31  
 HolidayCurtailDT         FLOAT,  
 PlninterventionDT         FLOAT,  
 ChangeOverDT          FLOAT,  
 HygCleaningDT          FLOAT,  
 EOProjectsDT          FLOAT,  
 UnscheduledDT          FLOAT,  
 CLAuditsDT           FLOAT,  
 IdealUnits           float, --INTEGER, -- Rev11.31   
 RollWidth2Stage         float,  
 RollWidth3Stage         float,  
 SplitUptime           float, -- Rev11.31  
 Runtime            FLOAT  -- 2007-03-22 VMK Rev11.37, Added  
 primary key (puid, starttime) --team, shift, prodid, starttime)  
 )  
  
  
---------------------------------------------------------------  
-- @ProductionStarts will hold the Production Starts information  
-- along with related product information  
---------------------------------------------------------------  
  
declare @ProductionStarts table  
 (  
 StartId            INTEGER,   -- 2009-08-31 VMK Rev11.77, Added.  
 Start_Time           datetime,  
 End_Time            datetime,  
 Prod_ID            int,  
 Prod_Code           varchar(50),  
 Prod_Desc           varchar(50),  
 PU_ID             int--,  
 primary key (pu_id, prod_id, start_time)  
 )  
  
  
------------------------------------------------------------------  
-- @Products will hold product information, as derived from  
-- @ProductionStarts  
-------------------------------------------------------------------  
  
declare @Products table  
 (  
 Prod_ID            int primary key,  
 Prod_Code           varchar(50),  
 Prod_Desc           varchar(50)--,  
 )  
  
---------------------------------------------------------------------------  
-- this table will hold active specification information, as related to  
-- characteristics, specifications, and properties.  
----------------------------------------------------------------------------  
  
declare @ActiveSpecs table  
 (  
 AS_Id             INTEGER,     -- 2009-08-31 VMK Rev11.77, Added.  
 effective_date          DATETIME,  
 expiration_date         datetime,  
 prod_id            int,   
 char_id            int,  
 char_desc           varchar(50),  
 spec_id            int,  
 spec_desc           varchar(50),  
 prop_id            int,  
 prop_desc           varchar(50),  
 target            varchar(50)--,  
 primary key (prod_id, effective_date, expiration_date, char_id, spec_id, prop_id)  
 )  
  
  
----------------------------------------------------------------------------------  
-- @CrewSchedule will hold information pertaining to the crew and shift schedule  
---------------------------------------------------------------------------------  
  
declare @CrewSchedule table  
 (  
 CS_Id             INTEGER,     -- 2009-08-31 VMK Rev11.77, Added.  
 Start_Time           datetime,  
 End_Time            datetime,  
 pu_id             int,  
 Crew_Desc           varchar(10),  
 Shift_Desc           varchar(10)--,  
 primary key (pu_id, start_time)  
 )  
  
/*  
------------------------------------------------------------------  
-- This table will hold the category information based on the   
-- values specific specific to each location.  
------------------------------------------------------------------  
  
declare @TECategories table   
 (  
 TEDet_Id            INTEGER,  
 ERC_Id            int  
 primary key (TEDet_ID, ERC_ID)  
 )  
*/  
  
--------------------------------------------------------------------------  
-- this table holds information about the Event Reasons.  
--------------------------------------------------------------------------  
  
declare @EventReasons table   
 (  
 Event_Reason_ID         int PRIMARY KEY NONCLUSTERED,  
 Event_Reason_Name         varchar(100)  
 )  
  
  
-----------------------------------------------------------------------------  
-- this table will hold the Equipment Group information for prod units  
----------------------------------------------------------------------------  
  
DECLARE @ProdUnitsEG TABLE   
 (   
 RowId             int PRIMARY KEY IDENTITY,  
 PLId             INTEGER,  
 Source_PUId           INTEGER,  
 EquipGroup           VARCHAR(100)   
 )  
  
  
-----------------------------------------------------------------------  
-- this table will hold comments associated with #delays  
-----------------------------------------------------------------------  
  
 declare @WasteNTimedComments table  
  (  
  timestamp           datetime,  
  comment_text          varchar(5000),  
  wtc_type            int,  
  wtc_source_id          int  
  primary key (wtc_source_id, timestamp,wtc_type)  
  )  
  
  
-- Rev11.31  
declare @VariableList table   
 (  
 Var_Id           int primary key,  
 var_desc     varchar(50),  
 pl_id      int,  
 pu_id      int,  
 eng_units    varchar(50),  
 extended_info   varchar(200)   
 )  
  
  
declare @SplitDT_UnitTeam table  
 (  
 [PLID]      int,  
 [PUID]      int,  
 [Team]      varchar(10),  
 [Stops]      int,  
 [StopsUnscheduled]  int,  
 [StopsMinor]    int,  
 [StopsEquipFails]   int,  
 [StopsProcessFailures] int,  
 [SplitDowntime]   float,  
 [UnschedSplitDT]   float,  
 [RawUptime]     float,  
 [SplitUptime]    float,  
 [Uptime2Min]     int,  
 [R2Numerator]     float,  
 [R2Denominator]    float,  
 [HolidayCurtailDT]  float,  
 [StopsELP]     int,  
 [ELPDowntime]     float,  
 [RLELPDowntime]    float,  
 [StopsRateLoss]    int,  
 [SplitRLDowntime]   float,  
 [PRPolyChangeEvents]  int,  
 [PRPolyChangeDowntime]  float  
 primary key (puid, team)  
 )  
  
  
declare @SplitDT_Unit table  
 (  
 [PLID]      int,  
 [PUID]      int primary key,  
 [Stops]      int,  
 [StopsUnscheduled]  int,  
 [StopsMinor]    int,  
 [StopsEquipFails]   int,  
 [StopsProcessFailures] int,  
 [SplitDowntime]   float,  
 [UnschedSplitDT]   float,  
 [RawUptime]     float,  
 [SplitUptime]    float,  
 [Uptime2Min]     int,  
 [R2Numerator]     float,  
 [R2Denominator]    float,  
 [HolidayCurtailDT]  float,  
 [StopsELP]     int,  
 [ELPDowntime]     float,  
 [RLELPDowntime]    float,  
 [StopsRateLoss]    int,  
 [SplitRLDowntime]   float,  
 [PRPolyChangeEvents]  int,  
 [PRPolyChangeDowntime]  float  
 )  
  
  
declare @SplitDT_Line table  
 (  
 [PLID]      int primary key,  
 [Stops]      int,  
 [StopsUnscheduled]  int,  
 [StopsMinor]    int,  
 [StopsEquipFails]   int,  
 [StopsProcessFailures] int,  
 [SplitDowntime]   float,  
 [UnschedSplitDT]   float,  
 [RawUptime]     float,  
 [SplitUptime]    float,  
 [Uptime2Min]     int,  
 [R2Numerator]     float,  
 [R2Denominator]    float,  
 [HolidayCurtailDT]  float,  
 [StopsELP]     int,  
 [ELPDowntime]     float,  
 [RLELPDowntime]    float,  
 [StopsRateLoss]    int,  
 [SplitRLDowntime]   float,  
 [PRPolyChangeEvents]  int,  
 [PRPolyChangeDowntime]  float,  
 [StopsPerDayDenomUT]  float  
 )  
  
  
  
declare @PRDTSums_UnitTeam table   
 (   
 [PUID]       int, -- primary key,  
 [PLID]       int,  
 [Team]       varchar(10),  
----- Metics by Line  
 [Stops]       INTEGER,  
 [StopsUnscheduled]   INTEGER,  
 [StopsMinor]     INTEGER,  
 [StopsEquipFails]    INTEGER,  
 [StopsProcessFailures]  INTEGER,  
 [SplitDowntime]    FLOAT,  
 [UnschedSplitDT]    FLOAT,  
 [RawUptime]      FLOAT,  
 [SplitUptime]     FLOAT,  
 [Uptime2Min]     INTEGER,  
 [R2Numerator]     float,  
 [R2Denominator]    float,  
 [StopsELP]      INTEGER,  
 [ELPDowntime]     float,  
 [RLELPDowntime]    float,  
 [ELPMins]      FLOAT,  
 [PaperRuntimeRaw]    float,  
 [Runtime]      float,  
 [ELPSchedDT]     float,  
   [PaperRuntime]             FLOAT,    
 [HolidayCurtailDT]   float,  
   [ProductionRuntime]        FLOAT,  
 [StopsRateLoss]    INTEGER,  
 [SplitRLDowntime]    FLOAT,  
 [PRPolyChangeEvents]   int,   
 [PRPolyChangeDowntime]  float  
 )    
  
  
declare @PRDTSums_Unit table   
 (   
 [PUID]       int,  
 [PLID]       int,  
----- Metics by Line  
 [Stops]       INTEGER,  
 [StopsUnscheduled]   INTEGER,  
 [StopsMinor]     INTEGER,  
 [StopsEquipFails]    INTEGER,  
 [StopsProcessFailures]  INTEGER,  
 [SplitDowntime]    FLOAT,  
 [UnschedSplitDT]    FLOAT,  
 [RawUptime]      FLOAT,  
 [SplitUptime]     FLOAT,  
 [Uptime2Min]     INTEGER,  
 [R2Numerator]     float,  
 [R2Denominator]    float,  
 [StopsELP]      INTEGER,  
 [ELPDowntime]     float,  
 [RLELPDowntime]    float,  
 [ELPMins]      FLOAT,  
 [PaperRuntimeRaw]    float,  
 [Runtime]      float,  
 [ELPSchedDT]     float,  
   [PaperRuntime]             FLOAT,    
 [HolidayCurtailDT]   float,  
   [ProductionRuntime]        FLOAT,  
 [StopsRateLoss]    INTEGER,  
 [SplitRLDowntime]    FLOAT,  
 [PRPolyChangeEvents]   int,   
 [PRPolyChangeDowntime]  float  
 )    
  
  
declare @PRDTSums_Line table   
 (   
 [PLID]       int primary key,  
----- Metics by Line  
 [Stops]       INTEGER,  
 [StopsUnscheduled]   INTEGER,  
 [StopsMinor]     INTEGER,  
 [StopsEquipFails]    INTEGER,  
 [StopsProcessFailures]  INTEGER,  
 [SplitDowntime]    FLOAT,  
 [UnschedSplitDT]    FLOAT,  
 [RawUptime]      FLOAT,  
 [SplitUptime]     FLOAT,  
 [Uptime2Min]     INTEGER,  
 [R2Numerator]     float,  
 [R2Denominator]    float,  
 [StopsELP]      INTEGER,  
 [ELPDowntime]     float,  
 [RLELPDowntime]    float,  
 [ELPMins]      FLOAT,  
 [PaperRuntimeRaw]    float,  
 [Runtime]      float,  
 [ELPSchedDT]     float,  
   [PaperRuntime]             FLOAT,    
 [HolidayCurtailDT]   float,  
   [ProductionRuntime]        FLOAT,  
 [StopsRateLoss]    INTEGER,  
 [SplitRLDowntime]    FLOAT,  
 [PRPolyChangeEvents]   int,   
 [PRPolyChangeDowntime]  float,  
 [StopsPerDayDenomUT]   float  
 )    
  
  
 declare @PEI table  
  (  
  pu_id   int,  
  pei_id  int,  
  Input_Order int,  
  Input_name varchar(50)  
  primary key (pu_id,input_name)  
  )  
  
  
declare @PRDTOutsideWindow table  
 (  
 TEDetID    int,  
 EventID    int,  
 SourceEventID  int,  
 PLID     int,  
 CvtgPUID    int,  
 ProdPUID    int,   PRPUID    int,  
 EventTimestamp  datetime,  
 SourceTimestamp datetime,  
 ParentPRID   varchar(50),  
 GrandParentPRID varchar(50),  
 PMTeam    varchar(5),  
 UWS     varchar(50),  
 Input_Order   int,  
 ParentType   int,  
 INTR     int  
 primary key (EventID,TEDetID)  
 )  
  
  
declare @DelaysOutsideWindow table  
 (  
 TEDetID  int,  
 PLID   int,  
 PUID   int,  
 ProdPUID  int,  
 StartTime datetime  
 primary key (prodpuid, starttime, puid)  
 )  
  
  
----------------------------------------------------------------------------------  
-- @runs will be the final production runs, as split by the dimensions  
----------------------------------------------------------------------------------  
  
--Rev11.55  
declare @runs table  
(  
 PLID             integer,  
 PUID             integer,  
 Shift             varchar(10),   
 Team             varchar(10),   
 ShiftStart           datetime,  
 ProdId            integer,  
 TargetSpeed           float,  
 IdealSpeed           float,  
 LineStatus           varchar(50),  
 -- add any additional dimensions that are required  
 StartTime           datetime,  
 EndTime            datetime  
 primary key (puid, starttime)   
)  
  
  
--Rev11.55  
  
--create table dbo.#ELPMetrics_UnitTeam   
declare @ELPMetrics_UnitTeam table   
 (   
 id_num       int,  
 [PLID]       int,  
 [PUID]       int,  
 [Team]       VARCHAR(10),  
 LineStatus      varchar(50),  
 StartTime      DATETIME,  
 EndTime       DATETIME,  
----- Metric by Unit and Team  
 [PaperRuntimeRaw]    float,  
 [ELPSchedDT]     float--,  
-- [HolidayCurtailDT]   float  
 )    
  
--CREATE CLUSTERED INDEX prs_PUId_team_StartTime  
--ON dbo.#ELPMetrics_UnitTeam (puid, team, starttime)  
  
  
--create table dbo.#ELPMetrics_Unit   
declare @ELPMetrics_Unit table   
 (   
 id_num       int,  
 [PLID]       int,  
 [PUID]       int,  
 LineStatus      varchar(50),  
 StartTime      DATETIME,  
 EndTime       DATETIME,  
----- Metrics by Unit  
 [PaperRuntimeRaw]    float,  
 [ELPSchedDT]     float--,  
-- [HolidayCurtailDT]   float  
 )    
  
--CREATE CLUSTERED INDEX prs_PUId_StartTime  
--ON dbo.#ELPMetrics_Unit (puid, starttime)  
  
  
--create table dbo.#ELPMetrics_Line   
declare @ELPMetrics_Line table  
 (   
 id_num       int,  
 [PLID]       int,  
 LineStatus      varchar(50),  
 StartTime      DATETIME,  
 EndTime       DATETIME,  
----- Metics by Line  
 [PaperRuntimeRaw]    float,  
 [ELPSchedDT]     float--,  
-- [HolidayCurtailDT]   float  
 )    
  
--CREATE CLUSTERED INDEX prs_PLID_StartTime  
--ON dbo.#ELPMetrics_Line (plid, starttime)  
  
  
-- Rev11.33  
--create table #ProdLines  
declare @ProdLines table  
 (  
 PLId             int primary key,  
 PLDesc            VARCHAR(50),  
 ProdPUID            integer,  
 ReliabilityPUID         integer,  
 RatelossPUID          integer,  
 RollsPUID           int,  
 CvtrBlockedStarvedPUID       int,  
 PackOrLine           varchar(5),  
 VarGoodUnitsId          INTEGER,  
 VarTotalUnitsId         INTEGER,  
 VarPMRollWidthId         INTEGER,  
 VarParentRollWidthId        INTEGER,  
 PropLineProdFactorId        INTEGER,  
 VarEffDowntimeId         INTEGER,  
 TotalStops           INTEGER,  
 TotalUptime           INTEGER,  
 TotalDowntime          INTEGER,  
 TotalStopsUTGT2Min        INTEGER,  
 VarActualLineSpeedId        INTEGER,  
-- VarStartTimeId          INTEGER,   
-- VarEndTimeId          INTEGER,   
 VarPRIDId           INTEGER,  
 VarParentPRIDId         INTEGER,  
-- VarGrandParentPRIDId        INTEGER,  
 VarUnwindStandId         INTEGER,   
 VarLineSpeedId          INTEGER,  
-- VarInputRollID          int,  
-- VarInputPRIDID          int,  
 Extended_Info          varchar(225),  
 ProductionRuntime         FLOAT,     -- 2007-04-11 VMK Rev11.37, Added.  
 PaperRuntime          FLOAT     -- 2007-04-11 VMK Rev11.37, Added.  
 )   
  
  
--/*  
declare @ESTOutsideWindow table  
 (  
 Event_ID   int,  
 Start_Time  datetime,  
 End_Time   datetime,  
 Event_Status int  
 )  
  
--CREATE CLUSTERED INDEX estow_eventid_starttime  
--ON dbo.#ESTOutsideWindow (event_id, start_time)  
--*/  
  
-- 2009-09-23 VMK Rev11.82 Table used for Data Quality Issues reporting.  
DECLARE @DataQA TABLE (  
 Issue       VARCHAR(100),  
 PLId       INTEGER,  
 PUId       INTEGER,  
 PUDesc      VARCHAR(100),  
 StartTime     DATETIME,  
 EndTime      DATETIME,  
 Downtime      FLOAT,  
 Uptime      FLOAT,  
 L1ReasonId     INTEGER,  
 L2ReasonId     INTEGER,  
 ScheduleId     INTEGER,  
 CategoryId     INTEGER )  
  
-- Rev11.55  
create table #PRsRun  
 (  
 Id_Num            INTEGER IDENTITY(1,1),   
 SourceID            int,  
 EventId            INTEGER,  
 PLID             int,  
 PUId             INTEGER,  
 PEIId             INTEGER,    
 [EventNum]           varchar(50),  
 StartTime           DATETIME,  
 EndTime            DATETIME,  
 InitEndTime           DATETIME, -- Rev11.33  
 PRPUId            INTEGER,   -- 2007-04-06 VMK Rev11.37, added  
 [PRPLID]            int,  
 PRTimeStamp           DATETIME,  -- 2007-04-06 VMK Rev11.37, added  
 ParentPRID           VARCHAR(50),   
 GrandParentPRID         VARCHAR(50),   
 UWS             VARCHAR(25),  
 InputOrder           INTEGER,  
 [LineStatus]          varchar(100),  
 EventTimestamp          datetime,  
 GPPRIDVarID           int,  
 DevComment           varchar(100)--, --Rev11.33  
 PRIMARY KEY (Id_Num, PUId, StartTime)   
  )  
  
CREATE NONCLUSTERED INDEX prs_PUId_StartTime_initendtime  
ON dbo.#PRsRun (puid, starttime, initendtime, peiid)  
  
CREATE NONCLUSTERED INDEX prs_PUId_StartTime_endtime  
ON dbo.#PRsRun (puid, starttime, endtime, peiid)  
  
  
------------------------------------------------------------  
-- #LimitTests is an intermediary table that will be used   
-- to load @PackTests  
-----------------------------------------------------------  
  
create table #LimitTests  
 (  
 result_on           datetime,  
 result            varchar(25),  
 var_id            int--,  
 primary key (var_id, result_on)  
 )  
  
  
------------------------------------------------------------  
-- This table will hold test information for the Pack lines  
------------------------------------------------------------  
  
create table #PackTests  
 (  
 TestId            int IDENTITY,  
 VarId             INTEGER,  
 PLId             INTEGER,  
 PUId             INTEGER,  
 Value             FLOAT,  
 SampleTime           DATETIME,  
 ProdId            INTEGER,  
 UOM             VARCHAR(50)--,  
 primary key (puid, varid, sampletime)  
 )  
  
  
----------------------------------------------------------------------------------  
-- #delays are the downtime events that need to be tracked for the report.  
---------------------------------------------------------------------------------  
  
CREATE TABLE dbo.#Delays   
 (  
 TEDetId            int PRIMARY KEY nonCLUSTERED,  
 PrimaryId           INTEGER,  
 SecondaryId           INTEGER,  
 PUId             INTEGER,  
 PLID             INTEGER,  
 PUDesc            VARCHAR(100),  
 StartTime           DATETIME,  
 EndTime            DATETIME,  
 LocationId           INTEGER,  
 L1ReasonId           INTEGER,  
 L2ReasonId           INTEGER,  
 L3ReasonId           INTEGER,  
 L4ReasonId           INTEGER,  
 TEFaultId           INTEGER,  
 ERTD_ID            int,  
 L1TreeNodeId          INTEGER,  
 L2TreeNodeId          INTEGER,  
 L3TreeNodeId          INTEGER,  
 L4TreeNodeId          INTEGER,  
 ScheduleId           INTEGER,  
 CategoryId           INTEGER,  
 GroupCauseId          INTEGER,  
 SubSystemId           INTEGER,  
 DownTime            float,  
 SplitDowntime          float,  
 UpTime            float,  
--Rev11.55  
 RawRateloss           float,  
 Stops             INTEGER,  
 StopsUnscheduled         INTEGER,  
 StopsMinor           INTEGER,  
 StopsEquipFails         INTEGER,  
 StopsProcessFailures        INTEGER,  
 StopsELP            INTEGER,  
 SplitELPDowntime         float,  
 StopsBlockedStarved        INTEGER,  
 SplitELPSchedDT         float,  
 UpTime2m            INTEGER,  
 StopsRateLoss          INTEGER,  
 RateLossInWindow         FLOAT,  
 RateLossRatio          FLOAT,  
 RateLossPRID          VARCHAR(50),  
 LineTargetSpeed         FLOAT,  
 LineActualSpeed         FLOAT,  
 UWS1Parent           VARCHAR(50),  
 UWS1GrandParent         VARCHAR(50),  
 UWS2Parent           VARCHAR(50),  
 UWS2GrandParent         VARCHAR(50),  
 Comment            VARCHAR(5000),  
 InRptWindow           int  
 )  
  
CREATE NONCLUSTERED INDEX td_PUId_StartTime  
 ON dbo.#Delays (puid, starttime, endtime)  
  
  
--------------------------------------------------------------------  
-- This is an intermediary table that will be used to compile the   
-- basic information in #delays.  
--------------------------------------------------------------------  
  
create table dbo.#TimedEventDetails  
 (  
 TEDet_ID            int PRIMARY KEY NONCLUSTERED,  
 Start_Time           datetime,  
 End_Time            datetime,  
 PU_ID             int,  
 Source_PU_Id          int,  
 --Rev11.55  
 Uptime            float,  
 Reason_Level1          int,  
 Reason_Level2          int,  
 Reason_Level3          int,  
 Reason_Level4          int,  
 TEFault_Id           int,  
 ERTD_ID            int,  
 Cause_Comment_Id         int,     --Used only by the 4.x code.  
 Cause_Comment          VARCHAR(5000) --Used only by the 4.x code.  
 )  
  
CREATE CLUSTERED INDEX ted_TEDetId_ERCId  
ON dbo.#TimedEventDetails (pu_id, start_time, end_time)  
  
  
------------------------------------------------------------------------  
-- This table will hold test related information for cvtg and rate loss  
-----------------------------------------------------------------------  
  
CREATE TABLE dbo.#Tests   
 (  
 VarId             INTEGER,  
 PLId             INTEGER,  
 PUId             INTEGER,  
 ProdId            INTEGER,  
 ProdCode            VARCHAR(25),  
 Value             varchar(50),  
 SheetValue           varchar(100),  
 SampleTime           DATETIME,  
 UOM             varchar(50)--,  
 primary key (varid, sampletime)  
 )  
  
  
---------------------------------------------------------------  
  
--  #SplitDowntimes will split the #delays information according   
-- to changes in @ProductionRunsShift  
---------------------------------------------------------------  
  
CREATE TABLE  dbo.#SplitDowntimes   
 (  
 seid             int IDENTITY,  
 StartTime           DATETIME,  
 EndTime            DATETIME,  
 NextStartTime          datetime,  
 ProdId            INTEGER,  
 PLID             INTEGER,  
 PUId             INTEGER,  
-- OrderIndex           int,  
 pudesc            VARCHAR(100),  
 Shift             VARCHAR(10),  
 Team             VARCHAR(10),  
 PrimaryId           INTEGER,  
 TEDetId            INTEGER,   
 TEFaultId           INTEGER,  
 ScheduleId           INTEGER,  
 CategoryId           INTEGER,  
 SubSystemId           INTEGER,  
 GroupCauseId          INTEGER,  
 LocationId           INTEGER,  
 L1ReasonId           INTEGER,  
 L2ReasonId           INTEGER,  
 L3ReasonId           INTEGER,  
 L4ReasonId           INTEGER,  
 LineStatus           VARCHAR(50),  
 Downtime            FLOAT,  
 SplitDowntime          FLOAT,  
 SplitRLDowntime         FLOAT,  
 RateLossInWindow         FLOAT,  
 Uptime            FLOAT,  
--Rev11.55  
 RawRateloss           float,  
 SplitUptime           FLOAT,  
 RateLossRatio          FLOAT,  
 Stops             INTEGER,  
 StopsUnscheduled         INTEGER,  
 StopsMinor           INTEGER,  
 StopsEquipFails         INTEGER,  
 StopsProcessFailures        INTEGER,  
 StopsBlockedStarved        INTEGER,  
 StopsELP            INTEGER,  
 StopsRateLoss          INTEGER,  
 UpTime2m            INTEGER,  
 MinorEF            INTEGER,  
 ModerateEF           INTEGER,  
 MajorEF            INTEGER,  
 MinorPF            INTEGER,  
 ModeratePF           INTEGER,  
 MajorPF            INTEGER,  
 Causes            INTEGER,  
 Comment            VARCHAR(5000),  
 SplitELPDowntime         FLOAT,  
 SplitELPSchedDT         FLOAT,  
 SplitRLELPDowntime        FLOAT,  
 SplitUnscheduledDT        float, -- ???????????????????  
 LineTargetSpeed         FLOAT,  
 LineActualSpeed         FLOAT,  
 UWS1Parent           VARCHAR(50),  
 UWS1GrandParent         VARCHAR(50),  
 UWS2Parent           VARCHAR(50),  
 UWS2GrandParent         VARCHAR(50),  
 LineIdealSpeed          FLOAT,  
 Runtime            float,  
 DelayType           VARCHAR(100)  
 primary key (puid, starttime, endtime)  
 )  
  
CREATE nonCLUSTERED INDEX se_seid  
 ON dbo.#SplitDowntimes (seid)  
  
  
---------------------------------------------------------------  
-- Once downtime events have been split, we can account for   
-- periods of uptime.  this table will hold that information.  
--------------------------------------------------------------  
  
CREATE TABLE  dbo.#SplitUptime   
 (  
 suid             INTEGER,  
 StartTime           DATETIME,  
 EndTime            DATETIME,  
 ProdId            INTEGER,  
 PLID             INTEGER,  
 PUId             INTEGER,  
 pudesc            VARCHAR(100),  
 Shift             VARCHAR(10),  
 Team             VARCHAR(10),  
 LineSpeedAvg          float, --int, -- Rev11.35  
 LineTargetSpeed         float, --int, -- Rev11.35  
 LineIdealSpeed          float, --int, -- Rev11.35  
 SplitUptime           FLOAT,    
 LineStatus           VARCHAR(50),  
 Comment            varchar(100)  
 primary key (puid, starttime, endtime)  
 )  
  
CREATE nonCLUSTERED INDEX su_suid  
 ON dbo.#SplitUptime (suid)  
  
  
----------------------------------------------------------------  
-- this table holds stops information groups by master unit   
-- and team  
---------------------------------------------------------------  
  
CREATE TABLE dbo.#UnitStops   
 (   
 -- OrderIndex has to be the first column in this result set  
 [OrderIndex]          int,  
 [Production Line]         VARCHAR(50),  
 [Master Unit]          VARCHAR(50),  
 [Team]            VARCHAR(10),  
 [Total Stops]          INTEGER,  
 [Unscheduled Stops]        INTEGER,  
 [Unscheduled Stops/Day]       INTEGER,  --FLD 01-NOV-2007 Rev11.53  
 [Minor Stops]          INTEGER,  
 [Equipment Failures]        INTEGER,  
 [Process Failures]        INTEGER,  
 [Split Downtime]         FLOAT,  
 [Unscheduled Split DT]       FLOAT,  
 [Raw Uptime]          FLOAT,  
 [Split Uptime]          FLOAT,  
 [Planned Availability]       FLOAT,  
 [Stops with Uptime <2 Min]         INTEGER,  
 [R(2)]            FLOAT,  
 [Unplanned MTBF]         FLOAT,  
 [Unplanned MTTR]         FLOAT,  
 [ELP Stops]           INTEGER,  
 [ELP Losses (Mins)]        FLOAT,  
 [ELP %]            FLOAT,  
 [Rate Loss Events]        INTEGER,  
 [Rate Loss Effective Downtime]    FLOAT,  
 [Rate Loss %]          FLOAT,  
   [Paper Runtime]                        FLOAT,    
   [Production Time]                      FLOAT,  
 [PR/Poly Change Events]       int,  -- Rev11.29  
 [PR/Poly Change Downtime]      float, -- Rev11.29  
 [Avg PR/Poly Change Time]      float  -- Rev11.29  
 primary key ([Production Line], [Master Unit], [Team])  -- Rev11.50  
 )    
  
  
-------------------------------------------------------------  
-- this table summarizes stops information grouped by Line  
------------------------------------------------------------  
  
CREATE TABLE dbo.#LineStops   
 (   
 [Production Line]         VARCHAR(50),  
 [Master Unit]          VARCHAR(50),  
 [Team]            VARCHAR(10),  
 [Total Stops]          INTEGER,  
 [Unscheduled Stops]        INTEGER,  
 [Unscheduled Stops/Day]       INTEGER,  --FLD 01-NOV-2007 Rev11.53  
 [Minor Stops]          INTEGER,  
 [Equipment Failures]        INTEGER,  
 [Process Failures]        INTEGER,  
 [Split Downtime]         FLOAT,  
 [Unscheduled Split DT]       FLOAT,  
 [Raw Uptime]          FLOAT,  
 [Split Uptime]          FLOAT,  
 [Planned Availability]       VARCHAR(8),  
 [Stops with Uptime <2 Min]         INTEGER,  
 [R(2)]            VARCHAR(8),  
 [Unplanned MTBF]         FLOAT,  
 [Unplanned MTTR]         FLOAT,  
 [ELP Stops]           INTEGER,  
 [ELP Losses (Mins)]        FLOAT,    
 [ELP %]            FLOAT,   
 [Rate Loss Events]        INTEGER,  
 [Rate Loss Effective Downtime]    FLOAT,   
 [Rate Loss %]          FLOAT,   
   [Paper Runtime]                        FLOAT,   
   [Production Time]                      FLOAT,  
 [PR/Poly Change Events]       VARCHAR(8), -- Rev11.29  
 [PR/Poly Change Downtime]      VARCHAR(8), -- Rev11.29  
 [Avg PR/Poly Change Time]      VARCHAR(8) -- Rev11.29  
 )    
  
  
--------------------------------------------------------------------  
-- This table will summarize stops information grouped as either   
-- Line or Pack.  
--------------------------------------------------------------------  
  
CREATE TABLE dbo.#LinePackStops   
 (   
 [Group Type]          VARCHAR(50) primary key,  
 [Master Unit]          VARCHAR(50),  
 [Team]            VARCHAR(10),  
 [Total Stops]          INTEGER,  
 [Unscheduled Stops]        INTEGER,  
 [Unscheduled Stops/Day]       INTEGER,  --FLD 01-NOV-2007 Rev11.53  
 [Minor Stops]          INTEGER,  
 [Equipment Failures]        INTEGER,  
 [Process Failures]        INTEGER,  
 [Split Downtime]         FLOAT,  
 [Unscheduled Split DT]       FLOAT,  
 [Raw Uptime]          FLOAT,  
 [Split Uptime]          FLOAT,  
 [Planned Availability]       VARCHAR(8),  
 [Stops with Uptime <2 Min]         INTEGER,  
 [R(2)]            VARCHAR(8),  
 [Unplanned MTBF]         FLOAT,  
 [Unplanned MTTR]         FLOAT,  
 [ELP Stops]           INTEGER,  
 [ELP Losses (Mins)]        FLOAT,  
 [ELP %]            FLOAT,  
 [Rate Loss Events]        INTEGER,  
 [Rate Loss Effective Downtime]    FLOAT,  
 [Rate Loss %]          FLOAT,  
   [Paper Runtime]                         FLOAT,  
   [Production Time]                       FLOAT,  
 [PR/Poly Change Events]       VARCHAR(8), -- Rev11.29  
 [PR/Poly Change Downtime]      VARCHAR(8), -- Rev11.29  
 [Avg PR/Poly Change Time]      VARCHAR(8) -- Rev11.29  
)  
  
  
-----------------------------------------------------------------------  
-- this table will give an overall summarization of stops information  
-----------------------------------------------------------------------  
  
CREATE TABLE dbo.#OverallStops   
 (   
 [Overall Totals]         VARCHAR(50),  
 [Master Unit]          VARCHAR(50),  
 [Team]            VARCHAR(10),  
 [Total Stops]          INTEGER,  
 [Unscheduled Stops]        INTEGER,  
 [Unscheduled Stops/Day]       INTEGER,  --FLD 01-NOV-2007 Rev11.53  
 [Minor Stops]          INTEGER,  
 [Equipment Failures]        INTEGER,  
 [Process Failures]        INTEGER,  
 [Split Downtime]         FLOAT,  
 [Unscheduled Split DT]       FLOAT,  
 [Raw Uptime]          VARCHAR(8),  
 [Split Uptime]          VARCHAR(8),  
 [Planned Availability]       VARCHAR(8),  
 [Stops with Uptime <2 Min]      INTEGER,   
 [R(2)]            VARCHAR(8),  
 [Unplanned MTBF]         VARCHAR(8),  
 [Unplanned MTTR]         VARCHAR(8),  
 [ELP Stops]           INTEGER,  
 [ELP Losses (Mins)]        FLOAT,  
 [ELP %]            FLOAT,   
 [Rate Loss Events]        INTEGER,   
 [Rate Loss Effective Downtime]    FLOAT,   
 [Rate Loss %]          FLOAT,   
   [Paper Runtime]                         FLOAT,   
   [Production Time]                       FLOAT,  
 [PR/Poly Change Events]       VARCHAR(8), -- Rev11.29  
 [PR/Poly Change Downtime]      VARCHAR(8), -- Rev11.29  
 [Avg PR/Poly Change Time]      VARCHAR(8) -- Rev11.29  
 )    
  
  
--------------------------------------------------------------------------  
-- This table will summarize production data by Line, Team, and Product.  
--------------------------------------------------------------------------  
  
CREATE TABLE dbo.#ProdProduction   
 (   
 [Production Line]         VARCHAR(50),  
 [Team]            VARCHAR(10),  
 [Product]           VARCHAR(25),  
 [Production Time]         FLOAT,  
 [Avg Stat CLD]          FLOAT,  
 [CVPR %]            FLOAT,  
 [Operations Efficiency %]      FLOAT,  
 [Total Units]          INTEGER,  
 [Good Units]          INTEGER,  
 [Reject Units]          INTEGER,  
 [Unit Broke %]          FLOAT,  
 [Actual Stat Cases]        INTEGER,  
 [Reliability Target Stat Cases]    INTEGER,  
 [Operations Target Stat Cases]    INTEGER,  
 [Ideal Stat Cases]        INTEGER,  
 [Line Speed Avg]         FLOAT,   
 [Target Line Speed]         FLOAT,    
 [Ideal Line Speed]        FLOAT,   
 [CVTI %]            FLOAT   
 )  
  
  
------------------------------------------------------------------------  
-- this table will summarize production data by Line  
------------------------------------------------------------------------  
  
CREATE TABLE dbo.#LineProduction   
 (   
 [Production Line]         VARCHAR(50) primary key,  
 [Team]            VARCHAR(10),  
 [Product]           VARCHAR(25),  
 [Production Time]         FLOAT,  
 [Avg Stat CLD]          FLOAT,  
 [CVPR %]            FLOAT,  
 [Operations Efficiency %]      FLOAT,  
 [Total Units]          INTEGER,  
 [Good Units]          INTEGER,  
 [Reject Units]          INTEGER,  
 [Unit Broke %]          FLOAT,  
 [Actual Stat Cases]        INTEGER,  
 [Reliability Target Stat Cases]    INTEGER,  
 [Operations Target Stat Cases]    INTEGER,  
 [Ideal Stat Cases]        INTEGER,  
 [Line Speed Avg]         FLOAT,    
 [Target Line Speed]         FLOAT,    
 [Ideal Line Speed]        FLOAT,    
 [CVTI %]            FLOAT  
 )   
  
  
------------------------------------------------------------------------  
-- this table will give an overall summary of production data  
-----------------------------------------------------------------------  
  
CREATE TABLE dbo.#OverallProduction   
 (   
 [Overall Totals]         VARCHAR(50),  
 [Team]            VARCHAR(10),  
 [Product]           VARCHAR(25),  
 [Production Time]         FLOAT,  
 [Avg Stat CLD]          FLOAT,  
 [CVPR %]            FLOAT,  
 [Operations Efficiency %]      FLOAT,  
 [Total Units]          INTEGER,  
 [Good Units]          INTEGER,  
 [Reject Units]          INTEGER,  
 [Unit Broke %]          FLOAT,  
 [Actual Stat Cases]        INTEGER,  
 [Reliability Target Stat Cases]    INTEGER,  
 [Operations Target Stat Cases]    INTEGER,  
 [Ideal Stat Cases]        INTEGER,  
 [Line Speed Avg]         FLOAT,    
 [Target Line Speed]         FLOAT,    
 [Ideal Line Speed]        FLOAT,    
 [CVTI %]            FLOAT  
 )    
  
  
-----------------------------------------------------------------  
-- this table will summarize production data for Pack lines  
-----------------------------------------------------------------  
  
CREATE TABLE dbo.#PackProduction   
 (    
 [Production Line]         VARCHAR(50),  
 [Master Unit]          VARCHAR(50),  
 [Team]            VARCHAR(10),  
 [Product]           VARCHAR(25),  
 [UOM]             VARCHAR(25),  
 [Good Units]          INTEGER   
 )  
  
  
--------------------------------------------------------------------  
-- this table will summarize stops information by master unit  
-------------------------------------------------------------------  
  
CREATE TABLE dbo.#UnitStops2   
 (   
 -- OrderIndex has to be the first column in this result set  
 [OrderIndex]          int,  
 [Production Line]         VARCHAR(50),  
 [Master Unit]          VARCHAR(50), -- Rev11.50  
 [Total Stops]          INTEGER,  
 [Unscheduled Stops]        INTEGER,  
 [Unscheduled Stops/Day]       INTEGER,  --FLD 01-NOV-2007 Rev11.53  
 [Minor Stops]          INTEGER,  
 [Equipment Failures]        INTEGER,  
 [Process Failures]        INTEGER,  
 [Split Downtime]         FLOAT,  
 [Unscheduled Split DT]       FLOAT,  
 [Raw Uptime]          FLOAT,  
 [Split Uptime]          FLOAT,  
 [Planned Availability]       FLOAT,  
 [Stops with Uptime <2 Min]      INTEGER,  
 [R(2)]            FLOAT,  
 [Unplanned MTBF]         FLOAT,  
 [Unplanned MTTR]         FLOAT,  
 [ELP Stops]           INTEGER,  
 [ELP Losses (Mins)]        FLOAT,  
 [ELP %]            FLOAT,  
 [Rate Loss Events]        INTEGER,  
 [Rate Loss Effective Downtime]    FLOAT,  
 [Rate Loss %]          FLOAT,  
   [Paper Runtime]                       FLOAT,   
   [Production Time]                     FLOAT,  
 [PR/Poly Change Events]       int,  --Rev11.29  
 [PR/Poly Change Downtime]      float, --Rev11.29  
 [Avg PR/Poly Change Time]      float  --Rev11.29  
 primary key ([Production Line], [Master Unit])  -- Rev11.50  
 )    
  
  
-----------------------------------------------------------------------  
-- this table will summarize stops information by Line  
----------------------------------------------------------------------  
  
CREATE TABLE dbo.#LineStops2   
 (   
 [Production Line]         VARCHAR(50),  
 [Master Unit]          VARCHAR(50),  
 [Total Stops]          INTEGER,  
 [Unscheduled Stops]        INTEGER,  
 [Unscheduled Stops/Day]       INTEGER,  --FLD 01-NOV-2007 Rev11.53  
 [Minor Stops]          INTEGER,  
 [Equipment Failures]        INTEGER,  
 [Process Failures]        INTEGER,  
 [Split Downtime]         FLOAT,  
 [Unscheduled Split DT]       FLOAT,  
 [Raw Uptime]          FLOAT,  
 [Split Uptime]          FLOAT,  
 [Planned Availability]       VARCHAR(8),  
 [Stops with Uptime <2 Min]         INTEGER,  
 [R(2)]            VARCHAR(8),  
 [Unplanned MTBF]         FLOAT,  
 [Unplanned MTTR]         FLOAT,  
 [ELP Stops]           INTEGER,  
 [ELP Losses (Mins)]        FLOAT,    
 [ELP %]            FLOAT,    
 [Rate Loss Events]        INTEGER,   
 [Rate Loss Effective Downtime]    FLOAT,   
 [Rate Loss %]          FLOAT,   
   [Paper Runtime]                        FLOAT,   
   [Production Time]                      FLOAT,  
 [PR/Poly Change Events]       VARCHAR(8), -- Rev11.29  
 [PR/Poly Change Downtime]      VARCHAR(8), -- Rev11.29  
 [Avg PR/Poly Change Time]      VARCHAR(8) -- Rev11.29  
 )    
  
  
-------------------------------------------------------------------------------  
-- this table will summarize stops according to a group type of Line or Pack  
-------------------------------------------------------------------------------  
  
CREATE TABLE dbo.#LinePackStops2   
 (   
 [Group Type]          VARCHAR(50) primary key,  
 [Master Unit]          VARCHAR(50),  
 [Total Stops]          INTEGER,  
 [Unscheduled Stops]        INTEGER,  
 [Unscheduled Stops/Day]       INTEGER,  --FLD 01-NOV-2007 Rev11.53  
 [Minor Stops]          INTEGER,  
 [Equipment Failures]        INTEGER,  
 [Process Failures]        INTEGER,  
 [Split Downtime]         FLOAT,  
 [Unscheduled Split DT]       FLOAT,   
 [Raw Uptime]          FLOAT,  
 [Split Uptime]          FLOAT,  
 [Planned Availability]       VARCHAR(8),  
 [Stops with Uptime <2 Min]      INTEGER,  
 [R(2)]            VARCHAR(8),  
 [Unplanned MTBF]         FLOAT,  
 [Unplanned MTTR]         FLOAT,  
 [ELP Stops]           INTEGER,  
 [ELP Losses (Mins)]        FLOAT,   
 [ELP %]            FLOAT,   
 [Rate Loss Events]        INTEGER,   
 [Rate Loss Effective Downtime]    FLOAT,   
 [Rate Loss %]          FLOAT,   
   [Paper Runtime]                        FLOAT,   
   [Production Time]                      FLOAT,  
 [PR/Poly Change Events]       VARCHAR(8), -- Rev11.29  
 [PR/Poly Change Downtime]      VARCHAR(8), -- Rev11.29  
 [Avg PR/Poly Change Time]      VARCHAR(8) -- Rev11.29  
 )   
  
  
---------------------------------------------------------------------  
-- this table provides an overall summary of stops information  
---------------------------------------------------------------------  
  
CREATE TABLE dbo.#OverallStops2   
 (   
 [Overall Totals]         VARCHAR(50),  
 [Master Unit]          VARCHAR(50),  
 [Total Stops]          INTEGER,  
 [Unscheduled Stops]        INTEGER,  
 [Unscheduled Stops/Day]       INTEGER, --FLD 01-NOV-2007 Rev11.53  
 [Minor Stops]          INTEGER,  
 [Equipment Failures]        INTEGER,  
 [Process Failures]        INTEGER,  
 [Split Downtime]         FLOAT,  
 [Unscheduled Split DT]       FLOAT,  
 [Raw Uptime]          VARCHAR(8),  
 [Split Uptime]          VARCHAR(8),  
 [Planned Availability]       VARCHAR(8),  
 [Stops with Uptime <2 Min]      INTEGER,   
 [R(2)]            VARCHAR(8),  
 [Unplanned MTBF]         VARCHAR(8),  
 [Unplanned MTTR]         VARCHAR(8),  
 [ELP Stops]           INTEGER,  
 [ELP Losses (Mins)]        FLOAT,   
 [ELP %]            FLOAT,    
 [Rate Loss Events]        INTEGER,   
 [Rate Loss Effective Downtime]    FLOAT,   
 [Rate Loss %]          FLOAT,   
   [Paper Runtime]                         FLOAT,   
   [Production Time]                   FLOAT,  
 [PR/Poly Change Events]       VARCHAR(8), -- Rev11.29  
 [PR/Poly Change Downtime]      VARCHAR(8), -- Rev11.29  
 [Avg PR/Poly Change Time]      VARCHAR(8) -- Rev11.29  
 )    
  
  
-------------------------------------------------------------------------  
-- This table will summarize production information by Line and Product  
------------------------------------------------------------------------  
  
CREATE TABLE dbo.#ProdProduction2   
 (   
 [Production Line]         VARCHAR(50),  
 [Product]           VARCHAR(25),  
 [Production Time]         FLOAT,  
 [Avg Stat CLD]          FLOAT,  
 [CVPR %]            FLOAT,  
 [Operations Efficiency %]      FLOAT,  
 [Total Units]          INTEGER,  
 [Good Units]          INTEGER,  
 [Reject Units]          INTEGER,  
 [Unit Broke %]          FLOAT,  
 [Actual Stat Cases]        INTEGER,  
 [Reliability Target Stat Cases]    INTEGER,  
 [Operations Target Stat Cases]    INTEGER,  
 [Ideal Stat Cases]        INTEGER,  
 [Line Speed Avg]         FLOAT,    
 [Target Line Speed]         FLOAT,    
 [Ideal Line Speed]        FLOAT,   
 [CVTI %]            FLOAT   
 )  
  
  
-----------------------------------------------------------------  
-- This table will summarize production information by Line  
----------------------------------------------------------------  
  
CREATE TABLE dbo.#LineProduction2   
 (   
 [Production Line]         VARCHAR(50) primary key,  
 [Product]           VARCHAR(25),  
 [Production Time]         FLOAT,  
 [Avg Stat CLD]          FLOAT,  
 [CVPR %]            FLOAT,  
 [Operations Efficiency %]      FLOAT,  
 [Total Units]          INTEGER,  
 [Good Units]          INTEGER,  
 [Reject Units]          INTEGER,  
 [Unit Broke %]          FLOAT,  
 [Actual Stat Cases]        INTEGER,  
 [Reliability Target Stat Cases]    INTEGER,  
 [Operations Target Stat Cases]    INTEGER,  
 [Ideal Stat Cases]          INTEGER,  
 [Line Speed Avg]         FLOAT,    
 [Target Line Speed]         FLOAT,    
 [Ideal Line Speed]        FLOAT,   
 [CVTI %]            FLOAT   
 )  
  
  
------------------------------------------------------------------  
-- This table will give an overall summary of the production data.  
------------------------------------------------------------------  
  
CREATE TABLE dbo.#OverallProduction2   
 (   
 [Overall Totals]         VARCHAR(50),  
 [Product]           VARCHAR(25),  
 [Production Time]         FLOAT,  
 [Avg Stat CLD]          FLOAT,  
 [CVPR %]            FLOAT,  
 [Operations Efficiency %]      FLOAT,  
 [Total Units]          INTEGER,  
 [Good Units]          INTEGER,  
 [Reject Units]          INTEGER,  
 [Unit Broke %]          FLOAT,  
 [Actual Stat Cases]        INTEGER,  
 [Reliability Target Stat Cases]    INTEGER,  
 [Operations Target Stat Cases]    INTEGER,  
 [Ideal Stat Cases]        INTEGER,  
 [Line Speed Avg]         FLOAT,    
 [Target Line Speed]         FLOAT,    
 [Ideal Line Speed]        FLOAT,   
 [CVTI %]            FLOAT   
 )  
  
  
-----------------------------------------------------------------------  
-- this table will summarize the production data for Pack lines.  
-----------------------------------------------------------------------  
  
CREATE TABLE dbo.#PackProduction2   
 (    
 [Production Line]         VARCHAR(50),  
 [Master Unit]          VARCHAR(50),  
 [Product]           VARCHAR(25),  
 [UOM]             VARCHAR(25),  
 [Good Units]          INTEGER   
 )  
  
  
----------------------------------------------------------------------------  
-- this table is used to pass out raw stops information to the result sets.  
----------------------------------------------------------------------------  
  
CREATE TABLE dbo.#Stops   
 (   
-- [OrderIndex]          int,  
 [Production Line]         VARCHAR(50),  
 [Master Unit]          VARCHAR(50),  
 [Start Date]          VARCHAR(25),  
 [Start Time]          VARCHAR(25),  
 [End Date]           VARCHAR(25),  
 [End Time]           VARCHAR(25),  
 [Event Downtime]         FLOAT,  
 [Split Downtime]         FLOAT,  
 [Product]           VARCHAR(25),  
 [Product Desc]          VARCHAR(50),  
 [Event Location Type]       VARCHAR(50),  
 [Team]            VARCHAR(10),  
 [Shift]            VARCHAR(10),  
 [Location]           VARCHAR(50),  
 [Fault Desc]          VARCHAR(100),  
 [RL1Title]           VARCHAR(100),  
 [RL2Title]           VARCHAR(100),  
 [Schedule]           VARCHAR(50),  
 [Category]           VARCHAR(50),  
 [SubSystem]           VARCHAR(50),  
 [GroupCause]          VARCHAR(50),  
 [Equipment Group]         VARCHAR(50),  
 [Comment]           VARCHAR(5000),  
 [Line Status]          VARCHAR(25),  
 [Event Type]          VARCHAR(10),  
 [Total Stops]          INTEGER,  
 [Minor Stops]          INTEGER,  
 [Equipment Failures]        INTEGER,   
 [Process Failures]        INTEGER,  
 [Total Causes]          INTEGER,  
 [UWS1GrandParent]         VARCHAR(50),   
 [UWS1GrandParent PM]        VARCHAR(50),  
 [UWS1Parent]          VARCHAR(50),   
 [UWS1Parent PM]         VARCHAR(50),  
 [UWS2GrandParent]         VARCHAR(50),   
 [UWS2GrandParent PM]        VARCHAR(50),  
 [UWS2Parent]          VARCHAR(50),   
 [UWS2Parent PM]         VARCHAR(50),  
 [Unscheduled Split DT]       FLOAT,  
 [Raw Uptime]          FLOAT,  
 [Split Uptime]          FLOAT,  
 [Stops with Uptime <2 Min]      FLOAT,   
 [Rate Loss Events]        INTEGER,        
 [Rate Loss Effective Downtime]    FLOAT,  
 [Target Line Speed]        FLOAT,  
 [Actual Line Speed]        FLOAT,  
 [Ideal Line Speed]        FLOAT,  
 [Total Blocked Starved]       INTEGER,  
 [Minor Equipment Failures]      INTEGER,   
 [Moderate Equipment Failures]     INTEGER,  
 [Major Equipment Failures]      INTEGER,  
 [Minor Process Failures]      INTEGER,  
 [Moderate Process Failures]     INTEGER,  
 [Major Process Failures]      INTEGER,  
 [RL3Title]           VARCHAR(100),  
 [RL4Title]           VARCHAR(100)  
 primary key ([Production Line], [Master Unit], [Start Date], [Start Time])  -- Rev11.50  
 )  
  
  
-------------------------------------------------------------------  
-- This table summaries stops data by Line, Master Unit, and team  
-------------------------------------------------------------------  
   
CREATE TABLE dbo.#LineSummary   
 (   
 -- OrderIndex has to be the first column in this result set  
 [OrderIndex]          int,  
 [Production Line]         VARCHAR(50),  
 [Master Unit]          VARCHAR(50),  
 [Team]            VARCHAR(10),  
 [Total Stops]          INTEGER,  
 [Minor Stops]          INTEGER,  
 [Equipment Failures]        INTEGER,  
 [Process Failures]        INTEGER,  
 [Total Causes]          INTEGER,  
 [Event Downtime]         FLOAT,  
 [Split Downtime]         FLOAT,  
 [Unscheduled Split DT]       FLOAT,  
 [Raw Uptime]          FLOAT,  
 [Split Uptime]          FLOAT,  
 [Stops with Uptime <2 Min]      INTEGER,  
 [Rate Loss Events]        INTEGER,  
 [Rate Loss Effective Downtime]    FLOAT,  
 [Total Blocked Starved]       INTEGER,  
 [Minor Equipment Failures]      INTEGER,   
 [Moderate Equipment Failures]     INTEGER,   
 [Major Equipment Failures]      INTEGER,   
 [Minor Process Failures]      INTEGER,   
 [Moderate Process Failures]     INTEGER,  
 [Major Process Failures]      INTEGER  
 primary key ([Master Unit], [Team])  
 )  
  
   
----------------------------------------------------------------  
-- This table summaries stops data by Line, Master Unit, Shift  
----------------------------------------------------------------  
   
CREATE TABLE dbo.#ShiftSummary   
 (   
 -- OrderIndex has to be the first column in this result set  
 [OrderIndex]          int,  
 [Production Line]         VARCHAR(50),  
 [Master Unit]          VARCHAR(50),  
 [Shift]            VARCHAR(10),  
 [Total Stops]          INTEGER,  
 [Minor Stops]          INTEGER,  
 [Equipment Failures]        INTEGER,  
 [Process Failures]        INTEGER,  
 [Total Causes]          INTEGER,  
 [Event Downtime]         FLOAT,  
 [Split Downtime]         FLOAT,  
 [Unscheduled Split DT]       FLOAT,  
 [Raw Uptime]          FLOAT,  
 [Split Uptime]          FLOAT,  
 [Stops with Uptime <2 Min]      INTEGER,  
 [Rate Loss Events]        INTEGER,  
 [Rate Loss Effective Downtime]    FLOAT,  
 [Total Blocked Starved]       INTEGER,  
 [Minor Equipment Failures]      INTEGER,  
 [Moderate Equipment Failures]     INTEGER,  
 [Major Equipment Failures]      INTEGER,  
 [Minor Process Failures]      INTEGER,  
 [Moderate Process Failures]     INTEGER,  
 [Major Process Failures]      INTEGER   
 primary key ([Master Unit], [Shift])  
 )  
  
   
-----------------------------------------------------------------  
-- This table summaries stops data by Line, Master Unit, Product  
-----------------------------------------------------------------  
   
CREATE TABLE dbo.#ProductSummary   
 (   
 -- OrderIndex has to be the first column in this result set  
 [OrderIndex]          int,  
 [Production Line]         VARCHAR(50),  
 [Master Unit]          VARCHAR(50),  
 [Product]           VARCHAR(50),  
 [Total Stops]          INTEGER,  
 [Minor Stops]          INTEGER,  
 [Equipment Failures]        INTEGER,  
 [Process Failures]        INTEGER,  
 [Total Causes]          INTEGER,  
 [Event Downtime]         FLOAT,  
 [Split Downtime]         FLOAT,  
 [Unscheduled Split DT]       FLOAT,  
 [Raw Uptime]          FLOAT,  
 [Split Uptime]          FLOAT,  
 [Stops with Uptime <2 Min]      INTEGER,  
 [Rate Loss Events]        INTEGER,  
 [Rate Loss Effective Downtime]    FLOAT,  
 [Total Blocked Starved]       INTEGER,  
 [Minor Equipment Failures]      INTEGER,  
 [Moderate Equipment Failures]     INTEGER,  
 [Major Equipment Failures]      INTEGER,  
 [Minor Process Failures]      INTEGER,  
 [Moderate Process Failures]     INTEGER,  
 [Major Process Failures]      INTEGER  
 primary key ([Master Unit], [Product])  
 )  
   
  
------------------------------------------------------------------  
-- This table summaries stops data by Line, Master Unit, Location  
------------------------------------------------------------------  
   
CREATE TABLE dbo.#LocationSummary   
 (   
 -- OrderIndex has to be the first column in this result set  
 [OrderIndex]          int,  
 [Production Line]         VARCHAR(50),  
 [Master Unit]          VARCHAR(50),  
 [Event Location Type]       VARCHAR(25),  
 [Total Stops]          INTEGER,  
 [Minor Stops]          INTEGER,  
 [Equipment Failures]        INTEGER,  
 [Process Failures]        INTEGER,  
 [Total Causes]          INTEGER,  
 [Event Downtime]         FLOAT,  
 [Split Downtime]         FLOAT,  
 [Unscheduled Split DT]       FLOAT,  
 [Raw Uptime]          FLOAT,  
 [Split Uptime]          FLOAT,  
 [Stops with Uptime <2 Min]      INTEGER,  
 [Rate Loss Events]        INTEGER,  
 [Rate Loss Effective Downtime]    FLOAT,  
 [Total Blocked Starved]       INTEGER,  
 [Minor Equipment Failures]      INTEGER,  
 [Moderate Equipment Failures]     INTEGER,  
 [Major Equipment Failures]      INTEGER,  
 [Minor Process Failures]      INTEGER,  
 [Moderate Process Failures]     INTEGER,  
 [Major Process Failures]      INTEGER   
 primary key ([Master Unit], [Event Location Type])  
 )  
  
   
------------------------------------------------------------------  
-- This table summaries stops data by Line, Master Unit, Category  
------------------------------------------------------------------  
   
CREATE TABLE dbo.#CategorySummary   
 (   
 -- OrderIndex has to be the first column in this result set  
 [OrderIndex]          int,  
 [Production Line]         VARCHAR(50),  
 [Master Unit]          VARCHAR(50),  
 [Category]           VARCHAR(25),  
 [Total Stops]          INTEGER,  
 [Minor Stops]          INTEGER,  
 [Equipment Failures]        INTEGER,  
 [Process Failures]        INTEGER,  
 [Total Causes]          INTEGER,  
 [Event Downtime]         FLOAT,  
 [Split Downtime]         FLOAT,  
 [Unscheduled Split DT]       FLOAT,  
 [Raw Uptime]          FLOAT,  
 [Split Uptime]          FLOAT,  
 [Stops with Uptime <2 Min]      INTEGER,  
 [Rate Loss Events]        INTEGER,  
 [Rate Loss Effective Downtime]    FLOAT,  
 [Total Blocked Starved]       INTEGER,  
 [Minor Equipment Failures]      INTEGER,  
 [Moderate Equipment Failures]     INTEGER,  
 [Major Equipment Failures]      INTEGER,  
 [Minor Process Failures]      INTEGER,  
 [Moderate Process Failures]     INTEGER,  
 [Major Process Failures]      INTEGER  
 primary key ([Master Unit], [Category])  
 )  
   
  
------------------------------------------------------------------  
-- This table summaries stops data by Line, Master Unit, Schedule  
------------------------------------------------------------------  
   
CREATE TABLE dbo.#ScheduleSummary   
 (   
 -- OrderIndex has to be the first column in this result set  
 [OrderIndex]          int,  
 [Production Line]         VARCHAR(50),  
 [Master Unit]          VARCHAR(50),  
 [Schedule]           VARCHAR(25),  
 [Total Stops]          INTEGER,  
 [Minor Stops]          INTEGER,  
 [Equipment Failures]        INTEGER,  
 [Process Failures]        INTEGER,  
 [Total Causes]          INTEGER,  
 [Event Downtime]         FLOAT,  
 [Split Downtime]         FLOAT,  
 [Unscheduled Split DT]       FLOAT,  
 [Raw Uptime]          FLOAT,  
 [Split Uptime]          FLOAT,  
 [Stops with Uptime <2 Min]      INTEGER,  
 [Rate Loss Events]        INTEGER,  
 [Rate Loss Effective Downtime]    FLOAT,  
 [Total Blocked Starved]       INTEGER,  
 [Minor Equipment Failures]      INTEGER,  
 [Moderate Equipment Failures]     INTEGER,  
 [Major Equipment Failures]      INTEGER,  
 [Minor Process Failures]      INTEGER,  
 [Moderate Process Failures]     INTEGER,  
 [Major Process Failures]      INTEGER  
 primary key ([Master Unit], [Schedule])  
 )  
  
---------------------------------------------------------------------------------  
-- 2007-Jan-11 VMK Rev11.30, added table #Events  
--Rev11.55  
CREATE TABLE dbo.#Events   
 (  
 event_id            INTEGER, -- PRIMARY KEY,  
 source_event          INTEGER,  
 pu_id             INTEGER,  
 start_time           datetime,  
 end_time            datetime,  
 timestamp           DATETIME,  
 entry_on            DATETIME,  
-- event_status          INTEGER,  
-- status_desc           varchar(50), -- Rev11.33  
 event_num           VARCHAR(50),  
 DevComment           varchar(300) -- Rev11.33  
-- primary key (Event_id, start_time)  
 )  
  
CREATE CLUSTERED INDEX events_eventid_StartTime  
ON dbo.#events (event_id, start_time)   
  
  
---------------------------------------------------------------------------------  
  
--Rev11.55  
create table dbo.#SplitPRsRun  
 (   
 --Rev11.63  
 [sprs_id]     int primary key identity,  
 [ID_num]                int, --primary key identity ,  
-- CalDay      varchar(10),  
 ShiftStart     datetime,  
 [PLID]      int,  
 [PUID]      int,      
 [Team]      varchar(5),  
 [ProdID]      int,  
   [PRPLID]      int,  
   [PRPUID]      int,  
 LineStatus     varchar(50),  
   [StartTime]     datetime,  
   [EndTime]     datetime,  
 StartTime_UnitTeam  datetime,  
 EndTime_UnitTeam   datetime,  
 StartTime_Unit    datetime,  
 EndTime_Unit    datetime,  
 StartTime_Line    datetime,  
 EndTime_Line    datetime,  
 DevComment     varchar(100)  
 )  
  
--Rev11.63  
CREATE nonCLUSTERED INDEX sprs_PUId_StartTime_endtime  
ON dbo.#SplitPRsRun (puid, starttime, endtime)  
  
--Rev11.63  
CREATE nonCLUSTERED INDEX sprs_PlId_StartTime_endtime  
ON dbo.#SplitPRsRun (plid, starttime, endtime)  
  
  
--Rev11.55  
create table dbo.#Dimensions   
 (  
 DimensionId     INTEGER,       -- 2009-08-31 VMK Rev11.77, Added.  
 Dimension     varchar(50),  
 Value       varchar(50),  
 StartTime     datetime,  
 EndTime      datetime,  
 PLID       int,  
 PUID       int  
 )  
  
CREATE CLUSTERED INDEX dim_PUId_EndTime  
ON dbo.#dimensions (puid, starttime)  
  
  
--Rev11.55  
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
-- Section 7: Check Input Parameters to make sure they are valid.  
-------------------------------------------------------------------------------  
IF @StartTime = @EndTime  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('The date range selected for this report has the same start and end date: ' + convert(varchar(25),@StartTime,107) +  
      ' through ' + convert(varchar(25),@EndTime,107))  
 GOTO ReturnResultSets  
 END  
IF IsDate(@StartTime) <> 1  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@StartTime is not a Date.')  
 GOTO ReturnResultSets  
 END  
IF IsDate(@EndTime) <> 1  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('@EndTime is not a Date.')  
 GOTO ReturnResultSets  
 END  
  
-- If the endtime is in the future, set it to current day.  This prevent zero records FROM being --printed on report.  
IF @EndTime > GetDate()  
 BEGIN  
 SELECT @EndTime = CONVERT(VARCHAR(4),YEAR(GetDate())) + '-' + CONVERT(VARCHAR(2),MONTH(GetDate())) + '-' +   
     CONVERT(VARCHAR(2),DAY(GetDate())) + ' ' + CONVERT(VARCHAR(2),DATEPART(hh,GetDate())) + ':' +   
     CONVERT(VARCHAR(2),DATEPART(mi,GetDate()))+ ':' + CONVERT(VARCHAR(2),DATEPART(ss,GetDate()))  
 END  
  
IF coalesce(@RptWindowMaxDays,0) = 0  
 BEGIN  
 SELECT @RptWindowMaxDays = 32  
 END  
  
-- IF DATEDIFF(d, @StartTime,@EndTime) > @RptWindowMaxDays  
--  BEGIN  
--  INSERT @ErrorMessages (ErrMsg)  
--   VALUES ('The date range selected exceeds the maximum allowed for this report: ' + CONVERT(VARCHAR(50),@RptWindowMaxDays) +  
--       '.  Decrease the date range or see your Proficy SSO for help.')  
--  GOTO ReturnResultSets  
--  END  
  
--print 'Get local language ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-------------------------------------------------------------------------------  
-- Section 8: Get local language ID  
-------------------------------------------------------------------------------  
  
SELECT   
@LanguageParmId  = 8,  
@LanguageId   = NULL  
  
SELECT @UserId = User_Id  
FROM dbo.Users with (nolock)  
WHERE UserName = @UserName  
  
SELECT @LanguageId =   
  CASE WHEN isnumeric(LTRIM(RTRIM(Value))) = 1   
    THEN CONVERT(FLOAT, LTRIM(RTRIM(Value)))  
    ELSE NULL  
    END  
FROM dbo.User_Parameters with (nolock)  
WHERE User_Id = @UserId  
AND Parm_Id = @LanguageParmId  
  
IF coalesce(@LanguageId,-1) = -1  
 BEGIN  
 SELECT @LanguageId =   
    CASE WHEN isnumeric(LTRIM(RTRIM(Value))) = 1   
      THEN CONVERT(FLOAT, LTRIM(RTRIM(Value)))  
      ELSE NULL  
      END  
 FROM dbo.Site_Parameters with (nolock)  
 WHERE Parm_Id = @LanguageParmId  
  
 IF coalesce(@LanguageId,-1) = -1  
  BEGIN  
  SELECT @LanguageId = 0  
  END  
 END  
  
-- 2004-12-20 JSJ assigned values used for > 65000 checks  
SELECT @NoDataMsg = GBDB.dbo.fnLocal_GlblTranslation('NO DATA meets the given criteria', @LanguageId)  
SELECT @TooMuchDataMsg = GBDB.dbo.fnLocal_GlblTranslation('There are more results than can be displayed', @LanguageId)  
  
  
--print 'Section 10 Get info about Prod Lines: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
------------------------------------------------------------  
-- Section 10: Get information about the production lines  
------------------------------------------------------------  
  
-- pull in prod lines that have an ID in the list  
insert @ProdLines -- Rev11.33   
 (  
 PLID,   
 PLDesc,  
 Extended_Info)  
select   
 PL_ID,   
 PL_Desc,  
 Extended_Info  
from dbo.prod_lines with (nolock)  
where charindex('|' + convert(varchar,pl_id) + '|','|' + @ProdLineList + '|') > 0  
option (keep plan)  
  
  
-- if the list is empty, then get all prod lines  
IF (SELECT count(PLId) FROM @ProdLines) = 0  -- Rev11.33  
 BEGIN  
  INSERT @ProdLines (PLId,PLDesc, Extended_Info) -- Rev11.33  
  SELECT PL_Id, PL_Desc, Extended_Info  
  FROM  dbo.Prod_Lines with (nolock)  
  option (keep plan)  
 END  
  
-- get the ID of the Converter Production unit associated with each line.  
update pl set  
 ProdPUID = pu_id  
from @ProdLines pl --with (nolock)-- Rev11.33  
join dbo.Prod_Units pu with (nolock)  
on pl.plid = pu.pl_id  
where pu_desc like '%Converter Production%'  
  
-- PackOrLine is used for grouping in the result sets and to restrict data in some where clauses  
update pl set  
 PackOrLine = GBDB.dbo.fnLocal_GlblParseInfo(pl.Extended_Info, @PackOrLineStr)  
from @ProdLines pl --with (nolock)-- Rev11.33  
  
  
-- get the ID of the Converter Reliability unit associated with each line.  
update pl set  
 ReliabilityPUID = pu_id  
from @ProdLines pl --with (nolock)-- Rev11.33  
join dbo.Prod_Units pu with (nolock)  
on pl.plid = pu.pl_id  
where pu_desc like '%Converter Reliability%'  
  
  
-- get the ID of the Rate Loss unit associated with each line.  
update pl set  
 RatelossPUID = pu_id  
from @ProdLines pl --with (nolock)-- Rev11.33  
join dbo.Prod_Units pu with (nolock)  
on pl.plid = pu.pl_id  
where pu_desc like '%Rate Loss%'  
  
  
update pl set  
 CvtrBlockedStarvedPUId = pu.PU_Id  
from @ProdLines pl  
join dbo.Prod_Units pu with (nolock)  
on pl.plid = pu.pl_id  
AND pu.PU_Desc LIKE '% Converter Blocked/Starved%'  
  
  
-- get the following variable IDs associated with the line  
update pl set  
 VarGoodUnitsId    = GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,   @VarGoodUnitsVN),  
 VarTotalUnitsId    = GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,   @VarTotalUnitsVN),  
 VarPMRollWidthId    = GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,   @VarPMRollWidthVN),  
 VarParentRollWidthId  = GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,   @VarParentRollWidthVN),  
 VarEffDowntimeId    = GBDB.dbo.fnLocal_GlblGetVarId(RateLossPUId,  @VarEffDowntimeVN),  
 VarActualLineSpeedId  = GBDB.dbo.fnLocal_GlblGetVarId(RateLossPUId,  @VarActualLineSpeedVN),  
-- VarStartTimeId    = GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,   @VarStartTimeVN),  
-- VarEndTimeId     = GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,   @VarEndTimeVN),  
 VarPRIDId      = GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,   @VarPRIDVN),  
 VarParentPRIDId    = GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,   @VarParentPRIDVN),  
-- VarGrandParentPRIDId  = GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,   @VarGrandParentPRIDVN),  
 VarUnwindStandId    = GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,   @VarUnwindStandVN),  
-- VarInputRollID    = GBDB.dbo.fnLocal_GlblGetVarId(RollsPUID,   @VarInputRollVN),  
-- VarInputPRIDID    = GBDB.dbo.fnLocal_GlblGetVarId(RollsPUID,   @VarInputPRIDVN),  
 -- Rev11.45  
 VarLineSpeedId    =   
         coalesce(  
            GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,@VarLinespeedMMinVN),  
            GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,@VarLinespeedVN)  
            )  
from @ProdLines pl --with (nolock)-- Rev11.33  
where PackOrLine = 'Line'  
  
  
-- get the Line Prod Factor  
update @ProdLines set -- Rev11.33   
 PropLineProdFactorId = Prop_Id  
FROM dbo.Product_Properties with (nolock)  
WHERE Prop_Desc = ltrim(rtrim(replace(PLDesc,@PPTT,''))) + ' ' + @LineProdFactorDesc  
   
  
--print 'Section 11 @DelayTypeList: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-------------------------------------------------------------------------------  
-- Section 11: Parse the DelayTypeList  
-------------------------------------------------------------------------------  
  
-- this parsing procedure extracts individual delay type values out of @DelayTypeList  
-- and inserts them into @DelayTypes  
-- ideally, we would do this without a while loop, but because this list will be short, this   
-- may be the most efficient way to do it.  
  
SELECT @SearchString = LTRIM(RTRIM(@DelayTypeList))  
WHILE len(@SearchString) > 0  
 BEGIN  
  SELECT @Position = CharIndex('|', @SearchString)  
  IF @Position = 0  
  BEGIN  
   SELECT   
   @PartialString = RTRIM(@SearchString),  
   @SearchString = ''  
  END  
 ELSE  
  BEGIN  
   SELECT   
   @PartialString = RTRIM(substring(@SearchString, 1, @Position - 1)),  
   @SearchString = LTRIM(RTRIM(substring(@SearchString, (@Position + 1), len(@SearchString))))  
  END  
 IF len(@PartialString) > 0  
  AND (  
    SELECT count(DelayTypeDesc)   
    FROM @DelayTypes   
    WHERE DelayTypeDesc = @PartialString  
    ) = 0  
  BEGIN  
   INSERT @DelayTypes (DelayTypeDesc)   
   VALUES (@PartialString)  
  END  
 END  
  
  
--print 'Section 12 @ProdUnits: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-------------------------------------------------------------------------------  
-- Section 12: Get information for ProdUnitList  
-------------------------------------------------------------------------------  
  
-- note that some values are parsed from the extended_info field  
INSERT @ProdUnits   
 (   
 PUId,  
 OrderIndex,  
 PUDesc,  
 PLId,  
 ExtendedInfo,  
 DelayType,  
 ScheduleUnit,  
 LineStatusUnit,  
 UWSVarId,   
 PRIDRLVarId)  
SELECT   
 pu.PU_Id,  
 1,  
 pu.PU_Desc,  
 pu.PL_Id,  
 pu.Extended_Info,  
 GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, @PUDelayTypeStr),  
 GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, @PUScheduleUnitStr),  
 GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, @PULineStatusUnitStr),  
 tpl.VarUnwindStandId,  
 rlv.Var_Id  
FROM dbo.Prod_Units pu with (nolock)  
JOIN @ProdLines tpl --with (nolock)-- Rev11.33    
ON pu.PL_Id = tpl.PLId  
and pu.Master_Unit is null  
JOIN dbo.Event_Configuration ec with (nolock)  
ON pu.PU_Id = ec.PU_Id  
AND ec.ET_Id = 2  
JOIN @DelayTypes dt   
ON dt.DelayTypeDesc = GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, @PUDelayTypeStr)   
LEFT JOIN dbo.Variables rlv with (nolock)  
ON rlv.PU_Id = pu.PU_Id   
--AND rlv.Var_Desc = @PRIDRLVarStr  
and rlv.var_id = dbo.fnLocal_GlblGetVarId(rlv.PU_ID, @PRIDRLVarStr)  
where pu_desc not like '%z_obs%'  
option (keep plan)  
  
  
--print 'Section 13 @UWS: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-------------------------------------------------------------------------------  
-- Section 13: Populate the @UWS table.  
-------------------------------------------------------------------------------  
  
INSERT INTO @UWS   
 (   
 InputName,  
 InputOrder,  
 PLId,  
 PEIId,         -- 2007-01-11 VMK Rev11.30, added  
 UWSPUId   
 )  
SELECT pei.Input_Name,  
 pei.Input_Order,  
 pl.PLId,  
 pei.PEI_Id,        -- 2007-01-11 VMK Rev11.29, added  
 COALESCE(pu.PU_Id,0-pei.PEI_Id)  
FROM dbo.PrdExec_Inputs pei with (nolock)  
JOIN @ProdLines pl --with (nolock)  
ON pl.ProdPUId = pei.PU_Id -- Rev11.33  
AND PackOrLine = 'LINE'  
LEFT JOIN dbo.Prod_Units pu with (nolock)  
ON pu.PL_Id = pl.PLId  
AND charindex('UWSORDER='+CONVERT(VARCHAR(5), pei.Input_Order) + ';', upper(REPLACE(pu.Extended_Info, ' ', '') + ';')) > 0  
option (keep plan)  
  
  
--print 'Section 14 @ProdUnits UWS Columns: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
--------------------------------------------------------------------------------------------  
--- Section 14: Update @ProdUnits UWS columns with the appropriate prod Unit desc.  
--------------------------------------------------------------------------------------------  
IF @IncludeStops = 1  
  
 UPDATE pu SET   
  UWS1 = upu1.PU_Desc,  
  UWS2 = upu2.PU_Desc  
 FROM @ProdUnits pu  
 LEFT JOIN @UWS uws1   
 ON pu.PLId = uws1.PLId  
 AND uws1.InputOrder = 1  
 LEFT JOIN dbo.Prod_Units upu1 with (nolock)  
 ON uws1.UWSPUId = upu1.PU_Id   
 LEFT JOIN @UWS uws2   
 ON pu.PLId = uws2.PLId  
 AND uws2.InputOrder = 2  
 LEFT JOIN dbo.Prod_Units upu2 with (nolock)  
 ON uws2.UWSPUId = upu2.PU_Id  
  
  
--print 'Section 15 @ProdUnitsPack: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-------------------------------------------------------------------------------  
-- Section 15: Populate @ProdUnitsPack  
-------------------------------------------------------------------------------  
  
INSERT @ProdUnitsPack    
 (   
 PUId,  
 PUDesc,  
 PLId,  
 PLDesc,    
 GoodUnitsVarId,  
 ScheduleUnit,  
 UOM  
 )   
SELECT pu.PU_Id,  
 pu.pu_desc,  
 pu.PL_Id,  
 pl.PLDesc,    
 v.Var_Id,  
 GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, @PUScheduleUnitStr),  
 v.Eng_Units  
FROM dbo.Prod_Units pu with (nolock)  
JOIN @ProdLines pl --with (nolock)  
ON pu.PL_Id = pl.PLId -- Rev11.33  
LEFT JOIN dbo.Variables v with (nolock)  
ON pu.PU_Id = v.PU_Id  
AND   
 (  
 v.Var_Desc_Global = @VarGoodUnitsVN   
 OR dbo.fnLocal_GlblParseInfo(v.Extended_Info, 'GlblDesc=') LIKE '%' + REPLACE(@VarGoodUnitsVN,' ','')  
-- v.var_id = dbo.fnLocal_GlblGetVarId(pu.PU_ID, @VarGoodUnitsVN)  
 )  
where charindex('|' + convert(varchar,pu.pu_id) + '|','|' + @PackPUIdList + '|') > 0  
option (keep plan)  
  
  
--print 'Section 16 @ProdUnitsEG: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
------------------------------------------------------------------  
-- Section 16: Populate @ProdUnitsEG  
------------------------------------------------------------------  
  
-------------------------------------------------------------------------------  
-- Filter the Production Unit list to only include the passed Delay Type list   
-- for the @ProdUnits and #Runs tables.  
-------------------------------------------------------------------------------  
IF @IncludeStops = 1  
 BEGIN  
 -------------------------------------------------------------------------------  
 -- Create Temporary table to determine Equipment Groups.  
 -------------------------------------------------------------------------------  
 -- Insert Master Production Units INTO @ProdUnitsEG  
 INSERT INTO @ProdUnitsEG   
  (   
  PLId,  
  Source_PUId,  
  EquipGroup  
  )  
 SELECT ppu.PLId,  
  PU_Id,  
  GBDB.dbo.fnLocal_GlblParseInfo(Extended_Info, @PUEquipGroupStr)  
 FROM @ProdUnits ppu   
 JOIN dbo.Prod_Units pu with (nolock)  
 ON ppu.PUId = pu.PU_Id  
 option (keep plan)  
  
  
 -- Insert Slave Production Units into #ProdUnitsEG  
 INSERT INTO @ProdUnitsEG   
  (   
  PLId,  
  Source_PUId,  
  EquipGroup  
  )  
 SELECT ppu.PLId,  
  PU_Id,  
  GBDB.dbo.fnLocal_GlblParseInfo(Extended_Info, @PUEquipGroupStr)  
 FROM @ProdUnits ppu  
 JOIN dbo.Prod_Units pu with (nolock)  
 ON ppu.PUId = pu.Master_Unit  
 option (keep plan)  
  
 END --@IncludeStops  
  
  
--print 'Section 21 @LineProdVars: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-------------------------------------------------------------------------------  
-- Section 21: Get Line Production Variables     
-------------------------------------------------------------------------------  
  
--print '@BusinessType = ' + Convert(VarChar(5), @BusinessType)  
IF @BusinessType IN (3, 4) -- Facial/Hanky  
  
 -- Facial/Hanky bases its production off a dedicated pack line so we're going to find  
 -- the pack line associated with this production line and gather all the necessary info FROM it  
 -- We're also going to filter by the argument pack pu list for consistency  
 INSERT INTO @LineProdVars   
  (   
  PLId,  
  PUId,  
  VarId,  
  VarType  
  )  
 SELECT  pl.PLId,  
  pup.PUId,  
  v.Var_Id,  
  dbo.fnLocal_GlblParseInfo(v.Extended_Info, @VarTypeStr)  
 FROM dbo.Variables v with (nolock)  
 JOIN @ProdUnitsPack pup ON v.PU_Id = pup.PUId  
 JOIN @ProdLines pl --with (nolock)  
 ON pl.PackOrLine = 'Line' -- Rev11.33  
 AND LTRIM(RTRIM(REPLACE(pup.PLDesc, ' ', ''))) = LTRIM(RTRIM(REPLACE(pl.PLDesc, ' ', ''))) + 'PACK'  
 WHERE dbo.fnLocal_GlblParseInfo(v.Extended_Info, @VarTypeStr) IN (@ACPUnitsFlag, @HPUnitsFlag, @TPUnitsFlag)  
 option (keep plan)  
  
  
  
-- Rev11.31  
-------------------------------------------------------------------------------------  
-- Section 11: Populate @VariableList  
-------------------------------------------------------------------------------------  
--print 'variablelist' + ' ' + convert(varchar(25),current_timestamp,108)  
  
--Insert Into @variablelist (Var_Id, PL_ID)   
--Select distinct VarStartTimeId, PLID  
--From @ProdLines --with (nolock) -- Rev11.33    
--where VarStartTimeId is not null  
  
--Insert Into @variablelist (Var_Id, PL_ID)   
--Select distinct VarEndTimeId, PLID  
--From @ProdLines --with (nolock) -- Rev11.33    
--where VarEndTimeId is not null  
  
--Insert Into @variablelist (Var_Id, PL_ID)   
--Select distinct VarPRIDId, PLID  
--From @ProdLines --with (nolock) -- Rev11.33    
--where VarPRIDId is not null  
  
--Insert Into @variablelist (Var_Id, PL_ID)   
--Select distinct VarParentPRIDId, PLID  
--From @ProdLines --with (nolock) -- Rev11.33   
--where VarParentPRIDId is not null  
  
--Insert Into @variablelist (Var_Id, PL_ID)   
--Select distinct VarGrandParentPRIDId, PLID  
--From dbo.#ProdLines with (nolock) -- Rev11.33    
--where VarGrandParentPRIDId is not null  
  
--Insert Into @variablelist (Var_Id, PL_ID)   
--Select distinct VarUnwindStandId, PLID  
--From @ProdLines --with (nolock) -- Rev11.33    
--where VarUnwindStandId is not null  
  
Insert Into @variablelist (Var_Id, PL_ID)   
Select distinct VarGoodUnitsId, PLID  
From @ProdLines --with (nolock) -- Rev11.33    
where VarGoodUnitsId is not null  
  
Insert Into @variablelist (Var_Id, PL_ID)   
Select distinct VarTotalUnitsId, PLID  
From @ProdLines --with (nolock) -- Rev11.33   
where VarTotalUnitsId is not null  
  
Insert Into @variablelist (Var_Id, PL_ID)   
Select distinct VarPMRollWidthId, PLID  
From @ProdLines --with (nolock) -- Rev11.33    
where VarPMRollWidthId is not null  
  
Insert Into @variablelist (Var_Id, PL_ID)   
Select distinct VarParentRollWidthId, PLID  
From @ProdLines --with (nolock) -- Rev11.33    
where VarParentRollWidthId is not null  
  
Insert Into @variablelist (Var_Id, PL_ID)   
Select distinct VarEffDowntimeId, PLID  
From @ProdLines --with (nolock) -- Rev11.33    
where VarEffDowntimeId is not null  
  
Insert Into @variablelist (Var_Id, PL_ID)   
Select distinct VarActualLineSpeedId, PLID  
From @ProdLines --with (nolock) -- Rev11.33    
where VarActualLineSpeedId is not null  
  
Insert Into @variablelist (Var_Id, PL_ID)   
Select distinct VarLineSpeedId, PLID  
From @ProdLines --with (nolock) -- Rev11.33    
where VarLineSpeedId is not null  
  
Insert Into @variablelist (Var_Id, PL_ID)   
Select distinct VarId, PLID  
From @LineProdVars  
where VarID is not null  
  
  
-- Rev11.31  
update vl set  
 var_desc   = v.var_desc,  
 pu_id    = v.pu_id,  
 eng_units  = upper(v.eng_units),  
 extended_info = v.extended_info  
from @variablelist vl  
join dbo.variables v with (nolock)  
on vl.var_id = v.var_id  
join dbo.prod_units pu with (nolock)  
on v.pu_id = pu.pu_id    
  
  
--print 'Get Tests: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-------------------------------------------------------------  
-- Section 32: Get Tests  
-------------------------------------------------------------  
  
-- Certain test results need to be compiled for this report.  Originally,  
-- there were multiple queries against the test table in the database to do this.    
-- But, its more efficient to only hit the table one time, and get all the data   
-- needed and put it into a temporary table.  This insert statement is   
-- designed to get all the test results needed for #PRsRun, @ProdRecords,  
-- and to determine the Actual Line Speed for #Delays.  
-- Note that the population of #PRsRun originally joined to the Tests table   
-- FIVE times... adding this intermediary table leads to a big improvement in   
-- efficiency.  
  
-- NOTE:  Later in the procedure there are two other test related intermediary tables.    
-- (LimitTests, which is then used to load PackTests).  I attempted to remove those   
-- tables and pull the results for PackTests into this table, but I had a lot of trouble   
-- with it.  If this could be done, it would further reduce the hits to the database,  
-- and remove two tables from this procedure.   
  
 -- Rev11.31  
 INSERT dbo.#Tests   
  (  
  VarId,  
  PLId,  
  PUID,  
  Value,  
  SampleTime--,  
  )  
 SELECT  
  distinct   
  t.Var_Id,  
  v1.PL_Id,  
  v1.pu_id,  
  t.Result,     
  t.Result_On  
 from dbo.tests t with (nolock)  
 join @variablelist v1  
 on t.var_id = v1.var_id   
 and t.result_on <= @EndTime  
 AND t.result_on >= dateadd(d, -1, @StartTime)  
 and t.result is not null  
 join @ProdLines pl --with (nolock) -- Rev11.33  
 on pl.plid = v1.pl_id  
  
 delete dbo.#tests  
 where VarId in (select VarLineSpeedId from @prodlines) and convert(float,value) = 0.0  
  
  
 -- Rev11.31  
 update t set  
  puid   = ps.pu_id,  
  prodid  = ps.Prod_Id,  
  prodcode = p.Prod_Code  
 from dbo.production_starts ps with (nolock)  
 JOIN dbo.#tests t with (nolock)  
 ON ps.pu_id = t.puid   
 AND ps.Start_Time <= t.SampleTime  
 AND (ps.End_Time > t.SampleTime or ps.end_time is null)  
 JOIN dbo.Products p with (nolock)  
 on ps.prod_id = p.prod_id  
 option (keep plan)  
  
  
--print 'Section 17 @CrewSchedule: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
---------------------------------------------------------------  
-- Section 17: Get Crew Schedule information  
---------------------------------------------------------------  
  
insert @CrewSchedule  
 (  
 CS_Id,          -- 2009-08-31 VMK Rev11.77, Added.  
 Start_Time,  
 End_Time,  
 pu_id,  
 Crew_Desc,  
 Shift_Desc  
 )  
select distinct   
 CS_Id,          -- 2009-08-31 VMK Rev11.77, Added.  
 start_time,  
 end_time,  
 pu_id,  
 crew_desc,  
 shift_desc  
from dbo.crew_schedule cs with (nolock)  
join @produnits pu  
on cs.pu_id = pu.scheduleunit  
where cs.start_time < @endtime  
and (cs.end_time > @starttime or cs.end_time is null)  
option (keep plan)  
  
if (select count(*) from @crewschedule) = 0  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES (@NoTeamInfoMsg)  
 GOTO ReturnResultSets  
 END  
  
  
--print 'Section 18 @ProductionStarts: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-------------------------------------------------------------------------------  
-- Section 18: Get Production Starts  
-------------------------------------------------------------------------------  
  
insert @ProductionStarts   
 (  
 StartId,          -- 2009-08-31 VMK Rev11.77, Added.  
 Start_Time,  
 End_Time,  
 Prod_ID,  
 Prod_Code,  
 Prod_Desc,  
 PU_ID  
 )  
select  
 ps.Start_Id,        -- 2009-08-31 VMK Rev11.77, Added.   
 ps.start_time,  
 ps.end_time,  
 ps.prod_id,  
 p.prod_code,  
 p.prod_desc,  
 ps.pu_id  
from dbo.production_starts ps with (nolock)  
join dbo.products p with (nolock)  
on ps.prod_id = p.prod_id  
join @produnits pu  
on start_time < @endtime  
and (ps.end_time > @starttime or ps.end_time is null)  
--AND p.Prod_Desc <> 'No Grade'   
and pu.puid = ps.pu_id   
option (keep plan)  
  
  
--/*  
-- 2006-07-19   
insert @ProductionStarts   
 (  
 StartId,          -- 2009-08-31 VMK Rev11.77, Added.  
 Start_Time,  
 End_Time,  
 Prod_ID,  
 Prod_Code,  
 Prod_Desc,  
 PU_ID  
 )  
select   
 ps.Start_Id,        -- 2009-08-31 VMK Rev11.77, Added.  
 ps.start_time,  
 ps.end_time,  
 ps.prod_id,  
 p.prod_code,  
 p.prod_desc,  
 ps.pu_id  
from dbo.production_starts ps with (nolock)  
join dbo.products p with (nolock)  
on ps.prod_id = p.prod_id  
join @ProdUnitsPack pu  
on start_time < @endtime  
and (ps.end_time > @starttime or ps.end_time is null)  
--AND p.Prod_Desc <> 'No Grade'   
and pu.puid = ps.pu_id   
where pu.puid not in (select puid from @produnits)  
option (keep plan)  
--*/  
  
--print 'Section 19 @Products: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-----------------------------------------------------------------------------  
-- Section 19: Get Products  
-----------------------------------------------------------------------------  
  
insert @products  
 (  
 prod_id,  
 prod_code,  
 prod_desc  
 )  
select distinct  
 prod_id,  
 prod_code,  
 prod_desc  
from @productionstarts   
order by prod_id  
option (keep plan)  
  
  
--print 'Section 20 @ActiveSpecs: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
------------------------------------------------------------------  
-- Section 20: Get Active Specs  
------------------------------------------------------------------  
  
------------------------------------------------------------  
-- now that we have populated the @products table, we   
-- can get the active specifications that we'll need later   
-- in the SP.  This is done by joining Active_Specs with   
-- Specifications, Characteristics, and Product_Properties.  
-- It was by compiling the data in this table variable   
-- that the old @ProdRecords cursor could be eliminated.  
------------------------------------------------------------  
  
insert @activespecs  
 (  
 AS_Id,         -- 2009-08-31 VMK Rev11.77, Added.  
 effective_date,  
 expiration_date,  
 prod_id,  
 spec_id,  
 spec_desc,  
 char_id,  
 char_desc,  
 prop_id,  
 prop_desc,  
 target  
 )  
select distinct  
 asp.AS_Id,        -- 2009-08-31 VMK Rev11.77, Added.  
 asp.effective_date,  
 coalesce(asp.expiration_date,@endtime),  
 p.prod_id,  
 s.spec_id,  
 s.spec_desc,  
 c.char_id,  
 c.char_desc,  
 pp.prop_id,  
 pp.prop_desc,  
 asp.target  
from dbo.active_specs asp with (nolock)  
join dbo.characteristics c with (nolock)  
on asp.char_id = c.char_id   
join dbo.specifications s with (nolock)  
on asp.spec_id = s.spec_id  
join dbo.product_properties pp with (nolock)  
on s.prop_id = pp.prop_id  
join @products p on   
c.char_desc = prod_code  
where effective_date < @EndTime  
and (expiration_date > @StartTime or expiration_date is null)  
AND ISNUMERIC(asp.target)=1   --When a spec is deleted, Proficy puts '<Deleted>' in front of the value.    
          --We don't wnat those records--or any others that don't have valid numeric values.  
option (keep plan)  
  
/*  
--print 'Section 21 @LineProdVars: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-------------------------------------------------------------------------------  
-- Section 21: Get Line Production Variables     
-------------------------------------------------------------------------------  
  
--print '@BusinessType = ' + Convert(VarChar(5), @BusinessType)  
IF @BusinessType IN (3, 4) -- Facial/Hanky  
  
 -- Facial/Hanky bases its production off a dedicated pack line so we're going to find  
 -- the pack line associated with this production line and gather all the necessary info FROM it  
 -- We're also going to filter by the argument pack pu list for consistency  
 INSERT INTO @LineProdVars   
  (   
  PLId,  
  PUId,  
  VarId,  
  VarType  
  )  
 SELECT  pl.PLId,  
  pup.PUId,  
  v.Var_Id,  
  dbo.fnLocal_GlblParseInfo(v.Extended_Info, @VarTypeStr)  
 FROM dbo.Variables v with (nolock)  
 JOIN @ProdUnitsPack pup ON v.PU_Id = pup.PUId  
 JOIN @ProdLines pl --with (nolock)  
 ON pl.PackOrLine = 'Line' -- Rev11.33  
 AND LTRIM(RTRIM(REPLACE(pup.PLDesc, ' ', ''))) = LTRIM(RTRIM(REPLACE(pl.PLDesc, ' ', ''))) + 'PACK'  
 WHERE dbo.fnLocal_GlblParseInfo(v.Extended_Info, @VarTypeStr) IN (@ACPUnitsFlag, @HPUnitsFlag, @TPUnitsFlag)  
 option (keep plan)  
*/  
  
---------------------  
-- Populate #PRsRun  
---------------------  
  
--Rev11.55  
  
--print 'Running Status ID ' + CONVERT(VARCHAR(20), GetDate(), 120)  
select @RunningStatusID = ps.prodstatus_id   
from dbo.Production_Status ps WITH(NOLOCK)   
where UPPER(ps.prodstatus_desc) = 'RUNNING'   
  
--print 'EventStatusTransitions ' + CONVERT(VARCHAR(20), GetDate(), 120)  
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
and est.start_time < @endtime  
and (est.start_time < est.end_time or est.end_time is null)  
and (est.end_time > @starttime or est.end_time is null)  
  
  
--print 'Events ' + CONVERT(VARCHAR(20), GetDate(), 120)  
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
 coalesce(est.end_time,@endtime),  
 e.timestamp,  
 e.event_num,  
 'Initial Load'  
--from dbo.event_status_transitions est  
from dbo.#EventStatusTransitions est with (nolock)  
join dbo.events e with(nolock)  
on est.event_id = e.event_id  
  
  
--print 'source event ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
-- 2007-01-18 VMK Rev7.43, added code from PmkgDDSELP  
update e set  
 source_event = coalesce(ec.source_event_id,e.event_id)  
from dbo.#events e with (nolock)  
LEFT JOIN dbo.event_components ec with (nolock)  
ON e.event_id = ec.event_id  
  
--print 'PRSRun initial load' + CONVERT(VARCHAR(20), GETDATE(), 120)  
--20080721  
  
--20080721  
INSERT INTO dbo.#prsrun  
 (   
 [EventID],  
 SourceID,  
 [PLID],  
 [puid],  
 [EventNum],  
 [StartTime],  
 [InitEndTime],  
 [PRTimeStamp],  
 [PRPUID],  
 EventTimestamp,  
 [LineStatus],  
 DevComment    
 )  
SELECT distinct  
 e.event_id,  
 e.Source_Event,  
 pu.pl_id,  
 pu.pu_id,  
 e.event_num,  
  
 CONVERT(DATETIME, CONVERT(VARCHAR(20), e.start_time, 120)) [StartTime],  
 CONVERT(DATETIME, CONVERT(VARCHAR(20), e.end_time, 120)) [EndTime],  
  
 CONVERT(DATETIME, CONVERT(VARCHAR(20), e1.timestamp, 120)) [PRIDTimeStamp],   
 e1.pu_id [PRPUID],  
 e.timestamp,  
 'Rel Unknown:Qual Unknown' [LineStatus],  
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
  
  
--print 'PRSRun Time Updates ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
update prs set  
 starttime = @starttime  
from dbo.#prsrun prs with (nolock)  
where starttime < @starttime  
  
--20080721  
update prs set  
 endtime = @endtime  
from dbo.#PRsRun prs with (nolock)  
where endtime > @endtime  
  
  
update prs set  
 [ParentPRID] = UPPER(RTRIM(LTRIM(tprid.result))),  
-- [ParentPM] =  UPPER(RTRIM(LTRIM(LEFT(COALESCE(tprid.Result, 'NoAssignedPRID'), 2)))),  
 [UWS] = coalesce(tuws.result,'No UWS Assigned')  
from dbo.#prsrun prs with (nolock)  
join @prodlines pl  
on prs.puid = pl.prodpuid  
-- ParentPRID  
left JOIN dbo.Tests tprid with (nolock)  
on (tprid.Var_Id = pl.VarPRIDId and tprid.result_on = prs.EventTimeStamp)  
or (tprid.var_id = pl.VarParentPRIDId and tprid.result_on = prs.EventTimeStamp)  
-- Unwind Stands   
left JOIN dbo.Tests tuws with (nolock)  
on tuws.Var_Id = pl.VarUnwindStandID   
and tuws.result_on = prs.EventTimeStamp  
  
  
UPDATE prs SET   
 PEIId   = pei_id,  
 InputOrder = pei.Input_Order  
FROM dbo.#prsrun prs with (nolock)   
JOIN dbo.PrdExec_Inputs pei WITH (NOLOCK)   
ON pei.pu_id = prs.puid   
AND pei.input_name = prs.UWS  
  
  
-- Line FFF1 in Facial has a different configuration than other lines.  
-- This code will pull the correct PEIID and determine a unique   
-- input_order for parent rolls on this line.  
  
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
 from dbo.PrdExec_Inputs pei with (nolock)  
 where (  
    pei.pu_id = 1465  
   or pei.pu_id = 1466  
   or pei.pu_id = 1467  
   or pei.pu_id = 1468  
   )  
  
 UPDATE prs SET   
  PEIId   = pei.pei_id,  
  InputOrder  = pei.input_order  
 FROM dbo.#prsrun prs with (nolock)   
 JOIN @pei pei  
 ON prs.puid = pei.pu_id  
 and pei.input_name = prs.UWS  
 where prs.puid = 1464  
   
end  
end  
  
DELETE dbo.#prsrun  
WHERE PEIId IS NULL  
  
update prs SET   
 [ParentPRID] = coalesce(t.result,'NoAssignedPRID'),   
 [PRTimeStamp] = e.timestamp,  
 [PRPUID] = e.pu_id  
FROM dbo.#prsrun prs with (nolock)   
join @prodlines pl   
on prs.plid = pl.plid  
LEFT JOIN dbo.events e with (nolock)   
ON e.event_id = prs.eventid  
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
  
  
/*  
--print 'parent type' + ' ' + convert(varchar(25),current_timestamp,108)  
  
UPDATE prs SET   
 [ParentType] =   
  CASE   
  WHEN prs.[PRPUID] = iu.puid   
  THEN 2  
      ELSE 1  
      END  
FROM @prsrun prs   
LEFT JOIN @IntUnits iu   
ON iu.puid = prs.[PRPUID]  
*/  
  
--print 'grand prid ' + ' ' + convert(varchar(25),current_timestamp,108)  
  
UPDATE prs SET   
 [GrandParentPRID] = t.result--,  
FROM dbo.#prsrun prs with (nolock)   
JOIN dbo.variables v with (nolock)   
on v.pu_id = prs.[PRPUID]   
and v.var_desc_global = 'Input PRID'  
JOIN dbo.tests t with (nolock)   
ON t.var_id = v.var_id  
and t.result_on = prs.[PRTimestamp]   
--where v.var_desc_global = 'Input PRID'  
  
UPDATE prs SET   
 [GrandParentPRID] = t.result--,  
FROM dbo.#prsrun prs with (nolock)   
JOIN dbo.variables v with (nolock)   
on v.pu_id = prs.[PRPUID]   
and v.var_desc_global = 'Input Roll ID'  
JOIN dbo.tests t with (nolock)   
ON t.var_id = v.var_id  
and t.result_on = prs.[PRTimestamp]   
--where v.var_desc_global = 'Input Roll ID'  
where GrandParentPRID is null  
  
  
--print 'overlap' + ' ' + convert(varchar(25),current_timestamp,108)  
  
--Rev11.55  
-- to identify overlap adjustments, query the temp table for InitEndtime <> Endtime  
UPDATE prs1 SET   
 prs1.Endtime =   
  coalesce((  
  select top 1 prs2.Starttime  
  from dbo.#prsrun prs2 with (nolock)   
  where prs1.PUId = prs2.PUId  
  and prs1.StartTime <= prs2.StartTime   
  and prs1.InitEndTime > prs2.StartTime  
  AND prs1.PEIId = prs2.PEIId  
  and prs1.eventid <> prs2.eventid  
  order by puid, starttime  
  ), prs1.InitEndtime)  
FROM dbo.#prsrun prs1 with (nolock)   
  
delete dbo.#prsrun  
where StartTime = EndTime   
  
/*  
UPDATE prs SET [GrandParentPRID] =  UPPER(RTRIM(LTRIM(t.Result)))  
FROM dbo.#PRsRun    prs with (nolock)  
LEFT JOIN dbo.tests   t WITH (NOLOCK) ON  t.result_on = prs.[PRTimestamp]   
LEFT JOIN dbo.variables v WITH (NOLOCK) ON  v.var_id  = t.var_id   
              AND  v.pu_id   = prs.[PRPUID]   
WHERE ( v.extended_info LIKE 'GlblDesc=Input Roll ID;'  
  OR v.extended_info LIKE 'GlblDesc=Input PRID;')  
*/  
  
--print 'fill gaps ' + CONVERT(VARCHAR(20), GetDate(), 120)  
 -------------------------------------------------------------------------------------------  
 -- 2007-01-16 VMK Rev11.30, moved this code to fill gaps so that it is below the update  
 --          to the EndTime for cases when the EndTime overlaps the  
 --          next StartTime.  
 -- 2006-03-29 VMK Rev11.15  
 -- #PRsRun includes PRs run for the converting lines included in the report.  However, it   
 -- does not include time slices where there is no PR loaded on the UWS.    
 -- Now add the records that fill in that time and assign them to 'NoAssignedPRID'.  
 -------------------------------------------------------------------------------------------  
 INSERT dbo.#PRsRun   
  (   
  EventId,  
  PLID,  
  PUId,  
  PEIId,    
  StartTime,  
  EndTime,  
  ParentPRID,  
  GrandParentPRID,   
  UWS,  
  InputOrder,  
  DevComment   
  )  
 SELECT    
  NULL,  
  prs1.PLID,  
  prs1.PUId,  
  prs1.PEIId,   
  prs1.EndTime,  
  prs2.StartTime,  
  'NoAssignedPRID',  
  'NoAssignedPRID',  
  prs1.UWS,  
  prs1.InputOrder, --NULL,  
  'Fill gaps'  
 FROM dbo.#PRsRun prs1 with (nolock)-- Rev11.33  
 JOIN dbo.#PRsRun prs2 with (nolock)  
   ON prs1.PUId = prs2.PUId -- Rev11.33  
         AND prs1.PEIId  = prs2.PEIId       -- 2007-01-16 VMK Rev11.30, added  
         AND prs2.StartTime = (SELECT TOP 1 prs.StartTime FROM dbo.#PRsRun prs with (nolock)-- Rev11.33  
                WHERE prs.StartTime > prs1.StartTime   
                AND prs.PUId = prs1.PUId  
                AND prs.PEIId = prs1.PEIId  -- 2007-01-16 VMK Rev11.30, added  
                ORDER BY prs.StartTime ASC)  
 WHERE prs1.EndTime <> prs2.StartTime  
  AND prs2.StartTime > prs1.EndTime  
 OPTION (KEEP PLAN)   
  
--print 'PR Start ' + CONVERT(VARCHAR(20), GetDate(), 120)  
 INSERT dbo.#PRsRun   
  ( -- Rev11.33  
  EventId,  
  PLID,  
  PUId,  
  PEIId,   
  StartTime,  
  EndTime,  
  ParentPRID,  
  GrandParentPRID,   
  UWS,  
  InputOrder,  
  DevComment   
  )  
 SELECT    
  NULL,  
  prs1.PLID,  
  prs1.PUId,  
  prs1.PEIId,   
  @StartTime,  
  prs1.StartTime,  
  'NoAssignedPRID',  
  'NoAssignedPRID',  
  prs1.UWS,  
  prs1.InputOrder, --NULL,  
  'Start of Report Window'  
 FROM dbo.#PRsRun prs1 with (nolock)-- Rev11.33  
 where prs1.StartTime > @starttime   
 and (prs1.endtime > @starttime or prs1.endtime is null)  
 and prs1.StartTime =   
 (  
 SELECT TOP 1 prs.StartTime   
 FROM dbo.#prsrun prs with (nolock)   
 WHERE prs.PUId = prs1.PUId  
 AND prs.PEIId = prs1.PEIId  
 ORDER BY prs.StartTime ASC  
 )  
OPTION (KEEP PLAN)  
  
--print 'PR End ' + CONVERT(VARCHAR(20), GetDate(), 120)  
 INSERT dbo.#PRsRun   
  ( -- Rev11.33  
  EventId,  
  PLID,  
  PUId,  
  PEIId,   
  StartTime,  
  EndTime,  
  ParentPRID,  
  GrandParentPRID,   
  UWS,  
  InputOrder,  
  DevComment   
  )  
 SELECT    
  NULL,  
  prs1.PLID,  
  prs1.PUId,  
  prs1.PEIId,   
  prs1.EndTime,  
  @EndTime,  
  'NoAssignedPRID',  
  'NoAssignedPRID',  
  prs1.UWS,  
  prs1.InputOrder, --NULL,  
  'End of Report Window'  
 FROM dbo.#PRsRun prs1 with (nolock)-- Rev11.33  
 where prs1.StartTime < @starttime   
 and (prs1.endtime < @starttime or prs1.endtime is null)  
 and prs1.StartTime =   
 (  
 SELECT TOP 1 prs.StartTime   
 FROM dbo.#prsrun prs with (nolock)   
 WHERE prs.PUId = prs1.PUId  
 AND prs.PEIId = prs1.PEIId  
 ORDER BY prs.StartTime ASC  
 )  
OPTION (KEEP PLAN)  
  
  
------------------------------------------------------------------------------------------------------------  
--print 'Section 22 Dimensions: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
--------------------------------------------------------------------  
-- Section 22: Get the dimensions to be used  
--------------------------------------------------------------------  
  
/*--------------------------------------------------------------------------------------  
  
Overview:  
  
Think of the time on a production unit as a constant timeline that is broken up by changes of   
various types (called dimensions).  Examples would be a change in Product being made, the Team   
working, the Shift working, the Target Speed of the line, the Line Status, etc.  Whenever   
the value of ANY dimension changes, there is a break in the timeline.    
  
NOTE that "dimension" is a term taken from data warehousing, and is used in a similar way.  
  
  
@Dimensions:  
  
The @Dimensions table tracks the different dimensions by which we want to split    
the timeline.  The table tracks each type of Dimension (in this case, ProdID, Team,   
Shift, TargetSpeed, and LineStatus, although more can be easily added, as needed),   
along with the different possible values associated with those dimensions (meaning only those   
values that actually occur within the report window), as well as the start and end time that   
each dimensional value comes into affect.    
  
If a new dimension is added to the table, it may need to be added to the indices of some result sets.  
Also, new dimensions may need to be added to @ProdRecords, #SplitDowntimes, and #SplitUptime.   
  
@Runs:  
  
If the starttimes of ALL the dimensional values for a given prod unit are laid out,   
in chronilogical order,  what we have are different segments of the timeline on that   
prod unit, each having a value for the different dimensions being tracked.  The @runs   
table will hold the start and end time of each segment, along with information about   
the dimensional values for each segment.    
  
----------------------------------------------------------------------------------*/  
  
------------------------------------------------------------  
-- add the prodid dimension  
------------------------------------------------------------  
  
insert dbo.#Dimensions   
 (  
 DimensionId,      -- 2009-08-31 VMK Rev11.77, Added.  
 Dimension,  
 Value,  
 Starttime,  
 EndTime,  
 PLID,  
 PUID  
 )  
SELECT distinct   
 StartId,        -- 2009-08-31 VMK Rev11.77, Added.  
 'ProdID',  
 ps.Prod_Id,  
 ps.Start_Time,  
 ps.End_Time,  
 pu.PLID,  
 ps.PU_Id  
FROM @ProductionStarts ps  
JOIN @ProdUnits pu ON ps.PU_Id = pu.PUId  
JOIN @DelayTypes dt ON dt.DelayTypeDesc = GBDB.dbo.fnLocal_GlblParseInfo(pu.ExtendedInfo, @PUDelayTypeStr)  
ORDER BY ps.start_time, ps.PU_Id  
option (keep plan)  
  
-- add the Team dimension  
insert dbo.#Dimensions  
 (  
 DimensionId,      -- 2009-08-31 VMK Rev11.77, Added.  
 Dimension,  
 Value,  
 Starttime,  
 EndTime,  
 PLID,  
 PUID  
 )  
select  distinct  
 CS_Id,        -- 2009-08-31 VMK Rev11.77, Added.  
 'Team',  
 Crew_Desc,  
 start_time,  
 end_time,  
 pu.PLID,  
 pu.puid  
from @crewschedule cs  
join @produnits pu on cs.pu_id = scheduleunit  
option (keep plan)  
  
  
-- add the shift dimension  
insert dbo.#Dimensions  
 (  
 DimensionId,      -- 2009-08-31 VMK Rev11.77, Added.  
 Dimension,  
 Value,  
 Starttime,  
 EndTime,  
 PLID,  
 PUID  
 )  
select  distinct  
 CS_Id,        -- 2009-08-31 VMK Rev11.77, Added.  
 'Shift',  
 Shift_Desc,  
 start_time,  
 end_time,  
 pu.PLID,  
 pu.puid  
from @crewschedule cs  
join @produnits pu on cs.pu_id = scheduleunit  
option (keep plan)  
  
  
--Rev11.55  
-- add the ShiftStart dimension  
insert dbo.#Dimensions  
 (  
 DimensionId,      -- 2009-08-31 VMK Rev11.77, Added.  
 Dimension,  
 Value,  
 Starttime,  
 EndTime,  
 PLID,  
 PUID  
 )  
select  distinct  
 CS_Id,        -- 2009-08-31 VMK Rev11.77, Added.  
 'ShiftStart',  
 convert(varchar(50),cs.Start_Time),  
 cs.start_time,  
 cs.end_time,  
 pu.PLID,  
 pu.puid  
from @crewschedule cs  
join @produnits pu   
on cs.pu_id = pu.scheduleunit -- pu.puid --   
option (keep plan)  
  
  
-- add target speed  
insert dbo.#Dimensions  
 (  
 DimensionId,      -- 2009-08-31 VMK Rev11.77, Added.  
 Dimension,  
 Value,  
 Starttime,  
 EndTime,  
 PLID,  
 PUID  
 )  
select  distinct  
 AS_Id,         -- 2009-08-31 VMK Rev11.77, Added.  
 'TargetSpeed',  
 asp.target,   
 asp.effective_date,  
 asp.expiration_date,  
 pl.plid,  
 ps.pu_id  
from @activespecs asp  
join @productionstarts ps  
on ps.prod_id = asp.prod_id  
join @produnits pu   
on ps.pu_id = pu.puid   
join @prodlines pl --with (nolock) -- Rev11.33   
on pu.plid = pl.plid  
and asp.prop_id = pl.PropLineProdFactorId  
where asp.spec_desc = @LineSpeedTargetSpecDesc --'Line Speed Target'  
and pu.pudesc like  '%Converter Reliability%'  
and asp.prop_desc = ltrim(rtrim(replace(PLDesc,@PPTT,''))) + ' ' + @LineProdFactorDesc  
option (keep plan)  
  
  
-- add Line Status  
  
insert dbo.#Dimensions  
 (  
 DimensionId,      -- 2009-08-31 VMK Rev11.77, Added.  
 dimension,   
 value,  
 StartTime,  
 EndTime,  
 PLID,  
 PUId  
 )  
  
SELECT   
 Status_Schedule_Id,    -- 2009-08-31 VMK Rev11.77, Added.  
 'LineStatus',  
 phrase_value,  
 ls.Start_DATETIME,  
 coalesce(ls.End_Datetime,@Endtime),  
 pu.plid,  
 pu.PUId  
FROM dbo.Local_PG_Line_Status ls with (nolock)  
JOIN @ProdUnits pu   
ON ls.Unit_Id = pu.LineStatusUnit   
AND pu.PUId > 0  
JOIN dbo.Phrase p with (nolock)  
ON line_status_id = p.Phrase_Id  
where ls.update_status <> 'DELETE'    
and ls.start_datetime < @EndTime  
and (ls.end_datetime > @StartTime or ls.end_datetime is null)  
option (keep plan)  
  
--  
-- add code for any additional dimensions  
--  
  
-------------------------------------------------------------------------------------------  
-- limit the starttime and endtime of @Dimensions to the report window start and end time  
-------------------------------------------------------------------------------------------  
  
update dbo.#Dimensions set  
 starttime = @StartTime  
where starttime < @StartTime  
  
update dbo.#Dimensions set  
 endtime = @EndTime  
where endtime > @EndTime  
or endtime is null  
  
--print 'Section 23 run times, values for dimensions: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-------------------------------------------------------------  
-- Section 23: Get the run times and values for each dimension  
-------------------------------------------------------------  
  
-------------------------------------------------------------  
-- create the intial time periods of the production runs.  
-- the runtime needs to be laid out as a series of changes...  
-- initially, we don't care WHY the change takes place (meaning   
-- which dimension is undergoing the change).  We just need   
-- to lay the times of these changes out into a straight line.  
-- for this purpose, we only care about the start times.  
-------------------------------------------------------------  
  
-- 2007-04-11 VMK Rev11.37, Insert PEIId with PLId and PUId.  
insert @runs  
 (  
 PLID,  
 PUID,  
 StartTime )  
select  distinct  
 PLID,  
 puid,  
 starttime  
from dbo.#Dimensions with (nolock)  
group by plid, puid, starttime  
order by puid, StartTime      
option (keep plan)  
  
--------------------------------------------------------------------  
-- once we know what time each new time split started, we can   
-- determine the endtime by simply looking at the NEXT start time  
-- in the line.  
--------------------------------------------------------------------  
  
update r1 set  
 endtime =   
  (  
  select top 1 starttime  
  from @runs r2  
  where r1.puid = r2.puid  
  and r1.starttime < r2.starttime  
  )  
from @runs r1  
  
update @runs set  
 endtime = @endtime  
where endtime is null  
    
  
-------------------------------------------------------  
-- now that we know where the time splits are, we need  
-- to determine what the dimensional values are in   
-- each time segment. this requires an update for each   
-- dimension.  
------------------------------------------------------  
  
-- get the ProdID   
  
update r set  
 ProdID =   
  (  
  select value  
  from dbo.#Dimensions d with (nolock)  
  where d.puid = r.puid  
  and d.starttime < r.endtime  
  and (d.endtime > r.starttime or d.endtime is null)  
  and Dimension = 'ProdID'  
  )  
from @runs r  
  
  
-- get the Team  
  
update r set   
 Team =   
  (  
  select value  
  from dbo.#Dimensions d with (nolock)  
  where d.puid = r.puid  
  and d.starttime < r.endtime  
  and (d.endtime > r.starttime or d.endtime is null)  
  and Dimension = 'Team'  
  )   
from @runs r  
  
  
-- get the shift  
  
update r set   
 Shift =   
  (  
  select value  
  from dbo.#Dimensions d with (nolock)  
  where d.puid = r.puid  
  and d.starttime < r.endtime  
  and (d.endtime > r.starttime or d.endtime is null)  
  and Dimension = 'Shift'  
  )   
from @runs r  
  
-- Rev11.55  
update r set   
 ShiftStart =   
  (  
--  select distinct convert(datetime,value)  
  select distinct value  
  from dbo.#Dimensions d with (nolock)   
  where d.puid = r.puid  
  and d.starttime < r.endtime  
  and (d.endtime > r.starttime or d.endtime is null)  
  and Dimension = 'ShiftStart'  
  )   
from @runs r   
  
  
-- get the target speed  
  
update r set  
 targetspeed =  
 (  
 select top 1   
 target  
 from @activespecs asp  
 WHERE asp.prod_id = r.prodid  
 AND asp.Prop_Id = pl.PropLineProdFactorId  
 and asp.Spec_Desc = @LineSpeedTargetSpecDesc  
 and Effective_Date <= r.starttime  
 order by effective_date desc  
 )  
from @runs r  
join @prodlines pl --with (nolock) -- Rev11.33  
on r.plid = pl.plid  
  
  
-- get the ideal speed  
-- note that this is not actually a dimension by which we have split our runtime.  
-- it is actually associated with product.  
  
update r set  
 idealspeed =  
 (  
 select top 1   
 target  
 from @activespecs asp  
 WHERE asp.prod_id = r.prodid  
 AND asp.Prop_Id = pl.PropLineProdFactorId  
 and asp.Spec_Desc = @LineSpeedIdealSpecDesc  
 and Effective_Date <= r.starttime  
 order by effective_date asc  
 )  
from @runs r  
join @prodlines pl --with (nolock) -- Rev11.33  
on r.plid = pl.plid  
  
-- get the line status  
-- 2007-03-13 VMK Rev11.37, and get PRSIdNum  
  
update r set   
 LineStatus =   
  (  
  select value  
  from dbo.#Dimensions d with (nolock)  
  where d.puid = r.puid  
  and d.starttime < r.endtime  
  and (d.endtime > r.starttime or d.endtime is null)  
  and Dimension = 'LineStatus'  
  )  
from @runs r  
  
  
--print 'Section 24 @RunSummary: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-----------------------------------------------------------------------------------  
-- Section 24: Populate @RunSummary  
-----------------------------------------------------------------------------------  
  
-- @RunSummary simply summarizes data from @Runs.  
-- For Hanky lines, the production is captured FROM the pack units.  Added IF  
-- statement to SELECT ONLY Converter Reliability unit(s) for Tissue/Towel.  
  
IF @BusinessType = 3  
 BEGIN  
  INSERT INTO @RunSummary   
   (   
   PLId,  
   PUId,  
   Shift,  
   Team,  
   ProdId,  
   StartTime,  
   EndTime,  
   TargetSpeed,  
   IdealSpeed,   
   LineStatus,  
   Runtime      -- 2007-03-22 VMK Rev11.37, Added.  
   )  
   
  SELECT distinct   
   PLId,  
   PUId,  
   Shift,  
   Team,  
   ProdId,  
   StartTime,  
   EndTime,  
   TargetSpeed,  
   IdealSpeed,  
   LineStatus,  
   SUM(DATEDIFF(ss, rls.StartTime, rls.EndTime) / 60.0)  -- 2007-03-22 VMK Rev11.37, Added.  
  FROM @runs rls  
  GROUP BY PLId, PuId, Team, Shift, ProdId, LineStatus, StartTime, EndTime, TargetSpeed, IdealSpeed  
  option (keep plan)  
 END  
ELSE  
 BEGIN  
  INSERT INTO @RunSummary   
   (   
   PLId,  
   PUId,  
   Shift,  
   Team,  
   ProdId,  
   StartTime,  
   EndTime,  
   TargetSpeed,  
   IdealSpeed,  
   LineStatus,  
   Runtime     -- 2007-03-22 VMK Rev11.37, Added  
   )  
   
  SELECT distinct   
   rls.PLId,  
   rls.PUId,  
   Shift,  
   Team,  
   ProdId,  
   StartTime,  
   EndTime,  
   TargetSpeed,  
   IdealSpeed,  
   LineStatus,  
   SUM(DATEDIFF(ss, rls.StartTime, rls.EndTime) / 60.0)  -- 2007-03-22 VMK Rev11.37, Added.  
  FROM @runs rls  
  JOIN @ProdUnits pu ON rls.PUId = pu.PUId  
  WHERE PUDesc LIKE '%Converter Reliability%'   
  GROUP BY rls.PLId, rls.PuId, Team, Shift, ProdId, LineStatus, StartTime, EndTime, TargetSpeed, IdealSpeed  
  option (keep plan)  
 END  
  
--print 'Section 25 Timed Event Details: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-------------------------------------------------------------------------------  
-- Section 25: Get the Time Event Details  
-------------------------------------------------------------------------------  
  
-- We get basic delays information from the real table, Timed_Event_Details.  
-- #TimedEventDetails is an intermediary table that is used so that we don't have to   
-- join to the real table 3 times in populating #Delays.  
  
-- Note that after the intermediary table is populated we do still access the real table   
-- a number of times (with multiple inserts to #TimedEventDetails, and to populate @FirstEvents).    
-- This is done to get related records that are outside of our report window.  If we could find   
-- a way to identify these records and include them in the initial insert to #TimedEventDetails,   
-- then we could remove a lot of the code below and reduce the hits to the database.    
  
  
 -- initial insert  
 insert dbo.#TimedEventDetails  
  (  
  TEDet_ID,  
  Start_Time,  
  End_Time,  
  PU_ID,  
  Source_PU_Id,  
--Rev11.55  
  Uptime,  
  Reason_Level1,  
  Reason_Level2,  
  Reason_Level3,  
  Reason_Level4,  
  TEFault_Id,  
  ERTD_ID,  
  Cause_Comment_Id--,  
--Rev11.55  
--  Cause_Comment  
  )  
 select  
  TEDet_ID,  
  Start_Time,  
  End_Time,  
  PU_ID,  
  Source_PU_Id,  
--Rev11.55  
  Uptime * 60.0,  
  Reason_Level1,  
  Reason_Level2,  
  Reason_Level3,  
  Reason_Level4,  
  TEFault_Id,  
  ted.event_reason_tree_data_id,  
  ted.Cause_Comment_ID --Co.Comment_Id--,  
--Rev11.55  
--  REPLACE(coalesce(convert(varchar(5000),co.comment_text),''), char(13)+char(10), ' ')  
 from dbo.timed_event_details ted with (nolock)  
 join @produnits pu  
 on ted.pu_id = pu.puid  
--Rev11.55  
-- LEFT JOIN dbo.Comments Co with (nolock) ON Co.Comment_Id = ted.Cause_Comment_Id  
 where Start_Time < @EndTime  
 AND (End_Time > @StartTime or end_time is null)  
--Rev11.55  
-- order by ted.pu_id, ted.start_time, ted.end_time  
 option (keep plan)  
  
 -- get the secondary events that span after the report window  
 insert dbo.#TimedEventDetails  
  (  
  TEDet_ID,  
  Start_Time,  
  End_Time,  
  PU_ID,  
  Source_PU_Id,  
--Rev11.55  
  Uptime,  
  Reason_Level1,  
  Reason_Level2,  
  Reason_Level3,  
  Reason_Level4,  
  TEFault_Id,  
  ERTD_ID,  
  Cause_Comment_Id--,  
--Rev11.55  
--  Cause_Comment  
  )  
 select  
  ted2.TEDet_ID,  
  ted2.Start_Time,  
  ted2.End_Time,  
  ted2.PU_ID,  
  ted2.Source_PU_Id,  
--Rev11.55  
  ted2.Uptime,  
  ted2.Reason_Level1,  
  ted2.Reason_Level2,  
  ted2.Reason_Level3,  
  ted2.Reason_Level4,  
  ted2.TEFault_Id,  
  ted2.event_reason_tree_data_id,  
  ted2.Cause_Comment_ID --Co.Comment_Id--,  
--Rev11.55  
--   Co.Comment_Text  
 from  dbo.#TimedEventDetails ted1 with (nolock)  
 join  (  
  select   
   tted.TEDet_ID,  
   tted.Start_Time,  
   tted.End_Time,  
   tted.PU_ID,  
   tted.Source_PU_Id,  
   -- Rev11.55  
   tted.Uptime * 60.0 Uptime,  
   tted.Reason_Level1,  
   tted.Reason_Level2,  
   tted.Reason_Level3,  
   tted.Reason_Level4,  
   tted.TEFault_Id,  
   tted.event_reason_tree_data_id,  
   tted.Cause_Comment_Id  
  from dbo.timed_event_details tted with (nolock)  
  join @produnits tpu  
  on tted.pu_id = tpu.puid   
  and tted.start_time >= @Endtime   
  ) ted2  
 on ted1.PU_Id = ted2.PU_Id  
 AND ted1.End_Time = ted2.Start_Time  
 and ted2.start_time >= @endtime  
 AND ted1.TEDet_Id <> ted2.TEDet_Id  
--Rev11.55  
-- LEFT JOIN dbo.Comments Co with (nolock) ON Co.Comment_Id = ted2.Cause_Comment_Id  
 option (keep plan)  
  
  -- get the secondary events that span before the report window  
    
 insert dbo.#TimedEventDetails  
   (  
   TEDet_ID,  
   Start_Time,  
   End_Time,  
   PU_ID,  
   Source_PU_Id,  
  --Rev11.5  
  Uptime,  
   Reason_Level1,  
   Reason_Level2,  
   Reason_Level3,  
   Reason_Level4,  
   TEFault_Id,  
  ERTD_ID,  
   Cause_Comment_Id--,  
--Rev11.55  
--   Cause_Comment  
   )  
  select  
  ted1.TEDet_ID,  
  ted1.Start_Time,  
  ted1.End_Time,  
  ted1.PU_ID,  
  ted1.Source_PU_Id,  
  --Rev11.55  
  ted1.Uptime,  
  ted1.Reason_Level1,  
  ted1.Reason_Level2,  
  ted1.Reason_Level3,  
  ted1.Reason_Level4,  
  ted1.TEFault_Id,  
  ted1.event_reason_tree_data_id,  
   ted1.Cause_Comment_ID --Co.Comment_Id--,  
--Rev11.55  
--    Co.Comment_Text  
  from dbo.#TimedEventDetails ted2 with (nolock)  
  join  (  
   select   
   tted.TEDet_ID,  
   tted.Start_Time,  
   tted.End_Time,  
   tted.PU_ID,  
   tted.Source_PU_Id,  
   --Rev11.55  
   tted.Uptime * 60.0 Uptime,  
   tted.Reason_Level1,  
   tted.Reason_Level2,  
   tted.Reason_Level3,  
   tted.Reason_Level4,  
   tted.TEFault_Id,  
   tted.event_reason_tree_data_id,  
   tted.Cause_Comment_Id  
   from dbo.timed_event_details tted with (nolock)  
   join @produnits tpu  
   on tted.pu_id = tpu.puid   
   and tted.start_time < @starttime   
   and tted.end_time <= @Starttime   
   ) ted1  
  on ted1.PU_Id = ted2.PU_Id  
  AND ted1.End_Time = ted2.Start_Time  
  and ted1.end_time <= @starttime  
 and ted2.end_time <= @endtime  -- added to address OX issue  
  AND ted1.TEDet_Id <> ted2.TEDet_Id  
--Rev11.55  
--  LEFT JOIN dbo.Comments Co with (nolock) ON Co.Comment_Id = ted2.Cause_Comment_Id  
  option (keep plan)  
  
--Rev11.55  
-- END  
  
--Rev11.55  
update ted set  
 cause_comment = REPLACE(coalesce(convert(varchar(5000),co.comment_text),''), char(13)+char(10), ' ')  
from dbo.#TimedEventDetails ted with (nolock)  
left join dbo.Comments co with (nolock)  
on ted.cause_comment_id = co.comment_id  
  
  
--print 'Section 26 #Delays: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
------------------------------------------------------------------------  
-- Section 26: Get the initial set of delays for the report period  
------------------------------------------------------------------------  
  
-------------------------------------------------------------------------------  
-- Collect dataset filtered by report period and Production Units.  
-------------------------------------------------------------------------------  
/* Can probably revert to this once the Timed_Event_Details index is changed to Clustered */  
INSERT dbo.#Delays (TEDetId,  
  PLID,  
  PUId,  
  StartTime,  
  EndTime,  
  LocationId,  
  --Rev11.55  
  Uptime,  
  L1ReasonId,  
  L2ReasonId,  
  L3ReasonId,  
  L4ReasonId,  
  TEFaultId,  
  ERTD_ID,  
  DownTime,  
  SplitDowntime,  
  PrimaryId,  
  SecondaryId,  
  InRptWindow,  
  Comment)  
SELECT ted.TEDet_Id,  
 tpu.plid,  
 ted.PU_Id,  
 ted.Start_Time,  
 COALESCE(ted.End_Time, @EndTime),  
 ted.Source_PU_Id,  
 --Rev11.55  
 ted.Uptime,  
 ted.Reason_Level1,  
 ted.Reason_Level2,  
 ted.Reason_Level3,  
 ted.Reason_Level4,  
 ted.TEFault_Id,  
 ted.ERTD_ID,  
 DATEDIFF(ss, ted.Start_Time,COALESCE(ted.End_Time, @EndTime)),  
 COALESCE(DATEDIFF(ss, CASE WHEN ted.Start_Time <= @StartTime   
          THEN @StartTime   
          ELSE ted.Start_Time  
          END,   
 CASE WHEN COALESCE(ted.End_Time, @EndTime) >= @EndTime   
   THEN @EndTime   
   ELSE COALESCE(ted.End_Time, @EndTime)  
   END), 0.0),    
 ted2.TEDet_Id,  
 ted3.TEDet_Id,  
 CASE WHEN (ted.start_time < @EndTime and coalesce(ted.end_time,@EndTime) > @StartTime)   
   THEN 1  
   ELSE 0  
   END,  
 ted.Cause_Comment  
FROM dbo.#TimedEventDetails ted with (nolock)  
JOIN @ProdUnits tpu    
ON ted.PU_Id = tpu.PUId  
AND tpu.PUId > 0  
LEFT JOIN dbo.#TimedEventDetails ted2 with (nolock)  
ON ted.PU_Id = ted2.PU_Id  
AND ted.Start_Time = ted2.End_Time  
AND ted.TEDet_Id <> ted2.TEDet_Id  
LEFT JOIN dbo.#TimedEventDetails ted3 with (nolock)  
ON ted.PU_Id = ted3.PU_Id  
AND ted.End_Time = ted3.Start_Time  
AND ted.TEDet_Id <> ted3.TEDet_Id  
option (keep plan)  
  
  
--print 'Section 28 Addl updates to #Delays: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
---------------------------------------------------------------------------  
-- Section 28: Additional updates to #Delays  
---------------------------------------------------------------------------  
  
Update td set  
 Plid = pu.plid   
from dbo.#delays td with (nolock)  
join @produnits pu  
on td.puid = pu.puid  
where td.plid is null   
  
  
-- Add PUDesc Rev11.50  
--/*  
UPDATE td  
SET PUDESC =    
 CASE   
 WHEN pu.PU_Desc NOT LIKE '%Converter Reliability%'  
 AND pu.PU_Desc NOT LIKE '%Rate Loss%'  
 THEN pu.PU_Desc    
 ELSE pu1.pu_desc   
 END  
FROM dbo.#Delays td with (nolock)  
JOIN dbo.Prod_units pu ON td.PUID = pu.PU_Id  
JOIN @ProdLines pl --with (nolock)   
ON pu.PL_Id = pl.PLId -- Rev11.33  
left join dbo.prod_units pu1  
on pl.reliabilitypuid = pu1.pu_id  
--WHERE td.pudesc is null   
--*/  
  
  
-------------------------------------------------------------------------------  
-- Ensure that all the PrimaryIds point to the actual Primary event.  
-------------------------------------------------------------------------------  
  
WHILE (   
 SELECT count(td1.TEDetId)  
 FROM dbo.#Delays td1 with (nolock)  
  JOIN dbo.#Delays td2 with (nolock) ON td1.PrimaryId = td2.TEDetId  
 WHERE td2.PrimaryId IS NOT NULL  
 ) > 0  
 BEGIN  
 UPDATE td1  
 SET PrimaryId = td2.PrimaryId  
 FROM dbo.#Delays td1 with (nolock)  
  INNER JOIN dbo.#Delays td2 with (nolock) ON td1.PrimaryId = td2.TEDetId  
 WHERE td2.PrimaryId IS NOT NULL  
 END  
  
UPDATE dbo.#Delays  
SET PrimaryId = TEDetId  
WHERE PrimaryId IS NULL  
  
  
--print 'Section 29 TE_Categories: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-------------------------------------------------------------------------------  
-- Section 29: Get the Timed Event Categories for #Delays  
-------------------------------------------------------------------------------  
  
-------------------------------------------------------------------------------  
-- Retrieve the Schedule, Category, GroupCause and SubSystem categories for the  
-- Timed_Event_Details row FROM the Local_Timed_Event_Categories table using  
-- the TEDet_Id.  
-------------------------------------------------------------------------------  
/*  
-- Get the minimum - maximum range for later queries  
SELECT @Max_TEDet_Id  = MAX(TEDetId) + 1,  
 @Min_TEDet_Id = MIN(TEDetId) - 1,  
 @RangeStartTime = MIN(StartTime),  
 @RangeEndTime = MAX(EndTime)  
FROM dbo.#Delays with (nolock)  
option (keep plan)  
  
  
INSERT INTO @TECategories   
 (  
 TEDet_Id,  
 ERC_Id  
 )  
SELECT tec.TEDet_Id,  
 tec.ERC_Id  
FROM dbo.#Delays td with (nolock)  
JOIN  dbo.Local_Timed_Event_Categories tec with (nolock)  
ON td.TEDetId = tec.TEDet_Id  
and tec.TEDet_Id > @Min_TEDet_Id  
AND tec.TEDet_Id < @Max_TEDet_Id  
option (keep plan)  
  
UPDATE td  
SET ScheduleId = tec.ERC_Id  
FROM dbo.#Delays td with (nolock)  
JOIN  @TECategories tec   
ON  td.TEDetId = tec.TEDet_Id  
JOIN  dbo.Event_Reason_Catagories erc with (nolock)  
ON tec.ERC_Id = erc.ERC_Id  
AND  erc.ERC_Desc LIKE @ScheduleStr + '%'  
  
UPDATE td  
SET ScheduleId = @SchedBlockedStarvedId  
FROM dbo.#Delays td with (nolock)  
JOIN dbo.Event_Reasons er with (nolock)  
on Event_Reason_ID = L1ReasonId   
WHERE ScheduleId IS NULL   
AND (Event_Reason_Name LIKE '%BLOCK%' OR Event_Reason_Name LIKE '%STARVE%')  
  
UPDATE td  
SET CategoryId = tec.ERC_Id  
FROM dbo.#Delays td with (nolock)  
JOIN  @TECategories tec   
ON  td.TEDetId = tec.TEDet_Id  
JOIN  dbo.Event_Reason_Catagories erc with (nolock)  
ON tec.ERC_Id = erc.ERC_Id  
AND  erc.ERC_Desc LIKE @CategoryStr + '%'  
*/  
  
UPDATE td SET  
 ScheduleId = erc.ERC_Id  
FROM dbo.#Delays td with (nolock)  
JOIN dbo.event_reason_category_data ercd WITH (NOLOCK)   
ON TD.ERTD_ID = ercd.event_reason_tree_data_id   
JOIN dbo.event_reason_catagories erc WITH (NOLOCK)   
ON ercd.erc_id = erc.erc_id   
where erc.ERC_Desc LIKE @ScheduleStr + '%'  
  
  
UPDATE td SET   
 ScheduleId = @SchedBlockedStarvedId  
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
  
  
IF @IncludeStops = 1  
 BEGIN  
  
/*  
  UPDATE td  
  SET GroupCauseId = tec.ERC_Id  
  FROM dbo.#Delays td with (nolock)  
  JOIN @TECategories tec   
  ON td.TEDetId = tec.TEDet_Id  
  JOIN dbo.Event_Reason_Catagories erc with (nolock)  
  ON tec.ERC_Id = erc.ERC_Id                     
  AND erc.ERC_Desc LIKE @GroupCauseStr + '%'  
  
  UPDATE td  
  SET SubSystemId = tec.ERC_Id  
  FROM dbo.#Delays td with (nolock)  
  JOIN @TECategories tec   
  ON td.TEDetId = tec.TEDet_Id  
  JOIN dbo.Event_Reason_Catagories erc with (nolock)  
  ON tec.ERC_Id = erc.ERC_Id  
  AND erc.ERC_Desc LIKE @SubSystemStr + '%'  
*/  
  
  UPDATE td SET  
   GroupCauseId = erc.ERC_Id  
  FROM dbo.#Delays td with (nolock)  
  JOIN dbo.event_reason_category_data ercd WITH (NOLOCK)   
  ON TD.ERTD_ID = ercd.event_reason_tree_data_id   
  JOIN dbo.event_reason_catagories erc WITH (NOLOCK)   
  ON ercd.erc_id = erc.erc_id   
  where erc.ERC_Desc LIKE @GroupCauseStr + '%'  
  
  UPDATE td SET  
   SubSystemId = erc.ERC_Id  
  FROM dbo.#Delays td with (nolock)  
  JOIN dbo.event_reason_category_data ercd WITH (NOLOCK)   
  ON TD.ERTD_ID = ercd.event_reason_tree_data_id   
  JOIN dbo.event_reason_catagories erc WITH (NOLOCK)   
  ON ercd.erc_id = erc.erc_id   
  where erc.ERC_Desc LIKE @SubSystemStr + '%'  
  
 END  
  
--print 'Section 31 Calc Stats: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
-------------------------------------------------------------------------  
-- Section 31: Calculate the Statistics for stops information in the #Delays dataset   
-------------------------------------------------------------------------  
  
UPDATE td SET   
 Stops =     
  CASE   
  WHEN tpu.DelayType <> @DelayTypeRateLossStr  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
/*  
 StopsUnscheduled =  
  CASE   
--  WHEN tpu.pudesc not like '%rate%loss%'  
--  and  tpu.pudesc not like '%converter reliability%'  
--  and  tpu.pudesc not like '%Converter Blocked/Starved'  
--  AND coalesce(td.ScheduleId,@SchedUnscheduledID) = @SchedUnscheduledId  
--  AND (td.StartTime >= @StartTime)  
--  THEN 1  
  WHEN (tpu.pudesc like '%reliability%' or tpu.pudesc like '%Converter Blocked/Starved')  
  AND coalesce(td.ScheduleId,@SchedUnscheduledID) in (@SchedUnscheduledId,@SchedBlockedStarvedId)   
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
 StopsMinor =    
  CASE   
--  WHEN td.DownTime < 600  
--  and tpu.pudesc not like '%rate%loss%'  
--  and  tpu.pudesc not like '%converter reliability%'  
--  and  tpu.pudesc not like '%Converter Blocked/Starved'  
--  AND coalesce(td.ScheduleId,@SchedUnscheduledID) = @SchedUnscheduledId  
--  AND (td.StartTime >= @StartTime)  
--  THEN 1  
  WHEN td.DownTime < 600  
  and (tpu.pudesc like '%reliability%' or tpu.pudesc like '%Converter Blocked/Starved')  
  AND coalesce(td.ScheduleId,@SchedUnscheduledID) in (@SchedUnscheduledId,@SchedBlockedStarvedId)   
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
*/  
 StopsUnscheduled = -- Rev2.50  
  CASE   
  WHEN (tpu.pudesc like '%reliability%' and tpu.pudesc not like '%converter reliability%')  
  AND coalesce(td.ScheduleId,@SchedUnscheduledID) in (@SchedUnscheduledId)   
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  WHEN (tpu.pudesc like '%converter reliability%' or tpu.pudesc like '%Converter Blocked/Starved')  
  AND coalesce(td.ScheduleId,@SchedUnscheduledID) in (@SchedUnscheduledId,@SchedBlockedStarvedId)   
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
 StopsMinor =    
  CASE   
  WHEN td.DownTime < 600  
  and (tpu.pudesc like '%reliability%' and tpu.pudesc not like '%converter reliability%')  
  AND coalesce(td.ScheduleId,@SchedUnscheduledID) in (@SchedUnscheduledId)   
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  WHEN td.DownTime < 600  
  and (tpu.pudesc like '%converter reliability%' or tpu.pudesc like '%Converter Blocked/Starved')  
  AND coalesce(td.ScheduleId,@SchedUnscheduledID) in (@SchedUnscheduledId,@SchedBlockedStarvedId)   
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
 StopsEquipFails =   --FLD 01-NOV-2007 Rev11.53  
/*  
  CASE   
--  WHEN td.DownTime >= 600  
--  and tpu.pudesc not like '%rate%loss%'  
--  and  tpu.pudesc not like '%converter reliability%'  
--  and  tpu.pudesc not like '%Converter Blocked/Starved'  
--  AND coalesce(td.ScheduleId,@SchedUnscheduledID) = @SchedUnscheduledId  
--  AND td.CategoryId IN (@CatMechEquipId, @CatElectEquipId)  
--  AND (td.StartTime >= @StartTime)  
--  THEN 1  
  WHEN td.DownTime >= 600  
  and (tpu.pudesc like '%reliability%' or tpu.pudesc like '%Converter Blocked/Starved')  
  AND coalesce(td.ScheduleId,@SchedUnscheduledID) in (@SchedUnscheduledId,@SchedBlockedStarvedId)   
  AND td.CategoryId IN (@CatMechEquipId, @CatElectEquipId)  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
*/  
  CASE   
  WHEN td.DownTime >= 600  
  and (tpu.pudesc like '%reliability%' and tpu.pudesc not like '%converter reliability%')  
  AND coalesce(td.ScheduleId,@SchedUnscheduledID) in (@SchedUnscheduledId)   
  AND td.CategoryId IN (@CatMechEquipId, @CatElectEquipId)  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  WHEN td.DownTime >= 600  
  and (tpu.pudesc like '%converter reliability%' or tpu.pudesc like '%Converter Blocked/Starved')  
  AND coalesce(td.ScheduleId,@SchedUnscheduledID) in (@SchedUnscheduledId,@SchedBlockedStarvedId)   
  AND td.CategoryId IN (@CatMechEquipId, @CatElectEquipId)  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
  
 StopsELP =    
  CASE   
  WHEN tpu.DelayType <> @DelayTypeRateLossStr  
  AND (td.CategoryId = @CatELPId)  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
 StopsBlockedStarved =   
  CASE   
  --WHEN td.CategoryId = @CatBlockStarvedId     
  WHEN td.ScheduleId = @SchedBlockedStarvedId  --FLD 01-NOV-2007 Rev11.53  
  AND tpu.DelayType <> @DelayTypeRateLossStr  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
 UpTime2m =    
  CASE   
  WHEN td.UpTime < 120  
  AND tpu.DelayType <> @DelayTypeRateLossStr  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
 StopsProcessFailures =   
/*  
  CASE   
--  WHEN td.DownTime >= 600  
--  and tpu.pudesc not like '%rate%loss%'  
--  and  tpu.pudesc not like '%converter reliability%'  
--  and  tpu.pudesc not like '%Converter Blocked/Starved'  
--  AND coalesce(td.ScheduleId,@SchedUnscheduledID) = @SchedUnscheduledId  
--  AND (td.CategoryId NOT IN (@CatMechEquipId, @CatElectEquipId)   
--   OR coalesce(td.CategoryId,0)=0)  
--  AND (td.StartTime >= @StartTime)  
--  THEN 1  
  WHEN td.DownTime >= 600  
  and (tpu.pudesc like '%reliability%' or tpu.pudesc like '%Converter Blocked/Starved')  
  AND coalesce(td.ScheduleId,@SchedUnscheduledID) in (@SchedUnscheduledId,@SchedBlockedStarvedId)   
  AND (td.CategoryId NOT IN (@CatMechEquipId, @CatElectEquipId)   
   OR coalesce(td.CategoryId,0)=0)  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END  
*/  
  CASE   
  WHEN td.DownTime >= 600  
  and (tpu.pudesc like '%reliability%' and tpu.pudesc not like '%converter reliability%')  
  AND coalesce(td.ScheduleId,@SchedUnscheduledID) in (@SchedUnscheduledId)   
  AND (td.CategoryId NOT IN (@CatMechEquipId, @CatElectEquipId)   
   OR coalesce(td.CategoryId,0)=0)  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  WHEN td.DownTime >= 600  
  and (tpu.pudesc like '%converter reliability%' or tpu.pudesc like '%Converter Blocked/Starved')  
  AND coalesce(td.ScheduleId,@SchedUnscheduledID) in (@SchedUnscheduledId,@SchedBlockedStarvedId)   
  AND (td.CategoryId NOT IN (@CatMechEquipId, @CatElectEquipId)   
   OR coalesce(td.CategoryId,0)=0)  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END  
  
FROM dbo.#Delays td with (nolock)  
JOIN @ProdUnits tpu   
ON  td.PUId = tpu.PUId  
WHERE  td.TEDetId = td.PrimaryId  
  
  
--print 'Section 35 @ProdRecords: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
----------------------------------------------------------  
-- Section 35: Populate @ProdRecords  
----------------------------------------------------------  
-------------------------------------------------------------------------------  
-- Get cvtg production factor specifications   
-- Again, the @ActiveSpecs table comes in handy...  
-- Saving lots of overhead.  
-------------------------------------------------------------------------------  
  
SELECT @PacksInBundleSpecId = Spec_Id  
FROM @ActiveSpecs  
WHERE Prop_Id = @PropCvtgProdFactorId  
 AND Spec_Desc =  @PacksInBundleSpecDesc  
option (keep plan)  
  
SELECT @SheetCountSpecId = Spec_Id  
FROM @ActiveSpecs  
WHERE Prop_Id = @PropCvtgProdFactorId  
 AND Spec_Desc =  @SheetCountSpecDesc  
option (keep plan)  
  
SELECT @CartonsInCaseSpecId = Spec_Id  
FROM @ActiveSpecs  
WHERE Prop_Id = @PropCvtgProdFactorId  
 AND Spec_Desc =  @CartonsInCaseSpecDesc  
option (keep plan)  
  
SELECT @ShipUnitSpecId = Spec_Id  
FROM @ActiveSpecs  
WHERE Prop_Id = @PropCvtgProdFactorId  
 AND Spec_Desc =  @ShipUnitSpecDesc  
option (keep plan)  
  
SELECT @StatFactorSpecId = Spec_Id  
FROM @ActiveSpecs  
WHERE Prop_Id = @PropCvtgProdFactorId  
 AND Spec_Desc = @StatFactorSpecDesc  
option (keep plan)  
  
SELECT @RollsInPackSpecId = Spec_Id  
FROM @ActiveSpecs  
WHERE Prop_Id = @PropCvtgProdFactorId  
 AND Spec_Desc = @RollsInPackSpecDesc  
option (keep plan)  
  
SELECT @SheetWidthSpecId = Spec_Id  
FROM @ActiveSpecs  
WHERE Prop_Id = @PropCvtgProdFactorId  
 AND Spec_Desc = @SheetWidthSpecDesc  
option (keep plan)  
  
SELECT @SheetLengthSpecId = Spec_Id  
FROM @ActiveSpecs  
WHERE Prop_Id = @PropCvtgProdFactorId  
 AND Spec_Desc = @SheetLengthSpecDesc  
option (keep plan)  
  
  
--print 'Section 33 #PRsRun: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
---------------------------------------------------------------------------------  
-- Section 33: Populate #PRsRun and update #Delays accordingly  
---------------------------------------------------------------------------------  
--  #PRsRun is used to track the Parent Rolls that ran during a report period.  
  
--------------------------------------------------------------------------------------------  
--- Insert Start_Times, UWS and PRIDs INTO temporary table.  
--------------------------------------------------------------------------------------------  
  
IF @IncludeStops = 1  
  
 begin  
  
--print 'PRID' + ' ' + convert(varchar(25),current_timestamp,108)  
  
 --------------------------------------------------------------------------------------------  
 --- Update the UWS Columns with the appropriate PRID results.  
 --------------------------------------------------------------------------------------------  
  
 UPDATE td SET   
  [UWS1Parent] = prs.ParentPRID,  
  [UWS1GrandParent] = prs.GrandParentPRID  
 FROM dbo.#prsrun prs with (nolock)   
 join @prodlines pl  
 on prs.puid = pl.prodpuid  
 join dbo.#delays td with (nolock)  
 on (pl.reliabilitypuid = td.puid or pl.ratelosspuid = td.puid)  
 and ((td.starttime >= prs.starttime and td.starttime < prs.endtime)   
  or (td.starttime < @starttime and td.endtime > @starttime))  
 AND prs.InputOrder = 1  
  
 UPDATE td SET   
  [UWS2Parent] = prs.ParentPRID,   
  [UWS2GrandParent] = prs.GrandParentPRID   
 FROM dbo.#prsrun prs with (nolock)   
 join @prodlines pl  
 on prs.puid = pl.prodpuid  
 join dbo.#delays td with (nolock)  
 on (pl.reliabilitypuid = td.puid or pl.ratelosspuid = td.puid)  
 and ((td.starttime >= prs.starttime and td.starttime < prs.endtime)   
  or (td.starttime < @starttime and td.endtime > @starttime))  
 AND prs.InputOrder = 2  
  
  
  
-- most of the UWS1 and UWS2 values in #Delays will be populated at this   
-- point, but some downtime events will start earlier than any of the parent rolls   
-- within the report window.  to handle these, we have the following code.  it may   
-- seem like a lot of work, but it shouldn't be too bad because it's only applied   
-- to a handful of records.  
  
--if (select count(*) from dbo.#Delays where UWS1Parent is null or UWS2Parent is null) > 0  
--begin   
  
----print 'ESTOutsideWindow ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
--/*  
insert @ESTOutsideWindow  
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
where est.event_id > 0   
and est.start_time < @starttime  
and est.end_time > @RangeStartTime  
and est.event_status = @RunningStatusID  
--*/  
  
--print '@DelaysOutsideWindow ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
  
insert @DelaysOutsideWindow  
 (  
 TEDetID,  
 PLID,  
 PUID,  
 ProdPUID,  
 StartTime  
 )  
select   
 td.TEDetID,  
 td.PLID,  
 td.PUID,  
 pl.ProdPUID,  
 td.StartTime  
from dbo.#delays td with (nolock)  
join @prodlines pl  
on (td.puid = pl.reliabilitypuid or td.puid = pl.ratelosspuid or td.puid = pl.CvtrBlockedStarvedPUID)  
--on td.plid = pl.plid  
where td.StartTime < @StartTime   
and (td.UWS1Parent is null or td.UWS2Parent is null)  
  
--print '@PRDTOutsideWindow 1 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
insert @PRDTOutsideWindow  
 (  
 TEDetID,  
 EventID,  
 SourceEventID,  
 PLID,  
 CvtgPUID,  
 ProdPUID,  
-- StartTime,  
 EventTimestamp  
 )  
select  
 td.TEDetID,  
 e.Event_ID,  
 e.Source_Event,  
 td.PLID,  
 td.PUID,  
 e.pu_id,  
-- td.StartTime,  
 e.[Timestamp]  
  
--FROM dbo.event_status_transitions est with (nolock)  
--join dbo.events e with (nolock)  
--on est.event_id = e.event_id  
--join dbo.#prodlines pl   
--on e.pu_id = pl.prodpuid  
--join @DelaysOutsideWindow td  
--on (pl.reliabilitypuid = td.puid or pl.ratelosspuid = td.puid)  
--and td.starttime >= est.start_time  
--and td.starttime < est.end_time  
--where est.event_status = @RunningStatusID  
  
FROM @ESTOutsideWindow est --with (nolock)  
join dbo.events e with (nolock)  
on est.event_id = e.event_id  
join @DelaysOutsideWindow td  
on td.prodpuid = e.pu_id  
and td.starttime >= est.start_time  
and td.starttime < est.end_time  
and est.event_status = @RunningStatusID  
  
  
--print '@PRDTOutsideWindow 2 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
update pdow set  
 [ParentPRID] = UPPER(RTRIM(LTRIM(tprid.result)))  
from @PRDTOutsideWindow pdow  
join @prodlines pl  
on pdow.plid = pl.plid  
JOIN dbo.Tests tprid with (nolock)  
on (tprid.Var_Id = pl.VarPRIDId and tprid.result_on = pdow.EventTimeStamp)  
or (tprid.var_id = pl.VarParentPRIDId and tprid.result_on = pdow.EventTimeStamp)  
  
--print '@PRDTOutsideWindow 3 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
update pdow set  
 PRPUID = e1.PU_ID,  
 SourceTimestamp = e1.[Timestamp]  
from @PRDTOutsideWindow pdow  
join dbo.Events e1  
on pdow.SourceEventID = e1.event_id  
  
/*  
--print '@PRDTOutsideWindow 4 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
UPDATE pdow SET   
 [ParentType] =   
  CASE   
  WHEN pdow.[PRPUID] = iu.puid   
  THEN 2  
      ELSE 1  
      END  
FROM @PRDTOutsideWindow pdow  
JOIN @IntUnits iu   
ON iu.puid = pdow.[PRPUID]  
*/  
  
/*  
--print '@PRDTOutsideWindow 5 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
update pdow set  
 [GrandparentPRID] = UPPER(RTRIM(LTRIM(tprid.result)))  
from @PRDTOutsideWindow pdow  
join dbo.#prodlines pl  
on pdow.plid = pl.plid  
JOIN dbo.Tests tprid with (nolock)  
on (tprid.Var_Id = pl.VarInputRollID and tprid.result_on = pdow.SourceTimeStamp)  
or (tprid.var_id = pl.VarInputPRIDID and tprid.result_on = pdow.SourceTimeStamp)  
--where pdow.[ParentType] = 2  
*/  
  
--print '@PRDTOutsideWindow 5 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
update pdow set  
 [GrandparentPRID] = UPPER(RTRIM(LTRIM(tprid.result)))  
from @PRDTOutsideWindow pdow  
join dbo.variables v  
on pdow.prpuid = v.pu_id  
JOIN dbo.Tests tprid with (nolock)  
on tprid.var_id = v.var_id and tprid.result_on = pdow.SourceTimeStamp  
where pdow.[ParentType] = 2  
and (v.var_id = dbo.fnLocal_GlblGetVarId(pdow.PRPUID, @VarInputRollVN)  
  or v.var_id = dbo.fnLocal_GlblGetVarId(pdow.PRPUID, @VarInputPRIDVN))  
  
  
UPDATE pdow SET   
 [GrandParentPRID] = t.result--,  
from @PRDTOutsideWindow pdow  
JOIN dbo.variables v with (nolock)   
on v.pu_id = pdow.[PRPUID]   
and v.var_desc_global = 'Input PRID'  
JOIN dbo.tests t with (nolock)   
ON t.var_id = v.var_id  
and t.result_on = pdow.SourceTimeStamp  
--where v.var_desc_global = 'Input PRID'  
where pdow.[ParentType] = 2  
  
  
UPDATE pdow SET   
 [GrandParentPRID] = t.result--,  
from @PRDTOutsideWindow pdow  
JOIN dbo.variables v with (nolock)   
on v.pu_id = pdow.[PRPUID]   
and v.var_desc_global = 'Input Roll ID'  
JOIN dbo.tests t with (nolock)   
ON t.var_id = v.var_id  
and t.result_on = pdow.SourceTimeStamp  
--where v.var_desc_global = 'Input Roll ID'  
where pdow.[ParentType] = 2  
and GrandParentPRID is null  
  
  
--print '@PRDTOutsideWindow 6 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
update pdow set  
 PMTeam = SUBSTRING(UPPER(RTRIM(LTRIM(coalesce(GrandParentPRID, ParentPRID, '')))), 3, 1)  
from @PRDTOutsideWindow pdow  
  
--print '@PRDTOutsideWindow 7 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
update pdow set  
 [UWS] = tuws.result  
from @PRDTOutsideWindow pdow  
join @prodlines pl  
on pdow.plid = pl.plid  
JOIN dbo.Tests tuws with (nolock)  
on tuws.Var_Id = pl.VarUnwindStandID   
and tuws.result_on = pdow.EventTimeStamp  
  
--print '@PRDTOutsideWindow 8 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
update pdow set  
 [Input_Order] = pei.input_order  
from @PRDTOutsideWindow pdow  
join @prodlines pl  
on pdow.plid = pl.plid  
JOIN dbo.PrdExec_Inputs pei WITH (NOLOCK)   
ON pei.pu_id = pdow.prodpuid   
AND pei.input_name = pdow.uws  
  
--print '@PRDTOutsideWindow 9 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
update pdow set  
 [INTR] = pu.pl_id  
from @PRDTOutsideWindow pdow  
join dbo.Events e1  
on pdow.SourceEventID = e1.event_id  
join dbo.prod_units pu  
on pu.pu_id = e1.pu_id  
where   
 (  
 select count(*)   
 from dbo.prod_units pu1  
 where pu1.pl_id = pu.pl_id  
 and pu1.pu_desc like '%INTR%'  
 ) > 0  
  
  
--print '@PRDTOutsideWindow 10 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
UPDATE td SET   
 [UWS1Parent]   = pdow.ParentPRID,    
-- [UWS1ParentPM]   = RTRIM(LTRIM(COALESCE(LEFT(pdow.ParentPRID, 2), 'NoAssignedPRID'))),  
 [UWS1GrandParent]  = pdow.GrandParentPRID--,  
-- [UWS1GrandParentPM] = LEFT(pdow.GrandparentPRID, 2),  
-- [UWS1PMTeam]   = pdow.PMTeam,  
-- [INTR]     = pdow.INTR      
from @PRDTOutsideWindow pdow  
join dbo.#delays td with (nolock)  
on td.tedetid = pdow.tedetid  
where pdow.input_order = 1  
  
--print '@PRDTOutsideWindow 11 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
UPDATE td SET   
 [UWS2Parent]   = pdow.ParentPRID,    
-- [UWS2ParentPM]   = RTRIM(LTRIM(COALESCE(LEFT(pdow.ParentPRID, 2), 'NoAssignedPRID'))),  
 [UWS2GrandParent]  = pdow.GrandParentPRID--,  
-- [UWS2GrandParentPM] = LEFT(pdow.GrandparentPRID, 2),  
-- [UWS2PMTeam]   = pdow.PMTeam,  
-- [INTR]     = pdow.INTR      
from @PRDTOutsideWindow pdow  
join dbo.#delays td with (nolock)  
on td.tedetid = pdow.tedetid  
where pdow.input_order = 2  
  
  
 UPDATE td SET   
  [UWS1Parent] = 'NoAssignedPRID'  
 FROM dbo.#Delays td with (nolock)  
 WHERE UWS1Parent IS NULL  
  
--end  
  
  
-- This update to #Tests replaces a lot of the initial work that used to be done in the old   
-- ProdRecordsShift cursor.  The rest of that work will be done in the insert and updates   
-- to @ProdRecords.  Note that there are FOUR joins to the @ActiveSpecs table.  
-- This is another case of an intermediary table saving us overhead compared to multiple   
-- hits to the database.  However, in this case, there is even more benefit in this regard,  
-- because the table compiles related data from multiple source tables.  
  
IF @BusinessType = 4  
 BEGIN  
  
  UPDATE t set  
   t.SheetValue =   
    case lpv.vartype  
    when @ACPUnitsFlag  
    then  convert(float,t.Value)  
      * CONVERT(FLOAT, asp1.Target)  
      * CONVERT(FLOAT, asp2.Target)  
      * CONVERT(FLOAT, asp4.Target)  
    when @HPUnitsFlag  
    then convert(float,t.Value)  
      * CONVERT(FLOAT, asp1.Target)  
      * CONVERT(FLOAT, asp2.Target)  
      * CONVERT(FLOAT, asp3.Target)  
      * CONVERT(FLOAT, asp4.Target)  
    when @TPUnitsFlag  
    then convert(float,t.Value)  
      * CONVERT(FLOAT, asp1.Target)  
      * CONVERT(FLOAT, asp2.Target)  
    else null  
    end  
  FROM dbo.#Tests t with (nolock)  
  JOIN @LineProdVars lpv   
  ON t.VarId = lpv.VarId  
  LEFT JOIN @ActiveSpecs asp1   
  on asp1.Prop_Id = @PropCvtgProdFactorId  
  AND asp1.Char_Desc = t.ProdCode  
  AND asp1.Spec_Id = @PacksInBundleSpecId  
  AND asp1.Effective_Date < t.SampleTime  
  AND (asp1.Expiration_Date >= t.SampleTime   
   or asp1.expiration_date is null)  
  LEFT JOIN @ActiveSpecs asp2  
  on asp2.Effective_Date < t.SampleTime  
  AND (asp2.Expiration_Date >= t.SampleTime   
   or asp2.Expiration_Date is null)  
  and asp2.Char_Id = asp1.Char_Id  
  AND asp2.Spec_Id = @SheetCountSpecId  
  LEFT JOIN @ActiveSpecs asp3  
  on asp3.Effective_Date < t.SampleTime  
  AND (asp3.Expiration_Date >= t.SampleTime  
   or asp3.Expiration_Date is null)  
  and asp3.Char_Id = asp1.Char_Id  
  AND asp3.Spec_Id = @ShipUnitSpecId  
  LEFT JOIN @ActiveSpecs asp4   
  on asp4.Effective_Date < t.SampleTime  
  AND (asp4.Expiration_Date >= t.SampleTime  
   or asp4.Expiration_Date is null)  
  and asp4.Char_Id = asp1.Char_Id  
  AND asp4.Spec_Id = @CartonsInCaseSpecId  
  
  
 END  
  
 end  -- end if  
  
  
--print 'Section 34 Rateloss: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
----------------------------------------------------------------------------------  
-- Section 34: Update the Rateloss information for #Delays  
----------------------------------------------------------------------------------  
  
/*-------------------------------------------------------------------------------  
Update the RateLoss SplitDowntime to be equal to the Effective Downtime  
FROM the #Tests table.    
Note: Effective Downtime is already in minutes!  
Set SplitDowntime and SplitUptime = 0 so that they will not be  
included in Total Report Time.  
RateLossRatio is the ratio of EffectiveDowntime / Downtime.  This will later be   
applied to the split events to get the split rateloss.  
-------------------------------------------------------------------------------*/  
UPDATE td SET    
 LineActualSpeed  = t2.Value,  
 SplitDowntime    = 0,  
 StopsRateLoss   = 1,  
 uptime    = null,  
 downtime    = null,  
 UWS1Parent  = (  
       SELECT result  
       FROM dbo.Tests t   
       WHERE Var_Id = pu.PRIDRLVarId   
       AND td.StartTime = t.result_on  
       ),   
 RateLossRatio  = (CONVERT(FLOAT,t1.Value) * 60.0) / Downtime,  
--Rev11.55  
 RawRateloss  = (CONVERT(FLOAT,t1.Value) * 60.0)   
FROM dbo.#Delays td with (nolock)  
JOIN @ProdUnits pu   
ON td.PUID = pu.PUID  
JOIN @ProdLines pl --with (nolock) -- Rev11.33  
ON pu.PLID = pl.PLID  
LEFT JOIN dbo.#Tests t1 with (nolock)  
ON (td.StartTime = t1.SampleTime)   
AND (pl.VarEffDowntimeId = t1.VarId)  
LEFT JOIN dbo.#Tests t2 with (nolock)  
ON (td.StartTime = t2.SampleTime)  
AND (pl.VarActualLineSpeedId = t2.VarId)  
WHERE pu.DelayType = @DelayTypeRateLossStr  
AND Downtime <> 0  
  
  
--print 'Insert Prod Records ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-- this table compiles production values so that they can be grouped   
-- as needed in the result sets later.  
  
INSERT @ProdRecords   
 (  
 PLId,   
 puid,  
 ReliabilityPUID,  
 Shift,  
 Team,  
 ProdId,  
 StartTime,   
 EndTime,   
 LineSpeedTarget,  
 LineSpeedIdeal,  
 CalendarRuntime,  
 StatFactor,  
 RollsInPack,  
 PacksInBundle,  
 SheetCount,  
 ShipUnit,  
 SheetWidth,  
 SheetLength,  
 CartonsInCase,  
 LineStatus  
 )  
SELECT distinct   
 pl.PLId,  
 puid,  
 ReliabilityPUID,  
 Shift,  
 Team,  
 ProdId,  
 rs.StartTime,  
 rs.EndTime,  
 TargetSpeed,  
 IdealSpeed,  
   
 CONVERT(FLOAT,DATEDIFF(ss,rs.StartTime, rs.EndTime)) / 60.0,  
  
 --StatFactor =  
 (  
 SELECT TOP 1 CONVERT(FLOAT, Target)  
 FROM @ActiveSpecs asp1  
 where asp1.prod_id = rs.prodid  
 AND Effective_Date <= rs.startTime  
 and asp1.Spec_Id = @StatFactorSpecId  
 AND asp1.Prop_Id = @PropCvtgProdFactorId  
 ORDER BY Effective_Date DESC  
 ),  
  
 --RollsInPack =  
 (  
 SELECT TOP 1 CONVERT(FLOAT, Target)  
 FROM @ActiveSpecs asp2  
 where asp2.prod_id = rs.prodid  
 AND Effective_Date <= rs.StartTime  
 and asp2.Spec_Id = @RollsInPackSpecId  
 ORDER BY Effective_Date DESC  
 ),  
  
 --PacksInBundle =  
 (  
 SELECT TOP 1 CONVERT(FLOAT,Target)  
 FROM @ActiveSpecs asp3  
 where asp3.prod_id = rs.prodid  
 AND Effective_Date <= rs.StartTime  
 and Spec_Id = @PacksInBundleSpecId  
 ORDER BY Effective_Date DESC  
 ),  
  
 --SheetCount =  
 (   
 SELECT TOP 1 CONVERT(FLOAT, Target)  
 FROM @ActiveSpecs asp4  
 where asp4.prod_id = rs.prodid  
 AND Effective_Date <= rs.StartTime  
 and asp4.Spec_Id = @SheetCountSpecId  
 ORDER BY Effective_Date DESC  
 ),  
  
 --ShipUnit =  
 (  
 SELECT TOP 1 CONVERT(FLOAT, Target)  
 FROM @ActiveSpecs asp5  
 where asp5.prod_id = rs.prodid  
 AND Effective_Date <= rs.StartTime  
 and asp5.Spec_Id = @ShipUnitSpecId  
 ORDER BY Effective_Date DESC  
 ),  
  
 --SheetWidth =  
 (  
 SELECT TOP 1 CONVERT(FLOAT, Target)  
 FROM @ActiveSpecs asp6  
 where asp6.prod_id = rs.prodid  
 AND Effective_Date <= rs.StartTime  
 and asp6.Spec_Id = @SheetWidthSpecId  
 ORDER BY Effective_Date DESC  
 ),  
  
 --SheetLength =  
 (  
 SELECT TOP 1 CONVERT(FLOAT, Target)  
 FROM @ActiveSpecs asp7  
 where asp7.prod_id = rs.prodid  
 AND Effective_Date <= rs.StartTime  
 and asp7.Spec_Id = @SheetLengthSpecId  
 ORDER BY Effective_Date DESC  
 ),  
  
 --CartonsInCase =  
 (  
 SELECT TOP 1 CONVERT(FLOAT, Target)  
 FROM @ActiveSpecs asp8  
 where asp8.prod_id = rs.prodid  
 AND Effective_Date <= rs.StartTime  
 and asp8.Spec_Id = @CartonsInCaseSpecId  
 ORDER BY Effective_Date DESC  
 ),  
  
 LineStatus  
  
FROM @ProdLines pl --with (nolock) -- Rev11.33   
JOIN @RunSummary rs  
ON rs.PLId = pl.PLId  
and pl.PackOrLine <> 'Pack'  
where puid = reliabilitypuid  
option (keep plan)  
  
  
--print 'Update Prod Records ' + CONVERT(VARCHAR(20), GetDate(), 120)-- the following series of updates replaces a lot of work that used to be done  
-- in the ProdRecordsShift cursor.  NOTE that there are sequential updates   
-- because in many cases, base values must be calculated before others can   
-- be done.  
  
update prs set  
  
 HolidayCurtailDT =  
  (  
  select COALESCE(SUM(  
   case  
   when td1.ScheduleId = @SchedHolidayCurtailId   
   then CONVERT(FLOAT,DATEDIFF(ss,   
    (  
    CASE   
    WHEN td1.StartTime <= rs1.StartTime   
    THEN rs1.StartTime   
    ELSE td1.StartTime END  
    ),   
    (  
    CASE   
    WHEN td1.EndTime >= rs1.EndTime   
    THEN rs1.EndTime   
    ELSE td1.EndTime   
    END  
    ))) / 60.0  
   else 0.0  
   end  
  ), 0.0)  
  from @RunSummary rs1  
  left join dbo.#Delays td1 with (nolock)  
  on  td1.PUId = prs.ReliabilityPUId   
  and td1.starttime < rs1.endtime  
  and td1.endtime > rs1.starttime   
  where rs1.PuId = prs.PuId  
  and (rs1.team = prs.team) --or (rs.team is null and prs.team is null))  
  and (rs1.shift = prs.shift) --or (rs.shift is null and prs.shift is null))  
  and rs1.prodid = prs.prodid  
  and rs1.starttime = prs.starttime  
  and rs1.endtime = prs.endtime  
  ),  
  
 PlninterventionDT =  
  (  
  select COALESCE(SUM(  
   case  
   when td2.ScheduleId = @SchedPlninterventionId  
   then CONVERT(FLOAT,DATEDIFF(ss,   
    (  
    CASE   
    WHEN td2.StartTime <= rs2.StartTime   
    THEN rs2.StartTime   
    ELSE td2.StartTime   
    END  
    ),   
    (  
    CASE   
    WHEN td2.EndTime >= rs2.EndTime   
    THEN rs2.EndTime   
    ELSE td2.EndTime   
    END  
    ))) / 60.0  
   else 0.0  
   end  
  ), 0.0)  
  from @RunSummary rs2  
  left join dbo.#Delays td2 with (nolock)  
  on  td2.PUId = prs.ReliabilityPUId   
  and td2.starttime < rs2.endtime  
  and td2.endtime > rs2.starttime   
  where rs2.PuId = prs.PuId  
  and rs2.team = prs.team  
  and rs2.shift = prs.shift  
  and rs2.prodid = prs.prodid  
  and rs2.starttime = prs.starttime  
  and rs2.endtime = prs.endtime  
  ),  
  
  
 ChangeOverDT =  
  (  
  select COALESCE(SUM(  
   case  
   when td3.ScheduleId = @SchedChangeOverId  
   then CONVERT(FLOAT,DATEDIFF(ss,   
    (  
    CASE   
    WHEN td3.StartTime <= rs3.StartTime   
    THEN rs3.StartTime   
    ELSE td3.StartTime   
    END  
    ),   
    (  
    CASE   
    WHEN td3.EndTime >= rs3.EndTime   
    THEN rs3.EndTime   
    ELSE td3.EndTime   
    END  
    ))) / 60.0  
   else 0.0  
   end  
  ), 0.0)  
  from @RunSummary rs3  
  left join dbo.#Delays td3 with (nolock)  
  on  td3.PUId = prs.ReliabilityPUId   
  and td3.starttime < rs3.endtime  
  and td3.endtime > rs3.starttime   
  where rs3.PuId = prs.PuId  
  and rs3.team = prs.team  
  and rs3.shift = prs.shift  
  and rs3.prodid = prs.prodid  
  and rs3.starttime = prs.starttime  
  and rs3.endtime = prs.endtime  
  ),  
  
 HygCleaningDT =  
  (  
  select COALESCE(SUM(  
   case  
   when td4.ScheduleId = @SchedHygCleaningId   
   then CONVERT(FLOAT,DATEDIFF(ss,   
    (  
    CASE   
    WHEN td4.StartTime <= rs4.StartTime   
    THEN rs4.StartTime   
    ELSE td4.StartTime   
    END  
    ),   
    (  
    CASE   
    WHEN td4.EndTime >= rs4.EndTime   
    THEN rs4.EndTime   
    ELSE td4.EndTime   
    END  
    ))) / 60.0  
   else 0.0  
   end  
  ), 0.0)  
  from @RunSummary rs4  
  left join dbo.#Delays td4 with (nolock)  
  on  td4.PUId = prs.ReliabilityPUId   
  and td4.starttime < rs4.endtime  
  and td4.endtime > rs4.starttime   
  where rs4.PuId = prs.PuId  
  and rs4.team = prs.team  
  and rs4.shift = prs.shift  
  and rs4.prodid = prs.prodid  
  and rs4.starttime = prs.starttime  
  and rs4.endtime = prs.endtime  
  ),  
  
 EOProjectsDT =  
  (  
  select COALESCE(SUM(  
   case  
   when td5.ScheduleId = @SchedEOProjectsId   
   then CONVERT(FLOAT,DATEDIFF(ss,   
    (  
    CASE   
    WHEN td5.StartTime <= rs5.StartTime   
    THEN rs5.StartTime   
    ELSE td5.StartTime   
    END  
    ),   
    (  
    CASE   
    WHEN td5.EndTime >= rs5.EndTime   
    THEN rs5.EndTime   
    ELSE td5.EndTime   
    END  
    ))) / 60.0  
   else 0.0  
   end  
  ), 0.0)  
  from @RunSummary rs5  
  left join dbo.#Delays td5 with (nolock)  
  on  td5.PUId = prs.ReliabilityPUId   
  and td5.starttime < rs5.endtime  
  and td5.endtime > rs5.starttime   
  where rs5.PuId = prs.PuId  
  and rs5.team = prs.team  
  and rs5.shift = prs.shift  
  and rs5.prodid = prs.prodid  
  and rs5.starttime = prs.starttime  
  and rs5.endtime = prs.endtime  
  ),  
  
 UnscheduledDT =  
  (  
  select COALESCE(SUM(  
   case  
   --when td.ScheduleId = @SchedUnscheduledId   
   when td6.StopsUnscheduled = 1  --FLD 01-NOV-2007 Rev11.53  ---SHPULD BE OK...VERIFY   
   then CONVERT(FLOAT,DATEDIFF(ss,   
    (  
    CASE   
    WHEN td6.StartTime <= rs6.StartTime   
    THEN rs6.StartTime   
    ELSE td6.StartTime   
    END  
    ),   
    (  
    CASE   
    WHEN td6.EndTime >= rs6.EndTime   
    THEN rs6.EndTime   
    ELSE td6.EndTime   
    END  
    ))) / 60.0  
   else 0.0  
   end  
  ), 0.0)  
  from @RunSummary rs6  
  left join dbo.#Delays td6 with (nolock)  
  on  td6.PUId = prs.ReliabilityPUId   
  and td6.starttime < rs6.endtime  
  and td6.endtime > rs6.starttime   
  where rs6.PuId = prs.PuId  
  and rs6.team = prs.team  
  and rs6.shift = prs.shift  
  and rs6.prodid = prs.prodid  
  and rs6.starttime = prs.starttime  
  and rs6.endtime = prs.endtime  
  ),  
  
 CLAuditsDT =  
  (  
  select COALESCE(SUM(  
   case  
   when td7.ScheduleId = @SchedCLAuditsId   
   then CONVERT(FLOAT,DATEDIFF(ss,   
    (  
    CASE   
    WHEN td7.StartTime <= rs7.StartTime   
    THEN rs7.StartTime   
    ELSE td7.StartTime   
    END  
    ),   
    (  
    CASE WHEN td7.EndTime >= rs7.EndTime   
    THEN rs7.EndTime   
    ELSE td7.EndTime   
    END  
    ))) / 60.0  
   else 0.0  
   end  
         ), 0.0)  
  from @RunSummary rs7  
  left join dbo.#Delays td7 with (nolock)  
  on  td7.PUId = prs.ReliabilityPUId   
  and td7.starttime < rs7.endtime  
  and td7.endtime > rs7.starttime   
  where rs7.PuId = prs.PuId  
  and rs7.team = prs.team  
  and rs7.shift = prs.shift  
  and rs7.prodid = prs.prodid  
  and rs7.starttime = prs.starttime  
  and rs7.endtime = prs.endtime  
  ),  
  
  
 OperationsRuntime =  
  CalendarRuntime -   
  (  
  select COALESCE(SUM(  
   case  
   --when td.ScheduleId NOT IN (@SchedPRPolyId, @SchedUnscheduledId)  
   when coalesce(td8.ScheduleId,0) NOT IN (@SchedPRPolyId, @SchedUnscheduledId, @SchedBlockedStarvedId, 0)  --FLD 01-NOV-2007 Rev11.53  
   --AND coalesce(td.ScheduleId,0)>0  
   then CONVERT(FLOAT,DATEDIFF(ss,   
    (  
    CASE   
    WHEN td8.StartTime <= rs8.StartTime   
    THEN rs8.StartTime   
    ELSE td8.StartTime   
    END  
    ),   
    (  
    CASE   
    WHEN td8.EndTime >= rs8.EndTime   
    THEN rs8.EndTime   
    ELSE td8.EndTime   
    END  
    ))) / 60.0  
   else 0.0  
   end  
  ), 0.0)  
  from  @RunSummary rs8  
  left join dbo.#Delays td8 with (nolock)  
  on  td8.PUId = prs.ReliabilityPUId   
  and td8.starttime < rs8.endtime  
  and td8.endtime > rs8.starttime   
  where rs8.PuId = prs.PuId  
  and rs8.team = prs.team  
  and rs8.shift = prs.shift  
  and rs8.prodid = prs.prodid  
  and rs8.starttime = prs.starttime  
  and rs8.endtime = prs.endtime  
  ),  
  
  
 TotalUnits =  
  CASE   
  WHEN @BusinessType in (1,2,4)  
  THEN  (  
   SELECT sum(convert(float,t9a.value))   
   FROM dbo.#Tests t9a with (nolock)  
   JOIN @ProdLines pl9a --with (nolock) -- Rev11.33  
   ON VarId = VarTotalUnitsId  
   and t9a.SampleTime > prs.StartTime   
   AND t9a.SampleTime <= prs.EndTime  
   and t9a.PLId = pl9a.PLId  
   and t9a.plid = prs.plid  
   )  
  WHEN @BusinessType = 3  
  THEN (  
   SELECT sum(convert(float,t9b.value))   
   FROM dbo.#Tests t9b with (nolock)  
   JOIN @LineProdVars lpv9b   
   ON t9b.VarId = lpv9b.VarId  
   AND t9b.SampleTime > prs.StartTime   
   AND t9b.SampleTime <= prs.EndTime  
   AND lpv9b.PLId = t9b.PLId  
   and t9b.plid = prs.plid  
   )  
  ELSE  NULL  
    END,  
  
  
 GoodUnits =   
  
  CASE    
  
  WHEN @BusinessType in (1,2)  
  THEN  (  
   SELECT sum(convert(float,t10a.value))   
   FROM dbo.#Tests t10a with (nolock)  
   JOIN @ProdLines pl10a --with (nolock)  
   ON t10a.VarId = pl10a.VarGoodUnitsId  
   AND t10a.SampleTime > prs.StartTime   
   AND t10a.SampleTime <= prs.EndTime  
   and t10a.PLId = pl10a.PLId  
   and t10a.plid = prs.plid  
   )  
  
      WHEN @BusinessType = 3   
  THEN  (  
   SELECT sum(convert(float,t10b.value))   
   FROM dbo.#Tests t10b with (nolock)  
   JOIN @LineProdVars lpv10b   
   ON t10b.VarId = lpv10b.VarID  
   AND t10b.SampleTime > prs.StartTime   
   AND t10b.SampleTime <= prs.EndTime  
   and t10b.PLId = lpv10b.PLId  
   and t10b.plid = prs.plid  
   )  
  
  WHEN @BusinessType = 4  
  THEN  (  
   SELECT   
    Sum(coalesce(convert(float,SheetValue), 0.0))  
   FROM dbo.#Tests t10c with (nolock)  
   JOIN @LineProdVars lpv10c   
   ON t10c.VarId = lpv10c.VarId  
   where t10c.SampleTime > prs.StartTime   
   AND t10c.SampleTime <= prs.EndTime  
   and t10c.PLId = lpv10c.PLId  
   and t10c.plid = prs.plid  
   )  
  
  ELSE  NULL  
  
  END,  
  
 RollWidth2Stage =  
  
  (  
  SELECT  avg(  
   case  
   when t11.VarId = pl11.VarPMRollWidthId    
   AND convert(float,t11.Value,0) < (@DefaultPMRollWidth*1.1)  
   then convert(float,t11.value)  
   else null  -- avg() should throw out any nulls from the count  
   end  
   )  
  FROM dbo.#Tests t11 with (nolock)  
  JOIN @ProdLines pl11 --with (nolock) -- Rev11.33   
  on t11.SampleTime > prs.StartTime   
  AND t11.SampleTime <= prs.EndTime  
  and t11.plid = prs.plid  
  and t11.Plid = pl11.PlId  
  ),  
  
 RollWidth3Stage =  
  
  (    SELECT  avg(  
   case  
   when t12.VarId = pl12.VarParentRollWidthId   
   AND convert(float,t12.Value) < (@DefaultPMRollWidth*1.1)  
   then convert(float,t12.value)  
   else null  -- avg() should throw out any nulls from the count  
   end  
   )  
  FROM dbo.#Tests t12 with (nolock)  
  JOIN @ProdLines pl12 --with (nolock) -- Rev11.33   
  on t12.SampleTime > prs.StartTime   
  AND t12.SampleTime <= prs.EndTime  
  and t12.plid = prs.plid  
  and t12.PlId = pl12.PlId  
  )--,  
FROM @ProdRecords prs  
  
  
update prs set  
  
 ProductionRuntime = CalendarRuntime - HolidayCurtailDT,  
 RejectUnits = TotalUnits - GoodUnits,  
  
 WebWidth =    
  CASE    
  WHEN  (   
   COALESCE(RollWidth2Stage,0) +   
   COALESCE(RollWidth3Stage,0) +   
   @DefaultPMRollWidth  
   ) = @DefaultPMRollWidth   
  THEN @DefaultPMRollWidth   
  ELSE COALESCE(RollWidth2Stage,RollWidth3Stage)  
  END  
    
from @ProdRecords prs  
  
  
update prs set  
  
 PlanningRuntime = ProductionRuntime -   
  (  
  select COALESCE(SUM(  
   case  
   when Downtime >= 120.0   
   AND td1.ScheduleId IN (@SchedPlninterventionId, @SchedChangeOverId,   
     @SchedHygCleaningId, @SchedEOProjectsId)  
   then CONVERT(FLOAT,DATEDIFF(ss,   
    (  
    CASE   
    WHEN td1.StartTime <= rs1.StartTime   
    THEN rs1.StartTime   
    ELSE td1.StartTime   
    END  
    ),   
    (  
    CASE   
    WHEN td1.EndTime >= rs1.EndTime   
    THEN rs1.EndTime   
    ELSE td1.EndTime   
    END  
    ))) / 60.0  
   else 0.0  
   end  
  ), 0.0)  
  from @RunSummary rs1  
  join dbo.#Delays td1 with (nolock)  
  on  td1.PUId = prs.ReliabilityPUId   
  and td1.starttime < rs1.endtime  
  and td1.endtime > rs1.starttime   
  where rs1.PuId = prs.PuId  
  and rs1.team = prs.team  
  and rs1.shift = prs.shift  
  and rs1.prodid = prs.prodid  
  and rs1.starttime = prs.starttime  
  and rs1.endtime = prs.endtime  
  ),  
  
 RollsPerLog = FLOOR((WebWidth * @ConvertInchesToMM) / SheetWidth)  
  
from @ProdRecords prs  
  
  
update prs set  
 TargetUnits =   
  CASE @BusinessType  
      WHEN 3   
  THEN --Facial, Line Speed Target is Cartons/Min.  
--   round(LineSpeedTarget * (1/convert(float,RollsInPack)) * (1/convert(float,PacksInBundle)) *  
--   ProductionRuntime * StatFactor,0)  
   LineSpeedTarget * (1/convert(float,RollsInPack)) * (1/convert(float,PacksInBundle)) *  
   ProductionRuntime * StatFactor  
  WHEN 4   
  THEN --Hanky lines in Neuss  
--   round((LineSpeedTarget / StatFactor) * ProductionRuntime,0)   
   (LineSpeedTarget / StatFactor) * ProductionRuntime   
   --@StatFactor is really StatUnit in Neuss!!!  
       ELSE        --Tissue/Towel/Napkins  
--       round(LineSpeedTarget * @ConvertFtToMM * (1/convert(float,SheetCount)) *  
--       (1/convert(float,SheetLength)) * RollsPerLog *   
--       ProductionRuntime * (1/convert(float,RollsInPack)) * (1/convert(float,PacksInBundle)) *  
--       StatFactor,0)   
       LineSpeedTarget * @ConvertFtToMM * (1/convert(float,SheetCount)) *  
       (1/convert(float,SheetLength)) * RollsPerLog *   
       ProductionRuntime * (1/convert(float,RollsInPack)) * (1/convert(float,PacksInBundle)) *  
       StatFactor   
       END,  
  
 ActualUnits =   
  CASE @BusinessType  
  WHEN 1    
  THEN --Tissue/Towel  
--   round(GoodUnits * RollsPerLog * (1/convert(float,RollsInPack)) *  
--   (1/convert(float,PacksInBundle)) * StatFactor,0)  
   (GoodUnits * RollsPerLog * (1/convert(float,RollsInPack)) *  
   (1/convert(float,PacksInBundle)) * StatFactor)  
  WHEN 2   
  THEN --Napkins  GoodUnits = Stacks, no conversion needed.  
--   round(GoodUnits * (1/convert(float,RollsInPack)) *  
--   (1/convert(float,PacksInBundle)) * StatFactor,0)  
   GoodUnits * (1/convert(float,RollsInPack)) *  
   (1/convert(float,PacksInBundle)) * StatFactor  
  WHEN 3   
  THEN --Facial (Convert Good Units on ACP to Stat)  
--   round(GoodUnits * StatFactor,0)  
   GoodUnits * StatFactor  
  WHEN 4    
  THEN  --Hanky Lines in Neuss.  Good Units = Sheets.  
    case   
    when StatFactor > 0.0  
    then GoodUnits/StatFactor  
    else null  
    end  
       --@StatFactor is really StatUnit [sheets per stat] in Neuss!!!  
  ELSE     --Else default to the Tissue/Towel Calc.  
--   round(GoodUnits * RollsPerLog * (1/convert(float,RollsInPack)) *  
--   (1/convert(float,PacksInBundle)) * StatFactor,0)  
   GoodUnits * RollsPerLog * (1/convert(float,RollsInPack)) *  
   (1/convert(float,PacksInBundle)) * StatFactor  
  END,  
  
 OperationsTargetUnits =   
  CASE @BusinessType  
      WHEN 3   
  THEN --Facial, Line Speed Target is Cartons/Min.  
--      round(LineSpeedTarget * (1/convert(float,RollsInPack)) * (1/convert(float,PacksInBundle)) *  
--       OperationsRuntime * StatFactor,0)  
      LineSpeedTarget * (1/convert(float,RollsInPack)) * (1/convert(float,PacksInBundle)) *  
       OperationsRuntime * StatFactor  
       WHEN 4   
  THEN --Hanky lines in Neuss  
--      round((LineSpeedTarget / StatFactor) * OperationsRuntime,0)   
      (LineSpeedTarget / StatFactor) * OperationsRuntime   
          --@StatFactor is really StatUnit in Neuss!!!  
       ELSE  --Tissue/Towel/Napkins  
--      round(LineSpeedTarget * @ConvertFtToMM * (1/convert(float,SheetCount)) *  
--     (1/convert(float,SheetLength)) * RollsPerLog *   
--      OperationsRuntime * (1/convert(float,RollsInPack)) * (1/convert(float,PacksInBundle)) *  
--     StatFactor,0)   
     LineSpeedTarget * @ConvertFtToMM * (1/convert(float,SheetCount)) *  
     (1/convert(float,SheetLength)) * RollsPerLog *   
     OperationsRuntime * (1/convert(float,RollsInPack)) * (1/convert(float,PacksInBundle)) *  
     StatFactor   
       END,  
  
 IdealUnits =   
  CASE @BusinessType  
      WHEN 3   
  THEN --Facial, Line Speed Target is Cartons/Min.  
--   round(LineSpeedIdeal * (1/convert(float,RollsInPack)) * (1/convert(float,PacksInBundle)) *  
--   ProductionRuntime * StatFactor,0)  
   LineSpeedIdeal * (1/convert(float,RollsInPack)) * (1/convert(float,PacksInBundle)) *  
   ProductionRuntime * StatFactor  
  WHEN 4   
  THEN --Hanky lines in Neuss  
--      round((LineSpeedIdeal / StatFactor) * ProductionRuntime,0)   
      (LineSpeedIdeal / StatFactor) * ProductionRuntime   
                  --@StatFactor is really StatUnit in Neuss!!!  
  ELSE        --Tissue/Towel/Napkins  
--       round(LineSpeedIdeal * @ConvertFtToMM * (1/convert(float,SheetCount)) *  
--       (1/convert(float,SheetLength)) * RollsPerLog *   
--       ProductionRuntime * (1/convert(float,RollsInPack)) * (1/convert(float,PacksInBundle)) *  
--       StatFactor,0)   
       LineSpeedIdeal * @ConvertFtToMM * (1/convert(float,SheetCount)) *  
       (1/convert(float,SheetLength)) * RollsPerLog *   
       ProductionRuntime * (1/convert(float,RollsInPack)) * (1/convert(float,PacksInBundle)) *  
       StatFactor   
  END     
   
from @ProdRecords prs  
  
  
--print 'Section 37 Get Pack Tests: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
----------------------------------------------------------------------------  
-- Section 37: Get Pack Test values  
----------------------------------------------------------------------------  
  
-------------------------------------------------------------------------------  
-- @PackTests is used to sum up production values for Pack Lines in the result sets.  
-- If the data for #PackTests could be efficiently integrated with #Tests,   
-- then these two tables could be eliminated.    
-------------------------------------------------------------------------------  
  
insert #LimitTests  
 (  
 result_on,  
 result,  
 var_id  
 )  
select   
 result_on,  
 result,  
 var_id  
from dbo.tests t with (nolock)  
join @ProdUnitsPack pup  
on var_id = GoodUnitsVarID  
and result_on between @StartTime and @Endtime  
option (keep plan)  
  
  
INSERT dbo.#PackTests   
   (   
   VarId,  
   PLId,  
   PUId,  
   Value,  
   SampleTime,  
   ProdId,  
   UOM  
   )  
SELECT t.Var_Id,  
   pup.PLId,  
   pup.PUId,  
   CONVERT(FLOAT, t.Result),  
   t.Result_On,  
   ps.Prod_Id,  
   pup.UOM  
FROM #LimitTests t with (nolock)  
INNER JOIN @ProdUnitsPack pup   
ON t.Var_Id = pup.GoodUnitsVarId  
and (t.Result_On > @StartTime  
AND t.Result_On <= @EndTime)  
JOIN dbo.Production_Starts ps with (nolock)  
ON pup.PUId = ps.PU_Id  
AND t.Result_On >= ps.Start_Time  
AND (t.Result_On < ps.End_Time OR ps.End_Time IS NULL)  
ORDER BY t.Var_Id,t.Result_On DESC  
option (keep plan)  
  
  
--------------------------------------------------------------------------------  
-- Section 38: Get Event_Reason and Event_Reason_Category info  
--------------------------------------------------------------------------------  
  
IF @IncludeStops = 1  
  
 insert @EventReasons  
  (  
  Event_Reason_ID,  
  Event_Reason_Name  
  )  
 select    
  distinct  
  Event_Reason_ID,  
  Event_Reason_Name  
 from dbo.Event_Reasons er with (nolock)  
 join dbo.#delays td with (nolock)  
 on Event_Reason_ID = L1ReasonId   
 or Event_Reason_ID = L2ReasonId   
 or Event_Reason_ID = L3ReasonId   
 or Event_Reason_ID = L4ReasonId   
 option (keep plan)  
  
  
--print 'Section 39 Split: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
--------------------------------------------------------------------------  
-- Section 39: Split the delays and calculate Split Uptime.  
--------------------------------------------------------------------------  
  
------------------------------------------------------------------------------------------  
--  Added #SplitDowntimes and #SplitUptime for   
--  Splitting Downtime 062904  JSJ  
-------------------------------------------------------------------------------------------  
-- insert records into #SplitDowntimes for each shift period in the report window.  
-- then update the rest of the table with summary data.  
-------------------------------------------------------------------------------------------  
  
insert into dbo.#SplitDowntimes   
 (  
 StartTime,   
 EndTime,   
 prodid,   
 PLID,   
 puid,  
 pudesc,  
 Team,   
 Shift,  
 PrimaryId,  
 TEDetID,  
 TEFaultID,  
 ScheduleID,  
 CategoryID,  
 SubSystemId,  
 GroupCauseId,  
 LocationId,     
 L1ReasonId,     
 L2ReasonId,     
 L3ReasonId,     
 L4ReasonId,     
 LineStatus,  
 Downtime,  
 Uptime,  
--Rev11.55  
 RawRateloss,  
 Stops,  
 StopsUnscheduled,  
 StopsMinor,  
 StopsEquipFails,  
 StopsProcessFailures,  
 StopsBlockedStarved,  
 UpTime2m,  
 StopsRateLoss,  
 StopsELP,   
 MinorEF,  
 ModerateEF,  
 MajorEF,  
 MinorPF,  
 ModeratePF,  
 MajorPF,  
 RateLossRatio,  
 Causes,  
 Comment,  
 LineTargetSpeed,  
 LineActualSpeed,  
 UWS1Parent,  
 UWS1GrandParent,  
 UWS2Parent,  
 UWS2GrandParent,  
 LineIdealSpeed,  
 Runtime             -- 2007-03-15 VMK Rev11.37, added.  
 )  
SELECT  distinct  
 case when td.StartTime < rls.StartTime  
 then rls.StartTime else td.StartTime end,  
 case when (coalesce(td.EndTime,rls.endtime) >= rls.EndTime)  
 then rls.EndTime else td.EndTime end,  
 rls.prodid,  
 td.plid,   
 td.puid,   
 td.pudesc,  
 rls.Team,  
 rls.Shift,  
 td.PrimaryId,  
 td.TEDetID,  
 TEFaultID,  
 ScheduleID,  
 CategoryID,  
 SubSystemId,  
 GroupCauseId,  
 LocationId,     
 L1ReasonId,     
 L2ReasonId,     
 L3ReasonId,     
 L4ReasonId,     
 rls.LineStatus,  
 Downtime,  
 Uptime,  
--Rev11.55  
 RawRateloss,  
 Stops,  
 COALESCE(td.StopsUnscheduled,0),  
 StopsMinor,  
 StopsEquipFails,  
 StopsProcessFailures,  
 StopsBlockedStarved,  
 UpTime2m,  
 StopsRateLoss,  
 StopsELP,   
 CASE    
 WHEN (COALESCE(td.StopsEquipFails, 0) = 1)   
 AND (td.Downtime/60.0 >= 10.0)  
 and (td.Downtime/60.0 <= 60.0)   
 THEN 1  
 ELSE 0   
 END,  
 CASE    
 WHEN (COALESCE(td.StopsEquipFails, 0) = 1)   
 AND (td.Downtime/60.0 > 60.0)  
 and (td.Downtime/60.0 <= 360.0)   
 THEN 1  
 ELSE 0   
 END,  
 CASE    
 WHEN (COALESCE(td.StopsEquipFails, 0) = 1)   
 AND (td.Downtime/60.0 > 360.0)  
 THEN 1  
 ELSE 0   
 END,  
 CASE    
 WHEN (COALESCE(td.StopsProcessFailures, 0) = 1)   
 AND (td.Downtime/60.0 >= 10.0)  
 and (td.Downtime/60.0 <= 60.0)   
 THEN 1  
 ELSE 0   
 END,  
 CASE    
 WHEN (COALESCE(td.StopsProcessFailures, 0) = 1)   
 AND (td.Downtime/60.0 > 60.0)  
 and (td.Downtime/60.0 <= 360.0)   
 THEN 1  
 ELSE 0   
 END,  
 CASE    
 WHEN (COALESCE(td.StopsProcessFailures, 0) = 1)   
 AND (td.Downtime/60.0 > 360.0)  
 THEN 1  
 ELSE 0   
 END,  
 RateLossRatio,  
 1,  
 Comment,  
 TargetSpeed,   
 LineActualSpeed,  
 UWS1Parent,  
 UWS1GrandParent,  
 UWS2Parent,  
 UWS2GrandParent,  
 IdealSpeed,  
 DATEDIFF(ss, (CASE WHEN rls.StartTime < td.StartTime THEN   -- 2007-03-15 VMK Rev11.37, added.  
         td.StartTime ELSE rls.StartTime END),  
     (CASE WHEN rls.EndTime > td.EndTime THEN   
         td.EndTime ELSE rls.EndTime END))  
FROM  @runs rls   
JOIN  dbo.#delays td with (nolock)  
on rls.puid = td.puid   
and (((rls.starttime < td.endtime or td.endtime is null)   
and rls.endtime > td.starttime) or inRptWindow = 0)  
WHERE inRptWindow = 1  
option (keep plan)  
  
  
update dbo.#SplitDowntimes set  
 SplitDowntime = DATEDIFF(ss,StartTime,EndTime)--,  
WHERE stopsRateloss is null  
  
update td set  
  DelayType = pu.DelayType  
from dbo.#SplitDowntimes td with (nolock)  
join @produnits pu  
on td.puid = pu.puid  
  
update se set  
 SplitRLDowntime = DATEDIFF(ss,StartTime,EndTime) * RateLossRatio,  
 SplitRLELPDowntime =   
 case  
 WHEN (se.CategoryId = @CatELPId) --FLD 01-NOV-2007 Rev11.53  
--Rev11.55  
 then coalesce(RawRateloss,0.0)  
 else 0.0   
 end  
FROM dbo.#SplitDowntimes se with (nolock)  
where se.DelayType = 'RATELOSS' --@DelayTypeRateLossStr  
  
  
Update se SET   
 SplitELPDowntime =   
  CASE   
  WHEN tpu.DelayType <> @DelayTypeRateLossStr  
  AND (se.CategoryId = @CatELPId)  
  THEN se.Downtime  
  ELSE 0.0   
  END  
FROM dbo.#SplitDowntimes se with (nolock)  
JOIN @ProdUnits tpu   
ON se.PUId = tpu.PUId  
  
  
UPDATE se SET    
 SplitELPSchedDT =    
  CASE   
  WHEN COALESCE(se.ScheduleId,0) NOT IN (@SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
      @SchedEOProjectsId, @SchedBlockedStarvedId, 0) --FLD 01-NOV-2007 Rev11.53  
          --AND se.ScheduleId IS NOT NULL    -- 2007-04-17 VMK Rev11.37, added.  
  THEN se.SplitDowntime  
  ELSE 0   
  END  
FROM dbo.#SplitDowntimes se with (nolock)  
JOIN @ProdUnits tpu   
ON se.PUId = tpu.PUId  
WHERE tpu.PUDesc LIKE '%Converter%'  
and tpu.PUDesc NOT LIKE '%rate%loss%'  
  
  
update se set  
 SplitUnscheduledDT =   
  case  
--20090316  
  WHEN (se.pudesc like '%reliability%' and se.pudesc not like '%converter reliability%')  
  AND coalesce(se.ScheduleId,@SchedUnscheduledID) in (@SchedUnscheduledId)   
  THEN se.SplitDowntime  
  WHEN (se.pudesc like '%converter reliability%' or se.pudesc like '%Converter Blocked/Starved')  
  AND coalesce(se.ScheduleId,@SchedUnscheduledID) in (@SchedUnscheduledId,@SchedBlockedStarvedId)   
  THEN se.SplitDowntime  
  else 0.0   
  end  
from dbo.#SplitDowntimes se with (nolock)    
  
  
-- after splitting events, there are some values that will   
-- no longer have any meaning and should not be included   
-- when summations are done...  
  
--Rev11.55  
update dbo.#SplitDowntimes set  
 Downtime = null,  
 Uptime = null,  
 Stops = null,  
 StopsMinor = null,  
 StopsEquipFails = null,  
 StopsProcessFailures = null,  
 StopsELP = null,  
 StopsRateLoss = null,  
 StopsUnscheduled = null,  
 RawRateloss = null,  
 SplitELPDowntime = null,  
 SplitRLELPDowntime = null,  
 UpTime2m = null,  
 MinorEF = null,  
 ModerateEF = null,  
 MajorEF = null,  
 MinorPF = null,  
 ModeratePF = null,  
 MajorPF = null,  
 Causes = 0  
WHERE  (  
 SELECT count(*)   
 FROM dbo.#delays td with (nolock)  
 WHERE td.puid = dbo.#SplitDowntimes.puid   
 and td.starttime = dbo.#SplitDowntimes.starttime  
 ) = 0  
  
  
-- this field is used to simplify the initial insert to   
-- #splituptime, and to make that insert more efficient.  
-- the original version of that insert required a nested   
-- subquery, and adding this field allows us to eliminate   
-- that.  
  
update se1 set  
 se1.NextStartTime =   
  (  
  select top 1 starttime   
  from dbo.#SplitDowntimes se2 with (nolock)  
  where se1.puid = se2.puid  
--  and se1.seid < se2.seid  
  and se1.Endtime <= se2.StartTime  
--  order by se2.seid asc  
  order by se2.StartTime asc  
  )  
from dbo.#SplitDowntimes se1 with (nolock)  
  
  
--print 'Split Uptime ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-----------------------------------------------------------------  
-- get Uptime data  
-- NOTE that there are multiple inserts to #SplitUptime.  
-- Since we are not hitting the database for these inserts,   
-- this really isn't too bad.  But if we could figure out how   
-- to do all the work in just one insert, then we could add   
-- some efficiency and reduce the amount of code.  
-- On the other hand, it is easier to read through the code and   
-- see what's going on if the inserts are done separately.  
-----------------------------------------------------------------  
  
-- get the basic data for uptime between downtime events.  
  
insert into dbo.#SplitUptime  
 (  
 StartTime,   
 EndTime,   
 prodid,   
 PLID,   
 puid,  
 pudesc,  
 Team,   
 Shift,  
 LineTargetSpeed,  
 LineIdealSpeed,  
 SplitUptime,  
 LineStatus,  
 Comment  
 )  
SELECT distinct  
 case   
 when se1.endtime > rls.starttime and se1.endtime <= rls.endtime  
 then se1.EndTime  
 else rls.StartTime end,  
 case   
 when NextStartTime >= rls.starttime and NextStartTime < rls.endtime  
 then NextStartTime   
 else rls.EndTime end,  
 rls.prodid,   
 rls.PLID,  
 rls.puid,  
 se1.pudesc,  
 rls.Team,  
 rls.Shift,  
 rls.TargetSpeed,  
 rls.IdealSpeed,  
 0,  
 rls.LineStatus, --NULL,  
 'Split Uptime: Initial Load'   
FROM @runs rls   
join dbo.#SplitDowntimes se1 with (nolock)  
on rls.puid = se1.puid  
and ((rls.starttime < coalesce(se1.endtime,rls.endtime))   
and rls.endtime > se1.starttime)  
option (keep plan)  
  
  
-- get the uptime FROM the start of a shift/product to the first downtime event.  
insert into dbo.#SplitUptime   
 (  
 StartTime,   
 EndTime,   
 prodid,   
 PLID,   
 puid,  
 pudesc,  
 Team,   
 Shift,  
 LineTargetSpeed,  
 LineIdealSpeed,  
 SplitUptime,  
 LineStatus,  
 Comment  
 )  
SELECT distinct  
 rls.starttime,  
 se.starttime,  
 rls.prodid,  
 rls.PLID,  
 rls.puid,  
 se.pudesc,  
 rls.Team,  
 rls.Shift,  
 rls.TargetSpeed,  
 rls.IdealSpeed,  
 0,  
 rls.LineStatus, --NULL,  
 'Split Uptime: Start of Window'  
FROM  @runs rls   
join  dbo.#SplitDowntimes se with (nolock)  
on  rls.puid = se.puid  
and (rls.starttime < se.starttime   
and  rls.endtime > se.starttime)  
and  se.StartTime =   
 (  
 SELECT min(StartTime)  
 FROM dbo.#SplitDowntimes se1 with (nolock)  
 where rls.puid = se1.puid  
 and rls.starttime <= se1.StartTime   
 and rls.endtime > se1.starttime  
 )  
option (keep plan)  
  
  
-- get the uptime FROM the timespans where no downtime occurred   
  
insert into dbo.#SplitUptime   
 (  
 StartTime,   
 EndTime,   
 prodid,   
 PLID,   
 puid,  
 pudesc,  
 Team,   
 Shift,  
 LineTargetSpeed,  
 LineIdealSpeed,  
 SplitUptime,  
 LineStatus,  
 Comment   
 )  
SELECT distinct  
 rls.starttime,  
 rls.endtime,  
 rls.prodid,  
 rls.PLID,  
 rls.puid,  
 pu.pudesc,  
 rls.Team,  
 rls.Shift,  
 rls.TargetSpeed,  
 rls.IdealSpeed,  
 0,  
 rls.LineStatus,  
 'Split Uptime: No Events'  
FROM  @runs rls    
join @produnits pu  
on rls.puid = pu.puid  
WHERE    
 (  
 SELECT count(*)   
 FROM dbo.#SplitDowntimes se with (nolock)  
 where rls.puid = se.puid  
 and rls.starttime < se.endtime   
 and rls.endtime > se.starttime  
 and rls.prodid = se.prodid  
 and (rls.team = se.team) --or (rls.team is null and se.team is null))  
 and (rls.shift = se.shift) --or (rls.shift is null and se.shift is null))    
 ) = 0  
 and  (  
   pu.pudesc like '%reliability%'  
   or pu.pudesc like '%rate%loss%'  
   --or pudesc like '%sheet%break%'  
   )  
option (keep plan)     
  
  
update dbo.#SplitUptime set  
 pudesc =    
  (  
  SELECT top 1 pudesc   
  FROM @produnits pu --dbo.#SplitDowntimes se  
  WHERE pu.puid = dbo.#SplitUptime.puid  
  ),  
 SplitUptime = DATEDIFF(ss,StartTime,EndTime),  
 suid =  
  (  
  SELECT seid  
  FROM dbo.#SplitDowntimes se with (nolock)  
  where se.puid = dbo.#SplitUptime.puid   
  and (se.StartTime = dbo.#SplitUptime.EndTime   
    or dbo.#SplitUptime.EndTime is null)  
  )  
  
  
update dbo.#SplitDowntimes set  
 SplitUptime =  
 (  
 SELECT sum(SplitUptime)  
 FROM dbo.#SplitUptime su with (nolock)  
 where su.puid = dbo.#SplitDowntimes.puid  
 and su.EndTime = dbo.#SplitDowntimes.StartTime  
 and stopsRateloss is null  
   )  
  
  
-- it would be good to find a way to write the above   
-- inserts so that we don't end up with entries that have   
-- startime = endtime.  then we could eliminate this   
-- delete statement.  However, it doesn't seem likely,  
-- since there are start and end times drawn from multiple   
-- sources within case statements.  
  
delete FROM dbo.#SplitUptime WHERE starttime = endtime   
  
  
-- get the LineStatus for "artificial" uptime records  
update su set  
 LineStatus = r.LineStatus  
from #SplitUptime su with (nolock)  
join @runs r  
on su.puid = r.puid  
and --su.starttime between r.starttime and r.endtime  
 su.starttime >= r.starttime and su.starttime < r.endtime  
where suid is null  
  
  
-- add the uptime into the #SplitDowntimes  
--print 'add uptime ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
insert into dbo.#SplitDowntimes   
 (  
 StartTime,   
 EndTime,   
 prodid,   
 PLID,   
 puid,  
 pudesc,  
 Team,   
 Shift,  
 LineTargetSpeed,  
 LineIdealSpeed,  
 Downtime,  
 SplitDowntime,  
 SplitRLDowntime,  
 Uptime,  
 SplitUptime,  
 LineStatus,   
 Comment  
 )  
SELECT  
 StartTime,   
 EndTime,   
 prodid,   
 PLID,   
 puid,  
 pudesc,  
 Team,   
 Shift,  
 LineTargetSpeed,  
 LineIdealSpeed,  
 0,0,0,0,  
 SplitUptime,  
 LineStatus,   
 --Comment  
 'This record artificially created for the sole purpose of allocating uptime that spans changes in shift/team, product, line status and/or the report end time.'--,  
FROM dbo.#SplitUptime su with (nolock)  
WHERE suid is null  
and  (  
 SELECT pu_desc   
 FROM dbo.prod_units pu with (nolock)  
 WHERE pu.pu_id = su.puid  
 ) not like '%rate loss%'   
option (keep plan)  
  
  
--print 'LineSpeedAvg 1 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
--/*  
update su set  
 LineSpeedAvg =  
  
  (  
  SELECT   
   sum(datediff  
     (  
     ss,  
     case   
     when dateadd(mi, -15, t1.SampleTime) < su1.starttime   
     and t1.SampleTime > su1.starttime  
     then su1.StartTime  
     else dateadd(mi, -15, t1.SampleTime)  
     end,  
     case   
     when t1.SampleTime > su1.endtime   
     and dateadd(mi, -15, t1.SampleTime) < su1.endtime  
     then su1.endtime  
     else t1.SampleTime   
     end  
     ) * coalesce(convert(float,t1.value),0.0)  
   ) /  
   convert(float,  
   sum(datediff  
     (  
     ss,  
     case   
     when dateadd(mi, -15, t1.SampleTime) < su1.starttime   
     and t1.SampleTime > su1.starttime  
     then su1.StartTime  
     else dateadd(mi, -15, t1.SampleTime)  
     end,  
     case   
     when t1.SampleTime > su1.endtime   
     and dateadd(mi, -15, t1.SampleTime) < su1.endtime  
     then su1.endtime  
     else t1.SampleTime   
     end  
     )  
    ))        
  from @ProdLines pl1 --with (nolock)-- Rev11.33  
  join dbo.#splituptime su1 with (nolock)  
  on su1.puid = pl1.reliabilitypuid  
--  left join dbo.#Tests t with (nolock)  
--  on t.puid = pl.prodpuid  
--  and t.VarId = pl.VarLineSpeedId   
--  and su1.StartTime < t.SampleTime   
--  and su1.EndTime > dateadd(mi, -15, t.SampleTime)  
  join dbo.#Tests t1 with (nolock)  
  on t1.VarId = pl1.VarLineSpeedId   
  and t1.SampleTime > su1.StartTime   
  and dateadd(mi, -15, t1.SampleTime) < su1.EndTime  
  where su1.puid = su.puid  
  and su1.starttime = su.starttime  
  )  
from dbo.#splituptime su with (nolock)  
--*/  
/*  
update su set  
 LineSpeedAvg =  
  
  (  
  SELECT   
   sum(datediff  
     (  
     ss,  
     case   
     when dateadd(mi, -15, t.SampleTime) < su1.starttime   
     and t.SampleTime > su1.starttime  
     then su1.StartTime  
     else dateadd(mi, -15, t.SampleTime)  
     end,  
     case   
     when t.SampleTime > su1.endtime   
     and dateadd(mi, -15, t.SampleTime) < su1.endtime  
     then su1.endtime  
     else t.SampleTime   
     end  
     ) * coalesce(convert(float,t.value),0.0)  
   ) /  
   convert(float,  
   sum(datediff  
     (  
     ss,  
     case   
     when dateadd(mi, -15, t.SampleTime) < su1.starttime   
     and t.SampleTime > su1.starttime  
     then su1.StartTime  
     else dateadd(mi, -15, t.SampleTime)  
     end,  
     case   
     when t.SampleTime > su1.endtime   
     and dateadd(mi, -15, t.SampleTime) < su1.endtime  
     then su1.endtime  
     else t.SampleTime   
     end  
     )  
    ))        
  from @prodlines pl --with (nolock)-- Rev11.33  
  join dbo.#splituptime su1 with (nolock)  
  on su1.puid = pl.reliabilitypuid  
  left join dbo.#Tests t with (nolock)  
  on t.puid = pl.prodpuid  
  and t.VarId = pl.VarLineSpeedId   
  and su1.StartTime < t.SampleTime   
  and su1.EndTime > dateadd(mi, -15, t.SampleTime)  
  where su1.puid = su.puid  
  and su1.starttime = su.starttime  
  )  
from dbo.#splituptime su with (nolock)  
*/  
  
--print 'LineSpeedAvg 2 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
update pr set  
  
 LineSpeedAvg =  
  (  
  SELECT   
   sum(convert(float,datediff  
     (  
     ss,  
     case   
     when su1.starttime < pr1.starttime   
     and su1.endtime > pr1.starttime  
     then pr1.starttime  
     else su1.starttime  
     end,  
     case   
     when su1.endtime > pr1.endtime   
     and su1.starttime < pr1.endtime  
     then pr1.endtime  
     else su1.endtime  
     end  
     )) * coalesce(su1.LineSpeedAvg,0.0)  
   ) /  
   sum(convert(float,datediff  
     (  
     ss,  
     case   
     when su1.starttime < pr1.starttime   
     and su1.endtime > pr1.starttime  
     then pr1.starttime  
     else su1.starttime  
     end,  
     case   
     when su1.endtime > pr1.endtime   
     and su1.starttime < pr1.endtime  
     then pr1.endtime  
     else su1.endtime  
     end  
     )  
   ))  
  from @ProdRecords pr1  
  join dbo.#SplitUptime su1 with (nolock)  
  on pr1.puid = su1.puid  
  and pr1.starttime < su1.endtime  
  and pr1.endtime > su1.starttime  
  and pr1.team = su1.team  
  and pr1.prodid = su1.prodid  
  and pr1.linestatus = su1.linestatus  
  where pr1.puid = pr.puid  
  and pr1.starttime = pr.starttime  
  and pr1.team = pr.team  
  and pr1.prodid = pr.prodid  
  and pr1.linestatus = pr.linestatus  
  ),  
  
 SplitUptime =  
  (  
  select  
   sum(datediff  
     (  
     ss,  
     case   
     when su2.starttime < pr2.starttime   
     and su2.endtime > pr2.starttime  
     then pr2.starttime  
     else su2.starttime  
     end,  
     case   
     when su2.endtime > pr2.endtime   
     and su2.starttime < pr2.endtime  
     then pr2.endtime  
     else su2.endtime  
     end  
     )  
    )  
  from @ProdRecords pr2  
  join dbo.#SplitUptime su2 with (nolock)  
  on pr2.puid = su2.puid  
  and pr2.starttime < su2.endtime  
  and pr2.endtime > su2.starttime  
  and pr2.team = su2.team  
  and pr2.prodid = su2.prodid  
  and pr2.linestatus = su2.linestatus  
  where pr2.puid = pr.puid  
  and pr2.starttime = pr.starttime  
  and pr2.team = pr.team  
  and pr2.prodid = pr.prodid    
  and pr2.linestatus = pr.linestatus  
  )  
  
from @ProdRecords pr  
  
  
----------------------------------  
-- get PRDTMetrics  
----------------------------------  
  
-- Rev11.55  
-----------------  
-- get metrics  
-----------------  
  
--print 'SplitPRsRun ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
-- Rev11.55  
update prs set  
 PRPLID = pu.pl_id  
from dbo.#prsrun prs with (nolock)  
join dbo.prod_units pu  
on prs.prpuid = pu.pu_id  
  
  
-- Rev11.55  
insert dbo.#SplitPRsRun  
 (  
 id_num,  
 ShiftStart,  
 LineStatus,  
   [StartTime],  
   [EndTime],  
 [PLID],  
 [PUID],  
 [Team],  
 [ProdID],  
   [PRPLID],  
   [PRPUID],  
 DevComment   
 )  
select  
 distinct  
 prs.id_num,  
 ts.ShiftStart,  
 ts.LineStatus,  
 case when ts.StartTime < prs.StartTime  
 then prs.StartTime else ts.StartTime end,  
 case when (coalesce(ts.EndTime,prs.endtime) >= prs.EndTime)  
 then prs.EndTime else ts.EndTime end,  
 ts.[PLID],  
 ts.[PUID],  
 ts.[Team],  
 ts.[ProdID],  
   prs.[PRPLID],  
   prs.[PRPUID],  
 'Cvtg Line Team Prod' --DevComment   
from @runs ts   
left join dbo.#PRsRun prs with (nolock)   
on prs.plid = ts.plid  
and (ts.starttime < prs.endtime or prs.endtime is null)   
and ts.endtime > prs.starttime  
option (keep plan)  
  
  
--/*  
-- this update depends on the data being ordered by starttime and endtime within the puid.  
-- changes to the clustered index on the table may cause these id_nums to not be updated correctly.  
  
declare @NewIDNum int  
select @NewIDNum = (select max(id_num) + 1 from dbo.#SplitPRsRun with (nolock))  
  
update sprs set  
 id_num = @NewIDNum,  
 @NewIDNum = @NewIDNum + 1  
from dbo.#SplitPRsRun sprs with (nolock)  
where id_num is null  
--*/  
  
  
--print 'Time Ranges ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
-- Rev11.55  
update pdr set  
  
 StartTime_UnitTeam =   
  coalesce(  
  (  
  select  
   case   
   when max(pr1.EndTime) > pdr.EndTime  
   then pdr.starttime   
   else max(pr1.EndTime)  
   end     
  from dbo.#SplitPRsRun pr1 with (nolock)  
  where pr1.PuID = pdr.PuID  
  and pr1.StartTime < pdr.StartTime   
  and pr1.EndTime > pdr.StartTime   
  and pr1.Team = pdr.Team  
  ),pdr.StartTime),  
  
 EndTime_UnitTeam =   
  coalesce(  
  (  
  select  
   case   
   when min(pr2.StartTime) > pdr.StartTime  
   then pdr.endtime   
   else min(pr2.StartTime)  
   end     
  from dbo.#SplitPRsRun pr2 with (nolock)   
  where pr2.PuID = pdr.PuID  
  and pr2.StartTime < pdr.EndTime   
  and pr2.EndTime > pdr.EndTime   
  and pr2.Team = pdr.Team  
  ),pdr.EndTime),  
  
 StartTime_Unit =  
  coalesce(  
  (  
  select  
   case   
   when max(pr3.EndTime) > pdr.EndTime  
   then pdr.starttime   
   else max(pr3.EndTime)  
   end     
  from dbo.#SplitPRsRun pr3 with (nolock)  
  where pr3.PuID = pdr.PuID  
  and pr3.StartTime < pdr.StartTime   
  and pr3.EndTime > pdr.StartTime   
  ),pdr.StartTime),  
  
 EndTime_Unit =  
  coalesce(  
  (  
  select  
   case   
   when min(pr4.StartTime) > pdr.StartTime  
   then pdr.endtime   
   else min(pr4.StartTime)  
   end     
  from dbo.#SplitPRsRun pr4 with (nolock)  
  where pr4.PuID = pdr.PuID  
  and pr4.StartTime < pdr.EndTime   
  and pr4.EndTime > pdr.EndTime   
  ),pdr.EndTime),  
  
 StartTime_Line =  
  coalesce(  
  (  
  select  
   case   
   when max(pr5.EndTime) > pdr.EndTime  
   then pdr.starttime   
   else max(pr5.EndTime)  
   end     
  from dbo.#SplitPRsRun pr5 with (nolock)  
  where pr5.PlID = pdr.PlID  
  and pr5.StartTime < pdr.StartTime   
  and pr5.EndTime > pdr.StartTime   
  ),pdr.StartTime),  
  
 EndTime_Line =  
  coalesce(  
  (  
  select  
   case   
   when min(pr6.StartTime) > pdr.StartTime  
   then pdr.endtime   
   else min(pr6.StartTime)  
   end  
  from dbo.#SplitPRsRun pr6 with (nolock)  
  where pr6.PlID = pdr.PlID  
  and pr6.StartTime < pdr.EndTime   
  and pr6.EndTime > pdr.EndTime   
  ),pdr.EndTime)  
  
from dbo.#SplitPRsRun pdr with (nolock)  
  
  
  
--Rev11.55  
--print 'Time Range Updates 1 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
--Rev11.63  
update sprs set  
 StartTime_UnitTeam =   
  case  
  when sprs.StartTime_UnitTeam > sprs.EndTime_UnitTeam  
  then sprs.EndTime_UnitTeam  
  else sprs.StartTime_UnitTeam  
  end,  
 StartTime_Unit =   
  case  
  when sprs.StartTime_Unit > sprs.EndTime_Unit  
  then sprs.EndTime_Unit  
  else sprs.StartTime_Unit  
  end,  
 StartTime_Line =   
  case  
  when sprs.StartTime_Line > sprs.EndTime_Line  
  then sprs.EndTime_Line  
  else sprs.StartTime_Line  
  end  
from dbo.#SplitPRsRun sprs with (nolock)  
where sprs.StartTime_UnitTeam > sprs.EndTime_UnitTeam  
or sprs.StartTime_Unit > sprs.EndTime_Unit  
or sprs.StartTime_Line > sprs.EndTime_Line  
  
  
--print 'Time Range Updates 2 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
update pdr set  
 pdr.StartTime_UnitTeam = pdr.EndTime_UnitTeam  
from dbo.#SplitPRsRun pdr with (nolock)  
join dbo.#SplitPRsRun pr with (nolock)  
on pr.PuID = pdr.PuID  
--Rev11.63  
and pdr.StartTime_UnitTeam < pdr.EndTime_UnitTeam  
and pr.StartTime_UnitTeam < pr.EndTime_UnitTeam  
--Rev11.63  
where (pr.StartTime_UnitTeam = pdr.StartTime_UnitTeam  
    or pr.EndTime_UnitTeam = pdr.EndTime_UnitTeam)  
and datediff(ss,pr.StartTime_UnitTeam, pr.EndTime_UnitTeam)   
    > datediff(ss,pdr.StartTime_UnitTeam, pdr.EndTime_UnitTeam)  
and pr.Team = pdr.Team   
  
  
--print 'Time Range Updates 3 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
update pdr set  
 pdr.StartTime_UnitTeam = pdr.EndTime_UnitTeam  
from dbo.#SplitPRsRun pdr with (nolock)  
join dbo.#SplitPRsRun pr with (nolock)  
on pr.PuID = pdr.PuID  
--Rev11.63  
and pdr.StartTime_UnitTeam < pdr.EndTime_UnitTeam  
and pr.StartTime_UnitTeam < pr.EndTime_UnitTeam  
--Rev11.63  
where (pr.StartTime_UnitTeam = pdr.StartTime_UnitTeam  
    and pr.EndTime_UnitTeam = pdr.EndTime_UnitTeam)  
and pr.Team = pdr.Team   
and pr.id_num > pdr.id_num  
  
  
--print 'Time Range Updates 5 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
update pdr set  
 pdr.StartTime_Unit = pdr.EndTime_Unit  
from dbo.#SplitPRsRun pdr with (nolock)  
join dbo.#SplitPRsRun pr with (nolock)  
on pr.PuID = pdr.PuID  
--Rev11.63  
and pdr.StartTime_Unit < pdr.EndTime_Unit  
and pr.StartTime_Unit < pr.EndTime_Unit  
--Rev11.63  
where (pr.StartTime_Unit = pdr.StartTime_Unit  
    or pr.EndTime_Unit = pdr.EndTime_Unit)  
and datediff(ss,pr.StartTime_Unit, pr.EndTime_Unit)   
    > datediff(ss,pdr.StartTime_Unit, pdr.EndTime_Unit)  
  
  
--print 'Time Range Updates 6 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
update pdr set  
 pdr.StartTime_Unit = pdr.EndTime_Unit  
from dbo.#SplitPRsRun pdr with (nolock)   
join dbo.#SplitPRsRun pr with (nolock)   
on pr.PuID = pdr.PuID  
--Rev11.63  
and pdr.StartTime_Unit < pdr.EndTime_Unit  
and pr.StartTime_Unit < pr.EndTime_Unit  
--Rev11.63  
where (pr.StartTime_Unit = pdr.StartTime_Unit  
    and pr.EndTime_Unit = pdr.EndTime_Unit)  
and pr.id_num > pdr.id_num  
  
  
--print 'Time Range Updates 8 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-- 20081118  
update pdr set  
 pdr.StartTime_Line = pdr.EndTime_Line  
from dbo.#SplitPRsRun pdr with (nolock)   
join dbo.#SplitPRsRun pr with (nolock)  
on pdr.PlID = pr.PlID  
--Rev11.63  
and pdr.StartTime_Line < pdr.EndTime_Line  
and pr.StartTime_Line < pr.EndTime_Line  
--Rev11.63  
where (pr.StartTime_Line = pdr.StartTime_Line  
    or pr.EndTime_Line = pdr.EndTime_Line)  
and datediff(ss,pr.StartTime_Line, pr.EndTime_Line)   
    > datediff(ss,pdr.StartTime_Line, pdr.EndTime_Line)  
  
  
--print 'Time Range Updates 9 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
update pdr set  
 pdr.StartTime_Line = pdr.EndTime_Line  
from dbo.#SplitPRsRun pdr with (nolock)  
join dbo.#SplitPRsRun pr with (nolock)  
on pr.PlID = pdr.PlID  
--Rev11.63  
and pdr.StartTime_Line < pdr.EndTime_Line  
and pr.StartTime_Line < pr.EndTime_Line  
--Rev11.63  
where (pr.StartTime_Line = pdr.StartTime_Line  
    and pr.EndTime_Line = pdr.EndTime_Line)  
and pr.id_num > pdr.id_num  
  
--*/  
  
----- by Unit & Team  
--print 'Unit & Team Metrics ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
-- Rev11.55  
insert @ELPMetrics_UnitTeam   
 (   
 id_num,  
 [PLID],  
 [PUID],  
 [Team],  
 LineStatus,  
 StartTime,  
 EndTime,  
----- Metric by Unit and Team  
 [ELPSchedDT]--,  
 )    
select  
 prs.id_num,  
 prs.PLID,  
 prs.puid, --td.PUID,  
 prs.team, --td.Team,  
 prs.LineStatus,  
 prs.StartTime_UnitTeam,  
 prs.EndTime_UnitTeam,  
----- Metric by Unit and Team  
 sum(  
  case  
  WHEN COALESCE(td.ScheduleId,0) NOT IN (@SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
    @SchedEOProjectsId, @SchedBlockedStarvedId, 0) --FLD 01-NOV-2007 Rev11.53  
  and tpu.DelayType <> @DelayTypeRateLossStr  
  then   
   datediff (  
      ss,  
      case   
      when td.StartTime <= prs.StartTime_UnitTeam  
      and td.EndTime > prs.StartTime_UnitTeam  
      then prs.Starttime_UnitTeam  
      when td.StartTime > prs.StartTime_UnitTeam  
      and td.StartTime < prs.EndTime_UnitTeam  
      then td.StartTime  
      else null  
      end,  
      case   
      when td.StartTime < prs.EndTime_UnitTeam  
      and td.EndTime >= prs.EndTime_UnitTeam  
      then prs.Endtime_UnitTeam  
      when td.EndTime > prs.StartTime_UnitTeam  
      and td.EndTime < prs.EndTime_UnitTeam  
      then td.EndTime  
      else null  
      end  
      )   
  else 0.0  
  end  
  ) ELPSchedDT--,  
from @ProdUnits tpu   
left join dbo.#SplitPRsRun prs with (nolock)   
ON prs.PUId = tpu.PUId  
left join dbo.#SplitDowntimes td with (nolock)  
on prs.puid = td.puid   
and (td.starttime < prs.endtime)   
and (td.endtime > prs.starttime)   
where prs.starttime_UnitTeam < prs.endtime_UnitTeam  
group by prs.id_num, prs.PLID, prs.puid, prs.team, --td.PUID, td.team,   
prs.LineStatus, prs.starttime_UnitTeam, prs.endtime_UnitTeam  
  
update pdm set  
 PaperRuntimeRaw =   
  DATEDIFF(ss,    
     CASE   
     WHEN StartTime < @StartTime   
     THEN @StartTime   
     ELSE StartTime  
     END,  
     CASE   
     WHEN EndTime > @EndTime   
     THEN @EndTime   
     ELSE EndTime  
     END  
    )  
from @ELPMetrics_UnitTeam pdm  
join @produnits pu  
on pdm.puid = pu.puid  
where pudesc not like '%rate%loss%'  
and pudesc not like '%block%starv%'  
  
  
--print 'Unit & Team Updates ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
insert @PRDTSums_UnitTeam  
 (   
 [PLID],  
 [PuID],  
 [team],  
----- Metics by Line  
 [PaperRuntimeRaw],  
 [ELPSchedDT]--,  
 )    
select  
 prs.[PLID],  
 prs.[PuID],  
 prs.[team],  
----- Metics by Line  
 sum(prs.PaperRuntimeRaw),  
 sum(prs.ELPSchedDT)--,  
from @ELPMetrics_UnitTeam prs  
where (charindex('|' + prs.LineStatus + '|', '|' + @LineStatusList + '|') > 0  
or @LineStatusList = 'All')   
group by prs.PLID, prs.PuID, prs.team  
  
  
insert @SplitDT_UnitTeam  
 (  
 [PLID],  
 [PuID],  
 [team],  
 [Stops],  
 [StopsUnscheduled],  
 [StopsMinor],  
 [StopsEquipFails],  
 [StopsProcessFailures],  
 [SplitDowntime],  
 [UnschedSplitDT],  
 [RawUptime],  
 [SplitUptime],  
 [Uptime2Min],  
 [R2Numerator],  
 [R2Denominator],  
 [StopsELP],  
 [ELPDowntime],  
 [RLELPDowntime],  
 [StopsRateLoss],  
 [SplitRLDowntime],  
 [PRPolyChangeEvents],  
 [PRPolyChangeDowntime],  
 [HolidayCurtailDT]  
 )  
select  
 td.plid,  
 td.puid,  
 td.team,  
  
 SUM(td.Stops) [Stops],  
 SUM(td.StopsUnscheduled) [StopsUnscheduled],  
  
 SUM(td.StopsMinor) [StopsMinor],  
 SUM(td.StopsEquipFails) [StopsEquipFails],  
 SUM(td.StopsProcessFailures) [StopsProcessFailures],  
  
 SUM(td.SplitDowntime) [SplitDowntime],  
  
 sum(COALESCE(td.SplitUnscheduledDT,0.0)) [UnschedSplitDT],  
  
 sum(td.Uptime) [RawUptime],  
 SUM(td.SplitUptime) [SplitUptime],  
  
 SUM(  
   (  
   CASE    
   WHEN coalesce(td.ScheduleId,0) <> @SchedHolidayCurtailId   
   AND td.Uptime2m = 1   
   THEN (COALESCE(td.Stops,0))  
   ELSE 0 END  
   )--)  
  )  [Uptime2Min],  
  
 sum(  
  CASE   
  WHEN coalesce(td.ScheduleId,0) <> @SchedHolidayCurtailId   
  AND td.Uptime2m = 1   
  THEN convert(float,COALESCE(td.Stops,0))  
  ELSE 0.0   
  END  
  ) [R2Numerator],  
  
 sum(  
  CASE   
  WHEN coalesce(td.ScheduleId,0) <> @SchedHolidayCurtailId   
  THEN convert(float,COALESCE(td.Stops,0))  
  ELSE 0.0   
  END  
  ) [R2Denominator],  
  
 SUM(td.StopsELP) [StopsELP],  
 Sum(td.SplitELPDowntime) [ELPDowntime],  
 Sum(td.SplitRLELPDownTime) [RLELPDowntime],  
  
 SUM(td.StopsRateLoss) [StopsRateLoss],  
 SUM(td.SplitRLDowntime) [SplitRLDowntime],  
 sum(  
  case  
  when td.ScheduleID = @SchedPRPolyId -- Rev11.29  
  then coalesce(stops,0)   -- 2005-DEC-15 Vince King  Rev11.12  
  else 0   
  end  
  ) [PRPolyChangeEvents],  
 sum(  
  case  
  when td.ScheduleID = @SchedPRPolyId -- Rev11.29  
  then downtime   
  else 0.0   
  end  
  ) [PRPolyChangeDowntime],  
 sum(  
  CASE   
  WHEN td.ScheduleId = @SchedHolidayCurtailId   
  and td.DelayType <> @DelayTypeRateLossStr  
  then td.SplitDowntime  
  else 0.0  
  end  
  ) [HolidayCurtailDT]  
from dbo.#SplitDowntimes td with (nolock)  
group by td.plid, td.puid, td.team   
  
  
update prs set  
 [Stops] = dm.Stops,  
 [StopsUnscheduled] = dm.StopsUnscheduled,  
 [StopsMinor] = dm.StopsMinor,  
 [StopsEquipFails] = dm.StopsEquipFails,  
 [StopsProcessFailures] = dm.StopsProcessFailures,  
 [SplitDowntime] = dm.SplitDowntime,  
 [UnschedSplitDT] = dm.UnschedSplitDT,  
 [RawUptime] = dm.RawUptime,  
 [SplitUptime] = dm.SplitUptime,  
 [Uptime2Min] = dm.Uptime2Min,  
 [R2Numerator] = dm.R2Numerator,  
 [R2Denominator] = dm.R2Denominator,  
 [Runtime] = coalesce(dm.SplitDowntime,0.0) + coalesce(dm.SplitUptime,0.0),   
 [StopsELP] = dm.StopsELP,  
 [ELPDowntime] = dm.ELPDownTime,  
 [RLELPDowntime] = dm.RLELPDownTime,  
 [StopsRateLoss] = dm.StopsRateLoss,  
 [SplitRLDowntime] = dm.SplitRLDowntime,  
 [PRPolyChangeEvents] = dm.PRPolyChangeEvents,  
 [PRPolyChangeDowntime] = dm.PRPolyChangeDowntime,  
 [HolidayCurtailDT] = dm.HolidayCurtailDT  
from @PRDTSums_UnitTeam prs  
join @SplitDT_UnitTeam dm  
on prs.puid = dm.puid  
and prs.team = dm.team  
  
  
update pdm set  
 [ELPMins] = coalesce(ELPDowntime,0.0) + coalesce(RLELPDowntime,0.0),  
   [PaperRuntime] =   
  case  
  when PaperRuntimeRaw > 0.0  
  then coalesce(PaperRuntimeRaw,0.0) - coalesce(ELPSchedDT,0.0)  
  else 0.0  
  end,  
   [ProductionRuntime] =   
  case  
  when Runtime > 0.0  
  then coalesce(Runtime,0.0) - coalesce(HolidayCurtailDT,0.0)  
  else 0.0  
  end  
from @PRDTSums_UnitTeam pdm  
  
update pdm set   
 puid = pl.reliabilitypuid  
from @PRDTSums_UnitTeam pdm  
join @prodlines pl  
on pdm.plid = pl.plid  
join @produnits pu  
on pdm.puid = pu.puid  
where pu.pudesc like '%rate%loss%'   
  
  
----- by Unit  
--print 'Unit Metrics ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
-- Rev11.55  
insert @ELPMetrics_Unit  
 (   
 id_num,  
 [PLID],  
 [PUID],  
 LineStatus,  
 StartTime,  
 EndTime,  
----- Metric by Unit  
 [ELPSchedDT]--,  
 )    
select  
 prs.id_num,  
 prs.PLID,  
 prs.puid, --td.PUID,  
 prs.LineStatus,  
 prs.StartTime_Unit,  
 prs.EndTime_Unit,  
----- Metric by Unit  
 sum(  
  case  
  WHEN COALESCE(td.ScheduleId,0) NOT IN (@SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
    @SchedEOProjectsId, @SchedBlockedStarvedId, 0) --FLD 01-NOV-2007 Rev11.53  
  and tpu.DelayType <> @DelayTypeRateLossStr  
  then   
   datediff (  
      ss,  
      case   
      when td.StartTime <= prs.StartTime_Unit  
      and td.EndTime > prs.StartTime_Unit  
      then prs.Starttime_Unit  
      when td.StartTime > prs.StartTime_Unit  
      and td.StartTime < prs.EndTime_Unit  
      then td.StartTime  
      else null  
      end,  
      case   
      when td.StartTime < prs.EndTime_Unit  
      and td.EndTime >= prs.EndTime_Unit  
      then prs.Endtime_Unit  
      when td.EndTime > prs.StartTime_Unit  
      and td.EndTime < prs.EndTime_Unit  
      then td.EndTime  
      else null  
      end  
      )   
  else 0.0  
  end  
  ) ELPSchedDT--,  
from @ProdUnits tpu   
left join dbo.#SplitPRsRun prs with (nolock)   
ON prs.PUId = tpu.PUId  
left join dbo.#SplitDowntimes td with (nolock)  
on prs.puid = td.puid   
and (td.starttime < prs.endtime)   
and (td.endtime > prs.starttime)   
where prs.starttime_Unit < prs.endtime_Unit  
group by prs.id_num, prs.PLID, prs.puid, --td.PUID, td.team,   
prs.LineStatus, prs.starttime_Unit, prs.endtime_Unit  
  
update pdm set  
 PaperRuntimeRaw =   
  DATEDIFF(ss,    
     CASE   
     WHEN StartTime < @StartTime   
     THEN @StartTime   
     ELSE StartTime  
     END,  
     CASE   
     WHEN EndTime > @EndTime   
     THEN @EndTime   
     ELSE EndTime  
     END  
    )  
from @ELPMetrics_Unit pdm  
join @produnits pu  
on pdm.puid = pu.puid  
where pudesc not like '%rate%loss%'  
and pudesc not like '%block%starv%'  
  
  
--print 'Unit Updates ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
insert @PRDTSums_Unit  
 (   
 [PLID],  
 [PuID],  
----- Metics by Line  
 [PaperRuntimeRaw],  
 [ELPSchedDT]--,  
 )    
select  
 prs.[PLID],  
 prs.[PuID],  
----- Metics by Line  
 sum(prs.PaperRuntimeRaw),  
 sum(prs.ELPSchedDT)--,  
from @ELPMetrics_Unit prs  
where (charindex('|' + prs.LineStatus + '|', '|' + @LineStatusList + '|') > 0  
or @LineStatusList = 'All')   
group by prs.PLID, prs.PuID  
  
  
insert @SplitDT_Unit  
 (  
 [PLID],  
 [PuID],  
 [Stops],  
 [StopsUnscheduled],  
 [StopsMinor],  
 [StopsEquipFails],  
 [StopsProcessFailures],  
 [SplitDowntime],  
 [UnschedSplitDT],  
 [RawUptime],  
 [SplitUptime],  
 [Uptime2Min],  
 [R2Numerator],  
 [R2Denominator],  
 [StopsELP],  
 [ELPDowntime],  
 [RLELPDowntime],  
 [StopsRateLoss],  
 [SplitRLDowntime],  
 [PRPolyChangeEvents],  
 [PRPolyChangeDowntime],  
 [HolidayCurtailDT]  
 )  
select  
 td.plid,  
 td.puid,  
-- td.team,  
  
 SUM(td.Stops) [Stops],  
 SUM(td.StopsUnscheduled) [StopsUnscheduled],  
  
 SUM(td.StopsMinor) [StopsMinor],  
 SUM(td.StopsEquipFails) [StopsEquipFails],  
 SUM(td.StopsProcessFailures) [StopsProcessFailures],  
  
 SUM(td.SplitDowntime) [SplitDowntime],  
  
 sum(COALESCE(td.SplitUnscheduledDT,0.0)) [UnschedSplitDT],  
  
 sum(td.Uptime) [RawUptime],  
 SUM(td.SplitUptime) [SplitUptime],  
  
 SUM(--CONVERT(FLOAT,   
   (  
   CASE    
   WHEN coalesce(td.ScheduleId,0) <> @SchedHolidayCurtailId   
   AND td.Uptime2m = 1   
   THEN (COALESCE(td.Stops,0))  
   ELSE 0 END)--)  
  )  [Uptime2Min],  
  
 sum(  
  CASE   
  WHEN coalesce(td.ScheduleId,0) <> @SchedHolidayCurtailId   
  AND td.Uptime2m = 1   
  THEN convert(float,COALESCE(td.Stops,0))  
  ELSE 0.0   
  END  
  ) [R2Numerator],  
  
 sum(  
  CASE   
  WHEN coalesce(td.ScheduleId,0) <> @SchedHolidayCurtailId   
  THEN convert(float,COALESCE(td.Stops,0))  
  ELSE 0.0   
  END  
  ) [R2Denominator],  
  
 SUM(td.StopsELP) [StopsELP],  
 Sum(td.SplitELPDownTime) [ELPDowntime],  
 Sum(td.SplitRLELPDownTime) [RLELPDowntime],  
  
 SUM(td.StopsRateLoss) [StopsRateLoss],  
 SUM(td.SplitRLDowntime) [SplitRLDowntime],  
 sum(  
  case  
  when td.ScheduleID = @SchedPRPolyId -- Rev11.29  
  then coalesce(stops,0)   -- 2005-DEC-15 Vince King  Rev11.12  
  else 0   
  end  
  ) [PRPolyChangeEvents],  
 sum(  
  case  
  when td.ScheduleID = @SchedPRPolyId -- Rev11.29  
  then downtime   
  else 0.0   
  end  
  ) [PRPolyChangeDowntime],  
 sum(  
  CASE   
  WHEN td.ScheduleId = @SchedHolidayCurtailId   
  and td.DelayType <> @DelayTypeRateLossStr  
  then td.SplitDowntime  
  else 0.0  
  end  
  ) [HolidayCurtailDT]  
from dbo.#SplitDowntimes td with (nolock)  
group by td.plid, td.puid --, td.team   
  
  
update prs set  
 [Stops] = dm.Stops,  
 [StopsUnscheduled] = dm.StopsUnscheduled,  
 [StopsMinor] = dm.StopsMinor,  
 [StopsEquipFails] = dm.StopsEquipFails,  
 [StopsProcessFailures] = dm.StopsProcessFailures,  
 [SplitDowntime] = dm.SplitDowntime,  
 [UnschedSplitDT] = dm.UnschedSplitDT,  
 [RawUptime] = dm.RawUptime,  
 [SplitUptime] = dm.SplitUptime,  
 [Uptime2Min] = dm.Uptime2Min,  
 [R2Numerator] = dm.R2Numerator,  
 [R2Denominator] = dm.R2Denominator,  
 [Runtime] = coalesce(dm.SplitDowntime,0.0) + coalesce(dm.SplitUptime,0.0),   
 [StopsELP] = dm.StopsELP,  
 [ELPDowntime] = dm.ELPDownTime,  
 [RLELPDowntime] = dm.RLELPDownTime,  
 [StopsRateLoss] = dm.StopsRateLoss,  
 [SplitRLDowntime] = dm.SplitRLDowntime,  
 [PRPolyChangeEvents] = dm.PRPolyChangeEvents,  
 [PRPolyChangeDowntime] = dm.PRPolyChangeDowntime,  
 [HolidayCurtailDT] = dm.HolidayCurtailDT  
from @PRDTSums_Unit prs  
join @SplitDT_Unit dm  
on prs.puid = dm.puid  
  
  
update pdm set  
 [ELPMins] = coalesce(ELPDowntime,0.0) + coalesce(RLELPDowntime,0.0),  
   [PaperRuntime] =   
  case  
  when PaperRuntimeRaw > 0.0  
  then coalesce(PaperRuntimeRaw,0.0) - coalesce(ELPSchedDT,0.0)  
  else 0.0  
  end,  
   [ProductionRuntime] =   
  case  
  when Runtime > 0.0  
  then coalesce(Runtime,0.0) - coalesce(HolidayCurtailDT,0.0)  
  else 0.0  
  end  
from @PRDTSums_Unit pdm  
  
  
update pdm set   
 puid = pl.reliabilitypuid  
from @PRDTSums_Unit pdm  
join @prodlines pl  
on pdm.plid = pl.plid  
join @produnits pu  
on pdm.puid = pu.puid  
where pu.pudesc like '%rate%loss%'   
  
  
----- by Line  
--print 'Line Metrics ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
-- Rev11.55  
insert @ELPMetrics_Line   
 (   
 id_num,  
 [PLID],  
 LineStatus,  
 StartTime,  
 EndTime,  
----- Metric by Unit  
 [ELPSchedDT]--,  
 )    
select --distinct  
 prs.id_num,  
 prs.PLID,  
  
 prs.LineStatus,  
  
 prs.StartTime_Line,  
 prs.EndTime_Line,  
----- Metric by Unit and Team  
  
 sum(  
  case  
  WHEN COALESCE(td.ScheduleId,0) NOT IN (@SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
    @SchedEOProjectsId, @SchedBlockedStarvedId, 0)   
  AND td.pudesc like '%Converter Reliability%'  
  then   
   datediff (  
      ss,  
      case   
      when td.StartTime <= prs.StartTime_Line  
      and td.EndTime > prs.StartTime_Line  
      then prs.Starttime_Line  
      when td.StartTime > prs.StartTime_Line  
      and td.StartTime < prs.EndTime_Line  
      then td.StartTime  
      else null  
      end,  
      case   
      when td.StartTime < prs.EndTime_Line  
      and td.EndTime >= prs.EndTime_Line  
      then prs.Endtime_Line  
      when td.EndTime > prs.StartTime_Line  
      and td.EndTime < prs.EndTime_Line  
      then td.EndTime  
      else null  
      end  
      )   
  else 0.0  
  end  
  ) ELPSchedDT--,  
from dbo.#SplitPRsRun prs with (nolock)  
left join dbo.#SplitDowntimes td with (nolock)  
on prs.puid = td.puid   
and td.starttime < prs.endtime --or prs.endtime is null)   
and td.endtime > prs.starttime --or td.endtime is null)   
where prs.starttime_Line < prs.endtime_Line  
group by prs.id_num, prs.PLID, prs.LineStatus,   
prs.starttime_Line, prs.endtime_Line  
--*/  
  
update pdm set  
 PaperRuntimeRaw = DATEDIFF(ss,StartTime,EndTime)  
from @ELPMetrics_Line pdm  
  
  
--print 'Line Updates ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  
insert @PRDTSums_Line  
 (   
 [PLID],  
----- Metics by Line  
 [PaperRuntimeRaw],  
 [ELPSchedDT]--,  
 )    
select  
 prs.[PLID],  
----- Metics by Line  
 sum(prs.PaperRuntimeRaw),  
 sum(prs.ELPSchedDT)--,  
from @ELPMetrics_Line prs  
where (charindex('|' + prs.LineStatus + '|', '|' + @LineStatusList + '|') > 0  
or @LineStatusList = 'All')   
group by prs.PLID  
  
  
insert @SplitDT_Line  
 (  
 [PLID],  
 [Stops],  
 [StopsUnscheduled],  
 [StopsMinor],  
 [StopsEquipFails],  
 [StopsProcessFailures],  
 [SplitDowntime],  
 [UnschedSplitDT],  
 [RawUptime],  
 [SplitUptime],  
 [Uptime2Min],  
 [R2Numerator],  
 [R2Denominator],  
 [StopsELP],  
 [ELPDowntime],  
 [RLELPDowntime],  
 [StopsRateLoss],  
 [SplitRLDowntime],  
 [PRPolyChangeEvents],  
 [PRPolyChangeDowntime],  
 [HolidayCurtailDT],  
 [StopsPerDayDenomUT]  
 )  
select  
 td.plid,  
 SUM(td.Stops) [Stops],  
 SUM(td.StopsUnscheduled) [StopsUnscheduled],  
 SUM(td.StopsMinor) [StopsMinor],  
 SUM(td.StopsEquipFails) [StopsEquipFails],  
 SUM(td.StopsProcessFailures) [StopsProcessFailures],  
  
  case    
  when  (  
    SELECT count(*)   
    FROM @produnits spu   
    WHERE pudesc like '%Converter Reliability%'  
    and spu.plid = td.plid --pl.plId  
    ) > 0  
  then  
   sum(  
    CONVERT(  
      FLOAT,  
      case    
      when td.pudesc like '%Converter Reliability%'  
      then COALESCE(td.SplitDowntime,0)  
      else 0.0  
      end  
      )  
    )  
  else   
   sum(CONVERT(FLOAT,COALESCE(td.SplitDowntime,0)))  
  end [SplitDowntime],    
  
  case    
  when  (  
    SELECT count(*)   
    FROM @produnits spu   
    WHERE pudesc like '%Converter Reliability%'  
    and spu.plid = td.plid --pl.plId  
    ) > 0  
  then  
   sum(   
    CONVERT(  
      FLOAT,  
      case   
      when td.pudesc like '%Converter Reliability%'  
      then COALESCE(td.SplitUnscheduledDT,0)  
      else 0.0   
      end  
      )  
    )  
  else    
   sum(CONVERT(FLOAT,COALESCE(td.SplitUnscheduledDT,0)))          
  end [UnschedSplitDT],  
  
  case    
  when  (  
    SELECT count(*)   
    FROM @produnits spu   
    WHERE pudesc like '%Converter Reliability%'  
    and spu.plid = td.plid --pl.plId  
    ) > 0  
  then   
   sum(  
    CONVERT(FLOAT,  
      case   
      when td.pudesc like '%Converter Reliability%'  
      then COALESCE(td.Uptime,0)  
      else 0.0  
      end  
      )  
    )  
  else    
   sum(CONVERT(FLOAT,COALESCE(Uptime,0)))   
  end [RawUptime],  
  
  case    
  when  (  
    SELECT count(*)   
    FROM @produnits spu   
    WHERE pudesc like '%Converter Reliability%'  
    and spu.plid = td.plid --pl.plId  
    ) > 0  
  then   
   sum(  
    CONVERT(FLOAT,  
     case     
     when  td.pudesc like '%Converter Reliability%'  
     then  COALESCE(td.SplitUptime,0.0)  
     else  0.0   
     end  
       )  
    )   
  else    
   sum(CONVERT(FLOAT,COALESCE(td.SplitUptime,0.0)))  
  end [SplitUptime],  
       
 SUM(  
   (  
   CASE    
   WHEN coalesce(td.ScheduleId,0) <> @SchedHolidayCurtailId   
   AND td.Uptime2m = 1   
   THEN (COALESCE(td.Stops,0))  
   ELSE 0   
   END  
   )  
  )  [Uptime2Min],  
  
 sum(  
  CASE   
  WHEN coalesce(td.ScheduleId,0) <> @SchedHolidayCurtailId   
  AND td.Uptime2m = 1   
  THEN convert(float,COALESCE(td.Stops,0))  
  ELSE 0.0   
  END  
  ) [R2Numerator],  
  
 sum(  
  CASE   
  WHEN coalesce(td.ScheduleId,0) <> @SchedHolidayCurtailId   
  THEN convert(float,COALESCE(td.Stops,0))  
  ELSE 0.0   
  END  
  ) [R2Denominator],  
  
 SUM(td.StopsELP) [StopsELP],  
  
 Sum(td.SplitELPDownTime) [ELPDowntime],  
 Sum(td.SplitRLELPDownTime) [RLELPDowntime],  
 SUM(td.StopsRateLoss) [StopsRateLoss],  
 SUM(td.SplitRLDowntime) [SplitRLDowntime],  
 sum(  
  case  
  when td.ScheduleID = @SchedPRPolyId -- Rev11.29  
  then coalesce(td.stops,0)   -- 2005-DEC-15 Vince King  Rev11.12  
  else 0   
  end  
  ) [PRPolyChangeEvents],  
 sum(  
  case  
  when td.ScheduleID = @SchedPRPolyId -- Rev11.29  
  then td.downtime   
  else 0.0   
  end  
  ) [PRPolyChangeDowntime],  
 sum(  
  CASE   
  WHEN td.ScheduleId = @SchedHolidayCurtailId   
  and td.DelayType <> @DelayTypeRateLossStr  
  then td.SplitDowntime  
  else 0.0  
  end  
  ) [HolidayCurtailDT],  
  case    
  when  (  
    SELECT count(*)   
    FROM @produnits spu   
    WHERE pudesc like '%Converter Reliability%'  
    and spu.plid = td.plid --pl.plId  
    ) > 0  
  then  
   sum(   
    CONVERT(  
      FLOAT,  
      case   
      when td.pudesc like '%Converter Reliability%'  
      then COALESCE(td.SplitUptime,0)  
      else 0.0   
      end  
      )  
    )  
  else    
   sum(CONVERT(FLOAT,COALESCE(td.SplitUptime,0)))          
  end [StopsPerDayDenomUT]  
from dbo.#SplitDowntimes td with (nolock)  
group by td.plid   
  
  
update prs set  
 [Stops] = dm.Stops,  
 [StopsUnscheduled] = dm.StopsUnscheduled,  
 [StopsMinor] = dm.StopsMinor,  
 [StopsEquipFails] = dm.StopsEquipFails,  
 [StopsProcessFailures] = dm.StopsProcessFailures,  
 [SplitDowntime] = dm.SplitDowntime,  
 [UnschedSplitDT] = dm.UnschedSplitDT,  
 [RawUptime] = dm.RawUptime,  
 [SplitUptime] = dm.SplitUptime,  
 [Uptime2Min] = dm.Uptime2Min,  
 [R2Numerator] = dm.R2Numerator,  
 [R2Denominator] = dm.R2Denominator,  
 [Runtime] = datediff(ss,@starttime,@endtime), --coalesce(dm.SplitDowntime,0.0) + coalesce(dm.SplitUptime,0.0),   
 [StopsELP] = dm.StopsELP,  
 [ELPDowntime] = dm.ELPDownTime,  
 [RLELPDowntime] = dm.RLELPDownTime,  
 [StopsRateLoss] = dm.StopsRateLoss,  
 [SplitRLDowntime] = dm.SplitRLDowntime,  
 [PRPolyChangeEvents] = dm.PRPolyChangeEvents,  
 [PRPolyChangeDowntime] = dm.PRPolyChangeDowntime,  
 [HolidayCurtailDT] = dm.HolidayCurtailDT,  
 [StopsPerDayDenomUT] = dm.[StopsPerDayDenomUT]  
from @PRDTSums_Line prs  
join @SplitDT_Line dm  
on prs.plid = dm.plid  
  
  
update pdm set  
 [ELPMins] = coalesce(ELPDowntime,0.0) + coalesce(RLELPDowntime,0.0),  
   [PaperRuntime] =   
  case  
  when PaperRuntimeRaw > 0.0  
  then coalesce(PaperRuntimeRaw,0.0) - coalesce(ELPSchedDT,0.0)  
  else 0.0  
  end,  
   [ProductionRuntime] =   
  case  
  when Runtime > 0.0  
  then coalesce(Runtime,0.0) - coalesce(HolidayCurtailDT,0.0)  
  else 0.0  
  end  
from @PRDTSums_Line pdm  
  
  
-- we need to designate unit labels so we can combine data from   
-- blocked/starved units with the corresponding reliability unit.  
  
update pu set  
 CombinedPUDesc = PUDesc  
from @ProdUnits pu  
  
update pu set  
 CombinedPUDesc = replace(CombinedPUDesc,'Blocked/Starved','Reliability')   
from @ProdUnits pu  
where CombinedPUDesc like '%block%starv%'  
  
update pu set  
 CombinedPUDesc = rtrim(replace(CombinedPUDesc,'Reliability','Reliability & Blocked/Starved'))   
from @ProdUnits pu  
where   
 (  
 select count(*)  
 from @produnits pu2  
 where pu2.CombinedPUDesc = pu.CombinedPUDesc  
 ) > 1  
  
  
update pu set  
 OrderIndex = 0  
from @produnits pu  
where pu.CombinedPUDesc like '%Converter Reliability%'  
  
  -----------------------------------------------------------------------------------------------------------------------  
  -- Check to see if there are any events that meet the 'Issues' criteria.  
  -----------------------------------------------------------------------------------------------------------------------  
   INSERT INTO @DataQA  
    SELECT (CASE WHEN (td.Uptime / 60.0 > @MinUptimeMinToRpt)   
        THEN  (CASE WHEN td.StartTime < @StartTime THEN  
           'Improbable Uptime - Beginning Event'  
          ELSE  
           'Improbable Uptime - Ending Event'  
          END)  
        ELSE 'Significant Uncoded Downtime' END)  [Issue],  
       td.PLId              [Line],  
       td.PUId             [PUId],  
       td.PUDesc             [Unit],  
       td.StartTime            [StartTime],  
       td.EndTime            [EndTime],  
       td.SplitDowntime / 60.0        [Downtime],  
       td.Uptime / 60.0          [Uptime],  
       td.L1ReasonId           [L1ReasonId],  
       td.L2ReasonId           [L2ReasonId],  
       td.ScheduleId           [ScheduleId],  
       td.CategoryId           [CategoryId]  
    FROM    dbo.#Delays       td     
    WHERE ((td.Uptime / 60.0 > @MinUptimeMinToRpt)               -- Uptime greater than 120 minutes.  
     OR ((td.L1ReasonId IS NULL OR td.L2ReasonId IS NULL) AND td.SplitDowntime > 3600)) -- Uncoded events greater than 60 minutes.  
     AND (td.PUDesc LIKE '%Converter%Reliability%')            -- Only include Converter.  
    ORDER BY [Issue], td.PLId, td.PUId  
   
   -----------------------------------------------------------------------------------------------------------------------  
   -- If there is an Beginning Event, but no associated Ending Event then go get it.  
   -----------------------------------------------------------------------------------------------------------------------  
   IF (SELECT COUNT(*) FROM @DataQA WHERE Issue like 'Improbable Uptime - Beginning Event%') > 0  
    INSERT INTO @DataQA  
     SELECT  'Improbable Uptime - Ending Event'   [Issue],   
        dq.PLId           [Line],   
        dq.PUId           [PUId],   
        dq.PUDesc          [Unit],   
        ted.Start_Time         [StartTime],   
        ted.End_Time         [EndTime],  
        ted.Duration         [Downtime],   
        ted.Uptime          [Uptime],   
        ted.Reason_Level1        [L1Reason],  
        ted.Reason_Level2        [L2Reason],  
        erc1.erc_id          [Schedule],  
        erc2.erc_id          [Category]  
     FROM   @DataQA         dq   
     LEFT JOIN dbo.Timed_Event_Details    ted WITH (NOLOCK) ON ted.TEDet_Id = (SELECT TOP 1 TEDet_Id  
                                  FROM dbo.Timed_Event_Details ted1  
                                  WHERE ted1.PU_Id = dq.PUId  
                                   AND ted1.Start_Time < dq.StartTime  
                                  ORDER BY ted1.Start_Time DESC)  
     LEFT JOIN dbo.Event_Reasons      rl1 WITH (NOLOCK) ON ted.Reason_Level1 = rl1.Event_Reason_Id  
     LEFT JOIN dbo.Event_Reasons      rl2 WITH (NOLOCK) ON ted.Reason_Level2 = rl2.Event_Reason_Id  
     LEFT JOIN  event_reason_tree_data     ertd  WITH (NOLOCK) ON ted.event_reason_tree_data_id = ertd.event_reason_tree_data_id  
     LEFT JOIN  event_reason_category_data   ercd  WITH (NOLOCK) ON ertd.Level1_Id = ercd.ercd_id  
     LEFT JOIN  event_reason_catagories    erc1 WITH (NOLOCK) ON ercd.erc_id = erc1.erc_id  
                            AND erc1.erc_desc like 'Schedule%'  
     LEFT JOIN  event_reason_catagories    erc2 WITH (NOLOCK) ON ercd.erc_id = erc2.erc_id  
                            AND erc2.erc_desc like 'Category%'  
     WHERE dq.Issue like 'Improbable Uptime - Beginning Event%'   
   
   -------------------------------------------------------------------------------------------------------  
   -- Case where we check to see if the uptime between the last event and the report endtime is  
   -- greater than the time indicated to be flagged as an issue (@MinUptimeMinToRpt).  
   -- This picks up any events that are included in the reporting period.  
   -------------------------------------------------------------------------------------------------------  
   IF (SELECT COUNT(*) FROM @DataQA WHERE Issue like 'Improbable Uptime - Beginning Event%'  
                 OR Issue like 'Improbable Uptime - Ending Event%') = 0  
    BEGIN  
     INSERT INTO @DataQA  
      SELECT  'Improbable Uptime - Beginning Event'    [Issue],  
         pu.PLId              [Line],  
         pu.PUId              [PUId],  
         pu.PUDesc             [Unit],  
         td.Start_Time            [StartTime],  
         td.End_Time             [EndTime],  
         td.Duration / 60.0          [Downtime],  
         (DATEDIFF(ss, td.End_Time, @EndTime)) / 60.0  [Uptime],  
         td.Reason_Level1           [L1Reason],  
         td.Reason_Level2           [L2Reason],  
         erc1.erc_id             [Schedule],  
         erc2.erc_id             [Category]  
      FROM @ProdUnits  pu  
      JOIN dbo.Timed_Event_Details      td  WITH (NOLOCK) ON  td.TEDet_Id = (SELECT TOP 1 td1.TEDetId  
                                   FROM dbo.#Delays td1   
                                   WHERE td1.PUId = pu.PUId  
                                   ORDER BY StartTime DESC)  
      LEFT JOIN  event_reason_tree_data     ertd  WITH (NOLOCK) ON td.event_reason_tree_data_id = ertd.event_reason_tree_data_id  
      LEFT JOIN  event_reason_category_data   ercd  WITH (NOLOCK) ON ertd.Level1_Id = ercd.ercd_id  
      LEFT JOIN  event_reason_catagories    erc1 WITH (NOLOCK) ON ercd.erc_id = erc1.erc_id  
                             AND erc1.erc_desc like 'Schedule%'  
      LEFT JOIN  event_reason_catagories    erc2 WITH (NOLOCK) ON ercd.erc_id = erc2.erc_id  
                             AND erc2.erc_desc like 'Category%'  
      WHERE ((DATEDIFF(ss, td.End_Time, @EndTime)) / 60.0) > @MinUptimeMinToRpt  
       AND (pu.PUDesc LIKE '%Converter%Reliability%')                -- Only include Converter.  
   
     INSERT INTO @DataQA  
      SELECT DISTINCT  
         'Improbable Uptime - Ending Event',  
         PLId,   
         PUId,  
         PUDesc,  
         @EndTime,  
         @EndTime,  
         NULL,  
         DATEDIFF(ss, dq.StartTime, @EndTime) / 60.0,  
         NULL,  
         NULL,  
         NULL,  
         NULL  
      FROM @DataQA dq  
      WHERE (DATEDIFF(ss, dq.StartTime, @EndTime) / 60.0) > @MinUptimeMinToRpt  
       AND (Issue LIKE 'Improbable Uptime - Beginning Event%')  
   
    END               
   
   -----------------------------------------------------------------------------------------------------------------------  
   -- If there is an Ending Event, but no associated Beginning Event then go get it.  
   -----------------------------------------------------------------------------------------------------------------------  
   IF (SELECT COUNT(*) FROM @DataQA WHERE Issue like 'Improbable Uptime - Ending Event%') > 0 AND  
     (SELECT COUNT(*) FROM @DataQA WHERE Issue like 'Improbable Uptime - Beginning Event%') = 0  
    INSERT INTO @DataQA  
     SELECT  DISTINCT   
        'Improbable Uptime - Beginning Event'  [Issue],   
        dq.PLId           [Line],   
        dq.PUId           [PUId],   
        dq.PUDesc          [Unit],   
        ted.Start_Time         [StartTime],   
        ted.End_Time         [EndTime],  
        ted.Duration         [Downtime],   
        ted.Uptime          [Uptime],   
        ted.Reason_Level1        [L1Reason],  
        ted.Reason_Level2        [L2Reason],  
        erc1.erc_id          [Schedule],  
        erc2.erc_id          [Category]  
     FROM   @DataQA         dq   
     LEFT JOIN dbo.Timed_Event_Details    ted WITH (NOLOCK) ON ted.TEDet_Id = (SELECT TOP 1 TEDet_Id  
                                  FROM dbo.Timed_Event_Details ted1  
                                  WHERE ted1.PU_Id = dq.PUId  
                                   AND ted1.Start_Time < dq.StartTime  
                                  ORDER BY ted1.Start_Time DESC)  
     LEFT JOIN dbo.Event_Reasons      rl1 WITH (NOLOCK) ON ted.Reason_Level1 = rl1.Event_Reason_Id  
     LEFT JOIN dbo.Event_Reasons      rl2 WITH (NOLOCK) ON ted.Reason_Level2 = rl2.Event_Reason_Id  
     LEFT JOIN  event_reason_tree_data     ertd  WITH (NOLOCK) ON ted.event_reason_tree_data_id = ertd.event_reason_tree_data_id  
     LEFT JOIN  event_reason_category_data   ercd  WITH (NOLOCK) ON ertd.Level1_Id = ercd.ercd_id  
     LEFT JOIN  event_reason_catagories    erc1 WITH (NOLOCK) ON ercd.erc_id = erc1.erc_id  
                            AND erc1.erc_desc like 'Schedule%'  
     LEFT JOIN  event_reason_catagories    erc2 WITH (NOLOCK) ON ercd.erc_id = erc2.erc_id  
                            AND erc2.erc_desc like 'Category%'  
     WHERE dq.Issue like 'Improbable Uptime - Ending Event%'   
   
   -----------------------------------------------------------------------------------------------------------------------  
   -- Check to see if no downtime events were selected for the time period.  If so, pick up the last event prior to the   
   -- report period and then check to see if the uptime meets the issue criteria.  
   -----------------------------------------------------------------------------------------------------------------------  
   IF (SELECT COUNT(*) FROM @DataQA WHERE Issue like 'Improbable Uptime - Beginning Event%') = 0  
    BEGIN  
     INSERT INTO @DataQA  
      SELECT  DISTINCT  
         'Improbable Uptime - Beginning Event' [Issue],  
         pu1.PL_Id          [Line],  
         ted.PU_Id          [PUId],  
         pu1.PU_Desc          [PUDesc],  
         ted.Start_Time         [StartTime],   
         ted.End_Time          [EndTime],   
         ted.Duration         [Downtime],  
         ted.Uptime          [Uptime],  
         ted.Reason_Level1        [L1Reason],  
         ted.Reason_Level2        [L2Reason],  
         erc1.erc_id          [Schedule],  
         erc2.erc_id          [Category]  
      FROM @ProdUnits          pu  
      JOIN dbo.Prod_Units         pu1 WITH (NOLOCK) ON pu.PUId   = pu1.PU_Id  
      JOIN dbo.Timed_Event_Details      ted WITH (NOLOCK) ON ted.TEDet_Id = (SELECT TOP 1 TEDet_Id  
                                   FROM dbo.Timed_Event_Details ted1  
                                   WHERE ted1.PU_Id = pu.PUId  
                                    AND ted1.Start_Time < @EndTime  
                                   ORDER BY ted1.Start_Time DESC)  
      LEFT JOIN  event_reason_tree_data     ertd  WITH (NOLOCK) ON ted.event_reason_tree_data_id = ertd.event_reason_tree_data_id  
      LEFT JOIN  event_reason_category_data   ercd  WITH (NOLOCK) ON ertd.Level1_Id = ercd.ercd_id  
      LEFT JOIN  event_reason_catagories    erc1 WITH (NOLOCK) ON ercd.erc_id = erc1.erc_id  
                             AND erc1.erc_desc like 'Schedule%'  
      LEFT JOIN  event_reason_catagories    erc2 WITH (NOLOCK) ON ercd.erc_id = erc2.erc_id  
                             AND erc2.erc_desc like 'Category%'  
     WHERE pu1.PU_Desc LIKE '%Converter Reliability%' AND ((DATEDIFF(ss, ted.End_Time, @EndTime)/60.0) > @MinUptimeMinToRpt)  
   
     INSERT INTO @DataQA  
      SELECT DISTINCT  
         'Improbable Uptime - Ending Event',  
         PLId,   
         PUId,  
         PUDesc,  
         @EndTime,  
         @EndTime,  
         NULL,  
         DATEDIFF(ss, dq.EndTime, @EndTime) / 60.0,  
         NULL,  
         NULL,  
         NULL,  
         NULL  
      FROM @DataQA dq  
      WHERE (Issue LIKE 'Improbable Uptime - Beginning Event%')  
    END  
               
--print 'ResturnResultSets: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-----------------------------------------------------------  
ReturnResultSets:  
-----------------------------------------------------------  
  
--select 'sprs', pl.pl_desc, prs.*   
--from #splitprsrun prs  
--join prod_lines pl  
--on prs.plid = pl.pl_id  
--where puid = 76  
--or puid = 561  
  
--select * from @PRDTSums_Unit  
  
-- select 'sd', * from #splitdowntimes sd  
--WHERE splitelpdowntime is not null  
--and pudesc like '%ott1%'  
--order by puid, starttime, endtime  
  
-- select '#Stops', * from dbo.#Stops  
  
--select 'pr', * from @ProdRecords pr  
--select 'su', * from #SplitUptime su  
--where plid = 46 or plid = 48  
  
--select 'runs', * from dbo.#Runs  
-- select 'runsummary', * from @RunSummary  
--select 'eventreasons', * from @EventReasons  
--select 'pdow', * from @PRDTOutsideWindow  
--select 'dow', * from @DelaysOutsideWindow  
  
-- select 'delays' [#Delays], * from dbo.#delays  
--select 'prsrun', * from dbo.#prsrun       
--select 'prodlines', * from @prodlines   
--select 'prodrecords', * from @ProdRecords  
--select 'LineProdVars', * from @LineProdVars  
--select 'Unit Tests', * from #tests  
--where varid = 29957  
--or varid = 29999  
--select 'produnits', * from @produnits  
--select 'est', * from dbo.#EventStatusTransitions  
--select 'estow', * from dbo.#ESTOutsideWindow  
  
  
----------------------------------------------------------------------------------------------------  
-- Section 40: If there are Error Messages, then return them without other result sets.  
----------------------------------------------------------------------------------------------------  
  
-- if there are errors FROM the parameter validation, then return them and skip the rest of the results  
  
IF (SELECT count(*) FROM @ErrorMessages) > 0  
 BEGIN  
 SELECT ErrMsg  
 FROM @ErrorMessages  
 END  
ELSE  
 BEGIN  
  
 -------------------------------------------------------------------------------  
 -- Section 41: Results Set #1 - Return the empty Error Messages.    
 -------------------------------------------------------------------------------  
  
 SELECT ErrMsg  
 FROM @ErrorMessages  
  
  
 -----------------------------------------------------------------------------  
 -- Section 42: Results Set #2 -  return the report parameter values.  
 ----------------------------------------------------------------------------  
  
 -----------------------------------------------------------------------------------------  
 -- This RS is used when Report Parameter values are required within the Excel Template.  
 -----------------------------------------------------------------------------------------  
 SELECT  
  @RptName [@RptName],  
  @RptTitle [@RptTitle],  
  @ProdLineList [@ProdLineList],  
  @DelayTypeList [@DelayTypeList],  
  @PropCvtgProdFactorId [@PropCvtgProdFactorId],  
  @DefaultPMRollWidth [@DefaultPMRollWidth],  
  @ConvertFtToMM [@ConvertFtToMM],  
  @ConvertInchesToMM [@ConvertInchesToMM],  
  @BusinessType [@BusinessType],  
  @IncludeTeam [@RptIncludeTeam],  
  @IncludeStops [@RptIncludeStops],  
  @BySummary [@RptBySummary],  
  @RL1Title [@RptRL1Title],  
  @RL2Title [@RptRL2Title],  
  @RL3Title [@RptRL3Title],  
  @RL4Title [@RptRL4Title],  
  @PackPUIdList [@PackPUIdList],  
  @UserName [@RptUser],  
  @RptPageOrientation [@RptPageOrientation],  
  @RptPageSize [@RptPageSize],  
  @RptPercentZoom [@RptPercentZoom],  
  @RptTimeout [@RptTimeout],  
  @RptFileLocation [@RptFileLocation],  
  @RptConnectionString [@RptConnectionString],  
  @RptGroupBy [@RptGroupBy],  
  COALESCE(@LineStatusList,'All') [@LineStatusList]  
  
 -------------------------------------------------------------------------------  
 -- All raw data.  Note that Excel can only handle a maximum of 65536 rows in a  
 -- spreadsheet.  Therefore, we send an error if there are more than that number.  
 -------------------------------------------------------------------------------  
 IF @IncludeTeam = 1  
  BEGIN    
  
  --print 'Result set 1 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  -------------------------------------------------------------------------------------------  
  -- Section 43: Results Set #3 - Return the stops result set for Line / Master Unit / Team.    
  -------------------------------------------------------------------------------------------  
  
  INSERT dbo.#UnitStops  
  
  
--Rev11.55  
  SELECT   
   pu.OrderIndex                [OrderIndex],  
   pl.PLDesc                  [Production Line],  
  
-- case  
-- when pu.PUDesc like '%block%starv%'   
-- then replace(pu.pudesc,'Blocked/Starved','Reliability')   
-- else pu.PUDesc  
-- end [Master Unit],  
  
   pu.CombinedPUDesc               [Master Unit],     
  
   pdm.team                  [Team],  
   coalesce(SUM(pdm.Stops),0)            [Total Stops],  
   coalesce(SUM(pdm.StopsUnscheduled),0)        [Unscheduled Stops],  
   0                     [Unscheduled Stops/Day],  
   coalesce(SUM(pdm.StopsMinor),0)          [Minor Stops],  
   coalesce(SUM(pdm.StopsEquipFails),0)        [Equipment Failures],  
   coalesce(SUM(pdm.StopsProcessFailures),0)       [Process Failures],  
   coalesce(SUM(pdm.SplitDowntime),0.0) / 60.0      [Split Downtime],  
   coalesce(sum(pdm.UnschedSplitDT),0.0) / 60.0      [Unscheduled Split DT],  
--   coalesce(sum(pdm.RawUptime),0.0) / 60.0       [Raw Uptime],  
--   coalesce(SUM(pdm.SplitUptime),0.0) / 60.0       [Split Uptime],  
  
   case  
   when   
    sum(  
     case  
     when pu.pudesc like '%reliability%'  
     then pdm.RawUptime  
     else 0.0  
     end  
     )  
    >  
    sum(  
     case  
     when pu.pudesc like '%block%starv%'  
     then pdm.SplitDowntime  
     else 0.0  
     end  
     )   
   then   
    (  
    sum(  
     case  
     when pu.pudesc like '%reliability%'  
     then pdm.RawUptime  
     else 0.0  
     end  
     )  
    -  
    sum(  
     case  
     when pu.pudesc like '%block%starv%'  
     then pdm.SplitDowntime  
     else 0.0  
     end  
     )   
    )/60.0  
   else 0.0  
   end                   [Raw Uptime],  
  
   case  
   when   
    sum(  
     case  
     when pu.pudesc like '%reliability%'  
     then pdm.SplitUptime  
     else 0.0  
     end  
     )  
    >  
    sum(  
     case  
     when pu.pudesc like '%block%starv%'  
     then pdm.SplitDowntime  
     else 0.0  
     end  
     )   
   then   
    (  
    sum(  
     case  
     when pu.pudesc like '%reliability%'  
     then pdm.SplitUptime  
     else 0.0  
     end  
     )  
    -  
    sum(  
     case  
     when pu.pudesc like '%block%starv%'  
     then pdm.SplitDowntime  
     else 0.0  
     end  
     )   
    )/60.0  
   else 0.0  
   end                    [Split Uptime],  
  
   0.0                    [Planned Availability],  
   coalesce(SUM(pdm.Uptime2min),0.0)         [Stops with Uptime <2 Min],  
  
   coalesce(     
   CASE   
   WHEN SUM(pdm.R2Denominator) > 0   
   THEN ROUND(1 - (SUM(pdm.R2Numerator)   
     /SUM(pdm.R2Denominator)), 2)   
     ELSE 0.0   
   END                      
   ,0.0)                   [R(2)],     
  
   0.0                    [Unplanned MTBF],  
   0.0                    [Unplanned MTTR],  
  
   coalesce(SUM(pdm.StopsELP),0)           [ELP Stops],  
--   coalesce(ROUND(Sum(pdm.ELPMins/60.0),2),0.0)      [ELP Losses (Mins)],  
   Sum(pdm.ELPMins)/60.0             [ELP Losses (Mins)],  
  
         CASE    
   WHEN SUM(pdm.PaperRuntime) > 0.0   
   THEN SUM(pdm.ELPMins) / SUM(pdm.PaperRuntime)   
   ELSE 0.0   
   END                    [ELP %],  
  
   coalesce(sum(pdm.StopsRateLoss),0)         [Rate Loss Events],  
   coalesce(SUM(pdm.SplitRLDowntime),0.0) / 60.0     [Rate Loss Effective Downtime],  
  
   coalesce(  
   CASE    
   WHEN SUM(pdm.ProductionRuntime) > 0.0   
   THEN SUM(pdm.SplitRLDowntime)   
     / SUM(pdm.ProductionRuntime)    
   ELSE 0.0   
   END                      
   ,0.0)                   [Rate Loss %],    
  
   coalesce(SUM(pdm.PaperRuntime),0.0) / 60.0      [Paper Runtime],                       
   coalesce(SUM(pdm.ProductionRuntime),0.0)/ 60.0     [Production Time],  
   coalesce(sum(pdm.PRPolyChangeEvents),0)       [PR/Poly Change Events],  
   coalesce(sum(pdm.PRPolyChangeDowntime),0.0)/60.0    [PR/Poly Change Downtime],  
   0.0                    [Avg PR/Poly Change Time]  
  FROM @PRDTSums_UnitTeam pdm --SplitEvents se  
  JOIN @ProdUnits pu   
  ON pdm.PUId = pu.PUId  
  JOIN @ProdLines pl -- Rev11.33   
  ON pu.PLId = pl.PLId  
  GROUP BY  pl.PLDesc, pu.OrderIndex, pu.CombinedPUDesc,  
-- case  
-- when pu.PUDesc like '%block%starv%'   
-- then replace(pu.pudesc,'Blocked/Starved','Reliability')   
-- else pu.PUDesc  
-- end,  
      pdm.team  
  ORDER BY  pl.PLDesc, pu.OrderIndex, pu.CombinedPUDesc,  
-- case  
-- when pu.PUDesc like '%block%starv%'   
-- then replace(pu.pudesc,'Blocked/Starved','Reliability')   
-- else pu.PUDesc  
-- end,  
      pdm.team  
  option (keep plan)  
  
  update dbo.#UnitStops set  
   [Unscheduled Stops/Day] = --FLD 01-NOV-2007 Rev11.53  
    case  when [Split Uptime] + [Unscheduled Split DT] > 0   
     then ROUND(([Unscheduled Stops] * 1440.0) / ([Split Uptime] + [Unscheduled Split DT]),0)       
     else 0 end,  
   [Planned Availability] =   
    case  when [Split Uptime] + [Unscheduled Split DT] > 0   
     then [Split Uptime] / ([Split Uptime] + [Unscheduled Split DT])       
     else 0 end,  
   [Unplanned MTBF] =   
    case when [Unscheduled Stops] > 0   
     then [Split Uptime] / [Unscheduled Stops]  
     else 0 end,  
   [Unplanned MTTR] =   
    case when [Unscheduled Stops] > 0   
     then [Unscheduled Split DT]/[Unscheduled Stops]  
     else 0 end,  
   [Avg PR/Poly Change Time] =            -- Rev11.29  
    case when [PR/Poly Change Events] > 0        -- Rev11.29  
     then [PR/Poly Change Downtime] / convert(float,[PR/Poly Change Events]) -- Rev11.29  
     else NULL end  
  
  
  SELECT @SQL =   
  case  
  when (SELECT count(*) FROM dbo.#UnitStops with (nolock)) > 65000 then   
  'SELECT ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
  when (SELECT count(*) FROM dbo.#UnitStops with (nolock)) = 0 then   
  'SELECT ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
  else GBDB.dbo.fnLocal_RptTableTranslation('#UnitStops', @LanguageId)  
   + ' order by [Production Line], [OrderIndex], [Master Unit], [Team]'  
  end  
  
  -- strip OrderIndex from the returned results  
  if charindex('OrderIndex',left(@SQL,25)) > 5  
  select @SQL = replace(@SQL,substring(@SQL,7,charindex(',',@SQL) -6), ' ')   
  
  execute sp_executesql @SQL   
  
  
  --print 'Result set 2 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  ----------------------------------------------------------------------------------------------  
  -- Section 44: Results Set #4 - Return the stops result set for totals by Line / Master Unit.  
  ----------------------------------------------------------------------------------------------  
  
  TRUNCATE TABLE dbo.#UnitStops  
  
  INSERT dbo.#UnitStops  
  
  
--Rev11.55  
  SELECT   
   pu.OrderIndex                [OrderIndex],  
   pl.PLDesc                  [Production Line],  
  
-- case  
-- when pu.PUDesc like '%block%starv%'   
-- then replace(pu.pudesc,'Blocked/Starved','Reliability')   
-- else pu.PUDesc  
-- end [Master Unit],  
  
   pu.CombinedPUDesc               [Master Unit],     
  
   ''                     [Team],  
   coalesce(SUM(pdm.Stops),0)            [Total Stops],  
   coalesce(SUM(pdm.StopsUnscheduled),0)        [Unscheduled Stops],  
   0                     [Unscheduled Stops/Day],  
   coalesce(SUM(pdm.StopsMinor),0)          [Minor Stops],  
   coalesce(SUM(pdm.StopsEquipFails),0)        [Equipment Failures],  
   coalesce(SUM(pdm.StopsProcessFailures),0)       [Process Failures],  
   coalesce(SUM(pdm.SplitDowntime),0.0) / 60.0      [Split Downtime],  
   coalesce(sum(pdm.UnschedSplitDT),0.0) / 60.0      [Unscheduled Split DT],  
--   coalesce(sum(pdm.RawUptime),0.0) / 60.0       [Raw Uptime],  
--   coalesce(SUM(pdm.SplitUptime),0.0) / 60.0       [Split Uptime],  
  
   case  
   when   
    sum(  
     case  
     when pu.pudesc like '%reliability%'  
     then pdm.RawUptime  
     else 0.0  
     end  
     )  
    >  
    sum(  
     case  
     when pu.pudesc like '%block%starv%'  
     then pdm.SplitDowntime  
     else 0.0  
     end  
     )   
   then   
    (  
    sum(  
     case  
     when pu.pudesc like '%reliability%'  
     then pdm.RawUptime  
     else 0.0  
     end  
     )  
    -  
    sum(  
     case  
     when pu.pudesc like '%block%starv%'  
     then pdm.SplitDowntime  
     else 0.0  
     end  
     )   
    )/60.0  
   else 0.0  
   end                   [Raw Uptime],  
  
   case  
   when   
    sum(  
     case  
     when pu.pudesc like '%reliability%'  
     then pdm.SplitUptime  
     else 0.0  
     end  
     )  
    >  
    sum(  
     case  
     when pu.pudesc like '%block%starv%'  
     then pdm.SplitDowntime  
     else 0.0  
     end  
     )   
   then   
    (  
    sum(  
     case  
     when pu.pudesc like '%reliability%'  
     then pdm.SplitUptime  
     else 0.0  
     end  
     )  
    -  
    sum(  
     case  
     when pu.pudesc like '%block%starv%'  
     then pdm.SplitDowntime  
     else 0.0  
     end  
     )   
    )/60.0  
   else 0.0  
   end                    [Split Uptime],  
  
   0.0                    [Planned Availability],  
   coalesce(SUM(pdm.Uptime2min),0.0)         [Stops with Uptime <2 Min],  
  
   coalesce(     
   CASE   
   WHEN SUM(pdm.R2Denominator) > 0   
   THEN ROUND(1 - (SUM(pdm.R2Numerator)   
     /SUM(pdm.R2Denominator)), 2)   
     ELSE 0.0   
   END                      
   ,0.0)                   [R(2)],     
  
   0.0                    [Unplanned MTBF],  
   0.0                    [Unplanned MTTR],  
   coalesce(SUM(pdm.StopsELP),0)           [ELP Stops],  
--   coalesce(ROUND(Sum(pdm.ELPMins/60.0),2),0.0)      [ELP Losses (Mins)],  
   Sum(pdm.ELPMins)/60.0             [ELP Losses (Mins)],  
  
         CASE    
   WHEN SUM(pdm.PaperRuntime) > 0.0   
   THEN SUM(pdm.ELPMins) / SUM(pdm.PaperRuntime)   
   ELSE 0.0   
   END                    [ELP %],  
  
   coalesce(sum(pdm.StopsRateLoss),0)         [Rate Loss Events],  
   coalesce(SUM(pdm.SplitRLDowntime),0.0) / 60.0     [Rate Loss Effective Downtime],  
  
   coalesce(  
   CASE    
   WHEN SUM(pdm.ProductionRuntime) > 0.0   
   THEN SUM(pdm.SplitRLDowntime)   
     / SUM(pdm.ProductionRuntime)    
   ELSE 0.0   
   END                      
   ,0.0)                   [Rate Loss %],    
  
   coalesce(SUM(pdm.PaperRuntime),0.0) / 60.0      [Paper Runtime],                       
   coalesce(SUM(pdm.ProductionRuntime),0.0)/ 60.0     [Production Time],  
   coalesce(sum(pdm.PRPolyChangeEvents),0)       [PR/Poly Change Events],  
   coalesce(sum(pdm.PRPolyChangeDowntime),0.0)/60.0    [PR/Poly Change Downtime],  
   0.0                    [Avg PR/Poly Change Time]  
  FROM @PRDTSums_Unit pdm --SplitEvents se  
  JOIN @ProdUnits pu   
  ON pdm.PUId = pu.PUId  
  JOIN @ProdLines pl -- Rev11.33   
  ON pu.PLId = pl.PLId  
  GROUP BY  pl.PLDesc, pu.OrderIndex, pu.CombinedPUDesc  
-- case  
-- when pu.PUDesc like '%block%starv%'   
-- then replace(pu.pudesc,'Blocked/Starved','Reliability')   
-- else pu.PUDesc  
-- end   
  ORDER BY  pl.PLDesc, pu.OrderIndex, pu.CombinedPUDesc  
-- case  
-- when pu.PUDesc like '%block%starv%'   
-- then replace(pu.pudesc,'Blocked/Starved','Reliability')   
-- else pu.PUDesc  
-- end   
  option (keep plan)  
  
  
  update dbo.#UnitStops set  
   [Unscheduled Stops/Day] = --FLD 01-NOV-2007 Rev11.53  
    case  when [Split Uptime] + [Unscheduled Split DT] > 0   
     then ROUND(([Unscheduled Stops] * 1440.0) / ([Split Uptime] + [Unscheduled Split DT]),0)     
     else 0 end,  
   [Planned Availability] =   
    case  when [Split Uptime] + [Unscheduled Split DT] > 0   
     then [Split Uptime] / ([Split Uptime] + [Unscheduled Split DT])  
     else 0 end,  
   [Unplanned MTBF] =   
    case when [Unscheduled Stops] > 0   
     then [Split Uptime] / [Unscheduled Stops]  
     else 0 end,  
   [Unplanned MTTR] =   
    case when [Unscheduled Stops] > 0   
     then [Unscheduled Split DT]/[Unscheduled Stops]  
     else 0 end,  
   [Avg PR/Poly Change Time] =            -- Rev11.29  
    case when [PR/Poly Change Events] > 0        -- Rev11.29  
     then [PR/Poly Change Downtime] / convert(float,[PR/Poly Change Events]) -- Rev11.29  
     else NULL end  
  
  
  SELECT @SQL =   
  case  
  when (SELECT count(*) FROM dbo.#UnitStops with (nolock)) > 65000 then   
  'SELECT ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
  when (SELECT count(*) FROM dbo.#UnitStops with (nolock)) = 0 then   
  'SELECT ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
  else GBDB.dbo.fnLocal_RptTableTranslation('#UnitStops', @LanguageId)  
   + ' order by [Production Line], [OrderIndex], [Master Unit]'  
  end  
  
  -- strip OrderIndex from the returned results  
  if charindex('OrderIndex',left(@SQL,25)) > 5  
  select @SQL = replace(@SQL,substring(@SQL,7,charindex(',',@SQL) -6), ' ')   
  
  execute sp_executesql @SQL   
  
  
  --print 'Result set 3 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  --------------------------------------------------------------------------------------------------------  
  -- Section 45: Results Set #5 - Return the stops result set for the individual Line or Packloop totals.  
  --------------------------------------------------------------------------------------------------------  
  
  INSERT dbo.#LineStops  
  
  
--Rev11.55  
  SELECT case when pl.PackOrLine like '%Pack%'  
    then 'Packloop Total'   
    else 'Line Total' end,  
   ''                    [Master Unit],  
   ''                    [Team],  
   coalesce(SUM(pdm.Stops),0)            [Total Stops],  
   coalesce(SUM(pdm.StopsUnscheduled),0)        [Unscheduled Stops],  
    case    
    when sum(pdm.[StopsPerDayDenomUT]/60.0)   
        + sum(pdm.UnschedSplitDT/60.0) > 0.0   
    then ROUND((sum(pdm.StopsUnscheduled) * 1440.0)   
         / (sum(pdm.[StopsPerDayDenomUT]/60.0)   
          + sum(pdm.UnschedSplitDT/60.0)),0)  
    else 0   
    end                  [Unscheduled Stops/Day],  
   coalesce(SUM(pdm.StopsMinor),0)          [Minor Stops],  
   coalesce(SUM(pdm.StopsEquipFails),0)        [Equipment Failures],  
   coalesce(SUM(pdm.StopsProcessFailures),0)       [Process Failures],  
   coalesce(SUM(pdm.SplitDowntime),0.0) / 60.0      [Split Downtime],  
   coalesce(sum(pdm.UnschedSplitDT),0.0) / 60.0      [Unscheduled Split DT],  
   coalesce(sum(pdm.RawUptime),0.0) / 60.0       [Raw Uptime],  
   coalesce(SUM(pdm.SplitUptime),0.0) / 60.0       [Split Uptime],  
   'N/A'                   [Planned Availability],  
   coalesce(SUM(pdm.Uptime2min),0.0)         [Stops with Uptime <2 Min],  
  
   'N/A'                   [R(2)],     
  
   0.0                    [Unplanned MTBF],  
   0.0                    [Unplanned MTTR],  
   coalesce(SUM(pdm.StopsELP),0)           [ELP Stops],  
   Sum(pdm.ELPMins)/60.0             [ELP Losses (Mins)],  
  
         CASE    
   WHEN SUM(pdm.PaperRuntime) > 0.0   
   THEN SUM(pdm.ELPMins) / SUM(pdm.PaperRuntime)   
   ELSE 0.0   
   END                    [ELP %],  
  
   coalesce(sum(pdm.StopsRateLoss),0)         [Rate Loss Events],  
   coalesce(SUM(pdm.SplitRLDowntime),0.0) / 60.0     [Rate Loss Effective Downtime],  
  
   coalesce(  
   CASE    
   WHEN SUM(pdm.ProductionRuntime) > 0.0   
   THEN SUM(pdm.SplitRLDowntime)   
     / SUM(pdm.ProductionRuntime)    
   ELSE 0.0   
   END                      
   ,0.0)                   [Rate Loss %],    
  
   coalesce(SUM(pdm.PaperRuntime),0.0) / 60.0      [Paper Runtime],                       
   coalesce(SUM(pdm.ProductionRuntime),0.0)/ 60.0     [Production Time],  
   'N/A'                   [PR/Poly Change Events],  
   'N/A'                   [PR/Poly Change Downtime],  
   'N/A'                   [Avg PR/Poly Change Time]  
  FROM @PRDTSums_Line pdm --SplitEvents se  
  JOIN @ProdLines pl -- Rev11.33   
  ON pdm.PLId = pl.PLId  
  GROUP BY pl.PLDesc, pl.plid, pl.packorline  
  ORDER BY pl.PLDesc, pl.plid  
  option (keep plan)  
  
  
  update dbo.#LineStops set  
   [Unplanned MTBF] =   
    case when [Unscheduled Stops] > 0   
     then [Split Uptime] / [Unscheduled Stops]  
     else 0 end,  
   [Unplanned MTTR] =   
    case when [Unscheduled Stops] > 0   
     then [Unscheduled Split DT]/[Unscheduled Stops]  
     else 0 end--,  
  
  
  --print 'Result set 4 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  -------------------------------------------------------------------------------------------------  
  -- Section 46: Results Set #6 - Return the stops result set for totals for Lines and Packloops.  
  -------------------------------------------------------------------------------------------------  
  
  INSERT dbo.#LinePackStops  
  SELECT [Production Line],  
   '' [Master Unit],  
   '' [Team],  
   SUM([Total Stops]) [Total Stops],  
   SUM([Unscheduled Stops]) [Unscheduled Stops],  
   --sum([Unscheduled Stops/Shift]) [Unscheduled Stops/Shift],  
   sum([Unscheduled Stops/Day]) [Unscheduled Stops/Day],  --FLD 01-NOV-2007 Rev11.53  
   SUM([Minor Stops]) [Minor Stops],  
   SUM([Equipment Failures]) [Equipment Failures],  
   SUM([Process Failures]) [Process Failures],  
   SUM([Split Downtime]) [Split Downtime],  
   sum([Unscheduled Split DT]) [Unscheduled Split DT],  
   sum([Raw Uptime]) [Raw Uptime],  
   sum([Split Uptime]) [Split Uptime],  
   'N/A' [Planned Availability],  
   sum([Stops with Uptime <2 Min]) [Stops with Uptime <2 Min],  
   'N/A' [R(2)],  
   0 [Unplanned MTBF],  
   0 [Unplanned MTTR],  
   SUM([ELP Stops]) [ELP Stops],  
  
   SUM([ELP Losses (Mins)])[ELP Losses (Mins)],  
   CASE WHEN SUM([Paper Runtime]) > 0.0   
              THEN SUM([ELP Losses (Mins)]) / SUM([Paper Runtime])  
        ELSE 0 END [ELP %],  
   SUM([Rate Loss Events]) [Rate Loss Events],  
   SUM([Rate Loss Effective Downtime]) [Rate Loss Effective Downtime],  
   CASE WHEN SUM([Production Time]) > 0.0  
              THEN SUM([Rate Loss Effective Downtime]) / SUM([Production Time])  
        ELSE 0 END [Rate Loss %],  
         SUM([Paper Runtime]) [Paper Runtime],    
         SUM([Production Time]) [Production Time],    
   'N/A' [PR/Poly Change Events],  -- Rev11.29  
   'N/A' [PR/Poly Change Downtime],  -- Rev11.29  
   'N/A' [Avg PR/Poly Change Time]  -- Rev11.29  
  FROM dbo.#LineStops with (nolock)  
  group by [Production Line]  
  order by [Production Line]  
  option (keep plan)  
  
  update dbo.#LinePackStops set  
   [Group Type] = REPLACE([Group Type], ' Total','s Total'),  
   [Unplanned MTBF] =   
    case when [Unscheduled Stops] > 0   
     then [Split Uptime] / [Unscheduled Stops]  
     else 0 end,  
   [Unplanned MTTR] =   
    case when [Unscheduled Stops] > 0   
     then [Unscheduled Split DT]/[Unscheduled Stops]  
     else 0 end--,  
  
                  
      update dbo.#LineStops set  
   [Production Line] = COALESCE((  
     SELECT translated_text   
     FROM dbo.local_pg_translations with (nolock)  
     WHERE language_id = @LanguageID  
     and global_text = [Production Line]  
     ), [Production Line])  
     
  update dbo.#LinePackStops set  
   [Group Type] =  COALESCE((  
     SELECT translated_text  
     FROM dbo.local_pg_translations with (nolock)  
     WHERE language_id = @LanguageID  
     and global_text = [Group Type]  
     ), [Group Type])   
    
  
  SELECT @SQL =   
  case  
  when (SELECT count(*) FROM dbo.#LineStops with (nolock)) > 65000 then   
  'SELECT ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
  when (SELECT count(*) FROM dbo.#LineStops with (nolock)) = 0 then   
  'SELECT ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
  else GBDB.dbo.fnLocal_RptTableTranslation('#LineStops', @LanguageId)  
  end  
  
  execute sp_executesql @SQL   
  
  
  SELECT @SQL =   
  case  
  when (SELECT count(*) FROM dbo.#LinePackStops with (nolock)) > 65000 then   
  'SELECT ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
  when (SELECT count(*) FROM dbo.#LinePackStops with (nolock)) = 0 then   
  'SELECT ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
  else GBDB.dbo.fnLocal_RptTableTranslation('#LinePackStops', @LanguageId)  
   + ' order by [Group Type]'  
  end  
  
  execute sp_executesql @SQL   
  
  
  --print 'Result set 5 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  -----------------------------------------------------------------------------  
  -- Section 47: Results Set #7 - Return the stops result set for Overall.  
  -----------------------------------------------------------------------------  
  
  INSERT dbo.#OverallStops  
  SELECT 'Overall Totals' [Overall Totals],  
   '' [Master Unit],  
   '' [Team],  
   SUM(lps.[Total Stops]) [Total Stops],  
   SUM(lps.[Unscheduled Stops]) [Unscheduled Stops],  
   --sum(lps.[Unscheduled Stops/Shift]) [Unscheduled Stops/Shift],  
   sum(lps.[Unscheduled Stops/Day]) [Unscheduled Stops/Day],  
   SUM(lps.[Minor Stops]) [Minor Stops],  
   SUM(lps.[Equipment Failures]) [Equipment Failures],  
   SUM(lps.[Process Failures]) [Process Failures],  
   sum(lps.[Split Downtime]) [Split Downtime],  
   sum(lps.[Unscheduled Split DT]) [Unscheduled Split DT],  
   'N/A' [Raw Uptime],  
   'N/A' [Split Uptime],  
   'N/A' [Planned Availability],  
   sum([Stops with Uptime <2 Min]) [Stops with Uptime <2 Min],    
   'N/A' [R(2)],  
   'N/A' [Unplanned MTBF],  
   'N/A' [Unplanned MTTR],  
   SUM(lps.[ELP Stops]) [ELP Stops],  
  
   SUM(lps.[ELP Losses (Mins)]) [ELP Losses (Mins)],  
   CASE WHEN SUM(lps.[Paper Runtime]) > 0.0   
              THEN SUM(lps.[ELP Losses (Mins)]) / SUM(lps.[Paper Runtime])  
        ELSE 0 END [ELP %],  
   SUM(lps.[Rate Loss Events]) [Rate Loss Events],  
   SUM(lps.[Rate Loss Effective Downtime]) [Rate Loss Effective Downtime],  
   CASE WHEN SUM(lps.[Production Time]) > 0.0  
              THEN SUM(lps.[Rate Loss Effective Downtime]) / SUM(lps.[Production Time])  
        ELSE 0 END [Rate Loss %],  
  
         SUM(lps.[Paper Runtime]) [Paper Runtime],    
         SUM(lps.[Production Time]) [Production Time],   
   'N/A' [PR/Poly Change Events],  -- Rev11.29  
   'N/A' [PR/Poly Change Downtime],  -- Rev11.29  
   'N/A' [Avg PR/Poly Change Time]  -- Rev11.29  
  FROM dbo.#LinePackStops lps with (nolock)  
  option (keep plan)  
    
  update dbo.#OverallStops set  
   [Overall Totals] = COALESCE((  
     SELECT translated_text  
     FROM dbo.local_pg_translations with (nolock)  
     WHERE language_id = @LanguageID  
     and global_text = [Overall Totals]  
     ), [Overall Totals])--,  
  
  
  SELECT @SQL =   
  case  
  when (SELECT count(*) FROM dbo.#OverallStops with (nolock)) > 65000 then   
  'SELECT ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
  when (SELECT count(*) FROM dbo.#OverallStops with (nolock)) = 0 then   
  'SELECT ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
  else GBDB.dbo.fnLocal_RptTableTranslation('#OverallStops', @LanguageId)  
  end  
  
  execute sp_executesql @SQL   
  
  
  --print 'Result set 6 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  -------------------------------------------------------------------------------------------  
  -- Section 48: Results Set #8 - Return the production result set by Line / Team / Product.  
  -------------------------------------------------------------------------------------------  
  
  INSERT dbo.#ProdProduction  
  SELECT  pl.PLDesc [Production Line],  
   prs.Team [Team],  
   ps.Prod_Code [Product],  
   SUM(prs.ProductionRuntime) [Production Time],  
   CASE WHEN SUM(prs.ProductionRuntime) > 0   
        THEN convert(integer,round(SUM(prs.ActualUnits)   
       * ((24 * 60) / SUM(prs.ProductionRuntime)),0))  
        ELSE 0 END [Avg Stat CLD],  
   CASE WHEN SUM(CONVERT(FLOAT,prs.TargetUnits)) > 0   
        THEN SUM(CASE  WHEN prs.TargetUnits IS NOT NULL     
          THEN CONVERT(FLOAT,prs.ActualUnits)   
          ELSE 0            
          END)              
      / SUM(CONVERT(FLOAT,prs.TargetUnits))  
      ELSE NULL END [CVPR %],   
   CASE WHEN SUM(CONVERT(FLOAT,prs.OperationsTargetUnits)) > 0   
        THEN SUM(CASE  WHEN prs.OperationsTargetUnits IS NOT NULL   
          THEN CONVERT(FLOAT,prs.ActualUnits)     
          ELSE 0              
          END)                
      / SUM(CONVERT(FLOAT,prs.OperationsTargetUnits))  
      ELSE NULL END [Operations Efficiency %],   
   CONVERT(INTEGER,SUM(prs.TotalUnits)) [Total Units],  
   CONVERT(INTEGER,SUM(prs.GoodUnits)) [Good Units],  
   CONVERT(INTEGER,SUM(prs.RejectUnits)) [Reject Units],  
   CASE WHEN CONVERT(FLOAT,SUM(prs.TotalUnits)) > 0   
        THEN CONVERT(FLOAT,SUM(prs.RejectUnits))   
      / CONVERT(FLOAT,SUM(prs.TotalUnits))  
        ELSE 0 END [Unit Broke %],  
   CONVERT(INTEGER,SUM(prs.ActualUnits)) [Actual Stat Cases],  
   CONVERT(INTEGER,SUM(prs.TargetUnits)) [Reliability Target Stat Cases],  
   CONVERT(INTEGER,SUM(prs.OperationsTargetUnits)) [Operations Target Stat Cases],  
   CONVERT(INTEGER,SUM(prs.IdealUnits)) [Ideal Stat Cases],  
  
   -- Rev11.36  
   case  
   when  SUM(prs.LineSpeedAvg * prs.SplitUptime) > 0.0  
   then  Convert(Float, SUM(prs.LineSpeedAvg * prs.SplitUptime))   
     / SUM (  
       case  
       when prs.LineSpeedAvg > 0.0  
       then convert(float,prs.SplitUptime)  
       else 0.0  
       end  
       )  
   else null  
   end [Line Speed Avg],  
  
   -- Rev11.36  
   case  
   when  SUM(prs.LineSpeedTarget * prs.ProductionRuntime) > 0.0   
   then  Convert(Float, SUM(prs.LineSpeedTarget * prs.ProductionRuntime))   
     / SUM (  
       case   
       when LineSpeedTarget > 0.0  
       then convert(float,prs.ProductionRuntime)  
       else 0.0  
       end  
       )  
   else null  
   end [Target Line Speed],  
  
   -- Rev11.36  
   case  
   when  SUM(prs.LineSpeedIdeal * prs.ProductionRuntime) > 0   
   then  Convert(Float, SUM(prs.LineSpeedIdeal * prs.ProductionRuntime))   
     / SUM (  
       case  
       when LineSpeedIdeal > 0.0  
       then convert(float,prs.ProductionRuntime)  
       else 0.0  
       end  
       )  
   else null  
   end [Ideal Line Speed],  
  
   CASE WHEN SUM(CONVERT(FLOAT,prs.IdealUnits)) > 0.0       
      THEN SUM(CASE  WHEN prs.IdealUnits IS NOT NULL    
          THEN CONVERT(FLOAT,prs.ActualUnits)   
          ELSE 0.0            
          END)              
      / SUM(CONVERT(FLOAT,prs.IdealUnits))  
        ELSE NULL END [CVTI %]  
  FROM @ProdRecords prs  
  LEFT JOIN @ProdLines pl --with (nolock) -- Rev11.33   
  ON prs.PLId = pl.PLId  
  LEFT JOIN @products ps   
  ON prs.ProdId = ps.Prod_Id  
  WHERE pl.PackOrLine <> 'Pack'  
  and (charindex('|' + LineStatus + '|', '|' + @LineStatusList + '|') > 0  
   or @LineStatusList = 'All')   
  GROUP BY pl.PLDesc, pl.PackOrLine, prs.Team, ps.Prod_Code, prs.LineSpeedTarget, prs.LineSpeedIdeal  
  ORDER BY pl.PLDesc, pl.PackOrLine, prs.Team, ps.Prod_Code  
  option (keep plan)  
  
  SELECT @SQL =   
  case  
  when (SELECT count(*) FROM dbo.#ProdProduction with (nolock)) > 65000 then   
  'SELECT ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
  when (SELECT count(*) FROM dbo.#ProdProduction with (nolock)) = 0 then   
  'SELECT ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
  else GBDB.dbo.fnLocal_RptTableTranslation('#ProdProduction', @LanguageId)  
   + ' order by [Production Line], [Team], [Product]'  
  end  
  
  execute sp_executesql @SQL   
  
  
  --print 'Result set 7 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  -----------------------------------------------------------------------------  
  -- Section 49: Results Set #9 - Return the production result set for Line.  
  -----------------------------------------------------------------------------  
  
  INSERT dbo.#LineProduction  
  SELECT  pl.PLDesc [Production Line],  
   '' [Team],  
   '' [Product],  
   SUM(prs.ProductionRuntime) [Production Time],  
   CASE WHEN SUM(prs.ProductionRuntime) > 0   
        THEN convert(integer,round(SUM(prs.ActualUnits)   
              * ((24.0 * 60.0) / SUM(prs.ProductionRuntime)),0))  
        ELSE 0 END [Avg Stat CLD],  
   CASE WHEN SUM(CONVERT(FLOAT,prs.TargetUnits)) > 0   
        THEN SUM(CASE  WHEN prs.TargetUnits IS NOT NULL     
          THEN CONVERT(FLOAT,prs.ActualUnits)   
          ELSE 0            
          END)              
      / SUM(CONVERT(FLOAT,prs.TargetUnits))  
      ELSE NULL END [CVPR %],   
   CASE WHEN SUM(CONVERT(FLOAT,prs.OperationsTargetUnits)) > 0   
        THEN SUM(CASE  WHEN prs.OperationsTargetUnits IS NOT NULL   
          THEN CONVERT(FLOAT,prs.ActualUnits)     
          ELSE 0              
          END)                
      / SUM(CONVERT(FLOAT,prs.OperationsTargetUnits))  
      ELSE NULL END [Operations Efficiency %],   
   CONVERT(INTEGER,SUM(prs.TotalUnits)) [Total Units],  
   CONVERT(INTEGER,SUM(prs.GoodUnits)) [Good Units],  
   CONVERT(INTEGER,SUM(prs.RejectUnits)) [Reject Units],  
   CASE WHEN CONVERT(FLOAT,SUM(prs.TotalUnits)) > 0   
        THEN CONVERT(FLOAT,SUM(prs.RejectUnits))   
      / CONVERT(FLOAT,SUM(prs.TotalUnits))  
        ELSE 0 END [Unit Broke %],  
   CONVERT(INTEGER,SUM(prs.ActualUnits)) [Actual Stat Cases],  
   CONVERT(INTEGER,SUM(prs.TargetUnits)) [Reliability Target Stat Cases],  
   CONVERT(INTEGER,SUM(prs.OperationsTargetUnits)) [Operations Target Stat Cases],  
   CONVERT(INTEGER,SUM(prs.IdealUnits)) [Ideal Stat Cases],  
  
   -- Rev11.36  
   case  
   when  SUM(prs.LineSpeedAvg * prs.SplitUptime) > 0.0  
   then  Convert(Float, SUM(prs.LineSpeedAvg * prs.SplitUptime))   
     / SUM (  
       case  
       when prs.LineSpeedAvg > 0.0  
       then convert(float,prs.SplitUptime)  
       else 0.0  
       end  
       )  
   else null  
   end [Line Speed Avg],  
  
   -- Rev11.36  
   case  
   when  SUM(prs.LineSpeedTarget * prs.ProductionRuntime) > 0.0   
   then  Convert(Float, SUM(prs.LineSpeedTarget * prs.ProductionRuntime))   
     / SUM (  
       case   
       when LineSpeedTarget > 0.0  
       then convert(float,prs.ProductionRuntime)  
       else 0.0  
       end  
       )  
   else null  
   end [Target Line Speed],  
  
   -- Rev11.36  
   case  
   when  SUM(prs.LineSpeedIdeal * prs.ProductionRuntime) > 0   
   then  Convert(Float, SUM(prs.LineSpeedIdeal * prs.ProductionRuntime))   
     / SUM (  
       case  
       when LineSpeedIdeal > 0.0  
       then convert(float,prs.ProductionRuntime)  
       else 0.0  
       end  
       )  
   else null  
   end [Ideal Line Speed],  
  
   CASE WHEN SUM(CONVERT(FLOAT,prs.IdealUnits)) > 0.0   
      THEN SUM(CASE  WHEN prs.IdealUnits IS NOT NULL    
          THEN CONVERT(FLOAT,prs.ActualUnits)   
          ELSE 0.0    
          END)              
      / SUM(CONVERT(FLOAT,prs.IdealUnits))  
        ELSE NULL END [CVTI %]  
  
  FROM @ProdRecords prs  
  LEFT JOIN @ProdLines pl --with (nolock) -- Rev11.33   
  ON prs.PLId = pl.PLId  
  WHERE pl.PackOrLine <> 'Pack'  
  and (charindex('|' + LineStatus + '|', '|' + @LineStatusList + '|') > 0  
   or @LineStatusList = 'All')   
  GROUP BY pl.PLDesc, pl.PackOrLine  
  ORDER BY pl.PLDesc, pl.PackOrLine  
  option (keep plan)  
  
  
  SELECT @SQL =   
  case  
  when (SELECT count(*) FROM dbo.#LineProduction with (nolock)) > 65000 then   
  'SELECT ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
  when (SELECT count(*) FROM dbo.#LineProduction with (nolock)) = 0 then   
  'SELECT ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
  else GBDB.dbo.fnLocal_RptTableTranslation('#LineProduction', @LanguageId)  
   + ' order by [Production Line]'  
  end  
  
  execute sp_executesql @SQL   
  
  
  --print 'Result set 8 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  -----------------------------------------------------------------------------  
  -- Section 50: Results Set #10 - Return the production result set for Overall.  
  -----------------------------------------------------------------------------  
  
  INSERT dbo.#OverallProduction  
  SELECT  'Overall Totals' [Overall Totals],  
   '' [Team],  
   '' [Product],  
   SUM(prs.ProductionRuntime) [Production Time],  
   CASE WHEN SUM(prs.ProductionRuntime) > 0   
        THEN CONVERT(INTEGER,round(SUM(prs.ActualUnits)   
       * ((24 * 60) / SUM(prs.ProductionRuntime)),0))  
        ELSE 0 END [Avg Stat CLD],  
   CASE WHEN SUM(CONVERT(FLOAT,prs.TargetUnits)) > 0   
        THEN SUM(CASE  WHEN prs.TargetUnits IS NOT NULL     
          THEN CONVERT(FLOAT,prs.ActualUnits)   
          ELSE 0            
          END)              
      / SUM(CONVERT(FLOAT,prs.TargetUnits))  
      ELSE NULL END [CVPR %], --FLD Rev9.11  
   CASE WHEN SUM(CONVERT(FLOAT,prs.OperationsTargetUnits)) > 0   
        THEN SUM(CASE  WHEN prs.OperationsTargetUnits IS NOT NULL   
          THEN CONVERT(FLOAT,prs.ActualUnits)     
          ELSE 0              
          END)                
      / SUM(CONVERT(FLOAT,prs.OperationsTargetUnits))  
      ELSE NULL END [Operations Efficiency %],   
   CONVERT(INTEGER,SUM(prs.TotalUnits)) [Total Units],  
   CONVERT(INTEGER,SUM(prs.GoodUnits)) [Good Units],  
   CONVERT(INTEGER,SUM(prs.RejectUnits)) [Reject Units],  
  
   CASE WHEN CONVERT(FLOAT,SUM(prs.TotalUnits)) > 0   
        THEN CONVERT(FLOAT,SUM(prs.RejectUnits))   
      / CONVERT(FLOAT,SUM(prs.TotalUnits))  
        ELSE 0 END [Unit Broke %],  
   CONVERT(INTEGER,SUM(prs.ActualUnits)) [Actual Stat Cases],  
   CONVERT(INTEGER,SUM(prs.TargetUnits)) [Reliability Target Stat Cases],  
   CONVERT(INTEGER,SUM(prs.OperationsTargetUnits)) [Operations Target Stat Cases],  
   CONVERT(INTEGER,SUM(prs.IdealUnits)) [Ideal Stat Cases],  
  
   -- Rev11.36  
   case  
   when  SUM(prs.LineSpeedAvg * prs.SplitUptime) > 0.0  
   then  Convert(Float, SUM(prs.LineSpeedAvg * prs.SplitUptime))   
     / SUM (  
       case  
       when prs.LineSpeedAvg > 0.0  
       then convert(float,prs.SplitUptime)  
       else 0.0  
       end  
       )  
   else null  
   end [Line Speed Avg],  
  
   -- Rev11.36  
   case  
   when  SUM(prs.LineSpeedTarget * prs.ProductionRuntime) > 0.0   
   then  Convert(Float, SUM(prs.LineSpeedTarget * prs.ProductionRuntime))   
     / SUM (  
       case   
       when LineSpeedTarget > 0.0  
       then convert(float,prs.ProductionRuntime)  
       else 0.0  
       end  
       )  
   else null  
   end [Target Line Speed],  
  
   -- Rev11.36  
   case  
   when  SUM(prs.LineSpeedIdeal * prs.ProductionRuntime) > 0   
   then  Convert(Float, SUM(prs.LineSpeedIdeal * prs.ProductionRuntime))   
     / SUM (  
       case  
       when LineSpeedIdeal > 0.0  
       then convert(float,prs.ProductionRuntime)  
       else 0.0  
       end  
       )  
   else null  
   end [Ideal Line Speed],  
  
   CASE WHEN SUM(CONVERT(FLOAT,prs.IdealUnits)) > 0.0   
      THEN SUM(CASE  WHEN prs.IdealUnits IS NOT NULL    
          THEN CONVERT(FLOAT,prs.ActualUnits)   
          ELSE 0.0    
          END)              
      / SUM(CONVERT(FLOAT,prs.IdealUnits))  
        ELSE NULL END [CVTI %]  
  FROM @ProdRecords prs  
  LEFT JOIN @ProdLines pl --with (nolock) -- Rev11.33  
  ON prs.PLId = pl.PLId  
  WHERE pl.PackOrLine <> 'Pack'  
  and (charindex('|' + LineStatus + '|', '|' + @LineStatusList + '|') > 0  
   or @LineStatusList = 'All')   
  option (keep plan)  
  
  update dbo.#OverallProduction set  
   [Overall Totals] = COALESCE((  
     SELECT translated_text  
     FROM dbo.local_pg_translations with (nolock)  
     WHERE language_id = @LanguageID  
     and global_text = [Overall Totals]  
     ), [Overall Totals])   
  
  
  SELECT @SQL =   
  case  
  when (SELECT count(*) FROM dbo.#OverallProduction with (nolock)) > 65000 then   
  'SELECT ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
  when (SELECT count(*) FROM dbo.#OverallProduction with (nolock)) = 0 then   
  'SELECT ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
  else GBDB.dbo.fnLocal_RptTableTranslation('#OverallProduction', @LanguageId)  
  end  
  
  execute sp_executesql @SQL   
  
  
  --print 'Result set 9 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  -----------------------------------------------------------------------------  
  -- Section 51: Results Set #11 -  Return the production result set for   
  --     Packing Production Units [Pack Prod worksheet].  
  -----------------------------------------------------------------------------  
  
  INSERT dbo.#PackProduction  
  SELECT pl.PLDesc [Production Line],  
   pu.PUDesc [Master Unit],  
   cs.Crew_Desc [Team],  
   ps.Prod_Code [Product],  
   t.UOM [UOM],  
   SUM(convert(int,Value)) [Good Units]  
  FROM dbo.#PackTests t with (nolock)  
  left JOIN @ProdLines pl --with (nolock) -- Rev11.33   
  ON t.PLId = pl.PLId  
  left JOIN @ProdUnitsPack pu  
  ON t.PUId = pu.PUId  
  LEFT join @products ps   
  ON t.ProdId = ps.Prod_Id  
  LEFT JOIN dbo.Crew_Schedule cs with (nolock)  
  ON pu.ScheduleUnit = cs.PU_Id  
  AND t.SampleTime >= cs.Start_Time  
  AND t.SampleTime < cs.End_Time  
  GROUP BY pl.PLDesc, pu.PUDesc, cs.Crew_Desc, t.UOM, ps.Prod_Code  
  ORDER BY pl.PLDesc, pu.PUDesc, cs.Crew_Desc, t.UOM, ps.Prod_Code  
  option (keep plan)  
  
  SELECT @SQL =   
  case  
  when (SELECT count(*) FROM dbo.#PackProduction with (nolock)) > 65000 then   
  'SELECT ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
  when (SELECT count(*) FROM dbo.#PackProduction with (nolock)) = 0 then   
  'SELECT ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
  else GBDB.dbo.fnLocal_RptTableTranslation('#PackProduction', @LanguageId)  
   + ' order by [Production Line], [Master Unit], [Team], [UOM], [Product]'  
  end  
  
  --print 'Resulst set 9 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  execute sp_executesql @SQL   
  
  END  --of the @IncludeTeam = 1 section  
 ELSE  
  BEGIN --of the @IncludeTeam <> 1 section  
  
  ------------------------------------------------------------------------------------  
  -- Section 52: Results Set #3 - Return the stops result set for Line / Master Unit.    
  ------------------------------------------------------------------------------------  
  
  --print 'Result set 10 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  ----------------------------------------------------------------------------  
  -- NOTE:  From Total Stops through Production Time, this SELECT code is the    
  --        same as that in the @IncludeTeam = 1 section.  
  -----------------------------------------------------------------------------  
  
  INSERT dbo.#UnitStops2  
  
--Rev11.55  
  SELECT   
   pu.OrderIndex                [OrderIndex],  
   pl.PLDesc                  [Production Line],  
  
-- case  
-- when pu.PUDesc like '%block%starv%'   
-- then replace(pu.pudesc,'Blocked/Starved','Reliability')   
-- else pu.PUDesc  
-- end [Master Unit],  
  
   pu.CombinedPUDesc               [Master Unit],     
  
   coalesce(SUM(pdm.Stops),0)            [Total Stops],  
   coalesce(SUM(pdm.StopsUnscheduled),0)        [Unscheduled Stops],  
   0                     [Unscheduled Stops/Day],  
   coalesce(SUM(pdm.StopsMinor),0)          [Minor Stops],  
   coalesce(SUM(pdm.StopsEquipFails),0)        [Equipment Failures],  
   coalesce(SUM(pdm.StopsProcessFailures),0)       [Process Failures],  
   coalesce(SUM(pdm.SplitDowntime),0.0) / 60.0      [Split Downtime],  
   coalesce(sum(pdm.UnschedSplitDT),0.0) / 60.0      [Unscheduled Split DT],  
--   coalesce(sum(pdm.RawUptime),0.0) / 60.0       [Raw Uptime],  
--   coalesce(SUM(pdm.SplitUptime),0.0) / 60.0       [Split Uptime],  
  
   case  
   when   
    sum(  
     case  
     when pu.pudesc like '%reliability%'  
     then pdm.RawUptime  
     else 0.0  
     end  
     )  
    >  
    sum(  
     case  
     when pu.pudesc like '%block%starv%'  
     then pdm.SplitDowntime  
     else 0.0  
     end  
     )   
   then   
    (  
    sum(  
     case  
     when pu.pudesc like '%reliability%'  
     then pdm.RawUptime  
     else 0.0  
     end  
     )  
    -  
    sum(  
     case  
     when pu.pudesc like '%block%starv%'  
     then pdm.SplitDowntime  
     else 0.0  
     end  
     )   
    )/60.0  
   else 0.0  
   end                   [Raw Uptime],  
  
   case  
   when   
    sum(  
     case  
     when pu.pudesc like '%reliability%'  
     then pdm.SplitUptime  
     else 0.0  
     end  
     )  
    >  
    sum(  
     case  
     when pu.pudesc like '%block%starv%'  
     then pdm.SplitDowntime  
     else 0.0  
     end  
     )   
   then   
    (  
    sum(  
     case  
     when pu.pudesc like '%reliability%'  
     then pdm.SplitUptime  
     else 0.0  
     end  
     )  
    -  
    sum(  
     case  
     when pu.pudesc like '%block%starv%'  
     then pdm.SplitDowntime  
     else 0.0  
     end  
     )   
    )/60.0  
   else 0.0  
   end                    [Split Uptime],  
  
   0.0                    [Planned Availability],  
   coalesce(SUM(pdm.Uptime2min),0.0)         [Stops with Uptime <2 Min],  
  
   coalesce(     
   CASE   
   WHEN SUM(pdm.R2Denominator) > 0   
   THEN ROUND(1 - (SUM(pdm.R2Numerator)   
     /SUM(pdm.R2Denominator)), 2)   
     ELSE 0.0   
   END                      
   ,0.0)                   [R(2)],     
  
   0.0                    [Unplanned MTBF],  
   0.0                    [Unplanned MTTR],  
   coalesce(SUM(pdm.StopsELP),0)           [ELP Stops],  
   Sum(pdm.ELPMins)/60.0             [ELP Losses (Mins)],  
  
        CASE    
   WHEN SUM(pdm.PaperRuntime) > 0.0   
   THEN SUM(pdm.ELPMins) / SUM(pdm.PaperRuntime)   
   ELSE 0.0   
   END                    [ELP %],  
  
   coalesce(sum(pdm.StopsRateLoss),0)         [Rate Loss Events],  
   coalesce(SUM(pdm.SplitRLDowntime),0.0) / 60.0     [Rate Loss Effective Downtime],  
  
   coalesce(  
   CASE    
   WHEN SUM(pdm.ProductionRuntime) > 0.0   
   THEN SUM(pdm.SplitRLDowntime)   
     / SUM(pdm.ProductionRuntime)    
   ELSE 0.0   
   END                      
   ,0.0)                   [Rate Loss %],    
  
   coalesce(SUM(pdm.PaperRuntime),0.0) / 60.0      [Paper Runtime],                       
   coalesce(SUM(pdm.ProductionRuntime),0.0)/ 60.0     [Production Time],  
   coalesce(sum(pdm.PRPolyChangeEvents),0)       [PR/Poly Change Events],  
   coalesce(sum(pdm.PRPolyChangeDowntime),0.0)/60.0    [PR/Poly Change Downtime],  
   0.0                    [Avg PR/Poly Change Time]  
  
  FROM @PRDTSums_Unit pdm --SplitEvents se  
  JOIN @ProdUnits pu   
  ON pdm.PUId = pu.PUId  
  JOIN @ProdLines pl -- Rev11.33   
  ON pu.PLId = pl.PLId  
  GROUP BY  pl.PLDesc, pu.OrderIndex, pu.CombinedPUDesc  
-- case  
-- when pu.PUDesc like '%block%starv%'   
-- then replace(pu.pudesc,'Blocked/Starved','Reliability')   
-- else pu.PUDesc  
-- end   
  ORDER BY  pl.PLDesc, pu.OrderIndex, pu.CombinedPUDesc  
-- case  
-- when pu.PUDesc like '%block%starv%'   
-- then replace(pu.pudesc,'Blocked/Starved','Reliability')   
-- else pu.PUDesc  
-- end   
  option (keep plan)  
  
  update dbo.#UnitStops2 set  
   [Unscheduled Stops/Day] = --FLD 01-NOV-2007 Rev11.53  
    case  when [Split Uptime] + [Unscheduled Split DT] > 0   
     then ROUND(([Unscheduled Stops] * 1440.0) / ([Split Uptime] + [Unscheduled Split DT]),0)      
     else 0 end,  
   [Planned Availability] =   
    case  when [Split Uptime] + [Unscheduled Split DT] > 0   
     then [Split Uptime] / ([Split Uptime] + [Unscheduled Split DT])  
     else 0 end,  
   [Unplanned MTBF] =   
    case when [Unscheduled Stops] > 0   
     then [Split Uptime] / [Unscheduled Stops]  
     else 0 end,  
   [Unplanned MTTR] =   
    case when [Unscheduled Stops] > 0   
     then [Unscheduled Split DT]/[Unscheduled Stops]  
     else 0 end,  
   [Avg PR/Poly Change Time] =            -- Rev11.29  
    case when [PR/Poly Change Events] > 0        -- Rev11.29  
     then [PR/Poly Change Downtime] / convert(float,[PR/Poly Change Events]) -- Rev11.29  
     else NULL end  
  
  
  SELECT @SQL =   
  case  
  when (SELECT count(*) FROM dbo.#UnitStops2 with (nolock)) > 65000 then   
  'SELECT ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
  when (SELECT count(*) FROM dbo.#UnitStops2 with (nolock)) = 0 then   
  'SELECT ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
  else GBDB.dbo.fnLocal_RptTableTranslation('#UnitStops2', @LanguageId)  
   + ' order by [Production Line], [OrderIndex], [Master Unit]'  
  end  
  
  -- strip OrderIndex from the returned results  
  if charindex('OrderIndex',left(@SQL,25)) > 5  
  select @SQL = replace(@SQL,substring(@SQL,7,charindex(',',@SQL) -6), ' ')   
  
  execute sp_executesql @SQL   
  
  
  --print 'Result set 11 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  -----------------------------------------------------------------------------------------  
  -- Section 53: Results Set #4 - Return a blank Result Set to keep the number of   
  -- result sets standard.    
  -----------------------------------------------------------------------------------------  
  
  ----------------------------------------------------------------------------  
  -- This simplifies the Excel template programming.  
  -- This would be the stops result set for totals by Line / Master Unit if   
  -- @IncludeTeam = 1.  
  -----------------------------------------------------------------------------  
  
  SELECT '' [Blank]  
  
  ----------------------------------------------------------------------------------------  
  -- Section 54: Results Set #5 - Return the stops result set for the individual Line or   
  -- Packloop totals.  
  ----------------------------------------------------------------------------------------  
  
  -----------------------------------------------------------------------------  
  -- NOTE:  From Total Stops through Production Time, this SELECT code is the   
  --        same as that in the @IncludeTeam = 1 section.  
  -----------------------------------------------------------------------------  
  
  INSERT dbo.#LineStops2  
  
--Rev11.55  
  SELECT case  when  pl.PackOrLine like '%Pack%'  
    then 'Packloop Total'   
    else 'Line Total' end,  
   ''                    [Master Unit],  
   coalesce(SUM(pdm.Stops),0)            [Total Stops],  
   coalesce(SUM(pdm.StopsUnscheduled),0)        [Unscheduled Stops],  
--   0                    [Unscheduled Stops/Day],  
    case    
    when sum(pdm.[StopsPerDayDenomUT]/60.0)   
        + sum(pdm.UnschedSplitDT/60.0) > 0.0   
    then ROUND((sum(pdm.StopsUnscheduled) * 1440.0)   
         / (sum(pdm.[StopsPerDayDenomUT]/60.0)   
          + sum(pdm.UnschedSplitDT/60.0)),0)  
    else 0   
    end                  [Unscheduled Stops/Day],  
   coalesce(SUM(pdm.StopsMinor),0)          [Minor Stops],  
   coalesce(SUM(pdm.StopsEquipFails),0)        [Equipment Failures],  
   coalesce(SUM(pdm.StopsProcessFailures),0)       [Process Failures],  
   coalesce(SUM(pdm.SplitDowntime),0.0) / 60.0      [Split Downtime],  
   coalesce(sum(pdm.UnschedSplitDT),0.0) / 60.0      [Unscheduled Split DT],  
   coalesce(sum(pdm.RawUptime),0.0) / 60.0       [Raw Uptime],  
   coalesce(SUM(pdm.SplitUptime),0.0) / 60.0       [Split Uptime],  
   'N/A'                   [Planned Availability],  
   coalesce(SUM(pdm.Uptime2min),0.0)         [Stops with Uptime <2 Min],  
  
   'N/A'                   [R(2)],     
  
   0.0                    [Unplanned MTBF],  
   0.0                    [Unplanned MTTR],  
   coalesce(SUM(pdm.StopsELP),0)           [ELP Stops],  
   Sum(pdm.ELPMins)/60.0             [ELP Losses (Mins)],  
  
         CASE    
   WHEN SUM(pdm.PaperRuntime) > 0.0   
   THEN SUM(pdm.ELPMins) / SUM(pdm.PaperRuntime)   
   ELSE 0.0   
   END                    [ELP %],  
  
   coalesce(sum(pdm.StopsRateLoss),0)         [Rate Loss Events],  
   coalesce(SUM(pdm.SplitRLDowntime),0.0) / 60.0     [Rate Loss Effective Downtime],  
  
   coalesce(  
   CASE    
   WHEN SUM(pdm.ProductionRuntime) > 0.0   
   THEN SUM(pdm.SplitRLDowntime)   
     / SUM(pdm.ProductionRuntime)    
   ELSE 0.0   
   END                      
   ,0.0)                   [Rate Loss %],    
  
   coalesce(SUM(pdm.PaperRuntime),0.0) / 60.0      [Paper Runtime],                       
   coalesce(SUM(pdm.ProductionRuntime),0.0)/ 60.0     [Production Time],  
   'N/A'                   [PR/Poly Change Events],  
   'N/A'                   [PR/Poly Change Downtime],  
   'N/A'                   [Avg PR/Poly Change Time]  
  
  FROM @PRDTSums_Line pdm --SplitEvents se  
  JOIN @ProdLines pl -- Rev11.33   
  ON pdm.PLId = pl.PLId  
  GROUP BY pl.PLDesc, pl.plid, pl.packorline  
  ORDER BY pl.PLDesc, pl.plid, pl.packorline  
  option (keep plan)  
  
  
  update dbo.#LineStops2 set  
--   [Unscheduled Stops/Day] = --FLD 01-NOV-2007 Rev11.53  
--    case  when [Split Uptime] + [Unscheduled Split DT] > 0   
--     then ROUND(([Unscheduled Stops] * 1440.0) / ([Split Uptime] + [Unscheduled Split DT]),0)    
--     else 0 end,  
   [Unplanned MTBF] =   
    case when [Unscheduled Stops] > 0   
     then [Split Uptime] / [Unscheduled Stops]  
     else 0 end,  
   [Unplanned MTTR] =   
    case when [Unscheduled Stops] > 0   
     then [Unscheduled Split DT]/[Unscheduled Stops]  
     else 0 end--,  
  
  
  --print 'Result set 12 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  -----------------------------------------------------------------------------------------------  
  -- Section 55: Results Set #6 - Return the stops result set for totals for Lines and Packloops.  
  -----------------------------------------------------------------------------------------------  
  
  -----------------------------------------------------------------------------  
  -- NOTE:  From Total Stops through Production Time, this SELECT code is the    
  --        same as that in the @IncludeTeam = 1 section.  
  -----------------------------------------------------------------------------  
  
  INSERT dbo.#LinePackStops2  
  SELECT [Production Line],  
   '' [Master Unit],  
   SUM([Total Stops]) [Total Stops],  
   SUM([Unscheduled Stops]) [Unscheduled Stops],  
   sum([Unscheduled Stops/Day]) [Unscheduled Stops/Day],  --FLD 01-NOV-2007 Rev11.53  
   SUM([Minor Stops]) [Minor Stops],  
   SUM([Equipment Failures]) [Equipment Failures],  
   SUM([Process Failures]) [Process Failures],  
   SUM([Split Downtime]) [Split Downtime],  
   sum([Unscheduled Split DT]) [Unscheduled Split DT],  
   sum([Raw Uptime]) [Raw Uptime],  
   sum([Split Uptime]) [Split Uptime],  
   'N/A' [Planned Availability],  
   sum([Stops with Uptime <2 Min]) [Stops with Uptime <2 Min],  
   'N/A' [R(2)],  
   0 [Unplanned MTBF],  
   0 [Unplanned MTTR],  
   SUM([ELP Stops]) [ELP Stops],  
  
   SUM([ELP Losses (Mins)])[ELP Losses (Mins)],  
   CASE WHEN SUM([Paper Runtime]) > 0.0   
                             THEN SUM([ELP Losses (Mins)]) / SUM([Paper Runtime])  
        ELSE 0 END [ELP %],  
   SUM([Rate Loss Events]) [Rate Loss Events],  
   SUM([Rate Loss Effective Downtime]) [Rate Loss Effective Downtime],  
   CASE WHEN SUM([Production Time]) > 0.0  
                             THEN SUM([Rate Loss Effective Downtime]) / SUM([Production Time])  
        ELSE 0 END [Rate Loss %],  
  
         SUM([Paper Runtime]) [Paper Runtime],    
         SUM([Production Time]) [Production Time],   
   'N/A' [PR/Poly Change Events],  -- Rev11.29  
   'N/A' [PR/Poly Change Downtime],  -- Rev11.29  
   'N/A' [Avg PR/Poly Change Time]  -- Rev11.29  
  FROM dbo.#LineStops2 with (nolock)  
  group by [Production Line]  
  order by [Production Line]  
  option (keep plan)  
  
  update dbo.#LinePackStops2 set  
   [Group Type] = REPLACE([Group Type], ' Total','s Total'),  
   [Unplanned MTBF] =   
    case when [Unscheduled Stops] > 0   
     then [Split Uptime] / [Unscheduled Stops]  
     else 0 end,  
   [Unplanned MTTR] =   
    case when [Unscheduled Stops] > 0   
     then [Unscheduled Split DT]/[Unscheduled Stops]  
     else 0 end--,  
  
  
  update dbo.#LineStops2 set  
   [Production Line] = COALESCE((  
     SELECT translated_text  
     FROM dbo.local_pg_translations with (nolock)  
     WHERE language_id = @LanguageID  
     and global_text = [Production Line]  
     ), [Production Line])   
     
  update dbo.#LinePackStops2 set  
   [Group Type] =  COALESCE((  
     SELECT translated_text  
     FROM dbo.local_pg_translations with (nolock)  
     WHERE language_id = @LanguageID  
     and global_text = [Group Type]  
     ), [Group Type])   
  
  
  SELECT @SQL =   
  case  
  when (SELECT count(*) FROM dbo.#LineStops2 with (nolock)) > 65000 then   
  'SELECT ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
  when (SELECT count(*) FROM dbo.#LineStops2 with (nolock)) = 0 then   
  'SELECT ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
  else GBDB.dbo.fnLocal_RptTableTranslation('#LineStops2', @LanguageId)  
  end  
  
  execute sp_executesql @SQL   
  
  
  SELECT @SQL =   
  case  
  when (SELECT count(*) FROM dbo.#LinePackStops2 with (nolock)) > 65000 then   
  'SELECT ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
  when (SELECT count(*) FROM dbo.#LinePackStops2 with (nolock)) = 0 then   
  'SELECT ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
  else GBDB.dbo.fnLocal_RptTableTranslation('#LinePackStops2', @LanguageId)  
   + ' order by [Group Type]'  
  end  
  
  execute sp_executesql @SQL   
  
  
  --print 'Result set 13 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  -----------------------------------------------------------------------------  
  -- Section 56: Results Set #7 - Return the stops result set for Overall.  
  -----------------------------------------------------------------------------  
  
  -----------------------------------------------------------------------------  
  -- NOTE:  From Total Stops through Production Time, this SELECT code is the    
  --        same as that in the @IncludeTeam = 1 section.  
  -----------------------------------------------------------------------------  
  
  INSERT dbo.#OverallStops2  
  SELECT 'Overall Totals' [Overall Totals],  
   '' [Master Unit],  
   SUM(lps.[Total Stops]) [Total Stops],  
   SUM(lps.[Unscheduled Stops]) [Unscheduled Stops],  
   sum(lps.[Unscheduled Stops/Day]) [Unscheduled Stops/Day],  --FLD 01-NOV-2007 Rev11.53  
   SUM(lps.[Minor Stops]) [Minor Stops],  
   SUM(lps.[Equipment Failures]) [Equipment Failures],  
   SUM(lps.[Process Failures]) [Process Failures],  
   sum(lps.[Split Downtime]) [Split Downtime],  
   sum(lps.[Unscheduled Split DT]) [Unscheduled Split DT],  
   'N/A' [Raw Uptime],  
   'N/A' [Split Uptime],  
   'N/A' [Planned Availability],  
   sum(lps.[Stops with Uptime <2 Min]) [Stops with Uptime <2 Min],    
   'N/A' [R(2)],  
   'N/A' [Unplanned MTBF],  
   'N/A' [Unplanned MTTR],  
   SUM(lps.[ELP Stops]) [ELP Stops],  
   SUM(lps.[ELP Losses (Mins)]) [ELP Losses (Mins)],  
   CASE WHEN SUM(lps.[Paper Runtime]) > 0.0   
              THEN SUM(lps.[ELP Losses (Mins)]) / SUM(lps.[Paper Runtime])  
        ELSE 0 END [ELP %],  
   SUM(lps.[Rate Loss Events]) [Rate Loss Events],  
   SUM(lps.[Rate Loss Effective Downtime]) [Rate Loss Effective Downtime],  
   CASE WHEN SUM(lps.[Production Time]) > 0.0  
              THEN SUM(lps.[Rate Loss Effective Downtime]) / SUM(lps.[Production Time])  
        ELSE 0 END [Rate Loss %],  
  
         SUM(lps.[Paper Runtime]) [Paper Runtime],    
         SUM(lps.[Production Time]) [Production Time],   
   'N/A' [PR/Poly Change Events],  -- Rev11.29  
   'N/A' [PR/Poly Change Downtime],  -- Rev11.29  
   'N/A' [Avg PR/Poly Change Time]  -- Rev11.29  
  FROM dbo.#LinePackStops2 lps with (nolock)  
  option (keep plan)  
    
  update dbo.#OverallStops2 set  
   [Overall Totals] = COALESCE((  
     SELECT translated_text  
     FROM dbo.local_pg_translations   
     WHERE language_id = @LanguageID  
     and global_text = [Overall Totals]  
     ), [Overall Totals])--,   
  
  
  SELECT @SQL =   
  case  
  when (SELECT count(*) FROM dbo.#OverallStops2 with (nolock)) > 65000 then   
  'SELECT ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
  when (SELECT count(*) FROM dbo.#OverallStops2 with (nolock)) = 0 then   
  'SELECT ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
  else GBDB.dbo.fnLocal_RptTableTranslation('#OverallStops2', @LanguageId)  
  end  
  
  execute sp_executesql @SQL   
  
  
  --print 'Result set 14 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  --------------------------------------------------------------------------------------  
  -- Section 57: Results Set #8 -  Return the production result set by Line and Product.  
  --------------------------------------------------------------------------------------  
  
  -----------------------------------------------------------------------------  
  -- NOTE:  From Production Time through CVTI %, this SELECT code is the    
  --        same as that in the @IncludeTeam = 1 section.  
  -----------------------------------------------------------------------------  
  
  INSERT dbo.#ProdProduction2  
  SELECT  pl.PLDesc [Production Line],  
   ps.Prod_Code [Product],  
   SUM(prs.ProductionRuntime) [Production Time],  
   CASE WHEN SUM(prs.ProductionRuntime) > 0   
        THEN CONVERT(INTEGER,round(SUM(prs.ActualUnits)   
       * ((24 * 60) / SUM(prs.ProductionRuntime)),0))  
        ELSE 0 END [Avg Stat CLD],  
   CASE WHEN SUM(CONVERT(FLOAT,prs.TargetUnits)) > 0   
        THEN SUM(CASE  WHEN prs.TargetUnits IS NOT NULL     
  
          THEN CONVERT(FLOAT,prs.ActualUnits)   
          ELSE 0            
          END)              
      / SUM(CONVERT(FLOAT,prs.TargetUnits))  
      ELSE NULL END [CVPR %],   
   CASE WHEN SUM(CONVERT(FLOAT,prs.OperationsTargetUnits)) > 0   
        THEN SUM(CASE  WHEN prs.OperationsTargetUnits IS NOT NULL   
          THEN CONVERT(FLOAT,prs.ActualUnits)     
          ELSE 0              
          END)                
      / SUM(CONVERT(FLOAT,prs.OperationsTargetUnits))  
      ELSE NULL END [Operations Efficiency %],   
   CONVERT(INTEGER,SUM(prs.TotalUnits)) [Total Units],  
   CONVERT(INTEGER,SUM(prs.GoodUnits)) [Good Units],  
   CONVERT(INTEGER,SUM(prs.RejectUnits)) [Reject Units],  
   CASE WHEN CONVERT(FLOAT,SUM(prs.TotalUnits)) > 0   
          THEN CONVERT(FLOAT,SUM(prs.RejectUnits))  
      / CONVERT(FLOAT,SUM(prs.TotalUnits))  
        ELSE 0 END [Unit Broke %],  
   CONVERT(INTEGER,SUM(prs.ActualUnits)) [Actual Stat Cases],  
   CONVERT(INTEGER,SUM(prs.TargetUnits)) [Reliability Target Stat Cases],  
   CONVERT(INTEGER,SUM(prs.OperationsTargetUnits)) [Operations Target Stat Cases],  
   CONVERT(INTEGER,SUM(prs.IdealUnits)) [Ideal Stat Cases],  
  
   -- Rev11.36  
   case  
   when  SUM(prs.LineSpeedAvg * prs.SplitUptime) > 0.0  
   then  Convert(Float, SUM(prs.LineSpeedAvg * prs.SplitUptime))   
     / SUM (  
       case  
       when prs.LineSpeedAvg > 0.0  
       then convert(float,prs.SplitUptime)  
       else 0.0  
       end  
       )  
   else null  
   end [Line Speed Avg],  
  
   -- Rev11.36  
   case  
   when  SUM(prs.LineSpeedTarget * prs.ProductionRuntime) > 0.0   
   then  Convert(Float, SUM(prs.LineSpeedTarget * prs.ProductionRuntime))   
     / SUM (  
       case   
       when LineSpeedTarget > 0.0  
       then convert(float,prs.ProductionRuntime)  
       else 0.0  
       end  
       )  
   else null  
   end [Target Line Speed],  
  
   -- Rev11.36  
   case  
   when  SUM(prs.LineSpeedIdeal * prs.ProductionRuntime) > 0   
   then  Convert(Float, SUM(prs.LineSpeedIdeal * prs.ProductionRuntime))   
     / SUM (  
       case  
       when LineSpeedIdeal > 0.0  
       then convert(float,prs.ProductionRuntime)  
       else 0.0  
       end  
       )  
   else null  
   end [Ideal Line Speed],  
  
   CASE WHEN SUM(CONVERT(FLOAT,prs.IdealUnits)) > 0.0   
      THEN SUM(CASE  WHEN prs.IdealUnits IS NOT NULL    
          THEN CONVERT(FLOAT,prs.ActualUnits)   
          ELSE 0.0    
          END)              
      / SUM(CONVERT(FLOAT,prs.IdealUnits))  
        ELSE NULL END [CVTI %]  
  
  FROM @ProdRecords prs   
  LEFT JOIN @ProdLines pl --with (nolock) -- Rev11.33   
  ON prs.PLId = pl.PLId  
  LEFT JOIN @products ps   
  ON prs.ProdId = ps.Prod_Id  
  WHERE pl.PackOrLine <> 'Pack'  
  and (charindex('|' + LineStatus + '|', '|' + @LineStatusList + '|') > 0  
   or @LineStatusList = 'All')   
  GROUP BY pl.PLDesc, pl.PackOrLine, ps.Prod_Code, prs.LineSpeedTarget, prs.LineSpeedIdeal  
  ORDER BY pl.PLDesc, pl.PackOrLine, ps.Prod_Code  
  option (keep plan)  
  
  SELECT @SQL =   
  case  
  when (SELECT count(*) FROM dbo.#ProdProduction2 with (nolock)) > 65000 then   
  'SELECT ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
  when (SELECT count(*) FROM dbo.#ProdProduction2 with (nolock)) = 0 then   
  'SELECT ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
  else GBDB.dbo.fnLocal_RptTableTranslation('#ProdProduction2', @LanguageId)  
   + ' order by [Production Line], [Product]'  
  end  
  
  execute sp_executesql @SQL   
  
  
  --print 'Result set 15 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  -----------------------------------------------------------------------------  
  -- Section 58: Results Set #9 - Return the production result set for Line.  
  ----------------------------------------------------------------------------  
  
  -----------------------------------------------------------------------------  
  -- NOTE:  From Production Time through CVTI %, this SELECT code is the    
  --        same as that in the @IncludeTeam = 1 section.  
  -----------------------------------------------------------------------------  
  
  INSERT dbo.#LineProduction2  
  SELECT  pl.PLDesc [Production Line],  
   '' [Product],  
   SUM(prs.ProductionRuntime) [Production Time],  
   CASE WHEN SUM(prs.ProductionRuntime) > 0   
        THEN CONVERT(INTEGER,round(SUM(prs.ActualUnits)   
       * ((24 * 60) / SUM(prs.ProductionRuntime)),0))  
        ELSE 0 END [Avg Stat CLD],  
   CASE WHEN SUM(CONVERT(FLOAT,prs.TargetUnits)) > 0   
        THEN SUM(CASE  WHEN prs.TargetUnits IS NOT NULL     
          THEN CONVERT(FLOAT,prs.ActualUnits)   
          ELSE 0            
          END)              
      / SUM(CONVERT(FLOAT,prs.TargetUnits))  
      ELSE NULL END [CVPR %],   
   CASE WHEN SUM(CONVERT(FLOAT,prs.OperationsTargetUnits)) > 0   
        THEN SUM(CASE  WHEN prs.OperationsTargetUnits IS NOT NULL   
          THEN CONVERT(FLOAT,prs.ActualUnits)     
          ELSE 0              
          END)                
      / SUM(CONVERT(FLOAT,prs.OperationsTargetUnits))  
      ELSE NULL END [Operations Efficiency %],   
   CONVERT(INTEGER,SUM(prs.TotalUnits)) [Total Units],  
   CONVERT(INTEGER,SUM(prs.GoodUnits)) [Good Units],  
   CONVERT(INTEGER,SUM(prs.RejectUnits)) [Reject Units],  
   CASE WHEN CONVERT(FLOAT,SUM(prs.TotalUnits)) > 0   
        THEN CONVERT(FLOAT,SUM(prs.RejectUnits))   
      / CONVERT(FLOAT,SUM(prs.TotalUnits))  
        ELSE 0 END [Unit Broke %],  
   CONVERT(INTEGER,SUM(prs.ActualUnits)) [Actual Stat Cases],  
   CONVERT(INTEGER,SUM(prs.TargetUnits)) [Reliability Target Stat Cases],  
   CONVERT(INTEGER,SUM(prs.OperationsTargetUnits)) [Operations Target Stat Cases],  
   CONVERT(INTEGER,SUM(prs.IdealUnits)) [Ideal Stat Cases],  
  
   -- Rev11.36  
   case  
   when  SUM(prs.LineSpeedAvg * prs.SplitUptime) > 0.0  
   then  Convert(Float, SUM(prs.LineSpeedAvg * prs.SplitUptime))   
     / SUM (  
       case  
       when prs.LineSpeedAvg > 0.0  
       then convert(float,prs.SplitUptime)  
       else 0.0  
       end  
       )  
   else null  
   end [Line Speed Avg],  
  
   -- Rev11.36  
   case  
   when  SUM(prs.LineSpeedTarget * prs.ProductionRuntime) > 0.0   
   then  Convert(Float, SUM(prs.LineSpeedTarget * prs.ProductionRuntime))   
     / SUM (  
       case   
       when LineSpeedTarget > 0.0  
       then convert(float,prs.ProductionRuntime)  
       else 0.0  
       end  
       )  
   else null  
   end [Target Line Speed],  
  
   -- Rev11.36  
   case  
   when  SUM(prs.LineSpeedIdeal * prs.ProductionRuntime) > 0   
   then  Convert(Float, SUM(prs.LineSpeedIdeal * prs.ProductionRuntime))   
     / SUM (  
       case  
       when LineSpeedIdeal > 0.0  
       then convert(float,prs.ProductionRuntime)  
       else 0.0  
       end  
       )  
   else null  
   end [Ideal Line Speed],  
  
   CASE WHEN SUM(CONVERT(FLOAT,prs.IdealUnits)) > 0.0   
      THEN SUM(CASE  WHEN prs.IdealUnits IS NOT NULL    
          THEN CONVERT(FLOAT,prs.ActualUnits)   
          ELSE 0.0    
          END)              
      / SUM(CONVERT(FLOAT,prs.IdealUnits))  
        ELSE NULL END [CVTI %]  
  
  FROM @ProdRecords prs  
  LEFT JOIN @ProdLines pl --with (nolock) -- Rev11.33   
  ON prs.PLId = pl.PLId  
  WHERE pl.PackOrLine <> 'Pack'  
  and (charindex('|' + LineStatus + '|', '|' + @LineStatusList + '|') > 0  
   or @LineStatusList = 'All')   
  GROUP BY pl.PLDesc, pl.PackOrLine  
  ORDER BY pl.PLDesc, pl.PackOrLine  
  option (keep plan)  
  
  SELECT @SQL =   
  case  
  when (SELECT count(*) FROM dbo.#LineProduction2 with (nolock)) > 65000 then   
  'SELECT ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
  when (SELECT count(*) FROM dbo.#LineProduction2 with (nolock)) = 0 then   
  'SELECT ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
  else GBDB.dbo.fnLocal_RptTableTranslation('#LineProduction2', @LanguageId)  
   + ' order by [Production Line]'  
  end  
  
  execute sp_executesql @SQL   
  
  
  --print 'Result set 16 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  -----------------------------------------------------------------------------  
  -- Section 59: Results Set #10 - Return the production result set for Overall.  
  -----------------------------------------------------------------------------  
  
  ----------------------------------------------------------------------------  
  -- NOTE:  From Production Time through CVTI %, this SELECT code is the    
  --        same as that in the @IncludeTeam = 1 section.  
  -----------------------------------------------------------------------------  
  
  INSERT dbo.#OverallProduction2  
  SELECT  'Overall Totals' [Overall Totals],  
   '' [Product],  
   SUM(prs.ProductionRuntime) [Production Time],  
   CASE WHEN SUM(prs.ProductionRuntime) > 0   
        THEN CONVERT(INTEGER,round(SUM(prs.ActualUnits)   
       * ((24 * 60) / SUM(prs.ProductionRuntime)),0))  
        ELSE 0 END [Avg Stat CLD],  
   CASE WHEN SUM(CONVERT(FLOAT,prs.TargetUnits)) > 0   
        THEN SUM(CASE  WHEN prs.TargetUnits IS NOT NULL     
          THEN CONVERT(FLOAT,prs.ActualUnits)   
          ELSE 0            
          END)              
             / SUM(CONVERT(FLOAT,prs.TargetUnits))  
      ELSE NULL END [CVPR %],   
   CASE WHEN SUM(CONVERT(FLOAT,prs.OperationsTargetUnits)) > 0   
        THEN SUM(CASE  WHEN prs.OperationsTargetUnits IS NOT NULL   
          THEN CONVERT(FLOAT,prs.ActualUnits)     
          ELSE 0              
          END)                
      / SUM(CONVERT(FLOAT,prs.OperationsTargetUnits))  
      ELSE NULL END [Operations Efficiency %],   
   CONVERT(INTEGER,SUM(prs.TotalUnits)) [Total Units],  
   CONVERT(INTEGER,SUM(prs.GoodUnits)) [Good Units],  
   CONVERT(INTEGER,SUM(prs.RejectUnits)) [Reject Units],  
   CASE WHEN CONVERT(FLOAT,SUM(prs.TotalUnits)) > 0   
        THEN CONVERT(FLOAT,SUM(prs.RejectUnits))   
      / CONVERT(FLOAT,SUM(prs.TotalUnits))  
        ELSE 0 END [Unit Broke %],  
   CONVERT(INTEGER,SUM(prs.ActualUnits)) [Actual Stat Cases],  
   CONVERT(INTEGER,SUM(prs.TargetUnits)) [Reliability Target Stat Cases],  
   CONVERT(INTEGER,SUM(prs.OperationsTargetUnits)) [Operations Target Stat Cases],  
   CONVERT(INTEGER,SUM(prs.IdealUnits)) [Ideal Stat Cases],  
  
   -- Rev11.36  
   case  
   when  SUM(prs.LineSpeedAvg * prs.SplitUptime) > 0.0  
   then  Convert(Float, SUM(prs.LineSpeedAvg * prs.SplitUptime))   
     / SUM (  
       case  
       when prs.LineSpeedAvg > 0.0  
       then convert(float,prs.SplitUptime)  
       else 0.0  
       end  
       )  
   else null  
   end [Line Speed Avg],  
  
   -- Rev11.36  
   case  
   when  SUM(prs.LineSpeedTarget * prs.ProductionRuntime) > 0.0   
   then  Convert(Float, SUM(prs.LineSpeedTarget * prs.ProductionRuntime))   
     / SUM (  
       case   
       when LineSpeedTarget > 0.0  
       then convert(float,prs.ProductionRuntime)  
       else 0.0  
       end  
       )  
   else null  
   end [Target Line Speed],  
  
   -- Rev11.36  
   case  
   when  SUM(prs.LineSpeedIdeal * prs.ProductionRuntime) > 0   
   then  Convert(Float, SUM(prs.LineSpeedIdeal * prs.ProductionRuntime))   
     / SUM (  
       case  
       when LineSpeedIdeal > 0.0  
       then convert(float,prs.ProductionRuntime)  
       else 0.0  
       end  
       )  
   else null  
   end [Ideal Line Speed],  
  
   CASE WHEN SUM(CONVERT(FLOAT,prs.IdealUnits)) > 0.0    
      THEN SUM(CASE  WHEN prs.IdealUnits IS NOT NULL    
          THEN CONVERT(FLOAT,prs.ActualUnits)   
          ELSE 0.0    
          END)              
      / SUM(CONVERT(FLOAT,prs.IdealUnits))  
        ELSE NULL END [CVTI %]  
  
  FROM @ProdRecords prs  
  LEFT JOIN @ProdLines pl --with (nolock) -- Rev11.33   
  ON prs.PLId = pl.PLId  
  WHERE pl.PackOrLine <> 'Pack'  
  and (charindex('|' + LineStatus + '|', '|' + @LineStatusList + '|') > 0  
   or @LineStatusList = 'All')   
  option (keep plan)  
  
  update dbo.#OverallProduction2 set  
   [Overall Totals] = COALESCE((  
     SELECT translated_text  
     FROM dbo.local_pg_translations with (nolock)  
     WHERE language_id = @LanguageID  
     and global_text = [Overall Totals]  
     ), [Overall Totals])   
  
  SELECT @SQL =   
  case  
  when (SELECT count(*) FROM dbo.#OverallProduction2 with (nolock)) > 65000 then   
  'SELECT ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
  when (SELECT count(*) FROM dbo.#OverallProduction2 with (nolock)) = 0 then   
  'SELECT ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
  else GBDB.dbo.fnLocal_RptTableTranslation('#OverallProduction2', @LanguageId)  
  end  
  
  execute sp_executesql @SQL   
  
  
  --print 'Result set 17 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  -----------------------------------------------------------------------------------------  
  -- Section 60: Results Set #11 - Return the production result set for Packing Production   
  --     Units [Pack Prod worksheet].  
  -----------------------------------------------------------------------------------------  
  
  INSERT dbo.#PackProduction2  
  SELECT pl.PLDesc [Production Line],  
   pu.PUDesc [Master Unit],  
   p.Prod_Code [Product],  
   pt.UOM [UOM],  
   CONVERT(INTEGER, SUM(Value)) [Good Units]  
  FROM dbo.#PackTests pt with (nolock)  
  LEFT JOIN @ProdLines pl --with (nolock) -- Rev11.33    
  ON pt.PLId = pl.PLId  
  LEFT JOIN @ProdUnitsPack pu   
  ON pt.PUId = pu.PUId  
  LEFT JOIN @Products p   
  ON pt.ProdId = p.Prod_Id  
  GROUP BY pl.PLDesc, pu.PUDesc, pt.UOM, p.Prod_Code  
  ORDER BY pl.PLDesc, pu.PUDesc, pt.UOM, p.Prod_Code  
  option (keep plan)  
  
  SELECT @SQL =   
  case  
  when (SELECT count(*) FROM dbo.#PackProduction2 with (nolock)) > 65000 then   
  'SELECT ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
  when (SELECT count(*) FROM dbo.#PackProduction2 with (nolock)) = 0 then   
  'SELECT ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
  else GBDB.dbo.fnLocal_RptTableTranslation('#PackProduction2', @LanguageId)  
   + ' order by [Production Line], [Master Unit], [UOM], [Product]'  
  end  
  
  execute sp_executesql @SQL   
  
  END --of the @IncludeTeam <> 1 section  
  
 IF @IncludeStops = 1  
  BEGIN  
  
  
  --print 'Result set 18 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
 -----------------------------------------------------------------------------------------  
 -- Section 61: Results Set #12 - Return the stops detail result set for the pivot table.  
 -----------------------------------------------------------------------------------------  
  
   INSERT INTO dbo.#Stops  
   SELECT  
--    pu.OrderIndex [OrderIndex],  
    pl.PLDesc [Production Line],  
    pu.PUDesc [Master Unit],  
    CONVERT(VARCHAR(25), se.StartTime, 101) [Start Date],  
    CONVERT(VARCHAR(25), se.StartTime, 114) [Start Time],  
    CONVERT(VARCHAR(25), se.EndTime, 101) [End Date],  
    CONVERT(VARCHAR(25), se.EndTime, 114) [End Time],  
    CONVERT(FLOAT, COALESCE(se.Downtime,0)) / 60.0 [Event Downtime],  
    COALESCE(se.SplitDowntime,0)/60.0 [Split Downtime],  
    ps.Prod_Code [Product],  
    ps.Prod_Desc [Product Desc],  
    pu.DelayType [Event Location Type],  
    se.team [Team],  
    se.Shift [Shift],  
    loc.PU_Desc [Location],  
    tef.TEFault_Name [Fault Desc],  
    er1.Event_Reason_Name,  
    case  
    when lower(er2.event_reason_name) in ('unknown','other','troubleshooting')  
    then er1.event_reason_name + ' - ' + er2.event_reason_name     
    when LTRIM(RTRIM(isnull(er2.event_reason_name, ' '))) = ''  
    and loc.PU_Desc not like '%rate loss%'  
    then isnull(er1.event_reason_name, '**UNCODED** - ' + tef.TEFault_Name)  
    when LTRIM(RTRIM(isnull(er2.event_reason_name, ' '))) = ''  
    and loc.PU_Desc like '%rate loss%'  
    then isnull(er1.event_reason_name, '**UNCODED** - RATE LOSS')  
    else er2.Event_Reason_Name end,  
    substring(erc1.ERC_Desc, CharIndex(Char(58), erc1.ERC_Desc) + 1, 50) [Schedule],  
    substring(erc2.ERC_Desc, CharIndex(Char(58), erc2.ERC_Desc) + 1, 50) [Category],  
    substring(erc3.ERC_Desc, CharIndex(Char(58), erc3.ERC_Desc) + 1, 50) [SubSystem],  
    substring(erc4.ERC_Desc, CharIndex(Char(58), erc4.ERC_Desc) + 1, 50) [GroupCause],  
    pueg.EquipGroup [Equipment Group],  
    Comment [Comment],  
    se.LineStatus [Line Status],  
    CASE  WHEN se.TEDetId = se.PrimaryId THEN 'Primary'   
     when coalesce(se.PrimaryID,0)=0 then 'Reporting'  
     ELSE 'Secondary' END [Event Type],  
    COALESCE(se.Stops, 0) [Total Stops],  
    COALESCE(se.StopsMinor, 0) [Minor Stops],  
    COALESCE(se.StopsEquipFails, 0) [Equipment Failures],   
    COALESCE(se.StopsProcessFailures, 0) [Process Failures],  
    COALESCE(causes,0) [Total Causes],  
    UPPER(se.UWS1GrandParent) [UWS1GrandParent],     
    UPPER(LTRIM(LEFT(se.UWS1GrandParent,2))) [UWS1GrandParent PM],  
    UPPER(se.UWS1Parent) [UWS1Parent],      
    UPPER(LTRIM(LEFT(se.UWS1Parent,2))) [UWS1Parent PM],  
    UPPER(se.UWS2GrandParent) [UWS2GrandParent],     
    UPPER(LTRIM(LEFT(se.UWS2GrandParent,2))) [UWS2GrandParent PM],  
    UPPER(se.UWS2Parent) [UWS2Parent],      
    UPPER(LTRIM(LEFT(se.UWS2Parent,2))) [UWS2Parent PM],  
  
    COALESCE(SplitUnscheduledDT,0) / 60.0     [Unscheduled Split DT],  --FLD 01-NOV-2007 Rev11.53  
  
    COALESCE(se.Uptime,0)/60.0 [Uptime],  
    COALESCE(se.SplitUptime,0)/60.0 [Split UpTime],  
    COALESCE(se.UpTime2m, 0) [Stops with Uptime <2 Min],   
    COALESCE(se.stopsrateloss,0) [Rate Loss Events],  
    COALESCE(se.SplitRLDowntime,0)/60.0 [Rate Loss Effective Downtime],  
    se.LineTargetSpeed [Target Line Speed],  
    se.LineActualSpeed [Actual Line Speed],  
    se.LineIdealSpeed [Ideal Line Speed],      
    COALESCE(se.StopsBlockedStarved, 0) [Total Blocked Starved],  
    CASE  WHEN (COALESCE(se.StopsEquipFails, 0) = 1) AND (COALESCE(se.SplitDowntime,0)/60.0 >= 10.0   
      AND COALESCE(se.SplitDowntime,0)/60.0 <= 30.0 )  
      THEN 1  
      ELSE 0   
      END [Minor Equipment Failures],   
    CASE  WHEN (COALESCE(se.StopsEquipFails, 0) = 1) AND (COALESCE(se.SplitDowntime,0)/60.0 > 30.0   
      AND COALESCE(se.SplitDowntime,0)/60.0 <= 120.0)   
      THEN 1  
      ELSE 0   
      END [Moderate Equipment Failures],   
    CASE  WHEN (COALESCE(se.StopsEquipFails, 0) = 1) AND (COALESCE(se.SplitDowntime,0)/60.0 > 120.0)  
      THEN 1  
      ELSE 0   
      END [Major Equipment Failures],   
    CASE  WHEN (COALESCE(se.StopsProcessFailures, 0) = 1) AND (COALESCE(se.SplitDowntime,0)/60.0 >= 10.0   
      AND COALESCE(se.SplitDowntime,0)/60.0 <= 30.0 )  
      THEN 1  
      ELSE 0   
      END [Minor Process Failures],   
    CASE  WHEN (COALESCE(se.StopsProcessFailures, 0) = 1) AND (COALESCE(se.SplitDowntime,0)/60.0 > 30.0   
      AND COALESCE(se.SplitDowntime,0)/60.0 <= 120.0)   
      THEN 1  
      ELSE 0   
      END [Moderate Process Failures],  
    CASE  WHEN (COALESCE(se.StopsProcessFailures, 0) = 1) AND (COALESCE(se.SplitDowntime,0)/60.0 > 120.0)  
      THEN 1  
      ELSE 0   
      END [Major Process Failures],  
    er3.Event_Reason_Name,   
    er4.Event_Reason_Name   
  
   FROM dbo.#SplitDowntimes se with (nolock)  
   JOIN @ProdUnits pu    
   ON  se.PUId = pu.PUId  
   JOIN @ProdLines pl --with (nolock) -- Rev11.33   
   ON pu.PLId = pl.PLId  
   JOIN @Products ps  
   ON se.ProdId = ps.Prod_Id  
   left  JOIN @ProdUnitsEG pueg ON se.LocationId = pueg.Source_PUId  
   LEFT JOIN dbo.Event_Reason_Catagories erc1 with (nolock)  
   ON se.ScheduleId   = erc1.ERC_Id  
   LEFT JOIN dbo.Event_Reason_Catagories erc2 with (nolock)  
   ON se.CategoryId   = erc2.ERC_Id  
   LEFT JOIN dbo.Event_Reason_Catagories erc3 with (nolock)  
   ON se.SubSystemId  = erc3.ERC_Id  
   LEFT JOIN dbo.Event_Reason_Catagories erc4 with (nolock)  
   ON se.GroupCauseId  = erc4.ERC_Id  
   LEFT JOIN dbo.Prod_Units loc with (nolock) ON se.LocationId = loc.PU_Id  
   LEFT JOIN @EventReasons er1  ON se.L1ReasonId   = er1.Event_Reason_Id  
   LEFT JOIN @EventReasons     er2  ON se.L2ReasonId   = er2.Event_Reason_Id  
   LEFT JOIN @EventReasons     er3  ON se.L3ReasonId   = er3.Event_Reason_Id  
   LEFT JOIN @EventReasons     er4  ON se.L4ReasonId   = er4.Event_Reason_Id  
   LEFT  JOIN  dbo.Timed_Event_Fault    tef  with (nolock) ON (se.TEFaultID   = TEF.TEFault_ID)  
   where (charindex('|' + LineStatus + '|', '|' + @LineStatusList + '|') > 0  
    or @LineStatusList = 'All')   
   ORDER  BY pl.PLDesc, se.Starttime  
   option (keep plan)  
     
   SELECT @SQL =   
   case  
   when (SELECT count(*) FROM dbo.#Stops with (nolock)) > 65000 then   
   'SELECT ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
   when (SELECT count(*) FROM dbo.#Stops with (nolock)) = 0 then   
   'SELECT ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
   else GBDB.dbo.fnLocal_RptTableTranslation('#Stops', @LanguageId)  
    + ' order by [Production Line], [Start Date], [Start Time]'  
   end  
  
   SELECT @SQL = REPLACE(@SQL, char(39) + 'RL1Title' +  char(39), char(39) + @RL1Title + char(39))  
   SELECT @SQL = REPLACE(@SQL, char(39) + 'RL2Title' +  char(39), char(39) + @RL2Title + char(39))  
   SELECT @SQL = REPLACE(@SQL, char(39) + 'RL3Title' +  char(39), char(39) + @RL3Title + char(39))  
   SELECT @SQL = REPLACE(@SQL, char(39) + 'RL4Title' +  char(39), char(39) + @RL4Title + char(39))  
  
   execute sp_executesql @SQL  
  
   
   IF @BySummary = 1  
    BEGIN  
  
    --print 'Result set 19 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
    -----------------------------------------------------------------------------  
    -- Return multiple resultsets for the Summary version of the report.  There are  
    -- a total of seven that have the data organized in various arrangements.  
    -----------------------------------------------------------------------------  
    -----------------------------------------------------------------------------  
    -- Section 62: Results Set #13 - Return the result set for Line/Team grouping.  
    -----------------------------------------------------------------------------  
    INSERT dbo.#LineSummary  
    SELECT  
     pu.OrderIndex [OrderIndex],   
     pl.PLDesc [Production Line],  
     se.PUDesc [Master Unit],  
     se.team [Team],  
     Sum(COALESCE(se.Stops, 0)) [Total Stops],  
     Sum(COALESCE(se.StopsMinor, 0)) [Minor Stops],  
     Sum(COALESCE(se.StopsEquipFails, 0)) [Equipment Failures],  
     Sum(COALESCE(se.StopsProcessFailures, 0)) [Process Failures],  
     Sum(COALESCE(se.causes,0)) [Total Causes],  
     sum(COALESCE(se.Downtime,0)/60.0) [Event Downtime],  
     Sum(COALESCE(se.SplitDowntime,0)/60.0) [Split Downtime],  
  
     SUM(COALESCE(SplitUnscheduledDT,0)) / 60.0           [Unscheduled Split DT],  --FLD 01-NOV-2007 Rev11.53  
  
     sum(COALESCE(se.Uptime,0)) / 60.0 [Raw Uptime],  
     Sum(COALESCE(se.SplitUptime,0)/60.0) [Split Uptime],  
     sum(COALESCE(se.UpTime2m, 0)) [Stops with Uptime <2 Min],   
     SUM(COALESCE(se.StopsRateLoss, 0)) [Rate Loss Events],  
     SUM(CONVERT(FLOAT, COALESCE(se.SplitRLDowntime, 0)))/60.0 [Rate Loss Effective Downtime],  
     Sum(COALESCE(se.StopsBlockedStarved, 0)) [Total Blocked Starved],  
     SUM(CASE WHEN  COALESCE(se.StopsEquipFails, 0) = 1  
        AND ( COALESCE(se.SplitDowntime,0)/60.0 >= 10.0   
        AND COALESCE(se.SplitDowntime,0)/60.0 <= 30.0 )  
        THEN 1  
        ELSE 0   
        END) [Minor Equipment Failures],   
     SUM(CASE WHEN  COALESCE(se.StopsEquipFails, 0) = 1  
        AND ( COALESCE(se.SplitDowntime,0)/60.0 > 30.0   
        AND COALESCE(se.SplitDowntime,0)/60.0 <= 120.0)   
        THEN 1  
        ELSE 0   
        END) [Moderate Equipment Failures],   
     SUM(CASE WHEN  COALESCE(se.StopsEquipFails, 0) = 1  
        AND (COALESCE(se.SplitDowntime,0)/60.0 > 120.0)  
        THEN 1  
        ELSE 0   
        END) [Major Equipment Failures],   
     SUM(CASE WHEN  COALESCE(se.StopsProcessFailures, 0) = 1  
        AND ( COALESCE(se.SplitDowntime,0)/60.0 >= 10.0   
        AND COALESCE(se.SplitDowntime,0)/60.0 <= 30.0 )  
        THEN 1  
        ELSE 0   
        END) [Minor Process Failures],   
     SUM(CASE WHEN COALESCE(se.StopsProcessFailures, 0) = 1  
        AND ( COALESCE(se.SplitDowntime,0)/60.0 > 30.0   
        AND COALESCE(se.SplitDowntime,0)/60.0 <= 120.0)   
        THEN 1  
        ELSE 0   
        END) [Moderate Process Failures],   
     SUM(CASE WHEN  COALESCE(se.StopsProcessFailures, 0) = 1  
        AND (COALESCE(se.SplitDowntime,0)/60.0 > 120.0)  
        THEN 1  
        ELSE 0   
        END) [Major Process Failures]  
    FROM dbo.#SplitDowntimes se with (nolock)  
    JOIN @ProdUnits pu   
    ON se.PUDesc = pu.PUDesc  
    JOIN @ProdLines pl --with (nolock) -- Rev11.33  
    ON pu.PLId = pl.PLId  
  
    where (charindex('|' + LineStatus + '|', '|' + @LineStatusList + '|') > 0  
     or @LineStatusList = 'All')   
    GROUP BY pl.PLDesc, pu.OrderIndex, se.PUDesc, se.team  
    ORDER BY pl.PLDesc, pu.OrderIndex, se.PUDesc, se.team  
    option (keep plan)   
   
    SELECT @SQL =   
    case  
    when (SELECT count(*) FROM dbo.#LineSummary with (nolock)) > 65000 then   
    'SELECT ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
    when (SELECT count(*) FROM dbo.#LineSummary with (nolock)) = 0 then   
    'SELECT ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
    else GBDB.dbo.fnLocal_RptTableTranslation('#LineSummary', @LanguageId)  
     + ' order by [Production Line], [OrderIndex], [Master Unit], [Team]'  
    end  
    
    -- strip OrderIndex from the returned results  
    if charindex('OrderIndex',left(@SQL,25)) > 5  
    select @SQL = replace(@SQL,substring(@SQL,7,charindex(',',@SQL) -6), ' ')   
  
    execute sp_executesql @SQL   
  
  
    --print 'Result set 20 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
    ------------------------------------------------------------------------------------  
    -- Section 63: Results Set #14 - Return the result set for Line/Shift Type grouping.  
    ------------------------------------------------------------------------------------  
  
    INSERT dbo.#ShiftSummary  
    SELECT  
     pu.OrderIndex [OrderIndex],  
     pl.PLDesc [Production Line],  
     se.PUDesc [Master Unit],  
     se.Shift [Shift],  
     Sum(COALESCE(se.Stops, 0)) [Total Stops],  
     Sum(COALESCE(se.StopsMinor, 0)) [Minor Stops],  
     Sum(COALESCE(se.StopsEquipFails, 0)) [Equipment Failures],  
     Sum(COALESCE(se.StopsProcessFailures, 0)) [Process Failures],  
     Sum(COALESCE(se.causes,0)) [Total Causes],  
     sum(COALESCE(se.Downtime,0)/60.0) [Event Downtime],  
     Sum(COALESCE(se.SplitDowntime,0)/60.0) [Split Downtime],  
  
     SUM(COALESCE(SplitUnscheduledDT,0)) / 60.0           [Unscheduled Split DT],  --FLD 01-NOV-2007 Rev11.53  
  
     sum(COALESCE(se.Uptime,0)) / 60.0 [Raw Uptime],  
     Sum(COALESCE(se.SplitUptime,0)/60.0) [Split Uptime],  
     sum(COALESCE(se.UpTime2m, 0)) [Stops with Uptime <2 Min],   
     SUM(COALESCE(se.StopsRateLoss, 0)) [Rate Loss Events],  
     SUM(CONVERT(FLOAT, COALESCE(se.SplitRLDowntime, 0)))/60.0 [Rate Loss Effective Downtime],  
     Sum(COALESCE(se.StopsBlockedStarved, 0)) [Total Blocked Starved],  
     SUM(CASE WHEN (COALESCE(se.StopsEquipFails, 0) = 1) AND (COALESCE(se.SplitDowntime,0)/60.0 >= 10.0   
        AND COALESCE(se.SplitDowntime,0)/60.0 <= 30.0 )  
        THEN 1  
        ELSE 0   
        END) [Minor Equipment Failures],   
     SUM(CASE WHEN (COALESCE(se.StopsEquipFails, 0) = 1) AND (COALESCE(se.SplitDowntime,0)/60.0 > 30.0   
        AND COALESCE(se.SplitDowntime,0)/60.0 <= 120.0)   
        THEN 1  
        ELSE 0   
        END) [Moderate Equipment Failures],   
     SUM(CASE WHEN (COALESCE(se.StopsEquipFails, 0) = 1) AND (COALESCE(se.SplitDowntime,0)/60.0 > 120.0)  
        THEN 1  
        ELSE 0   
        END) [Major Equipment Failures],   
     SUM(CASE WHEN (COALESCE(se.StopsProcessFailures, 0) = 1) AND (COALESCE(se.SplitDowntime,0)/60.0 >= 10.0   
        AND COALESCE(se.SplitDowntime,0)/60.0 <= 30.0 )  
        THEN 1  
        ELSE 0   
        END) [Minor Process Failures],   
     SUM(CASE WHEN (COALESCE(se.StopsProcessFailures, 0) = 1) AND (COALESCE(se.SplitDowntime,0)/60.0 > 30.0   
        AND COALESCE(se.SplitDowntime,0)/60.0 <= 120.0)   
        THEN 1  
        ELSE 0   
        END) [Moderate Process Failures],   
     SUM(CASE WHEN (COALESCE(se.StopsProcessFailures, 0) = 1) AND (COALESCE(se.SplitDowntime,0)/60.0 > 120.0)  
        THEN 1  
        ELSE 0   
        END) [Major Process Failures]  
    FROM dbo.#SplitDowntimes se with (nolock)  
    JOIN @ProdUnits pu   
    ON se.PUDesc = pu.PUDesc  
    JOIN @ProdLines pl --with (nolock) -- Rev11.33   
    ON pu.PLId = pl.PLId  
  
    where (charindex('|' + LineStatus + '|', '|' + @LineStatusList + '|') > 0  
     or @LineStatusList = 'All')   
    GROUP BY pl.PLDesc, pu.OrderIndex, se.PUDesc, se.Shift  
    ORDER BY pl.PLDesc, pu.OrderIndex, se.PUDesc, se.Shift  
    option (keep plan)   
   
    SELECT @SQL =   
    case  
    when (SELECT count(*) FROM dbo.#ShiftSummary with (nolock)) > 65000 then   
    'SELECT ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
    when (SELECT count(*) FROM dbo.#ShiftSummary with (nolock)) = 0 then   
    'SELECT ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
    else GBDB.dbo.fnLocal_RptTableTranslation('#ShiftSummary', @LanguageId)  
     + ' order by [Production Line], [OrderIndex], [Master Unit], [Shift]'  
    end  
  
    -- strip OrderIndex from the returned results  
    if charindex('OrderIndex',left(@SQL,25)) > 5  
    select @SQL = replace(@SQL,substring(@SQL,7,charindex(',',@SQL) -6), ' ')   
  
    execute sp_executesql @SQL   
  
  
    --print 'Result set 21 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
    ---------------------------------------------------------------------------------  
    -- Section 64: Results Set #15 - Return the result set for Line/Product grouping.  
    ---------------------------------------------------------------------------------  
  
    INSERT dbo.#ProductSummary  
    SELECT  
     pu.OrderIndex [OrderIndex],  
     pl.PLDesc [Production Line],  
     se.PUDesc [Master Unit],  
     ps.Prod_Desc [Product],  
     Sum(COALESCE(se.Stops, 0)) [Total Stops],  
     Sum(COALESCE(se.StopsMinor, 0)) [Minor Stops],  
     Sum(COALESCE(se.StopsEquipFails, 0)) [Equipment Failures],  
     Sum(COALESCE(se.StopsProcessFailures, 0)) [Process Failures],  
     Sum(COALESCE(se.causes,0)) [Total Causes],  
     sum(COALESCE(se.Downtime,0)/60.0) [Event Downtime],  
     Sum(COALESCE(se.SplitDowntime,0)/60.0) [Split Downtime],  
  
     SUM(COALESCE(SplitUnscheduledDT,0)) / 60.0           [Unscheduled Split DT],  --FLD 01-NOV-2007 Rev11.53  
  
     sum(COALESCE(se.Uptime,0)) / 60.0 [Raw Uptime],  
     Sum(COALESCE(se.SplitUptime,0)/60.0) [Split Uptime],  
     sum(COALESCE(se.UpTime2m, 0)) [Stops with Uptime <2 Min],   
     SUM(COALESCE(se.StopsRateLoss, 0)) [Rate Loss Events],  
     SUM(CONVERT(FLOAT, COALESCE(se.SplitRLDowntime, 0)))/60.0 [Rate Loss Effective Downtime],  
     Sum(COALESCE(se.StopsBlockedStarved, 0)) [Total Blocked Starved],  
     SUM(CASE WHEN  COALESCE(se.StopsEquipFails, 0) = 1  
        AND ( COALESCE(se.SplitDowntime,0)/60.0 >= 10.0   
        AND COALESCE(se.SplitDowntime,0)/60.0 <= 30.0 )  
        THEN 1  
        ELSE 0   
        END) [Minor Equipment Failures],   
     SUM(CASE WHEN  COALESCE(se.StopsEquipFails, 0) = 1  
        AND ( COALESCE(se.SplitDowntime,0)/60.0 > 30.0   
        AND COALESCE(se.SplitDowntime,0)/60.0 <= 120.0)   
        THEN 1  
        ELSE 0   
        END) [Moderate Equipment Failures],   
     SUM(CASE WHEN  COALESCE(se.StopsEquipFails, 0) = 1  
        AND COALESCE(se.SplitDowntime,0)/60.0 > 120.0  
        THEN 1  
        ELSE 0   
        END) [Major Equipment Failures],   
     SUM(CASE WHEN  COALESCE(se.StopsProcessFailures, 0) = 1  
        AND ( COALESCE(se.SplitDowntime,0)/60.0 >= 10.0   
        AND COALESCE(se.SplitDowntime,0)/60.0 <= 30.0 )  
        THEN 1  
        ELSE 0   
        END) [Minor Process Failures],   
     SUM(CASE WHEN  COALESCE(se.StopsProcessFailures, 0) = 1  
        AND ( COALESCE(se.SplitDowntime,0)/60.0 > 30.0   
        AND COALESCE(se.SplitDowntime,0)/60.0 <= 120.0)   
        THEN 1  
        ELSE 0   
        END) [Moderate Process Failures],   
     SUM(CASE WHEN  COALESCE(se.StopsProcessFailures, 0) = 1  
        AND COALESCE(se.SplitDowntime,0)/60.0 > 120.0  
        THEN 1  
        ELSE 0   
        END) [Major Process Failures]  
    FROM dbo.#SplitDowntimes se with (nolock)  
    JOIN @ProdUnits pu   
    ON se.PUDesc = pu.PUDesc  
    JOIN @ProdLines pl --with (nolock) -- Rev11.33  
    ON pu.PLId = pl.PLId  
    JOIN @products ps   
    ON se.ProdId = ps.Prod_Id  
    where (charindex('|' + LineStatus + '|', '|' + @LineStatusList + '|') > 0  
     or @LineStatusList = 'All')   
    GROUP BY pl.PLDesc, pu.OrderIndex, se.PUDesc, ps.Prod_Desc  
    ORDER BY pl.PLDesc, pu.OrderIndex, se.PUDesc, ps.Prod_Desc  
    option (keep plan)   
   
    SELECT @SQL =   
    case  
    when (SELECT count(*) FROM dbo.#ProductSummary with (nolock)) > 65000 then   
    'SELECT ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
    when (SELECT count(*) FROM dbo.#ProductSummary with (nolock)) = 0 then   
    'SELECT ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
    else GBDB.dbo.fnLocal_RptTableTranslation('#ProductSummary', @LanguageId)  
     + ' order by [Production Line], [OrderIndex], [Master Unit], [Product]'  
    end  
  
    -- strip OrderIndex from the returned results  
    if charindex('OrderIndex',left(@SQL,25)) > 5  
    select @SQL = replace(@SQL,substring(@SQL,7,charindex(',',@SQL) -6), ' ')   
  
    execute sp_executesql @SQL   
  
  
    --print 'Result set 22 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
    ---------------------------------------------------------------------------------------  
    -- Section 65: Results Set #16 - Return the result set for Line/Location Type grouping.  
    ---------------------------------------------------------------------------------------  
  
    INSERT dbo.#LocationSummary  
    SELECT  
     pu.OrderIndex [OrderIndex],  
     pl.PLDesc [Production Line],  
     se.PUDesc [Master Unit],  
     pu.DelayType [Event Location Type],  
     Sum(COALESCE(se.Stops, 0)) [Total Stops],  
     Sum(COALESCE(se.StopsMinor, 0)) [Minor Stops],  
     Sum(COALESCE(se.StopsEquipFails, 0)) [Equipment Failures],  
     Sum(COALESCE(se.StopsProcessFailures, 0)) [Process Failures],  
     Sum(COALESCE(se.causes,0)) [Total Causes],  
     sum(COALESCE(se.Downtime,0)/60.0) [Event Downtime],  
     Sum(COALESCE(se.SplitDowntime,0)/60.0) [Split Downtime],  
  
     SUM(COALESCE(SplitUnscheduledDT,0)) / 60.0           [Unscheduled Split DT],  --FLD 01-NOV-2007 Rev11.53  
  
     sum(COALESCE(se.Uptime,0)) / 60.0 [Raw Uptime],  
     Sum(COALESCE(se.SplitUptime,0)/60.0) [Split Uptime],  
     sum(COALESCE(se.UpTime2m, 0)) [Stops with Uptime <2 Min],   
     SUM(COALESCE(se.StopsRateLoss, 0)) [Rate Loss Events],  
     SUM(CONVERT(FLOAT, COALESCE(se.SplitRLDowntime, 0))) /60.0 [Rate Loss Effective Downtime],  
     Sum(COALESCE(se.StopsBlockedStarved, 0)) [Total Blocked Starved],  
     SUM(CASE WHEN (COALESCE(se.StopsEquipFails, 0) = 1) AND (COALESCE(se.SplitDowntime,0)/60.0 >= 10.0   
        AND COALESCE(se.SplitDowntime,0)/60.0 <= 30.0 )  
        THEN 1  
        ELSE 0   
        END) [Minor Equipment Failures],   
     SUM(CASE WHEN (COALESCE(se.StopsEquipFails, 0) = 1) AND (COALESCE(se.SplitDowntime,0)/60.0 > 30.0   
        AND COALESCE(se.SplitDowntime,0)/60.0 <= 120.0)   
        THEN 1  
        ELSE 0   
        END) [Moderate Equipment Failures],   
     SUM(CASE WHEN (COALESCE(se.StopsEquipFails, 0) = 1) AND (COALESCE(se.SplitDowntime,0)/60.0 > 120.0)  
        THEN 1  
        ELSE 0   
        END) [Major Equipment Failures],   
     SUM(CASE WHEN (COALESCE(se.StopsProcessFailures, 0) = 1) AND (COALESCE(se.SplitDowntime,0)/60.0 >= 10.0   
        AND COALESCE(se.SplitDowntime,0)/60.0 <= 30.0 )  
        THEN 1  
        ELSE 0   
        END) [Minor Process Failures],   
     SUM(CASE WHEN (COALESCE(se.StopsProcessFailures, 0) = 1) AND (COALESCE(se.SplitDowntime,0)/60.0 > 30.0   
        AND COALESCE(se.SplitDowntime,0)/60.0 <= 120.0)   
        THEN 1  
        ELSE 0   
        END) [Moderate Process Failures],   
     SUM(CASE WHEN (COALESCE(se.StopsProcessFailures, 0) = 1) AND (COALESCE(se.SplitDowntime,0)/60.0 > 120.0)  
        THEN 1  
        ELSE 0   
        END) [Major Process Failures]  
    FROM dbo.#SplitDowntimes se with (nolock)  
    JOIN @ProdUnits pu   
    ON se.PUDesc = pu.PUDesc  
    JOIN @ProdLines pl --with (nolock) -- Rev11.33   
    ON pu.PLId = pl.PLId  
  
    where (charindex('|' + LineStatus + '|', '|' + @LineStatusList + '|') > 0  
     or @LineStatusList = 'All')   
    GROUP BY pl.PLDesc, pu.OrderIndex, se.PUDesc, pu.DelayType  
    ORDER BY pl.PLDesc, pu.OrderIndex, se.PUDesc, pu.DelayType  
    option (keep plan)   
   
    SELECT @SQL =   
    case  
    when (SELECT count(*) FROM dbo.#LocationSummary with (nolock)) > 65000 then   
    'SELECT ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
    when (SELECT count(*) FROM dbo.#LocationSummary with (nolock)) = 0 then   
    'SELECT ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
    else GBDB.dbo.fnLocal_RptTableTranslation('#LocationSummary', @LanguageId)  
     + ' order by [Production Line], [OrderIndex], [Master Unit], [Event Location Type]'  
    end  
  
    -- strip OrderIndex from the returned results  
    if charindex('OrderIndex',left(@SQL,25)) > 5  
    select @SQL = replace(@SQL,substring(@SQL,7,charindex(',',@SQL) -6), ' ')   
  
    execute sp_executesql @SQL   
  
  
    --print 'Result set 23 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
    ----------------------------------------------------------------------------------  
    -- Section 66: Results Set #17 - Return the result set for Line/Category grouping.  
    ----------------------------------------------------------------------------------  
  
    INSERT dbo.#CategorySummary  
    SELECT  
     pu.OrderIndex [OrderIndex],  
     pl.PLDesc [Production Line],  
     se.PUDesc [Master Unit],  
     coalesce(substring(erc2.ERC_Desc, CharIndex(':', erc2.ERC_Desc) + 1, 50),'') [Category],  
     Sum(COALESCE(se.Stops, 0)) [Total Stops],  
     Sum(COALESCE(se.StopsMinor, 0)) [Minor Stops],  
     Sum(COALESCE(se.StopsEquipFails, 0)) [Equipment Failures],  
     Sum(COALESCE(se.StopsProcessFailures, 0)) [Process Failures],  
     Sum(COALESCE(causes,0)) [Total Causes],  
     sum(COALESCE(se.Downtime,0)/60.0) [Event Downtime],  
     Sum(COALESCE(se.SplitDowntime,0)/60.0) [Split Downtime],  
  
     SUM(COALESCE(SplitUnscheduledDT,0)) / 60.0           [Unscheduled Split DT],  --FLD 01-NOV-2007 Rev11.53  
  
     sum(COALESCE(se.Uptime,0)) / 60.0 [Raw Uptime],  
     Sum(COALESCE(se.SplitUptime,0)/60.0) [Split Uptime],  
     sum(COALESCE(se.UpTime2m, 0)) [Stops with Uptime <2 Min],   
     SUM(COALESCE(se.StopsRateLoss, 0)) [Rate Loss Events],  
     SUM(CONVERT(FLOAT, COALESCE(se.SplitRLDowntime, 0)))/60.0 [Rate Loss Effective Downtime],  
     Sum(COALESCE(se.StopsBlockedStarved, 0)) [Total Blocked Starved],  
     SUM(CASE WHEN (COALESCE(se.StopsEquipFails, 0) = 1) AND (COALESCE(se.SplitDowntime,0)/60.0 >= 10.0   
        AND COALESCE(se.SplitDowntime,0)/60.0 <= 30.0 )  
        THEN 1  
        ELSE 0   
        END) [Minor Equipment Failures],   
     SUM(CASE WHEN (COALESCE(se.StopsEquipFails, 0) = 1) AND (COALESCE(se.SplitDowntime,0)/60.0 > 30.0   
        AND COALESCE(se.SplitDowntime,0)/60.0 <= 120.0)   
        THEN 1  
        ELSE 0   
        END) [Moderate Equipment Failures],   
     SUM(CASE WHEN (COALESCE(se.StopsEquipFails, 0) = 1) AND (COALESCE(se.SplitDowntime,0)/60.0 > 120.0)  
        THEN 1  
        ELSE 0   
        END) [Major Equipment Failures],   
     SUM(CASE WHEN (COALESCE(se.StopsProcessFailures, 0) = 1) AND (COALESCE(se.SplitDowntime,0)/60.0 >= 10.0   
        AND COALESCE(se.SplitDowntime,0)/60.0 <= 30.0 )  
        THEN 1  
        ELSE 0   
        END) [Minor Process Failures],   
     SUM(CASE WHEN (COALESCE(se.StopsProcessFailures, 0) = 1) AND (COALESCE(se.SplitDowntime,0)/60.0 > 30.0   
        AND COALESCE(se.SplitDowntime,0)/60.0 <= 120.0)   
        THEN 1  
        ELSE 0   
        END) [Moderate Process Failures],   
     SUM(CASE WHEN (COALESCE(se.StopsProcessFailures, 0) = 1) AND (COALESCE(se.SplitDowntime,0)/60.0 > 120.0)  
        THEN 1  
        ELSE 0   
        END) [Major Process Failures]  
    FROM dbo.#SplitDowntimes se with (nolock)  
    JOIN @ProdUnits pu   
    ON se.PUDesc = pu.PUDesc  
    JOIN @ProdLines pl --with (nolock) -- Rev11.33   
    ON pu.PLId = pl.PLId  
  
    LEFT JOIN dbo.Event_Reason_Catagories erc2 with (nolock)  
    ON se.CategoryId = erc2.ERC_Id  
    where (charindex('|' + LineStatus + '|', '|' + @LineStatusList + '|') > 0  
     or @LineStatusList = 'All')   
    GROUP BY pl.PLDesc, pu.OrderIndex, se.PUDesc, erc2.ERC_Desc  
    ORDER BY pl.PLDesc, pu.OrderIndex, se.PUDesc, erc2.ERC_Desc  
    option (keep plan)        
   
    SELECT @SQL =   
    case  
    when (SELECT count(*) FROM dbo.#CategorySummary with (nolock)) > 65000 then   
    'SELECT ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
    when (SELECT count(*) FROM dbo.#CategorySummary with (nolock)) = 0 then   
    'SELECT ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
    else GBDB.dbo.fnLocal_RptTableTranslation('#CategorySummary', @LanguageId)  
     + ' order by [Production Line], [OrderIndex], [Master Unit], [Category]'  
    end  
  
    -- strip OrderIndex from the returned results  
    if charindex('OrderIndex',left(@SQL,25)) > 5  
    select @SQL = replace(@SQL,substring(@SQL,7,charindex(',',@SQL) -6), ' ')   
  
    execute sp_executesql @SQL   
  
  
    --print 'Result set 24 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
    -----------------------------------------------------------------------------------  
    -- Section 67: Results Set #18 -  Return the result set for Line/Schedule grouping.  
    -----------------------------------------------------------------------------------  
  
    INSERT dbo.#ScheduleSummary  
    SELECT  
     pu.OrderIndex [OrderIndex],  
     pl.PLDesc [Production Line],  
     se.PUDesc [Master Unit],  
     coalesce(substring(erc1.ERC_Desc, CharIndex(':', erc1.ERC_Desc) + 1, 50),'') [Schedule],  
     Sum(COALESCE(se.Stops, 0)) [Total Stops],  
     Sum(COALESCE(se.StopsMinor, 0)) [Minor Stops],  
     Sum(COALESCE(se.StopsEquipFails, 0)) [Equipment Failures],  
     Sum(COALESCE(se.StopsProcessFailures, 0)) [Process Failures],  
     Sum(COALESCE(se.causes,0)) [Total Causes],  
     sum(COALESCE(se.Downtime,0)/60.0) [Event Downtime],  
     Sum(COALESCE(se.SplitDowntime,0)/60.0) [Split Downtime],  
  
     SUM(COALESCE(SplitUnscheduledDT,0)) / 60.0           [Unscheduled Split DT],  --FLD 01-NOV-2007 Rev11.53  
  
     sum(COALESCE(se.Uptime,0)) / 60.0 [Raw Uptime],  
     Sum(COALESCE(se.SplitUptime,0)/60.0) [Split Uptime],  
     sum(COALESCE(se.UpTime2m, 0)) [Stops with Uptime <2 Min],   
     SUM(COALESCE(se.StopsRateLoss, 0)) [Rate Loss Events],  
     SUM(CONVERT(FLOAT, COALESCE(se.SplitRLDowntime, 0)))/60.0 [Rate Loss Effective Downtime],  
     Sum(COALESCE(se.StopsBlockedStarved, 0)) [Total Blocked Starved],  
     SUM(CASE WHEN (COALESCE(se.StopsEquipFails, 0) = 1) AND (COALESCE(se.SplitDowntime,0)/60.0 >= 10.0   
        AND COALESCE(se.SplitDowntime,0)/60.0 <= 30.0 )  
        THEN 1  
        ELSE 0   
        END) [Minor Equipment Failures],   
     SUM(CASE WHEN (COALESCE(se.StopsEquipFails, 0) = 1) AND (COALESCE(se.SplitDowntime,0)/60.0 > 30.0   
        AND COALESCE(se.SplitDowntime,0)/60.0 <= 120.0)   
        THEN 1  
        ELSE 0   
        END) [Moderate Equipment Failures],   
     SUM(CASE WHEN (COALESCE(se.StopsEquipFails, 0) = 1) AND (COALESCE(se.SplitDowntime,0)/60.0 > 120.0)  
        THEN 1  
        ELSE 0   
        END) [Major Equipment Failures],   
     SUM(CASE WHEN (COALESCE(se.StopsProcessFailures, 0) = 1) AND (se.SplitDowntime/60.0 >= 10.0   
        AND COALESCE(se.SplitDowntime,0)/60.0 <= 30.0 )  
        THEN 1  
        ELSE 0   
        END) [Minor Process Failures],   
  
     SUM(CASE WHEN (COALESCE(se.StopsProcessFailures, 0) = 1) AND (COALESCE(se.SplitDowntime,0)/60.0 > 30.0   
        AND COALESCE(se.SplitDowntime,0)/60.0 <= 120.0)   
        THEN 1  
        ELSE 0   
        END) [Moderate Process Failures],   
     SUM(CASE WHEN (COALESCE(se.StopsProcessFailures, 0) = 1) AND (COALESCE(se.SplitDowntime,0)/60.0 > 120.0)  
        THEN 1  
        ELSE 0   
        END) [Major Process Failures]  
    FROM dbo.#SplitDowntimes se with (nolock)  
    JOIN @ProdUnits pu   
    ON se.PUDesc = pu.PUDesc  
    JOIN @ProdLines pl --with (nolock) -- Rev11.33   
    ON pu.PLId = pl.PLId  
  
    LEFT JOIN dbo.Event_Reason_Catagories erc1 with (nolock)  
    ON se.ScheduleId = erc1.ERC_Id  
      where (charindex('|' + LineStatus + '|', '|' + @LineStatusList + '|') > 0  
     or @LineStatusList = 'All')   
    GROUP BY pl.PLDesc, pu.OrderIndex, se.PUDesc, erc1.ERC_Desc  
    ORDER BY pl.PLDesc, pu.OrderIndex, se.PUDesc, erc1.ERC_Desc  
    option (keep plan)      
  
    SELECT @SQL =   
    case  
    when (SELECT count(*) FROM dbo.#ScheduleSummary with (nolock)) > 65000 then   
    'SELECT ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
    when (SELECT count(*) FROM dbo.#ScheduleSummary with (nolock)) = 0 then   
    'SELECT ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
    else GBDB.dbo.fnLocal_RptTableTranslation('#ScheduleSummary', @LanguageId)  
     + ' order by [Production Line], [OrderIndex], [Master Unit], [Schedule]'  
    end  
  
    -- strip OrderIndex from the returned results  
    if charindex('OrderIndex',left(@SQL,25)) > 5  
    select @SQL = replace(@SQL,substring(@SQL,7,charindex(',',@SQL) -6), ' ')   
  
    execute sp_executesql @SQL   
   
    END --IF @BySummary  
  END --IF @IncludeStops  
  
  
  --print 'Result set 25 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  -----------------------------------------------------------------------------  
  -- Section 68: Results Set #13 if @BySummary = 0.  Otherwise, Results Set #19  
  -- Return the contents of the @ProdRecords table.  This will be placed  
  -- in a hidden sheet in the report for troubleshooting.  
  -----------------------------------------------------------------------------  
  
  SELECT  pl.PLDesc [Production Line],  
   Shift [Shift],  
   Team [Team],  
   Prod_Code [Product],  
   StartTime [StartTime],  
   EndTime [EndTime],  
   convert(int,TotalUnits) [Total Units],  -- Rev11.33  
   convert(int,GoodUnits) [Good Units],  -- Rev11.33  
   convert(int,RejectUnits) [Reject Units],  -- Rev11.33  
   LineSpeedIdeal [Ideal Line Speed],   
   LineSpeedTarget [Target Line Speed],   
   LineSpeedAvg [Avg Line Speed], -- Rev11.35  
   WebWidth [Web Width],  
   SheetWidth [Sheet Width],  
   convert(int,RollsPerLog) [Rolls Per Log],  -- Rev11.33  
   convert(int,RollsInPack) [Rolls In Pack],  -- Rev11.33  
   convert(int,PacksInBundle) [Packs In Bundle],  -- Rev11.33  
   convert(int,CartonsInCase) [Cartons In Case (Facial)],  -- Rev11.33  
   convert(int,SheetCount) [Sheet Count],  -- Rev11.33  
   SheetLength [Sheet Length],  
   StatFactor [Stat Factor],  
   CalendarRuntime [Calendar Runtime],  
   prs.ProductionRuntime [Production Time],  
   PlanningRuntime [Planning Runtime],  
   OperationsRuntime [Operations Runtime],  
   convert(int,ActualUnits) [Actual Stat Cases],  -- Rev11.33  
   convert(int,TargetUnits) [Reliability Target Stat Cases],  -- Rev11.33  
   convert(int,OperationsTargetUnits) [Operations Target Stat Units],  -- Rev11.33  
   convert(int,IdealUnits) [Ideal Stat Cases],  -- Rev11.33  
   HolidayCurtailDT [Holiday/Curtail DT],  
   PlninterventionDT [Planned intervention DT],  
   ChangeOverDT [ChangeOver DT],  
   HygCleaningDT [Hygiene/Cleaning DT],  
   EOProjectsDT [E.O./Projects DT],  
   UnscheduledDT [Unscheduled DT],  
   CLAuditsDT [CL Checks/Audits DT]  
  FROM @ProdRecords prs  
  JOIN @ProdLines pl --with (nolock) -- Rev11.33   
  ON prs.PLId = pl.PLId  
  JOIN @products ps  
  ON prs.ProdId = ps.Prod_Id  
  ORDER BY PLDesc, StartTime  
  option (keep plan)  
  
  --print 'Result set 26 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  -----------------------------------------------------------------------------  
  -- 2008-08-31 Vince King Rev11.77  
  -- Section 69: Results Set #14 if @BySummary = 0.  Otherwise, Results Set #20  
  -- Return a summary of hours by Line / Line Status.  
  --  
  -- 2009-09-09 VMK Rev11.78 Replaced code using @RunSummary with code using  
  -- #Dimensions.  Replaced Line with Unit.  
  --  
  -- 2009-09-14 VMK Rev11.79 Changed code to select units based on 'Line Status'  
  -- table field configuration.  
  -----------------------------------------------------------------------------  
  DECLARE @ClockHrs TABLE (  
   Unit      VARCHAR(100),  
   LineStatus    VARCHAR(100),  
   ClockHrs     FLOAT )  
  
  INSERT INTO @ClockHrs (Unit, LineStatus, ClockHrs)  
   SELECT DISTINCT    
    pu.pu_desc [Unit],   
    p.Phrase_Value [Line Status],  
    DATEDIFF(ss, (CASE WHEN ls.Start_DateTime < @StartTime THEN @StartTime ELSE ls.Start_DateTime END),  
       (CASE WHEN (ls.End_DateTime > @EndTime) OR (ls.End_Datetime IS NULL) THEN @EndTime ELSE ls.End_DateTime END))  
        / 3600.0 [Clock Hrs]  
   FROM dbo.Table_Fields_Values WITH (NOLOCK)  
   JOIN dbo.prod_units pu WITH (NOLOCK)  
   ON convert(varchar(10),pu.pu_id) = dbo.Table_Fields_Values.Value  
   JOIN dbo.prod_lines pl WITH (NOLOCK)  
   ON pl.pl_id = pu.pl_id  
   JOIN @ProdLines apl   
   ON apl.PLId = pl.pl_id  --Comment back in for use in sp  
   JOIN dbo.Local_PG_Line_Status ls WITH (NOLOCK)   
   ON pu.PU_Id = ls.Unit_Id  
   AND ls.update_status <> 'DELETE'    
   AND ls.start_datetime < @EndTime  
   AND (ls.end_datetime > @StartTime OR ls.end_datetime IS NULL)  
   JOIN dbo.Phrase p WITH (NOLOCK)   
   ON ls.Line_Status_Id = p.Phrase_Id  
   WHERE (((dbo.Table_Fields_Values.Table_Field_Id)   
         In (SELECT dbo.Table_Fields.Table_Field_Id   
               FROM dbo.Table_Fields   
               WHERE (((dbo.Table_Fields.Table_Field_Desc)='STLS_LS_MASTER_UNIT_ID'))))   
   AND ((dbo.Table_Fields_Values.TableId)   
         In (SELECT dbo.Tables.TableId   
               FROM dbo.Tables   
         WHERE (((dbo.Tables.TableName)='prod_units')))))  
   ORDER BY pu.PU_Desc, p.Phrase_Value, [Clock Hrs]  
  
   SELECT Unit, LineStatus, SUM(ClockHrs) [ClockHrs]  
   FROM @ClockHrs  
   GROUP BY Unit, LineStatus  
   ORDER BY Unit, LineStatus, [ClockHrs]  
  
  --print 'Result set 27 ' + CONVERT(VARCHAR(20), GetDate(), 120)  
  -----------------------------------------------------------------------------------------------------------------------  
  -- 2008-08-31 Vince King Rev11.77  
  -- Section 70: Results Set #15 if @BySummary = 0.  Otherwise, Results Set #21  
  -- Return details of Line Status by Line.  
  --  
  -- 2009-09-09 VMK Rev11.78 Replaced code using @RunSummary with code using  
  -- #Dimensions.  Replaced Line with Unit. Select only units with reliability  
  -- in desc.  
  --  
  -- 2009-09-14 VMK Rev11.79 Changed code to select units based on 'Line Status'  
  -- table field configuration.  
  -----------------------------------------------------------------------------------------------------------------------  
  SELECT DISTINCT  pu.PU_Desc   [Unit],   
        (CASE WHEN (ls.Start_DateTime < @StartTime OR ls.Start_DateTime IS NULL) THEN  
         @StartTime  
        ELSE ls.Start_DateTime END)  [StartTime],  
        (CASE WHEN (ls.End_DateTime > @EndTime OR ls.End_DateTime IS NULL) THEN  
         @EndTime  
        ELSE ls.End_DateTime END)    [EndTime],  
        p.Phrase_Value  [Line Status],  
        lsc.Comment_Text [Comment]  
  FROM dbo.Table_Fields_Values         WITH (NOLOCK)   
  JOIN dbo.prod_units          pu  WITH (NOLOCK) ON pu.pu_id     = dbo.Table_Fields_Values.Value  
  JOIN dbo.prod_lines           pl  WITH (NOLOCK) ON pl.pl_id     = pu.pl_id  
  JOIN @ProdLines            apl       ON apl.PLId     = pl.pl_id  --Comment back in for use in sp  
  LEFT JOIN dbo.Local_PG_Line_Status     ls  WITH (NOLOCK) ON pu.PU_Id   = ls.Unit_Id  
                          AND ls.update_status <> 'DELETE'    
                          AND ls.start_datetime < @EndTime  
                          AND (ls.end_datetime > @StartTime OR ls.end_datetime IS NULL)  
  LEFT JOIN  dbo.Phrase         p  WITH (NOLOCK) ON ls.Line_Status_Id  = p.Phrase_Id  
  LEFT JOIN dbo.Local_PG_Line_Status_Comments lsc WITH (NOLOCK) ON (SELECT TOP 1 Comment_Id FROM dbo.Local_PG_Line_Status_Comments plsc  
                           WHERE ls.Status_Schedule_Id = plsc.Status_Schedule_Id ORDER BY Entered_On DESC)  
                           = lsc.Comment_Id  
  WHERE (((dbo.Table_Fields_Values.Table_Field_Id)   
        In (SELECT dbo.Table_Fields.Table_Field_Id   
              FROM dbo.Table_Fields   
              WHERE (((dbo.Table_Fields.Table_Field_Desc)='STLS_LS_MASTER_UNIT_ID'))))   
  AND ((dbo.Table_Fields_Values.TableId)   
        In (SELECT dbo.Tables.TableId   
              FROM dbo.Tables   
        WHERE (((dbo.Tables.TableName)='prod_units')))))  
--    AND (lsc.Comment_Text IS NOT NULL AND lsc.Comment_Text <> '')        -- 2009-09-16 VMK Rev11.81 Removed.  Need to show all lines.  
  ORDER BY [Unit], [StartTime], [EndTime], [Line Status], [Comment]         -- 2009-09-16 VMK Rev11.80 Added.  
  
  -----------------------------------------------------------------------------------------------------------------------  
  -- 2009-09-02 Vince King Rev11.77  
  -- Section 71: Results Set #16 if @BySummary = 0.  Otherwise, Results Set #22  
  -- Return details of downtime events identified as data quality issues.  
  -- 2009-09-23 Vince King Rev11.82 Modifications to @DataQA table to initially  
  --      store Id values.  Also added code to pick up the event  
  --      prior to the report period IF it meets the issues criteria.  
  -----------------------------------------------------------------------------------------------------------------------  
  SELECT Issue,  
     pl.PL_Desc      [Line],  
     PUDesc       [Unit],  
     StartTime      [StartTime],  
     EndTime       [EndTime],  
     Downtime       [Downtime],  
     Uptime       [Uptime],  
     er1.Event_Reason_Name  [L1Reason],   
     er2.Event_Reason_Name  [L2Reason],  
     erc1.ERC_Desc     [Schedule],  
     erc2.ERC_Desc     [Category]  
  FROM @DataQA          dq  
  LEFT JOIN dbo.Prod_Lines      pl  WITH (NOLOCK) ON dq.PLId   = pl.PL_Id  
  LEFT JOIN dbo.Event_Reasons     er1 WITH (NOLOCK) ON dq.L1ReasonId = er1.Event_Reason_Id  
  LEFT JOIN dbo.Event_Reasons     er2 WITH (NOLOCK) ON dq.L2ReasonId = er2.Event_Reason_Id  
  LEFT JOIN dbo.Event_Reason_Catagories erc1 WITH (NOLOCK) ON dq.ScheduleId = erc1.ERC_Id  
  LEFT JOIN dbo.Event_Reason_Catagories erc2 WITH (NOLOCK) ON dq.CategoryId = erc2.ERC_Id  
  ORDER BY Line, Unit, StartTime  
  
  end  
  
-------------------------------------------------------------------------  
-- Drop temp tables  
-------------------------------------------------------------------------  
  
Finished:  
  
drop table dbo.#delays  
drop table dbo.#TimedEventDetails  
drop table dbo.#tests  
drop table dbo.#limittests  
drop table dbo.#packtests  
drop table dbo.#SplitDowntimes  
drop table dbo.#SplitUptime  
drop table dbo.#UnitStops  
drop table dbo.#LineStops  
drop table dbo.#LinePackStops  
drop table dbo.#OverallStops  
drop table dbo.#ProdProduction  
drop table dbo.#LineProduction  
drop table dbo.#OverallProduction  
drop table dbo.#PackProduction  
drop table dbo.#UnitStops2    -- 2007-04-06 VMK Rev11.37 Added.  
drop table dbo.#LineStops2  
drop table dbo.#LinePackStops2  
drop table dbo.#OverallStops2  
drop table dbo.#ProdProduction2  
drop table dbo.#LineProduction2  
drop table dbo.#OverallProduction2  
drop table dbo.#PackProduction2  
drop table dbo.#Stops  
drop table dbo.#LineSummary  
drop table dbo.#ShiftSummary  
drop table dbo.#ProductSummary  
drop table dbo.#LocationSummary  
drop table dbo.#CategorySummary  
drop table dbo.#ScheduleSummary  
DROP TABLE dbo.#Events     -- 2007-01-11 VMK Rev11.29  
drop table dbo.#prsrun     -- Rev11.33  
--drop table dbo.#prodlines     -- Rev11.33  
--Rev11.55  
drop table dbo.#splitprsrun  
drop table dbo.#dimensions  
--drop table dbo.#ELPMetrics_UnitTeam  
--drop table dbo.#ELPMetrics_Unit  
--drop table dbo.#ELPMetrics_Line  
drop table dbo.#EventStatusTransitions  
--drop table dbo.#ESTOutsideWindow  
--drop table dbo.#runs  
  
  
--print 'End of Result Sets: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
RETURN  
  
