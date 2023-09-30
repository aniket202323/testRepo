CREATE PROCEDURE [dbo].[spServer_PR2PRReadAfter]
@TriggeringEventPUId int,
@VarId nVarChar(1000),
@Timestamp datetime,
@NumValues int,
@IncludeExact int = 1,
@HonorRejects int = 0
AS
Declare
  @ActualVarId int,
  @Status int,
  @ErrorMsg nVarChar(255)
 	 
Declare @VarData Table(Event_Id int null , Result_On datetime, Result nVarChar(255) null)
If (IsNumeric(@VarId) = 1)
  Select @ActualVarId = Convert(int,@VarId)
Else
  Begin
    Execute @Status = spServer_CmnDecodeVarId @VarId, @ActualVarId output
    If (@Status <> 0)
      return
  End
If (@IncludeExact = 1)
 	 Insert Into @VarData(Event_Id,Result,Result_On) Select Event_Id,Result,Result_On from fnServer_CmnGetTestData(@ActualVarId,@TriggeringEventPUId,@Timestamp,NULL,NULL,NULL,@HonorRejects,'>=',@NumValues,1,0,0,0)
Else
 	 Insert Into @VarData(Event_Id,Result,Result_On) Select Event_Id,Result,Result_On from fnServer_CmnGetTestData(@ActualVarId,@TriggeringEventPUId,@Timestamp,NULL,NULL,NULL,@HonorRejects,'>', @NumValues,1,0,0,0)
Select @Status = NULL
Select @Status = Event_Id, @ErrorMsg = Result From @VarData Where Event_Id = -1
If (@Status Is NULL)
 	 Select @Status = 1
Else
 	 Select @Status = 0
If (@Status <> 1)
 	 Return(0)
Select Result_On, Result, 'Good' from @VarData Order By Result_On 
Return(1) 	 
