CREATE procedure [dbo].[spSDK_AU_PathStatusTransition_Bak_177]
 	 @AppUserId int,
 	 @Id int OUTPUT,
 	 @FromPPStatus varchar(50),
 	 @FromPPStatusId int,
 	 @ToPPStatus varchar(50),
 	 @ToPPStatusId int,
 	 @PathCode varchar(50),
 	 @PathId int,
 	 @ParentProductionPlan varchar(50),
 	 @ParentProductionPlanId int
AS
Declare @OldDesc VarChar(100)
IF @Id Is NOT Null
BEGIN
 	 IF Not Exists(SELECT 1 FROM Production_Plan_Status WHERE PPS_Id = @Id)
 	 BEGIN
 	  	 SELECT 'Production Plan Status Transition not found for update'
 	  	 RETURN(-100)
 	 END
 	 UPDATE Production_Plan_Status SET From_PPStatus_Id =@FromPPStatusId,To_PPStatus_Id = @ToPPStatusId,Parent_PP_Id=@ParentProductionPlanId 
 	  	 WHERE PPS_Id = @Id
END
ELSE
BEGIN
 	 IF Exists(SELECT 1 FROM Production_Plan_Status WHERE From_PPStatus_Id = @FromPPStatusId and To_PPStatus_Id = @ToPPStatusId and Path_Id = @PathId )
 	 BEGIN
 	  	 SELECT 'Production Plan Status Transition already exists'
 	  	 RETURN(-100)
 	 END
 	 INSERT INTO Production_Plan_Status(From_PPStatus_Id,Path_Id,To_PPStatus_Id,Parent_PP_Id)
 	  	 VALUES(@FromPPStatusId,@PathId,@ToPPStatusId,@ParentProductionPlanId)
END
