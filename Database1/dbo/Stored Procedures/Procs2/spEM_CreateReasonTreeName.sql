CREATE PROCEDURE dbo.spEM_CreateReasonTreeName
  @Level_Name nvarchar(50),
  @User_Id int,
  @TreeName_Id int OUTPUT 
 AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Can't create product group.
  --
  DECLARE @Insert_Id integer,@Sql nvarchar(1000) 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_CreateReasonTreeName',
                 @Level_Name + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
 	 INSERT INTO Event_Reason_Tree(Tree_Name_Local) VALUES(@Level_Name) 
  SELECT @TreeName_Id  = Tree_Name_Id From Event_Reason_Tree where Tree_Name = @Level_Name
  IF @TreeName_Id  IS NULL
 	 BEGIN
      UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 WHERE Audit_Trail_Id = @Insert_Id
      RETURN(1)
 	 END
 	 If (@@Options & 512) = 0
 	   Begin
 	  	 Update Event_Reason_Tree set Tree_Name_Global = Tree_Name_Local where Tree_Name_Id = @TreeName_Id
 	   End
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@TreeName_Id)
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
