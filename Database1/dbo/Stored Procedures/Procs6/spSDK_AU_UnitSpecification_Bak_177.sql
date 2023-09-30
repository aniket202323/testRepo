CREATE procedure [dbo].[spSDK_AU_UnitSpecification_Bak_177]
@AppUserId int,
@Id int OUTPUT,
@CentralSpecificationId int ,
@CommentId int OUTPUT,
@CommentText text ,
@Department varchar(200) ,
@DepartmentId int ,
@EffectiveDate datetime ,
@ESignatureLevel varchar(200) ,
@ESignatureLevelId int ,
@ExpirationDate datetime ,
@LCL nvarchar(25) ,
@LEL nvarchar(25) ,
@LRL nvarchar(25) ,
@LUL nvarchar(25) ,
@LWL nvarchar(25) ,
@OESignatureLevel tinyint ,
@OLCL tinyint ,
@OLEL tinyint ,
@OLRL tinyint ,
@OLUL tinyint ,
@OLWL tinyint ,
@OTCL tinyint ,
@OTestingFrequency tinyint ,
@OTGT tinyint ,
@OUCL tinyint ,
@OUEL tinyint ,
@OURL tinyint ,
@OUUL tinyint ,
@OUWL tinyint ,
@ProductCode nvarchar(25) ,
@ProductId int ,
@ProductionLine nvarchar(50) ,
@ProductionLineId int ,
@ProductionUnit nvarchar(50) ,
@ProductionUnitId int ,
@TCL nvarchar(25) ,
@TestingFrequency int ,
@TGT nvarchar(25) ,
@UCL nvarchar(25) ,
@UEL nvarchar(25) ,
@URL nvarchar(25) ,
@UUL nvarchar(25) ,
@UWL nvarchar(25) ,
@VarESignatureLevel varchar(200) ,
@VarESignatureLevelId int ,
@Variable nvarchar(50) ,
@VariableId int 
AS
DECLARE @ReturnMessages TABLE(msg VarChar(100))
DECLARE @Central Int
DECLARE @ApprovedDate DateTime, @CurrentComment INT, @Derived INT
EXEC dbo.spSDK_AU_LookupIds 	 
 	  	  	  	 @Department 	 OUTPUT,
 	  	  	  	 @DepartmentId OUTPUT, 	 
 	  	  	  	 @ProductionLine OUTPUT, 	 
 	  	  	  	 @ProductionLineId OUTPUT,
 	  	  	  	 @ProductionUnit OUTPUT,
 	  	  	  	 @ProductionUnitId  OUTPUT,
 	  	  	  	 Null,
 	  	  	  	 Null,
 	  	  	  	 @VariableId
If (@ProductionUnit Is NULL)
 	 Select @ProductionUnit = PU_Desc, @ProductionUnitId = PU_Id From Prod_Units_Base Where PU_Id = (Select PU_Id from Variables_Base as Variables Where Var_Id = @VariableId)
If (@ProductionLine Is NULL)
 	 Select @ProductionLine = Pl_Desc, @ProductionLineId = PL_Id From Prod_Lines_Base Where PL_Id = (Select PL_Id From Prod_Units_Base Where PU_Id = @ProductionUnitId)
IF EXISTS(Select 1 from Variables_Base as Variables Where Var_Id = @VariableId and Spec_Id Is Null)
 	 SET @Central = 0
ELSE
 	 SET @Central = 1
IF @Id IS NULL
BEGIN
 	 DECLARE @TransId Int,@TransDesc VarChar(50),@CurrentTransId Int
 	 IF NOT EXISTS(SELECT 1 FROM Transactions)
 	  	 Select @CurrentTransId = 1
 	 Else
 	  	 SELECT @CurrentTransId = IDENT_CURRENT('Transactions') + 1
 	  	 
 	 SELECT @TransDesc = '<' + Convert(VarChar(10),@CurrentTransId) + '>' + 'SDK-Specs' 
 	 
 	 EXECUTE spEM_CreateTransaction  @TransDesc,Null,1,Null,@AppUserId,@TransId OUTPUT 	 
 	 INSERT INTO @ReturnMessages(msg)
 	  	 EXECUTE spEM_IEImportVarSpecs 	 @ProductionLine,@ProductionUnit,@Variable,@Central,@ProductCode,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @LEL,@OLEL,@LRL,@OLRL,@LWL,@OLWL,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @LUL,@OLUL,@TGT,@OTGT,@UUL,@OUUL,@UWL,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @OUWL,@URL,@OURL,@UEL,@OUEL,@TestingFrequency,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @OTestingFrequency,@ESignatureLevel,@OESignatureLevel,@LCL,@OLCL,@TCL,
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 @OTCL,@UCL,@OUCL,@AppUserId,@TransId
 	 IF EXISTS(SELECT 1 FROM @ReturnMessages)
 	 BEGIN
 	  	 SELECT msg FROM @ReturnMessages
 	  	 RETURN(-100)
 	 END
 	 EXECUTE spEM_ApproveTrans @TransId,@AppUserId,1,Null,@ApprovedDate,@EffectiveDate Output
 	 SELECT @Id = a.VS_Id,@CurrentComment = Comment_Id  
 	  	 FROM Var_Specs a
 	  	 WHERE a.Var_Id = @VariableId AND a.Prod_Id = @ProductId and a.Effective_Date = @EffectiveDate
 	 SET @CommentId = COALESCE(@CurrentComment,@CommentId)
 	 IF @CommentId IS NOT NULL AND @CommentText IS NULL -- DELETE
 	 BEGIN
 	  	 UPDATE Var_Specs SET Comment_Id = NULL WHERE VS_Id =  @Id
 	  	 DELETE FROM Comments WHERE Comment_Id = @CommentId
 	  	 SET @CommentId = NULL
 	 END
 	 IF @CommentId IS NULL AND @CommentText IS NOT NULL --ADD
 	 BEGIN
    Insert Into Comments (Comment, Comment_Text, User_Id, Modified_On, CS_Id) 
 	  	  	 values (@CommentText,@CommentText, @AppUserId, dbo.fnServer_CmnGetDate(getutcdate()), 5)
    Select @CommentId = Scope_Identity()
 	  	 UPDATE Var_Specs SET Comment_Id = @CommentId WHERE VS_Id =  @Id
 	 END
 	 ELSE
 	 BEGIN
 	  	 IF @CommentId IS NOT NULL -- UPDATE TEXT
 	  	 BEGIN
 	  	  	 UPDATE Comments SET Comment = @CommentText,Comment_Text = @CommentText WHERE Comment_Id = @CommentId
 	  	 END
 	 END
END
ELSE
BEGIN
 	 SELECT 'Error - Updates to specifications are not supported'
 	 RETURN(-100)
END
RETURN(1)
