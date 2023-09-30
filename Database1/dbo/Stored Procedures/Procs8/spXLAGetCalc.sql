CREATE PROCEDURE dbo.spXLAGetCalc @VarId integer 
AS
/* dbo.Calcs No longer exist. 
   select * from calcs where rslt_var_id = @ID
   MSI/MT/10-19-2000
*/
DECLARE 	 @Calculation varchar(50)
SELECT 	 @Calculation = Case CALC.Equation When NULL Then NULL Else CONVERT(Varchar(50), CALC.Equation) End
FROM 	 Variables VARS, Calculations CALC
WHERE 	 VARS.Calculation_ID = CALC.Calculation_ID
AND 	 VARS.Var_Id = @VarId
SELECT 	 @Calculation
