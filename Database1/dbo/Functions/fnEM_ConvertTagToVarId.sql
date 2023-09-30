CREATE FUNCTION dbo.fnEM_ConvertTagToVarId(@TagDesc nvarchar(1000)) 
 	 Returns nvarchar(1000)
AS 
BEGIN
 	 Declare
 	   @LineDesc nvarchar(255),
 	   @UnitDesc nvarchar(255),
 	   @VarDesc nvarchar(255),
 	   @Pos int,
 	   @PLId int,
 	   @PUId int,
 	   @VarId 	 Int,
 	   @DefaultHistorian 	 nvarchar(255),
 	   @LocalHist 	 nvarchar(255),
 	   @Historian 	 nvarchar(255),
 	   @TagOnly 	 nvarchar(1000),
 	   @Temptag 	 nvarchar(1000)
 	 
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
 	  	 Select @TempTag = @TagOnly
 	  	 Select @Pos = CharIndex('.',@TempTag)
 	  	 If (@Pos = 0)
 	  	  	 Return @TagDesc
 	  	 Select @LineDesc = SubString(@TempTag,1,@Pos - 1)
 	  	 Select @TempTag = SubString(@TempTag,@Pos + 1,500)
 	  	 Select @Pos = CharIndex('.',@TempTag)
 	  	 If (@Pos = 0)
 	    	  	 Return @TagDesc
 	  	 Select @UnitDesc = SubString(@TempTag,1,@Pos - 1)
 	  	 Select @VarDesc = SubString(@TempTag,@Pos + 1,500)
 	  	 
 	  	 Select @PLId = NULL
 	  	 Select @PLId = PL_Id From Prod_Lines Where (REPLACE(REPLACE(REPLACE(PL_Desc,'.',''),' ',''),';','') = @LineDesc)
 	  	 If (@PLId Is NULL) 
 	    	  	 Return @TagDesc
 	  	 Select @PUId = NULL
 	  	 Select @PUId = PU_Id From Prod_Units Where (PL_Id = @PLId) And (REPLACE(REPLACE(REPLACE(PU_Desc,'.',''),' ',''),';','') = @UnitDesc) 
 	  	 If (@PUId Is NULL)
 	    	  	 Return @TagDesc
 	  	 Select @VarId = NULL
 	  	 Select @VarId = Var_Id From Variables Where (PU_Id = @PUId) And (REPLACE(REPLACE(REPLACE(Var_Desc,'.',''),' ',''),';','') = @VarDesc) 
 	  	 If (@VarId Is NULL)
 	    	  	 Return @TagDesc
 	  	 Else
 	  	   Return Replace(@TagDesc,@TagOnly,Convert(nVarChar(10),@VarId))
 	   End
 	 Return @TagDesc
END
