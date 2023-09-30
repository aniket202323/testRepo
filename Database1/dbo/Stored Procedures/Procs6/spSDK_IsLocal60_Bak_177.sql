CREATE procedure [dbo].[spSDK_IsLocal60_Bak_177]
@LocaleId int
AS
Declare
  @LanguageId int,
  @SiteLanguageId int
Select @LanguageId = NULL
select @LanguageId from language_locale_conversion where localeid = @LocaleId
If (@LanguageId = NULL)
 	 Select @LanguageId = 0
 	 
Select @SiteLanguageId = NULL
select @SiteLanguageId = coalesce(value,0)from site_parameters where Parm_Id  = 8
If (@SiteLanguageId = NULL)
 	 Select @SiteLanguageId = 0
if (@LanguageId = @SiteLanguageId)
 	 return(1)
 	 
return(0)
