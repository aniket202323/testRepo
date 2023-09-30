CREATE PROCEDURE dbo.spEM_CreateProdGroup
  @Product_Grp_Desc nvarchar(50),
  @User_Id int,
  @Product_Grp_Id   int OUTPUT
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Can't create product group.
  --
DECLARE @Insert_Id integer,@Sql nvarchar(1000)
Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_CreateProdGroup',
                 @Product_Grp_Desc + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
select @Insert_Id = Scope_Identity()
 If Exists (select * from dbo.syscolumns where name = 'Product_Grp_Desc_Local' and id =  object_id(N'[Product_Groups]'))
 	 Select @Sql =  'INSERT INTO Product_Groups(Product_Grp_Desc_Local)'
  Else
 	 Select @Sql =  'INSERT INTO Product_Groups(Product_Grp_Desc)'
  Select @Sql = @Sql + ' VALUES(''' + replace(@Product_Grp_Desc,'''','''''') + ''')'
  Execute(@Sql)
  SELECT @Product_Grp_Id = Product_Grp_Id From Product_Groups Where Product_Grp_Desc = @Product_Grp_Desc
  IF @Product_Grp_Id IS NULL 
 	 BEGIN
 	      Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 where Audit_Trail_Id = @Insert_Id
 	      RETURN(1)
 	 END
  If Exists (select * from dbo.syscolumns where name = 'Product_Grp_Desc_Local' and id =  object_id(N'[Product_Groups]'))
 	 If (@@Options & 512) = 0
 	   Begin
 	  	 Select @Sql =  'Update Product_Groups set Product_Grp_Desc_Global = Product_Grp_Desc_Local where Product_Grp_Id = ' + Convert(nVarChar(10),@Product_Grp_Id)
   	  	 Execute (@Sql)
 	   End
  Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@Product_Grp_Id) where Audit_Trail_Id = @Insert_Id
  RETURN(0)
