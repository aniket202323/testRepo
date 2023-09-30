CREATE PROCEDURE [dbo].[spRS_WWWGetUserInformation]
 	 @User_Id int 
, 	 @Host_Name varchar(50) = 'localhost'
 AS
Declare @Language_Id int
Declare @No_Count int
Declare @Site_Language_Id int
----------------------------
-- Get The Site Language Id
----------------------------
Select @Site_Language_Id = Convert(int, Value) From Site_Parameters Where Parm_Id = 8
If @Site_Language_Id Is Null
  Select @Site_Language_Id = 0
----------------------------
-- Get The Users Language Id
----------------------------
Select @Language_Id = Convert(int, Language_Id) From Client_Connections Where HostName = @Host_Name And Process_Id = -999 --Added to get language id from regional settings
If @Language_Id Is Null
  Select @Language_Id = @Site_Language_Id
If @Language_Id = @Site_Language_Id
  Select @No_Count = 1 -- Local Regional Settings Set NoCount On (True)
Else
  Select @No_Count = 0 -- Global Regional Settings Set NoCount Off (False)
----------------------------
-- Query
----------------------------
Select U.User_Id, @No_Count 'No_Count', @Language_Id 'Language_Id', @Site_Language_Id 'Site_Language_Id', U.User_Desc, U.UserName, U.Password, U.WindowsUserInfo, RTU.User_Rights, RTU.View_Setting, RTU.Report_Tree_Template_Id
from users U 
Join report_Tree_Users RTU on U.User_Id = RTU.User_Id
where U.user_Id = @User_Id
