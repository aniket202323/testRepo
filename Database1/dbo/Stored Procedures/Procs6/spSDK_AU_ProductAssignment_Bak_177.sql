CREATE procedure [dbo].[spSDK_AU_ProductAssignment_Bak_177]
@AppUserId int,
@Department varchar(200) ,
@DepartmentId int ,
@ProductCode nvarchar(25) ,
@ProductFamily nvarchar(50) ,
@ProductFamilyId int ,
@ProductId int ,
@ProductionLine nvarchar(50) ,
@ProductionLineId int ,
@ProductionUnit nvarchar(50) ,
@ProductionUnitId int 
AS
DECLARE @ProdCodeXRef VarChar(25)
EXEC dbo.spSDK_AU_LookupIds 	 
 	  	  	  	 @Department 	 OUTPUT,
 	  	  	  	 @DepartmentId OUTPUT, 	 
 	  	  	  	 @ProductionLine OUTPUT, 	 
 	  	  	  	 @ProductionLineId OUTPUT,
 	  	  	  	 @ProductionUnit OUTPUT,
 	  	  	  	 @ProductionUnitId
SET @ProdCodeXRef = Null    /* Not used at this time */
DECLARE @ApprovedDate 	  	  	 DateTime,
 	  	  	  	 @TransId 	  	  	  	  	 Int,
 	  	  	  	 @TransDesc 	  	  	  	 VarChar(50),
 	  	  	  	 @CurrentTransId 	  	 Int,
 	  	  	  	 @EffectiveDate 	  	 DateTime
DECLARE  @ReturnMessages TABLE(msg VarChar(100))
SELECT @EffectiveDate = dbo.fnServer_CmnGetDate(GetUtcDate())
SELECT @EffectiveDate = DATEADD(Millisecond,-DatePart(Millisecond,@EffectiveDate),@EffectiveDate)
IF NOT EXISTS(SELECT 1 FROM Transactions)
 	 Select @CurrentTransId = 1
Else
 	 SELECT @CurrentTransId = IDENT_CURRENT('Transactions') + 1
SELECT @TransDesc = '<' + Convert(VarChar(10),@CurrentTransId) + '>' + 'SDK-Specs' 
EXECUTE spEM_CreateTransaction  @TransDesc,Null,1,Null,@AppUserId,@TransId OUTPUT
INSERT INTO @ReturnMessages(msg)
 	 EXECUTE spEM_IEImportProductsToUnits @ProductionLine,@ProductionUnit,@ProductCode,@ProdCodeXRef,@AppUserId,@TransId
 	 
IF EXISTS(SELECT 1 FROM @ReturnMessages)
BEGIN
 	 SELECT msg FROM @ReturnMessages
 	 RETURN(-100)
END
EXECUTE spEM_ApproveTrans @TransId,@AppUserId,1,Null,@ApprovedDate,@EffectiveDate Output
RETURN(1)
