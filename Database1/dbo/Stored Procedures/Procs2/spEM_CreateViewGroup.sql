CREATE PROCEDURE dbo.spEM_CreateViewGroup
  @GroupName  nvarchar(30),
  @In_User_Id int,
  @Group_Id  int OUTPUT
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Can't create user.
  --
   DECLARE @Insert_Id integer ,@Sql nvarchar(1000)
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@In_User_Id,'spEM_CreateViewGroup',
                @GroupName + ','  + Convert(nVarChar(10), @In_User_Id),dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
 BEGIN TRANSACTION
  If Exists (select * from dbo.syscolumns where name = 'View_Group_Desc_Local' and id =  object_id(N'[View_Groups]'))
 	 Select @Sql =  'INSERT INTO View_Groups(View_Group_Desc_Local)'
  Else
 	 Select @Sql =  'INSERT INTO View_Groups(View_Group_Desc)'
  Select @Sql = @Sql + ' VALUES(''' + replace(@GroupName,'''','''''') + ''')'
  Execute(@Sql)
  SELECT @Group_Id = View_Group_Id From View_Groups Where View_Group_Desc = @GroupName
  IF @Group_Id IS NULL
    BEGIN
      ROLLBACK TRANSACTION
      UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 WHERE Audit_Trail_Id = @Insert_Id
      RETURN(1)
    END
  If Exists (select * from dbo.syscolumns where name = 'View_Group_Desc_Local' and id =  object_id(N'[View_Groups]'))
 	 If (@@Options & 512) = 0
 	   Begin
 	  	 Select @Sql =  'Update View_Groups set View_Group_Desc_Global = View_Group_Desc_Local where View_Group_Id = ' + Convert(nVarChar(10),@Group_Id)
   	  	 Execute (@Sql)
 	   End
  COMMIT TRANSACTION
   UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@Group_Id)
     WHERE Audit_Trail_Id = @Insert_Id
 RETURN(0)
