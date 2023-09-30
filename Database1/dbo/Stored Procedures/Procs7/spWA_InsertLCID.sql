CREATE PROCEDURE [dbo].[spWA_InsertLCID]
  @LCID INT
, @Host_Name nVarChar(50) = 'localhost'
AS
IF @LCID IS NULL
  RETURN
DECLARE @LangId INT
SELECT @LangId = Language_Id
FROM Language_Locale_Conversion
WHERE  LocaleId = @LCID
IF @LangId IS NULL
BEGIN
  SET @LangId = 0
END
DELETE FROM Client_Connections
WHERE HostName = @Host_Name And Process_Id = -999
INSERT INTO Client_Connections
(LocalId,HostName,Language_Id,Process_Id,start_time)
VALUES(@LCID, @Host_Name,@LangId,-999,dbo.fnServer_CmnGetDate(getutcdate()))
