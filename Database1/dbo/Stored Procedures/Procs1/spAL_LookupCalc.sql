Create Procedure dbo.spAL_LookupCalc
@var_id int 
AS
Select Member = cid.Member_Var_Id, 
       Alias = ci.Alias,
       Valid = Case
                  When ((ci.Calc_Input_Entity_Id = 3) and 
                        (ci.Calc_Input_Attribute_Id = 7) and 
                        --(ci.Optional = 0) and 
                        (c.Calculation_Type_Id = 1))      Then 1 
 	  	  	  	   WHEN ci.Calc_Input_Entity_Id = 1  THEN 1
 	  	  	  	   Else 0  
               End,
       Equation = c.Equation,
 	    ConstValue = Case When ci.Calc_Input_Entity_Id = 1 THEN Coalesce(cid.Default_Value,ci.Default_Value) Else Null END
  From Calculation_Input_Data cid
  Join Calculation_Inputs ci on ci.Calc_Input_Id = cid.Calc_Input_Id
  Join Calculations c on c.Calculation_ID = ci.Calculation_ID
  Join Variables v on v.Calculation_ID = c.Calculation_ID and v.Var_Id = @Var_id
  Where cid.Result_Var_Id = @Var_id
  Order By ci.Alias
