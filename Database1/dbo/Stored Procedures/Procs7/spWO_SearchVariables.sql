create procedure [dbo].[spWO_SearchVariables]
@LineId int = null,
@UnitId int = null,
@GroupId int = null,
@NameMask nVarChar(50) = null,
@UserId int = NULL
AS
/***************************
-- For Testing
--***************************
Select @UnitId = 2
Select @UserId = 1
Select @GroupId = 3
Select @NameMask = 'PM1'
SELECT @LineId 	 = Null
--***************************/
----------------------------------------------------------------
 -- Use Security groups for web apps if site parameter is enabled
----------------------------------------------------------------
IF EXISTS(SELECT 1 FROM Site_Parameters WHERE Parm_Id = 510 and HostName = '' and Value = 1)
BEGIN
 	 IF @UserId IS NULL
 	  	 BEGIN
 	  	  	 SELECT @UserId = user_id FROM User_Connections WHERE SPID = @@spid
 	  	 END
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
 	  	  	 SELECT @NameMask = coalesce(@NameMask, '')
 	  	  	 IF @GroupId IS NOT NULL
 	  	  	  	 BEGIN
 	  	  	  	  	 SELECT VariableId = Var_id, LongName = Var_Desc, ShortName = coalesce(test_name,Var_Desc), Tagname = input_tag
 	  	  	  	  	  	 FROM Variables v
 	  	  	  	  	  	  	 JOIN PU_Groups 	 pug 	  	 ON v.PUG_Id 	  	 = pug.PUG_Id
 	  	  	  	  	  	  	 JOIN Prod_Units pu 	  	 ON pug.PU_Id 	 = pu.PU_Id
 	  	  	  	  	  	  	 JOIN Prod_Lines pl 	  	 ON pu.PL_Id 	  	 = pl.PL_Id
 	  	  	  	  	  	  	 JOIN @SecurityGroup sg 	 ON pl.Group_Id 	 = sg.GroupId 
 	  	  	  	  	  	 WHERE pug.PUG_Id = @GroupId
 	  	  	  	  	  	  	 AND v.Var_Desc LIKE '%' + @NameMask + '%'
 	  	  	  	  	  	  	 AND v.data_type_id in (1,2,6,7)
 	  	  	  	  	  	  	 AND v.PU_Id >=1
 	  	  	  	  	  	  	 AND v.Is_Active = 1
 	  	  	  	  	 UNION
 	  	  	  	  	 SELECT VariableId = Var_id, LongName = Var_Desc, ShortName = coalesce(test_name,Var_Desc), Tagname = input_tag
 	  	  	  	  	  	 FROM Variables v
 	  	  	  	  	  	  	 JOIN PU_Groups 	 pug 	  	 ON v.PUG_Id 	  	 = pug.PUG_Id
 	  	  	  	  	  	  	 JOIN Prod_Units pu 	  	 ON pug.PU_Id 	 = pu.PU_Id
 	  	  	  	  	  	  	 JOIN @SecurityGroup sg 	 ON pu.Group_Id 	 = sg.GroupId 
 	  	  	  	  	  	 WHERE pug.PUG_Id = @GroupId
 	  	  	  	  	  	  	 AND v.Var_Desc LIKE '%' + @NameMask + '%'
 	  	  	  	  	  	  	 AND v.data_type_id in (1,2,6,7)
 	  	  	  	  	  	  	 AND v.PU_Id >=1 	 
 	  	  	  	  	  	  	 AND v.Is_Active = 1 	  	  	  	  	  	  	  	  	  	  	  	  	 
 	  	  	  	  	 UNION
 	  	  	  	  	 SELECT VariableId = Var_id, LongName = Var_Desc, ShortName = coalesce(test_name,Var_Desc), Tagname = input_tag
 	  	  	  	  	  	 FROM Variables v
 	  	  	  	  	  	  	 JOIN PU_Groups 	 pug 	  	 ON v.PUG_Id 	  	 = pug.PUG_Id
 	  	  	  	  	  	  	 JOIN @SecurityGroup sg 	 ON pug.Group_Id 	 = sg.GroupId 
 	  	  	  	  	  	 WHERE pug.PUG_Id = @GroupId
 	  	  	  	  	  	  	 AND v.Var_Desc LIKE '%' + @NameMask + '%'
 	  	  	  	  	  	  	 AND v.data_type_id in (1,2,6,7)
 	  	  	  	  	  	  	 AND v.PU_Id >=1
 	  	  	  	  	  	  	 AND v.Is_Active = 1 	  	  	  	  	  	  	 
 	  	  	  	 END
 	  	  	 ELSE IF @UnitId IS NOT NULL
 	  	  	  	 BEGIN
 	  	  	  	  	 SELECT VariableId = Var_id, LongName = Var_Desc, ShortName = coalesce(test_name,Var_Desc), Tagname = input_tag
 	  	  	  	  	  	 FROM Variables v
 	  	  	  	  	  	  	 JOIN PU_Groups 	 pug 	  	 ON v.PUG_Id 	  	 = pug.PUG_Id
 	  	  	  	  	  	  	 JOIN Prod_Units pu 	  	 ON pug.PU_Id 	 = pu.PU_Id
 	  	  	  	  	  	  	 JOIN Prod_Lines pl 	  	 ON pu.PL_Id 	  	 = pl.PL_Id
 	  	  	  	  	  	  	 JOIN @SecurityGroup sg 	 ON pl.Group_Id 	 = sg.GroupId 
 	  	  	  	  	  	 WHERE pu.PU_Id = @UnitId
 	  	  	  	  	  	  	 AND v.Var_Desc LIKE '%' + @NameMask + '%'
 	  	  	  	  	  	  	 AND v.data_type_id in (1,2,6,7)
 	  	  	  	  	  	  	 AND v.PU_Id >=1 	 
 	  	  	  	  	  	  	 AND v.Is_Active = 1 	  	  	  	  	  	  	  	  	  	  	  	  	 
 	  	  	  	  	 UNION
 	  	  	  	  	 SELECT VariableId = Var_id, LongName = Var_Desc, ShortName = coalesce(test_name,Var_Desc), Tagname = input_tag
 	  	  	  	  	  	 FROM Variables v
 	  	  	  	  	  	  	 JOIN PU_Groups 	 pug 	  	 ON v.PUG_Id 	  	 = pug.PUG_Id
 	  	  	  	  	  	  	 JOIN Prod_Units pu 	  	 ON pug.PU_Id 	 = pu.PU_Id
 	  	  	  	  	  	  	 JOIN @SecurityGroup sg 	 ON pu.Group_Id 	 = sg.GroupId 
 	  	  	  	  	  	 WHERE pu.PU_Id = @UnitId
 	  	  	  	  	  	  	 AND v.Var_Desc LIKE '%' + @NameMask + '%'
 	  	  	  	  	  	  	 AND v.data_type_id in (1,2,6,7)
 	  	  	  	  	  	  	 AND v.PU_Id >=1
 	  	  	  	  	  	  	 AND v.Is_Active = 1 	  	  	  	  	  	  	 
 	  	  	  	 END 	 
 	  	  	 ELSE IF @LineId IS NOT NULL
 	  	  	  	 BEGIN
 	  	  	  	  	 SELECT VariableId = Var_id, LongName = Var_Desc, ShortName = coalesce(test_name,Var_Desc), Tagname = input_tag
 	  	  	  	  	  	 FROM Variables v
 	  	  	  	  	  	  	 JOIN PU_Groups 	 pug 	  	 ON v.PUG_Id 	  	 = pug.PUG_Id
 	  	  	  	  	  	  	 JOIN Prod_Units pu 	  	 ON pug.PU_Id 	 = pu.PU_Id
 	  	  	  	  	  	  	 JOIN Prod_Lines pl 	  	 ON pu.PL_Id 	  	 = pl.PL_Id
 	  	  	  	  	  	  	 JOIN @SecurityGroup sg 	 ON pl.Group_Id 	 = sg.GroupId 
 	  	  	  	  	  	 WHERE pl.Pl_Id = @LineId
 	  	  	  	  	  	  	 AND v.Var_Desc LIKE '%' + @NameMask + '%'
 	  	  	  	  	  	  	 AND v.data_type_id in (1,2,6,7)
 	  	  	  	  	  	  	 AND v.PU_Id >=1
 	  	  	  	  	  	  	 AND v.Is_Active = 1 	  	  	  	  	  	  	 
 	  	  	  	 END 	 
 	  	  	 ELSE
 	  	  	  	 BEGIN
 	  	  	  	  	 SELECT VariableId = Var_id, LongName = Var_Desc, ShortName = coalesce(test_name,Var_Desc), Tagname = input_tag
 	  	  	  	  	  	 FROM Variables v
 	  	  	  	  	  	  	 JOIN PU_Groups 	 pug 	  	 ON v.PUG_Id 	  	 = pug.PUG_Id
 	  	  	  	  	  	  	 JOIN Prod_Units pu 	  	 ON pug.PU_Id 	 = pu.PU_Id
 	  	  	  	  	  	  	 JOIN Prod_Lines pl 	  	 ON pu.PL_Id 	  	 = pl.PL_Id
 	  	  	  	  	  	  	 JOIN @SecurityGroup sg 	 ON pl.Group_Id 	 = sg.GroupId 
 	  	  	  	  	  	 WHERE
 	  	  	  	  	  	  	 v.Var_Desc LIKE '%' + @NameMask + '%'
 	  	  	  	  	  	  	 AND v.data_type_id in (1,2,6,7)
 	  	  	  	  	  	  	 AND v.PU_Id >=1
 	  	  	  	  	  	  	 AND v.Is_Active = 1 	  	  	  	  	  	  	 
 	  	  	  	  	 UNION
 	  	  	  	  	 SELECT VariableId = Var_id, LongName = Var_Desc, ShortName = coalesce(test_name,Var_Desc), Tagname = input_tag
 	  	  	  	  	  	 FROM Variables v
 	  	  	  	  	  	  	 JOIN PU_Groups 	 pug 	  	 ON v.PUG_Id 	  	 = pug.PUG_Id
 	  	  	  	  	  	  	 JOIN Prod_Units pu 	  	 ON pug.PU_Id 	 = pu.PU_Id
 	  	  	  	  	  	  	 JOIN @SecurityGroup sg 	 ON pu.Group_Id 	 = sg.GroupId 
 	  	  	  	  	  	 WHERE
 	  	  	  	  	  	  	 v.Var_Desc LIKE '%' + @NameMask + '%'
 	  	  	  	  	  	  	 AND v.data_type_id in (1,2,6,7)
 	  	  	  	  	  	  	 AND v.PU_Id >=1
 	  	  	  	  	  	  	 AND v.Is_Active = 1 	  	  	  	  	  	  	 
 	  	  	  	  	 UNION
 	  	  	  	  	 SELECT VariableId = Var_id, LongName = Var_Desc, ShortName = coalesce(test_name,Var_Desc), Tagname = input_tag
 	  	  	  	  	  	 FROM Variables v
 	  	  	  	  	  	  	 JOIN PU_Groups 	 pug 	  	 ON v.PUG_Id 	  	 = pug.PUG_Id
 	  	  	  	  	  	  	 JOIN @SecurityGroup sg 	 ON pug.Group_Id 	 = sg.GroupId 
 	  	  	  	  	  	 WHERE
 	  	  	  	  	  	  	 v.Var_Desc LIKE '%' + @NameMask + '%'
 	  	  	  	  	  	  	 AND v.data_type_id in (1,2,6,7)
 	  	  	  	  	  	  	 AND v.PU_Id >=1 	 
 	  	  	  	  	  	  	 AND v.Is_Active = 1 	  	  	  	  	  	  	  	  	  	  	  	  	 
 	  	  	  	  	 UNION
 	  	  	  	  	 SELECT VariableId = Var_id, LongName = Var_Desc, ShortName = coalesce(test_name,Var_Desc), Tagname = input_tag
 	  	  	  	  	  	 FROM Variables v
 	  	  	  	  	  	  	 JOIN PU_Groups 	 pug 	  	 ON v.PUG_Id 	  	 = pug.PUG_Id
 	  	  	  	  	  	  	 JOIN @SecurityGroup sg 	 ON v.Group_Id 	 = sg.GroupId 
 	  	  	  	  	  	 WHERE
 	  	  	  	  	  	  	 v.Var_Desc LIKE '%' + @NameMask + '%'
 	  	  	  	  	  	  	 AND v.data_type_id in (1,2,6,7)
 	  	  	  	  	  	  	 AND v.PU_Id >=1 	 
 	  	  	  	  	  	  	 AND v.Is_Active = 1 	  	  	  	  	  	  	  	  	  	  	  	  	 
 	  	  	  	 END
 	  	  	 RETURN
 	  	 END
 	 ELSE
 	  	 BEGIN
 	  	  	 GOTO DEFAULTROUTINE
 	  	 END
END
DEFAULTROUTINE:
If @GroupId Is Not Null
  Begin
    If @NameMask Is Not Null
      Select VariableId = Var_id, LongName = Var_Desc, ShortName = coalesce(test_name,Var_Desc), Tagname = input_tag
        From Variables v
        left outer Join user_security s on s.group_id = v.group_id and s.user_id = @UserId
        Where v.pug_id = @GroupId and
              v.Var_desc like '%' + @NameMask + '%' and
              v.data_type_id in (1,2,6,7) and
              ((v.group_id is null) or (s.Access_level >= 1))
    Else
      Select VariableId = Var_id, LongName = Var_Desc, ShortName = coalesce(test_name,Var_Desc), Tagname = input_tag
        From Variables v
        left outer Join user_security s on s.group_id = v.group_id and s.user_id = @UserId
        Where v.pug_id = @GroupId and
              v.data_type_id in (1,2,6,7) and
              ((v.group_id is null) or (s.Access_level >= 1))
  End
Else If @UnitId Is Not Null
  Begin
    If @NameMask Is Not Null
      Select VariableId = Var_id, LongName = Var_Desc, ShortName = coalesce(test_name,Var_Desc), Tagname = input_tag
        From Variables v
        left outer Join user_security s on s.group_id = v.group_id and s.user_id = @UserId
        Where v.pu_id = @UnitId and
              v.Var_desc like '%' + @NameMask + '%' and
              v.data_type_id in (1,2,6,7) and
              ((v.group_id is null) or (s.Access_level >= 1))
    Else
      Select VariableId = Var_id, LongName = Var_Desc, ShortName = coalesce(test_name,Var_Desc), Tagname = input_tag
        From Variables v
        left outer Join user_security s on s.group_id = v.group_id and s.user_id = @UserId
        Where v.pu_id = @UnitId and
              v.data_type_id in (1,2,6,7) and
              ((v.group_id is null) or (s.Access_level >= 1))
  End
Else If @LineId Is Not Null
  Begin
    If @NameMask Is Not Null
      Select VariableId = Var_id, LongName = Var_Desc, ShortName = coalesce(test_name,Var_Desc), Tagname = input_tag
        From Variables v
        left outer Join user_security s on s.group_id = v.group_id and s.user_id = @UserId
        Where v.pu_id in (Select PU_Id From Prod_Units Where PL_Id = @LineId) and
              v.Var_desc like '%' + @NameMask + '%' and
              v.data_type_id in (1,2,6,7) and
              ((v.group_id is null) or (s.Access_level >= 1))
    Else
      Select VariableId = Var_id, LongName = Var_Desc, ShortName = coalesce(test_name,Var_Desc), Tagname = input_tag
        From Variables v
        left outer Join user_security s on s.group_id = v.group_id and s.user_id = @UserId
        Where v.pu_id in (Select PU_Id From Prod_Units Where PL_Id = @LineId) and
              v.data_type_id in (1,2,6,7) and
              ((v.group_id is null) or (s.Access_level >= 1))
  End
Else
  Begin
    If @NameMask Is Not Null
      Select VariableId = Var_id, LongName = Var_Desc, ShortName = coalesce(test_name,Var_Desc), Tagname = input_tag
        From Variables v
        left outer Join user_security s on s.group_id = v.group_id and s.user_id = @UserId
        Where v.Var_desc like '%' + @NameMask + '%'  and
              v.data_type_id in (1,2,6,7) and
              ((v.group_id is null) or (s.Access_level >= 1))
              and v.PU_Id <> 0
    Else
      Select VariableId = Var_id, LongName = Var_Desc, ShortName = coalesce(test_name,Var_Desc), Tagname = input_tag
        From Variables v
        left outer Join user_security s on s.group_id = v.group_id and s.user_id = @UserId
        Where v.data_type_id in (1,2,6,7) and
              ((v.group_id is null) or (s.Access_level >= 1))
              and v.PU_Id <> 0
  End
