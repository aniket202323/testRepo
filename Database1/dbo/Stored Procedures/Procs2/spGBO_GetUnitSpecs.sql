/* IMPORTANT : This proc is not used by the Proficy Operator, 
     it is left over from the GradeBook operator
     and required for backward compatibility */
Create Procedure dbo.spGBO_GetUnitSpecs 
@PU_Id int, 
@Prod_Id int, 
@STime datetime     
AS
  Select a.* 
    from var_specs a 
    join variables b on (b.var_id = a.var_id) and (b.pu_id = @PU_Id) 
    where (a.prod_id = @Prod_ID) and
          (a.effective_date <= @Stime) and  
          ((a.expiration_date > @Stime) or (a.expiration_date is NULL))
  return(100)
