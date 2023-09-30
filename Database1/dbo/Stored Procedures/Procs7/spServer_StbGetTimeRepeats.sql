CREATE PROCEDURE dbo.spServer_StbGetTimeRepeats
AS
Select Var_Id,
       PU_Id,
       Sampling_Interval,
       Sampling_Offset = COALESCE(Sampling_Offset,0),
       Var_Precision = COALESCE(Var_Precision,0),
       dbo.fnServer_GetTimeZone(PU_Id),
 	  	  	  Debug
  From Variables_Base 
  Where (Is_Active = 1) And 
        (DS_Id = 2) And 
        (Sampling_Interval > 1) And 
        (Sampling_Interval Is Not Null) And
        (Event_Type = 0) And
        (Repeating <> 0) And
        (Repeating Is Not Null)
  Order By PU_Id,Var_Desc
