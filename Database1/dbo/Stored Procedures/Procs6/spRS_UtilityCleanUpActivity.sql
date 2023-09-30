CREATE PROCEDURE [dbo].[spRS_UtilityCleanUpActivity]
 AS
--------------------------
-- LOCAL VARS
--------------------------
Declare @BackDate datetime
Declare @Days int -- this comes from site_parameters table
Declare @Now DateTime
Set @Now = dbo.fnServer_CmnGetDate(GetUtcDate())
---------------------------------------------
-- Determine how many days to go back in time
-- If it is not in the Site_Parameters table
-- go back 45 days
---------------------------------------------
Select @Days = Convert(int, Value) From Site_Parameters Where Parm_Id = 315
If @Days Is Null
  Select @Days = 10
Print 'Purging LogFiles Older Than ' + convert(varchar(2), @Days) + ' Days.'
--------------------
-- Get the back date
--------------------
Select @BackDate = DateAdd(d, -@Days, @Now)
-----------------------------------------
-- Delete every thing from that date back
-----------------------------------------
Delete from report_runs where start_time < @BackDate
Delete from report_Engine_Activity where time < @BackDate
