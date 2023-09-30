  
/*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
-- Version 7.84 2009-10-22 Jeff Jaeger  
--  
-- ELP Report.  Report ELP stops data with associated  
-- parent roll ids and papermachines.  Summarize total number of parent rolls  
-- ran and parent rolls rejected.  
--  
-- 2002-06-12 Vince King  
--  - Original version.  
--  
-- 2003-02-05 Vince King  
--  - Modified this report based on new requirements defined by the converting business.  
--  - The key change to the report is the ELP% calculation.  This calculation is:  
--    ELP% = (Paper Downtime during report period) / (Runtime during report period), where  
--    Runtime = (Total Uptime + Unscheduled Downtime).  
--  
--    One note, in this sp the Runtime is calulated as: (Total Time - Total Scheduled Downtime),  
--    which is actually the same as the above calc, this was a more straight forward way to   
--    get to the same result.  
  
-- 2003-02-21 Vince King  
--  - Added the report parameter @PackPUIdList.  This is used to add additional Pack Production  
--    Units to the Stops Pivot table.  These units are NOT included in ELP Summary Result Sets for  
--    for CONVERTing and Papermaking.  The stops are only included in the pivot table.  
--  
-- 2003-02-27 Vince King  
--  - Modified the code to select ELP Events.  I was only selecting Stops and needed to get ALL  
--    events include split that have CategoryId = @CatELPId.  
--  - Also modified select statements to return 0 if Runtime = 0.  
--  
-- 2003-02-28 Vince King  
--  - Changed the code to ALTER  the #PRSummary table so that it only includes the Converter for  
--    the summary result sets.  
--  
-- 2003-03-25 Vince King  
--  - Eff Downtime for Rate Loss was not being captured correctly for ELP.  Modified code for  
--    temporary table and result sets.  
--   
-- 2003-03-28 Vince King  
--  - Added code to Set ReportRLDowntime for Primary and Secondary Rate Loss events.  Secondary  
--    rate loss events were being included in the downtime.  
--  
-- 2003-04-25 Vince King  
--  - Modified selection of Rate Loss ELP events.  Report only includes RateLoss events that  
--    have a StartTime >= Report Start Time and StartTime < Report End Time.  
--  - Modified collection of Scheduled DT for Runtime calculation.  
--  
-- 2003-04-30 Vince King  
--  - Was not picking up the ELP Downtime for Secondary events in the Pivot Table.  Removed the code  
--    to update ReportELPDowntime out of UPDATE statement for primary events.  
--  
-- 2003-05-14 Vince King  
--  - In some cases the UWS1 PRID was not matching with the list of PRIDs in the #PRsRun table.  
--    I modified the code to assign the UWS1 PRID to the #Delays table to use the #PRsRun table  
--     to get the PRID.  This took care of the Fresh + Storage Stops <> Total Paper Stops and it  
--    resolved the problem with the Runtimes not matching (Fresh + Storage Runtime <> Total Runtime).  
--  
-- 2003-05-15 Vince King  
--  - Runtime and Papermachine was not coming in for a couple of lines in MP.  Found that they had two  
--     backstands, but were only running one.  It was Input 2 in the Production Execution configuration.  
--    Reports works against Input = 1 to allow for single backstand lines.  Changed the input values in   
--    the config.  
--  - Also changed the summary (#PRSummary) to use the PRIDPM column in the #PRsRun table to determine  
--    what papermachine, instead of using the UWS1PM column in the #Delays table.  
--  
-- 2003-06-10 Vince King   
--  - Modified code to pull Event_Reason_Catagories from the Local_Timed_Event_Categories table.  
--  
-- 2003-07-24 Vince King  
--  - Corrected problem with Fresh DT and Storage DT summaries not matching the summary of DT in the  
--    pivot table.  
--  
-- 2003-07-24 Vince King  
--  - When a PR was Partially Ran and then ran again, downtime events were being duplicated because  
--    of the multiple PR records. Added code in the JOIN to get PR ran with event ST between  
--    PR StartTime and EndTime.  
--  
-- 2003-09-18 Langdon Davis  
--  - Corrected bug wrt fresh/old determination.  Vince was calculating the age of the parent roll in  
--    hours and then testing this against 1 day.  Changed age determination to units of days.  
--  
-- 2003-10-19 Matthew Wells  
--  - Streamlined report execution by replacing cursors with queries  
--  - Fixed an error with the CONVERTing roll times coming from the wrong place in Proficy  
--  - Simplified report execution by consolidating the configuration gathering  
--  
-- 2003-11-12 Langdon Davis  
--  - Per recommendation from Matt Wells, modified the StartTime and EndTime selection  
--    for the #PRsRun table to address issue with Holiday/Curtail downtime events  
--    not being appropriately excluded from the Paper Runtime.  
--  - Modified several of the aliases to match terminology with what was agreed  
--    in the "Time Definitions".  
--  - Corrected the calculations for Fresh Paper DT, Storage Paper DT, Fresh   
--    ELP%, and Storage ELP%.  They were not including the effective DT for   
--    Rate Loss events.  
--  - Modified code to pull data for "NoAssignedPRID" into the PRSummary table so  
--    that it would show up on the summary page and thereby 1.) not hide the   
--    issue that some loss is unaccounted for due to no assigned PRID and 2.)  
--    insure that the stops count on the summary page and that on the pivot table  
--    are the same.  Since we have no way of knowing runtime under no assigned  
--    PRID, nor whether the parent roll that was really running was fresh or old,  
--    the only ELP%'s in which we can include ELP losses under no assigned PRID are  
--    the totals by line and by report, and then only if we use the calendar/clock   
--    time-based approach to determining Paper Runtime instead of the sum of   
--    ParentRollEndTime - ParentRollStartTime approach.  Accordingly, made this  
--    change.  
--  - Modified the summation of the scheduled time that is to be excluded from the   
--    paper runtime to only count the time for which there was a parent roll in the  
--    unwind stand.  
--  - Noticed that the #RunsLine, #RunsLineShift and #RunsLineShiftSum were not  
--    being used for anything so I dropped them from the code.  
--  - Dropped a bunch of program variables and a few data look-ups that weren't  
--    being used for anything in this report, e.g., variables associated with    
--    production amounts, actual and  ideal.  
--  
-- 2003-NOV-26 Langdon Davis  
--  - Modified criteria for summing up excluded time in populating #PRSummary.  
--    Not all of the possible situations of how an event may split across PROLL   
--    Start and End Times and/or No Assigned PRID were being covered.  
--   
-- 2003-NOV-29 Langdon Davis  
--  - Added code to delete 'NoAssignedPRID' records from #PRSummary if they  
--    reflect zero losses.   
--   
-- 2003-DEC-02 Langdon Davis  
--  - Moved the check on #Delays records exceeding 65000 from just after the  
--    initial population of #Delays, to the results set return section AND made  
--    it specific to the records in #Delays that we are actually looking to  
--    return to Excel to construct the pivot table worksheet.  What was happening  
--    before was, if the TOTAL number of event records in #Delays exceeded 65000,  
--    report processing ceased.  Obviously, we only need to worry about the limit  
--    being exceeded by just those records that we are actually looking to  
--    return to the worksheet.   
--  - Additionally, modified the logic around what happens when the 65000 is  
--    exceeded so that everything BUT the pivot worksheet is produced.  This is   
--    much better than no report at all.  The new logic will, in place of the   
--    pivot table data, display a message on that worksheet saying the 65000  
--    limit has been exceeded.  NOTE:  Some Excel-side code still needs to be  
--    added to look for this message in the 8th results set and, if present, not  
--    try and ALTER  a pivot table out of it.  Jeff Jaeger will do this work as  
--    part of bringing the ELP code up to date wrt error handling.  
--  
-- 2003-DEC-04 Langdon Davis  
--  - Corrected issue with Paper Runtime calculation for report overall totals.  
--    Among other things, involved leaving NoAssignedPRID data in place, i.e.,   
--    undoing the 2003-NOV-29 change and managing instead via WHERE clause in  
--    results set selections.  
--  
-- 2003-DEC-05 Langdon Davis  
--  - Added 5 variables to the "reinitialization" section of the code looping  
--    through a cursor to populate #ProdLines.  They had been left out, which  
--    was resulting in some prior loop values being carried through when the  
--    look-up of var_ID's for the PLID in the subsequent loop didn't find a  
--    value.  
--  
-- 2003-DEC-09 Langdon Davis  
--  - Modified to encompass Facial lines in Green Bay which have a 'PP' instead   
--    of 'TT' prefix.  
--  - Modified to be able to include ELP losses on the intermediate lines in   
--    addition to CONVERTing lines.  
--  - Got rid of the #Runs table as it wasn't really being used anywhere, just  
--    created and populated.  
--  
-- 2003-DEC-16 Jeff Jaeger Rev 6.66  
--  - Added an alias to the warning message returned in the > 65000 record count check.  
--  - Added flow control code for when #ErrMsg has an entry.  
--  - Removed the @CvtgDTPUStr parameter.  
--  
-- 2004-JAN-12 Jeff Jaeger Rev 6.67  
--  -  Add "AND td.puid = prs.puid" to the last join of the last result set.  This was done to eliminate   
--     the rare instance of duplicate records being created by the JOIN.  
--  
-- 2004-JAN-29 Matthew Wells Rev 6.68  
--  - Added optimization  
--  - Added multilingual  
--  - Added Inventory status (9) to the exclusion list of @prsrun  
--  
-- 2004-APR-26 Matthew Wells Rev6.69  
--  - Fixed issue with Crew Schedule assignment to downtime records.  
  
-- 2004-05-13 Jeff Jaeger  Rev6.70  
--  - Updated the join between @prsrun and #delays in the last result set so that it is based only on   
--    PRID = UWS1 and the original date restriction.  
--  - Updated the insert to @LineStatusRaw where clause, so that Update_Status is <> 'DELETE'  
--  - Moved the creation of temporary tables to the top of the sp, and the dropping of temp tables   
--    to the bottom of the sp, per our usual standard.  
--  - Updated the check for > 65000 records, to reflect the latest code.  
--  - Updated the varId lookups to use fnLocal_GlblGetVarId for multilingual.  
--  - Removed unused code.  
  
-- 2004-05-14 Langdon Davis  Rev6.71   
--  - Corrected "cut & paste" error in the application of fnLocal_GlblGetVarId.  They all  
--                had @RateLossPUId in the call.  
--  - Corrected the work for conversion to 3-stage genealogy model.  NOTE: Assumes that if the   
--    if the 3-stage genealogy variables are present, conversion to the 3-stage model has occurred.  
--  - Commented out a bunch of unused program variables.  
  
-- 2004-May-14 Langdon Davis Rev6.72  
--   - Modified the modifications for the new genealogy model to COALEASCE on the   
--    results instead of the Var_Id's.  
  
-- 2004-MAY-14  Langdon Davis Rev6.73  
--  - Addressed a few issues with PRIDPM and UWS2PM variable references arising from the conversion  
--    to the 3-stage genealogy model.  
--  - Dropped GrandParent PRID from the primary key of #PRsRun since it needs to be null if all 3  
--    stages of the 3-stage model aren't used.  
  
-- 2004-May-21  Jeff Jaeger Rev6.74  
--  - Modified the field names in #Stops.  [Paper Machine] is now [UWS1 PRoll Made By] and [UWS2 PM]   
--    is now [USW2 PRoll Made By].  
--  - Removed some unused code.  
--  
-- 2004-May-31 Simon Poon Rev6.75  
--  The previous version only has 1 set of PRID's is associated with the events and used to fill   
--  the UWS1, UWS1PM, UWS2 and UWS2PM fields in the 'raw data' result set. With the 3-stage genealogy  
--  mode, the following modifications have been done:  
--   * UWS1 is changed to UWS1Parent  
--   * UWS1PM is changed to UWS1ParentPM  
--   * UWS1GrandParent is added  
--   * UWS1GrandParentPM is added  
--   * UWS2 is changed to UWS2Parent  
--   * UWS2PM is changed to UWS2ParentPM  
--   * UWS2GrandParent is added  
--   * UWS2GrandParentPM is added  
--  
-- 2004-JUL-19  Langdon Davis Rev6.76  
--  - Added constraINTEGER to the insert into PRsRun to exclude PR's that have "0" run time.  
--  - Added constraINTEGER to the insert into PRsRun to exclude PR's that have a NULL PRID   
--    or whose runtime is > 1 day.  
--  - Removed Grandparent default to 'NoAssignedPRID'  
--  
-- 2004-SEP-20  Langdon Davis Rev6.78  
--  - Removed exclusion of PR's with a NULL PRID when insert to PRsRun is being done, letting the already  
--    existing COALESCE default them to 'NoAssignedPRID' instead.  
--  - Put in code to COALESCE the papermachine to 'NoAssignedPRID' when the PRID is NULL/NoAssigned PRID,  
--    increasing the field size from 10 to 15 to accomodate.  
--  - Removed the forcing of PRID's to UPPER case in the pivot table results set.  This was redundant with   
--           the formatting already done in populating these fields.  
  
-- 2004-12-09 Jeff Jaeger  Rev6.80  
--  - brought this sp up to date with Checklist 110804.  
--  - removed some unused code.  
--  - removed unused parameter, @PRIDVarStr.  
--  - in relation to the @prsrun table variable, updated Parent to ParentPM and GrandParent to GrandParentPM.  
--  - added the field TotalRolls to table @PRSummary.    
--  - updated the result sets to use TotalRolls in table @PRSummary instead of calculating the value.  
--  
-- 2005-MAR-14 Vince King  Rev6.81  
--  - Added code to check GrandParentPRID in @prsrun JOIN when adding rows to @PRSummary table.  
--  - Facial Lines (GB) were not being report on Summary sheet when running paper from intermediate lines (ParentPRID).  
--  
-- 2005-MAR-22 Vince King  Rev6.82  
--  - The SET ANSI_NULLS and QUOTED_IDENTIFIER had be inadvertantly set to OFF.  Changed them back to ON.  When set to  
--    OFF, the results sets are negatively affected.  
--  
-- 2005-MAR-23 Vince King  Rev6.83  
--  - For sites that had NO PRID associated with the DT events, NO Data was being reported.  In Rev6.76, there was data  
--    reported, only it was associated with No Assigned PRID.  Found that a section of code added by FLD to compensate   
--      for this was lost between Rev6.76 and Rev6.80.  I added that section of code back in, it is commented with:  
--    -- Added by FLD on 2003-11-12 to capture data records that have NoAssignedPRID --> they   
--    -- are not in @prsrun so they don't get picked up by the INSERT code above.  
--  
-- 2005-APR-06 Langdon Davis Rev6.84  
--  - Changed SET QUOTED_IDENTIFIER from ON to OFF.  This is our standard.  
--  - Addressed issue with getting 2 legitimate records with the same start date/time and NULL --> NoAssigned  
--    PRID's.  This was resulting in a primary key error when inserting into @prsrun.  Fix was, instead of just   
--      defaulting the NULL PRID to 'NoAssignedPRID', concatenating 'NoAssignedPRID' with the UWS result.  Thus, as   
--      long as the UWS results for the 2 records are not the same [if they were, the 2 records would not be legitimate   
--      since we can't run 2 rolls on the same UWS at once], the PRID's are different and the primary key constraINTEGER   
--      is met.  
--      In the insert to @prsrun, removed a constraINTEGER that ParentPRID not be NULL on the join between the Events table  
--      and Tests.  
--  - Added 'dbo.' to database object references to help minimize recompiles.  
--  
-- 2005-APR-07 Vince King Rev6.85  
--  - Events outside of the report window was being included in the raw data used for the stops pivot table.  This caused  
--    the ELP Downtime on the pivot table summary to be incorrect.  
--  - Added the InRptWindow column to the #Delays table and populated the same as the CvtgDDSStops report.  Then filtered  
--    the events for the Stops Pivot table to be only events in the Report window.  
--  - Modified the DATEDIFF statement for calculating ReportDowntime for the code that selects the previous event for   
--    each Prod_Unit so that it takes into account the situation of the Start_Time and End_Time less than @StartTime.  
  
-- 2005-APR-15  Langdon Davis  Rev6.86  
--   - Modified code for the addition of INTR to the PU_Desc for the intermediate reliability units.  
  
-- 2005-APR-27 Vince King Rev6.87  
--  - Modified sp to return result sets that include Paper Source, i.e. 12 ---> FW.  This is especially important when reporting  
--    ELP for sites with intermediate production lines.    
--    - Also added two new result sets that return Intermediates data.  This section provides the same ELP data grouped by  
--      Intermediate, then by Paper Run By (which CONVERTing line ran paper from this Intermediate line).  
--  - Added COALESCE statement to code that populates the @prsrun table.    
  
-- 2005-JUN-15 Vince King Rev6.88  
--  - Modified the SELECT statements used to return results to use the PaperRunBy instead of PaperMachine and added grouping.     
--    The results were not matching with previous (current) version of the report.  
--  - The PaperMachine summary was not calculating the Runtime the same as the CONVERTing summary.  Changed PaperMachine summary  
--    to use the same as CONVERTing Summary.  
  
-- 2005-JUN-14 Vince King Rev6.89  
--  - Applied MSI streamlining of code to sp.  Moved report parameters from ALTER  PROCEDURE and retrieved values using the  
--    spCmn_GetReportParameterValue stored procedure.  Selected Ids for Event_Reason_Categories using constant strings rather  
--    than passing the strings as parameters.  Moved other string report parameters to constants.  Added the RptName report  
--    parameter, which will be passed from the template and contain the Report Definition name.  The spCmn_GetReportParameterValue  
--      stored procedure using this to retrieve the parameter values.  
--  - Added Error trapping code for when the SP tries to add a duplicate PRID/TimeStamp to the @prsrun table.  This has caused a  
--    PRIMARY KEY VIOLATION error in the past which caused the report to fail.  If this error (2627) occurs, then code is executed  
--    to find the duplicate data and report it back in the report via the @ErrorMessages table.  
--  - SAMPLE ERROR MSG:  Duplicate PRID error.  ProdUnit: MT55 Converter Production; Roll Conv ST: May 13 2003  9:26AM;   
--         Parent PRID: 6MB025A3133; Count: 2; Max EventId: 1926611; Min EventId: 1926559  
--  
-- 2005-JUN-28 Vince King  
--  - Modified code to use the @Events table to build @prsrun versus hitting the dbo.Events table once to check for duplicate PRIDs   
--      and then again to build @prsrun.  Saw some performance increase.  
--  
-- 2005-JUL-12 Vince King Rev6.90  
--  - Rev6.89 was not reporting correct values for GB data.  At some point, the sp became corrupt.  Not sure how, but I could not  
--      get it to run nor produce good results.  I took Rev6.88 and rebuilt the sp to include the 6.89 modifications.  
--  
-- 2005-JUL-28 Vince King Rev6.91  
--  - Totals were not returning correct numbers.  The intermediates section is correct, so I duplicated that code for the Line  
--    and Paper Machine sections.  The Totals line for Intermediates is being reported even though there are not intermediates in the report.  
--      This is in the template and will be resolved there.  
--  - Modified the Totals Line for the Intermediates to reflect only data for intermediates.  
--  
-- 2005-AUG-22 Vince King Rev6.92  
--  -  Modified JOIN in the population of @UWS to be robust against there being more than 1   
--   digit in the UWSOrder specification.  Per CvtgDDSStops Code (FLD)  
  
-- 2005-AUG-30 Vince King Rev6.93  
--  - Added @RptWindowMaxDays parameter to allow configuration for maximum number of days allowed to run the report.  
--  - Modified calculations to Paper Runtime to provide more accurate numbers.    
--   By Line/PaperSource is Sum(Runtime) - Sum(RuntimeExlude) where RuntimeExclude is all downtime coded as   
--   ScheduleId IN (@SchedPlannedIntvId, @SchedChangeoverId, @SchedPlnHygCleaningId, @SchedCLChecksAuditsId, @SchedHolidayCurtailId)  
--      OR td.ScheduleId IS NULL).  
--   For Line Totals Paper Runtime is Calendar Time - RuntimeExclude.   
--   For Report Totals Paper Runtime = (@LineCount * ((Calendar Time) - (RuntimeExclude)), roughly.  See code for exact calc.  
--  -  Modified calculations for Total ELP%, they had been inadvertantly modified during testing.  
--  - Added JOIN to @ProdLines back into the SELECT for Events.  All Lines were being selected and included in the check  
--   for duplicate PRIDs.  
--  -  When getting comments for 3.x sites, some (WITZ) do not have the Timed_Event_Summarys table because they were started up on   
--   a version of Proficy that does not use that table.  Added an IF statement to the comments update to check and see if  
--   the table exists, if it does, then continue with update, else do nothing.  
--  
-- 2005-SEP-01 Vince King Rev6.94  
--  -  Paper Runtime was not calculating correctly for a cvtg line and papermachine at MP.  Found that when runtime was updated in  
--   @PRSummary, it was only taking into consideration the CvtgPLId and the PM to summarize runtime.  In this case, for this  
--   particular cvtg line there were rolls for the specific PM that were from that PM AND the generic PMRolls prod line.  
--   So when the runtime was summarized, it included ALL runtime and was updated to both rows in @PRSummary, one for the PM and the   
--   other for the generic PMRolls.  This duplicated the runtime. Added code to WHERE clause to also take into account the ParentPLId.  
--  
-- 2005-SEP-06 Vince King Rev6.95  
--  - Modified SP to capture duplicate PRIDs and write errors to the @ErrorMessages table, but allow the report to continue and return  
--   results.  Modified @prsrun table to have index on ProdUnit and EventNum (instead of ParentPRID).  Added code to check for duplicate  
--   PRIDs in the @prsrun table.  If dups are found, messages are written to the @ErrorMessages table and @blnDupPRIDErrors is set to 1.  
--   @blnDupPRIDErrors is used when checking errors in @ErrorMessages at the time that Result Sets are returned.  If Dup PRID errors are  
--   in @ErrorMessages table, then the sp continues and returns ALL result sets.  The template will be modified to return report AND  
--   error messages in Errors sheet.  
--  
-- 2005-SEP-07 Vince King Rev6.96  
--  -  Modified Paper Runtime Calc on Intermediates Total line to use @INTRLineCount for total intermediate lines instead of @LineCount.    
--   Changed Paper Run By in intermediate section to be actual Cvtg Line Desc without 'TT' or 'PP' prefix.  
--  
-- 2005-SEP-12 Vince King Rev6.97  
--  - StartTime was not being included when checking for duplicate PRIDs.  The check now includes PUId, PRID and StartTime.  This allows  
--   Parent Rolls to be loaded ran, removed and then ran again at a later time.  
--  
-- 2005-SEP-27 Vince King Rev6.98 Performance Tuning  
--  - Removed cursor used to update Runtime and number of Rolls in the @PRSummary table.  Created a Table Variable @PRSum and populated it  
--   with CvtgPLId, PaperMachine and ParentPLId from the @PRSummary table.  Then JOINed @PRSum and @PRSummary in an UPDATE statement that  
--   updates the Runtime and Rolls in @PRSummary.  This eliminates the need to use a cursor to get CvtgPLId, PaperMachine and ParentPLId  
--   in variables to be used in the SELECT statements.  Profiler comparisons revealed the following results for a single day:  
--       With Cursor       Without Cursor  
--    CPU:    51563         50234  
--    Reads:   581314        579912  
--    Writes:   23          0  
--    Duration:  62016         50626  
--  - Removed WHILE loop used to populate @ProdLines and replaced with an INSERT and several UPDATEs.  Reduced the reads from 579912   
--   to 578929, CPU, Writes and Duration remained same.  
--  - Modified Total Lines to correct calculations for Paper Runtime and Total ELP %.  Changed Intermediates section and PaperMachines section  
--   to use Sum of Runtime minus Sum of Runtime Exclude.  Thsi was also used in Total ELP % calculation.  
--  -  Corrected bug where Paper Runtime and Total ELP % was not being calculated for Line Section for NOAssignedPRID.  
--  - Found discrepencies between data in LineSchedTime table (Scheduled Time) and PRSummary table (RuntimeExclude) that was causing   
--   calculations to not match.  Modified all references for Scheduled downtime to be NOT IN (Special Causes, Unscheduled, PR Poly,  
--   EO Projects and Blocked Starved). Removed references for @LineSchedTime.SchedTime and replaced with @PRSummary.RuntimeExclude for  
--   consistency.  
--  -  Modified Result Set 2 Line/PaperSource to return NULL for Fresh/Storage Runtimes and Fresh/Storage ELP% when PaperSource = NoAssignedPRID.  
--  - Modified the code that selects comments for #Delays.  It Converted to VARCHAR, but did not specify length.  This caused the comment(s)  
--   to be truncated.  Changed code to be VARCHAR(5000).  
--  
-- 2005-OCT-12 Vince King Rev6.99  
--  - Removed code in UPDATE statement for #Delays PaperSource and PaperRunBy columns for Input_Source = 2.  Found that on the second UPDATE  
--   the values were getting incorrectly reset.  
--  - Corrected problem with comments getting truncated.  The comment was being Converted to VARCHAR, modified the code to VARCHAR(5000).  
--    
-- 2005-OCT-17 Vince King Rev7.00 Rewrote changes from 2005-Oct-05, never rolled out.  
--  - Modified code to use current running UWS with lowest Input_Order to assign PRIDs to downtime events.  Added PRSEventId column to #Delays  
--   table to link to the specific @prsrun record.  Updated PRSEventId by selecting the lowest Input_Order UWS PRID for the PUId, StartTime and   
--   EndTime.  
--  -  Added InputOrder to various tables in order to determine lowest Input_Order and use it to get the current running PRID.  This works for   
--   Facial since at any given point in time, an UWS may or may not be running.  Therefore, Input_Order = 1 will not always work for Facial.  
--   This approach ensures that a PRID is captured for Facial lines and should not change how the Tissue/Towel lines are currently getting  
--   a PRID assigned.  
--  -  Also added PLId to the error message for duplicate PRIDs.  
--  - Removed all references to @LineSchedTime.  Due to the changes in how Paper Runtime is calculated, @LineSchedTime is not needed.  The  
--   last use was with RepFactor, once we made the changes to Runtime, RepFactor was no longer required.  
--  
-- 2005-NOV-14 Vince King  Rev7.01  
--  - Performance tuning.  
--  - Added dbo. to all references to temporary and permanent tables.  
--  -  Added @WastenTimedComments table to prevent multiple JOINs to the Waste_n_Timed_Comments table in the db.  
--  - PUDesc was not getting updated on all #Delays rows.  Found where PUDesc was updated prior to the code that gets rows that start prior to  
--   or after the report period.  Moved the PUDesc code to be after that code.  
--  -  Modified various code and tables so that temporary tables and/or variable tables could be used in places where the actual db tables were  
--   being accessed.  
--  - Modified code that returns an error message when duplicate PRIDs exist to show PUDesc instead of PUId.  
--  - Added this UPDATE to capture the UWS assocated with the DT Event by using the PEI_Id that was already a column in @prsrun and @UWS.  The Event_Id   
--   (PRSEventId) is used and added to the #Delays table for each downtime event.  This provides a direct link to the running PRID in the @prsrun table.  
--  - Modified code to only update PRSEventId when NULL.  
--  - Changed all EXEC (SQL) to EXECUTE sp_executesql @SQL, per tuning changes from DDS-Stops.  
--  - Added SET NOCOUNT ON at beginning of sp and SET NOCOUNT OFF at end of sp.  
--  - Added OPTION (KEEP PLAN) to ALL SELECT statements.  
--  -  Came full circle.  I removed all references to the RuntimeExlude column(s) and changed the code to use the prs.ScheduledDT column.  The Total ELP%  
--   was in some cases slightly different than the Excel calc of [Paper DT] / [Paper Runtime] based on the cells in the report.  This was because   
--   RuntimeExclude was summing the DT from the events, but it was not taking into account the possibility of some of the downtime occuring across  
--   multiple PRs.  ScheduledDT took this into account so I went with it.  
--  - Added @PRRuntime table to determine which Input_Source to use to get the maximum Runtime for the @PRSummary.  
--  
-- 2005-Nov-15 VMK Rev7.02  
--  - Added @Dimension, @CrewSchedule, @ProductionStarts, @Products, @TECategories and @Primaries table per spLocal_RptCvtgDDSStops tuning changes.  
--  - Added code to populate the above mentioned tables.  
--  -  Added @Runs table to get Start and End Times for each Dimension.  Currently only using Line Status Dimension.  
--  - Modified the code to build the @PRSummary table to incorporate the @Runs table.  This uses the Start and End Times from the @Runs (LineStatus   
--   dimension) table and compares them with the Start and End Time in the #Delays table.  It allows us to summarize the data by   
--   PL_Id, PaperSource, PaperRunBy, GrandParentPM, ParentPM, INTR, ParentPLId and LineStatus.  
--  
-- 2005-Dec-07 VMK  Rev7.03  
--  - Added @LineStatusList parameter.  This will be used to 'filter' result sets based on Line Status.  The list will include 1 or more Line Statuses  
--   to include in the results.  
--  - Incorporated @LineStatusList in SELECT statements for Result Sets to 'filter' data by Line Status list.  
--  - Removed all references to @INTRLineCount.  It is not used in the report.  
--  - Modified the SELECT statements for the result sets for Line Totals and Overall Totals to SUBTRACT out the Runtime that is NOT part of the  
--   Line Status(es) in the @LineStatusList.  
--  
-- 2005-Dec-16 VMK Rev7.04  
--  - For Line Totals and Overall Total for PaperSource, the Runtime was not being calculated correctly when the RptLineStatusList was an empty string.  
--  - Added code to calculation to check for 'empty string', if yes, then 0.0 is returned, else check to see if the LineStatus is included in the   
--   @LineStatusList variable.  This filters unwanted LineStatus from the result set(s).  
--    (CONVERT(FLOAT, DATEDIFF(second, @StartTime, @EndTime) / 60.0))   -- 2005-AUG-28 VMK Rev6.93  
--     - SUM(CONVERT(FLOAT, prs.ScheduledDT) / (60.0))  
--     - (CASE WHEN @LineStatusList <> '' THEN          -- 2005-DEC-16 VMK Rev7.04  
--       SUM((CASE WHEN (charindex('|' + LineStatus + '|', '|' + @LineStatusList + '|') = 0) THEN  
--          prs.Runtime   
--         ELSE 0.0 END) / 60.0)  
--      ELSE 0.0 END) [Paper Runtime],     -- 2005-DEC-07 VMK Rev7.03 Added LineStatus check.  
--  
-- 2005-Dec-20 VMK Rev7.05  
--  - Scheduled DT was not being accurately captured since it was not being split by PaperMachine.  You may have an event that spanned across  
--   more than 1 Parent Roll and the parent rolls could be from different papermachines.  
--  - PaperMachine was added to the @Dimensions table as a new dimension.  But not in the same way as the other dimensions.  Since  
--   PM is based on the report data and not 'independent' like the other dimensions, we are really just using the @Dimensions table  
--   to capture the different time periods for the Paper Machines.  
--  - We can then summarize the Scheduled DT, Storage Sched DT and Fresh Sched DT for each PaperMachine and get an accurate number  
--   to be used for calculating Paper Runtime, Storage Runtime and Fresh Runtime.  
--  - Added COALESCE to some of the COLUMNS in the SELECTs for Result Sets.  NULL was being returned in some cases.  For instance,  
--   if there were no Scheduled DT, then Paper Runtime was not being returned.  
--  
-- 2005-Dec-23 VMK Rev7.06  
--  -  Fresh and Storage ELP% were showing zero when there were stops associated with them.  Found that NULLs were being included in the calculations.  
--   Modified code using COALESCE to change NULLs to zeros.  
--  
-- 2006-JAN-11 VMK  Rev7.07  
--  - Paper Runtime was not correct for Line and Overal Totals.  Found where Scheduled DT was not being captured for events with NoAssignedPRID.  I  
--   added the @LineSchedTime table back into the code in order to capture the TOTAL scheduled downtime for each line.  
--  - Then modified the Cvtg Line (Section 1) Line Total and Overall Total to include @LineSchedTime.SchedTime in calculation.  
--  - Still was not getting an accurate Paper Runtime for Line and Overall Totals.  The Scheduled DT for NoAssignedPRID events was being duplicated and   
--   so we were subtracting too much Scheduled DT.  This was discovered after correcting the problem mentioned above.  
--    I found where the 2nd INSERT into @PRSummary was no longer needed based on the @prsrun changes that I had made.  The NoAssignedPRIDs are   
--   captured in the 1st INSERT.  
--  - Found where SQL was not handling NULL values very well in JOIN statements when linking tables.  This was causing us to miss some Scheduled DT on   
--   some lines while other lines were calculating correctly.  I added a JOIN to @prsrun in the SELECT statement for INSERTing rows into @LineSchedTime.  
--   This gave me consistency between tables (@PRSummary and @LineSchedTime) and provided a one to one link between rows that SQL could handle.  
--2005-JAN-19 Namh Kim  Rev7.08  
--   Modified Linestatuslist value when a value of Linestatuslist is null or '', put a 'All' in value for Linestatuslist.  
--2005-JAN-19 Namh Kim  Rev7.09  
--   To fix problem, @linestatuslist <> '' changed to @linestatuslist <> 'All' because '' values changed to 'All' in version Rev7.08.  
--  
-- 2006-FEB-09 VMK Rev7.10  
--  -  Found where PR data was not being compiled with consideration for LineStatus.  This was discovered when a LineStatus change occurred on MNN4 in MP.  
--  - Modified code and added LineStatus to @prsrun table.  Then added code to SELECT data by LineStatus in addition to other groupings.  
--  
-- 2006-FEB-27 VMK  Rev7.11  
--  - Totals were not matching with PmkgDDSELP stored procedure.  Found where some Scheduled DT was not being captured.  
--  - Modified code to add PaperMachine dimension to the @Runs table and then added code to UPDATE the PaperMachine column.  
--  - Changed SELECT statements that summarize Scheduled DT so that they use the @Runs table.  This combines ALL dimensions and thus includes all  
--   downtime.  
--  - Was not including Line Status as a 'grouping' when summarizing data in @PRSummary table.    
--  
-- 2006-MAR-01 VMK Rev7.12  
--  - With Rev7.11 changes to @Dimensions table (having to add same dimension for multiple PUIds, Reliability and Production) we were returning  
--   more than 1 row in the updates of dimensions for LineStatus and PaperMachine.  Added a GROUP BY to @Dimension INSERT and TOP 1 to SELECT for  
--   UPDATES of @Runs table.  
--  - Added COALESCE to some of the columns in the ELP% calculations.  The ELP% was not being returned when at least one of those columns was  
--   equal to NULL.  
--  
-- 2006-MAR-01 VMK Rev7.13  
--  - Found a couple of columns that were missed when adding COALESCE to handle NULL values in ELP% calcs.  
--  - Removed code in Total By PaperMachine result set that was allowing a divide by zero error.  
--  
-- 2006-Mar-27 VMK  Rev7.14  
--  - Modified sp to include NoAssignedPRIDs in @prsrun table. This allows the NoAssignedPRID data to be captured through out the sp.  
--  - Made multiple changes to use the NoAssignedPRID @prsrun data throughout the sp.  This allows us to calc the Runtime for NoAssignedPRIDs.  
--  - Added IDENTITY column (Id_Num) to @prsrun table.  Changed Primary Key to be Id_Num, PUId, StartTime.  Modified code through out  
--   sp where Event_Id was being used to join to the @prsrun table and changed it to be Id_Num.  This allows us to use unique key for joins.  
--  - Changed column size for PaperMachine in several tables.  Values were getting truncated when NoAssignedPRID was added.  
--  - Added LineStatus column to @PRRuntime and @PRRuntime tables.  
--  - Set Line Status to default of Rel Inc:Qual Unknown when it is not available.  
--  - Removed @LineSchedTime from sp, since we have all runtime including NoAssignedPRID, we do not need it.  
--  - Removed Input_Order from Group By when populating @PRSummary, MIN(Input_Order) is used in select and should not  
--   be included in GROUP BY.  It was causing duplicate rows in @PRSummary.  
--  -  Added the ParentPLId and InputOrder dimensions to the @Dimensions table and the @Runs table.  Incorporated those dimensions in the calculation  
--   of runtime.   
--  - Added code to check and make sure that there is at least 1 entry in @prsrun for each PLId in @ProdLines.  Found that some of the non-US sites  
--   were not getting any PRs picked up for the report and with the changes above, no data was reported.  
--    
-- 2006-MAR-28 VMK  Rev7.15  
--  -  Modified @prsrun table to include AdjPREndTime column.  This column will have the actual EndTime of the PR before the endtimes are adjusted  
--   to prevent overlap and to fill in missing times.  This will be reported with the @prsrun data on the PRsRun sheet in the report.  
--  - Added additional result set for @prsrun data.  
--  
-- 2006-APR-05 VMK  Rev7.16  
--  -  Added additional COALESCE in compare statements used in WHERE clauses.  
--  - Added additional columns (PaperSource, PaperRunBy, INTR) to @PRSum table.  
--  - When adding @prsrun rows for time slices not originally captured, the code was picking up the previous PR run by PUId.  Modified the code  
--   and added PEIId so that it would get the previous PR run for the same PEIId.  
--  - Removed WHERE statement when inserting an @prsrun row when there is no record to cover from @StartTime to first PR row.  
--  - In UPDATE of individual dimension columns in @Runs the code had: and d.starttime < r.endtime and (d.endtime > r.starttime or d.endtime is null).  
--   But we found a case where the r.endtime equaled d.starttime, so we needed to include that possibility.  Changed code to and d.starttime <= r.endtime   
--   and (d.endtime >= r.starttime or d.endtime is null)  
--  
-- 2006-APR-07 VMK Rev7.17  
--  - Events in pivot table with NoAssignedPRID were being duplicated.  The JOIN to @prsrun table was modified in earlier versions and not  
--   changed in result set for pivot table.  
--  
-- 2006-APR-11 VMK  Rev7.18  
--  - Reversed change Intermediate to INTR in code to update PUDesc.  Intermediates were not showing up in Line section.  
--  
-- 2006-APR-12 VMK  Rev7.19  
--  - Paper Runtime was not showing up correctly in MP, it was less than the Fresh Runtime being report.  In an earlier version, the Runtime  
--   calculation had been modified so that it was calculated against the @Runs table.  Changed back to original code to use @prsrun table.  
--  - Duplicate rows being added into the @prsrun table.  Modified code that captures missing time slices in @prsrun table.  
--  - Modified code to return result set for PRsRun sheet.  It was returning Runtime in Rpt Window as ADJ Runtime in Rpt Window.  I remember  
--   thinking this was more complicated than it needed to be, apparently I made it so.  :)  
--  
-- 2006-MAY-03 VMK Rev7.20  
--  - We needed the ability to accurately capture Paper Runtime for intermediate lines.  The problem is that the INTR lines can have up to 70 unwind stands  
--   running at one time.  In order to do this, the code was modified to capture runtime for ALL unwind stands on a line.  This is organized by PEIId, which  
--   is the Id for input units in the PrdExec_Inputs table.  We have already filled in times on unwind stands where there is no paper machine defined.    
--   Therefore, we have captured all of the report period time for each UWS.  
--  - Since there will most likely be more time than is defined by the report period due to multiple UWSs (even T/T lines may have more than one UWS), we   
--   must adjust the runtime and downtimes to account for it.  
--   The NoOfUWSRunning column was added to the @ProdLines table and updated with the number of UWSs running on the line during the report period.  This  
--   number is used to adjust the runtimes and downtimes (ELP, RLDowntime, Sched DT, etc).  
--  - Added code to determine maximum amount of Runtime for NoAssignedPRID.  
--  - Found where the time slices that are being filled in the @prsrun table were not working correctly.  Added a check for PEIId.  
--  - Added PLId to code where #Delays record is captured after initial INSERT.  It was not being filled in.  
--  - Columns were not getting updated correctly.  Added COALESCE to code for update of @TopPRRuntime table.  
--  -  Could not get an accurate @PRSummary table when using #Delays columns for GROUP BY.  Modified code to assign required columns in the @prsrun table.  
--   This works very well since we now account for ALL time on ALL PEIIds.  
--  - Reworked code with respect to @Runs.  Added additional Value(x) columns to @Runs to capture data with 1 to 1 association.  Such as PEIId, InputOrder,  
--   ParentPLId, etc.  
--  - Modified Result Sets to account for capturing runtime for ALL PEIIds.  This required adjusting data based on the number of PEIIds and/or Lines in  
--   the report.  *** Major Modifications Here ***  
--  - Added PEIId comparison in code to update @Runs with @prsrun columns.  
--  - Added pl.NoOfUWSRunning > 0 to WHERE in result sets.  When there were prod_lines in @ProdLines that did not have any PR runtime, it was affecting   
--   the calc values.  
--   
-- 2006-MAY-04 VMK Rev7.21  
--  - Found where @prsrun_Columns were not being assigned correctly all of the times in @Runs.  Modified the WHERE clause in @Runs update.  
--  
-- 2006-MAY-08 VMK Rev7.22  
--  - Modified the code to INSERT rows into @PRSummary table so that the primary table selected from is the @Runs table.  Then the downtime data is  
--   summarized from the #Delays table based on start and end times in the @Runs table.  
--  
-- 2006-MAY-11 VMK Rev7.23  
--  - Due to the changes to have @PRSummary built based on @Runs which is built based on @prsrun, the PaperRunBy columns was not getting populated  
--   correctly.  This particularly showed up on INTR lines.  Modified code where PaperRunBy gets assigned for @prsrun table.  
--  - Modified Result Set code so that the INTR lines Runtime is not adjusted.  This will allow the total runtime to be reported for ALL unwind   
--   stands.  The stops, downtime and ELP calcs are calculated from adjusted amounts, which is really the actual values.  
--  
-- 2006-MAY-15 VMK Rev7.24  
--  - The PaperMachine in the @Runs update for @prsrun_Columns was not specifying the @Dimension = '@prsrun_Columns' and we were getting a   
--   conversion error.  
--  
-- 2006-MAY-21 VMK  Rev7.25  
--  - Rate Loss downtime was not being included in the report.  When the sp was modified to summarize (group) data using the @Runs table, the rows  
--   were linked by PUId.  This prevented the Rate Loss PU from being included.  Modified JOIN so that it is by PLId, which will include all  
--   Prod Units.  The WHERE clause limites to '%Converter%' and '%INTR%'.  
--  
-- 2006-MAY-21 VMK Rev7.26  
--  - Modified code so that Downtime and Stops are summarized for Lowest_PEIId only.  This prevents us from having to 'adjust' the values due to  
--   multiple UWS running.  In some cases, the rounding of the numbers were not giving us accurate values for totals vs. details.  
--  - Modified result sets to return ALL Runtime for Facial lines by checking to see if LEFT(PLDesc, 2) = 'PP'.  If it is not a Facial line, then  
--   adjust the runtime(s) based on @ProdLines.NoOfUWSRunning.  
--  - FLD found where sched dt was not being included for NoAssignedPRID, but I actually found where it was not limited to NoAssignedPRID.  There  
--   was downtime being missed due to how the datetime selection was setup.  If the StartTime was less than the @StartTime, it was not getting   
--   included.  
--  - Also added @ProdLines.NoOfUWSRunning as a column to the @prsrun result set.  This allows the user to know what factor was used in calculating  
--   ELP% for Facial lines.  
--  -  Found where ELP Downtime did not match the total Downtime in the ELP Pivot table.  After investigation, realized that the InRptWindow column  
--   was being used to filter events from the pivot data that were not within the report window.  Added InRptWindow = 1 to the WHERE clause for  
--   the initial INSERT of downtime data into the @PRSummary table.  
--  - Storage DT was not matching what was being reported in the ELP Pivot table.  Found where Storage Stops had been duplicated and in the place of  
--   Storage DT.  Corrected on all Result Sets.  
--  
-- 2006-MAY-22 VMK Rev7.27  
--  - Added td.PUDesc LIKE '%Converter%' OR td.PUDesc LIKE '%INTR%' to CASE statements for @PRSummary INSERT.  It was picking up other prod units DT.  
--  
-- 2006-JUN-10  Langdon Davis Rev7.27INT  
--  -  Constrained the '@prsrun_Columns' insert from @Dimensions into @Runs to WHERE PEIId IS NOT NULL to avoid the report crashing due to issues  
--   with the population of the UWS variable.  
--  
-- 2006-JUN-12 VMK Rev7.29  
--  *** There was a Rev7.28 floating around although I don't believe it was used, but to prevent confusion I went with Rev7.29.  
--  -  Modified code to Add NoAssignedPRID rows in @prsrun to beginning and end of time frame where there is a gap for each PEIId.  
--  -  Modified code to INSERT INTO @PRSummary.  It was not picking up the ScheduledDT associated with NoAssignedPRID for FF7A.  Found that it was   
--   actually missing based on when the DT event matched with @Runs times.  Modified JOIN to #Delays so that when any part of an event is within   
--   the time period of an @Runs row, it is included and the time calculated correctly.  
--  - Changed column name PRSEventId to PRSIdNum to better reflect data being stored.  
--  - Changed @PRSummary INSERT to summarize downtime and stops data where r.PRSIdNum = td.PRSIdNum.  Since each downtime event is associated with  
--   a specific parent roll, we are able to use this to assign the stops and downtime to the correct PaperSource, PaperMachine, etc.  
--   *** The runtime is not adjusted for Facial Lines (prefix = 'PP').  For all other lines, the runtime is adjusted based on the number of UWSs  
--     that ran during the report period.  This equates to the number of rows that show up in @PRSummary, which duplicates runtime that number  
--     of times.  Facial lines will typically show more Total Runtime than time in the report period.  
--  
-- 2006-JUN-13 VMK Rev7.30  
--  - Added code to remove NoAssignedPRIDs from Fresh Rolls Ran, Storage Rolls Ran and Total Rolls Ran.  
--  - Modified all Runtime calculations to adjust Sched DT based on NoOfUWSRunning.  
--  
-- 2006-JUN-19 VMK Rev7.31  
--  - Added code to @PRSummary update for Fresh/Storage runtime and Rolls ran to not include rolls assigned to '%PM00 Rolls' unit.  
--  
-- 2006-JUN-26 VMK Rev7.32 (For FLD)  
--  -  All sites missing Fresh and Storage Rolls ran data on ELP report.  Code was linking pr.PRPLId = pu.PU_Id.  Modified code to have   
--   pr.PUId = pu.PU_Id  
--  
-- 2006-JUL-12 VMK  Rev7.33  
--  -  Changed several column names.  Added Pmkg Product Desc to pivot table result set.  Add Paper Runtime to the pivot table results data.  
--  -  Added PRoll Runtime and ScheduledDT to #Delays.  Added Paper Runtime (PRoll Runtime - ScheduledDT) in pivot result set.  
--  -  Modifications to add ELP% to pivot table.  
--  - Changed CONVERTed to Converted throughout sp.  
--  - Changed RptPmkgOrCvtg to intRptPmkgOrCvtg in parameter retrieval section.  
--  
-- 2006-SEP-25 VMK  Rev7.34  
--  - Added code to capture downtime events for UWS Reliability prod units in Facial.  The downtime from the UWS Reliability units is  
--   used to determine amount of time that the UWS is in running status, but is not actually running.  The time is subtracted from   
--   the Runtime for the specific UWS (PEIId).  
--  - Also added the UWS downtime as a column in the @prsrun result sheet.  This will help users to determine the correct runtime when  
--   validating the report or looking at raw data.  
--  - Added NoOfUWSRunning to @prsrun table to adjust Runtime.  Added Cvtr Downtime columns to @PRSummary table.  Added Cvtr Downtime (Min) to   
--   @prsrun result set.  
--  - The NoOfUWSRunning column in @prsrun is updated based on whether the line has UWS Reliability units or not.  If the line does have   
--   the UWS reliability units, then the number of UWS running is based on downtime of the UWS Reliablity units.  Otherwise, it is   
--   set to COUNT DISTINCT of PEIId from the @prsrun table.  
--  
-- 2006-SEP-27 VMK Rev7.35  
--  - Were not capturing runtime correctly when a line changed from 1-ply to 2-ply product (or vice versa).  Modified sp to assign  
--   NoOfUWSRunning column in @prsrun table to be based on the number of DISTINCT PEIIds in @prsrun at the StartTime of the PR.  
--  - Also removed the code that fills in the gaps before the first @prsrun entry and the last @prsrun entry based on PEIId.  
--  - Due to removing that code had to make modifications to the code for updating @Runs columns.  
--  - Also had to change how the Endtime is updated for @Runs.  If the EndTime was NULL it was defaulted to the @EndTime of the report.  
--   Since we are not creating those filler rows, this causes us to have too much runtime.  Changed code to look up the corresponding   
--   @Dimensions row and use the EndTime for @Runs row with EndTime = NULL.  
--  
-- 2006-OCT-09 VMK Rev7.36  
--  - Getting negative runtimes on GK22 in Cape.  
--  - When calculating FreshRuntime, StorageRuntime and OverallRuntime, the sp was excluding PM00 Rolls PRs and this was causing in some  
--   cases for the Scheduled DT to exceed the runtime.  Thus, a negative runtime.  Commented out that code.  
--  - Also moved SET ANSI_WARNINGS OFF from below testing comments to above with SET NOCOUNT ON, per Langdon Davis (Jeff Jaeger testing).  
--  
-- 2006-Nov-02 VMK Rev7.37  
--  - Added code that will better calculate Runtime for Facial lines in GB.  There are two lines, FFF7 and FF7A, that share Unwind Stands.  
--   Code was added that distinquishes which UWSs are running on which lines.  Then this is used to determine the number of UWSs running.  
--   That is then used in combination with the UWS Reliability units on FFF7 to determine if an UWS is running or not.  For Facial, they  
--   may load a PR on an UWS, but not actually start running it.  The UWS Reliability units captures downtime on those Unwind Stands.  Then  
--   by comparing the downtime with the Events data, we can determine what unwind stands are loaded but not running and which are loaded  
--   and running.  The factor, Unwind Stand downtime - Converter Downtime, will be used to adjust the Runtime and remove the time associated  
--   with loaded but not running.  
--  - As of 2006-Nov-02, the majority of this code is commented out until a correction in the configuration can be completed.  The UWS Total  
--   Downtime should always be >= the Total Cvtr Downtime, but this is not currently the case.  Code was commented out to keep UWS downtime   
--   and Cvtr Downtime columns = 0 until the configuration is corrected.  
--  
-- 2006-Nov-02 VMK Rev7.38  
--  - The calculation for NoOfUWSRunning in @prsrun for the FFF7 line was not using the UWS Reliability units downtime events to determine the  
--   correct number of UWSs that were running for FFF7.  The calculation for the FF7A line was correct and should have been implemented for  
--   FFF7.   
--  - Modified the code to use the calculation for FFF7 as well as FF7A.  
--  
-- 2006-Nov-17 VMK  Rev7.39  
--  - Added #Events code from spLocal_RptPmkgDDSELP stored procedure.  Added associated code to build @prsrun using event_history table  
--   instead of Tests table.  
--  - Were not picking up all ScheduledDT.  Changed the code assigning PRSEventId in #Delays so that it uses an actual PR event and does not  
--   not pick up NoAssignedPRID.  
--  - Changed the code that populates the @PRSummary table so that ScheduledDT is accurately accounted for.  
--  - Modified the Result sets for Line/PaperSource, By Line and Papermachine by Paper Run By so that for Facial lines LIKE 'PP FF', if the  
--   runtime is greater than the report period, then it is defaulted to the report period.  
--  
-- 2006-Nov-20 VMK  Rev7.40  
--  - When putting in the #Events code from PmkgDDSELP, missed populating the PRPLId column in @prsrun table.  This prevented the   
--   INTR column from being populated in @Dimensions --> @Runs --> @PRSummary so the INTR result set section was not being reported.  
--   Added PRPLId to @prsrun and resolved the problem.  
--  - Added CONVERT to StartTime and EndTime when retrieving from Event_History table.  Some of the datetime values for TimeStamp and Entry_On   
--   were showing .1 of a second in the date/time.  This was causing the sp to create NoAssignedPRID records in @prsrun with .1 of a second  
--   runtime which rounded to 0 runtime.  The CONVERT statements round to the nearest second.  
--  
-- 2006-DEC-03 VMK Rev7.41  
--  - Removed some code that was filtering out NoAssignedPRID @prsrun rows when assigning a value for NULL PRSIdNum and UWSLocation columns.  
--   Now that we can better handle those NoAssignedPRID rows, we can allow that assignment to occur and then summarize in the appropriate  
--   rows in @PRSummary.  
--  
-- 2006-DEC-11 VMK Rev7.42  
--  - We were picking up some duplicate rows in #PRsRun.  It turned out to be due to an OR statement in a JOIN in the  
--   SELECT.  Changed it to use a COALESCE instead of using the OR and solved the problem.  
--  
-- 2007-JAN-24 VMK Rev7.43  
--  - Applied #Events/@prsrun code changes from spLocal_RptPmkgDDSELP Rev8.24 and Rev8.25.  
--  - Applied code changes from spLocal_RptPmkgDDSELP up through Rev8.34.  
--  
-- 2007-MAR-16 VMK Rev7.44  
--  - Implemented code changes from spLocal_RptPmkgDDSELP that handled the Overlap issues in PRsRun.  
--  - Moved some code at the end of the SP that updated the NoOfUWSRunning column in ProdLines.  It was already executed earlier in the SP.  
--  - Changed the calculation of PRollRuntime column to use NoOfUWSRunning in @Runs table instead of ProdLines.  
--  - Removed some of the comments to clean up the code.    
--  - All of these changes can be found by searching on 'Rev7.44'.  
--  
-- 2007-APR-10 VMK Rev7.45  
--  - Paper Run By was not correct in Intermediate results sets.  Found where PRPLId was being populated based on the initial event  
--   instead of the source event.  Modified code that populates @prsrun to correct.  
--  
-- 2007-JUN-05 FLD Rev7.46  
--  -  Removed earlier changes done to use Alternate_Event_Num for the PRID instead of   
--   the Tests PRID result.  This is necessary because with interplanted paper, we only have the PRID result.  
--  - Added a parameter check for start and end time being the same.  This avoids a bunch of processing and   
--   errors on the VB side from empty/NULL results sets.  
--  -  Defaulted LineStatus to 'Unknown;Unknown' when NULL versus 'Inc;Unknown'.  
--  - Modifed UPDATE of PrsRun grandparent information to use the extended info GlblDesc vesus VarDesc  
--   in the WHERE clause since VarDesc is not guaranteed to be in English.  
  NOTE:  These were all changes in Rev7.44PRIME and 7.44PRIME+ that Vince did not reapply in 7.45.  
  
2007-06-19 Jeff Jaeger Rev7.47  
 -  added RateLossPUID to the puid restriction in the population of @PRSummary.   
 - changed time measures in the sp tables to float data types instead of integer.  
 - ensured that when a time measure is calculated, any denominator is in float data type.  
 - ensured that all time measures are in seconds.  
 - moved the declaration of @DupPrids and @TopPRRuntime so that they are declared   
  where the other @tables are declared.  
 - cleaned up a lot of dead code.  see the  previous revision in VSS if needed...  
  
2007-JUL-10 LAngdon Davis Rev7.48  
 -  prs.StorageRLDT and prs.FreshRLDT were not getting converted from seconds to minutes in the   
  results sets, resulting in a mismatch of UOM since the Fresh and Storage Paper DT was in minutes.  
 -  Added ' WITH(NOLOCK)' to all SELECT's and JOIN's involving Proficy and/or temporary tables.  
  
2007-07-23 Jeff Jaeger Rev7.49  
 - added PMTeam to @prsrun  
 -  added updates to @prsrun that will correctly populate ParentTeam, GrandparentTeam, and PMTeam.  
 - changed the population of [PM Team] in the result sets.  
  
2007-09-27 Jeff Jaeger Rev7.50  
 - changed the left join for PRID test values in the insert to #PRsRun.  
  
2008-04-17 Jeff Jaeger Rev7.6  
-- find these changes by searching on "--Rev7.6".  
- changed the index on #delays.  this is intended to reduce the number of reads required when running this sp.  
- changed the structure and index of the #events table.  
- removed the @TECategories, @FirstEvents because they aren't used anymore.  
- removed the use of @CatBlockedStarvedID, @PropCvtgProdFactorId, @SchedPlannedIntvId,   
@SchedChangeoverId, @SchedPlnHygCleaningId, @SchedCLChecksAuditsId, @SchedHolidayCurtailId,   
@SchedMeetingsId, @SchedScheduledId, @UWSVarId, @DBVersion, @SQL4EventHistory,  
@SQL4EventHistoryBeforeReportWindow, @SQL3Events, @SQL3EventHistory,   
@SQL3EventHistoryBeforeReportWindow, @SQL3EventsBeforeReportWindow , which are not used any more.  
- added @VarInputRollVN, @VarInputPRIDVN, which are used to pull GrandParentPRID and GrandParentPM.  
added @LinkStr for use while populating @IntUnits.  
- in #Delays, removed NoOfUWSRunning, PRSIdNum, UWSLocation.  all of these fields are used   
in relating one downtime event to one parent roll.  since we aren't doing that anymore, these   
fields are not required.  
- added the temporary table #LineMachineELPByUWS.  This will be used to generate an additional   
result set by Line / Paper Source / UWS.  
- added the temporary table #LineMachineELPByUWS2.  this will be used to generate an additional  
result set by Paper Machine / Paper Run By / UWS.  
- added the temporary table #LineMachineELPByUWS3.  this will be used to generate an additional   
result set by Intermediate / Paper Run By / UWS  
- added the UWS field to #LineMachineELP, #LineELP, #ReportELP, #LineMachineELP2,   
#MachineELP2, #ReportELP2, #LineMachineELP3, #LineELP3, #ReportELP3, #Stops.  
- in #Stops, [UWS1 PRoll Made By], [UWS1 GPRoll Made By],[UWS2 PRoll Made By],   
[UWS2 GPRoll Made By].  Also removed [PRoll Runtime] because it doesn't really have   
any meaning anymore, and SchedDT because it isn't used anymore.  
- removed @LineStatus and @LineStatusRaw table variables since they are no longer used.  
- added @IntUnits and related code.  
- removed AdjPREndTime since it doesn't appear to be used anymore and removed   
NoOfUWSRunning from @prsrun.  
- added the following to @prsrun: FreshRolls, StorageRolls, TotalRolls, ELPStops,   
ELPDT, ELPSchedDT, RLELPDT, RLDT, FreshStops, FreshDT, FreshRLDT, FreshRuntime, StorageStops,   
StorageDT, StorageRLDT, StorageRuntime, FreshSchedDT, StorageSchedDT, PaperRuntime.  These   
metrics are now tracked through the parent rolls for summarizing according to different   
grouping conditions.    
- added to @prsrun: StartTimeLinePS, EndTimeLinePS, StartTimeLine, EndTimeLine, StartTimeIntrPL,   
EndTimeIntrPL, StartTimePMRunBy, EndTimePMRunBy.  These are used to define the timeframe of   
each parent roll to be related to the various time groupings.  It is determining these time ranges   
that allows us to eliminate the overlap in PaperRuntime, downtime, stops counts, etc.  
- added to @prsrun: RunTimeLinePS, ELPSchedDTLinePS, FreshRuntimeLinePS, StorageRuntimeLinePS,  
PaperRuntimeLinePS, RunTimeLine, ELPSchedDTLine, FreshRuntimeLine, StorageRuntimeLine,  
PaperRuntimeLine, RunTimeIntrPL, ELPSchedDTIntrPL, FreshRuntimeIntrPL, StorageRuntimeIntrPL,  
PaperRuntimeIntrPL, RunTimePMRunBy, ELPSchedDTPMRunBy, FreshRuntimePMRunBy, StorageRuntimePMRunBy,  
and PaperRuntimePMRunBy.   
- removed the following from @prsrun since they aren't used anymore:  UWSTotalDT, UWSStorageDT,   
UWSFreshDT, CvtrTotalDT, CvtrFreshDT, CvtrStorageDT.  
- added @PRDTMetrics, which is used as a more efficient way to summarize metrics according to the   
various timeframe groupings.  
- instead of @PRSummary, the sp now uses @PRSummaryUWS, @PRSummaryLinePS, @PRSummaryLine,   
@PRSummaryIntrPL, @PRSummaryIntr, @PRSummaryPMRunBy, and @PRSummaryPM in order to summarize metrics   
by the different time groupings.  
- removed @FirstEvents because uptime for #Delays is now being pulled directly from Timed_Event_Details.  
- removed @PRSum, @WasteNTimedComments, @PRRuntime, @Dimensions, @Runs, @TopPRRuntime and @Products   
because they are no longer used.  
- removed TotalUWS from #ProdLines.  
- updated the population of #Events to reflect our latest and greatest methodology.  
- updated the initial insert to @prsrun to reflect our latest and greatest methodlogy.  Note that this   
includes bounding the events by the report window.  
- added inserts of "NoAssignedPRID" to @prsrun to fill gaps at the start and end of the report window.  
- #Delays now has only one initial insert defined since all servers are now on Proficy 4.x.  
- in #Delays, updated the definitions of StopsUnscheduled, Stops2m, StopsMinor, StopsEquipFails,  
StopsBlockedStarved, Uptime2min, and StopsProcessFailures.  
  
2008-05-20 Jeff Jaeger Rev7.61  
- added #EventHist and related code.  The population of #Events needs to use EventHistory in order to accurately   
pull in all events from a given time window.  the use of the temp table makes this process a little more efficient.  
  
  
2008-07-22 Jeff Jaeger  Rev7.62  
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
- Created the RawRateloss field in #Delays and updated the code to populate it.  This is done to help caluculate   
 ELP metrics related to Rateloss.  
  
2008-08-19 Jeff Jaeger  Rev7.63  
- updated the index to #Events so it is a clustered index instead of a primary.  
- added the temp table #EventStatusTransitions and made it the data source for the insert to #PRsRun.  
- removed the id comparison in the secondary update to flavors of start time and end time where the   
 datediffs are compared.    
  
2008-09-23 Jeff Jaeger Rev7.64  
- added an additional update to PEIID for #PRsRun.  This is used for facial line FFF1, which has a different   
 configuration than the other lines.  
  
2008-09-23 Jeff Jaeger Rev7.65  
- removed the "_Dev" filename suffix from this reports filename within the code.  
  
2008-09-25 Langdon Davis Rev7.66  
 - Added 'Overall Totals' in as the value for the 'UWS' field in the overall toatls results sets for all   
  converting lines, all intermediate processors and all papermachines.  
  
2008-09-30 Jeff Jaeger Rev7.67  
- added the @PRDTOutsideWindow table and related code to populate UWS1 and UWS2 related data in #Delays   
 for downtime events that started prior to any of the @PRsRun entries.  
  
2008-10-08 Jeff Jaeger Rev7.68  
- updated the assignment of GrandParentPRID.  
  
2008-10-10 Jeff Jaeger Rev7.69  
- Added an update on #Delays to automatically fill in the Schedule ID as Blocked/Starved if it is null [means  
 the reason level 2 was not filled out or there is no event reason category association to a 'Schedule'    
 event reason category] AND if reason level 1 contains the word 'BLOCK' or 'STARVE'.  
  
2008-10-21 Jeff Jaeger Rev7.70  
- modified the Facial FFF1 special special update to PEIID in #PRsRun so that it only runs if the site   
 executing the code is GB... this will need to be added to all of the reports.  
- added [UWS1 PRoll Made By], [UWS1 GPRoll Made By], [UWS2 PRoll Made By], and [UWS2 GPRoll Made By]  
 back into #Stops.  
  
2008-10-24 Jeff Jaeger Rev7.71  
- added [UWS1 Paper Made Day], [UWS2 Paper Made Day], and [Paper Converted Day] to the #stops results.  
- updated the fields returned from #PRsRun in the final result set.  
   
2008-10-27 Jeff Jaeger Rev7.72  
- updated the fields returned from #PRsRun in the final result set.  
  
2008-10-27 Jeff Jaeger Rev7.73  
- updated the fields returned from #PRsRun in the final result set to remove [GPRoll PUDesc].  
  
2008-11-07 Jeff Jaeger Rev7.74  
- updated the assignment of UWS1FreshStorage and UWS2FreshStorage because the greater than / less than   
 check was incorrect in each of them.  
  
2008-11-11 Jeff Jaeger Rev7.75  
- Changed from using the “Var_Desc_Global” to get the variables that are used to populate Grand Parent PRID   
 to use “GlblDesc=” instead.  This was done for both @PRsRun and @PRDTOutsideWindow.  The change was   
 required because on FPRW the “Var_Desc_Global” for these variables was set to NULL.  This has been fixed,   
 but using "GlblDesc" is going to be the standard approach with the next generation.  Also note that these   
 variables all have the same value for “GlblDesc=”.  
- Changed the update to GrandParentPRID in @PRDTOutsideWindow to include a Timestamp check against the   
 test result_on.  
- While researching these issues, I found that RF has Grand Parent PRID values with a blank space in the   
 third position.  This would lead to an invalid Grand Parent Team being parsed from the value.   
- Removed the IF clause around the use of @PRDTOutsideWindow.  the check to see if there are any UWS1Parent   
 or UWS2Parent values that are NULL before actually running that section of code was taking (much) longer   
 than is actually needed to just run the code.  
- added @DelaysOutsideWindow and the code to populate this.  this was done to reduce the size of the data set  
 being joined to in the population of @PRDTOutsideWindow.  the effect is to noticably reduce the runtime of   
 the sp.  
  
2008-11-13 Jeff Jaeger Rev7.76  
- added the tables @GroupByLinePS, @GroupByLine, and @GroupByPMRunBy, along with the code to populate them.  
- removed EventStatus, StartStatus, EndStatus, PRStatus, RLDT, ELPSchedDTLinePS, PaperRuntimeLinePS,   
 ELPSchedDTLine, PaperRuntimeLine, ELPSchedDTIntrPL, PaperRuntimeIntrPL, ELPSchedDTPMRunBy, and   
 PaperRuntimePMRunBy from @prsrun because they are no longer used in that table.  
  
2008-11-13 Jeff Jaeger Rev7.77  
-  in the GroupBy tables, the field [Proll Conv. Scheduled DT (mins)] has been changed to   
 [Proll Conv. Scheduled DT (mins)] and [Proll Conv. Paper Runtime (mins)] has been changed to  
 [Proll Paper Runtime (mins)].  
  
2008-11-20 Jeff Jaeger Rev7.78  
- added [Source Event PUDesc] to the PRsRun result set.  
- modified the indices for PRsRun  
- made PRsRun a temp table instead of a table variable  
- modified the updates to Group By start and end times to make them more efficient.  
- changed the Group By tables to temp tables instead of table variables due to the amount of   
 data they could end up holding.  
- added #ESTOutsideWindow and code to populate it.  this table is used to optimize the   
 population of PRDTOutsideWindow.  
- added ProdPuid and an index to @DelaysOutsideWindow.  
  
2008-11-22 Jeff Jaeger Rev7.79  
(comments from changes by Langdon Davis)  
- Added PUID to the primary key in @DelaysOutsideWindow.  This was necessary to avoid duplicate key errors on  
 lines where rate loss and downtime events are happening at the same time [theoretically not possible but in   
 reality, it happens given today's independent production units for these events.  
- Restricted the population of @DelaysOutsideWindow to just those events that have a start time < the start   
 of the report window.  This makes the population meet the intent of being just events that started   
 before the report window that do not yet have a parent roll association.  
(comments from changes by Jeff Jaeger)  
- converted #ProdLines temp table into table variables.    
- removed the GroupBy result tables in favor of returning results from a straight query.  the tables are   
 not needed because once the datasets are created no updates are needed to them.  doing a straight query   
 for the data is more efficient.  
  
2009-02-05 Jeff Jaeger Rev7.80  
- modified the definition of StopsUnscheduled, StopsMinor, StopsEquipFails, and   
 StopsProcessFailures in #Delays  
  
2009-02-13 Jeff Jaeger Rev7.81  
- modified the method for pulling ScheduleID, CategoryID, GroupCauseID, and SubsystemID in #delays.  
  
2009-03-12 Jeff Jaeger Rev7.82  
- added z_obs restriction to the population of @produnits  
  
2009-03-17 Jeff Jaeger Rev7.83  
- modified the definition of StopsUnscheduled, StopsMinor, StopsEquipFails, StopsProcessFailures in #Delays  
- modified the definition of SplitUnscheduledDT in #SplitDowntimes  
  
2009-10-20 Jeff Jaeger Rev7.84  
- corrected one of the updates to EndTimeLine because it contained a typo, leading to the wrong   
 field being used in the update.  
- added StartTimeLinePSFresh, EndTimeLinePSFresh, StartTimeLineFresh, EndTimeLineFresh,   
 StartTimeIntrPLFresh, EndTimeIntrPLFresh, StartTimePMRunByFresh, EndTimePMRunByFresh,   
 RunTimeLinePSFresh, RunTimeLineFresh, RunTimeIntrPLFresh, and RunTimePMRunByFresh to #PRsRun,  
 along with related code.   
  
  
*/  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
  
CREATE PROCEDURE [dbo].[spLocal_RptCvtgELP]  
-- DECLARE  
 @StartTime      DATETIME,    -- Beginning period for the data.  
 @EndTime       DATETIME,    -- Ending period for the data.  
 @RptName       VARCHAR(100)   -- Report_Definitions.RP_Name  
  
AS  
  
  
-------------------------------------------------------------------------------  
-- Control settings  
-- 2006-10-09 VMK Rev7.36, moved SET ANSI_WARNINGS OFF to here from below  
--         testing comments.  
-------------------------------------------------------------------------------  
SET ANSI_WARNINGS OFF  
SET NOCOUNT ON  
  
--NEU  
-- select  
-- @StartTime = '2007-09-10 06:00:00',   
-- @EndTime = '2007-09-11 06:00:00',   
-- @RptName = 'ELP_Tkt#18083203_20070917'  
  
--MP   
-- SELECT    
-- @StartTime = '2008-11-18 06:00:00',   
-- @EndTime = '2008-11-19 06:00:00',   
-- @RptName = 'Perini ELP MT65-66 Tue 0600 0600'  
-- SELECT    
-- @StartTime = '2007-03-14 06:00:00',  --'2006-11-01 07:20:32',  --   
-- @EndTime = '2007-03-15 06:00:00',  --'2006-11-01 15:54:11',  --   
-- @RptName = 'Charmin Ultra ELP MT52-55 Mon 0600 0600' --'Charmin ELP MT56-58 Mon 0600 0600'  --'Bounty ELP MK79-80 Wed 0600 0600'   --'Bounty ELP MK70-72-74-75 Thu 0600 0600'  -- 'Perini ELP MT65-66 0000 2400' --   --'Charmin ELP MT60-63 - Last Month' 
--   --'Bounty ELP MK70-72-74-75 Fri 0600 0600'  
  
--GB   
-- SELECT    
-- @StartTime = '2008-11-01 00:00:00',   
-- @EndTime = '2008-11-22 00:00:00',   
-- @RptName = 'Site Towel ELP Report 0500-0500 Yesterday'     
-- @RptName = 'Site Puffs ELP Report 0500 0500 Sunday'     
-- @RptName =  'PP FFF7 DDS Last Month'   
  
--AY   
-- SELECT    
-- @StartTime = '2007-02-01 06:00:00',  --'2006-11-01 07:20:32',  --   
-- @EndTime = '2007-02-02 06:00:00',  --'2006-11-01 15:54:11',  --   
-- @RptName = 'AT16 ELP 0000 0000'  --'AKxx ELP 0000 0000'    --'AT07-10 ELP 0000 0000'  
  
--Cape  
-- SELECT    
-- @StartTime = '2008-10-01 00:00:00',  --'2006-11-01 07:20:32',  --   
-- @EndTime = '2008-10-02 00:00:00',  --'2006-11-01 15:54:11',  --   
-- @RptName = 'Towel ELP 730AM 730AM'  
-- SELECT    
-- @StartTime = '2008-09-16 07:30:00',  --'2006-11-01 07:20:32',  --   
-- @EndTime = '2008-09-17 07:30:00',  --'2006-11-01 15:54:11',  --   
-- @RptName = 'Tissue ELP 730AM 730AM'  
-- @RptName = 'Towel ELP 730AM 730AM'  
  
---- OX  
-- SELECT  
-- @StartTime = '2009-10-14 05:00:00',   
-- @EndTime = '2009-10-15 05:00:00',   
-- @RptName = '05:00-05:00 ELP OTT4-5'  
  
-- AZ  
-- SELECT  
-- @StartTime = '2006-05-01 07:00:00',   
-- @EndTime = '2006-05-02 07:00:00',   
-- @RptName = 'AZS1 Daily ELP 07:00 AM - 07:00 AM'  
  
-- WITZ  
-- SELECT  
-- @StartTime = '2005-08-30 07:00:00',   
-- @EndTime = '2005-08-31 07:00:00',   
-- @RptName = 'WT03 ELP VAL Test'  
  
-- MAN  
-- SELECT  
-- @StartTime = '2007-02-01 06:00:00',  --'2006-11-01 07:20:32',  --   
-- @EndTime = '2007-02-02 06:00:00',  --'2006-11-01 15:54:11',  --   
-- @RptName = 'UK01 ELP 0700-0700'  
  
-------------------------------------------------------------------------------  
-- Declare program variables.  
-------------------------------------------------------------------------------  
DECLARE   
 -------------------------------------------------------------------------  
 -- Report Parameters. 2005-06-13 VMK Rev6.89  
 -------------------------------------------------------------------------  
 @ProdLineList     VARCHAR(4000),  -- Collection of Prod_Lines.PL_Id for CONVERTing lines delimited by "|".  
 @CatMechEquipId    INTEGER,    -- Event_Reason_Categories.ERC_Id for Category:Mechanical Equipment.  
 @CatElectEquipId    INTEGER,    -- Event_Reason_Categories.ERC_Id for Category:Electrical Equipment.  
 @CatELPId      INTEGER,    -- Event_Reason_Categories.ERC_Id for Category:Paper (ELP).  
 @SchedPRPolyId     INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:PR/Poly Change.  
 @SchedUnscheduledId   INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:Unscheduled.  
 @SchedSpecialCausesId  INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:Special Causes.  
 @SchedEOProjectsId   INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:E.O./Projects.  
 @SchedBlockedStarvedId  INTEGER,    -- Event_Reason_Categories.ERC_Id for Schedule:Blocked/Starved.  
 @ScheduleStr     VARCHAR(50),  -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ":").  
 @CategoryStr     VARCHAR(50),  -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ":").  
 @GroupCauseStr     VARCHAR(50),  -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ":").  
 @SubSystemStr     VARCHAR(50),  -- Prefix from Event_Reason_Categories.ERC_Desc (portion prior to ":").  
 @RL1Title      VARCHAR(100),  -- Title to be used for Reason Level 1  
 @RL2Title      VARCHAR(100),  -- Title to be used for Reason Level 2  
 @RL3Title      VARCHAR(100),  -- Title to be used for Reason Level 3  
 @RL4Title      VARCHAR(100),  -- Title to be used for Reason Level 4  
 @DelayTypeRateLossStr  VARCHAR(100),  -- Prod_Units.Extended_Info string for the RateLoss Delay Type.  
 @PRIDRLVarStr     VARCHAR(100),  -- Variables.Var_Desc for the Rate Loss PRID variable for ALL lines.  Blank if NA.  
 @UWSVarStr      VARCHAR(100),  -- Variables.Var_Desc for the genealogy Unwind Stand variable for ALL lines.  Blank if NA.  
 @UserName      VARCHAR(30),  -- User calling this report  
 @RptTitle      VARCHAR(300),  -- Report title from Web Report.  
 @RptPageOrientation   VARCHAR(50),  -- Report Page Orientation from Web Report.  
 @RptPageSize     VARCHAR(50),   -- Report page Size from Web Report.  
 @RptPercentZoom    INTEGER,    -- Percent Zoom from Web Report.  
 @RptTimeout      VARCHAR(100),  -- Report Time from Web Report.  
 @RptFileLocation    VARCHAR(300),  -- Report file location from WEb Report.  
 @RptConnectionString   VARCHAR(300),  -- Connection String from Web Report.  
 @RptPmkgOrCvtg     INTEGER,    -- Used for formatting in Template.  
  
 -- 2005-08-24 Vince King Rev6.93  
 @RptWindowMaxDays    INTEGER,    -- Maximum number of days allowed in the date range specified for a given report.   
  
 -- 2005-DEC-07 Vince King Rev7.03  
 @LineStatusList    VARCHAR(4000),  
  
-------------------------------------------------------------------------------  
-- program variables.  
-------------------------------------------------------------------------------  
 @SearchString     VARCHAR(4000),  
 @Position      INTEGER,  
 @PartialString     VARCHAR(4000),  
 @Now        DATETIME,  
 @@Id        INTEGER,  
 @@ExtendedInfo     VARCHAR(255),  
 @PUDelayTypeStr    VARCHAR(100),  
 @PUScheduleUnitStr   VARCHAR(100),  
 @PULineStatusUnitStr   VARCHAR(100),  
 @@PUId       INTEGER,  
 @@TimeStamp      DATETIME,  
 @@LastEndTime     DATETIME,  
 @VarFreshDTVN     VARCHAR(100),  
 @VarFreshDTId     INTEGER,  
 @VarStorageDTVN    VARCHAR(100),  
 @VarStorageDTId    INTEGER,  
 @@PLId       INTEGER,  
 @@ProdId       INTEGER,  
 @ProdCode      VARCHAR(100),  
 @LineSpeedTarget    FLOAT,  
 @LineSpeedTargetSpecDesc VARCHAR(100),  
 @Runtime       FLOAT,  
 @PLDesc       VARCHAR(100),  
 @DelayTypeDesc     VARCHAR(100),  
 @VarEffDowntimeId    INTEGER,  
 @VarEffDowntimeVN    VARCHAR(50),  
 @VarTargetLineSpeedId  INTEGER,  
 @VarTargetLineSpeedVN  VARCHAR(50),  
 @VarActualLineSpeedId  INTEGER,  
 @VarActualLineSpeedVN  VARCHAR(50),  
 @LoopCtr       INTEGER,  
 @SQL        nVARCHAR(4000),  
 @PRIDRLVarId     INTEGER,   
 @ProdPUId      INTEGER,  
 @VarStartTimeVN    VARCHAR(50),  
 @VarEndTimeVN     VARCHAR(50),  
 @VarPRIDVN      VARCHAR(50),  
--Rev7.75  
@VarInputRollVN         varchar(50),  
@VarInputPRIDVN         varchar(50),  
  
  
/*----------------ADDED BY FLD TO ADDRESS GENEALOGY MODEL CHANGE---------------*/  
 @VarParentPRIDVN    VARCHAR(50),  
-- @VarGrandParentPRIDVN  VARCHAR(50),  
/*-----------------------------------------------------------------------------*/  
  
 @VarUnwindStandVN    VARCHAR(50),  
 @VarStartTimeId    INTEGER,  
 @VarEndTimeId     INTEGER,  
 @VarPRIDId      INTEGER,  
--Rev7.6  
 @LinkStr            varchar(100),  
  
/*----------------ADDED BY FLD TO ADDRESS GENEALOGY MODEL CHANGE---------------*/  
 @VarParentPRIDId    INTEGER,  
--Rev7.75  
-- @VarGrandParentPRIDId  INTEGER,  
/*-----------------------------------------------------------------------------*/  
  
 @VarUnwindStandId    INTEGER,  
 @ReliabilityPUId    INTEGER,  
 @RateLossPUId     INTEGER,  
 @RangeStartTime    DATETIME,  
 @RangeEndTime     DATETIME,  
 @Max_TEDet_Id     INTEGER,  
 @Min_TEDet_Id     INTEGER,  
 @Count       INTEGER,  
 @LineCount      INTEGER,  
 @LanguageId      INTEGER,  
 @UserId       INTEGER,  
 @LanguageParmId    INTEGER,  
  
 @NoDataMsg      VARCHAR(100),  
 @TooMuchDataMsg    VARCHAR(100),  
  
 @Row        INTEGER,  
 @Rows        INTEGER,  
 @@StartTime      DATETIME,  
 @@ParentPLId     INTEGER,   
 @blnDupPRIDErrors    INTEGER,   
  
 @RunningStatusID     int  
  
  
-------------------------------------------------------------------------------  
-- Constants  
-------------------------------------------------------------------------------  
SELECT  
 @ScheduleStr     = 'Schedule',  
 @CategoryStr     = 'Category',  
 @GroupCauseStr     = 'GroupCause',  
 @SubSystemStr     = 'Subsystem',  
 @PRIDRLVarStr      = 'Rate Loss PRID',  
 @UWSVarStr      = 'Unwind Stand',  
 @DelayTypeRateLossStr  = 'RateLoss',  
 @CatELPId     = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories WITH(NOLOCK) WHERE Erc_Desc = 'Category:Paper (ELP)'),  
 @CatMechEquipId   = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories WITH(NOLOCK) WHERE Erc_Desc = 'Category:Mechanical Equipment'),  
 @CatElectEquipId   = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories WITH(NOLOCK) WHERE Erc_Desc = 'Category:Electrical Equipment'),  
 @SchedPRPolyId    = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories WITH(NOLOCK) WHERE Erc_Desc = 'Schedule:PR/Poly Change'),  
 @SchedUnscheduledId  = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories WITH(NOLOCK) WHERE Erc_Desc = 'Schedule:Unscheduled'),  
 @SchedSpecialCausesId = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories WITH(NOLOCK) WHERE Erc_Desc = 'Schedule:Special Causes'),  
 @SchedEOProjectsId  = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories WITH(NOLOCK) WHERE Erc_Desc = 'Schedule:E.O./Projects'),  
 @SchedBlockedStarvedId = (SELECT ERC_ID FROM dbo.Event_Reason_Catagories WITH(NOLOCK) WHERE Erc_Desc = 'Schedule:Blocked/Starved')--,  
  
-------------------------------------------------------------------------------  
-- Create temp tables  
-------------------------------------------------------------------------------  
--/*  
CREATE TABLE #Delays   
 (  
 TEDetId      INTEGER PRIMARY KEY NONCLUSTERED,  
 PrimaryId     INTEGER,  
 SecondaryId     INTEGER,  
 PUId       INTEGER,  
 PLId       INTEGER,      
 source      INTEGER,  
 PUDesc      VARCHAR(100),  
 StartTime     DATETIME,  
 EndTime      DATETIME,  
 ShiftStartTime    DATETIME,  
 LocationId     INTEGER,  
 L1ReasonId     INTEGER,  
 L2ReasonId     INTEGER,  
 L3ReasonId     INTEGER,  
 L4ReasonId     INTEGER,  
 TEFaultId     INTEGER,  
 ERTD_ID      int,  
 L1TreeNodeId    INTEGER,  
 L2TreeNodeId    INTEGER,  
 L3TreeNodeId    INTEGER,  
 L4TreeNodeId    INTEGER,  
 ProdId      INTEGER,  
 LineStatus     VARCHAR(50),  
 Shift       VARCHAR(10),  
 Crew       VARCHAR(10),  
 ScheduleId     INTEGER,  
 CategoryId     INTEGER,  
 GroupCauseId    INTEGER,  
 SubSystemId     INTEGER,  
 DownTime      float,   
 RawRateloss     float,  
 ReportDownTime    float,   
 UpTime      float,   
 ReportUpTime    float,   
 Stops       INTEGER,  
 StopsUnscheduled   INTEGER,  
 Stops2m      INTEGER,  
 StopsMinor     INTEGER,  
 StopsEquipFails   INTEGER,  
 StopsProcessFailures  INTEGER,  
 StopsELP      INTEGER,  
 ReportELPDowntime   float,   
 UWS1FreshStorage   varchar(10),  
 UWS2FreshStorage   varchar(10),  
 StopsBlockedStarved  INTEGER,  
 UpTime2m      INTEGER,  
 StopsRateLoss    INTEGER,  
 ReportRLDowntime   FLOAT,  
 LineTargetSpeed   FLOAT,  
 LineActualSpeed   FLOAT,  
  
 INTR       VARCHAR(50),-- DEFAULT NULL,       
 UWS1Parent     VARCHAR(50),--DEFAULT 'NoAssignedPRID',   
 UWS1ParentPM    VARCHAR(16),-- DEFAULT 'NoAssignedPRID',   
 UWS1GrandParent   VARCHAR(50),   
 UWS1GrandParentPM   VARCHAR(16),   
 UWS2Parent     VARCHAR(50),-- DEFAULT 'NoAssignedPRID',   
 UWS2ParentPM    VARCHAR(16),-- DEFAULT 'NoAssignedPRID',   
 UWS2GrandParent   VARCHAR(50),   
 UWS2GrandParentPM   VARCHAR(16),   
 UWS1Timestamp    datetime,  
 UWS2Timestamp    datetime,  
 UWS1PMTeam     varchar(10),  
 UWS2PMTeam     varchar(10),  
  
 UWS1PMProd     varchar(100),  
 UWS2PMProd     varchar(100),  
  
 CommentId     INTEGER,      
 Comment      VARCHAR(5000),  
 ScheduledDT     FLOAT,   
 InRptWindow     INTEGER--,  
 )  
--*/  
  
  
--Rev7.6  
CREATE TABLE #LineMachineELPByUWS (   
    [Line]       VARCHAR(50),  
    [Paper Source]     VARCHAR(50),    
    [UWS]        VARCHAR(25),   
    [Paper Runtime]    FLOAT,  
    [Paper Stops]     INTEGER,  
    [DT due to Stops]    FLOAT,  
    [Eff. DT (Rate Loss)]  FLOAT,  
    [Total Paper DT]    FLOAT,  
    [Fresh Paper Stops]   INTEGER,  
    [Fresh Paper DT]    FLOAT,  
    [Fresh Paper Runtime]  FLOAT,  
    [Fresh Rolls Ran]    INTEGER,  
    [Storage Paper Stops]  INTEGER,  
    [Storage Paper DT]   FLOAT,  
    [Storage Paper Runtime]  FLOAT,  
    [Storage Rolls Ran]   INTEGER,  
    [Total Rolls Ran]    INTEGER,  
    [Fresh ELP%]     FLOAT,  
    [Storage ELP%]     FLOAT,  
    [Total ELP%]     FLOAT )  
  
CREATE TABLE #LineMachineELP (   
    [Line]       VARCHAR(50),  
    [Paper Source]     VARCHAR(50),     
    [UWS]        VARCHAR(25), --Rev7.6  
    [Paper Runtime]    FLOAT,  
    [Paper Stops]     INTEGER,  
    [DT due to Stops]    FLOAT,  
    [Eff. DT (Rate Loss)]  FLOAT,  
    [Total Paper DT]    FLOAT,  
    [Fresh Paper Stops]   INTEGER,  
    [Fresh Paper DT]    FLOAT,  
    [Fresh Paper Runtime]  FLOAT,  
    [Fresh Rolls Ran]    INTEGER,  
    [Storage Paper Stops]  INTEGER,  
    [Storage Paper DT]   FLOAT,  
    [Storage Paper Runtime]  FLOAT,  
    [Storage Rolls Ran]   INTEGER,  
    [Total Rolls Ran]    INTEGER,  
    [Fresh ELP%]     FLOAT,  
    [Storage ELP%]     FLOAT,  
    [Total ELP%]     FLOAT )  
  
  
 CREATE TABLE #LineELP (   
    [Line]       VARCHAR(50),  
    [Paper Source]     VARCHAR(50),  
    [UWS]        VARCHAR(25), --Rev7.6  
    [Paper Runtime]    FLOAT,  
    [Paper Stops]     INTEGER,  
    [DT due to Stops]    FLOAT,  
    [Eff. DT (Rate Loss)]  FLOAT,  
    [Total Paper DT]    FLOAT,  
    [Fresh Paper Stops]   INTEGER,  
    [Fresh Paper DT]    FLOAT,  
    [Fresh Paper Runtime]  FLOAT,  
    [Fresh Rolls Ran]    INTEGER,  
    [Storage Paper Stops]  INTEGER,  
    [Storage Paper DT]   FLOAT,  
    [Storage Paper Runtime]  FLOAT,  
    [Storage Rolls Ran]   INTEGER,  
    [Total Rolls Ran]    INTEGER,  
    [Fresh ELP%]     FLOAT,  
    [Storage ELP%]     FLOAT,  
    [Total ELP%]     FLOAT )  
  
  
 CREATE TABLE #ReportELP(  
    [Line]       VARCHAR(50),  
    [Paper Source]     VARCHAR(50),  
    [UWS]        VARCHAR(25), --Rev7.6  
    [Paper Runtime]    FLOAT,  
    [Paper Stops]     INTEGER,  
    [DT due to Stops]    FLOAT,  
    [Eff. DT (Rate Loss)]  FLOAT,  
    [Total Paper DT]    FLOAT,  
    [Fresh Paper Stops]   INTEGER,  
    [Fresh Paper DT]    FLOAT,  
    [Fresh Paper Runtime]  FLOAT,  
    [Fresh Rolls Ran]    INTEGER,  
    [Storage Paper Stops]  INTEGER,  
    [Storage Paper DT]   FLOAT,  
    [Storage Paper Runtime]  FLOAT,  
    [Storage Rolls Ran]   INTEGER,  
    [Total Rolls Ran]    INTEGER,  
    [Fresh ELP%]     FLOAT,  
    [Storage ELP%]     FLOAT,  
    [Total ELP%]     FLOAT)  
  
--Rev7.6  
 CREATE TABLE #LineMachineELPByUWS2 (   
     [Paper Machine]    VARCHAR(50),  
     [Paper Run By]     VARCHAR(50),  
     [UWS]        VARCHAR(25),  
     [Paper Runtime]    FLOAT,  
     [Paper Stops]     INTEGER,  
     [DT due to Stops]    FLOAT,  
     [Eff. DT (Rate Loss)]  FLOAT,  
     [Total Paper DT]    FLOAT,  
     [Fresh Paper Stops]   INTEGER,  
     [Fresh Paper DT]    FLOAT,  
     [Fresh Paper Runtime]  FLOAT,  
     [Fresh Rolls Ran]    INTEGER,  
     [Storage Paper Stops]  INTEGER,  
     [Storage Paper DT]   FLOAT,  
     [Storage Paper Runtime]  FLOAT,  
     [Storage Rolls Ran]   INTEGER,  
     [Total Rolls Ran]    INTEGER,  
     [Fresh ELP%]     FLOAT,  
     [Storage ELP%]     FLOAT,  
     [Total ELP%]     FLOAT)  
  
  
 CREATE TABLE #LineMachineELP2 (   
     [Paper Machine]    VARCHAR(50),  
     [Paper Run By]     VARCHAR(50),  
     [UWS]        VARCHAR(25), --Rev7.6  
     [Paper Runtime]    FLOAT,  
     [Paper Stops]     INTEGER,  
     [DT due to Stops]    FLOAT,  
     [Eff. DT (Rate Loss)]  FLOAT,  
     [Total Paper DT]    FLOAT,  
     [Fresh Paper Stops]   INTEGER,  
     [Fresh Paper DT]    FLOAT,  
     [Fresh Paper Runtime]  FLOAT,  
     [Fresh Rolls Ran]    INTEGER,  
     [Storage Paper Stops]  INTEGER,  
     [Storage Paper DT]   FLOAT,  
     [Storage Paper Runtime]  FLOAT,  
     [Storage Rolls Ran]   INTEGER,  
     [Total Rolls Ran]    INTEGER,  
     [Fresh ELP%]     FLOAT,  
     [Storage ELP%]     FLOAT,  
     [Total ELP%]     FLOAT)  
  
  
 CREATE TABLE #MachineELP2(   
     [Paper Machine]   VARCHAR(50),  
     [Paper Run By]    VARCHAR(50),  
     [UWS]       VARCHAR(25), --Rev7.6  
     [Paper Runtime]   FLOAT,  
     [Paper Stops]    INTEGER,  
     [DT due to Stops]   FLOAT,  
     [Eff. DT (Rate Loss)] FLOAT,  
     [Total Paper DT]   FLOAT,  
     [Fresh Paper Stops]  INTEGER,  
     [Fresh Paper DT]   FLOAT,  
     [Fresh Paper Runtime] FLOAT,  
     [Fresh Rolls Ran]   INTEGER,  
     [Storage Paper Stops] INTEGER,  
     [Storage Paper DT]  FLOAT,  
     [Storage Paper Runtime] FLOAT,  
     [Storage Rolls Ran]  INTEGER,  
     [Total Rolls Ran]   INTEGER,  
     [Fresh ELP%]    FLOAT,  
     [Storage ELP%]    FLOAT,  
     [Total ELP%]    FLOAT )  
  
  
 CREATE TABLE #ReportELP2(   
     [Paper Machine]   VARCHAR(50),  
     [Paper Run By]    VARCHAR(50),  
     [UWS]       VARCHAR(25), --Rev7.6  
     [Paper Runtime]   FLOAT,  
     [Paper Stops]    INTEGER,  
     [DT due to Stops]   FLOAT,  
     [Eff. DT (Rate Loss)] FLOAT,  
     [Total Paper DT]   FLOAT,  
     [Fresh Paper Stops]  INTEGER,  
     [Fresh Paper DT]   FLOAT,  
     [Fresh Paper Runtime] FLOAT,  
     [Fresh Rolls Ran]   INTEGER,  
     [Storage Paper Stops] INTEGER,  
     [Storage Paper DT]  FLOAT,  
     [Storage Paper Runtime] FLOAT,  
     [Storage Rolls Ran]  INTEGER,  
     [Total Rolls Ran]   INTEGER,  
     [Fresh ELP%]    FLOAT,  
     [Storage ELP%]    FLOAT,  
     [Total ELP%]    FLOAT)  
  
--Rev7.6  
 CREATE TABLE #LineMachineELPByUWS3(   
     [Intermediate]    VARCHAR(50),  
     [Paper Run By]    VARCHAR(50),      
     [UWS]       VARCHAR(25),  
     [Paper Runtime]   FLOAT,  
     [Paper Stops]    INTEGER,  
     [DT due to Stops]   FLOAT,  
     [Eff. DT (Rate Loss)] FLOAT,  
     [Total Paper DT]   FLOAT,  
     [Fresh Paper Stops]  INTEGER,  
     [Fresh Paper DT]   FLOAT,  
     [Fresh Paper Runtime] FLOAT,  
     [Fresh Rolls Ran]   INTEGER,  
     [Storage Paper Stops] INTEGER,  
     [Storage Paper DT]  FLOAT,  
     [Storage Paper Runtime] FLOAT,  
     [Storage Rolls Ran]  INTEGER,  
     [Total Rolls Ran]   INTEGER,  
     [Fresh ELP%]    FLOAT,  
     [Storage ELP%]    FLOAT,  
     [Total ELP%]    FLOAT)  
  
 CREATE TABLE #LineMachineELP3(   
     [Intermediate]    VARCHAR(50),  
     [Paper Run By]    VARCHAR(50),      
     [UWS]       VARCHAR(25), --Rev7.6  
     [Paper Runtime]   FLOAT,  
     [Paper Stops]    INTEGER,  
     [DT due to Stops]   FLOAT,  
     [Eff. DT (Rate Loss)] FLOAT,  
     [Total Paper DT]   FLOAT,  
     [Fresh Paper Stops]  INTEGER,  
     [Fresh Paper DT]   FLOAT,  
     [Fresh Paper Runtime] FLOAT,  
     [Fresh Rolls Ran]   INTEGER,  
     [Storage Paper Stops] INTEGER,  
     [Storage Paper DT]  FLOAT,  
     [Storage Paper Runtime] FLOAT,  
     [Storage Rolls Ran]  INTEGER,  
     [Total Rolls Ran]   INTEGER,  
     [Fresh ELP%]    FLOAT,  
     [Storage ELP%]    FLOAT,  
     [Total ELP%]    FLOAT)  
  
 CREATE TABLE #LineELP3(   
     [Intermediate]    VARCHAR(50),  
     [Paper Run By]    VARCHAR(50),      
     [UWS]       VARCHAR(25), --Rev7.6  
     [Paper Runtime]   FLOAT,  
     [Paper Stops]    INTEGER,  
     [DT due to Stops]   FLOAT,  
     [Eff. DT (Rate Loss)] FLOAT,  
     [Total Paper DT]   FLOAT,  
     [Fresh Paper Stops]  INTEGER,  
     [Fresh Paper DT]   FLOAT,  
     [Fresh Paper Runtime] FLOAT,  
     [Fresh Rolls Ran]   INTEGER,  
     [Storage Paper Stops] INTEGER,  
     [Storage Paper DT]  FLOAT,  
     [Storage Paper Runtime] FLOAT,  
     [Storage Rolls Ran]  INTEGER,  
     [Total Rolls Ran]   INTEGER,  
     [Fresh ELP%]    FLOAT,  
     [Storage ELP%]    FLOAT,  
     [Total ELP%]    FLOAT)  
  
 CREATE TABLE #ReportELP3(   
     [Intermediate]    VARCHAR(50),  
     [Paper Run By]    VARCHAR(50),      
     [UWS]       VARCHAR(25), --Rev7.6  
     [Paper Runtime]   FLOAT,  
     [Paper Stops]    INTEGER,  
     [DT due to Stops]   FLOAT,  
     [Eff. DT (Rate Loss)] FLOAT,  
     [Total Paper DT]   FLOAT,  
     [Fresh Paper Stops]  INTEGER,  
     [Fresh Paper DT]   FLOAT,  
     [Fresh Paper Runtime] FLOAT,  
     [Fresh Rolls Ran]   INTEGER,  
     [Storage Paper Stops] INTEGER,  
     [Storage Paper DT]  FLOAT,  
     [Storage Paper Runtime] FLOAT,  
     [Storage Rolls Ran]  INTEGER,  
     [Total Rolls Ran]   INTEGER,  
     [Fresh ELP%]    FLOAT,  
     [Storage ELP%]    FLOAT,  
     [Total ELP%]    FLOAT)  
  
--/*  
  CREATE TABLE #Stops (   
--     tedetid int,  
     [Production Line]     VARCHAR(50),  
     [Start Date]      VARCHAR(25),  
     [Start Time]      VARCHAR(25),  
     [End Date]       VARCHAR(25),  
     [End Time]       VARCHAR(25),  
     [Total Event Downtime]   FLOAT,  
     [Total Event UpTime]    FLOAT,  
     [Effective Downtime]    FLOAT,  
     [Master Unit]      VARCHAR(50),  
     [Location]       VARCHAR(50),  
     [RL1Title]       VARCHAR(100),  
     [RL2Title]       VARCHAR(100),  
     [Fault Desc]      VARCHAR(100),  
     [Comment]       VARCHAR(5000),  
     [Team]        VARCHAR(8),  
     [Shift]        VARCHAR(10),  
     [Cvtg Product]      VARCHAR(25),   
     [Cvtg Product Desc]    VARCHAR(50),   
     [UWS1 PRID]       VARCHAR(50),  
     [UWS1 PRoll Made By]    VARCHAR(50),  
     [UWS1 GPRID]      VARCHAR(50),  --SP - Rev6.75  
     [UWS1 GPRoll Made By]   VARCHAR(50),  --SP - Rev6.75   
     [UWS2 PRID]       VARCHAR(50),  
     [UWS2 PRoll Made By]    VARCHAR(50),  
     [UWS2 GPRID]      VARCHAR(50),    
     [UWS2 GPRoll Made By]   VARCHAR(50),    
     [Event Type]      VARCHAR(10),  
     [Schedule]       VARCHAR(50),  
     [Category]       VARCHAR(50),  
     [SubSystem]       VARCHAR(50),  
     [GroupCause]      VARCHAR(50),  
     [Event Location Type]   VARCHAR(50),  
     [Total Causes]      INTEGER,  
     [Total Stops]      INTEGER,  
     [Total Stops < 2 Min]   INTEGER,  
     [Minor Stops]      INTEGER,  
     [ELP Stops]       INTEGER,  
     [ELP Downtime]      FLOAT,   
     [Minor Equipment Failures]  INTEGER,   
     [Moderate Equipment Failures] INTEGER,   
     [Major Equipment Failures]  INTEGER,   
     [Minor Process Failures]  INTEGER,   
     [Moderate Process Failures] INTEGER,   
     [Major Process Failures]  INTEGER,  
     [Process Failures]    INTEGER,  
     [Total Blocked Starved]   INTEGER,  
     [Total UpTime < 2 Min]   FLOAT,   
     [Line Target Speed]    FLOAT,  
     [Line Actual Speed]    FLOAT,  
     [RL3Title]       VARCHAR(100),  
     [RL4Title]       VARCHAR(100),  
     [Line Status]      VARCHAR(25),  
     [UWS1 Fresh/Storage]    varchar(10),  
     [UWS2 Fresh/Storage]    varchar(10),  
     [Stop > 10 Min]     INTEGER,  
     [UWS1 PM Team]      VARCHAR(8),  
     [UWS2 PM Team]      VARCHAR(8),  
     [UWS1 Paper Made Day]   VARCHAR(25),  
     [UWS2 Paper Made Day]   VARCHAR(25),  
     [Paper Converted Day]   VARCHAR(25),  
     [UWS1 Pmkg Product Desc]  VARCHAR(50),   
     [UWS2 Pmkg Product Desc]  VARCHAR(50)--,   
)  
--*/  
  
  
--20080721  
CREATE TABLE dbo.#Events   
 (  
 event_id            INTEGER,   
 source_event          INTEGER,           
 pu_id             INTEGER,  
 start_time           datetime,  
 end_time           datetime,  
 timestamp           DATETIME,  
 event_status          INTEGER,  
 status_desc           VARCHAR(50),   
 event_num           VARCHAR(50),  
 DevComment           VARCHAR(300)   
-- primary key (Event_id, start_time)  
 )  
  
CREATE CLUSTERED INDEX events_eventid_StartTime  
ON dbo.#events (event_id, start_time)   
  
  
create table dbo.#EventStatusTransitions  
 (  
 Event_ID   int,  
 Start_Time  datetime,  
 End_Time   datetime,  
 Event_Status int  
 )  
  
CREATE CLUSTERED INDEX est_eventid_starttime  
ON dbo.#EventStatusTransitions (event_id, start_time)  
  
  
--/*  
create table dbo.#ESTOutsideWindow  
 (  
 Event_ID   int,  
 Start_Time  datetime,  
 End_Time   datetime,  
 Event_Status int  
 )  
  
CREATE CLUSTERED INDEX estow_eventid_starttime  
ON dbo.#ESTOutsideWindow (event_id, start_time)  
--*/  
  
  
--/*  
create table dbo.#prsrun   
 (  
 Id_Num      INTEGER primary key IDENTITY(1,1),   
 EventId      INTEGER,  
 SourceId      INTEGER,  
 PLID       int,  
 PUId       INTEGER,  
 PEIId       INTEGER,  
 PEIPId      INTEGER,  
 StartTime     DATETIME,  
 EndTime      DATETIME,  
 StartTimeFresh    DATETIME,  
 EndTimeFresh    DATETIME,  
 InitEndTime     DATETIME,   
 AgeOfPR      FLOAT,  
 PRTimeStamp     DATETIME,  
 EventNum      VARCHAR(50),  
 ParentPRID     VARCHAR(50),   
 GrandParentPRID   VARCHAR(50),   
 ParentPM      VARCHAR(15),    
 GrandParentPM    VARCHAR(15),    
 PaperMachine    varchar(15),  
 PRPLId      INTEGER,    
 PRPUId      INTEGER,    
 PRPUDesc      VARCHAR(100),   
 ParentTeam     VARCHAR(15),  
 GrandParentTeam   VARCHAR(15),  
 PMTeam      VARCHAR(15),  
   [ParentType]    int,  --2=intermediate and 1=Papermachine  
 UWS       VARCHAR(25),  
 Input_Order     INTEGER,  
 LineStatus     VARCHAR(50),  
 PaperSource     VARCHAR(50),   
 PaperRunBy     VARCHAR(50),   
 INTR       VARCHAR(50),   
 EventTimestamp    datetime,  
 Fresh       INTEGER,     
  
 FreshRolls     INTEGER,  
 StorageRolls    INTEGER,  
 TotalRolls     INTEGER,  
  
 RunTime      FLOAT,  
 ELPStops      INTEGER,  
 ELPDT       float,   
 ELPSchedDT     float,   
 RLELPDT      float,   
 FreshStops     INTEGER,  
 FreshDT      float,   
 FreshRLELPDT    FLOAT,  
 FreshRuntime    float,   
 StorageStops    INTEGER,  
 StorageDT     float,   
 StorageRLELPDT    FLOAT,  
 StorageRuntime    float,   
 FreshSchedDT    float,   
 StorageSchedDT    float,   
 PaperRuntime    float,    
  
 StartTimeLinePS   datetime,  
 EndTimeLinePS    datetime,  
 StartTimeLinePSFresh   datetime,  
 EndTimeLinePSFresh    datetime,  
 LinePSID1      int,  
 LinePSID2      int,  
  
 StartTimeLine    datetime,  
 EndTimeLine     datetime,  
 StartTimeLineFresh   datetime,  
 EndTimeLineFresh   datetime,  
 LineID1      int,  
 LineID2      int,  
  
 StartTimeIntrPL   datetime,  
 EndTimeIntrPL    datetime,  
 StartTimeIntrPLFresh   datetime,  
 EndTimeIntrPLFresh    datetime,  
  
 StartTimePMRunBy   datetime,  
 EndTimePMRunBy    datetime,  
 StartTimePMRunByFresh   datetime,  
 EndTimePMRunByFresh    datetime,  
 PMRunByID1     int,  
 PMRunByID2     int,  
  
 RunTimeLinePS    FLOAT,  
 RunTimeLinePSFresh    FLOAT,  
 FreshRuntimeLinePS  float,   
 StorageRuntimeLinePS  float,   
  
 RunTimeLine     FLOAT,  
 RunTimeLineFresh   FLOAT,  
 FreshRuntimeLine   float,   
 StorageRuntimeLine  float,   
  
 RunTimeIntrPL    FLOAT,  
 RunTimeIntrPLFresh    FLOAT,  
 FreshRuntimeIntrPL  float,   
 StorageRuntimeIntrPL  float,   
  
 RunTimePMRunBy    FLOAT,  
 RunTimePMRunByFresh    FLOAT,  
 FreshRuntimePMRunBy  float,   
 StorageRuntimePMRunBy float,   
  
 DevComment     VARCHAR(100)  
  
 )  
  
CREATE nonCLUSTERED INDEX prs_PUId_StartTime_endtime  
ON dbo.#PRsRun (puid, starttime, endtime)  
  
CREATE nonCLUSTERED INDEX prs_PlId_StartTime_endtime  
ON dbo.#PRsRun (plid, starttime, endtime)  
  
--*/  
  
-------------------------------------------------------  
  
declare @ProdLines table    
 (        
 PLId       INTEGER PRIMARY KEY,  
 PLDesc      VARCHAR(50),    
 DeptID      INTEGER,  
 VarEffDowntimeId   INTEGER,  
 VarTargetLineSpeedId  INTEGER,  
 VarActualLineSpeedId  INTEGER,  
 VarFreshId     INTEGER,  
 VarStorageId    INTEGER,  
 ProdPUId      INTEGER,   
 RollsPUID     int,  
 VarStartTimeId    INTEGER,   
 VarEndTimeId    INTEGER,   
 VarPRIDId     INTEGER,  
 VarParentPRIDId   INTEGER,  
 VarUnwindStandId   INTEGER,  
 VarInputRollID    int,  
 VarInputPRIDID    int,  
 ReliabilityPUId   INTEGER,  
 RateLossPUId    INTEGER,  
 MinEventID     int--,  
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
  
  
 declare @PEI table  
  (  
  pu_id   int,  
  pei_id  int,  
  Input_Order int,  
  Input_name varchar(50)  
  primary key (pu_id,input_name)  
  )  
  
  
DECLARE @UWS TABLE ( PEIId  INTEGER PRIMARY KEY,   
    InputName   VARCHAR(50),    
    InputOrder   INTEGER,     
    PLId     INTEGER,  
    MasterPUId   INTEGER,  
    UWSPUId    INTEGER,  
    PPPUId    INTEGER,      
    RelPUDesc   VARCHAR(50) )    
  
DECLARE @ProdUnits TABLE (  
    PUId     INTEGER PRIMARY KEY,  
    PUDesc    VARCHAR(100),  
    PLId     INTEGER,  
    ExtendedInfo  VARCHAR(255),  
    DelayType   VARCHAR(100),  
    ScheduleUnit  INTEGER,  
    LineStatusUnit  INTEGER,  
    PRIDVarId   INTEGER,  
    PRIDRLVarId   INTEGER,  
    UWS1     VARCHAR(50),  
    UWS2     VARCHAR(50)--,  
)  
  
  
--Rev7.6  
/* Intermediate Rolls Units Record Set */   
DECLARE @IntUnits TABLE  
 (  
 puid        int primary key  
 )  
  
  
--Rev7.6  
declare @PRDTMetrics table  
 (  
  
 id_num       int,  
  
 ELPStops       int,  
 ELPDT        float,  
 RLELPDT        float,  
 FreshStops       int,  
 FreshDT        float,  
 FreshRLELPDT      float,  
 StorageStops      int,  
 StorageDT       float,  
 StorageRLELPDT     float,  
 ELPSchedDT       float,  
 FreshSchedDT      float,  
 StorageSchedDT     float,  
  
 ELPStopsLinePS     int,  
 ELPDTLinePS      float,  
 RLELPDTLinePS      float,  
 FreshStopsLinePS     int,  
 FreshDTLinePS      float,  
 FreshRLELPDTLinePS    float,  
 StorageStopsLinePS    int,  
 StorageDTLinePS     float,  
 StorageRLELPDTLinePS   float,  
 ELPSchedDTLinePS     float,  
 FreshSchedDTLinePS    float,  
 StorageSchedDTLinePS   float,  
  
 ELPStopsLine      int,  
 ELPDTLine       float,  
 RLELPDTLine      float,  
 FreshStopsLine     int,  
 FreshDTLine      float,  
 FreshRLELPDTLine     float,  
 StorageStopsLine     int,  
 StorageDTLine      float,  
 StorageRLELPDTLine    float,  
 ELPSchedDTLine     float,  
 FreshSchedDTLine     float,  
 StorageSchedDTLine    float,  
  
 ELPStopsIntrPL     int,  
 ELPDTIntrPL      float,  
 RLELPDTIntrPL      float,  
 FreshStopsIntrPL     int,  
 FreshDTIntrPL      float,  
 FreshRLELPDTIntrPL    float,  
 StorageStopsIntrPL    int,  
 StorageDTIntrPL     float,  
 StorageRLELPDTIntrPL   float,  
 ELPSchedDTIntrPL     float,  
 FreshSchedDTIntrPL    float,  
 StorageSchedDTIntrPL   float,  
  
 ELPStopsPMRunBy     int,  
 ELPDTPMRunBy      float,  
 RLELPDTPMRunBy     float,  
 FreshStopsPMRunBy    int,  
 FreshDTPMRunBy     float,  
 FreshRLELPDTPMRunBy    float,  
 StorageStopsPMRunBy    int,  
 StorageDTPMRunBy     float,  
 StorageRLELPDTPMRunBy   float,  
 ELPSchedDTPMRunBy    float,  
 FreshSchedDTPMRunBy    float,  
 StorageSchedDTPMRunBy   float  
  
 )  
  
  
DECLARE @PRSummaryUWS TABLE   
 (  
 CvtgPLId     INTEGER,  
 InputOrder    INTEGER,     
 PEIId      INTEGER,     
 PaperSource    VARCHAR(20),   
 UWS      varchar(25),  
 PaperRunBy    VARCHAR(20),   
 PaperMachine   VARCHAR(16),  
 INTR      VARCHAR(20),   
 ParentPLId    INTEGER,     
 Runtime     float,   
 ELPStops     INTEGER,  
 ELPDowntime    float,   
 RLELPDowntime   float,   
 FreshStops    INTEGER,  
 FreshDT     float,   
 FreshRLELPDT   FLOAT,  
 FreshRuntime   float,   
 FreshRolls    INTEGER,  
 StorageStops   INTEGER,  
 StorageDT    float,   
 StorageRLELPDT   FLOAT,  
 StorageRolls   INTEGER,  
 StorageRuntime   float,   
 ScheduledDT    float,   
 FreshSchedDT   float,   
 StorageSchedDT   float,   
 TotalRolls    INTEGER,  
 UWSTotalDT    float,   
 UWSStorageDT   float,   
 UWSFreshDT    float,   
 CvtrTotalDT    float,   
 CvtrFreshDT    float,   
 CvtrStorageDT   float  
 )   
  
DECLARE @PRSummaryLinePS TABLE   
 (  
 CvtgPLId     INTEGER,  
 PaperSource    VARCHAR(20),   
 Runtime     float,   
 ELPStops     INTEGER,  
 ELPDowntime    float,   
 RLELPDowntime   float,   
 FreshStops    INTEGER,  
 FreshDT     float,   
 FreshRLELPDT   FLOAT,  
 FreshRuntime   float,   
 FreshRolls    INTEGER,  
 StorageStops   INTEGER,  
 StorageDT    float,   
 StorageRLELPDT   FLOAT,  
 StorageRolls   INTEGER,  
 StorageRuntime   float,   
 ScheduledDT    float,   
 FreshSchedDT   float,   
 StorageSchedDT   float,   
 TotalRolls    INTEGER,  
 UWSTotalDT    float,   
 UWSStorageDT   float,   
 UWSFreshDT    float,   
 CvtrTotalDT    float,   
 CvtrFreshDT    float,   
 CvtrStorageDT   float  
 )   
  
  
DECLARE @PRSummaryLine TABLE   
 (  
 CvtgPLId     INTEGER,  
 Runtime     float,   
 ELPStops     INTEGER,  
 ELPDowntime    float,   
 RLELPDowntime   float,   
 FreshStops    INTEGER,  
 FreshDT     float,   
 FreshRLELPDT   FLOAT,  
 FreshRuntime   float,   
 FreshRolls    INTEGER,  
 StorageStops   INTEGER,  
 StorageDT    float,   
 StorageRLELPDT   FLOAT,  
 StorageRolls   INTEGER,  
 StorageRuntime   float,   
 ScheduledDT    float,   
 FreshSchedDT   float,   
 StorageSchedDT   float,   
 TotalRolls    INT,  
 UWSTotalDT    float,   
 UWSStorageDT   float,   
 UWSFreshDT    float,   
 CvtrTotalDT    float,   
 CvtrFreshDT    float,   
 CvtrStorageDT   float  
 )   
  
  
DECLARE @PRSummaryIntrPL TABLE   
 (  
 INTR      VARCHAR(20),  
 PaperRunBy    VARCHAR(20),  
 Runtime     float,   
 ELPStops     INTEGER,  
 ELPDowntime    float,   
 RLELPDowntime   float,   
 FreshStops    INTEGER,  
 FreshDT     float,   
 FreshRLELPDT   FLOAT,  
 FreshRuntime   float,   
 FreshRolls    INTEGER,  
 StorageStops   INTEGER,  
 StorageDT    float,   
 StorageRLELPDT   FLOAT,  
 StorageRolls   INTEGER,  
 StorageRuntime   float,   
 ScheduledDT    float,   
 FreshSchedDT   float,   
 StorageSchedDT   float,   
 TotalRolls    INTEGER,  
 UWSTotalDT    float,   
 UWSStorageDT   float,   
 UWSFreshDT    float,   
 CvtrTotalDT    float,   
 CvtrFreshDT    float,   
 CvtrStorageDT   float  
 )   
  
  
DECLARE @PRSummaryIntr TABLE   
 (  
 INTR      VARCHAR(20),  
 Runtime     float,   
 ELPStops     INTEGER,  
 ELPDowntime    float,   
 RLELPDowntime   float,   
 FreshStops    INTEGER,  
 FreshDT     float,   
 FreshRLELPDT   FLOAT,  
 FreshRuntime   float,   
 FreshRolls    INTEGER,  
 StorageStops   INTEGER,  
 StorageDT    float,   
 StorageRLELPDT   FLOAT,  
 StorageRolls   INTEGER,  
 StorageRuntime   float,   
 ScheduledDT    float,   
 FreshSchedDT   float,   
 StorageSchedDT   float,   
 TotalRolls    INTEGER,  
 UWSTotalDT    float,   
 UWSStorageDT   float,   
 UWSFreshDT    float,   
 CvtrTotalDT    float,   
 CvtrFreshDT    float,   
 CvtrStorageDT   float  
 )   
  
DECLARE @PRSummaryPMRunBy TABLE   
 (  
 PaperRunBy    VARCHAR(20),  
 PaperMachine   VARCHAR(16),  
 Runtime     float,   
 ELPStops     INTEGER,  
 ELPDowntime    float,   
 RLELPDowntime   float,   
 FreshStops    INTEGER,  
 FreshDT     float,   
 FreshRLELPDT   FLOAT,  
 FreshRuntime   float,   
 FreshRolls    INTEGER,  
 StorageStops   INTEGER,  
 StorageDT    float,   
 StorageRLELPDT   FLOAT,  
 StorageRolls   INTEGER,  
 StorageRuntime   float,   
 ScheduledDT    float,   
 FreshSchedDT   float,   
 StorageSchedDT   float,   
 TotalRolls    INTEGER,  
 UWSTotalDT    float,   
 UWSStorageDT   float,   
 UWSFreshDT    float,   
 CvtrTotalDT    float,   
 CvtrFreshDT    float,   
 CvtrStorageDT   float  
 )   
  
  
DECLARE @PRSummaryPM TABLE   
 (  
 PaperMachine   VARCHAR(16),  
 Runtime     float,   
 ELPStops     INTEGER,  
 ELPDowntime    float,   
 RLELPDowntime   float,   
 FreshStops    INTEGER,  
 FreshDT     float,   
 FreshRLELPDT   FLOAT,  
 FreshRuntime   float,   
 FreshRolls    INTEGER,  
 StorageStops   INTEGER,  
 StorageDT    float,   
 StorageRLELPDT   FLOAT,  
 StorageRolls   INTEGER,  
 StorageRuntime   float,   
 ScheduledDT    float,   
 FreshSchedDT   float,   
 StorageSchedDT   float,   
 TotalRolls    INTEGER,  
 UWSTotalDT    float,   
 UWSStorageDT   float,   
 UWSFreshDT    float,   
 CvtrTotalDT    float,   
 CvtrFreshDT    float,   
 CvtrStorageDT   float  
 )   
  
  
----------------------------------------------------------------------------------  
-- 2005-Nov-15 VMK Rev7.02  
-- @CrewSchedule will hold information pertaining to the crew and shift schedule  
---------------------------------------------------------------------------------  
  
declare @CrewSchedule table  
 (  
 Start_Time           datetime,  
 End_Time            datetime,  
 pu_id             int,  
 Crew_Desc           varchar(10),  
 Shift_Desc           varchar(10)  
 primary key (pu_id, start_time)  
 )  
  
---------------------------------------------------------------  
-- 2005-Nov-15 VMK Rev7.02  
-- @ProductionStarts will hold the Production Starts information  
-- along with related product information  
---------------------------------------------------------------  
  
declare @ProductionStarts table  
 (  
 Start_Time           datetime,  
 End_Time            datetime,  
 Prod_ID            int,  
 Prod_Code           varchar(50),  
 Prod_Desc           varchar(50),  
 PU_ID             int--,  
 primary key (pu_id, prod_id, start_time)  
 )  
  
  
------------------------------------------------------------------  
-- 2005-Nov-15 VMK Rev7.02  
-- @Primaries will contain the primary events associated with   
-- entries in #delays.  
------------------------------------------------------------------  
--  do we still need this?????????????????  
declare @Primaries table  
 (  
 TEDetId            INTEGER,   
 PUId             INTEGER,  
 StartTime           DATETIME,  
 EndTime            DATETIME,  
 UpTime            INTEGER,  
 ReportUptime          INTEGER,    
 TEPrimaryId           INTEGER IDENTITY PRIMARY KEY,  
 UNIQUE (TEDetId))  
  
  
DECLARE @DupPRIDs TABLE   
 (  
 ProdUnit    INTEGER,  
 RollConvST   DATETIME,  
 PRID     VARCHAR(50),  
 PRIDCOUNT   INTEGER,  
 MaxEventId   INTEGER,  
 MinEventId   INTEGER   
 )  
  
declare @PRDTOutsideWindow table  
 (  
 TEDetID    int,  
 EventID    int,  
 SourceEventID  int,  
 PLID     int,  
 CvtgPUID    int,  
 ProdPUID    int,  
 PRPUID    int,  
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
  
  
-------------------------------------------------------------------------------  
-- Initialization  
-------------------------------------------------------------------------------  
DECLARE @ErrorMessages TABLE (  
 ErrMsg    VARCHAR(255) )  
  
---------------------------------------------------------------------------------------------------  
-- 2005-JUN-13 VMK Rev6.89  
-- Retrieve parameter values FROM report definition using spCmn_GetReportParameterValue  
---------------------------------------------------------------------------------------------------   
IF Len(@RptName) > 0   
BEGIN  
  --print 'Get Report Parameters.'  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptPLIdList',     '',  @ProdLineList     OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptRL1Title',     '',  @RL1Title      OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptRL2Title',     '',  @RL2Title      OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptRL3Title',     '',  @RL3Title      OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptRL4Title',     '',  @RL4Title      OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'Owner',        '',  @UserName      OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptTitle',      '',  @RptTitle      OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptPageOrientation',  '',  @RptPageOrientation   OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptPageSize',     '',  @RptPageSize     OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'intRptPercentZoom',    '',  @RptPercentZoom    OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'ReportTimeOut',     '',  @RptTimeout     OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'ServerFileLocation',   '',  @RptFileLocation    OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptConnectionString',  '',  @RptConnectionString  OUTPUT  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'intRptPmkgOrCvtg',   '',  @RptPmkgOrCvtg    OUTPUT -- 2006-07-17 VMK Rev7.33, changed RptPmkgOrCvtg to intRptPmkgOrCvtg  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'intRptWindowMaxDays',  '32', @RptWindowMaxDays   OUTPUT -- 2005-08-24 Vince King Rev6.93  
 EXEC dbo.spCmn_GetReportParameterValue @RptName, 'strRptLineStatusList',  '', @LineStatusList   OUTPUT -- 2005-12-07 Vince King Rev7.03  
END  
ELSE   -- 2005-MAR-16 VMK Rev8.81, If no Report Name provided, return error.  
BEGIN  
 INSERT INTO @ErrorMessages (ErrMsg)  
  VALUES ('No Report Name specified.')  
  GOTO ReturnResultSets  
  
END    
  
if (@LineStatusList IS NULL) or (@LineStatusList='')  
SELECT @LineStatusList='All'  
  
-- SELECT @ProdLineList = '62|74|124'  
-------------------------------------------------------------------------------  
-- Check Input Parameters.  
-------------------------------------------------------------------------------  
IF isDate(@StartTime) <> 1  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
 VALUES ('@StartTime is not a Date.')  
 GOTO ReturnResultSets  
 END  
  
IF isDate(@EndTime) <> 1  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
 VALUES ('@EndTime is not a Date.')  
 GOTO ReturnResultSets  
 END  
  
IF @UWSVarStr IS NULL  --If UWSVarStr is not provided.  
 BEGIN  
 SELECT @UWSVarStr = 'Unwind Stand'  
 END  
  
-- If the endtime is in the future, set it to current day.  This prevent zero records from being --printed on report.  
IF @EndTime > GetDate()  
 SELECT @EndTime = CONVERT(VARCHAR(4),YEAR(GetDate())) + '-' + CONVERT(VARCHAR(2),MONTH(GetDate())) + '-' +   
     CONVERT(VARCHAR(2),DAY(GetDate())) + ' ' + CONVERT(VARCHAR(2),DATEPART(hh,@EndTime)) + ':' +   
     CONVERT(VARCHAR(2),DATEPART(mi,@EndTime))+ ':' + CONVERT(VARCHAR(2),DATEPART(ss,@EndTime))  
  
-- 2005-08-24 Vince King Rev6.93  
-- Check RptWindowMaxDays, if NULL assign to 32.  If Date Range exceeds RptWindowMaxDays, then return error msg.  
IF @RptWindowMaxDays IS NULL   
        BEGIN   
        SELECT @RptWindowMaxDays = 32   
        END   
  
IF DATEDIFF(d, @StartTime,@EndTime) > @RptWindowMaxDays   
        BEGIN   
        INSERT        @ErrorMessages (ErrMsg)   
                VALUES        ('The date range selected exceeds the maximum allowed for this report: ' +                           
                        CONVERT(VARCHAR(50),@RptWindowMaxDays) +   
                        '.  Decrease the date range or see your Proficy SSO for help.')   
        GOTO        ReturnResultSets   
        END   
  
IF @StartTime = @EndTime  
 BEGIN  
 INSERT @ErrorMessages (ErrMsg)  
  VALUES ('The date range selected for this report has the same start and end date: ' + convert(varchar(25),@StartTime,107) +  
      ' through ' + convert(varchar(25),@EndTime,107))  
 GOTO ReturnResultSets  
 END  
-------------------------------------------------------------------------------  
-- Get local language  
-------------------------------------------------------------------------------  
  
SELECT @LanguageParmId  = 8,  
   @LanguageId    = NULL  
  
SELECT  @UserId = User_Id  
FROM   dbo.Users WITH(NOLOCK)   
WHERE  UserName = @UserName  
  
SELECT  @LanguageId = CASE WHEN isnumeric(ltrim(rtrim(Value))) = 1 THEN CONVERT(FLOAT, ltrim(rtrim(Value)))  
          ELSE NULL  
          END  
FROM dbo.User_Parameters WITH(NOLOCK)  
WHERE User_Id = @UserId  
 AND Parm_Id = @LanguageParmId  
  
IF @LanguageId IS NULL  
 BEGIN  
 SELECT @LanguageId = CASE WHEN isnumeric(ltrim(rtrim(Value))) = 1 THEN CONVERT(FLOAT, ltrim(rtrim(Value)))  
          ELSE NULL  
          END  
 FROM dbo.Site_Parameters WITH(NOLOCK)  
 WHERE Parm_Id = @LanguageParmId  
  
 IF @LanguageId IS NULL  
  BEGIN  
  SELECT @LanguageId = 0  
  END  
 END  
  
   
-------------------------------------------------------------------------------  
-- Constants  
-------------------------------------------------------------------------------  
SELECT @Now         = GetDate(),  
   @PUDelayTypeStr     = 'DelayType=',  
   @PUScheduleUnitStr    = 'ScheduleUnit=',  
   @PULineStatusUnitStr   = 'LineStatusUnit=',  
   @VarEffDowntimeVN    = 'Effective Downtime',  
   @LineSpeedTargetSpecDesc  = 'Line Speed Target',  
   @VarTargetLineSpeedVN   = 'Line Target Speed',  -- Rate Loss  
   @VarActualLineSpeedVN   = 'Line Actual Speed',  -- Rate Loss  
   @VarFreshDTVN      = 'ELP Fresh',  
   @VarStorageDTVN     = 'ELP Storage',  
   @VarStartTimeVN    = 'Roll Conversion Start Date/Time',  
   @VarEndTimeVN     = 'Roll Conversion End Date/Time',  
   @VarPRIDVN      = 'PRID',  
   @LinkStr       = 'RollsUnit=',  
/*----------------ADDED BY FLD TO ADDRESS GENEALOGY MODEL CHANGE---------------*/  
   @VarParentPRIDVN    = 'Parent PRID',  
--Rev7.75  
--   @VarGrandParentPRIDVN  = 'Grand Parent PRID',  
/*-----------------------------------------------------------------------------*/  
   @VarUnwindStandVN    = 'Unwind Stand',  
--Rev7.75  
@VarInputRollVN   = 'Input Roll ID',  
@VarInputPRIDVN   = 'Input PRID'  
  
select @NoDataMsg = GBDB.dbo.fnLocal_GlblTranslation('NO DATA meets the given criteria', @LanguageId)  
select @TooMuchDataMsg = GBDB.dbo.fnLocal_GlblTranslation('There are more results than can be displayed', @LanguageId)  
  
--print 'Parse passed lists: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
-------------------------------------------------------------------------------  
-- Parse the passed lists into temporary tables.  
-------------------------------------------------------------------------------  
-------------------------------------------------------------------------------  
-- ProdLineList  
-------------------------------------------------------------------------------  
  
INSERT @ProdLines   
 (  
 PLID,  
 PLDesc,  
 DeptID  
 )  
SELECT   
 PL_ID,  
 PL_Desc,  
 Dept_ID  
FROM dbo.prod_lines WITH(NOLOCK)  
WHERE CHARINDEX('|' + CONVERT(VARCHAR,pl_id) + '|','|' + @ProdLineList + '|') > 0  
OPTION (KEEP PLAN)  
  
-- 2005-OCT-25 VMK Rev7.01, modified to use 2 UPDATEs versus 4 different UPDATEs.  
-- Reduced Reads and Writes slightly. I had it to 1 UPDATE, but when I added in the  
-- 2nd UPDATE below, it actually decreased performance a bit.  
UPDATE pl SET ProdPUId    =  (SELECT PU_Id   
              FROM dbo.Prod_Units pu WITH(NOLOCK)  
              WHERE pl.PLId = pu.PL_Id  
               AND (PU_Desc LIKE '%Converter Production'  
               OR  PU_Desc LIKE '%UWS Production')),  
      ReliabilityPUId = (SELECT PU_Id  
              FROM dbo.Prod_Units pu WITH(NOLOCK)  
              WHERE pl.PLId = pu.PL_Id  
               AND (PU_Desc LIKE '%Converter Reliability%'  
               OR  PU_Desc LIKE '%INTR Reliability')),  
      RateLossPUId  = (SELECT PU_Id  
              FROM dbo.Prod_Units pu WITH(NOLOCK)  
              WHERE pl.PLId = pu.PL_Id  
               AND PU_Desc LIKE '%Rate Loss%')  
FROM @ProdLines pl   
         
UPDATE pl  
   SET VarEffDowntimeId   = GBDB.dbo.fnLocal_GlblGetVarId(RateLossPUId,   @VarEffDowntimeVN),  
     VarTargetLineSpeedId  = GBDB.dbo.fnLocal_GlblGetVarId(RateLossPUId,   @VarTargetLineSpeedVN),  
     VarActualLineSpeedId  = GBDB.dbo.fnLocal_GlblGetVarId(RateLossPUId,   @VarActualLineSpeedVN),  
     VarFreshId     = GBDB.dbo.fnLocal_GlblGetVarId(ReliabilityPUId,  @VarFreshDTVN),  
     VarStorageId     = GBDB.dbo.fnLocal_GlblGetVarId(ReliabilityPUId,  @VarStorageDTVN),  
     VarStartTimeId    = GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,    @VarStartTimeVN),  
     VarEndTimeId     = GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,    @VarEndTimeVN),  
     VarPRIDId      = GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,    @VarPRIDVN),  
     VarParentPRIDId    = GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,    @VarParentPRIDVN),  
     VarUnwindStandId   = GBDB.dbo.fnLocal_GlblGetVarId(ProdPUId,    @VarUnwindStandVN)--,  
FROM @ProdLines pl   
  
  
--print '@ProdUnits: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
-------------------------------------------------------------------------------  
-- ProdUnitList  
-- MKW - Event_Configuration needs a clustered index on PUIdByETId  
-------------------------------------------------------------------------------  
INSERT @ProdUnits ( PUId,  
       PUDesc,  
       PLId,  
       ExtendedInfo,  
       DelayType,  
       ScheduleUnit,  
       LineStatusUnit--,  
       )  
SELECT     pu.PU_Id,  
       pu.PU_Desc,  
       pu.PL_Id,  
       pu.Extended_Info,  
       GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, @PUDelayTypeStr),  
       GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, @PUScheduleUnitStr),  
       GBDB.dbo.fnLocal_GlblParseInfo(pu.Extended_Info, @PULineStatusUnitStr)--,  
FROM dbo.Prod_Units pu WITH(NOLOCK)  
JOIN @ProdLines pl on pl.PLId = pu.PL_Id  
JOIN dbo.departments d WITH (NOLOCK) on d.dept_id = pl.DeptID  
WHERE (PU_desc like '%Converter Reliability%' OR   
  (pu_desc like '%Rate Loss%' AND (d.dept_desc LIKE 'Cvtg %' OR d.dept_desc = 'Intr')))  
and pu_desc not like '%z_obs%'  
OPTION (KEEP PLAN)  
  
INSERT INTO @IntUnits  
 (  
 puid  
 )  
SELECT    
 pu.pu_id  
FROM dbo.prod_units pu with (nolock)  
WHERE pu.pu_id > 0   
and GBDB.dbo.fnlocal_GlblParseInfo(pu.extended_info,@LinkStr) is not null  
  
  
---------------------------------------------------------------  
-- 2005-Nov-15 VMK Rev7.02  
-- Section 17: Get Crew Schedule information  
---------------------------------------------------------------  
  
insert @CrewSchedule  
 (  
 Start_Time,  
 End_Time,  
 pu_id,  
 Crew_Desc,  
 Shift_Desc  
 )  
select distinct   
 start_time,  
 end_time,  
 pu_id,  
 crew_desc,  
 shift_desc  
from dbo.crew_schedule cs WITH(NOLOCK)  
join @produnits pu  
on cs.pu_id = pu.scheduleunit  
where cs.start_time < @endtime  
and (cs.end_time > @starttime or cs.end_time is null)  
option (keep plan)  
  
--print 'Section 18 @ProductionStarts: ' + CONVERT(VARCHAR(20), GetDate(), 120)  
-------------------------------------------------------------------------------  
-- 2005-Nov-15 VMK Rev7.02  
-- Section 18: Get Production Starts  
-------------------------------------------------------------------------------  
  
insert @ProductionStarts   
 (  
 Start_Time,  
 End_Time,  
 Prod_ID,  
 Prod_Code,  
 Prod_Desc,  
 PU_ID  
 )  
select ps.start_time,  
 ps.end_time,  
 ps.prod_id,  
 p.prod_code,  
 p.prod_desc,  
 ps.pu_id  
from dbo.production_starts ps WITH(NOLOCK)  
join dbo.products p WITH(NOLOCK)   
on ps.prod_id = p.prod_id  
join @produnits pu  
on start_time < @endtime  
and (ps.end_time > @starttime or ps.end_time is null)  
and pu.puid = ps.pu_id   
option (keep plan)  
  
--/*  
--print 'Fill @UWS: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
-------------------------------------------------------------------------------  
-- Fill out @UWS table.  
-- 2005-Dec-15 VMK Rev7.04, moved to accomodate PM dimension changes.  
-------------------------------------------------------------------------------  
  
INSERT INTO @UWS ( PEIId,  
       InputName,  
       InputOrder,  
       PLId,  
       MasterPUId,  
       UWSPUId,  
       RelPUDesc )           -- 2006-SEP-05 VMK Rev7.34, added  
SELECT     pei.PEI_Id,  
       pei.Input_Name,  
       pei.Input_Order,      
       pl.PLId,   
       pu.Master_Unit,  
       pu.PU_Id,  
       CASE WHEN pl.PLDesc LIKE 'PP%' THEN  
        'FFF7 UWS ' + pei.Input_Name + ' Reliability'  
       ELSE NULL END  
FROM dbo.PrdExec_Inputs pei WITH(NOLOCK)  
INNER JOIN @ProdLines pl ON pl.ProdPUId = pei.PU_Id  
LEFT  JOIN dbo.Prod_Units pu WITH(NOLOCK) ON pu.PL_Id = pl.PLId  
     AND charindex('UWSORDER='+CONVERT(VARCHAR(5), pei.Input_Order) + ';', upper(REPLACE(pu.Extended_Info, ' ', '') + ';')) > 0  -- 2005-08-22 VMK Rev6.92  
OPTION (KEEP PLAN)  
  
-- 2006-10-26 VMK Rev7.37, now update the PPPUId with the PUId for the UWS   
--         reliability unit.  
UPDATE uws SET   
 PPPUId = (SELECT pu.PU_Id FROM dbo.Prod_Units pu WITH(NOLOCK) WHERE pu.PU_Desc = uws.RelPUDesc)  
FROM @UWS uws  
--*/  
  
  
--print 'Events ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
--20080721  
  
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
and est.start_time < @endtime  
and (est.start_time < est.end_time or est.end_time is null)  
and (est.end_time > @starttime or est.end_time is null)  
  
  
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
from dbo.#EventStatusTransitions est  
join dbo.events e with(nolock)  
on est.event_id = e.event_id  
  
  
--print 'source event ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
-- 2007-01-18 VMK Rev7.43, added code from PmkgDDSELP  
update e set  
 source_event = coalesce(ec.source_event_id,e.event_id)  
from dbo.#events e with (nolock)  
LEFT JOIN dbo.event_components ec with (nolock)  
ON e.event_id = ec.event_id  
  
--print 'PRSRun ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
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
from dbo.#events e   
JOIN @ProdLines pl   
ON (e.PU_Id = pl.ProdPUId)-- or e.pu_id = pl.ratelosspuid)  
JOIN dbo.prod_units pu with (nolock)   
ON pu.pu_id = e.pu_id   
-- source events  
JOIN dbo.events e1 with (nolock)  
ON e1.event_id = e.source_event  
  
  
--print 'PRSRun Time Updates ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
update prs set  
 starttime = @starttime  
from dbo.#prsrun prs  
where starttime < @starttime  
  
--20080721  
update prs set  
 endtime = @endtime  
from dbo.#PRsRun prs  
where endtime > @endtime  
  
  
update prs set  
 [ParentPRID] = UPPER(RTRIM(LTRIM(tprid.result))),  
 [ParentPM] =  UPPER(RTRIM(LTRIM(LEFT(COALESCE(tprid.Result, 'NoAssignedPRID'), 2)))),  
 [UWS] = coalesce(tuws.result,'No UWS Assigned')  
from dbo.#prsrun prs  
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
 PEIId = pei_id,  
 Input_Order = pei.Input_Order  
FROM dbo.#prsrun prs   
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
 from dbo.PrdExec_Inputs pei  
 where (  
    pei.pu_id = 1465  
   or pei.pu_id = 1466  
   or pei.pu_id = 1467  
   or pei.pu_id = 1468  
   )  
  
 UPDATE prs SET   
  PEIId = pei.pei_id,  
  Input_Order = pei.input_order  
 FROM dbo.#prsrun prs   
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
FROM dbo.#prsrun prs   
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
  
  
--print 'parent type' + ' ' + convert(varchar(25),current_timestamp,108)  
  
UPDATE prs SET   
 [ParentType] =   
  CASE   
  WHEN prs.[PRPUID] = iu.puid   
  THEN 2  
      ELSE 1  
      END  
FROM dbo.#prsrun prs   
LEFT JOIN @IntUnits iu   
ON iu.puid = prs.[PRPUID]  
  
  
--print 'grand prid' + ' ' + convert(varchar(25),current_timestamp,108)  
UPDATE prs SET   
 [GrandParentPRID] = t.result,  
 [GrandParentPM] = UPPER(RTRIM(LTRIM(LEFT(t.Result, 2))))--,  
FROM dbo.#prsrun prs   
LEFT JOIN dbo.tests t with (nolock)   
ON t.result_on = prs.[PRTimestamp]   
and prs.[ParentType] = 2  
LEFT JOIN dbo.variables v with (nolock)   
ON v.var_id = t.var_id   
and v.pu_id = prs.[PRPUID]   
where v.var_id = dbo.fnLocal_GlblGetVarId(prs.PRPUID, @VarInputRollVN)  
or v.var_id = dbo.fnLocal_GlblGetVarId(prs.PRPUID, @VarInputPRIDVN)  
  
  
--print 'PMTeam' + ' ' + convert(varchar(25),current_timestamp,108)  
update prs set  
 ParentTeam =   
 SUBSTRING(UPPER(RTRIM(LTRIM(coalesce(ParentPRID, '')))), 3, 1),  
 GrandparentTeam =   
 SUBSTRING(UPPER(RTRIM(LTRIM(coalesce(GrandParentPRID, '')))), 3, 1),  
 PMTeam =   
 SUBSTRING(UPPER(RTRIM(LTRIM(coalesce(GrandParentPRID, ParentPRID, '')))), 3, 1)  
from dbo.#prsrun prs --with (nolock)  
where ParentPRID <> 'NoAssignedPRID'  
  
  
--==============================================================================================================================  
  
  ------------------------------------------------------------------------------------------------  
  -- If duplicate PRIDs Exist, INSERT Contents of @Events into the @ErrorMessages table, then  
  -- GOTO ReturnResultSets  
  ------------------------------------------------------------------------------------------------  
  SELECT @blnDupPRIDErrors = 0  
  
  INSERT @DupPRIDs (ProdUnit, RollConvST, PRID, PRIDCount, MaxEventId, MinEventId)  
   SELECT  PUId,  
      MAX(StartTime),  
      ParentPRID,  
      COUNT(ParentPRID),  
      MAX(EventId),  
      MIN(EventId)  
   FROM dbo.#prsrun pr   
   GROUP BY PUId, ParentPRID, StartTime    -- 2005-SEP-12 VMK Rev6.97 Added StartTime  
   OPTION (KEEP PLAN)  
  
  -- 2005-OCT-24 VMK Rev7.01 Modified to return PU_Desc instead of PUId (ProdUnit)  
  IF (SELECT COUNT(PRID) FROM @DupPRIDs WHERE PRIDCOUNT > 1) > 0  
   BEGIN  
    SELECT @blnDupPRIDErrors = 1  
    INSERT @ErrorMessages (ErrMsg)  
     SELECT  'Duplicate PRID error.  ProdUnit: ' + pu.PUDesc   +   
        '; Roll Conv ST: ' + CONVERT(VARCHAR(20), RollConvST) +  
        '; Parent PRID: ' + PRID  +  
        '; Count: ' + CONVERT(VARCHAR(5), PRIDCount) +   
        '; Max EventId: ' + CONVERT(VARCHAR(20), MaxEventId) +  
        '; Min EventId: ' + CONVERT(VARCHAR(20), MinEventId)  
     FROM @DupPRIDs dp  
       JOIN @ProdUnits pu ON dp.ProdUnit = pu.PUId  
     WHERE PRIDCount > 1  
     OPTION (KEEP PLAN)  
   END  
  
  
-- to identify overlap adjustments, query the temp table for InitEndtime <> Endtime  
UPDATE prs1 SET   
 prs1.Endtime =   
  coalesce((  
  select top 1 prs2.Starttime  
  from dbo.#prsrun prs2   
  where prs1.PUId = prs2.PUId  
  and prs1.StartTime <= prs2.StartTime   
  and prs1.InitEndTime > prs2.StartTime  
  AND prs1.PEIId = prs2.PEIId  
  and prs1.eventid <> prs2.eventid  
  order by puid, starttime  
  ), prs1.InitEndtime)  
FROM dbo.#prsrun prs1   
  
delete dbo.#prsrun  
where StartTime = EndTime   
  
  
-------------------------------------------------------------------------------------------  
-- 2006-03-17 VMK Rev7.14  
-- @prsrun includes PRs run for the converting lines included in the report.  However, it   
-- does not include time slices where there is no PR loaded on the UWS.    
-- Now add the records that fill in that time and assign them to 'NoAssignedPRID'.  
-------------------------------------------------------------------------------------------  
INSERT dbo.#prsrun (  
   EventId,  
   SourceId,  
   PLID,  
   PUId,  
   PEIId,  
   StartTime,  
   EndTime,  
   Runtime,  
   AgeOfPR,  
   PRTimeStamp,  
   EventNum,  
   ParentPRID,   
   GrandParentPRID,   
   ParentPM,  
   GrandParentPM,  
   PRPLId,    
   PRPUId,    
   PRPUDesc,   
   ParentTeam,  
   GrandParentTeam,  
   UWS,  
   Input_Order,  
   LineStatus,  
   DevComment )  
SELECT  NULL,   
   NULL,  
   prs1.PLID,  
   prs1.PUId,  
   prs1.PEIId,  
   prs1.EndTime,  
   prs2.StartTime,  
   DATEDIFF(ss, prs1.EndTime, prs2.StartTime),  
   NULL,  
   NULL,  
   NULL,  
   'NoAssignedPRID',  
   'NoAssignedPRID',  
   'NoAssignedPRID',  
   NULL,  
   NULL,  
   NULL,  
   NULL,  
   NULL,  
   NULL,  
   prs1.UWS,      
   prs1.Input_Order,    
   prs1.LineStatus,  
   'Fill Gaps'     
FROM dbo.#prsrun prs1  
JOIN dbo.#prsrun prs2   
ON prs1.PUId = prs2.PUId  
AND prs1.PEIId = prs2.PEIId                 
AND prs2.StartTime = (SELECT TOP 1 prs.StartTime FROM dbo.#prsrun prs  
        WHERE prs.StartTime > prs1.StartTime         
        AND prs.PUId = prs1.PUId  
        AND prs.PEIId = prs1.PEIId          
        ORDER BY prs.StartTime ASC)  
WHERE prs1.EndTime <> prs2.StartTime  
 AND prs1.EndTime < prs2.StartTime  
OPTION (KEEP PLAN)    
  
  
--print 'prs start' + ' ' + convert(varchar(25),current_timestamp,108)  
-------------------------------------------------------------------------------------------  
-- This fills in any gaps between the start of the report window and the FIRST existing PR.  
-------------------------------------------------------------------------------------------  
--Rev7.6  
INSERT INTO dbo.#prsrun  
 (   
 EventId,  
 PLID,         
 PUId,  
 PEIID,  
 [Input_Order],  
 StartTime,  
 EndTime,  
 ParentPRID,   
 GrandParentPRID,   
 ParentPM,  
 GrandParentPM,  
 PRPUID,      
 PRPLID,     
 UWS,  
 PRTimeStamp,  
 PMTeam,  
 DevComment  
 )     
SELECT    
 NULL,  
 prs1.PLID,  
 prs1.PUId,  
 PEIID,  
 [Input_Order],  
 @starttime,   
 prs1.StartTime,  
 'NoAssignedPRID',  
 'NoAssignedPRID',  
 'NoAssignedPRID',  
 'NoAssignedPRID',  
 -1, --prs1.PRPUID,  
 -1, --prs1.PRPLID,  
 UWS,  
 NULL,  
 '',  
 'Start of Report Window'  
FROM dbo.#prsrun prs1   
where prs1.StartTime > @starttime   
and (prs1.endtime > @starttime or prs1.endtime is null)  
and prs1.StartTime =   
 (  
 SELECT TOP 1 prs.StartTime   
 FROM dbo.#prsrun prs   
 WHERE prs.PUId = prs1.PUId  
 AND prs.PEIId = prs1.PEIId  
 ORDER BY prs.StartTime ASC  
 )  
OPTION (KEEP PLAN)  
  
  
--print 'prs end' + ' ' + convert(varchar(25),current_timestamp,108)  
-------------------------------------------------------------------------------------------  
--This fills in any gaps between the LAST existing PR and the end of the report window.  
-------------------------------------------------------------------------------------------  
--Rev7.6  
INSERT INTO dbo.#prsrun  
 (   
 EventId,  
 PLID,         
 PUId,  
 PEIID,  
 [Input_Order],  
 StartTime,  
 EndTime,  
 ParentPRID,   
 GrandParentPRID,   
 ParentPM,  
 GrandParentPM,  
 PRPUID,      
 PRPLID,     
 UWS,  
 PRTimeStamp,  
 PMTeam,  
 DevComment  
 )     
SELECT    
 NULL,  
 prs1.PLID,  
 prs1.PUId,  
 PEIID,  
 [Input_Order],  
 prs1.EndTime,  
 @endtime,   
 'NoAssignedPRID',  
 'NoAssignedPRID',  
 'NoAssignedPRID',  
 'NoAssignedPRID',  
 -1, --prs1.PRPUID,  
 -1, --prs1.PRPLID,  
 UWS,  
 NULL,  
 '',  
 'End of Report Window'  
FROM dbo.#prsrun prs1   
where prs1.starttime < @endtime   
AND prs1.EndTime < @endtime   
and prs1.EndTime =   
 (  
 SELECT TOP 1 prs.EndTime   
 FROM dbo.#prsrun prs   
 WHERE prs.PUId = prs1.PUId  
 AND prs.PEIId = prs1.PEIId   
 ORDER BY prs.EndTime DESC  
 )  
OPTION (KEEP PLAN)  
  
  
-- ALL  
delete dbo.#prsrun   
where endtime < @starttime  
  
update prs set  
 starttime = @starttime  
from dbo.#prsrun prs  
where starttime < @starttime  
  
--20080721  
update prs set  
 endtime = @endtime  
from dbo.#PRsRun prs  
where endtime > @endtime  
  
  
update prs set  
 prplid = (select pl_id from dbo.prod_units pu where pu_id = prs.prpuid)  
from dbo.#prsrun prs   
  
  
update prs SET   
--Rev7.6  
 AgeOfPR = datediff(ss, PRTimeStamp, prs.starttime) / 86400.0,  
 Fresh =  CASE    
    WHEN (datediff(ss, PRTimeStamp, prs.starttime) / 86400.0) <=1  
    and PRTimeStamp is not null  
    THEN 1  
    WHEN (datediff(ss, PRTimeStamp, prs.starttime) / 86400.0) > 1  
    and PRTimeStamp is not null  
    THEN 0  
    ELSE null  
    END  
FROM dbo.#prsrun prs   
  
update prs set  
 [LineStatus] = p.Phrase_Value  
FROM dbo.#prsrun prs   
LEFT JOIN dbo.Local_PG_Line_Status pgls WITH (NOLOCK)   
ON prs.PUId = pgls.Unit_Id  
AND (prs.Starttime >= pgls.Start_DateTime  
AND (prs.Starttime <  pgls.End_DateTime OR pgls.End_DateTime IS NULL))  
AND pgls.update_status <> 'DELETE'   
LEFT JOIN dbo.Phrase p WITH (NOLOCK)   
ON pgls.line_status_id = p.Phrase_Id  
  
  
------------------------------------------------------------  
-- 2006-MAR-28 VMK  Rev7.15  
-- Update UWS column based on PEIId when UWS IS NULL.  
------------------------------------------------------------  
UPDATE prs  
 SET UWS = pei.Input_Name  
FROM dbo.#prsrun prs  
JOIN dbo.PrdExec_Inputs pei WITH(NOLOCK) ON prs.PEIId = pei.PEI_Id  
WHERE prs.UWS IS NULL AND prs.PEIId IS NOT NULL  
  
update prs set  
 prpudesc = pu.pu_desc  
from dbo.#prsrun prs  
join dbo.prod_units pu  
on prs.prpuid = pu.pu_id  
  
UPDATE prs SET  
 [UWS] =   
  CASE   
  WHEN SUBSTRING(UPPER(RTRIM(LTRIM(pl.PlDesc))), 4, 4) IN ('FF7A', 'FFF7','FFFW', 'FPRW', 'FFF1')  
  THEN SUBSTRING(UPPER(RTRIM(LTRIM(pl.PlDesc))), 4, 4) + ' ' + [UWS]  
      ELSE [UWS]  
      END  
FROM dbo.#prsrun prs   
JOIN @ProdLines pl ON pl.PlId = prs.PlId  
  
  
--print 'Get #Delays: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
-------------------------------------------------------------------------------  
-- Collect dataset filtered by report period and Production Units.  
-------------------------------------------------------------------------------  
  
  INSERT INTO dbo.#Delays   
   (   
   TEDetId,  
   PUId,  
   PLId,       
   source,  
   StartTime,  
   EndTime,  
   LocationId,  
   L1ReasonId,  
   L2ReasonId,  
   L3ReasonId,  
   L4ReasonId,  
   TEFaultId,  
   ERTD_ID,  
   DownTime,  
   ReportDownTime,  
   Uptime,  
   PrimaryId,  
   SecondaryId,  
   InRptWindow,  
   CommentId,   
   Comment   
   )     
  SELECT ted.TEDet_Id,  
   ted.PU_Id,  
   tpu.PLId,        
   ted.source_pu_id,  
   ted.Start_Time,  
   COALESCE(ted.End_Time, @Now),  
   ted.Source_PU_Id,  
   ted.Reason_Level1,  
   ted.Reason_Level2,  
   ted.Reason_Level3,  
   ted.Reason_Level4,  
   ted.TEFault_Id,  
   ted.event_reason_tree_data_id,  
   DATEDIFF (second, ted.Start_Time, COALESCE(ted.End_Time, @Now)),  
   DATEDIFF (second, (CASE WHEN ted.Start_Time < @StartTime   
           THEN @StartTime   
           ELSE ted.Start_Time  
           END),  
         (CASE WHEN COALESCE(ted.End_Time, @Now) > @EndTime   
           THEN @EndTime   
           ELSE COALESCE(ted.End_Time, @Now)  
           END)),  
   ted.uptime * 60.0,  
   ted2.TEDet_Id,  
   ted3.TEDet_Id,  
   CASE   
   WHEN ted.Start_Time < @EndTime  
   AND COALESCE(ted.End_Time, @Now) > @StartTime  
   THEN 1  
   ELSE 0  
   END,  
   Co.Comment_Id,     
   Co.Comment_Text    
  FROM dbo.Timed_Event_Details ted WITH(NOLOCK)  
   JOIN @ProdUnits tpu ON ted.PU_Id = tpu.PUId AND tpu.PUId > 0      -- 2007-02-22 VMK Rev7.43, removed INNER  
   LEFT JOIN dbo.Timed_Event_Details ted2 WITH(NOLOCK) ON  ted.PU_Id = ted2.PU_Id  
        AND ted.Start_Time = ted2.End_Time  
        AND ted.TEDet_Id <> ted2.TEDet_Id  
   LEFT JOIN dbo.Timed_Event_Details ted3 WITH(NOLOCK) ON  ted.PU_Id = ted3.PU_Id  
        AND ted.End_Time = ted3.Start_Time  
        AND ted.TEDet_Id <> ted3.TEDet_Id  
   LEFT JOIN dbo.Comments Co WITH(NOLOCK) ON Co.Comment_Id = ted.Cause_Comment_Id -- 2005-Nov-15 VMK Rev7.02  
  WHERE ted.Start_Time < @EndTime  
  AND  (ted.End_Time > @StartTime OR ted.End_Time IS NULL)  
  OPTION (KEEP PLAN)  
  
  
UPDATE td     -- 2005-OCT-26 VMK Rev7.01 Modified code to use the dbo.#ProdLines and @ProdUnits table  
       --         Variables instead of linking to Db table.  
SET PUDESC =  CASE  WHEN pu.PUDesc LIKE ('%Converter Reliability%') OR pu.PUDesc LIKE ('%Rate Loss%')   
       THEN CASE  WHEN pl.PLDesc LIKE 'TT%'  
              THEN LTRIM(RTRIM(REPLACE(pl.PLDesc,'TT ',''))) + ' Converter Reliability'   
             WHEN pl.PLDesc LIKE 'PP%'  
             THEN LTRIM(RTRIM(REPLACE(pl.PLDesc,'PP ',''))) + ' Converter Reliability'    
             ELSE pu.PUDesc  
             END  
       WHEN pu.PUDesc LIKE ('%INTR Reliability%')                --Rev6.86  
       THEN CASE  WHEN pl.PLDesc LIKE 'TT%'                  --Rev6.86  
              THEN LTRIM(RTRIM(REPLACE(pl.PLDesc,'TT ',''))) + ' INTR Reliability'    --Rev6.86  --2006-04-11 VMK Rev7.18, changed Intermediate to INTR  
             WHEN pl.PLDesc LIKE 'PP%'                  --Rev6.86        
             THEN LTRIM(RTRIM(REPLACE(pl.PLDesc,'PP ',''))) + ' INTR Reliability'    --Rev6.86  --2006-04-11 VMK Rev7.18, changed Intermediate to INTR  
             ELSE pu.PUDesc                      --Rev6.86  
             END                         --Rev6.86  
       ELSE pu.PUDesc  
       END  
     
FROM  dbo.#Delays td WITH(NOLOCK)  
 INNER JOIN @ProdUnits pu ON td.PUID = pu.PUId  
 INNER JOIN @ProdLines pl ON pu.PLId = pl.PLId  
WHERE td.PUDESC IS NULL  
  
  
-- MKW - Get the maximum range for later queries  
SELECT TOP 1 @RangeStartTime = StartTime  
FROM dbo.#Delays WITH(NOLOCK)  
ORDER BY StartTime ASC  
OPTION (KEEP PLAN)  
  
SELECT TOP 1 @RangeEndTime = EndTime  
FROM dbo.#Delays WITH(NOLOCK)  
ORDER BY EndTime DESC  
OPTION (KEEP PLAN)  
  
  
--print 'PrimaryIds point to actual Primary event: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
-------------------------------------------------------------------------------  
-- Cycle through the dataset and ensure that all the PrimaryIds point to the  
-- actual Primary event.  
-------------------------------------------------------------------------------  
WHILE (SELECT Count(td1.TEDetId)  
  FROM dbo.#Delays td1 WITH(NOLOCK)  
  JOIN dbo.#Delays td2 WITH(NOLOCK) ON td1.PrimaryId = td2.TEDetId  
  WHERE td2.PrimaryId IS NOT NULL) > 0  
 BEGIN  
  UPDATE td1  
   SET PrimaryId = td2.PrimaryId  
  FROM dbo.#Delays td1 WITH(NOLOCK)  
   JOIN dbo.#Delays td2 WITH(NOLOCK) ON td1.PrimaryId = td2.TEDetId  
  WHERE td2.PrimaryId IS NOT NULL  
 END  
  
UPDATE dbo.#Delays  
 SET PrimaryId = TEDetId  
WHERE PrimaryId IS NULL  
  
--print 'Add Products to #Delays: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
-------------------------------------------------------------------------------  
-- Add the Products to the dataset.  
-------------------------------------------------------------------------------  
UPDATE td  
 SET ProdId = ps.Prod_Id  
FROM dbo.#Delays td WITH(NOLOCK)  
 INNER JOIN @ProductionStarts ps ON td.PUId = ps.PU_Id   
      AND td.StartTime >= ps.Start_Time  
      AND (td.StartTime < ps.End_Time OR ps.End_Time IS NULL)  
WHERE ps.Start_Time < @RangeEndTime  
 AND (ps.End_Time > @RangeStartTime OR ps.End_Time IS NULL)  -- MKW  
  
--print 'Add Shift/Crew to #Delays: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
-------------------------------------------------------------------------------  
-- Add the Shift and Crew to the dataset.  
-------------------------------------------------------------------------------  
-- 2005-OCT-26 VMK Rev7.01 Removed last UPDATE and changed 1st UPDATE to  
--         modify all rows.  
UPDATE td  
 SET Shift = cs.Shift_Desc,  
   Crew = cs.Crew_Desc  
FROM dbo.#Delays td WITH(NOLOCK)  
 INNER JOIN @ProdUnits tpu ON td.PUId = tpu.PUId  
 INNER JOIN dbo.Crew_Schedule cs WITH(NOLOCK) ON  tpu.ScheduleUnit = cs.PU_Id  
     AND td.StartTime >= cs.Start_Time  
     AND td.StartTime < cs.End_Time  
  
--print 'Add Line Status to #Delays: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
-------------------------------------------------------------------------------  
-- Add the Line Status to the dataset.  
-- 2006-03-20 VMK Rev7.14, removed @LineStatus unit, not getting all Line  
-- status.  There are some that have StartTime prior to @StartTime.  
-------------------------------------------------------------------------------  
UPDATE td  
 SET LineStatus = p.Phrase_Value  
FROM dbo.#Delays td WITH(NOLOCK)  
 JOIN @ProdUnits pu ON td.PUId = pu.PUId                    
 INNER JOIN dbo.Local_PG_Line_Status ls WITH(NOLOCK) ON  pu.LineStatusUnit = ls.Unit_Id    
     AND td.StartTime >= ls.Start_DateTime  
     AND (td.StartTime < ls.End_DateTime OR ls.End_DateTime IS NULL)  
 INNER JOIN dbo.Phrase p WITH(NOLOCK) ON ls.Line_Status_Id = p.Phrase_Id  
  
  
--print 'Get categories for #Delays: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
-------------------------------------------------------------------------------  
-- Retrieve the Schedule, Category, GroupCause and SubSystem categories for the  
-- dbo.Timed_Event_Details row from the Local_Timed_Event_Categories table using  
-- the TEDet_Id.  
-------------------------------------------------------------------------------  
  
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
  
  
--print 'Insert into #Primaries: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
-------------------------------------------------------------------------------  
-- Populate a separate temporary table that only contains the Primary records.  
-- This allows us to retrieve the EndTime of the previous downtime  
-- event which is used to calculate UpTime.  
-------------------------------------------------------------------------------  
-- 2005-Nov-15 VMK Rev7.02  
-- Replaced code and table for #Primaries with code and table @Primaries from  
-- spLocal_RptCvtgDDSStops tuned sp.  
-------------------------------------------------------------------------------  
INSERT @Primaries   
 (  
 TEDetId,  
 PUId,  
 StartTime,  
 EndTime  
 )  
SELECT td1.TEDetId,  
 td1.PUId,  
 MIN(td2.StartTime),  
 MAX(td2.EndTime)  
FROM dbo.#Delays td1 WITH(NOLOCK)  
 JOIN dbo.#Delays  td2 WITH(NOLOCK)  ON td1.TEDetId = td2.PrimaryId  
 JOIN @ProdUnits  pu  ON td1.PUID = pu.PUID   
WHERE td1.TEDetId = td1.PrimaryId  
 AND pu.DelayType <> @DelayTypeRateLossStr --FLD Rev8.52  
GROUP BY td1.TEDetId, td1.PUId  
ORDER BY td1.PUId, MIN(td2.StartTime) ASC  
option (keep plan)  
  
  
UPDATE p1 SET   
  ReportUptime =  CASE  WHEN p1.PUId = p2.PUId THEN DATEDIFF(ss, p2.EndTime, p1.StartTime)  
        WHEN p1.StartTime > @StartTime THEN DATEDIFF(ss,@StartTime, p1.StartTime)  
        ELSE 0.0  
        END  
FROM @Primaries p1  
JOIN @Primaries p2 ON p2.TEPrimaryId = (p1.TEPrimaryId - 1)   
WHERE p1.TEPrimaryId > 1  
  
UPDATE td SET   
  ReportUptime = tp.ReportUptime    
FROM dbo.#Delays td WITH(NOLOCK)  
JOIN @Primaries tp ON td.TEDetId = tp.TEDetId  
  
  
--print 'Update #Delays with #Primaries totals: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
-------------------------------------------------------------------------------  
-- Calculate the Statistics on the dataset and set NULL Uptimes to zero.  
-------------------------------------------------------------------------------  
  
UPDATE td SET   
 Stops =     
  CASE   
  WHEN tpu.DelayType <> @DelayTypeRateLossStr  
  AND (td.StartTime >= @StartTime)  
  THEN 1  
  ELSE 0  
  END,  
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
 Stops2m =  
  CASE   
  WHEN td.DownTime < 120  
  AND tpu.DelayType <> @DelayTypeRateLossStr  
  AND (td.ScheduleId = @SchedUnscheduledId OR td.ScheduleId IS NULL)  
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
  
  
UPDATE td SET    
 ReportDowntime    = 0,  
 StopsRateloss   = 1,  
 downtime    = null,  
 RawRateloss   = CONVERT(FLOAT,t1.result) * 60.0  
FROM dbo.#Delays td   
JOIN @ProdUnits pu   
ON td.PUID = pu.PUID  
JOIN @ProdLines pl   
ON pu.PLID = pl.PLID  
LEFT JOIN dbo.Tests t1   
ON (td.StartTime = t1.result_on)   
AND (pl.VarEffDowntimeId = t1.Var_Id)  
WHERE pu.DelayType = @DelayTypeRateLossStr  
  
  
--print 'Update @ProdUnits with UWS columns: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
  
--------------------------------------------------------------------------------------------  
--- Update @ProdUnits UWS columns with the appropriate prod Unit desc.  
--------------------------------------------------------------------------------------------  
  
--print 'Update @ProdUnits with UWS 1: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
  
--/*  
UPDATE pu  
SET UWS1 = upu1.PU_Desc,  
  UWS2 = upu2.PU_Desc  
FROM @ProdUnits pu  
 LEFT JOIN @UWS uws1 ON pu.PLId = uws1.PLId  
    AND uws1.InputOrder = 1  
 LEFT JOIN dbo.Prod_Units upu1 WITH(NOLOCK) ON uws1.UWSPUId = upu1.PU_Id   
 LEFT JOIN @UWS uws2 ON pu.PLId = uws2.PLId  
    AND uws2.InputOrder = 2  
 LEFT JOIN dbo.Prod_Units upu2 WITH(NOLOCK) ON uws2.UWSPUId = upu2.PU_Id  
--*/  
  
--print 'Update @ProdUnits with UWS 2: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
  
UPDATE td SET   
 [UWS1Parent]   = prs.ParentPRID,    --FLD Rev6.78     
 [UWS1ParentPM]   = prs.ParentPM,    --FLD Rev6.78   
 [UWS1GrandParent]  = prs.GrandParentPRID,   --FLD Rev6.78  
 [UWS1GrandParentPM] = prs.GrandParentPM,    --FLD Rev6.78  
 [UWS1PMTeam]   = prs.PMTeam,  
 UWS1Timestamp   = prs.EventTimestamp,  
 [INTR]     = plc.PL_Desc--,      
FROM dbo.#prsrun prs   
join @prodlines pl  
on prs.puid = pl.prodpuid  
join dbo.#delays td  
on (pl.reliabilitypuid = td.puid or pl.ratelosspuid = td.puid)  
and td.starttime >= prs.starttime   
and td.starttime < prs.endtime  
AND prs.Input_Order = 1  
LEFT JOIN dbo.Prod_Units puc WITH(NOLOCK)    
ON (prs.PRPLId = puc.PL_Id  
AND puc.PU_Desc LIKE '%INTR%')  
LEFT JOIN dbo.Prod_Lines plc WITH(NOLOCK)    
ON puc.PL_Id = plc.PL_Id  
  
--print 'Update @ProdUnits with UWS 3: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
  
UPDATE td  
SET [UWS2Parent]   = prs.ParentPRID,   --FLD Rev6.78      
  [UWS2ParentPM]   = prs.ParentPM,   --FLD Rev6.78   
  [UWS2GrandParent]  = prs.GrandParentPRID,  --FLD Rev6.78  
  [UWS2GrandParentPM] = prs.GrandParentPM,    --,   --FLD Rev6.78  
  [UWS2PMTeam]   = prs.PMTeam,  
  UWS2Timestamp   = prs.EventTimestamp  
FROM dbo.#prsrun prs   
join @prodlines pl  
on prs.puid = pl.prodpuid  
join dbo.#delays td  
on (pl.reliabilitypuid = td.puid or pl.ratelosspuid = td.puid)  
and td.starttime >= prs.starttime   
and td.starttime < prs.endtime  
AND prs.Input_Order = 2  
LEFT JOIN dbo.Prod_Units puc WITH(NOLOCK)    
ON (prs.PRPLId = puc.PL_Id  
AND puc.PU_Desc LIKE '%INTR%')  
LEFT JOIN dbo.Prod_Lines plc WITH(NOLOCK)    
ON puc.PL_Id = plc.PL_Id  
  
  
-- most of the UWS1 and UWS2 values in #Delays will be populated at this   
-- point, but some downtime events will start earlier than any of the parent rolls   
-- within the report window.  to handle these, we have the following code.  it may   
-- seem like a lot of work, but it shouldn't be too bad because it's only applied   
-- to a handful of records.  
  
--print 'ESTOutsideWindow ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
--/*  
insert dbo.#ESTOutsideWindow  
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
from dbo.#delays td  
join @prodlines pl  
on (td.puid = pl.reliabilitypuid or td.puid = pl.ratelosspuid)  
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
 EventTimestamp  
 )  
select  
 td.TEDetID,  
 e.Event_ID,  
 e.Source_Event,  
 td.PLID,  
 td.PUID,  
 e.pu_id,  
 e.[Timestamp]  
  
FROM dbo.#ESTOutsideWindow est with (nolock)  
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
join dbo.Events e1 with (nolock)  
on pdow.SourceEventID = e1.event_id  
  
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
 [UWS1ParentPM]   = RTRIM(LTRIM(COALESCE(LEFT(pdow.ParentPRID, 2), 'NoAssignedPRID'))),  
 [UWS1GrandParent]  = pdow.GrandParentPRID,    
 [UWS1GrandParentPM] = LEFT(pdow.GrandparentPRID, 2),  
 [UWS1PMTeam]   = pdow.PMTeam,  
 UWS1Timestamp   = pdow.EventTimestamp,  
 [INTR]     = pdow.INTR      
from @PRDTOutsideWindow pdow  
join dbo.#delays td  
on td.tedetid = pdow.tedetid  
where pdow.input_order = 1  
  
--print '@PRDTOutsideWindow 11 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
UPDATE td SET   
 [UWS2Parent]   = pdow.ParentPRID,    
 [UWS2ParentPM]   = RTRIM(LTRIM(COALESCE(LEFT(pdow.ParentPRID, 2), 'NoAssignedPRID'))),  
 [UWS2GrandParent]  = pdow.GrandParentPRID,    
 [UWS2GrandParentPM] = LEFT(pdow.GrandparentPRID, 2),  
 [UWS2PMTeam]   = pdow.PMTeam,  
 UWS2Timestamp   = pdow.EventTimestamp,  
 [INTR]     = pdow.INTR      
from @PRDTOutsideWindow pdow  
join dbo.#delays td  
on td.tedetid = pdow.tedetid  
where pdow.input_order = 2  
  
--end  
  
UPDATE  td set  
  
  UWS1FreshStorage =    
      CASE    
      WHEN prs.AgeOfPR <= 1.0   
      THEN 'Fresh'  
      ELSE 'Storage'  
      END  
  
FROM dbo.#Delays td WITH(NOLOCK)  
JOIN @ProdUnits tpu ON td.PUId = tpu.PUId  
LEFT JOIN dbo.#prsrun prs   
ON td.UWS1Parent = COALESCE(prs.GrandParentPRID, prs.ParentPRID)   
AND td.StartTime >= prs.StartTime   
AND td.StartTime < prs.EndTime  
WHERE td.CategoryId = @CatELPId  
  
  
UPDATE  td set   
  
  UWS2FreshStorage =    
      CASE    
      WHEN prs.AgeOfPR <= 1.0   
      THEN 'Fresh'  
      ELSE  'Storage'  
      END  
  
FROM dbo.#Delays td WITH(NOLOCK)  
JOIN @ProdUnits tpu ON td.PUId = tpu.PUId  
LEFT JOIN dbo.#prsrun prs   
ON td.UWS1Parent = COALESCE(prs.GrandParentPRID, prs.ParentPRID)   
AND td.StartTime >= prs.StartTime   
AND td.StartTime < prs.EndTime  
WHERE td.CategoryId = @CatELPId  
  
  
-- Update the ELP Report Downtime, Fresh DT and Storage DT columns in #Delays.  
UPDATE  td  
SET ReportELPDowntime = CASE WHEN tpu.DelayType <> @DelayTypeRateLossStr  
              AND (td.CategoryId = @CatELPId)  
         THEN td.downtime --td.ReportDownTime  
         ELSE 0  
         END--,  
  
FROM dbo.#Delays td WITH(NOLOCK)  
 JOIN @ProdUnits tpu ON td.PUId = tpu.PUId  
  
  
-------------------------------------  
  
  
  update td set  
  
   UWS1PMProd = p1.Prod_Desc,   
   UWS2PMProd = p2.Prod_Desc    
  
  FROM dbo.#Delays td WITH(NOLOCK)  
   JOIN  @ProdUnits tpu ON td.PUId = tpu.PUId  
   JOIN  @ProdLines tpl ON tpu.PLId = tpl.PLId  
   JOIN  dbo.Prod_Units pu WITH(NOLOCK) ON td.PUId = pu.PU_Id  
  
   LEFT JOIN dbo.#prsrun prs   
   on tpl.prodpuid = prs.puid   
   and (td.starttime < prs.endtime)   
   and (td.starttime >= prs.starttime)   
  
   LEFT JOIN dbo.Production_Starts  ps1 WITH(NOLOCK)   
   ON prs.PRPUId = ps1.PU_Id  
   AND ps1.Start_Time <= prs.PRTimeStamp  
   AND ps1.End_Time > prs.PRTimeStamp  
   LEFT JOIN dbo.Products p1 WITH(NOLOCK)   
   ON ps1.Prod_Id = p1.Prod_Id  
  
   LEFT JOIN dbo.Production_Starts  ps2 WITH(NOLOCK)   
   ON prs.PRPUId = ps2.PU_Id  
   AND ps2.Start_Time <= prs.PRTimeStamp  
   AND ps2.End_Time > prs.PRTimeStamp  
   LEFT JOIN dbo.Products p2 WITH(NOLOCK)   
   ON ps2.Prod_Id = p2.Prod_Id  
  
  WHERE td.CategoryId = @CatELPId AND td.InRptWindow = 1  
  AND (charindex('|' + td.LineStatus + '|', '|' + @LineStatusList + '|') > 0   
    OR  @LineStatusList = 'All')  
  
  
-----------------------------------------------------------------------------  
-- 2005-NOV-09 VMK Rev7.01  
-- Summarize Runtime by PUId, PaperMachine, PRPLId and InputOrder  
-----------------------------------------------------------------------------  
  
UPDATE prs SET  
  PaperMachine = coalesce(prs.GrandParentPM, prs.ParentPM),  
  [PaperSource]   = COALESCE((CASE  
          WHEN prs.ParentPM = 'NoAssignedPRID'         THEN prs.ParentPM  
          WHEN prs.ParentPM IS NOT NULL AND prs.GrandParentPM IS NULL THEN prs.ParentPM  
          ELSE prs.GrandParentPM + ' ---> ' + prs.ParentPM  
          END), 'NoAssignedPRID'),  
  [PaperRunBy]   = COALESCE((CASE                           
          WHEN prs.ParentPM = 'NoAssignedPRID'           THEN prs.ParentPM  
          WHEN prs.ParentPM IS NOT NULL AND prs.GrandParentPM IS NOT NULL  THEN prs.ParentPM + ' ---> ' + COALESCE(pll.PL_Desc, pl.PL_Desc)  
          ELSE COALESCE(pll.PL_Desc, pl.PL_Desc)  
          END), 'NoAssignedPRID'),  
  [INTR]     = pl.PL_Desc  
FROM dbo.#prsrun prs  
LEFT  JOIN dbo.Prod_Units  pu WITH(NOLOCK)   ON prs.PUId = pu.PU_Id  
LEFT  JOIN dbo.Prod_Units ppu WITH(NOLOCK)  ON prs.PRPLId = ppu.PL_Id        
AND ppu.PU_Desc LIKE '%INTR%'  
LEFT  JOIN dbo.Prod_Lines pl WITH(NOLOCK)   ON ppu.PL_Id = pl.PL_Id  
LEFT  JOIN dbo.Prod_Lines   pll WITH(NOLOCK)  ON pu.PL_Id = pll.PL_Id  
  
  
----------------------------------------------------------------------------------------------------  
-- these time ranges are used so that we can sum up downtime and stops counts according to different   
-- grouping criteria without inflating the numbers due to having paper events on multiple unwind stands.  
-- be VERY careful in changing the updates to these date ranges.  the basic idea is two eliminate any   
-- overlap between paper events within the same grouping criteria.  events that take place entirely   
-- within another event of the same grouping criteria will then have their runtimes adusted to zero,   
-- allowing the larger event to capture the time.   
-- note that "=" is not included in the comparisons for initial updates.  this is then handled in the   
-- next set of updates.  this is the most efficient way to allow for multiple events with the same   
-- start time or end time.  
-----------------------------------------------------------------------------------------------------  
  
--Rev7.6  
update prs set  
  
 StartTimeLinePS =   
  coalesce(  
  (  
  select  
   case   
   when max(pr.EndTime) > prs.EndTime  
   then prs.starttime   
   else max(pr.EndTime)  
   end     
  from dbo.#prsrun pr  
  where pr.PLID = prs.PLID  
  and pr.PaperSource = prs.PaperSource  
  and pr.StartTime < prs.StartTime   
  and pr.EndTime > prs.StartTime   
  ),prs.StartTime),  
  
 EndTimeLinePS =   
  coalesce(  
  (  
  select  
   case   
   when min(pr.StartTime) > prs.StartTime  
   then prs.endtime   
   else min(pr.StartTime)  
   end     
  from dbo.#prsrun pr  
  where pr.PLID = prs.PLID  
  and pr.PaperSource = prs.PaperSource  
  and pr.StartTime < prs.EndTime   
  and pr.EndTime > prs.EndTime   
  ),prs.EndTime),  
  
  
-- grouping time ranges at the Fresh/Storage level have been added to eliminate the overlap   
-- or Fresh or Storage status on multiple UWS within the broader grouping conditions.  
  
 StartTimeLinePSFresh =   
  coalesce(  
  (  
  select  
   case   
   when max(pr.EndTime) > prs.EndTime  
   then prs.starttime   
   else max(pr.EndTime)  
   end     
  from dbo.#prsrun pr  
  where pr.PLID = prs.PLID  
  and pr.PaperSource = prs.PaperSource  
  and pr.Fresh = prs.Fresh  
  and pr.StartTime < prs.StartTime   
  and pr.EndTime > prs.StartTime   
  ),prs.StartTime),  
  
  
-- grouping time ranges at the Fresh/Storage level have been added to eliminate the overlap   
-- or Fresh or Storage status on multiple UWS within the broader grouping conditions.  
  
 EndTimeLinePSFresh =   
  coalesce(  
  (  
  select  
   case   
   when min(pr.StartTime) > prs.StartTime  
   then prs.endtime   
   else min(pr.StartTime)  
   end     
  from dbo.#prsrun pr  
  where pr.PLID = prs.PLID  
  and pr.PaperSource = prs.PaperSource  
  and pr.Fresh = PRS.Fresh  
  and pr.StartTime < prs.EndTime   
  and pr.EndTime > prs.EndTime   
  ),prs.EndTime),  
  
 StartTimeLine =   
  coalesce(  
  (  
  select  
   case   
   when max(pr.EndTime) > prs.EndTime  
   then prs.starttime   
   else max(pr.EndTime)  
   end     
  from dbo.#prsrun pr  
  where pr.PLID = prs.PLID  
  and pr.StartTime < prs.StartTime   
  and pr.EndTime > prs.StartTime   
  ),prs.StartTime),  
  
 EndTimeLine =   
  coalesce(  
  (  
  select  
   case   
   when min(pr.StartTime) > prs.StartTime  
   then prs.endtime   
   else min(pr.StartTime)  
   end     
  from dbo.#prsrun pr  
  where pr.PLID = prs.PLID  
  and pr.StartTime < prs.EndTime   
  and pr.EndTime > prs.EndTime   
  ),prs.EndTime),  
  
  
-- grouping time ranges at the Fresh/Storage level have been added to eliminate the overlap   
-- or Fresh or Storage status on multiple UWS within the broader grouping conditions.  
  
 StartTimeLineFresh =   
  coalesce(  
  (  
  select  
   case   
   when max(pr.EndTime) > prs.EndTime  
   then prs.starttime   
   else max(pr.EndTime)  
   end     
  from dbo.#prsrun pr  
  where pr.PLID = prs.PLID  
  and pr.Fresh = prs.Fresh  
  and pr.StartTime < prs.StartTime   
  and pr.EndTime > prs.StartTime   
  ),prs.StartTime),  
  
  
-- grouping time ranges at the Fresh/Storage level have been added to eliminate the overlap   
-- or Fresh or Storage status on multiple UWS within the broader grouping conditions.  
  
 EndTimeLineFresh =   
  coalesce(  
  (  
  select  
   case   
   when min(pr.StartTime) > prs.StartTime  
   then prs.endtime   
   else min(pr.StartTime)  
   end     
  from dbo.#prsrun pr  
  where pr.PLID = prs.PLID  
  and pr.Fresh = prs.Fresh  
  and pr.StartTime < prs.EndTime   
  and pr.EndTime > prs.EndTime   
  ),prs.EndTime),  
  
 StartTimeIntrPL =   
  coalesce(  
  (  
  select  
   case   
   when max(pr.EndTime) > prs.EndTime  
   then prs.starttime   
   else max(pr.EndTime)  
   end     
  from dbo.#prsrun pr  
  where pr.paperrunby = prs.paperrunby --pr.PLID = prs.PLID  
  and coalesce(pr.Intr, 'NoIntr') = coalesce(prs.Intr,'NoIntr')  
  and pr.StartTime < prs.StartTime   
  and pr.EndTime > prs.StartTime   
  ),prs.StartTime),  
  
 EndTimeIntrPL =   
  coalesce(  
  (  
  select  
   case   
   when min(pr.StartTime) > prs.StartTime  
   then prs.endtime   
   else min(pr.StartTime)  
   end     
  from dbo.#prsrun pr  
  where pr.paperrunby = prs.paperrunby --pr.PLID = prs.PLID  
  and coalesce(pr.Intr, 'NoIntr') = coalesce(prs.Intr,'NoIntr')  
  and pr.StartTime < prs.EndTime   
  and pr.EndTime > prs.EndTime   
  ),prs.EndTime),  
  
  
-- grouping time ranges at the Fresh/Storage level have been added to eliminate the overlap   
-- or Fresh or Storage status on multiple UWS within the broader grouping conditions.  
  
 StartTimeIntrPLFresh =   
  coalesce(  
  (  
  select  
   case   
   when max(pr.EndTime) > prs.EndTime  
   then prs.starttime   
   else max(pr.EndTime)  
   end     
  from dbo.#prsrun pr  
  where pr.paperrunby = prs.paperrunby --pr.PLID = prs.PLID  
  and coalesce(pr.Intr, 'NoIntr') = coalesce(prs.Intr,'NoIntr')  
  and pr.Fresh = prs.Fresh  
  and pr.StartTime < prs.StartTime   
  and pr.EndTime > prs.StartTime   
  ),prs.StartTime),  
  
  
-- grouping time ranges at the Fresh/Storage level have been added to eliminate the overlap   
-- or Fresh or Storage status on multiple UWS within the broader grouping conditions.  
  
 EndTimeIntrPLFresh =   
  coalesce(  
  (  
  select  
   case   
   when min(pr.StartTime) > prs.StartTime  
   then prs.endtime   
   else min(pr.StartTime)  
   end     
  from dbo.#prsrun pr  
  where pr.paperrunby = prs.paperrunby --pr.PLID = prs.PLID  
  and coalesce(pr.Intr, 'NoIntr') = coalesce(prs.Intr,'NoIntr')  
  and pr.Fresh = prs.Fresh  
  and pr.StartTime < prs.EndTime   
  and pr.EndTime > prs.EndTime   
  ),prs.EndTime),  
  
 StartTimePMRunBy =   
  coalesce(  
  (  
  select  
   case   
   when max(pr.EndTime) > prs.EndTime  
   then prs.starttime   
   else max(pr.EndTime)  
   end     
  from dbo.#prsrun pr  
  where pr.PaperMachine = prs.PaperMachine  
  and pr.PaperRunBy = prs.PaperRunBy  
  and pr.StartTime < prs.StartTime   
  and pr.EndTime > prs.StartTime   
  ),prs.StartTime),  
  
 EndTimePMRunBy =   
  coalesce(  
  (  
  select  
   case   
   when min(pr.StartTime) > prs.StartTime  
   then prs.endtime   
   else min(pr.StartTime)  
   end     
  from dbo.#prsrun pr  
  where pr.PaperMachine = prs.PaperMachine  
  and pr.PaperRunBy = prs.PaperRunBy  
  and pr.StartTime < prs.EndTime   
  and pr.EndTime > prs.EndTime   
  ),prs.EndTime),  
  
  
-- grouping time ranges at the Fresh/Storage level have been added to eliminate the overlap   
-- or Fresh or Storage status on multiple UWS within the broader grouping conditions.  
  
 StartTimePMRunByFresh =   
  coalesce(  
  (  
  select  
   case   
   when max(pr.EndTime) > prs.EndTime  
   then prs.starttime   
   else max(pr.EndTime)  
   end     
  from dbo.#prsrun pr  
  where pr.PaperMachine = prs.PaperMachine  
  and pr.PaperRunBy = prs.PaperRunBy  
  and pr.Fresh = prs.Fresh  
  and pr.StartTime < prs.StartTime   
  and pr.EndTime > prs.StartTime   
  ),prs.StartTime),  
  
  
-- grouping time ranges at the Fresh/Storage level have been added to eliminate the overlap   
-- or Fresh or Storage status on multiple UWS within the broader grouping conditions.  
  
 EndTimePMRunByFresh =   
  coalesce(  
  (  
  select  
   case   
   when min(pr.StartTime) > prs.StartTime  
   then prs.endtime   
   else min(pr.StartTime)  
   end     
  from dbo.#prsrun pr  
  where pr.PaperMachine = prs.PaperMachine  
  and pr.PaperRunBy = prs.PaperRunBy  
  and pr.Fresh = prs.Fresh  
  and pr.StartTime < prs.EndTime   
  and pr.EndTime > prs.EndTime   
  ),prs.EndTime)  
  
from dbo.#prsrun prs  
  
--print 'Group by Time Ranges 1 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
  
--/*  
update sprs set  
 StartTimeLinePS =   
  case  
  when sprs.StartTimeLinePS > sprs.EndTimeLinePS  
  then sprs.EndTimeLinePS  
  else sprs.StartTimeLinePS  
  end,  
 StartTimeLinePSFresh =   
  case  
  when sprs.StartTimeLinePSFresh > sprs.EndTimeLinePSFresh  
  then sprs.EndTimeLinePSFresh  
  else sprs.StartTimeLinePSFresh  
  end,  
 StartTimeLine =   
  case  
  when sprs.StartTimeLine > sprs.EndTimeLine  
  then sprs.EndTimeLine  
  else sprs.StartTimeLine  
  end,  
 StartTimeLineFresh =   
  case  
  when sprs.StartTimeLineFresh > sprs.EndTimeLineFresh  
  then sprs.EndTimeLineFresh  
  else sprs.StartTimeLineFresh  
  end,  
 StartTimeIntrPL =   
  case  
  when sprs.StartTimeIntrPL > sprs.EndTimeIntrPL  
  then sprs.EndTimeIntrPL  
  else sprs.StartTimeIntrPL  
  end,  
 StartTimeIntrPLFresh =   
  case  
  when sprs.StartTimeIntrPLFresh > sprs.EndTimeIntrPLFresh  
  then sprs.EndTimeIntrPLFresh  
  else sprs.StartTimeIntrPLFresh  
  end,  
 StartTimePMRunBy =   
  case  
  when sprs.StartTimePMRunBy > sprs.EndTimePMRunBy  
  then sprs.EndTimePMRunBy  
  else sprs.StartTimePMRunBy  
  end,  
 StartTimePMRunByFresh =   
  case  
  when sprs.StartTimePMRunByFresh > sprs.EndTimePMRunByFresh  
  then sprs.EndTimePMRunByFresh  
  else sprs.StartTimePMRunByFresh  
  end  
from dbo.#PRsRun sprs with (nolock)  
where (  
 sprs.StartTimeLinePS > sprs.EndTimeLinePS  
or sprs.StartTimeLinePSFresh > sprs.EndTimeLinePSFresh  
or sprs.StartTimeLine > sprs.EndTimeLine  
or sprs.StartTimeLineFresh > sprs.EndTimeLineFresh  
or sprs.StartTimeIntrPL > sprs.EndTimeIntrPL  
or sprs.StartTimeIntrPLFresh > sprs.EndTimeIntrPLFresh  
or sprs.StartTimePMRunBy > sprs.EndTimePMRunBy  
or sprs.StartTimePMRunByFresh > sprs.EndTimePMRunByFresh  
)  
  
--*/  
  
--print 'Group by Time Ranges 2 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
  
update prs set  
 prs.StartTimeLinePS = prs.EndTimeLinePS  
from dbo.#prsrun prs with (nolock)  
join dbo.#prsrun pr with (nolock)  
on pr.PLID = prs.PLID  
and pr.PaperSource = prs.PaperSource  
and prs.StartTimeLinePS < prs.EndTimeLinePS  
and pr.StartTimeLinePS < pr.EndTimeLinePS  
where (pr.StartTimeLinePS = prs.StartTimeLinePS or pr.EndTimeLinePS = prs.EndTimeLinePS)  
and datediff(ss,pr.StartTimeLinePS,pr.EndTimeLinePS) > datediff(ss,prs.StartTimeLinePS,prs.EndTimeLinePS)  
  
  
--print 'Group by Time Ranges 3 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
  
update prs set  
 prs.StartTimeLinePS = prs.EndTimeLinePS  
from dbo.#prsrun prs with (nolock)  
join dbo.#prsrun pr with (nolock)  
on pr.PLID = prs.PLID  
and pr.PaperSource = prs.PaperSource  
and prs.StartTimeLinePS < prs.EndTimeLinePS  
and pr.StartTimeLinePS < pr.EndTimeLinePS  
where pr.[id_num] > prs.[id_num]  
and (pr.StartTimeLinePS = prs.StartTimeLinePS  
    and pr.EndTimeLinePS = prs.EndTimeLinePS)  
  
  
--print 'Group by Time Ranges 3 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
-- grouping time ranges at the Fresh/Storage level have been added to eliminate the overlap   
-- or Fresh or Storage status on multiple UWS within the broader grouping conditions.  
  
update prs set  
 prs.StartTimeLinePSFresh = prs.EndTimeLinePSFresh  
from dbo.#prsrun prs with (nolock)  
join dbo.#prsrun pr with (nolock)  
on pr.PLID = prs.PLID  
and pr.PaperSource = prs.PaperSource  
and pr.Fresh = prs.Fresh  
and prs.StartTimeLinePSFresh < prs.EndTimeLinePSFresh  
and pr.StartTimeLinePSFresh < pr.EndTimeLinePSFresh  
where (pr.StartTimeLinePSFresh = prs.StartTimeLinePSFresh or pr.EndTimeLinePSFresh = prs.EndTimeLinePSFresh)  
and datediff(ss,pr.StartTimeLinePSFresh,pr.EndTimeLinePSFresh)   
    > datediff(ss,prs.StartTimeLinePSFresh,prs.EndTimeLinePSFresh)  
  
  
--print 'Group by Time Ranges 3 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
-- grouping time ranges at the Fresh/Storage level have been added to eliminate the overlap   
-- or Fresh or Storage status on multiple UWS within the broader grouping conditions.  
  
update prs set  
 prs.StartTimeLinePSFresh = prs.EndTimeLinePSFresh  
from dbo.#prsrun prs with (nolock)  
join dbo.#prsrun pr with (nolock)  
on pr.PLID = prs.PLID  
and pr.PaperSource = prs.PaperSource  
and pr.Fresh = prs.Fresh  
and prs.StartTimeLinePSFresh < prs.EndTimeLinePSFresh  
and pr.StartTimeLinePSFresh < pr.EndTimeLinePSFresh  
where pr.[id_num] > prs.[id_num]  
and (pr.StartTimeLinePSFresh = prs.StartTimeLinePSFresh  
    and pr.EndTimeLinePSFresh = prs.EndTimeLinePSFresh)  
  
  
--print 'Group by Time Ranges 4 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
  
update prs set  
 prs.StartTimeLine = prs.EndTimeLine  
from dbo.#prsrun prs with (nolock)  
join dbo.#prsrun pr with (nolock)  
on pr.PLID = prs.PLID  
and prs.StartTimeLine < prs.EndTimeLine  
and pr.StartTimeLine < pr.EndTimeLine  
where (pr.StartTimeLine = prs.StartTimeLine or pr.EndTimeLine = prs.EndTimeLine)  
and datediff(ss,pr.StartTimeLine,pr.EndTimeLine) > datediff(ss,prs.StartTimeLine,prs.EndTimeLine)  
  
  
--print 'Group by Time Ranges 5 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
  
update prs set  
 prs.StartTimeLine = prs.EndTimeLine  
from dbo.#prsrun prs with (nolock)  
join dbo.#prsrun pr with (nolock)  
on pr.PLID = prs.PLID  
and prs.StartTimeLine < prs.EndTimeLine  
and pr.StartTimeLine < pr.EndTimeLine  
where pr.[id_num] > prs.[id_num]  
and (pr.StartTimeLine = prs.StartTimeLine  
    and pr.EndTimeLine = prs.EndTimeLine)  
  
  
  
--print 'Group by Time Ranges 3 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
-- grouping time ranges at the Fresh/Storage level have been added to eliminate the overlap   
-- or Fresh or Storage status on multiple UWS within the broader grouping conditions.  
  
update prs set  
 prs.StartTimeLineFresh = prs.EndTimeLineFresh  
from dbo.#prsrun prs with (nolock)  
join dbo.#prsrun pr with (nolock)  
on pr.PLID = prs.PLID  
and pr.Fresh = prs.Fresh  
and prs.StartTimeLineFresh < prs.EndTimeLineFresh  
and pr.StartTimeLineFresh < pr.EndTimeLineFresh  
where (pr.StartTimeLineFresh = prs.StartTimeLineFresh or pr.EndTimeLineFresh = prs.EndTimeLineFresh)  
and datediff(ss,pr.StartTimeLineFresh,pr.EndTimeLineFresh)   
  > datediff(ss,prs.StartTimeLineFresh,prs.EndTimeLineFresh)  
  
  
--print 'Group by Time Ranges 3 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
-- grouping time ranges at the Fresh/Storage level have been added to eliminate the overlap   
-- or Fresh or Storage status on multiple UWS within the broader grouping conditions.  
  
update prs set  
 prs.StartTimeLineFresh = prs.EndTimeLineFresh  
from dbo.#prsrun prs with (nolock)  
join dbo.#prsrun pr with (nolock)  
on pr.PLID = prs.PLID  
and pr.Fresh = prs.Fresh  
and prs.StartTimeLineFresh < prs.EndTimeLineFresh  
and pr.StartTimeLineFresh < pr.EndTimeLineFresh  
where pr.[id_num] > prs.[id_num]  
and (pr.StartTimeLineFresh = prs.StartTimeLineFresh  
    and pr.EndTimeLineFresh = prs.EndTimeLineFresh)  
  
  
--print 'Group by Time Ranges 6 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
  
update prs set  
 prs.StartTimeIntrPL = prs.EndTimeIntrPL  
from dbo.#prsrun prs with (nolock)  
join dbo.#prsrun pr with (nolock)  
on pr.paperrunby = prs.paperrunby   
and coalesce(pr.Intr,'NoIntr') = coalesce(prs.Intr,'NoIntr')  
and prs.StartTimeIntrPL < prs.EndTimeIntrPL  
and pr.StartTimeIntrPL < pr.EndTimeIntrPL  
where (pr.StartTimeIntrPL = prs.StartTimeIntrPL or pr.EndTimeIntrPL = prs.EndTimeIntrPL)  
and datediff(ss,pr.StartTimeIntrPL,pr.EndTimeIntrPL) > datediff(ss,prs.StartTimeIntrPL,prs.EndTimeIntrPL)  
  
  
--print 'Group by Time Ranges 7 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
  
update prs set  
 prs.StartTimeIntrPL = prs.EndTimeIntrPL  
from dbo.#prsrun prs with (nolock)  
join dbo.#prsrun pr with (nolock)  
on pr.paperrunby = prs.paperrunby   
and coalesce(pr.Intr,'NoIntr') = coalesce(prs.Intr,'NoIntr')  
and prs.StartTimeIntrPL < prs.EndTimeIntrPL  
and pr.StartTimeIntrPL < pr.EndTimeIntrPL  
where pr.[id_num] > prs.[id_num]  
and (pr.StartTimeIntrPL = prs.StartTimeIntrPL  
    and pr.EndTimeIntrPL = prs.EndTimeIntrPL)  
  
  
--print 'Group by Time Ranges 3 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
-- grouping time ranges at the Fresh/Storage level have been added to eliminate the overlap   
-- or Fresh or Storage status on multiple UWS within the broader grouping conditions.  
  
update prs set  
 prs.StartTimeIntrPLFresh = prs.EndTimeIntrPLFresh  
from dbo.#prsrun prs with (nolock)  
join dbo.#prsrun pr with (nolock)  
on pr.paperrunby = prs.paperrunby   
and coalesce(pr.Intr,'NoIntr') = coalesce(prs.Intr,'NoIntr')  
and pr.Fresh = prs.Fresh  
and prs.StartTimeIntrPLFresh < prs.EndTimeIntrPLFresh  
and pr.StartTimeIntrPLFresh < pr.EndTimeIntrPLFresh  
where (pr.StartTimeIntrPLFresh = prs.StartTimeIntrPLFresh or pr.EndTimeIntrPLFresh = prs.EndTimeIntrPLFresh)  
and datediff(ss,pr.StartTimeIntrPLFresh,pr.EndTimeIntrPLFresh) > datediff(ss,prs.StartTimeIntrPLFresh,prs.EndTimeIntrPLFresh)  
  
  
--print 'Group by Time Ranges 3 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
-- grouping time ranges at the Fresh/Storage level have been added to eliminate the overlap   
-- or Fresh or Storage status on multiple UWS within the broader grouping conditions.  
  
update prs set  
 prs.StartTimeIntrPLFresh = prs.EndTimeIntrPLFresh  
from dbo.#prsrun prs with (nolock)  
join dbo.#prsrun pr with (nolock)  
on pr.paperrunby = prs.paperrunby   
and coalesce(pr.Intr,'NoIntr') = coalesce(prs.Intr,'NoIntr')  
and pr.Fresh = prs.Fresh  
and prs.StartTimeIntrPLFresh < prs.EndTimeIntrPLFresh  
and pr.StartTimeIntrPLFresh < pr.EndTimeIntrPLFresh  
where pr.[id_num] > prs.[id_num]  
and (pr.StartTimeIntrPLFresh = prs.StartTimeIntrPLFresh  
    and pr.EndTimeIntrPLFresh = prs.EndTimeIntrPLFresh)  
  
  
--print 'Group by Time Ranges 8 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
  
update prs set  
 prs.StartTimePMRunBy = prs.EndTimePMRunBy  
from dbo.#prsrun prs with (nolock)  
join dbo.#prsrun pr with (nolock)  
on pr.PaperMachine = prs.PaperMachine  
and pr.PaperRunBy = prs.PaperRunBy  
and prs.StartTimePMRunBy < prs.EndTimePMRunBy  
and pr.StartTimePMRunBy < pr.EndTimePMRunBy  
where (pr.StartTimePMRunBy = prs.StartTimePMRunBy or pr.EndTimePMRunBy = prs.EndTimePMRunBy)  
and datediff(ss,pr.StartTimePMRunBy,pr.EndTimePMRunBy) > datediff(ss,prs.StartTimePMRunBy,prs.EndTimePMRunBy)  
  
  
--print 'Group by Time Ranges 9 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
  
update prs set  
 prs.StartTimePMRunBy = prs.EndTimePMRunBy  
from dbo.#prsrun prs with (nolock)  
join dbo.#prsrun pr with (nolock)  
on pr.PaperMachine = prs.PaperMachine  
and pr.PaperRunBy = prs.PaperRunBy  
and prs.StartTimePMRunBy < prs.EndTimePMRunBy  
and pr.StartTimePMRunBy < pr.EndTimePMRunBy  
where pr.[id_num] > prs.[id_num]  
and (pr.StartTimePMRunBy = prs.StartTimePMRunBy  
    and pr.EndTimePMRunBy = prs.EndTimePMRunBy)  
  
  
--print 'Group by Time Ranges 3 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
-- grouping time ranges at the Fresh/Storage level have been added to eliminate the overlap   
-- or Fresh or Storage status on multiple UWS within the broader grouping conditions.  
  
update prs set  
 prs.StartTimePMRunByFresh = prs.EndTimePMRunByFresh  
from dbo.#prsrun prs with (nolock)  
join dbo.#prsrun pr with (nolock)  
on pr.PaperMachine = prs.PaperMachine  
and pr.PaperRunBy = prs.PaperRunBy  
and pr.Fresh = prs.Fresh  
and prs.StartTimePMRunByFresh < prs.EndTimePMRunByFresh  
and pr.StartTimePMRunByFresh < pr.EndTimePMRunByFresh  
where (pr.StartTimePMRunByFresh = prs.StartTimePMRunByFresh or pr.EndTimePMRunByFresh = prs.EndTimePMRunByFresh)  
and datediff(ss,pr.StartTimePMRunByFresh,pr.EndTimePMRunByFresh) > datediff(ss,prs.StartTimePMRunByFresh,prs.EndTimePMRunByFresh)  
  
  
--print 'Group by Time Ranges 3 ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
-- grouping time ranges at the Fresh/Storage level have been added to eliminate the overlap   
-- or Fresh or Storage status on multiple UWS within the broader grouping conditions.  
  
update prs set  
 prs.StartTimePMRunByFresh = prs.EndTimePMRunByFresh  
from dbo.#prsrun prs with (nolock)  
join dbo.#prsrun pr with (nolock)  
on pr.PaperMachine = prs.PaperMachine  
and pr.PaperRunBy = prs.PaperRunBy  
and pr.Fresh = prs.Fresh  
and prs.StartTimePMRunByFresh < prs.EndTimePMRunByFresh  
and pr.StartTimePMRunByFresh < pr.EndTimePMRunByFresh  
where pr.[id_num] > prs.[id_num]  
and (pr.StartTimePMRunByFresh = prs.StartTimePMRunByFresh  
    and pr.EndTimePMRunByFresh = prs.EndTimePMRunByFresh)  
  
  
-------------------------------------------------------------------------------  
-------------------------------------------------------------------------------  
  
--print 'PRDTMetrics ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
  
--Rev7.6  
insert @PRDTMetrics  
 (  
 id_num,  
  
 ELPStops,  
 ELPDT,  
 RLELPDT,  
 FreshStops,  
 FreshDT,  
 FreshRLELPDT,   
 StorageStops,   
 StorageDT,  
 StorageRLELPDT,   
 ELPSchedDT,  
 FreshSchedDT,  
 StorageSchedDT,  
  
 ELPStopsLinePS,  
 ELPDTLinePS,  
 RLELPDTLinePS,  
 FreshStopsLinePS,  
 FreshDTLinePS,   
 FreshRLELPDTLinePS,    
 StorageStopsLinePS,   
 StorageDTLinePS,  
 StorageRLELPDTLinePS,   
 ELPSchedDTLinePS,  
 FreshSchedDTLinePS,  
 StorageSchedDTLinePS,  
  
 ELPStopsLine,  
 ELPDTLine,  
 RLELPDTLine,  
 FreshStopsLine,  
 FreshDTLine,  
 FreshRLELPDTLine,    
 StorageStopsLine,   
 StorageDTLine,  
 StorageRLELPDTLine,   
 ELPSchedDTLine,  
 FreshSchedDTLine,  
 StorageSchedDTLine,  
  
 ELPStopsIntrPL,  
 ELPDTIntrPL,  
 RLELPDTIntrPL,  
 FreshStopsIntrPL,  
 FreshDTIntrPL,  
 FreshRLELPDTIntrPL,    
 StorageStopsIntrPL,   
 StorageDTIntrPL,  
 StorageRLELPDTIntrPL,   
 ELPSchedDTIntrPL,  
 FreshSchedDTIntrPL,  
 StorageSchedDTIntrPL,  
  
 ELPStopsPMRunBy,  
 ELPDTPMRunBy,  
 RLELPDTPMRunBy,  
 FreshStopsPMRunBy,  
 FreshDTPMRunBy,  
 FreshRLELPDTPMRunBy,    
 StorageStopsPMRunBy,   
 StorageDTPMRunBy,  
 StorageRLELPDTPMRunBy,   
 ELPSchedDTPMRunBy,  
 FreshSchedDTPMRunBy,  
 StorageSchedDTPMRunBy  
  
 )  
  
select  
  
 prs.id_num,  
  
 SUM(  
  CASE   
  when  td.CategoryId = @CatELPId  
  and  td.StopsELP = 1  
  and td.starttime >= prs.starttime  
  and (td.starttime < prs.endtime or prs.endtime is null)  
  THEN  1   
  ELSE  0   
  END  
  ) ELPStops,  
  
 sum(  
  case  
  WHEN tpu.DelayType <> @DelayTypeRateLossStr  
  AND td.CategoryId = @CatELPId  
  and td.starttime >= prs.starttime  
  and (td.starttime < prs.endtime or prs.endtime is null)  
  then td.downtime --ReportELPDowntime   
  else 0.0  
  end  
  ) ELPDT,  
  
 sum(  
  case  
  when td.CategoryId = @CatELPId  
  and td.starttime >= prs.starttime  
  and (td.starttime < prs.endtime or prs.endtime is null)  
  then td.RawRateloss --td.ReportRLDowntime  
  else 0.0  
  end   
  ) RLELPDT,  
  
 SUM(  
  CASE   
  WHEN  prs.AgeOfPR <= 1.0   
  AND  prs.PaperMachine <> 'NoAssignedPRID'   
  AND td.CategoryId = @CatELPId   
  AND  td.StopsELP = 1   
  and td.starttime >= prs.starttime  
  and td.starttime < prs.endtime  
  THEN  1  
  ELSE  0  
  END  
  ) FreshStops,  
  
 SUM(  
  CASE   
  WHEN  prs.AgeOfPR <= 1.0   
  AND  prs.PaperMachine <> 'NoAssignedPRID'    
  AND td.CategoryId = @CatELPId   
  and td.starttime >= prs.starttime  
  and td.starttime < prs.endtime  
  then td.downtime --td.ReportDowntime  
  ELSE  0  
  END  
  ) FreshDT,  
  
 sum(  
  case  
  WHEN prs.AgeOfPR <= 1.0   
  AND prs.PaperMachine <> 'NoAssignedPRID'   
  AND td.CategoryId = @CatELPId  
  and td.starttime >= prs.starttime  
  and (td.starttime < prs.endtime or prs.endtime is null)  
  then td.RawRateloss --td.ReportRLDowntime  
  else 0.0  
  end  
  ) FreshRLELPDT,  
  
 SUM(  
  CASE   
  WHEN  prs.AgeOfPR > 1.0   
  AND  prs.PaperMachine <> 'NoAssignedPRID'  
  AND td.CategoryId = @CatELPId   
  AND  td.StopsELP = 1   
  and td.starttime >= prs.starttime  
  and td.starttime < prs.endtime  
  THEN  1  
  ELSE  0  
  END  
  ) StorageStops,  
  
 SUM(  
  CASE   
  WHEN  prs.AgeOfPR > 1.0   
  AND  prs.PaperMachine <> 'NoAssignedPRID'  
  AND td.CategoryId = @CatELPId   
  and td.starttime >= prs.starttime  
  and td.starttime < prs.endtime  
  then td.downtime --td.ReportDowntime  
  ELSE  0  
  END  
  ) StorageDT,  
  
 sum(  
  case  
  WHEN prs.AgeOfPR > 1.0   
  AND prs.PaperMachine <> 'NoAssignedPRID'   
  AND td.CategoryId = @CatELPId  
  and td.starttime >= prs.starttime  
  and (td.starttime < prs.endtime or prs.endtime is null)  
  then td.RawRateloss --td.ReportRLDowntime  
  else 0.0  
  end  
  ) StorageRLELPDT,  
  
 sum(  
  case  
  WHEN COALESCE(td.ScheduleId,0) NOT IN (@SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
    @SchedEOProjectsId, @SchedBlockedStarvedId, 0) --FLD 01-NOV-2007 Rev11.53  
  then   
   datediff (  
      ss,  
      case   
      when td.StartTime <= prs.StartTime  
      and td.EndTime > prs.StartTime  
      then prs.Starttime  
      when td.StartTime > prs.StartTime  
      and td.StartTime < prs.EndTime  
      then td.StartTime  
      else null  
      end,  
      case   
      when td.StartTime < prs.EndTime  
      and td.EndTime >= prs.EndTime  
      then prs.Endtime  
      when td.EndTime > prs.StartTime  
      and td.EndTime < prs.EndTime  
      then td.EndTime  
      else null  
      end  
      )   
  else 0.0  
  end  
  ) ELPSchedDT,  
  
 SUM(  
  CASE   
  WHEN COALESCE(td.ScheduleId,0) NOT IN (@SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
    @SchedEOProjectsId, @SchedBlockedStarvedId, 0) --FLD 01-NOV-2007 Rev11.53  
  AND prs.AgeOfPR <= 1.0   
  AND prs.PaperMachine <> 'NoAssignedPRID'  
  then   
   datediff (  
      ss,  
      case   
      when td.StartTime <= prs.StartTime  
      and td.EndTime > prs.StartTime  
      then prs.Starttime  
      when td.StartTime > prs.StartTime  
      and td.StartTime < prs.EndTime  
      then td.StartTime  
      else null  
      end,  
      case   
      when td.StartTime < prs.EndTime  
      and td.EndTime >= prs.EndTime  
      then prs.Endtime  
      when td.EndTime > prs.StartTime  
      and td.EndTime < prs.EndTime  
      then td.EndTime  
      else null  
      end  
      )   
  ELSE 0  
  END  
  ) FreshSchedDT,  
  
 SUM(  
  CASE   
  WHEN COALESCE(td.ScheduleId,0) NOT IN (@SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
    @SchedEOProjectsId, @SchedBlockedStarvedId, 0) --FLD 01-NOV-2007 Rev11.53  
  AND prs.AgeOfPR > 1.0   
  AND prs.PaperMachine <> 'NoAssignedPRID'  
  then   
   datediff (  
      ss,  
      case   
      when td.StartTime <= prs.StartTime  
      and td.EndTime > prs.StartTime  
      then prs.Starttime  
      when td.StartTime > prs.StartTime  
      and td.StartTime < prs.EndTime  
      then td.StartTime  
      else null  
      end,  
      case   
      when td.StartTime < prs.EndTime  
      and td.EndTime >= prs.EndTime  
      then prs.Endtime  
      when td.EndTime > prs.StartTime  
      and td.EndTime < prs.EndTime  
      then td.EndTime  
      else null  
      end  
      )   
  ELSE 0  
  END  
  ) StorageSchedDT,  
  
 SUM(  
  CASE   
  when td.CategoryId = @CatELPId  
  and td.StopsELP = 1  
  and td.starttime >= prs.StartTimeLinePS  
  and (td.starttime < prs.EndTimeLinePS or prs.EndTimeLinePS is null)  
  THEN 1   
  ELSE 0   
  END  
  ) ELPStopsLinePS,  
  
 sum(  
  case  
  WHEN tpu.DelayType <> @DelayTypeRateLossStr  
  AND td.CategoryId = @CatELPId  
  and td.starttime >= prs.StartTimeLinePS  
  and (td.starttime < prs.EndTimeLinePS or prs.EndTimeLinePS is null)  
  then td.downtime --ReportELPDowntime   
  else 0.0  
  end  
  ) ELPDTLinePS,  
  
 sum(  
  case  
  when td.CategoryId = @CatELPId  
  and td.starttime >= prs.StartTimeLinePS  
  and (td.starttime < prs.EndTimeLinePS or prs.EndTimeLinePS is null)  
  then td.RawRateloss --td.ReportRLDowntime  
  else 0.0  
  end   
  ) RLELPDTLinePS,  
  
 SUM(  
  CASE   
  WHEN  prs.AgeOfPR <= 1.0   
  AND  prs.PaperMachine <> 'NoAssignedPRID'   
  AND td.CategoryId = @CatELPId   
  AND  td.StopsELP = 1   
  and td.starttime >= prs.StartTimeLinePSFresh  
  and td.starttime < prs.EndTimeLinePSFresh  
  THEN  1  
  ELSE  0  
  END  
  ) FreshStopsLinePS,  
  
 SUM(  
  CASE   
  WHEN  prs.AgeOfPR <= 1.0   
  AND  prs.PaperMachine <> 'NoAssignedPRID'    
  AND td.CategoryId = @CatELPId   
  and td.starttime >= prs.StartTimeLinePSFresh  
  and td.starttime < prs.EndTimeLinePSFresh  
  then td.downtime --td.ReportDowntime  
  ELSE  0  
  END  
  ) EffFreshDTLinePS,  
  
 sum(  
  case  
  WHEN prs.AgeOfPR <= 1.0   
  AND prs.PaperMachine <> 'NoAssignedPRID'   
  AND td.CategoryId = @CatELPId  
  and td.starttime >= prs.StartTimeLinePSFresh  
  and (td.starttime < prs.EndTimeLinePSFresh or prs.EndTimeLinePSFresh is null)  
  then td.RawRateloss --td.ReportRLDowntime  
  else 0.0  
  end  
  ) FreshRLELPDTLinePS,  
  
 SUM(  
  CASE   
  WHEN  prs.AgeOfPR > 1.0   
  AND  prs.PaperMachine <> 'NoAssignedPRID'  
  AND td.CategoryId = @CatELPId   
  AND  td.StopsELP = 1   
  and td.starttime >= prs.StartTimeLinePSFresh  
  and td.starttime < prs.EndTimeLinePSFresh  
  THEN  1  
  ELSE  0  
  END  
  ) StorageStopsLinePS,  
  
 SUM(  
  CASE   
  WHEN  prs.AgeOfPR > 1.0   
  AND  prs.PaperMachine <> 'NoAssignedPRID'  
  AND td.CategoryId = @CatELPId   
  and td.starttime >= prs.StartTimeLinePSFresh  
  and td.starttime < prs.EndTimeLinePSFresh  
  then td.downtime --td.ReportDowntime  
  ELSE  0  
  END  
  ) StorageDTLinePS,  
  
 sum(  
  case  
  WHEN prs.AgeOfPR > 1.0   
  AND prs.PaperMachine <> 'NoAssignedPRID'   
  AND td.CategoryId = @CatELPId  
  and td.starttime >= prs.StartTimeLinePSFresh  
  and (td.starttime < prs.EndTimeLinePSFresh or prs.EndTimeLinePSFresh is null)  
  then td.RawRateloss --td.ReportRLDowntime  
  else 0.0  
  end  
  ) StorageRLELPDTLinePS,  
  
 sum(  
  case  
  WHEN COALESCE(td.ScheduleId,0) NOT IN (@SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
    @SchedEOProjectsId, @SchedBlockedStarvedId, 0) --FLD 01-NOV-2007 Rev11.53  
  then   
   datediff (  
      ss,  
      case   
      when td.StartTime <= prs.StartTimeLinePS  
      and td.EndTime > prs.StartTimeLinePS  
      then prs.StarttimeLinePS  
      when td.StartTime > prs.StartTimeLinePS  
      and td.StartTime < prs.EndTimeLinePS  
      then td.StartTime  
      else null  
      end,  
      case   
      when td.StartTime < prs.EndTimeLinePS  
      and td.EndTime >= prs.EndTimeLinePS  
      then prs.EndtimeLinePS  
      when td.EndTime > prs.StartTimeLinePS  
      and td.EndTime < prs.EndTimeLinePS  
      then td.EndTime  
      else null  
      end  
      )   
  else 0.0  
  end  
  ) ELPSchedDTLinePS,  
  
 SUM(  
  CASE   
  WHEN COALESCE(td.ScheduleId,0) NOT IN (@SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
    @SchedEOProjectsId, @SchedBlockedStarvedId, 0) --FLD 01-NOV-2007 Rev11.53  
  AND prs.AgeOfPR <= 1.0   
  AND prs.PaperMachine <> 'NoAssignedPRID'  
  then   
   datediff (  
      ss,  
      case   
      when td.StartTime <= prs.StartTimeLinePSFresh  
      and td.EndTime > prs.StartTimeLinePSFresh  
      then prs.StarttimeLinePSFresh  
      when td.StartTime > prs.StartTimeLinePSFresh  
      and td.StartTime < prs.EndTimeLinePSFresh  
      then td.StartTime  
      else null  
      end,  
      case   
      when td.StartTime < prs.EndTimeLinePSFresh  
      and td.EndTime >= prs.EndTimeLinePSFresh  
      then prs.EndtimeLinePSFresh  
      when td.EndTime > prs.StartTimeLinePSFresh  
      and td.EndTime < prs.EndTimeLinePSFresh  
      then td.EndTime  
      else null  
      end  
      )   
  ELSE 0  
  END  
  ) FreshSchedDTLinePS,  
  
 SUM(  
  CASE   
  WHEN COALESCE(td.ScheduleId,0) NOT IN (@SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
    @SchedEOProjectsId, @SchedBlockedStarvedId, 0) --FLD 01-NOV-2007 Rev11.53  
  AND prs.AgeOfPR > 1.0 --prs.AgeOfPR > 1.0  
  AND prs.PaperMachine <> 'NoAssignedPRID'  
  then   
   datediff (  
      ss,  
      case   
      when td.StartTime <= prs.StartTimeLinePSFresh  
      and td.EndTime > prs.StartTimeLinePSFresh  
      then prs.StarttimeLinePSFresh  
      when td.StartTime > prs.StartTimeLinePSFresh  
      and td.StartTime < prs.EndTimeLinePSFresh  
      then td.StartTime  
      else null  
      end,  
      case   
      when td.StartTime < prs.EndTimeLinePSFresh  
      and td.EndTime >= prs.EndTimeLinePSFresh  
      then prs.EndtimeLinePSFresh  
      when td.EndTime > prs.StartTimeLinePSFresh  
      and td.EndTime < prs.EndTimeLinePSFresh  
      then td.EndTime  
      else null  
      end  
      )   
  ELSE 0  
  END  
  ) StorageSchedDTLinePS,  
  
 SUM(  
  CASE   
  when  td.CategoryId = @CatELPId  
  and td.starttime >= prs.StartTimeLine  
  and (td.starttime < prs.EndTimeLine or prs.EndTimeLine is null)  
  and  td.StopsELP = 1  
  THEN  1   
  ELSE  0   
   END  
  ) ELPStopsLine,  
  
 sum(  
  case  
  WHEN tpu.DelayType <> @DelayTypeRateLossStr  
  AND td.CategoryId = @CatELPId  
  and td.starttime >= prs.StartTimeLine  
  and (td.starttime < prs.EndTimeLine or prs.EndTimeLine is null)  
  then td.downtime --td.ReportELPDowntime   
  else 0.0  
  end  
  ) ELPDTLine,  
  
 sum(  
  case  
  when td.CategoryId = @CatELPId  
  and td.starttime >= prs.StartTimeLine  
  and (td.starttime < prs.EndTimeLine or prs.EndTimeLine is null)  
  then td.RawRateloss --td.ReportRLDowntime  
  else 0.0  
  end   
  ) RLELPDTLine,  
  
 SUM(  
  CASE   
  WHEN  prs.AgeOfPR <= 1.0   
  AND  prs.PaperMachine <> 'NoAssignedPRID'   
  AND td.CategoryId = @CatELPId   
  AND  td.StopsELP = 1   
  and td.starttime >= prs.StartTimeLineFresh  
  and td.starttime < prs.EndTimeLineFresh  
  THEN  1  
  ELSE  0  
  END  
  ) FreshStopsLine,  
  
 SUM(  
  CASE   
  WHEN  prs.AgeOfPR <= 1.0   
  AND  prs.PaperMachine <> 'NoAssignedPRID'    
  AND td.CategoryId = @CatELPId   
  and td.starttime >= prs.StartTimeLineFresh  
  and td.starttime < prs.EndTimeLineFresh  
  then td.downtime --td.ReportDowntime  
  ELSE  0  
  END  
  ) FreshDTLine,  
  
 sum(  
  case  
  WHEN prs.AgeOfPR <= 1.0   
  AND prs.PaperMachine <> 'NoAssignedPRID'   
  AND td.CategoryId = @CatELPId  
  and td.starttime >= prs.StartTimeLineFresh  
  and (td.starttime < prs.EndTimeLineFresh or prs.EndTimeLineFresh is null)  
  then td.RawRateloss --td.ReportRLDowntime  
  else 0.0  
  end  
  ) FreshRLELPDTLine,  
  
 SUM(  
  CASE   
  WHEN  prs.AgeOfPR > 1.0   
  AND  prs.PaperMachine <> 'NoAssignedPRID'  
  AND td.CategoryId = @CatELPId   
  AND  td.StopsELP = 1   
  and td.starttime >= prs.StartTimeLineFresh  
  and td.starttime < prs.EndTimeLineFresh  
  THEN  1  
  ELSE  0  
  END  
  ) StorageStopsLine,  
  
 SUM(  
  CASE   
  WHEN  prs.AgeOfPR > 1.0   
  AND  prs.PaperMachine <> 'NoAssignedPRID'  
  AND td.CategoryId = @CatELPId   
  and td.starttime >= prs.StartTimeLineFresh  
  and td.starttime < prs.EndTimeLineFresh  
  then td.downtime --td.ReportDowntime  
  ELSE  0  
  END  
  ) StorageDTLine,  
  
 sum(  
  case  
  WHEN prs.AgeOfPR > 1.0   
  AND prs.PaperMachine <> 'NoAssignedPRID'   
  AND td.CategoryId = @CatELPId  
  and td.starttime >= prs.StartTimeLineFresh  
  and (td.starttime < prs.EndTimeLineFresh or prs.EndTimeLineFresh is null)  
  then td.RawRateloss --td.ReportRLDowntime  
  else 0.0  
  end  
  ) StorageRLELPDTLine,  
  
 sum(  
  case  
  WHEN COALESCE(td.ScheduleId,0) NOT IN (@SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
    @SchedEOProjectsId, @SchedBlockedStarvedId, 0) --FLD 01-NOV-2007 Rev11.53  
  then   
   datediff (  
      ss,  
      case   
      when td.StartTime <= prs.StartTimeLine  
      and td.EndTime > prs.StartTimeLine  
      then prs.StarttimeLine  
      when td.StartTime > prs.StartTimeLine  
      and td.StartTime < prs.EndTimeLine  
      then td.StartTime  
      else null  
      end,  
      case   
      when td.StartTime < prs.EndTimeLine  
      and td.EndTime >= prs.EndTimeLine  
      then prs.EndtimeLine  
      when td.EndTime > prs.StartTimeLine  
      and td.EndTime < prs.EndTimeLine  
      then td.EndTime  
      else null  
      end  
      )   
  else 0.0  
  end  
  ) ELPSchedDTLine,  
  
 SUM(  
  CASE   
  WHEN COALESCE(td.ScheduleId,0) NOT IN (@SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
    @SchedEOProjectsId, @SchedBlockedStarvedId, 0) --FLD 01-NOV-2007 Rev11.53  
  AND prs.AgeOfPR <= 1.0   
  AND prs.PaperMachine <> 'NoAssignedPRID'  
  then   
   datediff (  
      ss,  
      case   
      when td.StartTime <= prs.StartTimeLineFresh  
      and td.EndTime > prs.StartTimeLineFresh  
      then prs.StarttimeLineFresh  
      when td.StartTime > prs.StartTimeLineFresh  
      and td.StartTime < prs.EndTimeLineFresh  
      then td.StartTime  
      else null  
      end,  
      case   
      when td.StartTime < prs.EndTimeLineFresh  
      and td.EndTime >= prs.EndTimeLineFresh  
      then prs.EndtimeLineFresh  
      when td.EndTime > prs.StartTimeLineFresh  
      and td.EndTime < prs.EndTimeLineFresh  
      then td.EndTime  
      else null  
      end  
      )   
  ELSE 0  
  END  
  ) FreshSchedDTLine,  
  
 SUM(  
  CASE   
  WHEN COALESCE(td.ScheduleId,0) NOT IN (@SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
    @SchedEOProjectsId, @SchedBlockedStarvedId, 0) --FLD 01-NOV-2007 Rev11.53  
  AND prs.AgeOfPR > 1.0 --prs.AgeOfPR > 1.0  
  AND prs.PaperMachine <> 'NoAssignedPRID'  
  then   
   datediff (  
      ss,  
      case   
      when td.StartTime <= prs.StartTimeLineFresh  
      and td.EndTime > prs.StartTimeLineFresh  
      then prs.StarttimeLineFresh  
      when td.StartTime > prs.StartTimeLineFresh  
      and td.StartTime < prs.EndTimeLineFresh  
      then td.StartTime  
      else null  
      end,  
      case   
      when td.StartTime < prs.EndTimeLineFresh  
      and td.EndTime >= prs.EndTimeLineFresh  
      then prs.EndtimeLineFresh  -- fixed 20091020  
      when td.EndTime > prs.StartTimeLineFresh  
      and td.EndTime < prs.EndTimeLineFresh  
      then td.EndTime  
      else null  
      end  
      )   
  ELSE 0  
  END  
  ) StorageSchedDTLine,  
  
  
 SUM(  
  CASE   
  when  td.CategoryId = @CatELPId  
  and td.starttime >= prs.StartTimeIntrPL  
  and (td.starttime < prs.EndTimeIntrPL or prs.EndTimeIntrPL is null)  
  and  td.StopsELP = 1  
  THEN  1   
  ELSE  0   
  END  
  ) ELPStopsIntrPL,  
  
 sum(  
  case  
  WHEN tpu.DelayType <> @DelayTypeRateLossStr  
  AND td.CategoryId = @CatELPId  
  and td.starttime >= prs.StartTimeIntrPL  
  and (td.starttime < prs.EndTimeIntrPL or prs.EndTimeIntrPL is null)  
  then td.downtime --ReportELPDowntime   
  else 0.0  
  end  
  ) ELPDTIntrPL,  
  
 sum(  
  case  
  when td.CategoryId = @CatELPId  
  and td.starttime >= prs.StartTimeIntrPL  
  and (td.starttime < prs.EndTimeIntrPL or prs.EndTimeIntrPL is null)  
  then td.RawRateloss --td.ReportRLDowntime  
  else 0.0  
  end   
  ) RLELPDTIntrPL,  
  
 SUM(  
  CASE   
  WHEN  prs.AgeOfPR <= 1.0   
  AND  prs.PaperMachine <> 'NoAssignedPRID'   
  AND td.CategoryId = @CatELPId   
  AND  td.StopsELP = 1   
  and td.starttime >= prs.StartTimeIntrPLFresh  
  and td.starttime < prs.EndTimeIntrPLFresh  
  THEN  1  
  ELSE  0  
  END  
  ) FreshStopsIntrPL,  
  
 SUM(  
  CASE   
  WHEN  prs.AgeOfPR <= 1.0   
  AND  prs.PaperMachine <> 'NoAssignedPRID'    
  AND td.CategoryId = @CatELPId   
  and td.starttime >= prs.StartTimeIntrPLFresh  
  and td.starttime < prs.EndTimeIntrPLFresh  
  then td.downtime --td.ReportDowntime  
  ELSE  0  
  END  
  ) FreshDTIntrPL,  
  
 sum(  
  case  
  WHEN prs.AgeOfPR <= 1.0   
  AND  prs.PaperMachine <> 'NoAssignedPRID'   
  AND  td.CategoryId = @CatELPId  
  and td.starttime >= prs.StartTimeIntrPLFresh  
  and (td.starttime < prs.EndTimeIntrPLFresh or prs.EndTimeIntrPLFresh is null)  
  then td.RawRateloss --td.ReportRLDowntime  
  else 0.0  
  end  
  ) FreshRLELPDTIntrPL,  
  
 SUM(  
  CASE   
  WHEN  prs.AgeOfPR > 1.0   
  AND  prs.PaperMachine <> 'NoAssignedPRID'  
  AND td.CategoryId = @CatELPId   
  AND  td.StopsELP = 1   
  and td.starttime >= prs.StartTimeIntrPLFresh  
  and td.starttime < prs.EndTimeIntrPLFresh  
  THEN  1  
  ELSE  0  
  END  
  ) StorageStopsIntrPL,  
  
 SUM(  
  CASE   
  WHEN  prs.AgeOfPR > 1.0   
  AND  prs.PaperMachine <> 'NoAssignedPRID'  
  AND td.CategoryId = @CatELPId   
  and td.starttime >= prs.StartTimeIntrPLFresh  
  and td.starttime < prs.EndTimeIntrPLFresh  
  then td.downtime --td.ReportDowntime  
  ELSE  0  
  END  
  ) StorageDTIntrPL,  
  
 sum(  
  case  
  WHEN prs.AgeOfPR > 1.0   
  AND  prs.PaperMachine <> 'NoAssignedPRID'   
  AND  td.CategoryId = @CatELPId  
  and td.starttime >= prs.StartTimeIntrPLFresh  
  and (td.starttime < prs.EndTimeIntrPLFresh or prs.EndTimeIntrPLFresh is null)  
  then td.RawRateloss --td.ReportRLDowntime  
  else 0.0  
  end  
  ) StorageRLELPDTIntrPL,  
  
 sum(  
  case  
  WHEN COALESCE(td.ScheduleId,0) NOT IN (@SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
    @SchedEOProjectsId, @SchedBlockedStarvedId, 0) --FLD 01-NOV-2007 Rev11.53  
  then   
   datediff (  
      ss,  
      case   
      when td.StartTime <= prs.StartTimeIntrPL  
      and td.EndTime > prs.StartTimeIntrPL  
      then prs.StarttimeIntrPL  
      when td.StartTime > prs.StartTimeIntrPL  
      and td.StartTime < prs.EndTimeIntrPL  
      then td.StartTime  
      else null  
      end,  
      case   
      when td.StartTime < prs.EndTimeIntrPL  
      and td.EndTime >= prs.EndTimeIntrPL  
      then prs.EndtimeIntrPL  
      when td.EndTime > prs.StartTimeIntrPL  
      and td.EndTime < prs.EndTimeIntrPL  
      then td.EndTime  
      else null  
      end  
      )   
  else 0.0  
  end  
  ) ELPSchedDTIntrPL,  
  
 SUM(  
  CASE   
  WHEN COALESCE(td.ScheduleId,0) NOT IN (@SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
    @SchedEOProjectsId, @SchedBlockedStarvedId, 0) --FLD 01-NOV-2007 Rev11.53  
  AND prs.AgeOfPR <= 1.0   
  AND prs.PaperMachine <> 'NoAssignedPRID'  
  then   
   datediff (  
      ss,  
      case   
      when td.StartTime <= prs.StartTimeIntrPLFresh  
      and td.EndTime > prs.StartTimeIntrPLFresh  
      then prs.StarttimeIntrPLFresh  
      when td.StartTime > prs.StartTimeIntrPLFresh  
      and td.StartTime < prs.EndTimeIntrPLFresh  
      then td.StartTime  
      else null  
      end,  
      case   
      when td.StartTime < prs.EndTimeIntrPLFresh  
      and td.EndTime >= prs.EndTimeIntrPLFresh  
      then prs.EndtimeIntrPLFresh  
      when td.EndTime > prs.StartTimeIntrPLFresh  
      and td.EndTime < prs.EndTimeIntrPLFresh  
      then td.EndTime  
      else null  
      end  
      )   
  ELSE 0  
  END  
  ) FreshSchedDTIntrPL,  
  
 SUM(  
  CASE   
  WHEN COALESCE(td.ScheduleId,0) NOT IN (@SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
    @SchedEOProjectsId, @SchedBlockedStarvedId, 0) --FLD 01-NOV-2007 Rev11.53  
  AND prs.AgeOfPR > 1.0   
  AND prs.PaperMachine <> 'NoAssignedPRID'  
  then   
   datediff (  
      ss,  
      case   
      when td.StartTime <= prs.StartTimeIntrPLFresh  
      and td.EndTime > prs.StartTimeIntrPLFresh  
      then prs.StarttimeIntrPLFresh  
      when td.StartTime > prs.StartTimeIntrPLFresh  
      and td.StartTime < prs.EndTimeIntrPLFresh  
      then td.StartTime  
      else null  
      end,  
      case   
      when td.StartTime < prs.EndTimeIntrPLFresh  
      and td.EndTime >= prs.EndTimeIntrPLFresh  
      then prs.EndtimeIntrPLFresh  
      when td.EndTime > prs.StartTimeIntrPLFresh  
      and td.EndTime < prs.EndTimeIntrPLFresh  
      then td.EndTime  
      else null  
      end  
      )   
  ELSE 0  
  END  
  ) StorageSchedDTIntrPL,  
  
 SUM(  
  CASE   
  when td.CategoryId = @CatELPId  
  and td.starttime >= prs.StartTimePMRunBy  
  and (td.starttime < prs.EndTimePMRunBy or prs.EndTimePMRunBy is null)  
  and prs.PaperMachine <> 'NoAssignedPRID'  
  and td.StopsELP = 1  
  THEN  1   
  ELSE  0   
  END  
  ) ELPStopsPMRunBy,  
  
 sum(  
  case  
  WHEN tpu.DelayType <> @DelayTypeRateLossStr  
  AND td.CategoryId = @CatELPId  
  and td.starttime >= prs.StartTimePMRunBy  
  and (td.starttime < prs.EndTimePMRunBy or prs.EndTimePMRunBy is null)  
  and prs.PaperMachine <> 'NoAssignedPRID'  
  then td.downtime --ReportELPDowntime    
  else 0.0  
  end  
  ) ELPDTPMRunBy,  
  
 sum(  
  case  
  when td.CategoryId = @CatELPId  
  and td.starttime >= prs.StartTimePMRunBy  
  and (td.starttime < prs.EndTimePMRunBy or prs.EndTimePMRunBy is null)  
  and prs.PaperMachine <> 'NoAssignedPRID'  
  then td.RawRateloss --td.ReportRLDowntime  
  else 0.0  
  end   
  ) RLELPDTPMRunBy,  
  
 SUM(  
  CASE   
  WHEN  prs.AgeOfPR <= 1.0   
  AND  prs.PaperMachine <> 'NoAssignedPRID'   
  AND td.CategoryId = @CatELPId   
  AND  td.StopsELP = 1   
  and td.starttime >= prs.StartTimePMRunByFresh  
  and td.starttime < prs.EndTimePMRunByFresh  
  THEN  1  
  ELSE  0  
  END  
  ) FreshStopsPMRunBy,  
  
 SUM(  
  CASE   
  WHEN  prs.AgeOfPR <= 1.0   
  AND  prs.PaperMachine <> 'NoAssignedPRID'    
  AND td.CategoryId = @CatELPId   
  and td.starttime >= prs.StartTimePMRunByFresh  
  and td.starttime < prs.EndTimePMRunByFresh  
  then td.downtime --td.ReportDowntime  
  ELSE  0  
  END  
  ) FreshDTPMRunBy,  
  
 sum(  
  case  
  WHEN prs.AgeOfPR <= 1.0   
  AND prs.PaperMachine <> 'NoAssignedPRID'   
  AND td.CategoryId = @CatELPId  
  and td.starttime >= prs.StartTimePMRunByFresh  
  and (td.starttime < prs.EndTimePMRunByFresh or prs.EndTimePMRunByFresh is null)  
  then td.RawRateloss --td.ReportRLDowntime  
  else 0.0  
  end  
  ) FreshRLELPDTPMRunBy,  
  
 SUM(  
  CASE   
  WHEN  prs.AgeOfPR > 1.0   
  AND  prs.PaperMachine <> 'NoAssignedPRID'  
  AND td.CategoryId = @CatELPId   
  AND  td.StopsELP = 1   
  and td.starttime >= prs.StartTimePMRunByFresh  
  and td.starttime < prs.EndTimePMRunByFresh  
  THEN  1  
  ELSE  0  
  END  
  ) StorageStopsPMRunBy,  
  
 SUM(  
  CASE   
  WHEN  prs.AgeOfPR > 1.0   
  AND  prs.PaperMachine <> 'NoAssignedPRID'  
  AND td.CategoryId = @CatELPId   
  and td.starttime >= prs.StartTimePMRunByFresh  
  and td.starttime < prs.EndTimePMRunByFresh  
  then td.downtime --td.ReportDowntime  
  ELSE  0  
  END  
  ) StorageDTPMRunBy,  
  
 sum(  
  case  
  WHEN prs.AgeOfPR > 1.0   
  AND prs.PaperMachine <> 'NoAssignedPRID'   
  AND td.CategoryId = @CatELPId  
  and td.starttime >= prs.StartTimePMRunByFresh  
  and (td.starttime < prs.EndTimePMRunByFresh or prs.EndTimePMRunByFresh is null)  
  then td.RawRateloss --td.ReportRLDowntime  
  else 0.0  
  end  
  ) StorageRLELPDTPMRunBy,  
  
 sum(  
  case  
  WHEN COALESCE(td.ScheduleId,0) NOT IN (@SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
    @SchedEOProjectsId, @SchedBlockedStarvedId, 0) --FLD 01-NOV-2007 Rev11.53  
    and prs.PaperMachine <> 'NoAssignedPRID'  
  then   
   datediff (  
      ss,  
      case   
      when td.StartTime <= prs.StartTimePMRunBy  
      and td.EndTime > prs.StartTimePMRunBy  
      then prs.StarttimePMRunBy  
      when td.StartTime > prs.StartTimePMRunBy  
      and td.StartTime < prs.EndTimePMRunBy  
      then td.StartTime  
      else null  
      end,  
      case   
      when td.StartTime < prs.EndTimePMRunBy  
      and td.EndTime >= prs.EndTimePMRunBy  
      then prs.EndtimePMRunBy  
      when td.EndTime > prs.StartTimePMRunBy  
      and td.EndTime < prs.EndTimePMRunBy  
      then td.EndTime  
      else null  
      end  
      )   
  else 0.0  
  end  
  ) ELPSchedDTPMRunBy,  
  
 SUM(  
  CASE   
  WHEN COALESCE(td.ScheduleId,0) NOT IN (@SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
    @SchedEOProjectsId, @SchedBlockedStarvedId, 0) --FLD 01-NOV-2007 Rev11.53  
  AND prs.AgeOfPR <= 1.0   
  AND prs.PaperMachine <> 'NoAssignedPRID'  
  then   
   datediff (  
      ss,  
      case   
      when td.StartTime <= prs.StartTimePMRunByFresh  
      and td.EndTime > prs.StartTimePMRunByFresh  
      then prs.StarttimePMRunByFresh  
      when td.StartTime > prs.StartTimePMRunByFresh  
      and td.StartTime < prs.EndTimePMRunByFresh  
      then td.StartTime  
      else null  
      end,  
      case   
      when td.StartTime < prs.EndTimePMRunByFresh  
      and td.EndTime >= prs.EndTimePMRunByFresh  
      then prs.EndtimePMRunByFresh  
      when td.EndTime > prs.StartTimePMRunByFresh  
      and td.EndTime < prs.EndTimePMRunByFresh  
      then td.EndTime  
      else null  
      end  
      )   
  ELSE 0  
  END  
  ) FreshSchedDTPMRunBy,  
  
 SUM(  
  CASE   
  WHEN COALESCE(td.ScheduleId,0) NOT IN (@SchedSpecialCausesId, @SchedUnscheduledId, @SchedPRPolyId,   
    @SchedEOProjectsId, @SchedBlockedStarvedId, 0) --FLD 01-NOV-2007 Rev11.53  
  AND prs.AgeOfPR > 1.0 --prs.AgeOfPR > 1.0  
  AND prs.PaperMachine <> 'NoAssignedPRID'  
  then   
   datediff (  
      ss,  
      case   
      when td.StartTime <= prs.StartTimePMRunByFresh  
      and td.EndTime > prs.StartTimePMRunByFresh  
      then prs.StarttimePMRunByFresh  
      when td.StartTime > prs.StartTimePMRunByFresh  
      and td.StartTime < prs.EndTimePMRunByFresh  
      then td.StartTime  
      else null  
      end,  
      case   
      when td.StartTime < prs.EndTimePMRunByFresh  
      and td.EndTime >= prs.EndTimePMRunByFresh  
      then prs.EndtimePMRunByFresh  
      when td.EndTime > prs.StartTimePMRunByFresh  
      and td.EndTime < prs.EndTimePMRunByFresh  
      then td.EndTime  
      else null  
      end  
      )     ELSE 0  
  END  
  ) StorageSchedDTPMRunBy  
  
FROM dbo.#prsrun prs   
join @prodlines pl  
on prs.puid = pl.prodpuid  
left join dbo.#delays td  
on (pl.reliabilitypuid = td.puid or pl.ratelosspuid = td.puid)  
and (td.starttime < prs.endtime)   
and (td.endtime > prs.starttime)   
left JOIN @ProdUnits tpu   
ON td.PUId = tpu.PUId  
-----------  
-- testing  
--where td.CategoryId = @CatELPId or td.tedetid is null  
-----------  
group by prs.id_num   
  
--Rev7.6  
update prs set  
  
 Runtime =   
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
    ),   
  
 RunTimeLinePS =  
  DATEDIFF(ss,    
     CASE   
     WHEN StartTimeLinePS < @StartTime   
     THEN @StartTime   
     ELSE StartTimeLinePS  
     END,  
     CASE   
     WHEN EndTimeLinePS > @EndTime   
     THEN @EndTime   
     ELSE EndTimeLinePS  
     END  
    ),   
  
 RunTimeLinePSFresh =  
  DATEDIFF(ss,    
     CASE   
     WHEN StartTimeLinePSFresh < @StartTime   
     THEN @StartTime   
     ELSE StartTimeLinePSFresh  
     END,  
     CASE   
     WHEN EndTimeLinePSFresh > @EndTime   
     THEN @EndTime   
     ELSE EndTimeLinePSFresh  
     END  
    ),   
  
 RunTimeLine =  
  DATEDIFF(ss,    
     CASE   
     WHEN StartTimeLine < @StartTime   
     THEN @StartTime   
     ELSE StartTimeLine  
     END,  
     CASE   
     WHEN EndTimeLine > @EndTime   
     THEN @EndTime   
     ELSE EndTimeLine  
     END  
    ),   
  
 RunTimeLineFresh =  
  DATEDIFF(ss,    
     CASE   
     WHEN StartTimeLineFresh < @StartTime   
     THEN @StartTime   
     ELSE StartTimeLineFresh  
     END,  
     CASE   
     WHEN EndTimeLineFresh > @EndTime   
     THEN @EndTime   
     ELSE EndTimeLineFresh  
     END  
    ),   
  
 RunTimeIntrPL =  
  DATEDIFF(ss,    
     CASE   
     WHEN StartTimeIntrPL < @StartTime   
     THEN @StartTime   
     ELSE StartTimeIntrPL  
     END,  
     CASE   
     WHEN EndTimeIntrPL > @EndTime   
     THEN @EndTime   
     ELSE EndTimeIntrPL  
     END  
    ),   
  
 RunTimeIntrPLFresh =  
  DATEDIFF(ss,    
     CASE   
     WHEN StartTimeIntrPLFresh < @StartTime   
     THEN @StartTime   
     ELSE StartTimeIntrPLFresh  
     END,  
     CASE   
     WHEN EndTimeIntrPLFresh > @EndTime   
     THEN @EndTime   
     ELSE EndTimeIntrPLFresh  
     END  
    ),   
  
 RunTimePMRunBy =  
  case  
  when prs.PaperMachine <> 'NoAssignedPRID'  
  then  
  DATEDIFF(ss,    
     CASE   
     WHEN StartTimePMRunBy < @StartTime   
     THEN @StartTime   
     ELSE StartTimePMRunBy  
     END,  
     CASE   
     WHEN EndTimePMRunBy > @EndTime   
     THEN @EndTime   
     ELSE EndTimePMRunBy  
     END  
    )  
  else null  
  end,   
  
 RunTimePMRunByFresh =  
  case  
  when prs.PaperMachine <> 'NoAssignedPRID'  
  then  
  DATEDIFF(ss,    
     CASE   
     WHEN StartTimePMRunByFresh < @StartTime   
     THEN @StartTime   
     ELSE StartTimePMRunByFresh  
     END,  
     CASE   
     WHEN EndTimePMRunByFresh > @EndTime   
     THEN @EndTime   
     ELSE EndTimePMRunByFresh  
     END  
    )  
  else null  
  end,   
  
  
 ELPStops = pdm.ELPStops,  
 ELPDT = pdm.ELPDT,  
 RLELPDT = pdm.RLELPDT,  
 FreshStops = pdm.FreshStops,  
 FreshDT = pdm.FreshDT,  
 FreshRLELPDT = pdm.FreshRLELPDT,    
 StorageStops = pdm.StorageStops,   
 StorageDT = pdm.StorageDT,  
 StorageRLELPDT = pdm.StorageRLELPDT,  
 ELPSchedDT = pdm.ELPSchedDT,  
 FreshSchedDT = pdm.FreshSchedDT,  
 StorageSchedDT = pdm.StorageSchedDT  
  
from dbo.#prsrun prs  
join @prdtmetrics pdm  
on prs.id_num = pdm.id_num  
  
--Rev7.6  
update prs set  
  
 PaperRuntime = Runtime - ELPSchedDT,  
 FreshRuntime =   
  case  
  when  AgeOfPR <= 1.0  
  then  Runtime  
  else 0.0  
  end,  
 StorageRuntime =  
  case  
  when  AgeOfPR > 1.0  
  then  Runtime  
  else 0.0  
  end,  
  
 FreshRuntimeLinePS =   
  case  
  when  AgeOfPR <= 1.0  
  then  RuntimeLinePSFresh  
  else 0.0  
  end,  
 StorageRuntimeLinePS =  
  case  
  when  AgeOfPR > 1.0  
  then  RuntimeLinePSFresh  
  else 0.0  
  end,  
  
 FreshRuntimeLine =   
  case  
  when  AgeOfPR <= 1.0  
  then  RuntimeLineFresh  
  else 0.0  
  end,  
 StorageRuntimeLine =  
  case  
  when  AgeOfPR > 1.0  
  then  RuntimeLineFresh  
  else 0.0  
  end,  
  
  
 FreshRuntimeIntrPL =   
  case  
  when  AgeOfPR <= 1.0  
  then  RuntimeIntrPLFresh  
  else 0.0  
  end,  
 StorageRuntimeIntrPL =  
  case  
  when  AgeOfPR > 1.0  
  then  RuntimeIntrPLFresh  
  else 0.0  
  end,  
  
 FreshRuntimePMRunBy =   
  case  
  when  AgeOfPR <= 1.0  
  then  RuntimePMRunByFresh  
  else 0.0  
  end,  
 StorageRuntimePMRunBy =  
  case  
  when  AgeOfPR > 1.0  
  then  RuntimePMRunByFresh  
  else 0.0  
  end,  
  
 TotalRolls =   
  case  
  when  COALESCE(GrandParentPRID, ParentPRID) is not null  
  then  1  
  else 0  
  end,  
 FreshRolls =   
  case  
  when  AgeOfPR <= 1.0  
  and  prs.PaperMachine <> 'NoAssignedPRID'  
  and COALESCE(GrandParentPRID, ParentPRID) is not null  
  then  1  
  else 0  
  end,  
 StorageRolls =   
  case  
  when  AgeOfPR > 1.0  
  and  prs.PaperMachine <> 'NoAssignedPRID'  
  and COALESCE(GrandParentPRID, ParentPRID) is not null  
  then  1  
  else 0  
  end  
  
from dbo.#prsrun prs  
  
  
--print 'Insert for @PRSummary table: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
--------------------------------------------------------------------------------------------  
--- summarize runtime by Line, PaperSource, PaperRunBy, papermachine, INTR and ParentPLId.  
--------------------------------------------------------------------------------------------  
  
--Rev7.6  
INSERT INTO @PRSummaryUWS  
 (  
 CvtgPLId,   
  PaperSource,   
 PaperRunBy,    
  PaperMachine,  
 INTR,      
 ParentPLId,    
 InputOrder,    
 PEIId,  
 UWS,  
 ELPStops,  
 ELPDowntime,  
 RLELPDowntime,  
 FreshStops,  
 FreshDT,  
 FreshRLELPDT,   
 StorageStops,  
 StorageDT,  
 StorageRLELPDT,  
 ScheduledDT,  
 FreshSchedDT,  
 StorageSchedDT,  
 Runtime,  
 FreshRuntime,  
 StorageRuntime,  
 TotalRolls,   
 FreshRolls,  
 StorageRolls--,  
 )   
SELECT    
 pl.plid, --r.PLId,  
 r.PaperSource,  
 r.PaperRunBy,  
 r.PaperMachine,  
 r.INTR,  
 r.PRPLId,  
 r.Input_Order,  
 r.PEIId,  
 r.UWS,  
 sum(r.ELPStops),  
 sum(r.ELPDT),  
 sum(r.RLELPDT),  
 sum(r.FreshStops),  
 sum(r.FreshDT),  
 sum(r.FreshRLELPDT),   
 sum(r.StorageStops),  
 sum(r.StorageDT),  
 sum(r.StorageRLELPDT),  
 sum(r.ELPSchedDT),   
 sum(r.FreshSchedDT),   
 sum(r.StorageSchedDT),  
  
 sum(r.Runtime),  
 sum(r.FreshRuntime),  
 sum(r.StorageRuntime),  
  
 sum(r.TotalRolls),   
 sum(r.FreshRolls),  
 sum(r.StorageRolls)--,  
from @ProdLines pl   
join dbo.#prsrun r  
ON r.PLId = pl.PLId  
WHERE  r.Runtime IS NOT NULL  
AND (charindex('|' + r.LineStatus + '|', '|' + @LineStatusList + '|') > 0  
OR  @LineStatusList = 'All')  
GROUP BY pl.PLId, r.PEIId, r.uws, r.PaperMachine, r.Input_Order, r.PRPLId, r.PaperSource, r.PaperRunBy, r.INTR, r.LineStatus  
  
--Rev7.6  
INSERT INTO @PRSummaryLinePS   
 (  
 CvtgPLId,   
  PaperSource,   
 ELPStops,  
 ELPDowntime,  
 RLELPDowntime,  
 FreshStops,  
 FreshDT,  
 FreshRLELPDT,   
 StorageStops,  
 StorageDT,  
 StorageRLELPDT,  
 ScheduledDT,  
 FreshSchedDT,  
 StorageSchedDT,  
 Runtime,  
 FreshRuntime,  
 StorageRuntime,  
 TotalRolls,   
 FreshRolls,  
 StorageRolls--,  
 )   
SELECT    
 pl.plid, --r.PLId,  
 r.PaperSource,  
 sum(pdm.ELPStopsLinePS),  
 sum(pdm.ELPDTLinePS),  
 sum(pdm.RLELPDTLinePS),  
 sum(pdm.FreshStopsLinePS),  
 sum(pdm.FreshDTLinePS),  
 sum(pdm.FreshRLELPDTLinePS),   
 sum(pdm.StorageStopsLinePS),  
 sum(pdm.StorageDTLinePS),  
 sum(pdm.StorageRLELPDTLinePS),  
 sum(pdm.ELPSchedDTLinePS),   
 sum(pdm.FreshSchedDTLinePS),   
 sum(pdm.StorageSchedDTLinePS),  
  
 sum(r.RuntimeLinePS),  
 sum(r.FreshRuntimeLinePS),  
 sum(r.StorageRuntimeLinePS),  
  
 sum(r.TotalRolls),   
 sum(r.FreshRolls),  
 sum(r.StorageRolls)--,  
from @ProdLines pl   
join dbo.#prsrun r  
ON r.PLId = pl.PLId  
join @prdtmetrics pdm  
on r.id_num = pdm.id_num  
WHERE r.RuntimeLinePS IS NOT NULL  
AND (charindex('|' + r.LineStatus + '|', '|' + @LineStatusList + '|') > 0  
OR @LineStatusList = 'All')  
GROUP BY pl.PLId, r.PaperSource  
  
--Rev7.6  
INSERT INTO @PRSummaryLine  
 (  
 CvtgPLId,   
 ELPStops,  
 ELPDowntime,  
 RLELPDowntime,  
 FreshStops,  
 FreshDT,  
 FreshRLELPDT,   
 StorageStops,  
 StorageDT,  
 StorageRLELPDT,  
 ScheduledDT,  
 FreshSchedDT,  
 StorageSchedDT,  
 Runtime,  
 FreshRuntime,  
 StorageRuntime,  
 TotalRolls,   
 FreshRolls,  
 StorageRolls--,  
 )   
SELECT    
 pl.plid, --r.PLId,  
 sum(pdm.ELPStopsLine),  
 sum(pdm.ELPDTLine),  
 sum(pdm.RLELPDTLine),  
 sum(pdm.FreshStopsLine),  
 sum(pdm.FreshDTLine),  
 sum(pdm.FreshRLELPDTLine),   
 sum(pdm.StorageStopsLine),  
 sum(pdm.StorageDTLine),  
 sum(pdm.StorageRLELPDTLine),  
 sum(pdm.ELPSchedDTLine),   
 sum(pdm.FreshSchedDTLine),   
 sum(pdm.StorageSchedDTLine),  
  
 sum(r.RuntimeLine),  
 sum(r.FreshRuntimeLine),  
 sum(r.StorageRuntimeLine),  
  
 sum(r.TotalRolls),   
 sum(r.FreshRolls),  
 sum(r.StorageRolls)--,  
from @ProdLines pl   
join dbo.#prsrun r  
ON r.PLId = pl.PLId  
join @prdtmetrics pdm  
on r.id_num = pdm.id_num  
WHERE r.RuntimeLine IS NOT NULL   
AND (charindex('|' + r.LineStatus + '|', '|' + @LineStatusList + '|') > 0  
OR @LineStatusList = 'All')  
GROUP BY pl.plid --r.PLId  
  
  
--Rev7.6  
INSERT INTO @PRSummaryIntrPL  
 (  
 INTR,  
 PaperRunBy,      
 ELPStops,  
 ELPDowntime,  
 RLELPDowntime,  
 FreshStops,  
 FreshDT,  
 FreshRLELPDT,   
 StorageStops,  
 StorageDT,  
 StorageRLELPDT,  
 ScheduledDT,  
 FreshSchedDT,  
 StorageSchedDT,  
 Runtime,  
 FreshRuntime,  
 StorageRuntime,  
 TotalRolls,   
 FreshRolls,  
 StorageRolls--,  
 )   
SELECT    
 r.INTR,  
 r.PaperRunBy,  
 sum(pdm.ELPStopsIntrPL),  
 sum(pdm.ELPDTIntrPL),  
 sum(pdm.RLELPDTIntrPL),  
 sum(pdm.FreshStopsIntrPL),  
 sum(pdm.FreshDTIntrPL),  
 sum(pdm.FreshRLELPDTIntrPL),   
 sum(pdm.StorageStopsIntrPL),  
 sum(pdm.StorageDTIntrPL),  
 sum(pdm.StorageRLELPDTIntrPL),  
 sum(pdm.ELPSchedDTIntrPL),   
 sum(pdm.FreshSchedDTIntrPL),   
 sum(pdm.StorageSchedDTIntrPL),  
  
 sum(r.RuntimeIntrPL),  
 sum(r.FreshRuntimeIntrPL),  
 sum(r.StorageRuntimeIntrPL),  
  
 sum(r.TotalRolls),   
 sum(r.FreshRolls),  
 sum(r.StorageRolls)--,  
from @ProdLines pl   
 join dbo.#prsrun r  
ON r.PLId = pl.PLId  
 join @prdtmetrics pdm  
on r.id_num = pdm.id_num  
WHERE r.RuntimeIntrPL IS NOT NULL  
AND (charindex('|' + r.LineStatus + '|', '|' + @LineStatusList + '|') > 0  
OR @LineStatusList = 'All')  
and r.intr is not null  
GROUP BY r.Intr, r.PaperRunBy  
  
--Rev7.6  
INSERT INTO @PRSummaryIntr  
 (  
 INTR,      
 ELPStops,  
 ELPDowntime,  
 RLELPDowntime,  
 FreshStops,  
 FreshDT,  
 FreshRLELPDT,   
 StorageStops,  
 StorageDT,  
 StorageRLELPDT,  
 ScheduledDT,  
 FreshSchedDT,  
 StorageSchedDT,  
 Runtime,  
 FreshRuntime,  
 StorageRuntime,  
 TotalRolls,   
 FreshRolls,  
 StorageRolls--,  
 )   
SELECT    
 INTR,  
 sum(ELPStops),  
 sum(ELPDowntime),  
 sum(RLELPDowntime),  
 sum(FreshStops),  
 sum(FreshDT),  
 sum(FreshRLELPDT),   
 sum(StorageStops),  
 sum(StorageDT),  
 sum(StorageRLELPDT),  
 sum(ScheduledDT),   
 sum(FreshSchedDT),   
 sum(StorageSchedDT),  
 sum(Runtime),  
 sum(FreshRuntime),  
 sum(StorageRuntime),  
 sum(TotalRolls),   
 sum(FreshRolls),  
 sum(StorageRolls)--,  
from @PRSummaryIntrPL  
GROUP BY Intr  
  
--Rev7.6  
INSERT INTO @PRSummaryPMRunBy  
 (  
 PaperRunBy,    
  PaperMachine,  
 ELPStops,  
 ELPDowntime,  
 RLELPDowntime,  
 FreshStops,  
 FreshDT,  
 FreshRLELPDT,   
 StorageStops,  
 StorageDT,  
 StorageRLELPDT,  
 ScheduledDT,  
 FreshSchedDT,  
 StorageSchedDT,  
 Runtime,  
 FreshRuntime,  
 StorageRuntime,  
 TotalRolls,   
 FreshRolls,  
 StorageRolls--,  
 )   
SELECT    
 r.PaperRunBy,  
 r.PaperMachine,  
 sum(pdm.ELPStopsPMRunBy),  
 sum(pdm.ELPDTPMRunBy),  
 sum(pdm.RLELPDTPMRunBy),  
 sum(pdm.FreshStopsPMRunBy),  
 sum(pdm.FreshDTPMRunBy),  
 sum(pdm.FreshRLELPDTPMRunBy),   
 sum(pdm.StorageStopsPMRunBy),  
 sum(pdm.StorageDTPMRunBy),  
 sum(pdm.StorageRLELPDTPMRunBy),  
 sum(pdm.ELPSchedDTPMRunBy),   
 sum(pdm.FreshSchedDTPMRunBy),   
 sum(pdm.StorageSchedDTPMRunBy),  
  
 sum(r.RuntimePMRunBy),  
 sum(r.FreshRuntimePMRunBy),  
 sum(r.StorageRuntimePMRunBy),  
  
 sum(r.TotalRolls),   
 sum(r.FreshRolls),  
 sum(r.StorageRolls)--,  
from @ProdLines pl   
join dbo.#prsrun r  
ON r.PLId = pl.PLId  
 join @prdtmetrics pdm  
on r.id_num = pdm.id_num  
WHERE r.RuntimePMRunBy IS NOT NULL  
AND (charindex('|' + r.LineStatus + '|', '|' + @LineStatusList + '|') > 0  
  OR @LineStatusList = 'All')  
and r.PaperMachine <> 'NoAssignedPRID'  
GROUP BY r.PaperMachine, r.PaperRunBy  
  
--Rev7.6  
INSERT INTO @PRSummaryPM  
 (  
  PaperMachine,  
 ELPStops,  
 ELPDowntime,  
 RLELPDowntime,  
 FreshStops,  
 FreshDT,  
 FreshRLELPDT,   
 StorageStops,  
 StorageDT,  
 StorageRLELPDT,  
 ScheduledDT,  
 FreshSchedDT,  
 StorageSchedDT,  
 Runtime,  
 FreshRuntime,  
 StorageRuntime,  
 TotalRolls,   
 FreshRolls,  
 StorageRolls--,  
 )   
SELECT    
 PaperMachine,  
 sum(ELPStops),  
 sum(ELPDowntime),  
 sum(RLELPDowntime),  
 sum(FreshStops),  
 sum(FreshDT),  
 sum(FreshRLELPDT),   
 sum(StorageStops),  
 sum(StorageDT),  
 sum(StorageRLELPDT),  
 sum(ScheduledDT),   
 sum(FreshSchedDT),   
 sum(StorageSchedDT),  
 sum(Runtime),  
 sum(FreshRuntime),  
 sum(StorageRuntime),  
 sum(TotalRolls),   
 sum(FreshRolls),  
 sum(StorageRolls)--,  
from @PRSummaryPMRunBy pdm  
GROUP BY PaperMachine  
  
  
----------------------  
-- Validation Code  
----------------------  
  
update prs set  
 LinePSID1 =  
  (  
  select top 1 LinePS.id_num --EventID  
  from dbo.#prsrun LinePS  
  join dbo.#prsrun pr  
  on pr.PLID = LinePS.PLID  
  and pr.PaperSource = LinePS.PaperSource  
  and pr.StartTime >= LinePS.StartTimeLinePS   
  and pr.StartTime < LinePS.EndTimeLinePS   
  and pr.id_num = prs.id_num  
  order by datediff(ss,LinePS.StartTimeLinePS,LinePS.EndtimeLinePS) desc, LinePS.StartTimeLinePS  
  )  
from dbo.#prsrun prs  
  
update prs set  
 LineID1 =  
  (  
  select top 1 Line.id_num --EventID  
  from dbo.#prsrun Line  
  join dbo.#prsrun pr  
  on pr.PLID = Line.PLID  
  and pr.StartTime >= Line.StartTimeLine   
  and pr.StartTime < Line.EndTimeLine   
  and pr.id_num = prs.id_num  
  order by datediff(ss,Line.StartTimeLine,Line.EndtimeLine) desc, Line.StartTimeLine  
  )  
from dbo.#prsrun prs  
  
update prs set  
 PMRunByID1 =  
  (  
  select top 1 PMRunBy.id_num --EventID  
  from dbo.#prsrun PMRunBy  
  join dbo.#prsrun pr  
  on pr.PaperMachine = PMRunBy.PaperMachine  
  and pr.PaperRunBy = PMRunBy.PaperRunBy  
  and pr.StartTime >= PMRunBy.StartTimePMRunBy   
  and pr.StartTime < PMRunBy.EndTimePMRunBy   
  and pr.id_num = prs.id_num  
  order by datediff(ss,PMRunBy.StartTimePMRunBy,PMRunBy.EndtimePMRunBy) desc, PMRunBy.StartTimePMRunBy  
  )  
from dbo.#prsrun prs  
  
  
update prs set  
 LinePSID2 =  
  (  
  select top 1 LinePS.id_num --EventID  
  from dbo.#prsrun LinePS  
  join dbo.#prsrun pr  
  on pr.PLID = LinePS.PLID  
  and pr.PaperSource = LinePS.PaperSource  
  and pr.EndTime > LinePS.StartTimeLinePS   
  and pr.EndTime <= LinePS.EndTimeLinePS   
  and pr.id_num = prs.id_num  
  order by datediff(ss,LinePS.StartTimeLinePS,LinePS.EndtimeLinePS) desc, LinePS.StartTimeLinePS  
  )  
from dbo.#prsrun prs  
  
update prs set  
 LineID2 =  
  (  
  select top 1 Line.id_num --EventID  
  from dbo.#prsrun Line  
  join dbo.#prsrun pr  
  on pr.PLID = Line.PLID  
  and pr.EndTime > Line.StartTimeLine   
  and pr.EndTime <= Line.EndTimeLine   
  and pr.id_num = prs.id_num  
  order by datediff(ss,Line.StartTimeLine,Line.EndtimeLine) desc, Line.StartTimeLine  
  )  
from dbo.#prsrun prs  
  
update prs set  
 PMRunByID2 =  
  (  
  select top 1 PMRunBy.id_num --EventID  
  from dbo.#prsrun PMRunBy  
  join dbo.#prsrun pr  
  on pr.PaperMachine = PMRunBy.PaperMachine  
  and pr.PaperRunBy = PMRunBy.PaperRunBy  
  and pr.EndTime > PMRunBy.StartTimePMRunBy   
  and pr.EndTime <= PMRunBy.EndTimePMRunBy   
  and pr.id_num = prs.id_num  
  order by datediff(ss,PMRunBy.StartTimePMRunBy,PMRunBy.EndtimePMRunBy) desc, PMRunBy.StartTimePMRunBy  
  )  
from dbo.#prsrun prs  
  
  
update prs set  
 StartTimeLinePS = null,  
 EndTimeLinePS = null  
from dbo.#prsrun prs  
where StartTimeLinePS = EndTimeLinePS  
  
update prs set  
 StartTimeLine = null,  
 EndTimeLine = null  
from dbo.#prsrun prs  
where StartTimeLine = EndTimeLine  
  
update prs set  
 StartTimePMRunBy = null,  
 EndTimePMRunBy = null  
from dbo.#prsrun prs  
where StartTimePMRunBy = EndTimePMRunBy  
  
  
-------------------------------------------------------------------------------  
--print 'ReturnResultSets: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
  
ReturnResultSets:      
  
--select 'uws', *  
--from @uws  
--order by RelPUDesc  
  
--select 'downtime', sd.*   
--from #delays sd  
--join prod_units pu  
--on sd.puid = pu.pu_id  
--order by puid, starttime, endtime  
  
--select 'produnits', * from @produnits pu  
--order by puid  
--select 'prodlines', * from @prodlines pl  
--order by plid  
  
/*  
select '@prsrun', --pu.pu_desc, r.*  
 pu.PU_Desc,  
 AgeOfPR,  
 PaperMachine,  
 StartTimeLine,  
 EndTimeLine,  
 StorageSchedDT/60.0 StorageSchedDT,   
 StorageRuntime/60.0 StorageRuntime,  
 StorageRuntimeLine/60.0 StorageRuntimeLine,  
 RuntimeLine/60.0 RuntimeLine,  
 UWS,  
 ID_Num,  
 EventID,  
 SourceID,  
 PLID,  
 PUID,  
 PEIID,  
 PEIPID,  
 ParentPRID,  
 GrandParentPRID,  
 ParentPM,  
 GrandParentPM,  
 PRPLID,  
 PRPUID,  
 StartTime,  
 EndTime,  
 DevComment, r.*   
from dbo.#prsrun r  
join prod_units pu  
on r.puid = pu.pu_id  
where pu_desc like '%ott4%'  
--order by plid, puid, starttime, endtime  
order by plid, starttimeline, endtimeline  
*/  
  
--select   
-- 'prs', prs.*--,  
--FROM @PRSummaryLine prs  
--LEFT JOIN @ProdLines pl   
--ON prs.CvtgPLId = pl.PLId  
--where pldesc like '%ott5%'  
  
/*  
select 'breakout', r.*, '||', pdm.*  
from @ProdLines pl   
join dbo.#prsrun r  
ON r.PLId = pl.PLId  
join @prdtmetrics pdm  
on r.id_num = pdm.id_num  
WHERE r.RuntimeLine IS NOT NULL   
AND (charindex('|' + r.LineStatus + '|', '|' + @LineStatusList + '|') > 0  
OR @LineStatusList = 'All')  
and pl.pldesc like '%ott5%'  
and r.fresh = 1  
--and pdm.FreshDTLine > 0.0  
*/  
  
-- if there are errors from the parameter validation, then return them and skip the rest of the results  
  
 if (select count(*) from @ErrorMessages) > 0 AND @blnDupPRIDErrors = 0   -- 2005-SEP-06 VMK Rev6.95  
  
 begin  
  
  -------------------------------------------------------------------------------  
  -- Error Messages.  
  -------------------------------------------------------------------------------  
  SELECT ErrMsg  
  FROM @ErrorMessages  
  OPTION (KEEP PLAN)  
  
 end  
  
 else  
  
 begin  
  
  --print 'RS1: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
 -- result set 1  
 -------------------------------------------------------------------------------  
 -- Error Messages.  
 -------------------------------------------------------------------------------  
  SELECT ErrMsg  
  FROM @ErrorMessages  
  OPTION (KEEP PLAN)  
  
 --print 'RS2: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
 -- result set 2    
  
 -------------------------------------------------------------------------------  
 -- new  
 -- Summarize ELP by Line / Paper Source / PEIID.     
 -------------------------------------------------------------------------------  
--Rev7.6  
 INSERT INTO dbo.#LineMachineELPByUWS  
 SELECT pl.PLDesc                                [Line],  
  prs.PaperSource                               [Paper Source],  
  prs.UWS [UWS],  
  (CASE WHEN (SUM(COALESCE(prs.Runtime, 0.0)) > DATEDIFF(ss, @StartTime, @EndTime))  
     AND pl.PLDesc LIKE 'PP FF%' THEN                                  -- 2006-11-17 VMK Rev7.39, added CASE  
   ((DATEDIFF(ss, @StartTime, @EndTime)) - SUM(COALESCE(prs.ScheduledDT, 0.0))) --   
  ELSE     
   SUM((COALESCE(prs.Runtime, 0.0)) - COALESCE(prs.ScheduledDT, 0.0)) --   
  END) / 60.0                                 [Paper Runtime],        
  SUM(COALESCE(prs.ELPStops, 0))                          [Paper Stops],  
  SUM(CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)) / 60.0)                  [DT due to Stops],  
  SUM(COALESCE(prs.RLELPDowntime/60.0, 0.0))                          [Eff. DT (Rate Loss)],  
  SUM((CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)) / 60.0) + (COALESCE(prs.RLELPDowntime/60.0, 0.0)))      [Total Paper DT],  
  SUM(CONVERT(FLOAT, prs.FreshStops))                         [Fresh Paper Stops],  
  SUM((CONVERT(FLOAT, COALESCE(prs.FreshDT, 0.0)) / 60.0) + (COALESCE(prs.FreshRLELPDT/60.0, 0.0)))        [Fresh Paper DT],--FLD CapeProb  
  SUM((COALESCE(prs.FreshRuntime, 0.0)) - COALESCE(prs.FreshSchedDT, 0.0)) / 60.0           [Fresh Paper Runtime],  
  SUM(COALESCE(prs.FreshRolls, 0))                          [Fresh Rolls Ran],  
  SUM(CONVERT(FLOAT, COALESCE(prs.StorageStops, 0)))                    [Storage Paper Stops],  
  SUM((CONVERT(FLOAT, COALESCE(prs.StorageDT, 0.0)) / 60.0) + (COALESCE(prs.StorageRLELPDT/60.0, 0.0)))       [Storage Paper DT],--FLD CapeProb  
  SUM((COALESCE(prs.StorageRuntime, 0.0)) - COALESCE(prs.StorageSchedDT, 0.0)) / 60.0         [Storage Paper Runtime],  
  SUM(COALESCE(prs.StorageRolls, 0))                          [Storage Rolls Ran],  
  sum(COALESCE(prs.TotalRolls, 0))                          [Total Rolls Ran],  
  
  
  CASE WHEN (SUM((COALESCE(prs.FreshRuntime, 0.0) - COALESCE(prs.FreshSchedDT, 0.0))) / 60.0) > 0.0 THEN               -- 2006-09-18 VMK Rev7.34, modified calc  
     (SUM(((CONVERT(FLOAT, COALESCE(prs.FreshDT, 0.0)))/60.0) + COALESCE(prs.FreshRLELPDT/60.0, 0.0)) / --FLD CapeProb  
     (SUM(COALESCE(prs.FreshRuntime, 0.0) - COALESCE(prs.FreshSchedDT, 0.0))/60.0)) --   
  ELSE 0.0 END                                  [Fresh ELP%],  
  
  
  CASE WHEN (SUM((COALESCE(prs.StorageRuntime, 0.0) - COALESCE(prs.StorageSchedDT, 0.0))) / 60.0) > 0.0 THEN             -- 2006-09-18 VMK Rev7.34, modified calc  
   (SUM(((CONVERT(FLOAT, COALESCE(prs.StorageDT, 0.0)))/60.0) + COALESCE(prs.StorageRLELPDT/60.0, 0.0)) / --FLD CapeProb  
    (SUM(COALESCE(prs.StorageRuntime, 0.0) - COALESCE(prs.StorageSchedDT, 0.0))/60.0)) --   
  ELSE 0.0 END                                  [Storage ELP%],  
  
  CASE WHEN (SUM((COALESCE(prs.Runtime, 0.0) - COALESCE(prs.ScheduledDT, 0.0))) / 60.0) > 0.0 THEN               -- 2006-09-18 VMK Rev7.34, modified calc  
   CASE WHEN (SUM(COALESCE(prs.Runtime, 0.0)) > DATEDIFF(ss, @StartTime, @EndTime))  
      AND pl.PLDesc LIKE 'PP FF%' THEN                                 -- 2006-11-17 VMK Rev7.39, added CASE  
     (SUM(((CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)))/60.0) + COALESCE(prs.RLELPDowntime/60.0, 0.0)) /  
      (((DATEDIFF(ss, @StartTime, @EndTime)) - (SUM(COALESCE(prs.ScheduledDT, 0.0))))/60.0)) --   
   ELSE  
     (SUM(((CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)))/60.0) + COALESCE(prs.RLELPDowntime/60.0, 0.0)) /   
     (SUM(COALESCE(prs.Runtime, 0.0) - COALESCE(prs.ScheduledDT, 0.0))/60.0))--   
   END  
  ELSE 0.0 END                                  [Total ELP%]  
 FROM @PRSummaryUWS prs  
 LEFT JOIN @ProdLines pl   
 ON prs.CvtgPLId = pl.PLId  
 GROUP BY pl.PLDesc, prs.PaperSource, UWS           -- 2005-APR-22 VMK Rev6.87  
 ORDER BY pl.PLDesc, prs.PaperSource, UWS  --prs.PaperMachine   -- 2005-APR-21 VMK Rev6.87  
 OPTION (KEEP PLAN)  
     
 select @SQL =   
 case  
 when (select count(*) from dbo.#LineMachineELPByUWS) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from dbo.#LineMachineELPByUWS) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#LineMachineELPByUWS', @LanguageId)  
 end  
  
 EXECUTE sp_executesql @SQL     -- 2005-OCT-26 VMK Rev7.01  
  
 -------------------------------------------------------------------------------  
 -- Summarize ELP by Line / Paper Source.  
 -------------------------------------------------------------------------------  
  
 INSERT INTO dbo.#LineMachineELP  
 SELECT pl.PLDesc                                [Line],  
  prs.PaperSource                               [Paper Source],  
  '' [UWS],  --Rev7.6  
  (CASE WHEN (SUM(COALESCE(prs.Runtime, 0.0)) > DATEDIFF(ss, @StartTime, @EndTime))  
     AND pl.PLDesc LIKE 'PP FF%' THEN                                  -- 2006-11-17 VMK Rev7.39, added CASE  
   ((DATEDIFF(ss, @StartTime, @EndTime)) - SUM(COALESCE(prs.ScheduledDT, 0.0))) --   
--Rev7.6     --(COALESCE(prs.UWSTotalDT, 0.0) - COALESCE(prs.CvtrTotalDT, 0.0))))  
  ELSE     
   SUM((COALESCE(prs.Runtime, 0.0)) - COALESCE(prs.ScheduledDT, 0.0)) --   
--Rev7.6    --(COALESCE(prs.UWSTotalDT, 0.0) - COALESCE(prs.CvtrTotalDT, 0.0)))  
  END) / 60.0                                 [Paper Runtime],        
  SUM(COALESCE(prs.ELPStops, 0))                          [Paper Stops],  
  SUM(CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)) / 60.0)                  [DT due to Stops],  
  SUM(COALESCE(prs.RLELPDowntime, 0.0)/60.0)                          [Eff. DT (Rate Loss)],  
  SUM((CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)) / 60.0) + (COALESCE(prs.RLELPDowntime, 0.0)/60.0))      [Total Paper DT],  
  SUM(CONVERT(FLOAT, prs.FreshStops))                         [Fresh Paper Stops],  
  SUM((CONVERT(FLOAT, COALESCE(prs.FreshDT, 0.0)) / 60.0) + (COALESCE(prs.FreshRLELPDT, 0.0)/60.0))        [Fresh Paper DT],--FLD CapeProb  
  SUM((COALESCE(prs.FreshRuntime, 0.0)) - COALESCE(prs.FreshSchedDT, 0.0)) / 60.0           [Fresh Paper Runtime],  
--Rev7.6   --(COALESCE(prs.UWSFreshDT, 0.0) - COALESCE(prs.CvtrFreshDT, 0.0))) / 60.0  -- 2006-10-29 VMK Rev7.37, modified calc  
  SUM(COALESCE(prs.FreshRolls, 0))                          [Fresh Rolls Ran],  
  SUM(CONVERT(FLOAT, COALESCE(prs.StorageStops, 0)))                    [Storage Paper Stops],  
  SUM((CONVERT(FLOAT, COALESCE(prs.StorageDT, 0.0)) / 60.0) + (COALESCE(prs.StorageRLELPDT, 0.0)/60.0))       [Storage Paper DT],--FLD CapeProb  
  SUM((COALESCE(prs.StorageRuntime, 0.0)) - COALESCE(prs.StorageSchedDT, 0.0)) / 60.0         [Storage Paper Runtime],  
--Rev7.6   --(COALESCE(prs.UWSStorageDT, 0.0) - COALESCE(prs.CvtrStorageDT, 0.0))) / 60.0 -- 2006-10-29 VMK Rev7.37, modified calc  
  SUM(COALESCE(prs.StorageRolls, 0))                          [Storage Rolls Ran],  
  sum(COALESCE(prs.TotalRolls, 0))                          [Total Rolls Ran],  
  
  
  CASE WHEN (SUM((COALESCE(prs.FreshRuntime, 0.0) - COALESCE(prs.FreshSchedDT, 0.0))) / 60.0) > 0.0 THEN               -- 2006-09-18 VMK Rev7.34, modified calc  
     (SUM(((CONVERT(FLOAT, COALESCE(prs.FreshDT, 0.0)))/60.0) + COALESCE(prs.FreshRLELPDT, 0.0)/60.0) / --FLD CapeProb  
     (SUM(COALESCE(prs.FreshRuntime, 0.0) - COALESCE(prs.FreshSchedDT, 0.0))/60.0))--   
--Rev7.6      --(COALESCE(prs.UWSFreshDT, 0.0) - COALESCE(prs.CvtrFreshDT, 0.0)))/60.0))  
  ELSE 0.0 END                                  [Fresh ELP%],  
  
  
  CASE WHEN (SUM((COALESCE(prs.StorageRuntime, 0.0) - COALESCE(prs.StorageSchedDT, 0.0))) / 60.0) > 0.0 THEN             -- 2006-09-18 VMK Rev7.34, modified calc  
   (SUM(((CONVERT(FLOAT, COALESCE(prs.StorageDT, 0.0)))/60.0) + COALESCE(prs.StorageRLELPDT, 0.0)/60.0) / --FLD CapeProb  
    (SUM(COALESCE(prs.StorageRuntime, 0.0) - COALESCE(prs.StorageSchedDT, 0.0))/60.0)) --   
--Rev7.6     --(COALESCE(prs.UWSStorageDT, 0.0) - COALESCE(prs.CvtrStorageDT, 0.0)))/60.0))  
  ELSE 0.0 END                                  [Storage ELP%],  
  
  CASE WHEN (SUM((COALESCE(prs.Runtime, 0.0) - COALESCE(prs.ScheduledDT, 0.0))) / 60.0) > 0.0 THEN               -- 2006-09-18 VMK Rev7.34, modified calc  
   CASE WHEN (SUM(COALESCE(prs.Runtime, 0.0)) > DATEDIFF(ss, @StartTime, @EndTime))  
      AND pl.PLDesc LIKE 'PP FF%' THEN                                 -- 2006-11-17 VMK Rev7.39, added CASE  
     (SUM(((CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)))/60.0) + COALESCE(prs.RLELPDowntime, 0.0)/60.0) /  
      (((DATEDIFF(ss, @StartTime, @EndTime)) - (SUM(COALESCE(prs.ScheduledDT, 0.0))))/60.0)) --   
--Rev7.6             --(COALESCE(prs.UWSTotalDT, 0.0) - COALESCE(prs.CvtrTotalDT, 0.0)))))/60.0))  
   ELSE  
     (SUM(((CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)))/60.0) + COALESCE(prs.RLELPDowntime, 0.0)/60.0) /   
     (SUM(COALESCE(prs.Runtime, 0.0) - COALESCE(prs.ScheduledDT, 0.0))/60.0))--   
--Rev7.6      --(COALESCE(prs.UWSTotalDT, 0.0) - COALESCE(prs.CvtrTotalDT, 0.0)))/60.0))  
   END  
  ELSE 0.0 END                                  [Total ELP%]  
 FROM @PRSummaryLinePS prs  
 LEFT JOIN @ProdLines pl   
 ON prs.CvtgPLId = pl.PLId  
 GROUP BY pl.PLDesc, prs.PaperSource           -- 2005-APR-22 VMK Rev6.87  
 ORDER BY pl.PLDesc, prs.PaperSource  --prs.PaperMachine   -- 2005-APR-21 VMK Rev6.87  
 OPTION (KEEP PLAN)  
     
 select @SQL =   
 case  
 when (select count(*) from dbo.#LineMachineELP) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from dbo.#LineMachineELP) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#LineMachineELP', @LanguageId)  
 end  
  
 EXECUTE sp_executesql @SQL     -- 2005-OCT-26 VMK Rev7.01  
  
--   --print 'RS3: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
 -- result set 3  
 -------------------------------------------------------------------------------  
 -- Summarize ELP by Line.  
 -------------------------------------------------------------------------------  
  
 INSERT INTO dbo.#LineELP  
 SELECT pl.PLDesc [Line],  
  '' [Paper Source],   
  '' [UWS], --Rev7.6  
  (CASE WHEN (SUM(COALESCE(prs.Runtime, 0.0)) > DATEDIFF(ss, @StartTime, @EndTime))  
     AND pl.PLDesc LIKE 'PP FF%' THEN                                  -- 2006-11-17 VMK Rev7.39, added CASE  
   ((DATEDIFF(ss, @StartTime, @EndTime)) - SUM(COALESCE(prs.ScheduledDT, 0.0))) --   
--Rev7.6     --(COALESCE(prs.UWSTotalDT, 0.0) - COALESCE(prs.CvtrTotalDT, 0.0))))  
  ELSE     
   SUM((COALESCE(prs.Runtime, 0.0)) - COALESCE(prs.ScheduledDT, 0.0)) --   
--Rev7.6    --(COALESCE(prs.UWSTotalDT, 0.0) - COALESCE(prs.CvtrTotalDT, 0.0)))  
  END) / 60.0                                 [Paper Runtime],        
  SUM(COALESCE(prs.ELPStops, 0))                          [Paper Stops],  
  SUM(CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)) / 60.0)                  [DT due to Stops],  
  SUM(COALESCE(prs.RLELPDowntime/60.0, 0.0))                          [Eff. DT (Rate Loss)],  
  SUM((CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)) / 60.0) + (COALESCE(prs.RLELPDowntime/60.0, 0.0)))      [Total Paper DT],  
  SUM(CONVERT(FLOAT, prs.FreshStops))                         [Fresh Paper Stops],  
  SUM((CONVERT(FLOAT, COALESCE(prs.FreshDT, 0.0)) / 60.0) + (COALESCE(prs.FreshRLELPDT/60.0, 0.0)))        [Fresh Paper DT],--FLD CapeProb  
  SUM((COALESCE(prs.FreshRuntime, 0.0)) - COALESCE(prs.FreshSchedDT, 0.0)) / 60.0           [Fresh Paper Runtime],  
--Rev7.6   --(COALESCE(prs.UWSFreshDT, 0.0) - COALESCE(prs.CvtrFreshDT, 0.0))) / 60.0  -- 2006-10-29 VMK Rev7.37, modified calc  
  SUM(COALESCE(prs.FreshRolls, 0.0))                          [Fresh Rolls Ran],  
  SUM(CONVERT(FLOAT, COALESCE(prs.StorageStops, 0.0)))                    [Storage Paper Stops],  
  SUM((CONVERT(FLOAT, COALESCE(prs.StorageDT, 0.0)) / 60.0) + (COALESCE(prs.StorageRLELPDT/60.0, 0.0)))       [Storage Paper DT],--FLD CapeProb  
  SUM((COALESCE(prs.StorageRuntime, 0.0)) - COALESCE(prs.StorageSchedDT, 0.0)) / 60.0         [Storage Paper Runtime],  
--Rev7.6   --(COALESCE(prs.UWSStorageDT, 0.0) - COALESCE(prs.CvtrStorageDT, 0.0))) / 60.0 -- 2006-10-29 VMK Rev7.37, modified calc  
  SUM(COALESCE(prs.StorageRolls, 0))                          [Storage Rolls Ran],  
  sum(COALESCE(prs.TotalRolls, 0))                          [Total Rolls Ran],  
  
  
  CASE WHEN (SUM((COALESCE(prs.FreshRuntime, 0.0) - COALESCE(prs.FreshSchedDT, 0.0))) / 60.0) > 0.0 THEN               -- 2006-09-18 VMK Rev7.34, modified calc  
     (SUM(((CONVERT(FLOAT, COALESCE(prs.FreshDT, 0.0)))/60.0) + COALESCE(prs.FreshRLELPDT/60.0, 0.0)) / --FLD CapeProb  
     (SUM(COALESCE(prs.FreshRuntime, 0.0) - COALESCE(prs.FreshSchedDT, 0.0))/60.0))--   
--Rev7.6      --(COALESCE(prs.UWSFreshDT, 0.0) - COALESCE(prs.CvtrFreshDT, 0.0)))/60.0))  
  ELSE 0.0 END                                  [Fresh ELP%],  
  
  
  CASE WHEN (SUM((COALESCE(prs.StorageRuntime, 0.0) - COALESCE(prs.StorageSchedDT, 0.0))) / 60.0) > 0.0 THEN             -- 2006-09-18 VMK Rev7.34, modified calc  
   (SUM(((CONVERT(FLOAT, COALESCE(prs.StorageDT, 0.0)))/60.0) + COALESCE(prs.StorageRLELPDT/60.0, 0.0)) / --FLD CapeProb  
    (SUM(COALESCE(prs.StorageRuntime, 0.0) - COALESCE(prs.StorageSchedDT, 0.0))/60.0)) --   
--Rev7.6     --(COALESCE(prs.UWSStorageDT, 0.0) - COALESCE(prs.CvtrStorageDT, 0.0)))/60.0))  
  ELSE 0.0 END                                  [Storage ELP%],  
  
  CASE WHEN (SUM((COALESCE(prs.Runtime, 0.0) - COALESCE(prs.ScheduledDT, 0.0))) / 60.0) > 0.0 THEN               -- 2006-09-18 VMK Rev7.34, modified calc  
   CASE WHEN (SUM(COALESCE(prs.Runtime, 0.0)) > DATEDIFF(ss, @StartTime, @EndTime))  
      AND pl.PLDesc LIKE 'PP FF%' THEN                                 -- 2006-11-17 VMK Rev7.39, added CASE  
     (SUM(((CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)))/60.0) + COALESCE(prs.RLELPDowntime/60.0, 0.0)) /  
      (((DATEDIFF(ss, @StartTime, @EndTime)) - (SUM(COALESCE(prs.ScheduledDT, 0.0))))/60.0)) --   
--Rev7.6             --(COALESCE(prs.UWSTotalDT, 0.0) - COALESCE(prs.CvtrTotalDT, 0.0)))))/60.0))  
   ELSE  
     (SUM(((CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)))/60.0) + COALESCE(prs.RLELPDowntime/60.0, 0.0)) /   
     (SUM(COALESCE(prs.Runtime, 0.0) - COALESCE(prs.ScheduledDT, 0.0))/60.0))--   
--Rev7.6      --(COALESCE(prs.UWSTotalDT, 0.0) - COALESCE(prs.CvtrTotalDT, 0.0)))/60.0))  
   END  
  ELSE 0 END                                  [Total ELP%]  
 FROM @PRSummaryLine prs  
-- FROM @PRSummaryUWS prs  
 LEFT JOIN @ProdLines pl   
 ON prs.CvtgPLId = pl.PLId  
 GROUP BY pl.PLDesc  
 OPTION (KEEP PLAN)  
   
 select @SQL =   
 case  
 when (select count(*) from dbo.#LineELP) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from dbo.#LineELP) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#LineELP', @LanguageId)  
 end  
  
 EXECUTE sp_executesql @SQL     -- 2005-OCT-26 VMK Rev7.01  
  
  
--   --print 'RS4: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
 -- result set 4  
 -------------------------------------------------------------------------------  
 -- Summarize ELP for all Lines.  
 -------------------------------------------------------------------------------  
  
 INSERT INTO dbo.#ReportELP  
 SELECT ''                                  [Line],  
  ''                                    [Paper Machine],  
  'Overall Totals' [UWS], --Rev7.6  
  SUM((COALESCE(prs.Runtime, 0.0)) - COALESCE(prs.ScheduledDT, 0.0)) / 60.0             [Paper Runtime],  
--Rev7.6   --(COALESCE(prs.UWSTotalDT, 0.0) - COALESCE(prs.CvtrTotalDT, 0.0))) / 60.0  -- 2006-10-29 VMK Rev7.37, modified calc  
  SUM(COALESCE(prs.ELPStops, 0))                          [Paper Stops],  
  SUM(CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)) / 60.0)                  [DT due to Stops],  
  SUM(COALESCE(prs.RLELPDowntime/60.0, 0.0))                          [Eff. DT (Rate Loss)],  
  SUM((CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)) / 60.0) + (COALESCE(prs.RLELPDowntime/60.0, 0.0)))      [Total Paper DT],  
  SUM(CONVERT(FLOAT, prs.FreshStops))                         [Fresh Paper Stops],  
  SUM((CONVERT(FLOAT, COALESCE(prs.FreshDT, 0.0)) / 60.0) + (COALESCE(prs.FreshRLELPDT/60.0, 0.0)))        [Fresh Paper DT],--FLD CapeProb  
  SUM((COALESCE(prs.FreshRuntime, 0.0)) - COALESCE(prs.FreshSchedDT, 0.0)) / 60.0           [Fresh Paper Runtime],  
--Rev7.6   --(COALESCE(prs.UWSFreshDT, 0.0) - COALESCE(prs.CvtrFreshDT, 0.0))) / 60.0   -- 2006-10-29 VMK Rev7.37, modified calc  
  SUM(COALESCE(prs.FreshRolls, 0))                          [Fresh Rolls Ran],  
  SUM(CONVERT(FLOAT, COALESCE(prs.StorageStops, 0)))                    [Storage Paper Stops],  
  SUM((CONVERT(FLOAT, COALESCE(prs.StorageDT, 0.0)) / 60.0) + (COALESCE(prs.StorageRLELPDT/60.0, 0.0)))       [Storage Paper DT],--FLD CapeProb  
  SUM((COALESCE(prs.StorageRuntime, 0.0)) - COALESCE(prs.StorageSchedDT, 0.0)) / 60.0         [Storage Paper Runtime],  
--Rev7.6   --(COALESCE(prs.UWSStorageDT, 0.0) - COALESCE(prs.CvtrStorageDT, 0.0))) / 60.0 -- 2006-10-29 VMK Rev7.37, modified calc  
  SUM(COALESCE(prs.StorageRolls, 0))                          [Storage Rolls Ran],  
  sum(COALESCE(prs.TotalRolls, 0))                          [Total Rolls Ran],  
  CASE WHEN (SUM((COALESCE(prs.FreshRuntime, 0.0) - COALESCE(prs.FreshSchedDT, 0.0))) / 60.0) > 0.0 THEN               -- 2006-09-18 VMK Rev7.34, modified calc  
   (SUM(((CONVERT(FLOAT, COALESCE(prs.FreshDT, 0.0)))/60.0) + COALESCE(prs.FreshRLELPDT/60.0, 0.0)) / --FLD CapeProb  
    (SUM(COALESCE(prs.FreshRuntime, 0.0) - COALESCE(prs.FreshSchedDT, 0.0))/60.0))--   
--Rev7.6     --(COALESCE(prs.UWSFreshDT, 0.0) - COALESCE(prs.CvtrFreshDT, 0.0)))/60.0))  
  ELSE 0.0 END                                  [Fresh ELP%],  
  CASE WHEN (SUM((COALESCE(prs.StorageRuntime, 0.0) - COALESCE(prs.StorageSchedDT, 0.0))) / 60.0) > 0.0 THEN             -- 2006-09-18 VMK Rev7.34, modified calc  
   (SUM(((CONVERT(FLOAT, COALESCE(prs.StorageDT, 0.0)))/60.0) + COALESCE(prs.StorageRLELPDT/60.0, 0.0)) / --FLD CapeProb  
    (SUM(COALESCE(prs.StorageRuntime, 0.0) - COALESCE(prs.StorageSchedDT, 0.0))/60.0)) --   
--Rev7.6     --(COALESCE(prs.UWSStorageDT, 0.0) - COALESCE(prs.CvtrStorageDT, 0.0)))/60.0))  
  ELSE 0.0 END                                  [Storage ELP%],  
  CASE WHEN (SUM((COALESCE(prs.Runtime, 0.0) - COALESCE(prs.ScheduledDT, 0.0))) / 60.0) > 0.0 THEN                 -- 2006-09-18 VMK Rev7.34, modified calc  
   (SUM(((CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)))/60.0) + COALESCE(prs.RLELPDowntime/60.0, 0.0)) /   
    (SUM(COALESCE(prs.Runtime, 0.0) - COALESCE(prs.ScheduledDT, 0.0))/60.0))--   
--Rev7.6     --(COALESCE(prs.UWSTotalDT, 0.0) - COALESCE(prs.CvtrTotalDT, 0.0)))/60.0))  
  ELSE 0.0 END                                  [Total ELP%]       -- 2006-09-18 VMK Rev7.34, modified calc  
 FROM @PRSummaryLine prs  
 OPTION (KEEP PLAN)  
   
 select @SQL =   
 case  
 when (select count(*) from dbo.#ReportELP) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from dbo.#ReportELP) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#ReportELP', @LanguageId)  
 end  
  
 EXECUTE sp_executesql @SQL     -- 2005-OCT-26 VMK Rev7.01  
  
  
  --print 'RS5: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
 -- result set 5  
 -------------------------------------------------------------------------------  
 -- Summarize ELP by Intermediate, [Paper Run By], and PEIID.  
 -------------------------------------------------------------------------------  
 INSERT INTO dbo.#LineMachineELPByUWS3  
 SELECT   
  prs.INTR                                  [Intermediate],  
  REPLACE(REPLACE(pl.PLDesc, 'TT ', ''), 'PP ', '')                    [Paper Run By],  
  prs.UWS [UWS], --Rev7.6  
  SUM((COALESCE(prs.Runtime, 0.0)) - COALESCE(prs.ScheduledDT, 0.0)) / 60.0             [Paper Runtime],   
  SUM(COALESCE(prs.ELPStops, 0))                          [Paper Stops],  
  SUM(CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)) / 60.0)                  [DT due to Stops],  
  SUM(COALESCE(prs.RLELPDowntime/60.0, 0.0))                          [Eff. DT (Rate Loss)],  
  SUM((CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)) / 60.0) + (COALESCE(prs.RLELPDowntime/60.0, 0.0)))      [Total Paper DT],  
  SUM(CONVERT(FLOAT, prs.FreshStops))                         [Fresh Paper Stops],  
  SUM((CONVERT(FLOAT, COALESCE(prs.FreshDT, 0.0)) / 60.0) + (COALESCE(prs.FreshRLELPDT/60.0, 0.0)))        [Fresh Paper DT],--FLD CapeProb  
  SUM((COALESCE(prs.FreshRuntime, 0.0)) - COALESCE(prs.FreshSchedDT, 0.0)) / 60.0           [Fresh Paper Runtime],  
  SUM(COALESCE(prs.FreshRolls, 0))                          [Fresh Rolls Ran],  
  SUM(CONVERT(FLOAT, COALESCE(prs.StorageStops, 0)))                    [Storage Paper Stops],  
  SUM((CONVERT(FLOAT, COALESCE(prs.StorageDT, 0.0)) / 60.0) + (COALESCE(prs.StorageRLELPDT/60.0, 0.0)))       [Storage Paper DT],--FLD CapeProb  
  SUM((COALESCE(prs.StorageRuntime, 0.0)) - COALESCE(prs.StorageSchedDT, 0.0)) / 60.0         [Storage Paper Runtime],  
  SUM(COALESCE(prs.StorageRolls, 0))                          [Storage Rolls Ran],  
  sum(COALESCE(prs.TotalRolls, 0))                          [Total Rolls Ran],  
  CASE WHEN (SUM((COALESCE(prs.FreshRuntime, 0.0) - COALESCE(prs.FreshSchedDT, 0.0))) / 60.0) > 0.0 THEN               -- 2006-09-18 VMK Rev7.34, modified calc  
   (SUM(((CONVERT(FLOAT, COALESCE(prs.FreshDT, 0.0)))/60.0) + COALESCE(prs.FreshRLELPDT/60.0, 0.0)) / --FLD CapeProb  
    (SUM(COALESCE(prs.FreshRuntime, 0.0) - COALESCE(prs.FreshSchedDT, 0.0))/60.0))--   
  ELSE 0.0 END                                  [Fresh ELP%],  
  CASE WHEN (SUM((COALESCE(prs.StorageRuntime, 0.0) - COALESCE(prs.StorageSchedDT, 0.0))) / 60.0) > 0.0 THEN             -- 2006-09-18 VMK Rev7.34, modified calc  
   (SUM(((CONVERT(FLOAT, COALESCE(prs.StorageDT, 0.0)))/60.0) + COALESCE(prs.StorageRLELPDT/60.0, 0.0)) / --FLD CapeProb  
    (SUM(COALESCE(prs.StorageRuntime, 0.0) - COALESCE(prs.StorageSchedDT, 0.0))/60.0)) --   
  ELSE 0.0 END                                  [Storage ELP%],  
  CASE WHEN (SUM((COALESCE(prs.Runtime, 0.0) - COALESCE(prs.ScheduledDT, 0.0))) / 60.0) > 0.0 THEN                 -- 2006-09-18 VMK Rev7.34, modified calc  
   (SUM(((CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)))/60.0) + COALESCE(prs.RLELPDowntime/60.0, 0.0)) /   
    (SUM(COALESCE(prs.Runtime, 0.0) - COALESCE(prs.ScheduledDT, 0.0))/60.0))--   
  ELSE 0.0 END                                  [Total ELP%]       -- 2006-09-18 VMK Rev7.34, modified calc  
 FROM @PRSummaryUWS prs  
 LEFT JOIN @ProdLines pl   
 ON prs.CvtgPLId = pl.PLId  
where intr is not null  
 GROUP BY prs.INTR, pl.PLDesc, prs.UWS  
 ORDER BY prs.INTR, pl.PLDesc, prs.UWS  
 OPTION (KEEP PLAN)  
  
 select @SQL =   
 case  
 when (select count(*) from dbo.#LineMachineELPByUWS3) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#LineMachineELPByUWS3', @LanguageId)  
 end  
  
 EXECUTE sp_executesql @SQL     -- 2005-OCT-26 VMK Rev7.01  
  
 -------------------------------------------------------------------------------  
 -- Summarize ELP by Intermediate and [Paper Run By].  
 -------------------------------------------------------------------------------  
 INSERT INTO dbo.#LineMachineELP3  
 SELECT   
  prs.INTR                                  [Intermediate],  
--  REPLACE(REPLACE(pl.PLDesc, 'TT ', ''), 'PP ', '')                    [Paper Run By],  
  prs.PaperRunBy                                [Paper Run By],  
  '' [UWS], --Rev7.6  
  SUM((COALESCE(prs.Runtime, 0.0)) - COALESCE(prs.ScheduledDT, 0.0)) / 60.0             [Paper Runtime],  
--Rev7.6   --(COALESCE(prs.UWSTotalDT, 0.0) - COALESCE(prs.CvtrTotalDT, 0.0))) / 60.0  -- 2006-10-29 VMK Rev7.37, modified calc  
  SUM(COALESCE(prs.ELPStops, 0))                          [Paper Stops],  
  SUM(CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)) / 60.0)                  [DT due to Stops],  
  SUM(COALESCE(prs.RLELPDowntime/60.0, 0.0))                          [Eff. DT (Rate Loss)],  
  SUM((CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)) / 60.0) + (COALESCE(prs.RLELPDowntime/60.0, 0.0)))      [Total Paper DT],  
  SUM(CONVERT(FLOAT, prs.FreshStops))                         [Fresh Paper Stops],  
  SUM((CONVERT(FLOAT, COALESCE(prs.FreshDT, 0.0)) / 60.0) + (COALESCE(prs.FreshRLELPDT/60.0, 0.0)))        [Fresh Paper DT],--FLD CapeProb  
  SUM((COALESCE(prs.FreshRuntime, 0.0)) - COALESCE(prs.FreshSchedDT, 0.0)) / 60.0           [Fresh Paper Runtime],  
--Rev7.6   --(COALESCE(prs.UWSFreshDT, 0.0) - COALESCE(prs.CvtrFreshDT, 0.0))) / 60.0  -- 2006-10-29 VMK Rev7.37, modified calc  
  SUM(COALESCE(prs.FreshRolls, 0))                          [Fresh Rolls Ran],  
  SUM(CONVERT(FLOAT, COALESCE(prs.StorageStops, 0)))                    [Storage Paper Stops],  
  SUM((CONVERT(FLOAT, COALESCE(prs.StorageDT, 0.0)) / 60.0) + (COALESCE(prs.StorageRLELPDT/60.0, 0.0)))       [Storage Paper DT],--FLD CapeProb  
  SUM((COALESCE(prs.StorageRuntime, 0.0)) - COALESCE(prs.StorageSchedDT, 0.0)) / 60.0         [Storage Paper Runtime],  
--Rev7.6   --(COALESCE(prs.UWSStorageDT, 0.0) - COALESCE(prs.CvtrStorageDT, 0.0))) / 60.0 -- 2006-10-29 VMK Rev7.37, modified calc  
  SUM(COALESCE(prs.StorageRolls, 0))                          [Storage Rolls Ran],  
  sum(COALESCE(prs.TotalRolls, 0))                          [Total Rolls Ran],  
  CASE WHEN (SUM((COALESCE(prs.FreshRuntime, 0.0) - COALESCE(prs.FreshSchedDT, 0.0))) / 60.0) > 0.0 THEN               -- 2006-09-18 VMK Rev7.34, modified calc  
   (SUM(((CONVERT(FLOAT, COALESCE(prs.FreshDT, 0.0)))/60.0) + COALESCE(prs.FreshRLELPDT/60.0, 0.0)) / --FLD CapeProb  
    (SUM(COALESCE(prs.FreshRuntime, 0.0) - COALESCE(prs.FreshSchedDT, 0.0))/60.0))--   
--Rev7.6     --(COALESCE(prs.UWSFreshDT, 0.0) - COALESCE(prs.CvtrFreshDT, 0.0)))/60.0))  
  ELSE 0.0 END                                  [Fresh ELP%],  
  CASE WHEN (SUM((COALESCE(prs.StorageRuntime, 0.0) - COALESCE(prs.StorageSchedDT, 0.0))) / 60.0) > 0.0 THEN             -- 2006-09-18 VMK Rev7.34, modified calc  
   (SUM(((CONVERT(FLOAT, COALESCE(prs.StorageDT, 0.0)))/60.0) + COALESCE(prs.StorageRLELPDT/60.0, 0.0)) / --FLD CapeProb  
    (SUM(COALESCE(prs.StorageRuntime, 0.0) - COALESCE(prs.StorageSchedDT, 0.0))/60.0)) --   
--Rev7.6     --(COALESCE(prs.UWSStorageDT, 0.0) - COALESCE(prs.CvtrStorageDT, 0.0)))/60.0))  
  ELSE 0.0 END                                  [Storage ELP%],  
  CASE WHEN (SUM((COALESCE(prs.Runtime, 0.0) - COALESCE(prs.ScheduledDT, 0.0))) / 60.0) > 0.0 THEN                 -- 2006-09-18 VMK Rev7.34, modified calc  
   (SUM(((CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)))/60.0) + COALESCE(prs.RLELPDowntime/60.0, 0.0)) /   
    (SUM(COALESCE(prs.Runtime, 0.0) - COALESCE(prs.ScheduledDT, 0.0))/60.0))--   
--Rev7.6     --(COALESCE(prs.UWSTotalDT, 0.0) - COALESCE(prs.CvtrTotalDT, 0.0)))/60.0))  
  ELSE 0.0 END                                  [Total ELP%]       -- 2006-09-18 VMK Rev7.34, modified calc  
 FROM @PRSummaryIntrPL prs  
 GROUP BY prs.INTR, prs.paperrunby --pl.PLDesc  
 ORDER BY prs.INTR, prs.paperrunby --pl.PLDesc  
 OPTION (KEEP PLAN)  
  
 select @SQL =   
 case  
 when (select count(*) from dbo.#LineMachineELP3) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#LineMachineELP3', @LanguageId)  
 end  
  
 EXECUTE sp_executesql @SQL     -- 2005-OCT-26 VMK Rev7.01  
  
  --print 'RS6: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
 -- result set 6  
 -------------------------------------------------------------------------------  
 -- Summarize ELP by Intermediate.  
 -------------------------------------------------------------------------------  
 INSERT INTO dbo.#LineELP3  
 SELECT   
  prs.INTR                                  [Intermediate],  
  ''                                    [Paper Run By],      
  '' [UWS], --Rev7.6  
  SUM((COALESCE(prs.Runtime, 0.0)) - COALESCE(prs.ScheduledDT, 0.0)) / 60.0             [Paper Runtime],  
--Rev7.6   --(COALESCE(prs.UWSTotalDT, 0.0) - COALESCE(prs.CvtrTotalDT, 0.0))) / 60.0  -- 2006-10-29 VMK Rev7.37, modified calc  
  SUM(COALESCE(prs.ELPStops, 0))                          [Paper Stops],  
  SUM(CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)) / 60.0)                  [DT due to Stops],  
  SUM(COALESCE(prs.RLELPDowntime/60.0, 0.0))                          [Eff. DT (Rate Loss)],  
  SUM((CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)) / 60.0) + (COALESCE(prs.RLELPDowntime/60.0, 0.0)))      [Total Paper DT],  
  SUM(CONVERT(FLOAT, prs.FreshStops))                         [Fresh Paper Stops],  
  SUM((CONVERT(FLOAT, COALESCE(prs.FreshDT, 0.0)) / 60.0) + (COALESCE(prs.FreshRLELPDT/60.0, 0.0)))        [Fresh Paper DT],--FLD CapeProb  
  SUM((COALESCE(prs.FreshRuntime, 0.0)) - COALESCE(prs.FreshSchedDT, 0.0)) / 60.0           [Fresh Paper Runtime],  
--Rev7.6   --(COALESCE(prs.UWSFreshDT, 0.0) - COALESCE(prs.CvtrFreshDT, 0.0))) / 60.0  -- 2006-10-29 VMK Rev7.37, modified calc  
  SUM(COALESCE(prs.FreshRolls, 0))                          [Fresh Rolls Ran],  
  SUM(CONVERT(FLOAT, COALESCE(prs.StorageStops, 0)))                    [Storage Paper Stops],  
  SUM((CONVERT(FLOAT, COALESCE(prs.StorageDT, 0.0)) / 60.0) + (COALESCE(prs.StorageRLELPDT/60.0, 0.0)))       [Storage Paper DT],--FLD CapeProb  
  SUM((COALESCE(prs.StorageRuntime, 0.0)) - COALESCE(prs.StorageSchedDT, 0.0)) / 60.0         [Storage Paper Runtime],  
--Rev7.6   --(COALESCE(prs.UWSStorageDT, 0.0) - COALESCE(prs.CvtrStorageDT, 0.0))) / 60.0 -- 2006-10-29 VMK Rev7.37, modified calc  
  SUM(COALESCE(prs.StorageRolls, 0))                          [Storage Rolls Ran],  
  sum(COALESCE(prs.TotalRolls, 0))                          [Total Rolls Ran],  
  CASE WHEN (SUM((COALESCE(prs.FreshRuntime, 0.0) - COALESCE(prs.FreshSchedDT, 0.0))) / 60.0) > 0.0 THEN               -- 2006-09-18 VMK Rev7.34, modified calc  
   (SUM(((CONVERT(FLOAT, COALESCE(prs.FreshDT, 0.0)))/60.0) + COALESCE(prs.FreshRLELPDT/60.0, 0.0)) / --FLD CapeProb  
    (SUM(COALESCE(prs.FreshRuntime, 0.0) - COALESCE(prs.FreshSchedDT, 0.0))/60.0))--   
--Rev7.6     --(COALESCE(prs.UWSFreshDT, 0.0) - COALESCE(prs.CvtrFreshDT, 0.0)))/60.0))  
  ELSE 0.0 END                                  [Fresh ELP%],  
  CASE WHEN (SUM((COALESCE(prs.StorageRuntime, 0.0) - COALESCE(prs.StorageSchedDT, 0.0))) / 60.0) > 0.0 THEN             -- 2006-09-18 VMK Rev7.34, modified calc  
   (SUM(((CONVERT(FLOAT, COALESCE(prs.StorageDT, 0.0)))/60.0) + COALESCE(prs.StorageRLELPDT/60.0, 0.0)) / --FLD CapeProb  
    (SUM(COALESCE(prs.StorageRuntime, 0.0) - COALESCE(prs.StorageSchedDT, 0.0))/60.0)) --   
--Rev7.6     --(COALESCE(prs.UWSStorageDT, 0.0) - COALESCE(prs.CvtrStorageDT, 0.0)))/60.0))  
  ELSE 0.0 END                                  [Storage ELP%],  
  CASE WHEN (SUM((COALESCE(prs.Runtime, 0.0) - COALESCE(prs.ScheduledDT, 0.0))) / 60.0) > 0.0 THEN                 -- 2006-09-18 VMK Rev7.34, modified calc  
   (SUM(((CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)))/60.0) + COALESCE(prs.RLELPDowntime/60.0, 0.0)) /   
    (SUM(COALESCE(prs.Runtime, 0.0) - COALESCE(prs.ScheduledDT, 0.0))/60.0))--   
--Rev7.6     --(COALESCE(prs.UWSTotalDT, 0.0) - COALESCE(prs.CvtrTotalDT, 0.0)))/60.0))  
  ELSE 0.0 END                                  [Total ELP%]       -- 2006-09-18 VMK Rev7.34, modified calc  
 FROM @PRSummaryIntr prs  
 GROUP BY prs.INTR  
 ORDER BY prs.INTR  
 OPTION (KEEP PLAN)  
  
 select @SQL =   
 case  
 when (select count(*) from dbo.#LineELP3) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#LineELP3', @LanguageId)  
 end  
  
 EXECUTE sp_executesql @SQL     -- 2005-OCT-26 VMK Rev7.01  
  
  --print 'RS7: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
 -- result set 7  
 -------------------------------------------------------------------------------  
 -- Total ELP for all Intermediates.  
 -------------------------------------------------------------------------------  
 INSERT INTO dbo.#ReportELP3  
 SELECT   
  ''                                    [Intermediate],  
  ''                                    [Paper Run By],      
  'Overall Totals' [UWS], --Rev7.6  
  SUM((COALESCE(prs.Runtime, 0.0)) - COALESCE(prs.ScheduledDT, 0.0)) / 60.0             [Paper Runtime],  
--Rev7.6   --(COALESCE(prs.UWSTotalDT, 0.0) - COALESCE(prs.CvtrTotalDT, 0.0))) / 60.0  -- 2006-10-29 VMK Rev7.37, modified calc  
  SUM(COALESCE(prs.ELPStops, 0))                          [Paper Stops],  
  SUM(CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)) / 60.0)                  [DT due to Stops],  
  SUM(COALESCE(prs.RLELPDowntime/60.0, 0.0))                          [Eff. DT (Rate Loss)],  
  SUM((CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)) / 60.0) + (COALESCE(prs.RLELPDowntime/60.0, 0.0)))      [Total Paper DT],  
  SUM(CONVERT(FLOAT, prs.FreshStops))                         [Fresh Paper Stops],  
  SUM((CONVERT(FLOAT, COALESCE(prs.FreshDT, 0.0)) / 60.0) + (COALESCE(prs.FreshRLELPDT/60.0, 0.0)))        [Fresh Paper DT],--FLD CapeProb  
  SUM((COALESCE(prs.FreshRuntime, 0.0)) - COALESCE(prs.FreshSchedDT, 0.0)) / 60.0           [Fresh Paper Runtime],  
--Rev7.6   --(COALESCE(prs.UWSFreshDT, 0.0) - COALESCE(prs.CvtrFreshDT, 0.0))) / 60.0  -- 2006-10-29 VMK Rev7.37, modified calc  
  SUM(COALESCE(prs.FreshRolls, 0))                          [Fresh Rolls Ran],  
  SUM(CONVERT(FLOAT, COALESCE(prs.StorageStops, 0)))                    [Storage Paper Stops],  
  SUM((CONVERT(FLOAT, COALESCE(prs.StorageDT, 0.0)) / 60.0) + (COALESCE(prs.StorageRLELPDT/60.0, 0.0)))       [Storage Paper DT], --FLD CapeProb  
  SUM((COALESCE(prs.StorageRuntime, 0.0)) - COALESCE(prs.StorageSchedDT, 0.0)) / 60.0         [Storage Paper Runtime],  
--Rev7.6   --(COALESCE(prs.UWSStorageDT, 0.0) - COALESCE(prs.CvtrStorageDT, 0.0))) / 60.0 -- 2006-10-29 VMK Rev7.37, modified calc  
  SUM(COALESCE(prs.StorageRolls, 0))                          [Storage Rolls Ran],  
  sum(COALESCE(prs.TotalRolls, 0))                          [Total Rolls Ran],  
  CASE WHEN (SUM((COALESCE(prs.FreshRuntime, 0.0) - COALESCE(prs.FreshSchedDT, 0.0))) / 60.0) > 0.0 THEN               -- 2006-09-18 VMK Rev7.34, modified calc  
   (SUM(((CONVERT(FLOAT, COALESCE(prs.FreshDT, 0.0)))/60.0) + COALESCE(prs.FreshRLELPDT/60.0, 0.0)) / --FLD CapeProb  
    (SUM(COALESCE(prs.FreshRuntime, 0.0) - COALESCE(prs.FreshSchedDT, 0.0))/60.0))--   
--Rev7.6     --(COALESCE(prs.UWSFreshDT, 0.0) - COALESCE(prs.CvtrFreshDT, 0.0)))/60.0))  
  ELSE 0.0 END                                  [Fresh ELP%],  
  CASE WHEN (SUM((COALESCE(prs.StorageRuntime, 0.0) - COALESCE(prs.StorageSchedDT, 0.0))) / 60.0) > 0.0 THEN             -- 2006-09-18 VMK Rev7.34, modified calc  
   (SUM(((CONVERT(FLOAT, COALESCE(prs.StorageDT, 0.0)))/60.0) + COALESCE(prs.StorageRLELPDT/60.0, 0.0)) / --FLD CapeProb  
    (SUM(COALESCE(prs.StorageRuntime, 0.0) - COALESCE(prs.StorageSchedDT, 0.0))/60.0)) --   
--Rev7.6     --(COALESCE(prs.UWSStorageDT, 0.0) - COALESCE(prs.CvtrStorageDT, 0.0)))/60.0))  
  ELSE 0.0 END                                  [Storage ELP%],  
  CASE WHEN (SUM((COALESCE(prs.Runtime, 0.0) - COALESCE(prs.ScheduledDT, 0.0))) / 60.0) > 0.0 THEN                 -- 2006-09-18 VMK Rev7.34, modified calc  
   (SUM(((CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)))/60.0) + COALESCE(prs.RLELPDowntime/60.0, 0.0)) /   
    (SUM(COALESCE(prs.Runtime, 0.0) - COALESCE(prs.ScheduledDT, 0.0))/60.0))--   
--Rev7.6     --(COALESCE(prs.UWSTotalDT, 0.0) - COALESCE(prs.CvtrTotalDT, 0.0)))/60.0))  
  ELSE 0.0 END                                  [Total ELP%]       -- 2006-09-18 VMK Rev7.34, modified calc  
 FROM @PRSummaryIntr prs  
 OPTION (KEEP PLAN)  
  
 select @SQL =   
 case  
 when (select count(*) from dbo.#ReportELP3) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#ReportELP3', @LanguageId)  
 end  
  
 EXECUTE sp_executesql @SQL     -- 2005-OCT-26 VMK Rev7.01  
  
  --print 'RS8: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
 -- result set 8  
 -------------------------------------------------------------------------------  
 -- Summarize ELP by PaperMachine, [Paper Run By], and PEIID.  
 -------------------------------------------------------------------------------  
  
 INSERT INTO dbo.#LineMachineELPByUWS2  
 SELECT prs.PaperMachine                              [Paper Machine],  
  prs.PaperRunBy                                [Paper Run By],   -- 2005-APR-21 VMK Rev6.87  
  prs.UWS [UWS], --Rev7.6  
  (CASE WHEN (SUM(COALESCE(prs.Runtime, 0.0)) > DATEDIFF(ss, @StartTime, @EndTime))  
     AND prs.PaperRunBy LIKE '%PP FF%' THEN                                  -- 2006-11-17 VMK Rev7.39, added CASE  
   ((DATEDIFF(ss, @StartTime, @EndTime)) - SUM(COALESCE(prs.ScheduledDT, 0.0))) --   
  ELSE     
   SUM((COALESCE(prs.Runtime, 0.0)) - COALESCE(prs.ScheduledDT, 0.0)) --   
  END) / 60.0                                 [Paper Runtime],        
  SUM(COALESCE(prs.ELPStops, 0))                          [Paper Stops],  
  SUM(CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)) / 60.0)                  [DT due to Stops],  
  SUM(COALESCE(prs.RLELPDowntime/60.0, 0.0))                          [Eff. DT (Rate Loss)],  
  SUM((CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)) / 60.0) + (COALESCE(prs.RLELPDowntime/60.0, 0.0)))      [Total Paper DT],  
  SUM(CONVERT(FLOAT, prs.FreshStops))                         [Fresh Paper Stops],  
  SUM((CONVERT(FLOAT, COALESCE(prs.FreshDT, 0.0)) / 60.0) + (COALESCE(prs.FreshRLELPDT/60.0, 0.0)))        [Fresh Paper DT],--FLD CapeProb  
  SUM((COALESCE(prs.FreshRuntime, 0.0)) - COALESCE(prs.FreshSchedDT, 0.0)) / 60.0           [Fresh Paper Runtime],  
  SUM(COALESCE(prs.FreshRolls, 0))                          [Fresh Rolls Ran],  
  SUM(CONVERT(FLOAT, COALESCE(prs.StorageStops, 0)))                    [Storage Paper Stops],  
  SUM((CONVERT(FLOAT, COALESCE(prs.StorageDT, 0.0)) / 60.0) + (COALESCE(prs.StorageRLELPDT/60.0, 0.0)))       [Storage Paper DT],--FLD CapeProb  
  SUM((COALESCE(prs.StorageRuntime, 0.0)) - COALESCE(prs.StorageSchedDT, 0.0)) / 60.0         [Storage Paper Runtime],  
  SUM(COALESCE(prs.StorageRolls, 0))                          [Storage Rolls Ran],  
  sum(COALESCE(prs.TotalRolls, 0))                          [Total Rolls Ran],  
  
  
  CASE WHEN (SUM((COALESCE(prs.FreshRuntime, 0.0) - COALESCE(prs.FreshSchedDT, 0.0))) / 60.0) > 0.0 THEN               -- 2006-09-18 VMK Rev7.34, modified calc  
     (SUM(((CONVERT(FLOAT, COALESCE(prs.FreshDT, 0.0)))/60.0) + COALESCE(prs.FreshRLELPDT/60.0, 0.0)) /  --FLD CapeProb  
     (SUM(COALESCE(prs.FreshRuntime, 0.0) - COALESCE(prs.FreshSchedDT, 0.0))/60.0))--   
  ELSE 0.0 END                                  [Fresh ELP%],  
  
  
  CASE WHEN (SUM((COALESCE(prs.StorageRuntime, 0.0) - COALESCE(prs.StorageSchedDT, 0.0))) / 60.0) > 0.0 THEN             -- 2006-09-18 VMK Rev7.34, modified calc  
   (SUM(((CONVERT(FLOAT, COALESCE(prs.StorageDT, 0.0)))/60.0) + COALESCE(prs.StorageRLELPDT/60.0, 0.0)) /  --FLD CapeProb  
    (SUM(COALESCE(prs.StorageRuntime, 0.0) - COALESCE(prs.StorageSchedDT, 0.0))/60.0)) --   
  ELSE 0.0 END                                  [Storage ELP%],  
  
  CASE WHEN (SUM((COALESCE(prs.Runtime, 0.0) - COALESCE(prs.ScheduledDT, 0.0))) / 60.0) > 0.0 THEN               -- 2006-09-18 VMK Rev7.34, modified calc  
   CASE WHEN (SUM(COALESCE(prs.Runtime, 0.0)) > DATEDIFF(ss, @StartTime, @EndTime))  
      AND prs.PaperRunBy LIKE '%PP FF%' THEN                                 -- 2006-11-17 VMK Rev7.39, added CASE  
     (SUM(((CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)))/60.0) + COALESCE(prs.RLELPDowntime/60.0, 0.0)) /  
      (((DATEDIFF(ss, @StartTime, @EndTime)) - (SUM(COALESCE(prs.ScheduledDT, 0.0))))/60.0)) --   
   ELSE  
     (SUM(((CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)))/60.0) + COALESCE(prs.RLELPDowntime/60.0, 0.0)) /   
     (SUM(COALESCE(prs.Runtime, 0.0) - COALESCE(prs.ScheduledDT, 0.0))/60.0))--   
   END  
  ELSE 0.0 END                                  [Total ELP%]  
 FROM @PRSummaryUWS prs  
where prs.PaperMachine <> 'NoAssignedPRID'  
 GROUP BY prs.PaperMachine, prs.PaperRunBy, prs.UWS  
 ORDER BY prs.PaperMachine, prs.PaperRunBy, prs.UWS   --prs.PaperSource  --pl.PL_Desc    -- 2005-APR-21 VMK Rev6.87  
 OPTION (KEEP PLAN)  
  
 select @SQL =   
 case  
 when (select count(*) from dbo.#LineMachineELPByUWS2) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from dbo.#LineMachineELPByUWS2) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#LineMachineELPByUWS2', @LanguageId)  
 end  
  
 EXECUTE sp_executesql @SQL     -- 2005-OCT-26 VMK Rev7.01  
  
  
 -------------------------------------------------------------------------------  
 -- Summarize ELP by PaperMachine and [Paper Run By].  
 -------------------------------------------------------------------------------  
  
 INSERT INTO dbo.#LineMachineELP2  
 SELECT prs.PaperMachine                              [Paper Machine],  
  prs.PaperRunBy                                [Paper Run By],   -- 2005-APR-21 VMK Rev6.87  
  '' [UWS], --Rev7.6  
  (CASE WHEN (SUM(COALESCE(prs.Runtime, 0.0)) > DATEDIFF(ss, @StartTime, @EndTime))  
     AND prs.PaperRunBy LIKE '%PP FF%' THEN                                  -- 2006-11-17 VMK Rev7.39, added CASE  
   ((DATEDIFF(ss, @StartTime, @EndTime)) - SUM(COALESCE(prs.ScheduledDT, 0.0))) --   
--Rev7.6     --(COALESCE(prs.UWSTotalDT, 0.0) - COALESCE(prs.CvtrTotalDT, 0.0))))  
  ELSE     
   SUM((COALESCE(prs.Runtime, 0.0)) - COALESCE(prs.ScheduledDT, 0.0)) --   
--Rev7.6    --(COALESCE(prs.UWSTotalDT, 0.0) - COALESCE(prs.CvtrTotalDT, 0.0)))  
  END) / 60.0                                 [Paper Runtime],        
  SUM(COALESCE(prs.ELPStops, 0))                          [Paper Stops],  
  SUM(CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)) / 60.0)                  [DT due to Stops],  
  SUM(COALESCE(prs.RLELPDowntime/60.0, 0.0))                          [Eff. DT (Rate Loss)],  
  SUM((CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)) / 60.0) + (COALESCE(prs.RLELPDowntime/60.0, 0.0)))      [Total Paper DT],  
  SUM(CONVERT(FLOAT, prs.FreshStops))                         [Fresh Paper Stops],  
  SUM((CONVERT(FLOAT, COALESCE(prs.FreshDT, 0.0)) / 60.0) + (COALESCE(prs.FreshRLELPDT/60.0, 0.0)))        [Fresh Paper DT],--FLD CapeProb  
  SUM((COALESCE(prs.FreshRuntime, 0.0)) - COALESCE(prs.FreshSchedDT, 0.0)) / 60.0           [Fresh Paper Runtime],  
--Rev7.6   --(COALESCE(prs.UWSFreshDT, 0.0) - COALESCE(prs.CvtrFreshDT, 0.0))) / 60.0  -- 2006-10-29 VMK Rev7.37, modified calc  
  SUM(COALESCE(prs.FreshRolls, 0))                          [Fresh Rolls Ran],  
  SUM(CONVERT(FLOAT, COALESCE(prs.StorageStops, 0)))                    [Storage Paper Stops],  
  SUM((CONVERT(FLOAT, COALESCE(prs.StorageDT, 0.0)) / 60.0) + (COALESCE(prs.StorageRLELPDT/60.0, 0.0)))       [Storage Paper DT],--FLD CapeProb  
  SUM((COALESCE(prs.StorageRuntime, 0.0)) - COALESCE(prs.StorageSchedDT, 0.0)) / 60.0         [Storage Paper Runtime],  
--Rev7.6   --(COALESCE(prs.UWSStorageDT, 0.0) - COALESCE(prs.CvtrStorageDT, 0.0))) / 60.0 -- 2006-10-29 VMK Rev7.37, modified calc  
  SUM(COALESCE(prs.StorageRolls, 0))                          [Storage Rolls Ran],  
  sum(COALESCE(prs.TotalRolls, 0))                          [Total Rolls Ran],  
  
  
  CASE WHEN (SUM((COALESCE(prs.FreshRuntime, 0.0) - COALESCE(prs.FreshSchedDT, 0.0))) / 60.0) > 0.0 THEN               -- 2006-09-18 VMK Rev7.34, modified calc  
     (SUM(((CONVERT(FLOAT, COALESCE(prs.FreshDT, 0.0)))/60.0) + COALESCE(prs.FreshRLELPDT/60.0, 0.0)) /  --FLD CapeProb  
     (SUM(COALESCE(prs.FreshRuntime, 0.0) - COALESCE(prs.FreshSchedDT, 0.0))/60.0))--   
--Rev7.6      --(COALESCE(prs.UWSFreshDT, 0.0) - COALESCE(prs.CvtrFreshDT, 0)))/60.0))  
  ELSE 0.0 END                                  [Fresh ELP%],  
  
  
  CASE WHEN (SUM((COALESCE(prs.StorageRuntime, 0.0) - COALESCE(prs.StorageSchedDT, 0.0))) / 60.0) > 0.0 THEN             -- 2006-09-18 VMK Rev7.34, modified calc  
   (SUM(((CONVERT(FLOAT, COALESCE(prs.StorageDT, 0.0)))/60.0) + COALESCE(prs.StorageRLELPDT/60.0, 0.0)) /  --FLD CapeProb  
    (SUM(COALESCE(prs.StorageRuntime, 0.0) - COALESCE(prs.StorageSchedDT, 0.0))/60.0)) --   
--Rev7.6     --(COALESCE(prs.UWSStorageDT, 0.0) - COALESCE(prs.CvtrStorageDT, 0.0)))/60.0))  
  ELSE 0.0 END                                  [Storage ELP%],  
  
  CASE WHEN (SUM((COALESCE(prs.Runtime, 0.0) - COALESCE(prs.ScheduledDT, 0.0))) / 60.0) > 0.0 THEN               -- 2006-09-18 VMK Rev7.34, modified calc  
   CASE WHEN (SUM(COALESCE(prs.Runtime, 0.0)) > DATEDIFF(ss, @StartTime, @EndTime))  
      AND prs.PaperRunBy LIKE '%PP FF%' THEN                                 -- 2006-11-17 VMK Rev7.39, added CASE  
     (SUM(((CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)))/60.0) + COALESCE(prs.RLELPDowntime/60.0, 0.0)) /  
      (((DATEDIFF(ss, @StartTime, @EndTime)) - (SUM(COALESCE(prs.ScheduledDT, 0.0))))/60.0)) --   
--Rev7.6             --(COALESCE(prs.UWSTotalDT, 0.0) - COALESCE(prs.CvtrTotalDT, 0.0)))))/60.0))  
   ELSE  
     (SUM(((CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)))/60.0) + COALESCE(prs.RLELPDowntime/60.0, 0.0)) /   
     (SUM(COALESCE(prs.Runtime, 0.0) - COALESCE(prs.ScheduledDT, 0.0))/60.0))--   
--Rev7.6      --(COALESCE(prs.UWSTotalDT, 0.0) - COALESCE(prs.CvtrTotalDT, 0.0)))/60.0))  
   END  
  ELSE 0.0 END                                  [Total ELP%]  
 FROM @PRSummaryPMRunBy prs  
 GROUP BY prs.PaperMachine, prs.PaperRunBy  
 ORDER BY prs.PaperMachine, prs.PaperRunBy   --prs.PaperSource  --pl.PL_Desc    -- 2005-APR-21 VMK Rev6.87  
 OPTION (KEEP PLAN)  
  
 select @SQL =   
 case  
 when (select count(*) from dbo.#LineMachineELP2) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from dbo.#LineMachineELP2) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#LineMachineELP2', @LanguageId)  
 end  
  
 EXECUTE sp_executesql @SQL     -- 2005-OCT-26 VMK Rev7.01  
  
  
  --print 'RS9: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
 -- result set 9  
 -------------------------------------------------------------------------------  
 -- Summarize ELP by PaperMachine  
 -------------------------------------------------------------------------------  
  
 INSERT INTO dbo.#MachineELP2  
 SELECT prs.PaperMachine                              [Paper Machine],  
  ''                                    [Paper Run By],     -- 2005-APR-21 VMK Rev6.87  
  '' [UWS], --Rev7.6  
  SUM((COALESCE(prs.Runtime, 0.0)) - COALESCE(prs.ScheduledDT, 0.0)) / 60.0             [Paper Runtime],   
--Rev7.6   --(COALESCE(prs.UWSTotalDT, 0.0) - COALESCE(prs.CvtrTotalDT, 0.0))) / 60.0  -- 2006-10-29 VMK Rev7.37, modified calc  
  SUM(COALESCE(prs.ELPStops, 0))                          [Paper Stops],  
  SUM(CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)) / 60.0)                  [DT due to Stops],  
  SUM(COALESCE(prs.RLELPDowntime/60.0, 0.0))                          [Eff. DT (Rate Loss)],  
  SUM((CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)) / 60.0) + (COALESCE(prs.RLELPDowntime/60.0, 0.0)))      [Total Paper DT],  
  SUM(CONVERT(FLOAT, prs.FreshStops))                         [Fresh Paper Stops],  
  SUM((CONVERT(FLOAT, COALESCE(prs.FreshDT, 0.0)) / 60.0) + (COALESCE(prs.FreshRLELPDT/60.0, 0.0)))        [Fresh Paper DT], --FLD CapeProb  
  SUM((COALESCE(prs.FreshRuntime, 0.0)) - COALESCE(prs.FreshSchedDT, 0.0)) / 60.0           [Fresh Paper Runtime],  
--Rev7.6   --(COALESCE(prs.UWSFreshDT, 0.0) - COALESCE(prs.CvtrFreshDT, 0.0))) / 60.0  -- 2006-10-29 VMK Rev7.37, modified calc  
  SUM(COALESCE(prs.FreshRolls, 0))                          [Fresh Rolls Ran],  
  SUM(CONVERT(FLOAT, COALESCE(prs.StorageStops, 0)))                    [Storage Paper Stops],  
  SUM((CONVERT(FLOAT, COALESCE(prs.StorageDT, 0.0)) / 60.0) + (COALESCE(prs.StorageRLELPDT/60.0, 0.0)))       [Storage Paper DT], --FLD CapeProb  
  SUM((COALESCE(prs.StorageRuntime, 0.0)) - COALESCE(prs.StorageSchedDT, 0.0)) / 60.0         [Storage Paper Runtime],  
--Rev7.6   --(COALESCE(prs.UWSStorageDT, 0.0) - COALESCE(prs.CvtrStorageDT, 0.0))) / 60.0 -- 2006-10-29 VMK Rev7.37, modified calc  
  SUM(COALESCE(prs.StorageRolls, 0))                          [Storage Rolls Ran],  
  sum(COALESCE(prs.TotalRolls, 0))                          [Total Rolls Ran],  
  CASE WHEN (SUM((COALESCE(prs.FreshRuntime, 0.0) - COALESCE(prs.FreshSchedDT, 0.0))) / 60.0) > 0.0 THEN               -- 2006-09-18 VMK Rev7.34, modified calc  
   (SUM(((CONVERT(FLOAT, COALESCE(prs.FreshDT, 0.0)))/60.0) + COALESCE(prs.FreshRLELPDT/60.0, 0.0)) /  --FLD CapeProb  
    (SUM(COALESCE(prs.FreshRuntime, 0.0) - COALESCE(prs.FreshSchedDT, 0.0))/60.0))--   
--Rev7.6     --(COALESCE(prs.UWSFreshDT, 0.0) - COALESCE(prs.CvtrFreshDT, 0.0)))/60.0))  
  ELSE 0.0 END                                  [Fresh ELP%],  
  CASE WHEN (SUM((COALESCE(prs.StorageRuntime, 0.0) - COALESCE(prs.StorageSchedDT, 0.0))) / 60.0) > 0.0 THEN             -- 2006-09-18 VMK Rev7.34, modified calc  
   (SUM(((CONVERT(FLOAT, COALESCE(prs.StorageDT, 0.0)))/60.0) + COALESCE(prs.StorageRLELPDT/60.0, 0.0)) /  --FLD CapeProb  
    (SUM(COALESCE(prs.StorageRuntime, 0.0) - COALESCE(prs.StorageSchedDT, 0.0))/60.0)) --   
--Rev7.6     --(COALESCE(prs.UWSStorageDT, 0.0) - COALESCE(prs.CvtrStorageDT, 0.0)))/60.0))  
  ELSE 0.0 END                                  [Storage ELP%],  
  CASE WHEN (SUM((COALESCE(prs.Runtime, 0.0) - COALESCE(prs.ScheduledDT, 0.0))) / 60.0) > 0.0 THEN                 -- 2006-09-18 VMK Rev7.34, modified calc  
   (SUM(((CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)))/60.0) + COALESCE(prs.RLELPDowntime/60.0, 0.0)) /   
    (SUM(COALESCE(prs.Runtime, 0.0) - COALESCE(prs.ScheduledDT, 0.0))/60.0))--   
--Rev7.6     --(COALESCE(prs.UWSTotalDT, 0.0) - COALESCE(prs.CvtrTotalDT, 0.0)))/60.0))  
  ELSE 0.0 END                                  [Total ELP%]       -- 2006-09-18 VMK Rev7.34, modified calc  
 FROM @PRSummaryPM prs  
 GROUP BY prs.PaperMachine  
 OPTION (KEEP PLAN)     
   
 select @SQL =   
 case  
 when (select count(*) from dbo.#MachineELP2) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from dbo.#MachineELP2) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#MachineELP2', @LanguageId)  
 end  
  
 EXECUTE sp_executesql @SQL     -- 2005-OCT-26 VMK Rev7.01  
  
  
  --print 'RS10: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
 -- result set 10  
 -------------------------------------------------------------------------------  
 -- Summarize ELP for All Paper Machines.  
 -------------------------------------------------------------------------------  
  
 INSERT INTO dbo.#ReportELP2  
 SELECT ''                                  [Paper Machine],  
  ''                                    [Paper Run By],      -- 2005-APR-21 VMK Rev6.87  
  'Overall Totals' [UWS], --Rev7.6  
  SUM((COALESCE(prs.Runtime, 0.0)) - COALESCE(prs.ScheduledDT, 0.0) -   
   (COALESCE(prs.UWSTotalDT, 0.0) - COALESCE(prs.CvtrTotalDT, 0.0))) / 60.0             [Paper Runtime],      -- 2006-10-29 VMK Rev7.37, modified calc  
  SUM(COALESCE(prs.ELPStops, 0))                          [Paper Stops],  
  SUM(CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)) / 60.0)                  [DT due to Stops],  
  SUM(COALESCE(prs.RLELPDowntime/60.0, 0.0))                          [Eff. DT (Rate Loss)],  
  SUM((CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)) / 60.0) + (COALESCE(prs.RLELPDowntime/60.0, 0.0)))      [Total Paper DT],  
  SUM(CONVERT(FLOAT, prs.FreshStops))                         [Fresh Paper Stops],  
  SUM((CONVERT(FLOAT, COALESCE(prs.FreshDT, 0.0)) / 60.0) + (COALESCE(prs.FreshRLELPDT/60.0, 0.0)))        [Fresh Paper DT],--FLD CapeProb  
  SUM((COALESCE(prs.FreshRuntime, 0.0)) - COALESCE(prs.FreshSchedDT, 0.0)) / 60.0           [Fresh Paper Runtime],  
--Rev7.6   --(COALESCE(prs.UWSFreshDT, 0.0) - COALESCE(prs.CvtrFreshDT, 0.0))) / 60.0  -- 2006-10-29 VMK Rev7.37, modified calc  
  SUM(COALESCE(prs.FreshRolls, 0))                          [Fresh Rolls Ran],  
  SUM(CONVERT(FLOAT, COALESCE(prs.StorageStops, 0)))                    [Storage Paper Stops],  
  SUM((CONVERT(FLOAT, COALESCE(prs.StorageDT, 0.0)) / 60.0) + (COALESCE(prs.StorageRLELPDT/60.0, 0.0)))       [Storage Paper DT], --FLD CapeProb  
  SUM((COALESCE(prs.StorageRuntime, 0.0)) - COALESCE(prs.StorageSchedDT, 0.0)) / 60.0         [Storage Paper Runtime],  
--Rev7.6   --(COALESCE(prs.UWSStorageDT, 0.0) - COALESCE(prs.CvtrStorageDT, 0.0))) / 60.0 -- 2006-10-29 VMK Rev7.37, modified calc  
  SUM(COALESCE(prs.StorageRolls, 0))                          [Storage Rolls Ran],  
  sum(COALESCE(prs.TotalRolls, 0))                          [Total Rolls Ran],  
  CASE WHEN (SUM((COALESCE(prs.FreshRuntime, 0.0) - COALESCE(prs.FreshSchedDT, 0.0))) / 60.0) > 0.0 THEN               -- 2006-09-18 VMK Rev7.34, modified calc  
   (SUM(((CONVERT(FLOAT, COALESCE(prs.FreshDT, 0.0)))/60.0) + COALESCE(prs.FreshRLELPDT/60.0, 0.0)) /  --FLD CapeProb  
    (SUM(COALESCE(prs.FreshRuntime, 0.0) - COALESCE(prs.FreshSchedDT, 0.0))/60.0))--   
--Rev7.6     --(COALESCE(prs.UWSFreshDT, 0.0) - COALESCE(prs.CvtrFreshDT, 0.0)))/60.0))  
  ELSE 0.0 END                                  [Fresh ELP%],  
  CASE WHEN (SUM((COALESCE(prs.StorageRuntime, 0.0) - COALESCE(prs.StorageSchedDT, 0.0))) / 60.0) > 0.0 THEN             -- 2006-09-18 VMK Rev7.34, modified calc  
   (SUM(((CONVERT(FLOAT, COALESCE(prs.StorageDT, 0.0)))/60.0) + COALESCE(prs.StorageRLELPDT/60.0, 0.0)) /  --FLD CapeProb  
    (SUM(COALESCE(prs.StorageRuntime, 0.0) - COALESCE(prs.StorageSchedDT, 0.0))/60.0)) --   
--Rev7.6     --(COALESCE(prs.UWSStorageDT, 0.0) - COALESCE(prs.CvtrStorageDT, 0.0)))/60.0))  
  ELSE 0.0 END                                  [Storage ELP%],  
  CASE WHEN (SUM((COALESCE(prs.Runtime,        0.0) - COALESCE(prs.ScheduledDT,    0.0))) / 60.0) > 0.0 THEN                 -- 2006-09-18 VMK Rev7.34, modified calc  
   (SUM(((CONVERT(FLOAT, COALESCE(prs.ELPDowntime, 0.0)))/60.0) + COALESCE(prs.RLELPDowntime/60.0, 0.0)) /   
    (SUM(COALESCE(prs.Runtime, 0.0) - COALESCE(prs.ScheduledDT, 0.0))/60.0))--   
--Rev7.6     --(COALESCE(prs.UWSTotalDT, 0.0) - COALESCE(prs.CvtrTotalDT, 0.0)))/60.0))  
  ELSE 0.0 END                                  [Total ELP%]       -- 2006-09-18 VMK Rev7.34, modified calc  
 FROM @PRSummaryPM prs  
 OPTION (KEEP PLAN)  
   
   
 select @SQL =   
 case  
 when (select count(*) from dbo.#ReportELP2) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from dbo.#ReportELP2) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else GBDB.dbo.fnLocal_RptTableTranslation('#ReportELP2', @LanguageId)  
 end  
  
 EXECUTE sp_executesql @SQL     -- 2005-OCT-26 VMK Rev7.01  
  
  
  --print 'RS11: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
 -- result set 11  
 -------------------------------------------------------------------------------  
 -- All raw data.  Note that Excel can only handle a maximum of 65536 rows in a  
 -- spreadsheet.  Therefore, we send an error if there are more than that number.  
 -------------------------------------------------------------------------------  
 -------------------------------------------------------------------------------  
 -- If the dataset has more than 65000 records, then send an error message and  
 -- suspend processing.  This is because Excel can not handle more than 65536 rows  
 -- in a spreadsheet.  
 -------------------------------------------------------------------------------  
--Rev7.6  
  INSERT INTO dbo.#Stops  
  SELECT --distinct   
--   tedetid,  
   tpl.PLDesc                      [Production Line],  
   CONVERT(VARCHAR(25), td.StartTime, 101)            [Start Date],  
   CONVERT(VARCHAR(25), td.StartTime, 108)            [Start Time],  
   CONVERT(VARCHAR(25), td.EndTime, 101)             [End Date],  
   CONVERT(VARCHAR(25), td.EndTime, 108)             [End Time],  
   td.ReportDownTime/60.0                  [Total Event Downtime],  
   td.ReportUpTime/60.0                  [Total Event UpTime],  
   td.RawRateloss / 60.0                 [Effective Downtime],  
   pu.PU_Desc                      [Master Unit],  
   loc.PU_Desc                     [Location],  
   er1.Event_Reason_Name                  [RL1Title],  
   er2.Event_Reason_Name                  [RL2Title],  
   tef.TEFault_Name                    [Fault Desc],  
   Comment                       [Comment],  
   td.Crew                       [Team],  
   td.Shift                      [Shift],  
   p.Prod_Code                     [Cvtg Product],             -- 2006-07-10 VMK Rev7.33, added Cvtg  
   p.Prod_Desc                     [Cvtg Product Desc],            -- 2006-07-10 VMK Rev7.33, added Cvtg  
  
--   td.UWS1Parent                     [UWS1 PRID],  
--   td.UWS1GrandParent                   [UWS1 GPRID],  
--   td.UWS2Parent                     [UWS2 PRID],  
--   td.UWS2GrandParent                   [UWS2 GPRID],  
  
   td.UWS1Parent                     [UWS1 PRID],  
   UWS1ParentPM                     [UWS1 PRoll Made By],  
   td.UWS1GrandParent                   [UWS1 GPRID],  
   UWS1GrandParentPM                   [UWS1 GPRoll Made By],  
   td.UWS2Parent                     [UWS2 PRID],  
   UWS2ParentPM                     [UWS2 PRoll Made By],  
   td.UWS2GrandParent                   [UWS2 GPRID],  
   UWS2GrandParentPM                   [UWS2 GPRoll Made By],  
  
   CASE   
   WHEN td.TEDetId = td.PrimaryId   
   THEN 'Primary'  
   ELSE 'Secondary'  
   END                        [Event Type],  
   SubString(erc1.ERC_Desc, CharIndex(Char(58), erc1.ERC_Desc) + 1, 50)  [Schedule],  
   SubString(erc2.ERC_Desc, CharIndex(Char(58), erc2.ERC_Desc) + 1, 50)  [Category],  
   SubString(erc3.ERC_Desc, CharIndex(Char(58), erc3.ERC_Desc) + 1, 50)  [SubSystem],  
   SubString(erc4.ERC_Desc, CharIndex(Char(58), erc4.ERC_Desc) + 1, 50)  [GroupCause],  
   tpu.DelayType                     [Event Location Type],  
   1                         [Total Causes],  
   COALESCE(td.Stops, 0)                  [Total Stops],  
   COALESCE(td.Stops2m, 0)                 [Total Stops < 2 Min],  
   COALESCE(td.StopsMinor, 0)                [Minor Stops],  
   COALESCE(td.StopsELP, 0)                 [ELP Stops],  
   COALESCE(td.ReportELPDowntime, 0.0) / 60.0           [ELP Downtime],   
   CASE    
   WHEN (COALESCE(td.StopsEquipFails, 0) = 1)   
   AND (td.ReportDowntime/60.0 >= 10.0   
   AND td.ReportDowntime/60.0 < 60.0 )  
   THEN 1  
   ELSE 0   
   END                        [Minor Equipment Failures],   
   CASE    
   WHEN (COALESCE(td.StopsEquipFails, 0) = 1)   
   AND (td.ReportDowntime/60.0 >= 60.0   
   AND td.ReportDowntime/60.0 <= 120.0)   
   THEN 1  
   ELSE 0   
   END                        [Moderate Equipment Failures],   
   CASE    
   WHEN (COALESCE(td.StopsEquipFails, 0) = 1)   
   AND (td.ReportDowntime/60.0 > 120.0)  
   THEN 1  
   ELSE 0   
   END                        [Major Equipment Failures],   
   CASE    
   WHEN (COALESCE(td.StopsProcessFailures, 0) = 1)   
   AND (td.ReportDowntime/60.0 >= 10.0   
   AND td.ReportDowntime/60.0 < 60.0 )  
   THEN 1  
   ELSE 0   
   END                        [Minor Process Failures],   
   CASE    
   WHEN (COALESCE(td.StopsProcessFailures, 0) = 1)   
   AND (td.ReportDowntime/60.0 >= 60.0   
   AND td.ReportDowntime/60.0 <= 120.0)   
   THEN 1  
   ELSE 0   
   END                        [Moderate Process Failures],   
   CASE    
   WHEN (COALESCE(td.StopsProcessFailures, 0) = 1)   
   AND (td.ReportDowntime/60.0 > 120.0)  
   THEN 1  
   ELSE 0   
   END                        [Major Process Failures],  
   COALESCE(td.StopsProcessFailures, 0)             [Process Failures],  
   COALESCE(td.StopsBlockedStarved, 0)             [Total Blocked Starved],  
   COALESCE(td.UpTime2m, 0)                 [Total UpTime < 2 Min],   
   td.LineTargetSpeed                   [Line Target Speed],  
   td.LineActualSpeed                   [Line Actual Speed],  
   er3.Event_Reason_Name                  [RL3Title],  
   er4.Event_Reason_Name                  [RL4Title],  
   td.LineStatus                     [Line Status],  
  
   td.UWS1FreshStorage                  [UWS1 Fresh Or Storage],   
   td.UWS2FreshStorage                  [UWS2 Fresh Or Storage],   
  
   CASE    
   WHEN (COALESCE(td.ReportDowntime, 0.0)) > 600   
   AND (COALESCE(td.Stops, 0)) = 1   
   THEN 1   
   ELSE 0   
   END                        [Stop > 10 Min],  
  
   UWS1PMTeam                      [UWS1 PM Team],     
   UWS2PMTeam                      [UWS2 PM Team],     
  
   CONVERT(VARCHAR(25), td.UWS1Timestamp, 101)          [UWS1 Paper Made Day],  
   CONVERT(VARCHAR(25), td.UWS2Timestamp, 101)          [UWS2 Paper Made Day],  
   CONVERT(VARCHAR(25), td.StartTime, 101)           [Paper Converted Day],  
  
   UWS1PMProd                     [UWS1 Pmkg Product Desc],  
   UWS2PMProd                     [UWS2 Pmkg Product Desc]  
  
  FROM dbo.#Delays td WITH(NOLOCK)  
   JOIN  @ProdUnits tpu ON td.PUId = tpu.PUId  
   JOIN  @ProdLines tpl ON tpu.PLId = tpl.PLId  
   JOIN  dbo.Prod_Units pu WITH(NOLOCK) ON td.PUId = pu.PU_Id  
   JOIN  dbo.Products p WITH(NOLOCK) ON td.ProdId = p.Prod_Id  
  
--  from dbo.#ProdLines tpl WITH(NOLOCK)   
--   left  join dbo.#Delays td WITH(NOLOCK) ON td.PLId = tpl.PLId  
--   left  JOIN @ProdUnits tpu ON td.PUId = tpu.PUId  
--   left  JOIN dbo.Prod_Units pu WITH(NOLOCK) ON td.PUId = pu.PU_Id  
--   left  JOIN dbo.Products p WITH(NOLOCK) ON td.ProdId = p.Prod_Id  
  
   LEFT JOIN dbo.Event_Reason_Catagories erc1 WITH(NOLOCK) ON td.ScheduleId = erc1.ERC_Id  
   LEFT JOIN dbo.Event_Reason_Catagories erc2 WITH(NOLOCK) ON td.CategoryId = erc2.ERC_Id  
   LEFT JOIN dbo.Event_Reason_Catagories erc3 WITH(NOLOCK) ON td.SubSystemId = erc3.ERC_Id  
   LEFT JOIN dbo.Event_Reason_Catagories erc4 WITH(NOLOCK) ON td.GroupCauseId = erc4.ERC_Id  
   LEFT JOIN dbo.Prod_Units loc WITH(NOLOCK) ON td.LocationId = loc.PU_Id  
   LEFT JOIN dbo.Event_Reasons er1 WITH(NOLOCK) ON td.L1ReasonId = er1.Event_Reason_Id  
   LEFT JOIN dbo.Event_Reasons er2 WITH(NOLOCK) ON td.L2ReasonId = er2.Event_Reason_Id  
   LEFT JOIN dbo.Event_Reasons er3 WITH(NOLOCK) ON td.L3ReasonId = er3.Event_Reason_Id  
   LEFT JOIN dbo.Event_Reasons er4 WITH(NOLOCK) ON td.L4ReasonId = er4.Event_Reason_Id  
   LEFT  JOIN  dbo.Timed_Event_Fault tef WITH(NOLOCK) on (td.TEFaultID = TEF.TEFault_ID)  
  
  WHERE td.CategoryId = @CatELPId   
  AND td.InRptWindow = 1          -- 2005-APR-07 VMK Rev6.85  
  AND (charindex('|' + td.LineStatus + '|', '|' + @LineStatusList + '|') > 0   -- 2005-DEC-07 VMK Rev7.03  
  OR  @LineStatusList = 'All')  
  ORDER BY pu.PU_Desc, td.StartTime  
--  ORDER BY tpl.PLDesc, CONVERT(VARCHAR(25), td.StartTime, 101)  
  OPTION (KEEP PLAN)  
  
 select @SQL =   
 case  
 when (select count(*) from dbo.#Stops) > 65000 then   
 'select ' + char(39) + @TooMuchDataMsg + char(39) + ' [User Notification Msg]'  
 when (select count(*) from dbo.#Stops) = 0 then   
 'select ' + char(39) + @NoDataMsg + char(39) + ' [User Notification Msg]'  
 else    
  GBDB.dbo.fnLocal_RptTableTranslation('#Stops', @LanguageId)   
 end  
  
 SELECT @SQL = replace(@SQL, char(39) + 'RL1Title' +  char(39), char(39) + @RL1Title + char(39))  
 SELECT @SQL = replace(@SQL, char(39) + 'RL2Title' +  char(39), char(39) + @RL2Title + char(39))  
 SELECT @SQL = replace(@SQL, char(39) + 'RL3Title' +  char(39), char(39) + @RL3Title + char(39))  
 SELECT @SQL = replace(@SQL, char(39) + 'RL4Title' +  char(39), char(39) + @RL4Title + char(39))  
  
 EXECUTE sp_executesql @SQL     -- 2005-OCT-26 VMK Rev7.01  
    
   
 END  -- to the if (select count(*) from @ErrorMessages) > 0 ... ELSE BEGIN  
  
  --print 'RS12: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
 -- result set 2 (Error Messages occurred) or 12 (report ran)  
 -----------------------------------------------------------------------------  
 -- 2005-JUN-17 Vince King Rev6.89  
 -- Result Set containing Report Parameter Values.  This RS is used when  
 -- Report Parameter values are required within the Excel Template.  
 -----------------------------------------------------------------------------  
 SELECT  
  @RptName         [@RptName],  
  @RptTitle        [@RptTitle],  
  @ProdLineList        [@ProdLineList],  
--  @DelayTypeList       [@DelayTypeList],  
  COALESCE(@LineStatusList,'All') [@LineStatusList], --2006-JAN-19 NHK Rev7.08  
  @RL1Title        [@RptRL1Title],  
  @RL2Title        [@RptRL2Title],  
  @RL3Title        [@RptRL3Title],  
  @RL4Title        [@RptRL4Title],  
--  @PackPUIdList       [@PackPUIdList],  
  @UserName        [@RptUser],  
  @RptPageOrientation     [@RptPageOrientation],    
  @RptPageSize       [@RptPageSize],  
  @RptPercentZoom      [@RptPercentZoom],  
  @RptTimeout        [@RptTimeout],  
  @RptFileLocation      [@RptFileLocation],  
  @RptConnectionString     [@RptConnectionString],  
  @RptPmkgOrCvtg       [@RptPmkgOrCvtg]  
  
 -- Result Set 3 (Error Messages Occurred) or 13 (Report Ran)  
  --print 'RS13: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
 -----------------------------------------------------------------------------  
 -- 2006-MAR-28 Vince King Rev7.15  
 -- @prsrun result set to be reported in PRsRun sheet in template.  
 -----------------------------------------------------------------------------  
 SELECT   
  
  EventId             [EventId],  
  SourceId             [SourceId],  
  UWS              [UWS],  
  Input_Order            [Input Order],  
  StartTime            [Proll Conv. StartTime],  
  EndTime             [Proll Conv. EndTime],       
--  DATEDIFF(ss, StartTime, EndTime) / 60.0  [Runtime in Rpt Window (min)],    
  ParentPRID            [PRID], --[ParentPRID],  
  ParentPM             [PRoll Made By], --[ParentPM],  
  ParentTeam            [ParentTeam],  
  PRTimeStamp            [PRoll TimeStamp], --[PRTimeStamp],  
  AgeOfPR             [PRoll Age (days)], --[AgeOfPR],  
  ELPStops             [ELPStops],  
  ELPDT/60.0            [ELP DT (min)], --[ELPDowntime],  
  RLELPDT/60.0           [ELP Rate Loss Eff. DT (min)], --[RatelossELPDowntime],  
  Runtime/60.0           [Raw PRoll Runtime in Rpt Window (min)],     
  ELPSchedDT/60.0          [Scheduled DT (min)], --[ELPScheduledDowntime],  
  PaperRuntime/60.0          [Paper Runtime (min)],   
  LineStatus            [LineStatus],  
  GrandParentPRID          [GPRID], ----[GrandParentPRID],  
  GrandParentPM           [GPRoll Made By], --[GrandParentPM],  
  GrandParentTeam          [GParentTeam], --[GrandParentTeam]  
  PRPUDesc             [Source Event PUDesc]  
--  PUId              [PUId],  
--  PU_Desc             [PUDesc]  
--  prs.PEIId            [PEIId],  
--  PRPUId             [PRPUID],  
--  EventTimestamp           [GrandParentTimestamp],  
--  INTR              [Intr],  
  
 FROM dbo.#prsrun prs  
 --LEFT   
 JOIN dbo.Prod_Units pu WITH(NOLOCK)  
 ON prs.PUId = pu.PU_Id  
 --LEFT   
 JOIN @ProdLines pl   
 ON pu.PL_Id = pl.PLId         
 LEFT JOIN @UWS uws   
 ON prs.PEIId = uws.PEIId  
 ORDER BY UWS, StartTime, EndTime  
  
  
------------------------------------------  
-- Validation tables  
------------------------------------------  
  
--print 'RS14: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
  
------------------------------------------------------------------------------------  
-- these GroupBy tables are used to help show how Parent Rolls info is summarized  
------------------------------------------------------------------------------------  
  
/*  
 EventId           int,  
 [Proll Conv. StartTime]      datetime,  
 [Proll Conv. EndTime]      datetime,  
 [Proll Scheduled DT (mins)]    float,  
 [Proll Paper Runtime (mins)]    float,  
 [GroupBy StartTime]       datetime,  
 [GroupBy EndTime]        datetime,  
 [GroupBy Scheduled DT (mins)]    float,  
 [GroupBy Paper Runtime (mins)]   float,  
 Line            varchar(50),  
 PaperSource          varchar(50),  
 UWS            varchar(50),  
 [Proll Conv. Id_Num]       int,  
 [GroupBy Start ID]       int,  
 [GroupBy End ID]        int  
*/  
  
--insert dbo.#GroupByLinePS  
select --'LinePS',   
 prs.EventId EventID,  
 prs.StartTime [Proll Conv. StartTime],  
 prs.EndTime [Proll Conv. EndTime],  
 prs.ELPSchedDT/60.0 [Proll Scheduled DT (mins)],  
 prs.PaperRuntime/60.0 [Proll Paper Runtime (mins)],  
 prs.StartTimeLinePS [GroupBy StartTime],  
 prs.EndTimeLinePS [GroupBy EndTime],  
 pdm.ELPSchedDTLinePS/60.0 [GroupBy Scheduled DT (mins)],  
-- prs.PaperRuntimeLinePS/60.0,  
 (prs.RuntimeLinePS - pdm.ELPSchedDTLinePS)/60.0 [GroupBy Paper Runtime (mins)],  
 pl.pl_desc Line,  
 prs.PaperSource PaperSource,  
 prs.UWS UWS,  
 prs.Id_Num [Proll Conv. Id_Num],  
 prs.LinePSID1 [GroupBy Start ID],  
 prs.LinePSID2 [GroupBy End ID]  
from dbo.#PRsRun prs  
join prod_lines pl  
on prs.plid = pl.pl_id  
join @PRDTMetrics pdm  
on prs.id_num = pdm.id_num  
order by pl.pl_desc, prs.PaperSource, prs.Id_Num, prs.LinePSID1, prs.LinePSID2,   
   prs.starttimeLinePS, prs.endtimeLinePS, prs.starttime, prs.endtime  
  
--select * from dbo.#GroupByLinePS  
--order by Line, PaperSource, [Proll Conv. Id_Num], [GroupBy Start ID], [GroupBy End ID],   
--   [GroupBy StartTime], [GroupBy EndTime], [Proll Conv. StartTime], [Proll Conv. EndTime]  
  
  
--print 'RS15: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
  
/*  
create table dbo.#GroupByLine   
 (  
 EventId           int,  
 [Proll Conv. StartTime]      datetime,  
 [Proll Conv. EndTime]      datetime,  
 [Proll Scheduled DT (mins)]    float,  
 [Proll Paper Runtime (mins)]    float,  
 [GroupBy StartTime]       datetime,  
 [GroupBy EndTime]        datetime,  
 [GroupBy Scheduled DT (mins)]    float,  
 [GroupBy Paper Runtime (mins)]   float,  
 Line            varchar(50),  
 UWS            varchar(50),  
 [Proll Conv. Id_Num]       int,  
 [GroupBy Start ID]       int,  
 [GroupBy End ID]        int  
 )  
*/  
  
--insert dbo.#GroupByLine  
select --'Line',   
 prs.EventId EventID,  
 prs.StartTime [Proll Conv. StartTime],  
 prs.EndTime [Proll Conv. EndTime],  
 prs.ELPSchedDT/60.0 [Proll Scheduled DT (mins)],  
 prs.PaperRuntime/60.0 [Proll Paper Runtime (mins)],  
 prs.StartTimeLine [GroupBy StartTime],  
 prs.EndTimeLine [GroupBy EndTime],  
 pdm.ELPSchedDTLine/60.0 [GroupBy Scheduled DT (mins)],  
-- prs.PaperRuntimeLine/60.0,  
 (prs.RuntimeLine - pdm.ELPSchedDTLine)/60.0 [GroupBy Paper Runtime (mins)],  
 pl.pl_desc Line,  
 prs.UWS UWS,  
 prs.Id_Num [Proll Conv. Id_Num],  
 prs.LineID1 [GroupBy Start ID],  
 prs.LineID2 [GroupBy End ID]  
from dbo.#PRsRun prs  
join prod_lines pl  
on prs.plid = pl.pl_id  
join @PRDTMetrics pdm  
on prs.id_num = pdm.id_num  
order by pl.pl_desc, prs.Id_Num, prs.LineID1, prs.LineID2,   
   prs.starttimeLine, prs.endtimeLine, prs.starttime, prs.endtime  
  
--select * from dbo.#GroupByLine  
--order by Line, [Proll Conv. Id_Num], [GroupBy Start ID], [GroupBy End ID],   
--   [GroupBy StartTime], [GroupBy EndTime], [Proll Conv. StartTime], [Proll Conv. EndTime]  
  
  
--print 'RS16: ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
  
/*  
create table dbo.#GroupByPMRunBy   
 (  
 EventId           int,  
 [Proll Conv. StartTime]      datetime,  
 [Proll Conv. EndTime]      datetime,  
 [Proll Scheduled DT (mins)]    float,  
 [Proll Paper Runtime (mins)]    float,  
 [GroupBy StartTime]       datetime,  
 [GroupBy EndTime]        datetime,  
 [GroupBy Scheduled DT (mins)]    float,  
 [GroupBy Paper Runtime (mins)]   float,  
 PaperMachine         varchar(50),  
 PaperRunBy          varchar(50),  
 UWS            varchar(50),  
 [Proll Conv. Id_Num]       int,  
 [GroupBy Start ID]       int,  
 [GroupBy End ID]        int  
 )  
*/  
  
--insert dbo.#GroupByPMRunBy  
select --'PMRunBy',   
 prs.EventId EventID,  
 prs.StartTime [Proll Conv. StartTime],  
 prs.EndTime [Proll Conv. EndTime],  
 prs.ELPSchedDT/60.0 [Proll Scheduled DT (mins)],  
 prs.PaperRuntime/60.0 [Proll Paper Runtime (mins)],  
 prs.StartTimePMRunBy [GroupBy StartTime],  
 prs.EndTimePMRunBy [GroupBy EndTime],  
 pdm.ELPSchedDTPMRunBy/60.0 [GroupBy Scheduled DT (mins)],  
-- prs.PaperRuntimePMRunBy/60.0,  
 (prs.RuntimePMRunBy - pdm.ELPSchedDTPMRunBy)/60.0 [GroupBy Paper Runtime (mins)],  
 prs.PaperMachine PaperMachine,  
 prs.PaperRunBy PaperRunBy,  
 prs.UWS UWS,  
 prs.Id_Num [Proll Conv. Id_Num],  
 prs.PMRunByID1 [GroupBy Start ID],  
 prs.PMRunByID2 [GroupBy End ID]  
from dbo.#PRsRun prs  
join @PRDTMetrics pdm  
on prs.id_num = pdm.id_num  
order by prs.PaperMachine, prs.PaperRunBy, prs.Id_Num, prs.PMRunByID1, prs.PMRunByID2,   
   prs.starttimePMRunBy, prs.endtimePMRunBy, prs.starttime, prs.endtime  
  
--select * from dbo.#GroupByPMRunBy  
--order by PaperMachine, PaperRunBy, [Proll Conv. Id_Num], [GroupBy Start ID], [GroupBy End ID],   
--   [GroupBy StartTime], [GroupBy EndTime], [Proll Conv. StartTime], [Proll Conv. EndTime]  
  
  
--print 'drop tables ' + CONVERT(VARCHAR(20), GETDATE(), 120)  
  
Finished:  
  
 DROP TABLE dbo.#Delays  
 DROP  TABLE  dbo.#LineMachineELP  
 DROP  TABLE  dbo.#LineMachineELPByUWS  
 DROP  TABLE  dbo.#LineMachineELPByUWS2  
 DROP  TABLE  dbo.#LineMachineELPByUWS3  
 DROP  TABLE  dbo.#LineELP  
 DROP  TABLE  dbo.#ReportELP  
 DROP  TABLE  dbo.#LineMachineELP2  
 DROP  TABLE  dbo.#MachineELP2  
 DROP  TABLE  dbo.#ReportELP2  
 DROP  TABLE  dbo.#Stops  
 DROP  TABLE  dbo.#LineMachineELP3  
 DROP  TABLE  dbo.#ReportELP3  
 DROP  TABLE  dbo.#LineELP3  
 DROP TABLE dbo.#Events  
-- DROP TABLE dbo.#ProdLines    
 drop  table  dbo.#EventStatusTransitions  
 drop  table  dbo.#PRsRun  
 drop  table dbo.#ESTOutsideWindow  
-- drop  table  dbo.#GroupByLinePS  
-- drop  table  dbo.#GroupByLine  
-- drop  table  dbo.#GroupByPMRunBy  
  
  
SET NOCOUNT OFF  
  
