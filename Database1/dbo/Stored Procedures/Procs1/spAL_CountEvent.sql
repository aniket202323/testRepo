Create Procedure dbo.spAL_CountEvent
@EventNum nvarchar(50),
@TimeStamp datetime,
@UnitId int,
@CType tinyint,
@Count tinyint OUTPUT
AS
if @Ctype = 1
  begin
    --Search For EventNum
    Select @Count = count(event_id)
      From Events 
      Where pu_id = @UnitId and
            event_num = @EventNum
  end 
else
  begin
    --Search For TimeStamp
    Select @Count = count(event_id)
      From Events 
      Where pu_id = @UnitId and
            timestamp = @TimeStamp
  end
return(100)
