CREATE PROCEDURE [dbo].[spWO_GetProdGroupList]
@UnitId int = Null
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
 	  	  	 SELECT PUG_Id, PUG_Desc
 	  	  	  	 FROM PU_Groups pug
 	  	  	  	 JOIN Prod_Units pu ON pug.PU_Id = pu.PU_Id
 	  	  	  	 JOIN Prod_Lines pl ON pu.PL_Id 	 = pl.PL_Id
 	  	  	  	 JOIN @SecurityGroup sg ON pl.Group_Id = sg.GroupId
 	  	  	  	 WHERE (@UnitId Is Null Or pu.PU_Id = @UnitId)
 	  	  	 UNION 	  	  	  	 
 	  	  	 SELECT PUG_Id, PUG_Desc
 	  	  	  	 FROM PU_Groups pug
 	  	  	  	 JOIN Prod_Units pu ON pug.PU_Id = pu.PU_Id
 	  	  	  	 JOIN @SecurityGroup sg ON pu.Group_Id = sg.GroupId
 	  	  	  	 WHERE (@UnitId Is Null Or pu.PU_Id = @UnitId)
 	  	  	 UNION
 	  	  	 SELECT PUG_Id, PUG_Desc
 	  	  	  	 FROM PU_Groups pug
 	  	  	  	 JOIN @SecurityGroup sg ON pug.Group_Id = sg.GroupId
 	  	  	  	 WHERE (@UnitId Is Null Or pug.PU_Id = @UnitId)
 	  	  	 ORDER BY PUG_Desc
 	  	  	 RETURN
 	  	 END
 	 ELSE
 	  	 BEGIN
 	  	  	 GOTO DEFAULTROUTINE
 	  	 END
 	 
END
DEFAULTROUTINE:
Select PUG_Id, PUG_Desc
 	 From 	 PU_Groups
 	 Where 	 (@UnitId Is Null Or PU_Id = @UnitId)
 	 Order By PUG_Desc
