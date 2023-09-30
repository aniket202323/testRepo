CREATE PROCEDURE dbo.spEM_CreateChar
  @Char_Desc      nvarchar(50),
  @Prop_Id        int,
  @User_Id int,
  @Char_Id        int OUTPUT
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Can't create characteristic.
  --
DECLARE @Insert_Id integer,@Sql nvarchar(1000)
Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_CreateChar',
                 @Char_Desc + ',' + convert(nVarChar(10), @Prop_Id) + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
select @Insert_Id = Scope_Identity()
  BEGIN TRANSACTION
  If Exists (select * from dbo.syscolumns where name = 'Char_Desc_Local' and id =  object_id(N'[Characteristics]'))
   Begin
 	  	 If (@@options & 512) > 0
 	  	   Begin
 	  	  	 Select @Sql =  'INSERT INTO Characteristics(Char_Desc_Local, Prop_Id)'
   	  	  	 Select @Sql = @Sql + ' VALUES(''' + replace(@Char_Desc,'''','''''') + ''','  + Convert(nVarChar(10),@Prop_Id) + ')'
 	  	   End
 	  	 Else
 	  	   Begin
 	  	  	 Select @Sql =  'INSERT INTO Characteristics(Char_Desc_Local,Char_Desc_Global, Prop_Id)'
   	  	  	 Select @Sql = @Sql + ' VALUES(''' + replace(@Char_Desc,'''','''''') + ''','''  +  replace(@Char_Desc,'''','''''') + ''','  + Convert(nVarChar(10),@Prop_Id) + ')'
 	  	   End
 	 End
  Else
 	 Begin
 	  	 Select @Sql =  'INSERT INTO Characteristics(Char_Desc, Prop_Id)'
   	  	 Select @Sql = @Sql + ' VALUES(''' + replace(@Char_Desc,'''','''''') + ''','  + Convert(nVarChar(10),@Prop_Id) + ')'
 	 End
  Execute(@Sql)
  SELECT @Char_Id = Char_Id From Characteristics Where Char_Desc = @Char_Desc and Prop_Id = @Prop_Id
  IF @Char_Id IS NULL
    BEGIN
      ROLLBACK TRANSACTION
      Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 where Audit_Trail_Id = @Insert_Id
      RETURN(1)
    END
  COMMIT TRANSACTION
  DECLARE @PropagateChars Int,@ProdFamId Int,@ProdId Int
  SELECT   @ProdFamId = Product_Family_Id,@PropagateChars = Auto_Sync_Chars  FROM  Product_Properties  where Prop_Id = @Prop_Id
  If  @PropagateChars = 1
  BEGIN
 	  	 Select @ProdId = Prod_Id From Products where Product_Family_Id = @ProdFamId and Prod_Code = @Char_Desc
 	  	   IF  @ProdId Is not Null
 	  	   BEGIN
 	  	  	 Update Characteristics set Prod_Id = @ProdId Where Char_Id = @Char_Id
 	  	  	 Execute spEM_PutProductCharacteristic  @ProdId, @Char_Id, @Prop_Id,@User_Id
 	  	   END
 	 END
  Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0 ,Output_Parameters = convert(nVarChar(10),@Char_Id)  where Audit_Trail_Id = @Insert_Id
  RETURN(0)
