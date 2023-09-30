-------------------------------------------------------------------------------
-- Desc:
-- This stored procedure returns looks up a sql string that matches @PrmRRDId and
-- returns a date
-- Edit History:
-- DS 9-25-03 Copied the guts of this sp and moved them into spRS_GetTimeOptions.
--            spCmn_GetRelativeDate now acts as a shell to spRS_GetTimeOptions and will
-- 	  	  	   return data in output parameters exactly as it had done before in order
-- 	  	  	   to keep backward compatibility.  The source code for spRS_GetTimeOptions
-- 	  	  	   is in VSS/$/Proficy/Applications/EIS/WWW/ReportServer_Web/Stored Procedures
--
-- RP 12-Mar-2002 MSI Change Drop Table #BaseDate to Truncate Table #BaseDate. 
-- RP 26-Sep-2002 MSI Added @ShiftInterval 
-- AM 04-Apr-2003 MSI resolved issue with negative @EndOfDayHour, @EndOfDayMinute
-- AM 04-Apr-2003 MSI Added @ShiftOffset
-- AM 08-Apr-2003 MSI Modified to implement @ShiftOffset as a time interval in minutes between midnight and 1st shift start.
-- 	  	  	  	  	  	  	  Can be positive or negative.
-- Sample Exec statement
/*
DECLARE 	 @StartTimeStamp DateTime,
 	 @EndTimeStamp 	 DateTime
EXEC 	 spCmn_GetRelativeDate
 	 4,
 	 @StartTimeStamp OUTPUT,
 	 @EndTimeStamp OUTPUT
SELECT  	 @StartTimeStamp, @EndTimeStamp
*/
-------------------------------------------------------------------------------
CREATE PROCEDURE dbo.spCmn_GetRelativeDate
 	 @PrmRRDId 	  	 Int,
 	 @StartTimeStamp 	 DateTime 	 OUTPUT,
 	 @EndTimeStamp 	 DateTime 	 OUTPUT
AS
Declare @Date_Type_Id int
Create table #tt(
  RRD_Id int,
  Date_Type_Id int,
  Description varchar(100),
  Start_Time varchar(30),
  End_Time varchar(30)
)
Set NoCount On
-- Determine what type I'm working with
Select @Date_Type_Id = Date_Type_Id From Report_Relative_Dates RRD Where RRD.RRD_Id = @PrmRRDId
-- Call spRS_GetTimeOptions to get the correct timestamp
Insert Into #tt Exec spRS_GetTimeOptions @PrmRRDId
-- Shove the timestamp value into the correct output parameter
-- Per Vancouver Request: for types 1 and 2, always put the result into the StartTimeStamp field
if @Date_Type_Id = 1
  Begin
 	 Select @StartTimeStamp = Convert(DateTime,Start_Time) From #tt Where #tt.RRD_Id = @PrmRRDId
  End
if @Date_Type_Id = 2
  Begin
 	 Select @StartTimeStamp = Convert(DateTime,End_Time) From #tt Where #tt.RRD_Id = @PrmRRDId
  End
if @Date_Type_Id = 3
  Begin
 	 Select @StartTimeStamp = Convert(DateTime,Start_Time), @EndTimeStamp = Convert(DateTime,End_Time) From #tt Where #tt.RRD_Id = @PrmRRDId
  End
drop table #tt
