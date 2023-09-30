CREATE PROCEDURE dbo.spEM_RenameReasonTree
  @TreeName_Id      int,
  @Description nvarchar(50),
  @User_Id int
 AS
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_RenameReasonTree',
                Convert(nVarChar(10),@TreeName_Id) + ','  + 
                @Description + ','  + 
 	  	 Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Return codes: 0 = Success.
  --
  If (@@Options & 512) = 0
 	 Update Event_Reason_Tree Set Tree_Name_Global = @Description Where Tree_Name_Id = @TreeName_Id
 Else
 	 Update Event_Reason_Tree Set Tree_Name_Local = @Description Where Tree_Name_Id = @TreeName_Id
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
