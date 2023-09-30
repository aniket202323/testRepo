Create Procedure dbo.spEMPE_GetAllParms
@Mode 	  int,
@User_Id int
AS
If @Mode = 1
 select Parm_Name,p.Parm_Id,ft.ED_Field_Type_Id,ft.SP_Lookup,ft.Store_Id,p.Customize_By_Host
  from Parameters p 
  Join Ed_FieldTypes ft on ft.ED_Field_Type_Id = p.Field_Type_Id
  Where (system <> 1) and (Customize_By_Host = 1) and ((Parm_Type_Id = 0) or(Parm_Type_Id = 1))
  Order by Parm_Name
Else
 Begin
   If @User_Id > 50 or @User_Id = 1
 	    Select Parm_Name,p.Parm_Id,ft.ED_Field_Type_Id,ft.SP_Lookup,ft.Store_Id,p.Add_Delete,p.Customize_By_Host
 	     from Parameters p 
 	     Join Ed_FieldTypes ft on ft.ED_Field_Type_Id = p.Field_Type_Id
 	     Where (system <> 1) and (Add_Delete = 2 and p.Parm_Id not in (select Parm_Id from user_parameters where user_Id = @User_Id ))
 	  	  	 or (Add_Delete = 2 and Customize_By_Host = 1)
 	     Order by Parm_Name
   Else
 	    Select Parm_Name,p.Parm_Id,ft.ED_Field_Type_Id,ft.SP_Lookup,ft.Store_Id,p.Add_Delete,p.Customize_By_Host
 	     from Parameters p 
 	     Join Ed_FieldTypes ft on ft.ED_Field_Type_Id = p.Field_Type_Id
 	  	 Join User_Parameter_XRef ux on p.parm_Id = ux.parm_Id and ux.user_Id = @User_Id
 	     Where (system <> 1) and  (Add_Delete = 1 and p.Parm_Id not in (select Parm_Id from user_parameters where user_Id = @User_Id ))
 	  	  	 or (Add_Delete = 1 and Customize_By_Host = 1)
 	     Order by Parm_Name
 End
