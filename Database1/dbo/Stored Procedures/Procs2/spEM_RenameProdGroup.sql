CREATE PROCEDURE dbo.spEM_RenameProdGroup
  @Product_Grp_Id   int,
  @Product_Grp_Desc nvarchar(50),
  @User_Id int
  AS
  DECLARE @Insert_Id integer ,@Sql nvarchar(1000)
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_RenameProdGroup',
                Convert(nVarChar(10),@Product_Grp_Id) + ','  + 
                @Product_Grp_Desc + ','  + 
 	  	 Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
 --
  -- Return codes: 0 = Success.
  --
  If Exists (select * from dbo.syscolumns where name = 'Product_Grp_Desc_Local' and id =  object_id(N'[Product_Groups]'))
   Begin
 	   If (@@Options & 512) = 0
 	  	 Select @Sql =  'Update Product_Groups Set Product_Grp_Desc_Global = ''' + replace(@Product_Grp_Desc,'''','''''') + ''' Where Product_Grp_Id = ' + Convert(nVarChar(10),@Product_Grp_Id)
     Else
 	  	 Select @Sql =  'Update Product_Groups Set Product_Grp_Desc_Local = ''' + replace(@Product_Grp_Desc,'''','''''') + ''' Where Product_Grp_Id = ' + Convert(nVarChar(10),@Product_Grp_Id)
 	 End
  Else
 	 Select @Sql =  'Update Product_Groups Set Product_Grp_Desc = ''' + replace(@Product_Grp_Desc,'''','''''') + ''' Where Product_Grp_Id = ' + Convert(nVarChar(10),@Product_Grp_Id)
  Execute(@Sql)
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
