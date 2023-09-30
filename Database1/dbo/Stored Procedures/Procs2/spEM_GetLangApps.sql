CREATE PROCEDURE dbo.spEM_GetLangApps
@User_Id int
AS
select App_Id, App_Name from AppVersions
where Min_Prompt is NOT NULL and Max_Prompt is NOT NULL
Order By App_Name
