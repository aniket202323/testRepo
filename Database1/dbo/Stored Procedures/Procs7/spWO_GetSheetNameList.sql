CREATE PROCEDURE [dbo].[spWO_GetSheetNameList]
AS
----------------------------------------------------------------
 -- Use Security groups for web apps if site parameter is enabled
----------------------------------------------------------------
IF EXISTS(SELECT 1 FROM Site_Parameters WHERE Parm_Id = 510 and HostName = '' and Value = 1)
BEGIN
 	 DECLARE @UserId int
 	 SELECT @UserId = user_id FROM User_Connections WHERE SPID = @@spid
 	 -- Determine the groups to which the user belongs
 	 DECLARE @SecurityGroup TABLE (
 	  	  	 GroupId int)
 	 INSERT INTO @SecurityGroup (GroupId)
 	  	 SELECT DISTINCT(Group_Id) FROM User_Security WHERE User_Id = @UserId 
 	  	 
 	 INSERT Into @SecurityGroup (GroupId)
 	 (select Group_Id from  User_Role_Security urs
 	 join User_Security us on urs.Role_User_Id=us.User_Id where urs.User_Id=@UserId) 	  	 
 	 ----------------------------------------------------------------
 	 -- Administrators --> Group_Id = 1
 	 ----------------------------------------------------------------
 	 IF NOT EXISTS(SELECT 1 FROM @SecurityGroup WHERE  GroupId = 1)
 	  	 BEGIN
 	  	  	  	 SELECT 	 s.Sheet_Desc SheetName, s.sheet_desc + ' (' + cast(count(sv.sheet_id) as nvarchar(10)) + ' variables)'  Sheet_Desc
 	  	  	  	 FROM sheet_variables sv
 	  	  	  	  	 JOIN sheets s ON s.sheet_id = sv.sheet_id
 	  	  	  	  	 JOIN Variables v ON sv.Var_Id = v.Var_Id
 	  	  	  	  	 JOIN PU_Groups pug ON v.PUG_Id = pug.PUG_Id
 	  	  	  	  	 JOIN Prod_Units pu ON pug.PU_Id = pu.PU_Id
 	  	  	  	  	 JOIN Prod_Lines pl ON pu.PL_Id 	 = pl.PL_Id 
 	  	  	  	  	 JOIN @SecurityGroup sg ON pl.Group_Id = sg.GroupId
 	  	  	  	 WHERE sv.Var_Id IS NOT NULL
 	  	  	  	 GROUP BY s.sheet_desc
 	  	  	  	 HAVING count(sv.sheet_id) >= 1
 	  	  	 UNION
 	  	  	  	 SELECT 	 s.Sheet_Desc SheetName, s.sheet_desc + ' (' + cast(count(sv.sheet_id) as nvarchar(10)) + ' variables)'  Sheet_Desc
 	  	  	  	 FROM sheet_variables sv
 	  	  	  	  	 JOIN sheets s ON s.sheet_id = sv.sheet_id
 	  	  	  	  	 JOIN Variables v ON sv.Var_Id = v.Var_Id
 	  	  	  	  	 JOIN PU_Groups pug ON v.PUG_Id = pug.PUG_Id
 	  	  	  	  	 JOIN Prod_Units pu ON pug.PU_Id = pu.PU_Id
 	  	  	  	  	 JOIN @SecurityGroup sg ON pu.Group_Id = sg.GroupId
 	  	  	  	 WHERE sv.Var_Id IS NOT NULL
 	  	  	  	 GROUP BY s.sheet_desc
 	  	  	  	 HAVING count(sv.sheet_id) >= 1 	  	  	 
 	  	  	 UNION
 	  	  	  	 SELECT 	 s.Sheet_Desc SheetName, s.sheet_desc + ' (' + cast(count(sv.sheet_id) as nvarchar(10)) + ' variables)'  Sheet_Desc
 	  	  	  	 FROM sheet_variables sv
 	  	  	  	  	 JOIN sheets s ON s.sheet_id = sv.sheet_id
 	  	  	  	  	 JOIN Variables v ON sv.Var_Id = v.Var_Id
 	  	  	  	  	 JOIN PU_Groups pug ON v.PUG_Id = pug.PUG_Id
 	  	  	  	  	 JOIN Prod_Units pu ON pug.PU_Id = pu.PU_Id
 	  	  	  	  	 JOIN @SecurityGroup sg ON pug.Group_Id = sg.GroupId
 	  	  	  	 WHERE sv.Var_Id IS NOT NULL
 	  	  	  	 GROUP BY s.sheet_desc
 	  	  	  	 HAVING count(sv.sheet_id) >= 1
 	  	  	 UNION
 	  	  	  	 SELECT 	 s.Sheet_Desc SheetName, s.sheet_desc + ' (' + cast(count(sv.sheet_id) as nvarchar(10)) + ' variables)'  Sheet_Desc
 	  	  	  	 FROM sheet_variables sv
 	  	  	  	  	 JOIN sheets s ON s.sheet_id = sv.sheet_id
 	  	  	  	  	 JOIN Variables v ON sv.Var_Id = v.Var_Id
 	  	  	  	  	 JOIN @SecurityGroup sg ON s.Group_Id = sg.GroupId
 	  	  	  	 WHERE sv.Var_Id IS NOT NULL
 	  	  	  	 GROUP BY s.sheet_desc
 	  	  	  	 HAVING count(sv.sheet_id) >= 1 	 
 	  	  	 RETURN
 	  	 END
 	 ELSE
 	  	 BEGIN
 	  	  	 GOTO DEFAULTROUTINE
 	  	 END
 	  	 
END
DEFAULTROUTINE:
SELECT s.Sheet_Desc SheetName, s.sheet_desc + ' (' + cast(count(sv.sheet_id) as nvarchar(10)) + ' variables)'  Sheet_Desc
FROM sheet_variables sv
 	 JOIN sheets s ON s.sheet_id = sv.sheet_id
WHERE sv.Var_Id IS NOT NULL
GROUP BY s.sheet_desc
HAVING count(sv.sheet_id) >= 1
