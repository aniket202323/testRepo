CREATE PROCEDURE dbo.spEM_GetServerTime
 	 @Now Datetime OUTPUT 
  AS
  --
  SELECT @Now = dbo.fnServer_CmnGetDate(getutcdate())
  --
