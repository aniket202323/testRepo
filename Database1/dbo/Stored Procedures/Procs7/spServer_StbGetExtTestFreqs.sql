CREATE PROCEDURE dbo.spServer_StbGetExtTestFreqs 
 AS
Select Var_Id,PU_Id,Extended_Test_Freq
  From Variables_Base
  Where (Is_Active = 1) And 
        (Event_Type = 1 or Event_Type = 0) And
        (Extended_Test_Freq Is Not NULL) And
        (Extended_Test_Freq > 1)
  Order By PU_Id,Var_Desc
