CREATE PROCEDURE dbo.spEM_DropViewGroup
  @View_Group_Id int,
  @User_Id int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --
  -- Delete the product group data.
  --
  DECLARE @Insert_Id integer 
  If @View_Group_Id = 1 Return(1)
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DropViewGroup',
                 convert(nVarChar(10),@View_Group_Id)  + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  BEGIN TRANSACTION
  Update Views Set View_Group_Id = 1 Where View_Group_Id = @View_Group_Id
  DELETE FROM View_Groups WHERE View_Group_Id = @View_Group_Id
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
