CREATE PROCEDURE dbo.spRS_GetWebPagePrompts
@PageName varchar(50)
 AS
Select *
From Report_WebPages
Where File_Name = @PageName
