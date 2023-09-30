Create Procedure dbo.spRSQ_GetVariables 
@PU_Id int
AS
select var_id, var_desc, var_precision, data_type_id 
  from variables 
  where pu_id = @PU_Id
  order By var_desc
