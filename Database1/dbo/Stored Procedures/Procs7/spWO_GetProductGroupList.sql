CREATE procedure [dbo].[spWO_GetProductGroupList]
@VariableId int = Null
AS
Declare @UnitId int
If @VariableId Is Not Null
 	 Select @UnitId = Case When Master_Unit Is Null Then PU_Id Else Master_Unit End
  From Prod_Units 
  Where PU_Id = (Select PU_Id From Variables Where Var_Id = @VariableId)
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
 	  	  	 SELECT DISTINCT GroupId = pg.Product_Grp_Id, GroupDescription = pg.Product_Grp_Desc
 	  	  	  	 FROM Product_Groups pg
 	  	  	  	 JOIN Product_Group_Data pgd on pgd.Product_Grp_id = pg.Product_Grp_Id
 	  	  	  	 JOIN pu_products pup on pup.prod_id = pgd.prod_id
 	  	  	  	 JOIN Products p ON p.Prod_Id = pgd.Prod_Id
 	  	  	  	 JOIN Product_Family pf ON pf.Product_Family_Id = p.Product_Family_Id
 	  	  	  	 JOIN @SecurityGroup sg ON pf.Group_Id = sg.GroupId
 	  	  	  	 WHERE (@UnitId Is Null Or pup.pu_id = @UnitId)
 	  	  	 RETURN
 	  	 END
 	 ELSE
 	  	 BEGIN
 	  	  	 GOTO DEFAULTROUTINE
 	  	 END
 	 
END
DEFAULTROUTINE:
Select Distinct GroupId = pg.Product_Grp_Id, GroupDescription = pg.Product_Grp_Desc
  From Product_Groups pg
  Join Product_Group_Data pgd on pgd.Product_Grp_id = pg.Product_Grp_Id
  Join pu_products pup on pup.prod_id = pgd.prod_id
 	 Where (@UnitId Is Null Or pup.pu_id = @UnitId)
