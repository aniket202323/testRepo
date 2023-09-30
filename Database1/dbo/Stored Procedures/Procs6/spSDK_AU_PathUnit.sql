CREATE procedure [dbo].[spSDK_AU_PathUnit]
 	  	 @AppUserId 	  	  	  	  	 int,
 	  	 @Id 	  	  	  	  	  	  	  	  	 int OUTPUT,
 	  	 @IsProductionPoint 	 bit,
 	  	 @IsSchedulePoint 	  	 bit,
 	  	 @UnitOrder 	  	  	  	  	 int,
 	  	 @PathCode 	  	  	  	  	  	 varchar(100),
 	  	 @PathId 	  	  	  	  	  	  	 int,
 	  	 @Department 	  	  	  	  	 varchar(100),
 	  	 @DepartmentId 	  	  	  	 int,
 	  	 @ProductionLine 	  	  	 varchar(100),
 	  	 @ProductionLineId 	  	 int,
 	  	 @ProductionUnit 	  	  	 varchar(100),
 	  	 @ProductionUnitId 	  	 int
AS
DECLARE @PathCheck Int
DECLARE @OldPUId   INT
DECLARE @OldPathId INT
EXEC dbo.spSDK_AU_LookupIds 	 
 	  	  	  	 @Department 	 OUTPUT,
 	  	  	  	 @DepartmentId OUTPUT, 	 
 	  	  	  	 @ProductionLine OUTPUT, 	 
 	  	  	  	 @ProductionLineId OUTPUT,
 	  	  	  	 @ProductionUnit OUTPUT,
 	  	  	  	 @ProductionUnitId
IF @Id Is Null
BEGIN
 	 SELECT  @Id = PEPU_Id FROM Prdexec_Path_units WHERE Path_Id = @PathId and PU_Id = @ProductionUnitId
 	 IF @Id IS Not NULL
 	 BEGIN
 	  	 SELECT 'Add Failed - Path Unit Already Exists'
 	  	 Return (-100)
 	 END
END
ELSE
BEGIN
 	 SELECT @PathCheck = PEPU_Id,@OldPUId = pU_Id,@OldPathId = Path_Id  FROM Prdexec_Path_units WHERE PEPU_Id = @Id
 	 IF @PathCheck IS NULL
 	 BEGIN
 	  	 SELECT 'Update Failed - Path Unit Not Found'
 	  	 Return (-100)
 	 END
 	 IF @OldPUId <> @ProductionUnitId or @OldPathId <> @PathId 
 	 BEGIN
 	  	 SELECT 'Update Failed - Change of unit or path not supported'
 	  	 Return (-100)
 	 END
END
Execute spEMEPC_PutPathUnits @ProductionUnitId,@PathId,@IsSchedulePoint,@IsProductionPoint,@UnitOrder,
 	  	  	  	  	  	  	  	 @AppUserId,@Id OUTPUT
IF @Id IS NULL
BEGIN
 	 SELECT 'Failed - Unable to create Path Unit'
 	 Return (-100)
END
Return(1)
