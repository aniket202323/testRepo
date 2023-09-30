CREATE PROCEDURE dbo.spEM_RenameReasonCategory
  @Cat_Id  int,
  @CatName nVarChar(100),
  @User2_Id int
  AS
  DECLARE @Insert_Id Int
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User2_Id,'spEM_RenameReasonCategory',
                Convert(nVarChar(10),@Cat_Id) + ','  + @CatName + ','  + 
                Convert(nVarChar(10),@User2_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Return Code: 0 = Success. 
  --
 	 If (@@Options & 512) = 0
 	  	 Update Event_Reason_Catagories Set ERC_Desc_Global = @CatName Where ERC_Id = @Cat_Id
 	 Else
 	  	 Update Event_Reason_Catagories Set ERC_Desc_Local = @CatName Where ERC_Id = @Cat_Id
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
