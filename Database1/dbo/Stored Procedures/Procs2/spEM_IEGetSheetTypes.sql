CREATE PROCEDURE dbo.spEM_IEGetSheetTypes
  AS
Select Import_Order,IE_Type_Desc from Import_Export_Types Order by Import_Order
