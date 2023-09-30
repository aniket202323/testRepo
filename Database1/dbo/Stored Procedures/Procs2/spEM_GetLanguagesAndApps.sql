CREATE PROCEDURE dbo.spEM_GetLanguagesAndApps 
  AS
  Create Table #Apps(AppId Int,Min_Prompt Int)
  Insert Into #Apps (AppId,Min_Prompt)
 	 Select App_Id,Min_Prompt From appversions  Where Min_Prompt is not Null
  Select v.App_Id,v.App_Name
 	  from appversions v
 	 Join #Apps a on a.AppId = v.App_Id
 	 Order by v.App_Name
Drop Table #Apps
  Select Language_Id,Language_Desc from languages Where Enabled = 1  Order by Language_Desc
