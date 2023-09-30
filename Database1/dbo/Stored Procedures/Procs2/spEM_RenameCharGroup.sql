CREATE PROCEDURE dbo.spEM_RenameCharGroup
  @CharGroup_Id   int,
  @Char_Desc nvarchar(50),
  @User_Id int
  AS
  DECLARE @Insert_Id integer,@Sql nvarchar(1000)
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_RenameCharGroup',
                Convert(nVarChar(10),@CharGroup_Id) + ','  + 
                @Char_Desc + ','  + 
 	   Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Return Code: 0 = Success. 
  --
  If Exists (select * from dbo.syscolumns where name = 'Characteristic_Grp_Desc_Local' and id =  object_id(N'[Characteristic_Groups]'))
   Begin
 	   If (@@Options & 512) = 0
 	  	   Select @Sql =  'Update Characteristic_Groups Set Characteristic_Grp_Desc_Global = ''' + replace(@Char_Desc,'''','''''') + ''' Where Characteristic_Grp_Id = ' + Convert(nVarChar(10),@CharGroup_Id)
     Else
 	  	   Select @Sql =  'Update Characteristic_Groups Set Characteristic_Grp_Desc_Local = ''' + replace(@Char_Desc,'''','''''') + ''' Where Characteristic_Grp_Id = ' + Convert(nVarChar(10),@CharGroup_Id)
 	 End
  Else
 	 Select @Sql =  'Update Characteristic_Groups Set Characteristic_Grp_Desc = ''' + replace(@Char_Desc,'''','''''') + ''' Where Characteristic_Grp_Id = ' + Convert(nVarChar(10),@CharGroup_Id)
  Execute(@Sql)
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
