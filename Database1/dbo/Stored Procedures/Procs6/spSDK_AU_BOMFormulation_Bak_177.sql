CREATE PROCEDURE [dbo].[spSDK_AU_BOMFormulation_Bak_177]
@AppUserId int,
@Id bigint OUTPUT,
@BOM nvarchar(50) ,
@BOMFormulation nvarchar(50) ,
@BOMFormulationCode varchar(25) ,
@BOMId int ,
@CommentId int OUTPUT,
@CommentText text ,
@EffectiveDate datetime ,
@EngineeringUnit nvarchar(50) ,
@EngineeringUnitId int ,
@ExpirationDate datetime ,
@MasterBOMFormulation nvarchar(50) ,
@MasterBOMFormulationId bigint ,
@QuantityPrecision int ,
@StandardQuantity int 
AS
DECLARE @EngCode 	  	  	  	  	 VarChar(50),
 	  	  	  	 @sComment 	  	  	  	  	 VarChar(255),
 	  	  	  	 @sEffectiveDate 	  	 VarChar(14),
 	  	  	  	 @sExpirationDate 	 VarChar(14),
 	  	  	  	 @sPart 	  	  	  	  	  	 VarChar(2)
DECLARE  @ReturnMessages TABLE(msg VarChar(100))
/*
BOM_Formulation_Code Not Currently supported for Formulations
*/
IF @Id IS NULL
BEGIN
 	 SELECT @EngCode = Eng_Unit_Code 
 	  	 FROM Engineering_Unit
 	  	 WHERE Eng_Unit_Desc = @EngineeringUnit
 	 SELECT @sComment = SUBSTRING(@CommentText,1,255)
 	 EXECUTE spSDK_ConvertDate @EffectiveDate,@sEffectiveDate OUTPUT
 	 EXECUTE spSDK_ConvertDate @ExpirationDate,@sExpirationDate OUTPUT
 	 
 	 INSERT INTO @ReturnMessages(msg)
 	 EXECUTE spEM_IEImportBillOfMaterialFormulation
 	  	  	  	  	 @BOM,
 	  	  	  	  	 @BOMFormulation,
 	  	  	  	  	 @MasterBOMFormulation,
 	  	  	  	  	 @sEffectiveDate,
 	  	  	  	  	 @sExpirationDate,
 	  	  	  	  	 @StandardQuantity,
 	  	  	  	  	 @QuantityPrecision,
 	  	  	  	  	 @EngCode,
 	  	  	  	  	 @sComment,
 	  	  	  	  	 @AppUserId
 	 IF EXISTS(SELECT 1 FROM @ReturnMessages)
 	 BEGIN
 	  	 SELECT msg FROM @ReturnMessages
 	  	 RETURN(-100)
 	 END
 	 SELECT @Id =  BOM_Formulation_Id,@CommentId = Comment_id  
 	  	  	 FROM Bill_Of_Material_Formulation 
 	  	  	 WHERE BOM_Formulation_Desc = @BOMFormulation
 	 IF @CommentId IS Not NULL
 	 BEGIN
 	  	 UPDATE Comments SET Comment = @CommentText, Comment_Text = @CommentText WHERE Comment_Id = @CommentId
 	 END
END
ELSE
BEGIN
 	 EXECUTE spEM_BOMSaveFormulation  @BOMId,@EffectiveDate,@ExpirationDate,@StandardQuantity,@QuantityPrecision, @EngineeringUnitId,@CommentText ,@MasterBOMFormulationId ,@AppUserId,@BOMFormulation,@Id OUTPUT
 	 Select @CommentId = Comment_Id From Bill_Of_Material_Formulation Where BOM_Formulation_Id = @Id
 	 If (@CommentId Is Not NULL)
 	  	 Update Comments Set Comment_Text = @CommentText Where Comment_Id = @CommentId 	 
END
Update Bill_Of_Material_Formulation Set BOM_Formulation_Code = @BOMFormulationCode Where BOM_Formulation_Id = @Id
RETURN(1)
