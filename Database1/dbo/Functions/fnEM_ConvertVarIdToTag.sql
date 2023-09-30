CREATE FUNCTION dbo.fnEM_ConvertVarIdToTag(@TagDesc nvarchar(1000)) 
 	 Returns nvarchar(1000)
AS 
BEGIN
 	 Declare
 	   @LineDesc nvarchar(255),
 	   @UnitDesc nvarchar(255),
 	   @VarDesc nvarchar(255),
 	   @Pos int,
 	   @PLDesc nvarchar(50),
 	   @PUDesc nvarchar(50),
 	   @VarId 	 Int,
 	   @DefaultHistorian 	 nvarchar(255),
 	   @LocalHist 	 nvarchar(255),
 	   @Historian 	 nvarchar(255),
 	   @TagOnly 	 nvarchar(1000)
 	 
 	 If @TagDesc is null or @TagDesc = ''
 	  	 Return @TagDesc
 	 
 	 Select @TagOnly = case 
 	             When (CharIndex('\\',@TagDesc) = 0)  Then @TagDesc
 	             When (CharIndex('\\',@TagDesc) = 1)Then SubString(@TagDesc,CharIndex('\',SubString(@TagDesc,3,1000)) + 3,1000)
 	  	  	 End
 	 
 	 Select @LocalHist = Alias From Historians Where Hist_Id = -1
 	 Select @DefaultHistorian = Alias From Historians Where Hist_Default = 1
 	 Select @Historian = case 
 	             When (CharIndex('\\',@TagDesc) = 0)  Then @DefaultHistorian
 	             When (CharIndex('\\',@TagDesc) = 1)Then SubString(@TagDesc,3,CharIndex('\',SubString(@TagDesc,3,1000)) - 1)
 	  	  	 End
 	 If @Historian = @LocalHist
 	   Begin
 	  	 If Isnumeric(@TagOnly) = 0
 	  	  	 Return @TagDesc
 	  	 Select @PLDesc = PL_Desc,@PUDesc = PU_Desc,@VarDesc = Var_Desc 
 	  	  	 From Variables v
 	  	  	 Join Prod_Units pu On pu.PU_Id = v.PU_Id
 	  	  	 Join Prod_Lines pl on pl.PL_Id = pu.PL_Id
 	  	  	 Where Var_Id = @TagOnly
 	  	 Select @PLDesc =  REPLACE(REPLACE(REPLACE(@PLDesc,'.',''),' ',''),';','')
 	  	 Select @PUDesc =  REPLACE(REPLACE(REPLACE(@PUDesc,'.',''),' ',''),';','')
 	  	 Select @VarDesc = REPLACE(REPLACE(REPLACE(@VarDesc,'.',''),' ',''),';','')
 	  	 If @Historian = @DefaultHistorian
 	  	  	 Return @PLDesc + '.' + @PUDesc + '.' + @VarDesc
 	  	 Else
 	  	  	 Return '\\' + @Historian + '\' + @PLDesc + '.' + @PUDesc + '.' + @VarDesc
 	   End
 	 Return @TagDesc
END
