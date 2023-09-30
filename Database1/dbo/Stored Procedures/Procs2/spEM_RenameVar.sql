CREATE PROCEDURE dbo.spEM_RenameVar
  @Var_Id      int,
  @Description nvarchar(50),
  @User_Id int
 AS
  DECLARE @Insert_Id Int
  DECLARE @LocalHistorian nvarchar(50), @InputTag nvarchar(255), @NewInputTag nvarchar(255)
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_RenameVar',
                Convert(nVarChar(10),@Var_Id) + ','  + 
                @Description + ','  + 
                Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --Update any base variables that reference the old variable name
  Select @LocalHistorian = '\\' + Alias + '\' From Historians Where Hist_Id = -1
  Select @InputTag = Replace(Replace(Replace(pl.PL_Desc,'.',''),':',''),' ','') + '.' + Replace(Replace(Replace(pu.PU_Desc,'.',''),':',''),' ','') + '.' + Replace(Replace(Replace(v.Var_Desc,'.',''),':',''),' ',''),@NewInputTag = Replace(Replace(Replace(pl.PL_Desc,'.',''),':',''),' ','') + '.' + Replace(Replace(Replace(pu.PU_Desc,'.',''),':',''),' ','') + '.'
    From Variables v
      Join Prod_Units pu on pu.PU_Id = v.PU_Id
      Join Prod_Lines pl on pl.PL_Id = pu.PL_Id
      Where v.Var_Id = @Var_Id
  Select @NewInputTag =@NewInputTag + Replace(Replace(Replace(@Description,'.',''),':',''),' ','')
  Select @InputTag = @LocalHistorian + @InputTag
  Select @NewInputTag = @LocalHistorian + @NewInputTag
  Update Variables_Base set Input_Tag = @NewInputTag Where Input_Tag = @InputTag
  --
 	 If (@@Options & 512) = 0
 	  	 Update Variables_base Set Var_Desc_Global = @Description Where Var_Id = @Var_Id
 	 Else
 	  	 Update Variables_base Set Var_Desc = @Description Where Var_Id = @Var_Id
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
