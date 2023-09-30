CREATE PROCEDURE dbo.spServer_StbGetBackRepeats
AS
Select Var_Id,PU_Id,Repeat_BackTime,dbo.fnServer_GetTimeZone(PU_Id),Debug
  From Variables_Base
  Where (Is_Active = 1) And 
        (Repeating Is Not Null) And
        (Repeating <> 0) And
        (Repeat_Backtime Is Not Null) And
        (Repeat_Backtime > 0) And
        (Repeat_Backtime < 50000)
  Order By PU_Id,Var_Desc
