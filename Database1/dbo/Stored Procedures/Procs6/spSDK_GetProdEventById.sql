CREATE PROCEDURE dbo.spSDK_GetProdEventById
 	 @EventId 	  	  	 INT
AS
-- This SP Is Maintained for backward compatibility only.
-- All builds after 215.508 call spSDK_AdHocProductionEvent Directly
DECLARE 	 @Filter 	 nvarchar(25)
SET 	 @Filter = '|1~1~1~' + CONVERT(VARCHAR, COALESCE(@EventId, 0))
EXECUTE 	 spSDK_AdHocProductionEvents 	 @Filter
