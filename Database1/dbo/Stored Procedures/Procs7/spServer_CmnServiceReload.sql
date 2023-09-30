CREATE PROCEDURE dbo.spServer_CmnServiceReload
@Service_Desc nvarchar(50),
@Reload_Flag int OUTPUT,
@Year int OUTPUT,
@Month int OUTPUT,
@Day int OUTPUT,
@Hour int OUTPUT,
@Minute int OUTPUT,
@Second int OUTPUT
 AS
Declare 
  @CurrentTime datetime
Select @Second = 0
Select 	 @Reload_Flag = Reload_Flag,
 	 @Year = DatePart(Year,Time_Stamp),
 	 @Month = DatePart(Month,Time_Stamp),
 	 @Day = DatePart(Day,Time_Stamp),
 	 @Hour = DatePart(Hour,Time_Stamp),
 	 @Minute = DatePart(Minute,Time_Stamp)
 	 From CXS_Service
 	 Where (Service_Desc = @Service_Desc)
If @Reload_Flag Is Null
  Select @Reload_Flag = 0
If @Year Is Null
Begin
  Select @CurrentTime = dbo.fnServer_CmnGetDate(GetUTCDate())
  Select @Year = DatePart(Year,@CurrentTime)
  Select @Month = DatePart(Month,@CurrentTime)
  Select @Day = DatePart(Day,@CurrentTime)
  Select @Hour = 0
  Select @Minute = 0 
End
Update CXS_Service Set Reload_Flag = NULL, Time_Stamp = NULL
 	 Where (Service_Desc = @Service_Desc)
