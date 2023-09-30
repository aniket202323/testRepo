CREATE procedure [dbo].[spSDK_AU_UnitLocation_Bak_177]
@AppUserId int,
@Id int OUTPUT,
@CommentId int OUTPUT,
@CommentText text ,
@Department varchar(100) ,
@DepartmentId int ,
@LocationCode varchar(100) ,
@MaximumAlarmEnabled bit ,
@MaximumDimensionA real ,
@MaximumDimensionX real ,
@MaximumDimensionY real ,
@MaximumDimensionZ real ,
@MaximumItems int ,
@MinimumAlarmEnabled bit ,
@MinimumDimensionA real ,
@MinimumDimensionX real ,
@MinimumDimensionY real ,
@MinimumDimensionZ real ,
@MinimumItems int ,
@ProductCode varchar(100) ,
@ProductId int ,
@ProductionLine varchar(100) ,
@ProductionLineId int ,
@ProductionUnit varchar(100) ,
@ProductionUnitId int ,
@UnitLocation varchar(100) 
AS
DECLARE @sComment VarChar(255)
DECLARE @CurrentLocCode VarChar(100)
DECLARE @CurrentPUId Int
DECLARE @OldCommentId Int
DECLARE  @ReturnMessages TABLE(msg VarChar(100))
EXEC dbo.spSDK_AU_LookupIds 	 
 	  	  	  	 @Department 	 OUTPUT,
 	  	  	  	 @DepartmentId OUTPUT, 	 
 	  	  	  	 @ProductionLine OUTPUT, 	 
 	  	  	  	 @ProductionLineId OUTPUT,
 	  	  	  	 @ProductionUnit OUTPUT,
 	  	  	  	 @ProductionUnitId
If (@ProductCode Is NULL)
 	 SELECT @ProductCode = Prod_Code FROM Products Where Prod_Id = @ProductId
 	 
SELECT @sComment = SUBSTRING(@CommentText,1,255)
IF @Id is Not Null
BEGIN
 	 IF Not Exists(SELECT 1 FROM Unit_Locations WHERE Location_Id = @Id)
 	 BEGIN
 	  	 SELECT 'Unit Location not found for update'
 	  	 RETURN(-100)
 	 END
 	 SELECT @CurrentLocCode = a.Location_Code,@CurrentPUId = a.PU_Id,@OldCommentId = Comment_Id
 	  	 FROM Unit_Locations a
 	  	 WHERE a.Location_Id = @Id
 	 IF @CurrentPUId <> @ProductionUnitId
 	 BEGIN
 	  	 SELECT 'Updating of Production Unit is not supported'
 	  	 RETURN (-100)
 	 END
 	 IF @CurrentLocCode <> @LocationCode
 	  	 UPDATE Unit_Locations SET Location_Code = @LocationCode WHERE Location_Id = @Id
END
ELSE
BEGIN
 	 IF Exists(SELECT 1 FROM Unit_Locations WHERE PU_Id = @ProductionUnitId and Location_Code = @LocationCode)
 	 BEGIN
 	  	 SELECT 'Unit Location already exists cannot add'
 	  	 RETURN(-100)
 	 END
END
INSERT INTO @ReturnMessages(msg)
EXECUTE spEM_IEImportUnitLocations @ProductionLine,@ProductionUnit,@LocationCode,@UnitLocation,@ProductCode,
 	  	  	  	  	  	  	  	 @MaximumItems,@MaximumDimensionX,@MaximumDimensionY,@MaximumDimensionZ,@MaximumDimensionA,
 	  	  	  	  	  	  	  	 @MaximumAlarmEnabled,@MinimumItems,@MinimumDimensionX,@MinimumDimensionY,@MinimumDimensionZ,
 	  	  	  	  	  	  	  	 @MinimumDimensionA,@MinimumAlarmEnabled,@sComment,@AppUserId
 	  	  	  	  	  	  	  	 
IF EXISTS(SELECT 1 FROM @ReturnMessages)
BEGIN
 	 SELECT msg FROM @ReturnMessages
 	 RETURN(-100)
END
SELECT @Id = Location_Id FROM Unit_Locations WHERE PU_Id = @ProductionUnitId and Location_Code = @LocationCode
SET @CommentId = COALESCE(@OldCommentId,@CommentId)
IF @CommentId IS NOT NULL AND @CommentText IS NULL -- DELETE
BEGIN
 	 DELETE FROM Comments WHERE TopOfChain_Id = @CommentId
 	 DELETE FROM Comments WHERE Comment_Id = @CommentId
  UPDATE Unit_Locations SET Comment_Id = Null WHERE Location_Id = @Id and Comment_Id Is not null
 	 SET @CommentId = NULL
END
IF @CommentId IS NULL AND @CommentText IS NOT NULL --ADD
BEGIN
 	  	 INSERT INTO Comments (Comment, Comment_Text, User_Id, Modified_On, CS_Id) 
 	  	  	 SELECT @CommentText,@CommentText, @AppUserId, dbo.fnServer_CmnGetDate(getutcdate()), 1
    SELECT @CommentId = Scope_Identity()
    UPDATE Unit_Locations SET Comment_Id = @CommentId WHERE Location_Id = @Id
END
ELSE
IF @CommentId IS NOT NULL -- UPDATE TEXT
BEGIN
 	 UPDATE Comments SET Comment = @CommentText,Comment_Text = @CommentText WHERE Comment_Id = @CommentId
END
Return(1)
