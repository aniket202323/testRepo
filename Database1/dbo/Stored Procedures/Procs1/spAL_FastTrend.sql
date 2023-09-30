Create Procedure dbo.spAL_FastTrend @ProdId int, @VarId int  
 AS
  select t.result, vs.l_warning, vs.u_warning, vs.l_reject, vs.u_reject, 
    t.result_on from tests t join var_specs vs on t.var_id = vs.var_id where 
    vs.prod_id = @ProdId and vs.var_id = @VarId and t.result_on >= vs.Effective_Date and 
    (t.result_on <= vs.Expiration_Date or vs.Expiration_Date is null) order by result_on
