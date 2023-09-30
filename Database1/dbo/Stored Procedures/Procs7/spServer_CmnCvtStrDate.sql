CREATE PROCEDURE dbo.spServer_CmnCvtStrDate
@TimeStamp nVarChar(30),
@TYear int OUTPUT,
@TMonth int OUTPUT,
@TDay int OUTPUT,
@THour int OUTPUT,
@TMin int OUTPUT,
@TSec int OUTPUT
 AS
Declare
  @TheTime Datetime
Select @TheTime = @TimeStamp
Select @TYear = Datepart(Year,@TheTime)
Select @TMonth = Datepart(Month,@TheTime)
Select @TDay = Datepart(Day,@TheTime)
Select @THour = Datepart(Hour,@TheTime)
Select @TMin = Datepart(Minute,@TheTime)
Select @TSec = Datepart(Second,@TheTime)
