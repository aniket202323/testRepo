create procedure [dbo].[spASP_appEventAnalysisUnits]
--declare 
@EventType int,
@EventSubtype int = Null,
@LineId int = Null,
@UserId int = NULL
AS
/***************************
-- For Testing
--***************************
Select @EventType = 2
Select @EventSubtype = null
Select @LineId = 2
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
 	  	  	 IF @EventType = 11
 	  	  	  	 SELECT DISTINCT Id = mu.pu_id, Description = mu.pu_desc  
 	  	  	  	  	 FROM variables v  
 	  	  	  	  	 JOIN Prod_units pu ON pu.pu_id = v.pu_id and (@LineId Is Null Or pu.pl_id = @LineId)
 	  	  	  	  	 JOIN Prod_Units mu ON mu.pu_id = case when pu.master_unit Is Null Then pu.pu_id Else pu.master_unit End
 	  	  	  	  	 JOIN alarm_template_var_data a ON a.var_id = v.var_id 
 	  	  	  	  	 JOIN Prod_Lines pl ON mu.PL_Id = pl.PL_Id
 	  	  	  	  	 JOIN @SecurityGroup sg ON pl.Group_Id = sg.GroupId
 	  	  	  	 UNION
 	  	  	  	 SELECT DISTINCT Id = mu.pu_id, Description = mu.pu_desc  
 	  	  	  	  	 FROM variables v  
 	  	  	  	  	 JOIN Prod_units pu ON pu.pu_id = v.pu_id and (@LineId Is Null Or pu.pl_id = @LineId)
 	  	  	  	  	 JOIN Prod_Units mu ON mu.pu_id = case when pu.master_unit Is Null Then pu.pu_id Else pu.master_unit End
 	  	  	  	  	 JOIN alarm_template_var_data a ON a.var_id = v.var_id 
 	  	  	  	  	 JOIN @SecurityGroup sg ON mu.Group_Id = sg.GroupId
 	  	  	 ELSE IF @EventType = -2
 	  	  	  	 SELECT DISTINCT Id = pu.pu_id, Description = pu.pu_desc   
 	  	  	  	  	 FROM Prod_units pu
 	  	  	  	  	 JOIN Prod_Lines pl ON pu.PL_Id = pl.PL_Id
 	  	  	  	  	 JOIN @SecurityGroup sg ON pl.Group_Id = sg.GroupId
 	  	  	  	  	 WHERE pu.PU_Id In (SELECT PU_Id From NonProductive_Detail)
 	  	  	  	 UNION
 	  	  	  	 SELECT DISTINCT Id = pu.pu_id, Description = pu.pu_desc   
 	  	  	  	  	 FROM Prod_units pu
 	  	  	  	  	 JOIN @SecurityGroup sg ON pu.Group_Id = sg.GroupId
 	  	  	  	  	 WHERE pu.PU_Id In (SELECT PU_Id From NonProductive_Detail)
 	  	  	 ELSE IF @EventSubType Is Not Null
 	  	  	  	 SELECT DISTINCT Id = ec.pu_id, Description = pu.pu_desc  
 	  	  	  	  	 FROM Event_Configuration ec
 	  	  	  	  	 JOIN Event_Types et ON et.et_id = ec.et_id
 	  	  	  	  	 LEFT OUTER JOIN Event_Subtypes es ON es.event_subtype_id = ec.event_subtype_id and es.event_subtype_id = @EventSubtype
 	  	  	  	  	 JOIN Prod_Units pu ON pu.pu_id = ec.pu_id and (@LineId Is Null Or pu.pl_id = @LineId)
 	  	  	  	  	 JOIN Prod_Lines pl ON pu.PL_Id = pl.PL_Id
 	  	  	  	  	 JOIN @SecurityGroup sg ON pl.Group_Id = sg.GroupId
 	  	  	  	  	 WHERE (ec.et_id = @EventType Or @EventType Is Null)
 	  	  	  	 UNION
 	  	  	  	 SELECT DISTINCT Id = ec.pu_id, Description = pu.pu_desc  
 	  	  	  	  	 FROM Event_Configuration ec
 	  	  	  	  	 JOIN Event_Types et ON et.et_id = ec.et_id
 	  	  	  	  	 LEFT OUTER JOIN Event_Subtypes es ON es.event_subtype_id = ec.event_subtype_id and es.event_subtype_id = @EventSubtype
 	  	  	  	  	 JOIN Prod_Units pu ON pu.pu_id = ec.pu_id and (@LineId Is Null Or pu.pl_id = @LineId)
 	  	  	  	  	 JOIN @SecurityGroup sg ON pu.Group_Id = sg.GroupId
 	  	  	  	  	 WHERE (ec.et_id = @EventType Or @EventType Is Null)
 	  	  	 ELSE
 	  	  	  	 SELECT DISTINCT Id = ec.pu_id, Description = pu.pu_desc  
 	  	  	  	  	 FROM Event_Configuration ec
 	  	  	  	  	 JOIN Prod_Units pu ON pu.pu_id = ec.pu_id and (@LineId Is Null Or pu.pl_id = @LineId)
 	  	  	  	  	 JOIN Prod_Lines pl ON pu.PL_Id = pl.PL_Id
 	  	  	  	  	 JOIN @SecurityGroup sg ON pl.Group_Id = sg.GroupId
 	  	  	  	  	 WHERE (ec.et_id = @EventType Or @EventType Is Null)
 	  	  	  	 UNION
 	  	  	  	 SELECT DISTINCT Id = ec.pu_id, Description = pu.pu_desc  
 	  	  	  	  	 FROM Event_Configuration ec
 	  	  	  	  	 JOIN Prod_Units pu ON pu.pu_id = ec.pu_id and (@LineId Is Null Or pu.pl_id = @LineId)
 	  	  	  	  	 JOIN @SecurityGroup sg ON pu.Group_Id = sg.GroupId
 	  	  	  	  	 WHERE (ec.et_id = @EventType Or @EventType Is Null)
 	  	  	   ORDER BY Description ASC
 	  	  	 RETURN
 	  	 END
 	 ELSE
 	  	 BEGIN
 	  	  	 GOTO DEFAULTROUTINE
 	  	 END
END
DEFAULTROUTINE:
If @EventType = 11
 	 Select Distinct Id = mu.pu_id, Description = mu.pu_desc  
 	   From variables v  
 	   Join Prod_units pu on pu.pu_id = v.pu_id and (@LineId Is Null Or pu.pl_id = @LineId)
    join Prod_Units mu on mu.pu_id = case when pu.master_unit Is Null Then pu.pu_id Else pu.master_unit End
 	   Join alarm_template_var_data a on a.var_id = v.var_id 
Else If @EventType = -2
 	 Select Distinct Id = pu.pu_id, Description = pu.pu_desc   
 	 From Prod_units pu
 	 Where pu.PU_Id In (Select PU_Id From NonProductive_Detail)
Else If @EventSubType Is Not Null
 	 Select Distinct Id = ec.pu_id, Description = pu.pu_desc  
 	   From Event_Configuration ec
 	   Join Event_Types et on et.et_id = ec.et_id
 	   Left Outer Join Event_Subtypes es on es.event_subtype_id = ec.event_subtype_id and es.event_subtype_id = @EventSubtype
    Join Prod_Units pu on pu.pu_id = ec.pu_id and (@LineId Is Null Or pu.pl_id = @LineId)
 	   Where (ec.et_id = @EventType Or @EventType Is Null)
Else
 	 Select Distinct Id = ec.pu_id, Description = pu.pu_desc  
 	   From Event_Configuration ec
    Join Prod_Units pu on pu.pu_id = ec.pu_id and (@LineId Is Null Or pu.pl_id = @LineId)
 	   Where (ec.et_id = @EventType Or @EventType Is Null)
  order By Description ASC
