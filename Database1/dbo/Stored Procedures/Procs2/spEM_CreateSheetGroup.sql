CREATE PROCEDURE dbo.spEM_CreateSheetGroup
  @SheetGroup_Desc      nvarchar(50),
  @User_Id int,
  @SheetGroup_Id        int OUTPUT
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Can't create characteristic.
  --
 DECLARE @Insert_Id integer,@Sql nvarchar(1000)
Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_CreateSheetGroup',
                 convert(nVarChar(10),@SheetGroup_Desc) + ','  +  Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
select @Insert_Id = Scope_Identity()
 BEGIN TRANSACTION
  If Exists (select * from dbo.syscolumns where name = 'Sheet_Group_Desc_Local' and id =  object_id(N'[Sheet_Groups]'))
 	 Select @Sql =  'INSERT INTO Sheet_Groups(Sheet_Group_Desc_Local) VALUES(''' + replace(@SheetGroup_Desc,'''','''''') + ''')'
  Else
 	 Select @Sql =  'INSERT INTO Sheet_Groups(Sheet_Group_Desc) VALUES(''' + replace(@SheetGroup_Desc,'''','''''') + ''')'
  Execute(@Sql)
  SELECT @SheetGroup_Id = Sheet_Group_Id From Sheet_Groups Where Sheet_Group_Desc = @SheetGroup_Desc
  IF @SheetGroup_Id IS NULL
    BEGIN
      ROLLBACK TRANSACTION
     Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 where Audit_Trail_Id = @Insert_Id
      RETURN(1)
    END
  If Exists (select * from dbo.syscolumns where name = 'Sheet_Group_Desc_Local' and id =  object_id(N'[Sheet_Groups]'))
 	 If (@@Options & 512) = 0
 	   Begin
 	  	 Select @Sql =  'Update Sheet_Groups set Sheet_Group_Desc_Global = Sheet_Group_Desc_Local where Sheet_Group_Id = ' + Convert(nVarChar(10),@SheetGroup_Id)
   	  	 Execute (@Sql)
 	   End
  COMMIT TRANSACTION
 Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@SheetGroup_Id) where Audit_Trail_Id = @Insert_Id
 RETURN(0)
