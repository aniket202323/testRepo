Create Procedure dbo.spAL_GetProfileData
  @Entry_On datetime,
  @Var_Id int,
  @DecimalSep char(1) = '.'
 AS
Create Table #Vars (Var_Id int)
Insert into #Vars
  Select Var_Id From Variables Where PVar_Id = @Var_Id
--  Must replace the period in the result value with a comma if the 
--  passed decimal separator is not a period.
Select @DecimalSep = COALESCE(@DecimalSep,'.')
DECLARE @DataType 	  	 Int
SELECT @DataType = Data_Type_Id 
  FROM Variables
  Where Var_Id = @Var_Id
  -- Get our Profile data.
  SELECT t.Canceled,
          Result = CASE 
                        WHEN @DecimalSep <> '.' and @DataType = 2 THEN REPLACE(T.Result, '.', @DecimalSep)
                        ELSE T.Result
                      END
  FROM Tests t
  Join #Vars v on v.Var_Id = t.Var_Id
  WHERE t.Result_on = @Entry_On
Drop Table #Vars
