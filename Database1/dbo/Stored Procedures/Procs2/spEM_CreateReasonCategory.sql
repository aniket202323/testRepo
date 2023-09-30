CREATE PROCEDURE dbo.spEM_CreateReasonCategory
  @CatName  nvarchar(50),
  @In_User_Id int,
  @Cat_Id  int OUTPUT
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Can't create user.
  --
   DECLARE @Insert_Id Int
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@In_User_Id,'spEM_CreateReasonCategory',
                @CatName + ','  + Convert(nVarChar(10), @In_User_Id),dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
 BEGIN TRANSACTION
INSERT INTO Event_Reason_Catagories(ERC_Desc_Local) VALUES(@CatName)
  SELECT @Cat_Id = ERC_Id From Event_Reason_Catagories Where ERC_Desc = @CatName
  IF @Cat_Id IS NULL
    BEGIN
      ROLLBACK TRANSACTION
      UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 WHERE Audit_Trail_Id = @Insert_Id
      RETURN(1)
    END
 	 If (@@Options & 512) = 0
 	   Begin
 	  	 Update Event_Reason_Catagories set ERC_Desc_Global = ERC_Desc_Local where ERC_Id = @Cat_Id
 	   End
  COMMIT TRANSACTION
   UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@Cat_Id)
     WHERE Audit_Trail_Id = @Insert_Id
 RETURN(0)
