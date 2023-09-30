CREATE procedure [dbo].[spWO_GetUnitList]
--Declare
@LineId int = NULL,
@UserId int = NULL
AS
----------------------------------------------------------------
 -- Use Security groups for web apps if site parameter is enabled
----------------------------------------------------------------
IF EXISTS(SELECT 1 FROM Site_Parameters WHERE Parm_Id = 510 and HostName = '' and Value = 1)
BEGIN
 	 IF @UserId IS NULL
 	  	 Begin
 	  	  	 SELECT @UserId = user_id FROM User_Connections WHERE SPID = @@spid
 	  	 End
 	 -- Determine the groups to which the user belongs
 	 DECLARE @SecurityGroup TABLE (GroupId int)
 	 INSERT INTO @SecurityGroup (GroupId)
 	  	 SELECT DISTINCT(Group_Id) FROM User_Security WHERE User_Id = @UserId 
 	 Insert Into @SecurityGroup (GroupId)
 	 (select Group_Id from  User_Role_Security urs
 	 join User_Security us on urs.Role_User_Id=us.User_Id where urs.User_Id=@UserId)
 	 ------------------------------------------------------------------ 
 	 -- Administrators --> Group_Id = 1
 	 ----------------------------------------------------------------
 	 IF NOT EXISTS(SELECT 1 FROM @SecurityGroup WHERE  GroupId = 1)
 	  	 BEGIN
 	  	  	 IF @LineId Is Null
 	  	  	  	 BEGIN
 	  	  	  	  	 SELECT PU_Id, PU_Desc
 	  	  	  	  	  	 FROM Prod_Units pu
 	  	  	  	  	  	 JOIN @SecurityGroup sg ON pu.Group_Id = sg.GroupId 
 	  	  	  	  	  	 WHERE PU_Id > 0
 	  	  	  	  	  	 ORDER BY PU_Desc
 	  	  	  	 END
 	  	  	 ELSE
 	  	  	  	 BEGIN 	 
 	  	  	  	  	 SELECT PU_Id, PU_Desc
 	  	  	  	  	  	 FROM Prod_Units pu
 	  	  	  	  	  	 JOIN Prod_Lines pl ON pu.PL_Id = pl.PL_Id
 	  	  	  	  	  	 JOIN @SecurityGroup sg ON pl.Group_Id = sg.GroupId 
 	  	  	  	  	  	 WHERE pl.PL_Id = @LineId  
 	  	  	  	  	 UNION
 	  	  	  	  	 SELECT PU_Id, PU_Desc
 	  	  	  	  	  	 FROM Prod_Units pu
 	  	  	  	  	  	 JOIN @SecurityGroup sg ON pu.Group_Id = sg.GroupId 
 	  	  	  	  	  	 WHERE pu.PL_Id = @LineId  
 	  	  	  	  	 ORDER BY PU_Desc 	  	 
 	    	  	  	 END
 	  	  	 RETURN
 	  	 END
 	 ELSE
 	  	 BEGIN
 	  	  	 GOTO DEFAULTROUTINE
 	  	 END
END
DEFAULTROUTINE:
If @LineId Is Null
  Select PU_Id, PU_Desc
 	 From Prod_Units 
 	 Where PU_Id > 0
 	 Order By PU_Desc
Else
  Select PU_Id, PU_Desc
 	 From Prod_Units 
 	 Where PL_Id = @LineId
 	 Order By PU_Desc 	 
