CREATE PROCEDURE dbo.spCC_LoadLanguages
 AS 
-- Load all languages from the languages table
Select Language_Id, Language_Desc
  From Languages
    Where Enabled = 1
    Order by Language_Desc
