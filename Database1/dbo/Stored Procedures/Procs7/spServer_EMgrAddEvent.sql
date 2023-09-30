CREATE PROCEDURE dbo.spServer_EMgrAddEvent
@PU_Id int,
@Event_Num nVarChar(50),
@TimeStamp datetime,
@Event_Status int,
@SourceEvent int,
@AppProdId int,
@Success int OUTPUT,
@Event_Id int OUTPUT
 AS
Declare
  @Result int,
  @TheTimeStamp datetime,
  @TheSourceEvent int,
  @TheAppProdId int
If @SourceEvent <> 0 
  Select @TheSourceEvent = @SourceEvent
Else
  Select @TheSourceEvent = NULL
If @AppProdId <> 0 
  Select @TheAppProdId = @AppProdId
Else
  Select @TheAppProdId = NULL
Select @Success = 0
Select @TheTimeStamp = @TimeStamp
Execute @Result = spServer_DBMgrUpdEvent 
 	 @Event_Id OUTPUT,
 	 @Event_Num,
 	 @PU_Id,
 	 @TheTimeStamp,
 	 @TheAppProdId,
 	 @TheSourceEvent,
 	 @Event_Status,
 	 1,
 	 0,NULL,NULL,NULL,NULL,NULL,NULL,0
If @Result = 1
  Select @Success = 1
