Create Procedure dbo.spDBR_Get_LanguageID
 @LCID INT
AS
DECLARE @LangId int
SET @LangId = 0
Select @LangId = Language_Id From Language_Locale_Conversion Where LocaleID = @LCID
Select @LangId as Language_Id
