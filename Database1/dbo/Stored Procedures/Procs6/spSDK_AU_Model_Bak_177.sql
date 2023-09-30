CREATE procedure [dbo].[spSDK_AU_Model_Bak_177]
@AppUserId int,
@Id int OUTPUT,
@AllowDerived bit ,
@CommentId int OUTPUT,
@CommentText text ,
@DerivedFrom int ,
@EventType varchar(100) ,
@EventTypeId int ,
@InstalledOn datetime ,
@IntervalBased bit ,
@IsActive bit ,
@Locked bit ,
@Model varchar(100) ,
@ModelNumber int ,
@ModelVersion varchar(20) ,
@NumFields int ,
@OverrideModuleId bit ,
@ServerVersion varchar(20) ,
@UserDefined bit 
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
