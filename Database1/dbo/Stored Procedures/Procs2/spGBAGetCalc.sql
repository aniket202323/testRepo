Create Procedure dbo.spGBAGetCalc @ID integer 
 AS
  select * from calcs where rslt_var_id = @ID
