﻿CREATE procedure [dbo].[spSDK_AU_PropertyType]
@AppUserId int,
@Id int OUTPUT,
@PropertyData int ,
@PropertyType nvarchar(50) 
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