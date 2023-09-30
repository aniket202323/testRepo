CREATE PROCEDURE [dbo].[spASP_wrGetLanguageIdUsingLCID]
@LCID int
AS
BEGIN
SELECT Language_id,LocaleId FROM Language_Locale_Conversion WHERE localeId = @LCID
END
