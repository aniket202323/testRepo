CREATE PROCEDURE dbo.spServer_EMgrGetMaxNonTempTime
@PU_Id int,
@Success int OUTPUT,
@TYear int OUTPUT,
@TMonth int OUTPUT,
@TDay int OUTPUT,
@THour int OUTPUT,
@TMin int OUTPUT
 AS
Declare
  @TimeStamp Datetime
Select @Success = 0
Select @TimeStamp = TimeStamp 
  From Events
  Where (PU_Id = @PU_Id) And
        (TimeStamp = (Select Max(TimeStamp) 
                        From Events 
                        Where (PU_Id = @PU_Id) And 
                              (Event_Status Is Not Null) And
                              (Event_Status Not In (1,2,3,4))))
If (@TimeStamp Is Null)
  Return
Select @TYear = DatePart(Year,@TimeStamp)  
Select @TMonth = DatePart(Month,@TimeStamp)  
Select @TDay = DatePart(Day,@TimeStamp)  
Select @THour = DatePart(Hour,@TimeStamp)  
Select @TMin = DatePart(Minute,@TimeStamp)  
Select @Success = 1
