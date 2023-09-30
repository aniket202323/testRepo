CREATE PROCEDURE dbo.spEM_RenameSheetGroup
  @SheetGroup_Id   int,
  @SheetGroup_Desc nvarchar(50),
  @User_Id int
  AS
DECLARE  @Insert_Id integer,@Sql nvarchar(1000)
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_RenameSheetGroup',
                Convert(nVarChar(10),@SheetGroup_Id) + ','  + 
                @SheetGroup_Desc + ','  + 
 	    Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  If Exists (select * from dbo.syscolumns where name = 'Sheet_Group_Desc_Local' and id =  object_id(N'[Sheet_Groups]'))
 	 Begin
 	   If (@@Options & 512) = 0
 	  	 Select @Sql =  'Update Sheet_Groups Set Sheet_Group_Desc_Global = ''' + replace(@SheetGroup_Desc,'''','''''') + ''' Where Sheet_Group_Id = ' + Convert(nVarChar(10),@SheetGroup_Id)
     Else
 	  	 Select @Sql =  'Update Sheet_Groups Set Sheet_Group_Desc_Local = ''' + replace(@SheetGroup_Desc,'''','''''') + ''' Where Sheet_Group_Id = ' + Convert(nVarChar(10),@SheetGroup_Id)
 	 End
  Else
 	 Select @Sql =  'Update Sheet_Groups Set Sheet_Group_Desc = ''' + replace(@SheetGroup_Desc,'''','''''') + ''' Where Sheet_Group_Id = ' + Convert(nVarChar(10),@SheetGroup_Id)
  Execute(@Sql)
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
