Create Procedure dbo.spAL_InactiveSheets AS
  SELECT Sheet_Id, Sheet_Desc, Event_Type FROM Sheets WHERE Is_Active = 0 and sheet_type is null
