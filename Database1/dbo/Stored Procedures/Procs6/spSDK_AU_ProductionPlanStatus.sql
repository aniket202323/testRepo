CREATE procedure [dbo].[spSDK_AU_ProductionPlanStatus]
@AppUserId int,
@Id int OUTPUT,
@AllowEdit tinyint ,
@Color varchar(100) ,
@ColorId int ,
@Movable bit ,
@ProductionPlanStatus varchar(100) 
AS
DECLARE @OldDesc 	  	  	  	  	 Varchar(50)
IF @Id IS NULL
BEGIN
 	 IF EXISTS(SELECT 1 FROM Production_Plan_Statuses WHERE PP_Status_Desc = @ProductionPlanStatus)
 	 BEGIN
 	  	 SELECT 'Production Plan Status already exists can not create'
 	  	 RETURN(-100)
 	 END
 	 Execute spEM_CreateScheduleStatus @ProductionPlanStatus, @AppUserId, @Id Output
 	 IF @Id Is NULL
 	 BEGIN
 	  	 SELECT 'Production Plan Status failed to create'
 	  	 RETURN(-100)
 	 END
END
ELSE
BEGIN
 	 IF NOT EXISTS(SELECT 1 FROM Production_Plan_Statuses WHERE PP_Status_Id = @Id)
 	 BEGIN
 	  	 SELECT 'Production Plan Status not found for update'
 	  	 RETURN(-100)
 	 END
 	 SELECT @OldDesc = PP_Status_Desc  FROM Production_Plan_Statuses WHERE PP_Status_Id = @Id
 	 IF @OldDesc <> @ProductionPlanStatus
 	 BEGIN
 	  	 EXECUTE spEM_RenameScheduleStatus @Id, @ProductionPlanStatus,@AppUserId
 	 END
END
EXECUTE spEM_SetScheduleStatusColor @Id,@ColorId,@AppUserId
EXECUTE spEM_SetScheduleStatusEditable @Id,@AllowEdit,@AppUserId
EXECUTE spEM_SetScheduleStatusMovable @Id,@AllowEdit,@AppUserId
Return(1)
