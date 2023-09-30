CREATE procedure [dbo].[spSDK_AU_EventType_Bak_177]
@AppUserId int,
@Id tinyint OUTPUT,
@AllowDataView tinyint ,
@AllowMultipleActive bit ,
@CommentText varchar(100) ,
@EventModels int ,
@EventType nvarchar(50) ,
@HasSubtypes tinyint ,
@IncludeOnSoe tinyint ,
@IsTimeBased tinyint ,
@IsVariableEventType int ,
@parentetid tinyint ,
@SingleEventConfiguration bit ,
@UserConfigured tinyint ,
@ValidateTestData bit 
AS
Declare
  @Status int,
  @ErrorMsg varchar(500)
  Select @ErrorMsg = 'Object does not support Add/Update.' 
  Select @Status = 0
  -- Call to Import/Export SP goes here
  If (@Status <> 1)
    Select @ErrorMsg
  Return(@Status)
