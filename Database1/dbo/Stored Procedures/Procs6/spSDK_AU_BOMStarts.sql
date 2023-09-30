CREATE procedure [dbo].[spSDK_AU_BOMStarts]
@AppUserId int,
@Id int OUTPUT,
@BOMFormulation varchar(100) ,
@BOMFormulationId bigint ,
@Department varchar(200) ,
@DepartmentId int ,
@EndTime datetime ,
@ProductionLine nvarchar(50) ,
@ProductionLineId int ,
@ProductionUnit nvarchar(50) ,
@ProductionUnitId int ,
@StartTime datetime ,
@UserId int ,
@Username varchar(100) 
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
