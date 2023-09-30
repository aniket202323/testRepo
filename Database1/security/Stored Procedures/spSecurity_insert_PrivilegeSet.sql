
CREATE PROCEDURE security.spSecurity_insert_PrivilegeSet
@paramType nvarchar(50)
AS

DECLARE @MaxId int;  --Get the Max Value id

 IF exists(select top 1 1 from [security].[Privilege_Sets] where displayname = 'Equipment')
    BEGIN
		update security.Privilege_Sets SET icon ='fa_equipment',displayname='OEE Dashboard' WHERE displayname = 'Equipment';
	END

IF not exists(select top 1 1 from [security].[Privilege_Sets] where displayname = 'OEE Dashboard') 
BEGIN
select @MaxId = max(id) from security.Privilege_Sets;
IF @MaxId is Null
   BEGIN
	select @MaxId = 0;
	END
	
INSERT INTO security.Privilege_Sets (id,displayname,scope,description,icon,category) Values(@MaxId+1,'OEE Dashboard','mes.equipment.user','View OEE summary statistics','fa_equipment','Common');
END

IF not exists(select top 1 1 from [security].[Privilege_Sets] where displayname = 'Reports') 
BEGIN
select @MaxId = max(id) from security.Privilege_Sets;
INSERT INTO security.Privilege_Sets (id,displayname,scope,description,icon,category) Values(@MaxId+1,'Reports' , 'mes.reports.user','OEE and process order status reports','fa_reports','Common') ;
END
ELSE	
	BEGIN
			update security.privilege_sets set icon ='fa_reports' where displayname='Reports'
	END

IF  exists(select top 1 1 from [security].[Privilege_Sets] where displayname = 'Downtime Displays' or displayname = 'Downtime' ) 
    begin
	      	update security.privilege_sets set icon ='fa_downtime',displayname='Downtime' where displayname='Downtime' or displayname = 'Downtime Displays' 
	end
	
IF not exists(select top 1 1 from [security].[Privilege_Sets] where displayname = 'Downtime') 
BEGIN
	select @MaxId = max(id) from security.Privilege_Sets;
	INSERT INTO security.Privilege_Sets (id,displayname,scope,description,icon,category) Values(@MaxId+1,'Downtime', 'mes.downtime.user','View and update Downtime details','fa_downtime','Common') ;
END

IF not exists(select top 1 1 from [security].[Privilege_Sets] where displayname = 'Alarms') 
BEGIN
select @MaxId = max(id) from security.Privilege_Sets;
INSERT INTO security.Privilege_Sets (id,displayname,scope,description,icon,category) Values(@MaxId+1,'Alarms','mes.alarms.user','View and update Alarm details','bell','Common') ;
END

 IF exists(select top 1 1 from [security].[Privilege_Sets] where displayname = 'Security Management')
    BEGIN
		update security.Privilege_Sets SET icon ='fa_security',displayname='Security' WHERE displayname = 'Security Management';
	END
	
IF not exists(select top 1 1 from [security].[Privilege_Sets] where displayname = 'Security')
BEGIN
select @MaxId = max(id) from security.Privilege_Sets;
INSERT INTO security.Privilege_Sets (id,displayname,scope,description,icon,category) Values(@MaxId+1,'Security','mes.security_management.user','Manage security by users and groups','fa_security','Common') ;
END


IF not exists(select top 1 1 from [security].[Privilege_Sets] where displayname = 'Activities')
    BEGIN
	select @MaxId = max(id) from security.Privilege_Sets;
	INSERT INTO security.Privilege_Sets (id,displayname,scope,description,icon,category) Values(@MaxId+1,'Activities', 'mes.activities.user','View and perform Activities ','fa_activities','Common') ;
	END
ELSE	
	BEGIN
	        update security.privilege_sets set icon='fa_activities' ,category ='Common' where displayname='Activities'; 
	END
IF not exists(select top 1 1 from [security].[Privilege_Sets] where displayname = 'My Machines')
	BEGIN
	select @MaxId = max(id) from security.Privilege_Sets;
	INSERT INTO security.Privilege_Sets (id,displayname,scope,description,icon,category) Values(@MaxId+1,'My Machines','mes.my_machines.user','Select the machines that will provide context to some menu items','fa_my_machines','Common') ;
    END
ELSE	
	BEGIN
			update security.privilege_sets set category ='Common',icon='fa_my_machines' where displayname='My Machines'
	END
	
IF  exists(select top 1 1 from [security].[Privilege_Sets] where displayname = 'Process Order' or displayname = 'Production Scheduler' or displayname = 'Process Orders')
   BEGIN
	    update security.privilege_sets set icon='fa_production_scheduler',displayname='Process Orders',scope='mes.process_orders.user',description='Manage Process Orders' where displayname='Process Order' or displayname = 'Production Scheduler' or displayname = 'Process Orders'
   END
 
IF not exists(select top 1 1 from [security].[Privilege_Sets] where displayname = 'Process Orders')
	BEGIN
		select @MaxId = max(id) from security.Privilege_Sets;
		INSERT INTO security.Privilege_Sets (id,displayname,scope,description,icon,category) Values(@MaxId+1,'Process Orders','mes.process_orders.user','Manage Process Orders','fa_production_scheduler','Common') ;
	END

IF  exists(select top 1 1 from [security].[Privilege_Sets] where displayname = 'WasteManagement' or displayname = 'Waste Management')	
 	  BEGIN
  		    update security.privilege_sets set icon='fa_waste_management',scope = 'mes.waste.user', displayname='Waste' where displayname='WasteManagement' or displayname = 'Waste Management'
      END
											    
 IF not exists(select top 1 1 from [security].[Privilege_Sets] where displayname = 'Waste')
	BEGIN
	select @MaxId = max(id) from security.Privilege_Sets;
		INSERT INTO security.Privilege_Sets (id,displayname,scope,description,icon,category) Values(@MaxId+1,'Waste','mes.waste.user','Calculate material loss associated with product event or time based event','fa_waste_management','Common') ;
	END	

IF not exists(select top 1 1 from [security].[Privilege_Sets] where displayname = 'Global')
BEGIN
select @MaxId = max(id) from security.Privilege_Sets;
	INSERT INTO security.Privilege_Sets (id,displayname) Values(@MaxId+1,'Global');
END


IF not exists(select top 1 1 from [security].[Privilege_Sets] where displayname = 'Genealogy')
BEGIN
select @MaxId = max(id) from security.Privilege_Sets;
INSERT INTO security.Privilege_Sets (id,displayname,scope,description,icon,category) Values(@MaxId+1,'Genealogy','mes.genealogy.user','Search for serials and lots for a review of items genealogy','fa_genealogy','Common') ;
END

IF not exists(select top 1 1 from [security].[Privilege_Sets] where displayname = 'BOM Editor')
    BEGIN
		select @MaxId = max(id) from security.Privilege_Sets;
		INSERT INTO security.Privilege_Sets (id,displayname,scope,description,icon,category) Values(@MaxId+1,'BOM Editor','mes.bom_editor.user','Create and manage BOM','fa_bom','Common');
    END
    ELSE	
	BEGIN
			update security.privilege_sets set category ='Common',description='Create and manage BOM' where displayname='BOM Editor'
	END

IF(@paramType='DISCRETE' OR @paramType='ALL' )
BEGIN
    select @MaxId = max(id) from security.Privilege_Sets;
   IF exists(select top 1 1 from [security].[Privilege_Sets] where displayname = 'Operations' or displayname = 'Unit Operations')
    BEGIN
		update security.Privilege_Sets SET icon ='fa_operations', displayname = 'Unit Operations' WHERE displayname = 'Operations';
	END
	
    IF not exists(select top 1 1 from [security].[Privilege_Sets] where displayname = 'Unit Operations')
    BEGIN
	INSERT INTO security.Privilege_Sets (id,displayname,scope,description,icon,category) Values(@MaxId+1,'Unit Operations','mes.operations.user','Assembly operator display that lists operations to be completed by serial/lot number for a given machine','fa_operations','Discrete') ;
	END
			
	IF not exists(select top 1 1 from [security].[Privilege_Sets] where displayname = 'Work Queue')
    BEGIN
	select @MaxId = max(id) from security.Privilege_Sets;
	INSERT INTO security.Privilege_Sets (id,displayname,scope,description,icon,category) Values(@MaxId+1,'Work Queue','mes.work_queue.user','Component operator display that allows an operator to build a queue of work, listed by operation','fa_workqueue','Discrete') ;
	END
	ELSE	
	BEGIN
			update security.privilege_sets set icon ='fa_workqueue' where displayname='Work Queue'
	END
	
	IF exists(select top 1 1 from [security].[Privilege_Sets] where displayname = 'Non Conformance Management' or displayname = 'Non Conformance ')
    BEGIN
		update security.Privilege_Sets SET icon ='fa_ncm', displayname = 'Non Conformance' WHERE displayname = 'Non Conformance Management' or displayname = 'Non Conformance ';
	END
	
	IF not exists(select top 1 1 from [security].[Privilege_Sets] where displayname = 'Non Conformance')
    BEGIN
	select @MaxId = max(id) from security.Privilege_Sets;
	INSERT INTO security.Privilege_Sets (id,displayname,scope,description,icon,category) Values(@MaxId+1,'Non Conformance','mes.ncm_management.user','View and disposition non-conforming parts','fa_ncm','Discrete') ;
	END
	
	IF exists(select top 1 1 from [security].[Privilege_Sets] where displayname = 'Order Management')
    BEGIN
		update security.Privilege_Sets SET icon ='fa_order_management', displayname = 'Work Order Manager' WHERE displayname = 'Order Management';
	END
	
	IF not exists(select top 1 1 from [security].[Privilege_Sets] where displayname = 'Work Order Manager')
    BEGIN
	select @MaxId = max(id) from security.Privilege_Sets;
	INSERT INTO security.Privilege_Sets (id,displayname,scope,description,icon,category) Values(@MaxId+1,'Work Order Manager','mes.order_management.user','View and update order information across 1 or more lines','fa_order_management','Discrete') ;
	END
	
	IF exists(select top 1 1 from [security].[Privilege_Sets] where displayname = 'Route Management')
    BEGIN
		update security.Privilege_Sets SET icon ='fa_route', displayname = 'Route Editor' WHERE displayname = 'Route Management';
	END
	
    IF not exists(select top 1 1 from [security].[Privilege_Sets] where displayname = 'Route Editor')
    BEGIN
	select @MaxId = max(id) from security.Privilege_Sets;
	INSERT INTO security.Privilege_Sets (id,displayname,scope,description,icon,category) Values(@MaxId+1,'Route Editor','mes.route_management.user','Create and manage routes','fa_route','Discrete') ;
	END
	
	IF not exists(select top 1 1 from [security].[Privilege_Sets] where displayname = 'Property Definition')
    BEGIN
	select @MaxId = max(id) from security.Privilege_Sets;
	INSERT INTO security.Privilege_Sets (id,displayname,scope,description,icon,category) Values(@MaxId+1,'Property Definition','mes.property_definition.user','Manage common properties that will be used through out the system','fa_property_definition','Discrete') ;
    END
    ELSE	
	BEGIN
			update security.privilege_sets set icon ='fa_property_definition' where displayname='Property Definition'
	END
    
	IF exists(select top 1 1 from [security].[Privilege_Sets] where displayname = 'Configuration Management')
    BEGIN
		update security.Privilege_Sets SET icon ='fa_configuration_management', displayname = 'Configuration' WHERE displayname = 'Configuration Management';
	END
	
	IF not exists(select top 1 1 from [security].[Privilege_Sets] where displayname = 'Configuration')
    BEGIN
	select @MaxId = max(id) from security.Privilege_Sets;
	INSERT INTO security.Privilege_Sets (id,displayname,scope,description,icon,category) Values(@MaxId+1, 'Configuration','mes.configuration_management.user','Create and manage configurations for operator application tabs including pre requisite and post requisite extensions','fa_configuration_management','Discrete') ;
    END
    
    IF not exists(select top 1 1 from [security].[Privilege_Sets] where displayname = 'Time Booking')
    BEGIN
	select @MaxId = max(id) from security.Privilege_Sets;
	INSERT INTO security.Privilege_Sets (id,displayname,scope,description,icon,category) Values(@MaxId+1,'Time Booking','mes.time_booking.user','Update clock on records for labor vouchering','fa_time_booking','Discrete') ;
    END
    ELSE	
	BEGIN
			update security.privilege_sets set icon ='fa_time_booking' where displayname='Time Booking'
	END
	
	IF not exists(select top 1 1 from [security].[Privilege_Sets] where displayname = 'Approval Cockpit')
    BEGIN
	      select @MaxId = max(id) from security.Privilege_Sets;
	      INSERT INTO security.Privilege_Sets (id,displayname,scope,description,icon,category) Values(@MaxId+1,'Approval Cockpit','mes.approval_cockpit.user','Set-up, execute and track approval workflows for various actions','fa_approval_cockpit','Discrete') ;
	END
	IF exists(select top 1 1 from [security].[Privilege_Sets] where displayname = 'Receiving And Inspection')
		BEGIN
			  update security.privilege_sets set icon ='fa_receiving_inspection',displayname='Receiving Inspection' where displayname='Receiving And Inspection'
		END 
	IF not exists(select top 1 1 from [security].[Privilege_Sets] where displayname = 'Receiving Inspection')
    BEGIN
	      select @MaxId = max(id) from security.Privilege_Sets;
	      INSERT INTO security.Privilege_Sets (id,displayname,scope,description,icon,category) Values(@MaxId+1,'Receiving Inspection','mes.receiving_inspection.user','Receiving And Inspection','fa_receiving_inspection','Discrete') ;
	END
END


IF(@paramType='PROCESS' OR @paramType='ALL')
BEGIN	
	IF not exists(select top 1 1 from [security].[Privilege_Sets] where displayname = 'Analysis')
    BEGIN
	select @MaxId = max(id) from security.Privilege_Sets;
	INSERT INTO security.Privilege_Sets (id,displayname,scope,description,icon,category) Values(@MaxId+1,'Analysis','mes.analysis.user','Display trends for variables and historian tags as well as batch information','fa_analysis','Process') ;
	END
	 ELSE	
	BEGIN
			update security.privilege_sets set icon ='fa_analysis' where displayname='Analysis'
	END
	
END
