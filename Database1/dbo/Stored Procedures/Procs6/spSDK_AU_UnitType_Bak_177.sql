﻿CREATE procedure [dbo].[spSDK_AU_UnitType_Bak_177]
@AppUserId int,
@Id int OUTPUT,
@Icon varchar(100) ,
@IconId int ,
@UnitType varchar(100) ,
@UsesLocations bit ,
@UsesProduction bit 
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
