CREATE FUNCTION dbo.fnRS_GetScheduleReportDesc
(@Interval int,
@Daily nvarchar(50),
@Monthly nvarchar(50),
@Start_Date_Time datetime)
Returns nvarchar(2000)
AS
BEGIN
Declare @Weekly nvarchar(255) 	  	 -- Report_Schedule Weekly Field
Declare @StartDate nvarchar(10) 	  	 -- DatePart of @Start_Date_Time
Declare @StartTime nvarchar(10) 	  	 -- TimePart of @Start_Date_Time
Declare @Desc nvarchar(2000)
---------------------------------------
-- Separate Start Date From Start Time
-- Monthly could be numeric or text = (First, Second, Third, Fourth, Last)
---------------------------------------
If @Monthly Is Null
 	 Select @StartDate = convert(nvarchar(10), DatePart(yyyy, @Start_Date_Time)) + '-' + convert(nvarchar(10), DatePart(mm, @Start_Date_Time)) + '-' + convert(nvarchar(10), DatePart(dd, @Start_Date_Time))
Else
 	 If (ISNUMERIC(@Monthly) = 1) 
 	  	 Select @StartDate = convert(nvarchar(10), DatePart(yyyy, @Start_Date_Time)) + '-' + convert(nvarchar(10), DatePart(mm, @Start_Date_Time)) + '-' + @Monthly
 	 Else
 	  	 Select @StartDate = convert(nvarchar(10), DatePart(yyyy, @Start_Date_Time)) + '-' + convert(nvarchar(10), DatePart(mm, @Start_Date_Time)) + '-' + convert(nvarchar(10), DatePart(dd, @Start_Date_Time))
-- Get the time that the report is scheduled to execute
If (DatePart(mi, @Start_Date_Time)) < 10 
 	 Select @StartTime = convert(nvarchar(10), DatePart(hh, @Start_Date_Time)) + ':0' + convert(nvarchar(10), DatePart(mi, @Start_Date_Time)) 
Else
 	 Select @StartTime = convert(nvarchar(10), DatePart(hh, @Start_Date_Time)) + ':' + convert(nvarchar(10), DatePart(mi, @Start_Date_Time)) 
--===============================
-- Minute/Hourly
--===============================
If @Interval Is Not Null
  Begin
 	 If (Convert(int, @Interval) = 1440) 
 	  	 Select @Desc = 'This Is An Interval Report And Will Run Every Day At ' + @StartTime
 	 Else
 	  	 Select @Desc = 'This Is An Interval Report And Will Run Every ' + convert(nvarchar(5), @Interval) + ' Minutes Beginning At ' + @StartTime
 	 End
--===============================
-- Monthly Report
--===============================
Else If @Monthly Is Not Null
  Begin
 	 
 	 -- is monthly numeric?
 	 If (ISNUMERIC(@Monthly) = 1) 
 	   Begin
 	  	 Select @Desc = 'This Is A Monthly Report And Will Run On Day ' + @Monthly + ' Of Every Month At ' + @StartTime --+ ' Beginning ' + @StartDate
 	   End
 	 Else
 	   Begin
 	  	 Select @Desc = 'This Is A Monthly Report And Will Run Every ' + @Monthly + ' ' + @Daily + ' At ' + @StartTime
 	  	 
 	   End
   End
--===============================
-- Weekly
--===============================
Else If @Daily Is Not Null
  Begin
 	 Select @Desc = 'This Is A Daily Report And Will Run Every ' + @Daily + ' At ' + @StartTime -- + ' Beginning ' + @StartDate
  End
RETURN @Desc
END
