CREATE PROCEDURE dbo.spCSS_LookupDec1000Sep
@Locale nvarchar(25),
@DecimalSep char(1) OUTPUT,
@ThousandsSep char(1) OUTPUT 
AS
set nocount on 
if @Locale in (
  '00000436', 
  '00000C09', 
  '00001009', 
  '00002409', 
  '00001809', 
  '00002009', 
  '00001409', 
  '00001C09', 
  '00000809', 
  '00000409'
  ) 
  BEGIN
    Select @DecimalSep = '.', @ThousandsSep = ','
  END
else 
  --German (Switzerland)
  If @Locale = '00000807'
    BEGIN
 	     Select @DecimalSep = '.', @ThousandsSep = char(39) --apostrophe character
    END
  else
 	   BEGIN
 	     Select @DecimalSep = ',', @ThousandsSep = '.'
 	   END
