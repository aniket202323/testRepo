CREATE PROCEDURE dbo.spEM_RenameViewGroup
  @Group_Id  int,
  @Groupname nVarChar(100),
  @User2_Id int
  AS
  DECLARE @Insert_Id integer ,@Sql nvarchar(1000)
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User2_Id,'spEM_RenameViewGroup',
                Convert(nVarChar(10),@Group_Id) + ','  + 
                @Groupname + ','  + 
                Convert(nVarChar(10),@User2_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Return Code: 0 = Success. 
  --
  If Exists (select * from dbo.syscolumns where name = 'View_Group_Desc_Local' and id =  object_id(N'[View_Groups]'))
 	 Begin
 	   If (@@Options & 512) = 0
 	  	 Select @Sql =  'Update View_Groups Set View_Group_Desc_Global = ''' + replace(@Groupname,'''','''''') + ''' Where View_Group_Id = ' + Convert(nVarChar(10),@Group_Id)
     Else
 	  	 Select @Sql =  'Update View_Groups Set View_Group_Desc_Local = ''' + replace(@Groupname,'''','''''') + ''' Where View_Group_Id = ' + Convert(nVarChar(10),@Group_Id)
 	 End
  Else
 	 Select @Sql =  'Update View_Groups Set View_Group_Desc = ''' + replace(@Groupname,'''','''''') + ''' Where View_Group_Id = ' + Convert(nVarChar(10),@Group_Id)
  Execute(@Sql)
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
