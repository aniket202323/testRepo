Create Procedure dbo.spEM_CreateCharGroup
  @CharGroup_Desc      nvarchar(50),
  @Prop_Id        int,
  @User_Id int,
  @CharGroup_Id        int OUTPUT
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Can't create characteristic.
  --
DECLARE @Insert_Id integer,@Sql nvarchar(1000)
Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_CreateCharGroup',
                 @CharGroup_Desc + ',' + convert(nVarChar(10),@Prop_Id) + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  Select @Insert_Id = Scope_Identity()
  BEGIN TRANSACTION
  If Exists (select * from dbo.syscolumns where name = 'Characteristic_Grp_Desc_Local' and id =  object_id(N'[Characteristic_Groups]'))
   Begin
 	  	 If @@options & 512 > 0
 	  	  	 Select @Sql =  'INSERT INTO Characteristic_Groups(Characteristic_Grp_Desc_Local, Prop_Id) VALUES(''' + replace(@CharGroup_Desc,'''','''''') + ''',' + Convert(nVarChar(10),@Prop_Id) + ')'
 	  	 Else
 	  	  	 Select @Sql =  'INSERT INTO Characteristic_Groups(Characteristic_Grp_Desc_Local,Characteristic_Grp_Desc_Global, Prop_Id) VALUES(''' + replace(@CharGroup_Desc,'''','''''') + ''','''  + replace(@CharGroup_Desc,'''','''''') + ''',' + Convert(nVarChar(10),@Prop_Id) + ')'
 	 End
  Else
 	   Select @Sql =  'INSERT INTO Characteristic_Groups(Characteristic_Grp_Desc, Prop_Id) VALUES(''' + replace(@CharGroup_Desc,'''','''''') + ''',' + Convert(nVarChar(10),@Prop_Id) + ')'
  Execute(@Sql)
  SELECT @CharGroup_Id = Characteristic_Grp_Id From Characteristic_Groups Where Characteristic_Grp_Desc = @CharGroup_Desc and Prop_Id = @Prop_Id
  IF @CharGroup_Id IS NULL
    BEGIN
      ROLLBACK TRANSACTION
      Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 where Audit_Trail_Id = @Insert_Id
     RETURN(1)
    END
  COMMIT TRANSACTION
  Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@CharGroup_Id) where Audit_Trail_Id = @Insert_Id
  RETURN(0)
