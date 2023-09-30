Create Procedure dbo.spEMEC_GetProdUnits
 	 @LineId Int,
 	 @Event_Type tinyint,
 	 @User_Id int
 AS
Select pu.PU_Id,PU_Desc,Master_Unit,Name_Id
 	 From Prod_Units pu
 	 Join Prod_Events pe on pe.Pu_Id = pu.Pu_Id
 	 Where (pu.PU_Id = @LineId or master_unit  =@LineId)  And pe.Event_Type = @Event_Type
