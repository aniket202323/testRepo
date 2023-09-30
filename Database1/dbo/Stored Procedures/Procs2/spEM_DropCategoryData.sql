CREATE PROCEDURE dbo.spEM_DropCategoryData
  @ERCD_ID Int,
  @User_Id Int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Can't create user group.
  --
  DECLARE @Insert_Id integer
  Declare @CatId Int,@RTDId Int
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DropCategoryData',
 	  	 Convert(nVarChar(10),@ERCD_ID) + ',' +
 	  	 Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  Select @RTDId = Event_Reason_Tree_Data_Id,@CatId = ERC_Id
   From Event_Reason_Category_Data
   Where  ERCD_Id = @ERCD_ID
  BEGIN TRANSACTION
   Delete From Event_Reason_Category_Data Where Propegated_From_ETDId = @RTDId and  ERC_Id = @CatId
   Delete From  Event_Reason_Category_Data Where ERCD_Id = @ERCD_ID
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0  WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
