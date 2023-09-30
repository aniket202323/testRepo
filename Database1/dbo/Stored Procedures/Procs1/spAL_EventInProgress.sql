Create Procedure dbo.spAL_EventInProgress
@EventId int,
@IsInProgress tinyint OUTPUT
AS
Select @IsInProgress = 0
If (Select Count(Event_Id) From PrdExec_Input_Event Where Event_Id = @EventId) > 0
  Begin 
    Select @IsInProgress = 1
  End
return(0)
