CREATE procedure [dbo].[spSDK_AU_PathInput_Bak_177]
@AppUserId int,
@Id int OUTPUT,
@AlternateSpec varchar(100) ,
@AlternateSpecId int ,
@DefEventCompSheetId int ,
@Department varchar(200) ,
@DepartmentId int ,
@EventSubType nvarchar(50) ,
@EventSubTypeId int ,
@PathInput nvarchar(50) ,
@InputOrder int ,
@LockInprogressInput bit ,
@PrimarySpec varchar(100) ,
@PrimarySpecId int ,
@ProductionLine nvarchar(50) ,
@ProductionLineId int ,
@ProductionUnit nvarchar(50) ,
@ProductionUnitId int 
AS
DECLARE @PrimSpec VarChar(100)
DECLARE @AltSpec VarChar(100)
DECLARE @ReturnMessages TABLE(msg VarChar(100))
EXEC dbo.spSDK_AU_LookupIds 	 
 	  	  	  	 @Department 	 OUTPUT,
 	  	  	  	 @DepartmentId OUTPUT, 	 
 	  	  	  	 @ProductionLine OUTPUT, 	 
 	  	  	  	 @ProductionLineId OUTPUT,
 	  	  	  	 @ProductionUnit OUTPUT,
 	  	  	  	 @ProductionUnitId OUTPUT
 	  	  	  	 
/* @DefEventCompSheetId Not set here set by sheet update */
IF @AlternateSpecId Is Not Null
BEGIN
 	 SELECT @AltSpec = b.Prop_Desc + '/' + a.Spec_Desc 
 	 From Specifications a
 	 Join Product_Properties b on b.Prop_Id = a.Prop_Id 
 	 WHERE a.Spec_Id = @AlternateSpecId
END
IF @PrimarySpecId Is Not Null
BEGIN
 	 SELECT @PrimSpec = b.Prop_Desc + '/' + a.Spec_Desc 
 	 From Specifications a
 	 Join Product_Properties b on b.Prop_Id = a.Prop_Id 
 	 WHERE a.Spec_Id = @PrimarySpecId
END
IF @Id Is Null
BEGIN
 	 IF EXISTS(SELECT 1 FROM PrdExec_Inputs WHERE PU_Id = @ProductionUnitId and Input_Name = @PathInput)
 	 BEGIN
 	  	 SELECT 'Path Input already exists Add failed' 
 	  	 RETURN(-100)
 	 END
 	 INSERT INTO @ReturnMessages(msg)
 	  	 EXECUTE spEM_IEImportRawMaterialInputs 	 @ProductionLine,@ProductionUnit,@PathInput,@EventSubType,@PrimSpec,
 	  	  	  	  	  	  	 @AltSpec,@LockInprogressInput,Null,Null,Null,@AppUserId
 	 IF EXISTS(SELECT 1 FROM @ReturnMessages)
 	 BEGIN
 	  	 SELECT msg FROM @ReturnMessages
 	  	 RETURN(-100)
 	 END
 	 SELECT @Id = PEI_Id FROM PrdExec_Inputs WHERE PU_Id = @ProductionUnitId and Input_Name = @PathInput
 	 IF @Id Is Null
 	 BEGIN
 	  	 SELECT 'Failed to create input'
 	  	 RETURN(-100)
 	 END
END
ELSE
BEGIN
 	 IF Not EXISTS(SELECT 1 FROM PrdExec_Inputs WHERE PEI_Id = @Id)
 	 BEGIN
 	  	 SELECT 'Path Input not found for update' 
 	  	 RETURN(-100)
 	 END
 	 BEGIN TRY
 	 UPDATE PrdExec_Inputs SET Input_Name = @PathInput,Event_Subtype_Id = @EventSubTypeId,Input_Order = @InputOrder,Primary_Spec_Id = @PrimarySpecId,Alternate_Spec_Id = @AlternateSpecId 
 	  	 WHERE PEI_Id = @Id
 	 End TRY
 	 BEGIN CATCH
 	  	 SELECT 'Path Input update Failed' 
 	  	 RETURN(-100)
 	 END CATCH
END
Return(1)
