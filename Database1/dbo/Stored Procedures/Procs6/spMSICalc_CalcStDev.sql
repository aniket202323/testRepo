-------------------------------------------------------------------------------
-- This calculation SP will determine the Standard Deviation of a group of variables
-- connected as Input Dependencies.
--
-- 2003-02-13 	 B.Seely 	  	 Original
-------------------------------------------------------------------------------
CREATE PROCEDURE dbo.spMSICalc_CalcStDev
 	 @OutputValue 	 nVarChar(25) 	 OUTPUT,
 	 @VarId 	  	  	 Int,
 	 @TimeStamp 	  	 DateTime,
 	 @AllRequired 	 Int = 0
AS
DECLARE 	 @TempValue 	 Float,
 	  	 @NumDependVars Int,
 	  	 @NumValues  	 Int
Select @AllRequired = isnull(@AllRequired,0)
SELECT 	 @OutputValue = ''
SELECT 	 @TempValue = StDev(Convert(Float, t.Result)),@NumValues = count(*)
 	 FROM 	 Tests t
 	 JOIN 	 Variables v ON t.Var_Id = v.Var_Id
 	 JOIN 	 Calculation_Instance_Dependencies cid ON v.Var_Id = cid.Var_Id
 	 WHERE 	 t.Result_On = @TimeStamp
 	 AND 	 cid.Result_Var_Id = @VarId
 	 AND 	 v.Data_Type_Id IN (1, 2)
    AND t.Result is not NULL
If @AllRequired = 1
BEGIN
 	 SELECT @NumDependVars = count(*) 
 	 FROM 	 Calculation_Instance_Dependencies
 	 WHERE Result_Var_Id = @VarId
 	 IF @NumDependVars <> @NumValues 
 	   RETURN
END
IF 	 IsNumeric(@TempValue) = 1
 	 SELECT 	 @OutputValue = Convert(nVarChar(25), @TempValue)
