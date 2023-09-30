CREATE PROCEDURE dbo.spServer_StbGetEventSheetStubs 
 AS
Select a.Sheet_Id,
       a.Master_Unit,
       a.Sheet_Desc,
       b.PU_Desc,
       a.Interval,
       a.Offset,
       a.Sheet_Type,
       a.Event_Subtype_Id,
       dbo.fnServer_GetTimeZone(a.Master_Unit)
  From Sheets a
  Join Prod_Units b on (b.PU_Id = a.Master_Unit) And (b.Master_Unit Is NULL)
  Where (a.Sheet_Type In (16,20,21,22,23,24,25,26)) And (a.Master_Unit Is Not NULL)
  Order by a.Sheet_Type,a.Sheet_Desc
