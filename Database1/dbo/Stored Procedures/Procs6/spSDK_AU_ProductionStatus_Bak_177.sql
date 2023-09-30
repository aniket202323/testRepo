CREATE procedure [dbo].[spSDK_AU_ProductionStatus_Bak_177]
@AppUserId int,
@Id int OUTPUT,
@ColorId int ,
@Color nvarchar(50) ,
@CountForInventory tinyint ,
@CountForProduction tinyint ,
@IconId int ,
@LifeCycleStage int ,
@ProductionStatus nvarchar(50) ,
@StatusValidForInput tinyint 
AS
DECLARE @OldStatusDesc 	  	  	 VarChar(50)
DECLARE  @ReturnMessages TABLE(msg VarChar(100))
DECLARE @IconDesc Varchar(100)
IF @IconId IS NULL
BEGIN
 	 SELECT @IconDesc = 'Flag - Green'
END
ELSE
BEGIN
 	 SELECT @IconDesc = Icon_Desc FROM Icons WHERE Icon_Id = @IconId
 	 IF @IconDesc Is NULL
 	 BEGIN
 	  	 SELECT 'Icon not found'
 	  	 RETURN(-100)
 	 END
END
IF @Id IS Not Null
BEGIN
 	 IF @IconId IS NULL
 	  	 SELECT @IconId = Icon_Id
 	  	  	 FROM Production_Status a
 	  	  	 WHERE ProdStatus_Id = @Id
 	 EXECUTE spEMPSC_ProductionStatusConfigUpdate  	 @Id,@IconId,@ColorId,@CountForProduction,@CountForInventory,@StatusValidForInput,@ProductionStatus
END
ELSE
BEGIN
 	 INSERT INTO @ReturnMessages(msg)
 	  	  	 EXECUTE spEM_IEImportProductionStatuses @ProductionStatus,@IconDesc,@Color,@StatusValidForInput,@CountForInventory,@CountForProduction,@AppUserId
 	 IF EXISTS(SELECT 1 FROM @ReturnMessages)
 	 BEGIN
 	  	 SELECT msg FROM @ReturnMessages
 	  	 RETURN(-100)
 	 END
 	 Select @Id = ProdStatus_Id from Production_Status where ProdStatus_Desc = @ProductionStatus
END
RETURN(1)
