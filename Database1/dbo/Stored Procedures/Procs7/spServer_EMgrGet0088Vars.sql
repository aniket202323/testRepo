CREATE PROCEDURE dbo.spServer_EMgrGet0088Vars
 AS
Declare @ValmetVars Table(MasterUnit int NULL, PU_Id int, Var_Id int, Var_Desc nVarChar(100) COLLATE DATABASE_DEFAULT, Data_Type_Id int, Sampling_Type int, Input_Tag nVarChar(100) COLLATE DATABASE_DEFAULT NULL, MachineDesc nvarchar(20) COLLATE DATABASE_DEFAULT NULL, PropId nVarChar(30) COLLATE DATABASE_DEFAULT NULL, VarPrecision int NULL)
Insert Into @ValmetVars (MasterUnit,PU_Id,Var_Id,Var_Desc,Data_Type_Id,Sampling_Type,Input_Tag,VarPrecision)
(Select b.Master_Unit,a.PU_Id,a.Var_Id,a.Var_Desc,a.Data_Type_Id,Sampling_Type = COALESCE(a.Sampling_Type,0),a.Input_Tag,a.Var_Precision
  From Variables_Base a
  Join Prod_Units_Base b on b.PU_Id = a.PU_Id
  Where (a.DS_Id = 12) And
        (a.Event_Type = 1) And
        (a.Input_Tag Is Not Null) And
        (CharIndex('\',a.Input_Tag) > 0))
Update @ValmetVars
  Set MasterUnit = PU_Id
  Where MasterUnit Is Null
Update @ValmetVars
  Set MachineDesc = SubString(Input_Tag,1,CharIndex('\',Input_Tag) - 1)
Update @ValmetVars
  Set Input_Tag = SubString(Input_Tag,CharIndex('\',Input_Tag) + 1,200)
Delete From @ValmetVars Where (Input_Tag Is Null)
Update @ValmetVars
  Set PropId = Input_Tag
Select MasterUnit,Var_Id,Var_Desc,Data_Type_Id,Sampling_Type,MachineDesc,PropId = Convert(int,PropId),VarPrecision = VarPrecision
  From @ValmetVars
