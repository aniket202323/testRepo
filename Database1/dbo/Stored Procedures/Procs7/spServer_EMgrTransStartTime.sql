CREATE PROCEDURE dbo.spServer_EMgrTransStartTime
@PU_Id int,
@Event_Status int,
@StartYear int OUTPUT,
@StartMonth int OUTPUT,
@StartDay int OUTPUT,
@StartHour int OUTPUT
 AS
Declare
  @StartingTime DateTime
Select @StartingTime = Min(Entry_On)
  From Events
  Where (PU_Id = @PU_Id) And
        (Event_Status = @Event_Status)
If @StartingTime Is Null
  Select @StartingTime = dbo.fnServer_CmnGetDate(GetUTCDate())
Select @StartingTime = DateAdd(Minute,-30,@StartingTime)
Select @StartYear = DatePart(Year,@StartingTime)
Select @StartMonth = DatePart(Month,@StartingTime)
Select @StartDay = DatePart(Day,@StartingTime)
Select @StartHour = DatePart(Hour,@StartingTime)
