CREATE PROCEDURE dbo.spAL_ActiveSheets AS
  SELECT Sheet_Id,Sheet_Desc FROM Sheets WHERE Is_Active = 1
    and (sheet_type is null OR sheet_type in (1,2)) OR (Sheet_Type = 16 and Event_Type = 0 and Master_Unit IS NOT NULL)
