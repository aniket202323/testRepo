CREATE procedure [dbo].[spSDK_AU_EngineeringUnit]
@AppUserId int,
@Id int OUTPUT,
@EngineeringUnit nvarchar(50) ,
@EngineeringUnitCode varchar(15) ,
@IsActive bit 
AS
DECLARE @ReturnMessages TABLE(msg VarChar(100))
DECLARE @OldEngineeringUnit 	  	  	 VarChar(50)
DECLARE @OldEngineeringUnitCode 	 VarChar(50)
DECLARE @OldIsActive 	  	  	  	  	  	 VarChar(50)
IF @Id Is NULL
BEGIN
 	 IF Exists(SELECT 1 FROM Engineering_Unit WHERE Eng_Unit_Code = @EngineeringUnitCode)
 	 BEGIN
 	  	 SELECT 'Engineering unit already exists add not allowed'
 	  	 RETURN(-100)
 	 END
 	 INSERT INTO @ReturnMessages(msg)
 	  	 EXECUTE spEM_IEImportEngineeringUnit @EngineeringUnit,@EngineeringUnitCode,@AppUserId
 	 IF EXISTS(SELECT 1 FROM @ReturnMessages)
 	 BEGIN
 	  	 SELECT msg FROM @ReturnMessages
 	  	 RETURN(-100)
 	 END
 	 SELECT @Id = Eng_Unit_Id FROM Engineering_Unit WHERE Eng_Unit_Code = @EngineeringUnitCode
 	 IF @Id IS NULL
 	 BEGIN
 	  	 SELECT 'Create Engineering unit failed'
 	  	 RETURN(-100)
 	 END
END
ELSE
BEGIN
 	 IF Not Exists(SELECT 1 FROM Engineering_Unit a WHERE a.Eng_Unit_Id = @Id)
 	 BEGIN
 	  	 SELECT 'Engineering unit not found for update'
 	  	 RETURN(-100)
 	 END
 	 IF  @Id < 50001
 	 BEGIN
 	  	 SELECT 'system Engineering unit not updatable'
 	  	 RETURN(-100)
 	 END
 	 SELECT 	 @OldEngineeringUnit = a.Eng_Unit_Desc,
 	  	  	  	  	 @OldEngineeringUnitCode = a.Eng_Unit_Code,
 	  	  	  	  	 @OldIsActive = a.Is_Active 
 	  	 FROM Engineering_Unit a
 	  	 WHERE a.Eng_Unit_Id = @Id
 	 SET @IsActive = Coalesce(@IsActive,@OldIsActive)
 	 SET @EngineeringUnit = Coalesce(@EngineeringUnit,@OldEngineeringUnit)
 	 SET @EngineeringUnitCode = Coalesce(@EngineeringUnitCode,@OldEngineeringUnitCode)
 	 IF @IsActive <> @OldIsActive
 	 BEGIN
 	  	 UPDATE Engineering_Unit set Is_Active = @IsActive WHERE Eng_Unit_Id = @Id
 	 END
 	 IF @EngineeringUnit <> @OldEngineeringUnit or  @EngineeringUnitCode <> @OldEngineeringUnitCode
 	 BEGIN
 	  	 EXECUTE spEM_EUPut  @Id,@EngineeringUnit,@EngineeringUnitCode,@AppUserId
 	 END
END
Return(1)
