 	 Create View dbo.VariablesNoAspect
 	  	 AS
 	  	 select a.Var_Id 	    
 	  	 FROM dbo.Variables_Base a
 	  	 Left JOIN dbo.Variables_Aspect_EquipmentProperty e on e.Var_Id = a.Var_Id 
 	  	 WHERE a.PU_Id  != 0 and  e.Var_Id is null
