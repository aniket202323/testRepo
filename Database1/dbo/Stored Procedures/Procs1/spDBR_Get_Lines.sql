Create Procedure dbo.spDBR_Get_Lines
AS 	 
----------------------------------------------------------------
 -- Use Security groups for web apps if site parameter is enabled
----------------------------------------------------------------
IF EXISTS(SELECT 1 FROM Site_Parameters WHERE Parm_Id = 510 and HostName = '' and Value = 1)
BEGIN
 	 DECLARE @UserId int
 	 SELECT @UserId = user_id FROM User_Connections WHERE SPID = @@spid
 	 -- Determine the groups to which the user belongs
 	 DECLARE @SecurityGroup TABLE (GroupId int)
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
 	  	  	 SELECT PL_Id, PL_Desc
 	  	  	  	 FROM Prod_Lines pl
 	  	  	  	 JOIN @SecurityGroup sg ON pl.Group_Id = sg.GroupId
 	  	  	  	 WHERE PL_Id > 0
 	  	  	  	 ORDER BY PL_Desc
 	  	  	 RETURN
 	  	 END
 	 ELSE
 	  	 BEGIN
 	  	  	 GOTO DEFAULTROUTINE
 	  	 END
END
DEFAULTROUTINE:
select PL_ID, PL_Desc from Prod_Lines where pl_id > 0 order by pl_desc
