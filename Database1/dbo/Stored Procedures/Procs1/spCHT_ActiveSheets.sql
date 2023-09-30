Create Procedure dbo.spCHT_ActiveSheets AS
  SELECT Sheet_Id,Sheet_Desc FROM Sheets WHERE Is_Active = 1
    and sheet_type is null
