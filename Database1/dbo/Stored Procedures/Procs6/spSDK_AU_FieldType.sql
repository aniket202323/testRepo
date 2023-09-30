CREATE procedure [dbo].[spSDK_AU_FieldType]
@AppUserId int,
@Id int OUTPUT,
@Extension varchar(100) ,
@FieldType varchar(100) ,
@Prefix varchar(100) ,
@SPLookup tinyint ,
@StoreId tinyint ,
@UserDefinedProperty tinyint 
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
