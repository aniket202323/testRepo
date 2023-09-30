Create Procedure dbo.spCHT_GetMissingSigmaData
@VarId int,
@TimeStamp datetime,
@DecimalSep char(1) = '.'
AS
  -- Declare local variables.
  DECLARE 
      @OLCL nvarchar(25),
      @OTCL nvarchar(25),
      @OUCL nvarchar(25),
      @prec 	 Int,
      @DataType Int,
      @Found 	 Int
Select @DecimalSep = Coalesce(@DecimalSep, '.')
 Select  @prec = Var_Precision,@DataType = v.Data_Type_Id 
  From Variables V 
   Where V.Var_Id = @VarId          
Select @Found = 0
SELECT  	 @OLCL = 	 ltrim(str(tsd.Mean - 3 * tsd.sigma,25,@prec)),
 	  	 @OTCL = 	 ltrim(str(tsd.Mean,25,@prec)),
 	  	 @OUCL = 	 ltrim(str(tsd.Mean + 3 * tsd.sigma,25,@prec)),
 	  	 @Found = 1
 	 FROM Tests t
 	 Join Test_Sigma_Data tsd on tsd.Test_Id = t.Test_Id 
 	 WHERE Var_Id =  @VarId and Result_On = @TimeStamp
IF @Found = 1
SELECT
        OLCL = Case When @DecimalSep <> '.' and @DataType = 2 Then Replace (@OLCL,'.', @DecimalSep) ELSE @OLCL END,
        OTCL = Case When @DecimalSep <> '.' and @DataType = 2 Then Replace (@OTCL,'.', @DecimalSep) ELSE @OTCL END,
        OUCL = Case When @DecimalSep <> '.' and @DataType = 2 Then Replace (@OUCL,'.', @DecimalSep) ELSE @OUCL END
