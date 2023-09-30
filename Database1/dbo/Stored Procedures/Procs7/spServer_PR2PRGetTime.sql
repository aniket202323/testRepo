CREATE PROCEDURE dbo.spServer_PR2PRGetTime
AS
  Select dbo.fnServer_CmnGetDate(GetUTCDate())
