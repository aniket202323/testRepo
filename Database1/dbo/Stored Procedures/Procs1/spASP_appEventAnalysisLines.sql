create procedure [dbo].[spASP_appEventAnalysisLines]
@EventType int = Null,
@EventSubtype int = Null
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
 	  	  	 IF @EventType = 11
 	  	  	  	 SELECT DISTINCT [Id] = pl.pl_id, [Description] = pl.pl_desc  
 	  	  	  	  	 FROM variables v  
 	  	  	  	  	 JOIN Prod_units pu ON pu.pu_id = v.pu_id
 	  	  	  	  	 JOIN Prod_lines pl ON pl.pl_id = pu.pl_id
 	  	  	  	  	 JOIN alarm_template_var_data a on a.var_id = v.var_id 
 	  	  	  	  	 JOIN @SecurityGroup sg ON pl.Group_Id = sg.GroupId
 	  	  	 ELSE IF @EventType = -2
 	  	  	  	 SELECT DISTINCT [Id] = pl.PL_Id, [Description] = pl.pl_desc  
 	  	  	  	  	 FROM Prod_Lines pl
 	  	  	  	  	 JOIN Prod_units pu ON pu.PL_id = pl.PL_Id
 	  	  	  	  	 JOIN @SecurityGroup sg ON pl.Group_Id = sg.GroupId
 	  	  	  	 WHERE pu.PU_Id In (SELECT PU_Id FROM NonProductive_Detail)
 	  	  	 ELSE IF @EventSubType Is Not Null
 	  	  	  	 SELECT DISTINCT [Id] = pl.pl_id, [Description] = pl.pl_desc  
 	  	  	  	  	 FROM Event_Configuration ec
 	  	  	  	  	 JOIN Event_Types et ON et.et_id = ec.et_id
 	  	  	  	  	 LEFT OUTER JOIN Event_Subtypes es ON es.event_subtype_id = ec.event_subtype_id and es.event_subtype_id = @EventSubtype
 	  	  	  	  	 JOIN Prod_Units pu ON pu.pu_id = ec.pu_id
 	  	  	  	  	 JOIN Prod_lines pl ON pl.pl_id = pu.pl_id
 	  	  	  	  	 JOIN @SecurityGroup sg ON pl.Group_Id = sg.GroupId
 	  	  	  	 WHERE (ec.et_id = @EventType Or @EventType Is Null)
 	  	  	 ELSE
 	  	  	  	 SELECT DISTINCT [Id] = pl.pl_id, [Description] = pl.pl_desc  
 	  	  	  	  	 FROM Event_Configuration ec
 	  	  	  	  	 JOIN Prod_Units pu ON pu.pu_id = ec.pu_id
 	  	  	  	  	 JOIN Prod_lines pl ON pl.pl_id = pu.pl_id
 	  	  	  	  	 JOIN @SecurityGroup sg ON pl.Group_Id = sg.GroupId
 	  	  	  	 WHERE (ec.et_id = @EventType Or @EventType Is null)
 	  	  	  	  	 ORDER BY [Description] ASC
 	  	 RETURN
 	  	 END
 	 ELSE
 	  	 BEGIN
 	  	  	 GOTO DEFAULTROUTINE 	 
 	  	 END
END
DEFAULTROUTINE:
If @EventType = 11
  Select Distinct [Id] = pl.pl_id, [Description] = pl.pl_desc  
  From variables v  
  Join Prod_units pu on pu.pu_id = v.pu_id
  join Prod_lines pl on pl.pl_id = pu.pl_id
  Join alarm_template_var_data a on a.var_id = v.var_id 
Else If @EventType = -2
 	 Select Distinct [Id] = pl.PL_Id, [Description] = pl.pl_desc  
 	 From Prod_Lines pl
 	 Join Prod_units pu on pu.PL_id = pl.PL_Id
 	 Where pu.PU_Id In (Select PU_Id From NonProductive_Detail)
Else If @EventSubType Is Not Null
  Select Distinct [Id] = pl.pl_id, [Description] = pl.pl_desc  
  From Event_Configuration ec
  Join Event_Types et on et.et_id = ec.et_id
  Left Outer Join Event_Subtypes es on es.event_subtype_id = ec.event_subtype_id and es.event_subtype_id = @EventSubtype
  Join Prod_Units pu on pu.pu_id = ec.pu_id
  join Prod_lines pl on pl.pl_id = pu.pl_id
  Where (ec.et_id = @EventType Or @EventType Is Null)
Else
  Select Distinct [Id] = pl.pl_id, [Description] = pl.pl_desc  
  From Event_Configuration ec
  Join Prod_Units pu on pu.pu_id = ec.pu_id
  join Prod_lines pl on pl.pl_id = pu.pl_id
  Where (ec.et_id = @EventType Or @EventType Is null)
  order By [Description] ASC
