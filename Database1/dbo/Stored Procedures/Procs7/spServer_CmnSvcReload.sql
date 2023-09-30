CREATE PROCEDURE dbo.spServer_CmnSvcReload
@Service_Desc nvarchar(50),
@UserId int,
@HostName nVarChar(50),
@Reload_Flag int OUTPUT,
@FullLogging_Flag int OUTPUT,
@IsAlive_Flag int OUTPUT,
@DebugMode_Flag int OUTPUT,
@Year int OUTPUT,
@Month int OUTPUT,
@Day int OUTPUT,
@Hour int OUTPUT,
@Minute int OUTPUT,
@Second int OUTPUT
 AS
Declare 
  @CurrentTime datetime,
  @Value nVarChar(50),
  @DoUpdate int
Select @CurrentTime = dbo.fnServer_CmnGetDate(GetUTCDate())
Update CXS_Service Set Reload_Flag = 2,Should_Reload_Timestamp = Null
 	 Where Reload_Flag is null and Should_Reload_Timestamp < @CurrentTime
select @DoUpdate = 1
Select @Second = 0
Select 	 @Reload_Flag = Reload_Flag,
 	 @Year = DatePart(Year,Time_Stamp),
 	 @Month = DatePart(Month,Time_Stamp),
 	 @Day = DatePart(Day,Time_Stamp),
 	 @Hour = DatePart(Hour,Time_Stamp),
 	 @Minute = DatePart(Minute,Time_Stamp)
 	 From CXS_Service
 	 Where (Service_Desc = @Service_Desc and Node_Name = @HostName)
If @Reload_Flag Is Null and @Year is null
  select @DoUpdate = 0
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
if @DoUpdate = 1
  Update CXS_Service Set Reload_Flag = NULL, Time_Stamp = NULL
   	 Where (Service_Desc = @Service_Desc and Node_Name = @HostName)
select @Value = Null
exec spServer_CmnGetParameter 123, @UserId, @HostName, @Value OUTPUT
if @Value is null or @value = '0'
   select @IsAlive_Flag = 0
else
   select @IsAlive_Flag = 1
select @Value = Null
exec spServer_CmnGetParameter 100, @UserId, @HostName, @Value OUTPUT
if @Value is null or @value = '0'
   select @FullLogging_Flag = 0
else
   select @FullLogging_Flag = 1
select @Value = Null
exec spServer_CmnGetParameter 112, @UserId, @HostName, @Value OUTPUT
if @Value is null or @value = '0'
   select @DebugMode_Flag = 0
else
   select @DebugMode_Flag = @value
