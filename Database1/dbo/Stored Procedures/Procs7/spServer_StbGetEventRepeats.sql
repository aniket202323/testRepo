CREATE PROCEDURE dbo.spServer_StbGetEventRepeats
@MasterUnit int
AS
Declare @VarData Table (Var_Id int,Var_Desc nVarChar(255),PU_Id int,Debug bit null,Event_Type int,Event_SubType_Id int null)
insert into @VarData (Var_Id,Var_Desc,PU_Id,Debug,Event_Type,Event_SubType_Id)
Select Var_Id,Var_Desc,PU_Id,Debug,Event_Type,Coalesce(Event_SubType_Id,0)
  From Variables_Base
  Where (Is_Active = 1) And 
        (PU_Id In (Select PU_Id From Prod_Units_Base Where (PU_Id = @MasterUnit) Or (Master_Unit = @MasterUnit))) And
        (DS_Id = 2) And
        (Repeating Is Not Null) And
        (Repeating <> 0) And
        (Event_Type in (1,2,3,14,22))
-- We don't support Subtypes on Prod Events
Update @VarData set Event_SubType_Id = 0 where Event_Type = 1
Select Var_Id,PU_Id,Debug,Event_Type,Event_SubType_Id
  From @VarData
  Order By PU_Id,Var_Desc
