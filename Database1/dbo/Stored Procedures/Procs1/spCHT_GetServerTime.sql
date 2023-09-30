Create Procedure dbo.spCHT_GetServerTime
 	 @Now Datetime_ComX OUTPUT 
 AS
  --
  SELECT @Now = dbo.fnServer_CmnGetDate(getUTCdate()) 
  --
