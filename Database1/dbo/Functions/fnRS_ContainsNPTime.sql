CREATE FUNCTION [dbo].[fnRS_ContainsNPTime](
 	  @UnitId Int,     
     @Timestamp DateTime,
     @EndTime DateTime)
RETURNS @NonProductiveTime TABLE(IsNPT TinyInt, TimeRangeSeconds Real, NonProductiveSeconds Real, Start_Time datetime, End_Time datetime)
AS
BEGIN
Declare @IsNPT TinyInt, @TimeRangeSeconds Real, @NonProductiveSeconds Real, @New_Start_Time datetime, @New_End_Time datetime
Select @IsNPT = 0, @TimeRangeSeconds=0, @NonProductiveSeconds=0, @New_Start_Time = @Timestamp, @New_End_Time = @EndTime
If @EndTime Is Null
 	 Begin
 	  	 --? what should be returned for timestamps here?
 	  	 -- Single TimeStamp Contained Within A Non-Productive Time
 	  	 Select @NonProductiveSeconds = DateDiff(Second, Start_Time, End_Time), @New_Start_Time=@Timestamp, @New_End_Time=Null
          From NonProductive_Detail nptd
 	  	   Where nptd.PU_Id = @UnitId
 	  	   And (@Timestamp Between Start_Time and End_Time) And @EndTime is null
        If @NonProductiveSeconds > 0 
          Begin
            Select @IsNPT = 1
 	  	     goto EndOfProc
          End        
 	 End
Else
 	 Begin
 	  	 Select @TimeRangeSeconds = DateDiff(Second, @Timestamp, @EndTime)
 	  	 -- Time Range Contained Within A Non-Productive Time
 	  	 Select @NonProductiveSeconds = DateDiff(Second, Start_Time, End_Time), @New_Start_Time=@Timestamp, @New_End_Time=@EndTime
 	  	   From NonProductive_Detail nptd
 	  	   Where nptd.PU_Id = @UnitId
 	  	   And (@Timestamp Between Start_Time and End_Time) And @EndTime Between Start_Time and End_Time
        If @NonProductiveSeconds > 0 
          Begin
 	  	     Select @IsNPT = 1
 	  	     goto EndOfProc
          End
 	  	 -- Time Range Overlaps The Beginning Of A Non-Productive Time
 	  	 Select @NonProductiveSeconds = DateDiff(Second, Start_Time, @EndTime), @New_Start_Time=@Timestamp, @New_End_Time=Start_Time
 	  	   From NonProductive_Detail nptd
 	  	   Where nptd.PU_Id = @UnitId
          And (@Timestamp < Start_Time)
 	  	   And (@EndTime Between Start_Time and End_Time)
        If @NonProductiveSeconds > 0 
          Begin
 	  	  	 Select @IsNPT = 2
 	  	     goto EndOfProc
          End
 	  	 -- Time Range Overlaps The Ending Of A Non-Productive Time
 	  	 Select @NonProductiveSeconds = DateDiff(Second, @Timestamp, End_Time), @New_Start_Time=End_Time, @New_End_Time=@EndTime 
 	  	   From NonProductive_Detail nptd
 	  	   Where nptd.PU_Id = @UnitId
          And (@Timestamp Between Start_Time and End_Time) And @EndTime > End_Time
        If @NonProductiveSeconds > 0 
          Begin
 	  	  	 Select @IsNPT = 3
 	  	     goto EndOfProc
          End
 	  	 Select @NonProductiveSeconds = DateDiff(Second, Start_Time, End_Time), @New_Start_Time=@Timestamp, @New_End_Time=@EndTime
 	  	   From NonProductive_Detail nptd
 	  	   Where nptd.PU_Id = @UnitId
 	  	   And (@Timestamp <= Start_Time) And (@EndTime >= End_Time)
        If @NonProductiveSeconds > 0 
          Begin
 	  	     Select @IsNPT = 4
 	  	     goto EndOfProc
          End
 	 End
EndOfProc:
   INSERT @NonProductiveTime(IsNPT, TimeRangeSeconds, NonProductiveSeconds, Start_Time, End_Time)
 	 select @IsNPT, @TimeRangeSeconds, @NonProductiveSeconds, @New_Start_Time, @New_End_Time
return
END
