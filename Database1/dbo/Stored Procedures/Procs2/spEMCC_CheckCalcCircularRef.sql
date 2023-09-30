Create Procedure dbo.spEMCC_CheckCalcCircularRef
 	 @Var_Id  	 Int,
 	 @IsCircular     bit
AS 
Declare @MV_Var_Id  	 Int,
 	 @MV1_Var_Id  	 Int
/*
Create Table #MV(Var_Id Int)
Create Table #MV1(Var_Id Int)
    Insert Into #MV  Select Distinct Member_Var_Id 
 	  	  	 From Calculation_Input_Data cid
 	   	  	 Join Calculation_Inputs ci on  ci.Calc_Input_Id = cid.Calc_Input_Id
 	   	  	 Where Calc_Input_Attribute_Id = 7  and Member_Var_Id is not null and Result_Var_Id = @Var_Id
    Insert Into #MV  Select Distinct Var_Id 
 	  	  	 From calculation_Dependency_data 
 	  	  	 Where Result_Var_Id = @Var_Id 
    Insert Into #MV  Select Distinct Var_Id 
 	  	  	 From calculation_instance_Dependencies
 	  	  	 Where Result_Var_Id = @Var_Id 
  	 
Loop1:
 	 Delete From #MV1
 	 Insert Into #MV1  Select Distinct Member_Var_Id 
 	   From Calculation_Input_Data cid
 	   Join Calculation_Inputs ci on  ci.Calc_Input_Id = cid.Calc_Input_Id
 	   Where Calc_Input_Attribute_Id = 7  and Member_Var_Id is not null and Result_Var_Id in (Select Var_Id from #MV) 
 	 Insert Into #MV1  Select Distinct Var_Id 
 	   From calculation_Dependency_data
 	   Where Result_Var_Id  in (Select Var_Id from #MV)
 	 Insert Into #MV1 Select Distinct Var_Id 
 	   From calculation_instance_Dependencies
 	   Where Result_Var_Id  in (Select Var_Id from #MV)
   	  If (Select Count(*) From #MV1) > 0
 	     Begin
 	  	 Delete From #MV
 	  	 Insert Into #MV Select * From #MV1 
 	  	 IF (select Count(*) from #MV Where Var_Id = @Var_Id ) > 0
 	  	     Goto CircularRef
 	  	 Goto Loop1
 	     End
Drop Table #MV
Drop Table #MV1
Return (1)
CircularRef:
Drop Table #MV
Drop Table #MV1
Return (2)
*/
Return (1)
