CREATE PROCEDURE dbo.spServer_CalcMgrGetVarInputValue
@AttribType int,
@InputVarId int, 
@InputVarPUId int, 
@ResultVarId int, 
@ResultVarPUId int,
@RunTime datetime, 
@EventId int, 
@TriggeringVarEventId int,
@ResultVarEventType int,
@ResultVarEventSubType int,
@Result nVarChar(255) OUTPUT
AS
Declare
 	 @InputVarEventType int,
 	 @RecordingIdsForResultEventType int,
 	 @RecordingIdsForInputEventType int,
 	 @Status int,
 	 @ErrorMsg nVarChar(255)
Declare @TestData Table (EventId int NULL, Result nVarChar(255) NULL, ResultOn datetime)
Select @Result = NULL
If (@InputVarId Is NULL) Or (@InputVarId = 0)
 	 Return
 	 
Select @InputVarEventType = Event_Type From Variables_Base Where Var_Id = @InputVarId
 	  	  	  	  	 
Select @RecordingIdsForInputEventType = NULL
Select @RecordingIdsForInputEventType = ValidateTestData From Event_Types Where ET_Id = @InputVarEventType
If (@RecordingIdsForInputEventType Is NULL)
 	 Select @RecordingIdsForInputEventType = 0
 	  	  	  	 
If (@ResultVarEventType = @InputVarEventType) 	 
 	 Select @RecordingIdsForResultEventType = @RecordingIdsForInputEventType
Else 	 
 	 Begin 	  	  	  	 
 	  	 Select @RecordingIdsForResultEventType = NULL
 	  	 Select @RecordingIdsForResultEventType = ValidateTestData From Event_Types Where ET_Id = @ResultVarEventType
 	  	 If (@RecordingIdsForResultEventType Is NULL)
 	  	  	 Select @RecordingIdsForResultEventType = 0
 	 End
If (@ResultVarPUId = -100)
 	 Begin
 	  	 Select @ResultVarPUId = NULL
 	  	 If (@EventId Is Not NULL) And (@EventId <> 0)
 	  	  	 Execute @ResultVarPUId = spServer_CmnGetEventPUId @EventId, @ResultVarEventType
 	  	 If (@ResultVarPUId Is NULL)
 	  	  	 Return
 	 End
If (@InputVarPUId = -100)
 	 Select @InputVarPUId = @ResultVarPUId
 	 
If (@AttribType = 7) -- This Value
 	 Begin
 	  	 If (@ResultVarPUId <> @InputVarPUId) Or (@RecordingIdsForInputEventType = 0)
 	  	  	 Select @Result = Result From Tests Where (Var_Id = @InputVarId) and (Result_On = @RunTime) and (Canceled = 0) and (Result Is Not NULL)
 	  	 Else
 	  	  	 If (@EventId Is Not NULL) And (@EventId <> 0) And (@ResultVarEventType = @InputVarEventType)
 	  	  	  	 Select @Result = Result From Tests Where (Var_Id = @InputVarId) and (Event_Id = @EventId) and (Canceled = 0) and (Result Is Not NULL)
 	  	  	 Else
 	  	  	  	 Begin
 	  	  	  	  	 Insert Into @TestData(EventId,Result,ResultOn) Select Event_Id,Result,Result_On from fnServer_CmnGetTestData(@InputVarId,@InputVarPUId,@RunTime,NULL,0,0,0,'=',1,1,0,0,0)
 	  	  	  	  	 Select @Status = NULL
 	  	  	  	  	 Select @Status = EventId, @ErrorMsg = Result From @TestData Where EventId = -1
 	  	  	  	  	 If (@Status Is NULL)
 	  	  	  	  	  	 Select @Result = Result From @TestData
 	  	  	  	 End 	  	  	 
 	 End
 	 
Else If (@AttribType = 8)  -- Last Value
 	 Begin
 	  	 Insert Into @TestData(EventId,Result,ResultOn) Select Event_Id,Result,Result_On from fnServer_CmnGetTestData(@InputVarId,@InputVarPUId,@RunTime,NULL,0,0,0,'<',1,1,0,0,0)
 	  	 Select @Status = NULL
 	  	 Select @Status = EventId, @ErrorMsg = Result From @TestData Where EventId = -1
 	  	 If (@Status Is NULL)
 	  	  	 Select @Result = Result From @TestData
 	 End
 	 
 	 
Else If (@AttribType = 9)  -- Next Value
 	 Begin
 	  	 Insert Into @TestData(EventId,Result,ResultOn) Select Event_Id,Result,Result_On from fnServer_CmnGetTestData(@InputVarId,@InputVarPUId,@RunTime,NULL,0,0,0,'>',1,1,0,0,0)
 	  	 Select @Status = NULL
 	  	 Select @Status = EventId, @ErrorMsg = Result From @TestData Where EventId = -1
 	  	 If (@Status Is NULL)
 	  	  	 Select @Result = Result From @TestData
 	 End 
