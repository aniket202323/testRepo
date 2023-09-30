/* This sp is called by dbo.spBatch_ProcessProcedureReport parameters need to stay in sync*/
Create Procedure dbo.spEMPSC_ProductionStatusConfigUpdate 
 	 @ProdStatusId int,
 	 @IconId int,
 	 @ColorId int,
 	 @IsProduction int,
 	 @IsInventory Int,
 	 @GoodBad int,
 	 @Desc nvarchar(50),
 	 @DisableHistory Int = 0,
 	 @LockData Int = 0
AS
 	 IF @DisableHistory Is Null SET @DisableHistory = 0
 	 IF @LockData Is Null SET @LockData = 0
 	 If @ProdStatusId Is Null
 	 Begin
 	  	 INSERT INTO Production_Status(ProdStatus_Desc_Local, Icon_Id,Color_Id,Status_Valid_For_Input,Count_For_Inventory,Count_For_Production,NoHistory,LockData)
 	  	  	 VALUES(@Desc,@IconId,@ColorId,@GoodBad,@IsInventory,@IsProduction,@DisableHistory,@LockData)
 	  	 Select @ProdStatusId = ProdStatus_Id From Production_Status Where ProdStatus_Desc = @Desc
 	  	 If (@@Options & 512) = 0
 	  	 Begin
 	  	  	 Update Production_Status set ProdStatus_Desc_Global = ProdStatus_Desc_Local where ProdStatus_Id = @ProdStatusId
 	  	 End
 	  	 Return(@ProdStatusId)
     End
   Else
    Begin
 	  	 If (@@Options & 512) = 0
 	  	  	 Update Production_Status Set ProdStatus_Desc_Global = @Desc Where prodstatus_id = @ProdStatusId
 	  	 Else
 	  	  	 Update Production_Status Set ProdStatus_Desc_Local = @Desc Where prodstatus_id = @ProdStatusId
      Update production_status set Icon_Id = @IconId, 
 	  	  	  	 Color_Id = @ColorId, 
 	  	  	  	 Status_Valid_For_Input = @GoodBad,
 	  	  	  	 Count_For_Inventory =@IsInventory,
 	  	  	  	 Count_For_Production = @IsProduction,
 	  	  	  	 NoHistory = @DisableHistory,
 	  	  	  	 LockData = @LockData
  	  	 Where prodstatus_id = @ProdStatusId
      Return(@ProdStatusId)
    End
