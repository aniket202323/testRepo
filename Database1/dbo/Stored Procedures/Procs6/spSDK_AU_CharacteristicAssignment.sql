CREATE procedure [dbo].[spSDK_AU_CharacteristicAssignment]
@AppUserId int,
@Characteristic nvarchar(50) ,
@CharacteristicId int ,
@Department varchar(200) ,
@DepartmentId int ,
@ProductCode nvarchar(25) ,
@ProductId int ,
@ProductionLine nvarchar(50) ,
@ProductionLineId int ,
@ProductionUnit nvarchar(50) ,
@ProductionUnitId int ,
@ProductProperty nvarchar(50) ,
@ProductPropertyId int 
AS
DECLARE @ApprovedDate 	  	  	 DateTime,
 	  	  	  	 @TransId 	  	  	  	  	 Int,
 	  	  	  	 @TransDesc 	  	  	  	 VarChar(50),
 	  	  	  	 @CurrentTransId 	  	 Int,
 	  	  	  	 @EffectiveDate 	  	 DateTime
DECLARE  @ReturnMessages TABLE(msg VarChar(100))
EXEC dbo.spSDK_AU_LookupIds 	 
 	  	  	  	 @Department 	 OUTPUT,
 	  	  	  	 @DepartmentId OUTPUT, 	 
 	  	  	  	 @ProductionLine OUTPUT, 	 
 	  	  	  	 @ProductionLineId OUTPUT,
 	  	  	  	 @ProductionUnit OUTPUT,
 	  	  	  	 @ProductionUnitId
SELECT @EffectiveDate = dbo.fnServer_CmnGetDate(GetUtcDate())
SELECT @EffectiveDate = DATEADD(Millisecond,-DatePart(Millisecond,@EffectiveDate),@EffectiveDate)
IF NOT EXISTS(SELECT 1 FROM Transactions)
 	 Select @CurrentTransId = 1
Else
 	 SELECT @CurrentTransId = IDENT_CURRENT('Transactions') + 1
SELECT @TransDesc = '<' + Convert(VarChar(10),@CurrentTransId) + '>' + 'SDK-Specs' 
EXECUTE spEM_CreateTransaction  @TransDesc,Null,1,Null,@AppUserId,@TransId OUTPUT
INSERT INTO @ReturnMessages(msg)
 	 EXECUTE spEM_IEImportProductCharacteristics
 	  	  	  	  	 @ProductionLine,
 	  	  	  	  	 @ProductionUnit,
 	  	  	  	  	 @ProductCode,
 	  	  	  	  	 @ProductProperty,
 	  	  	  	  	 @Characteristic,
 	  	  	  	  	 @AppUserId,
 	  	  	  	  	 @TransId 
 	  	  	  	  	 
IF EXISTS(SELECT 1 FROM @ReturnMessages)
BEGIN
 	 SELECT msg FROM @ReturnMessages
 	 RETURN(-100)
END
EXECUTE spEM_ApproveTrans @TransId,@AppUserId,1,Null,@ApprovedDate,@EffectiveDate Output
RETURN(1)
