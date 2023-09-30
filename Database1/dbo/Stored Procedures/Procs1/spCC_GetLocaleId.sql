CREATE PROCEDURE dbo.spCC_GetLocaleId
@LanguageId int,
@LocaleId int OUTPUT
 AS 
Select @LocaleId = LocaleId 
  From Languages
    Where Language_Id = @LanguageId
RETURN
