CREATE PROCEDURE dbo.spServer_EMgrGet0650Vars
@MasterUnit int
AS
Select Var_Id,Data_Type_Id
  From Variables_Base 
  Where (Event_Type = 1) And
        (Is_Conformance_Variable = 1) And
 	 PU_Id in (Select PU_Id From Prod_Units_Base Where (PU_Id = @MasterUnit) or (Master_Unit = @MasterUnit))
