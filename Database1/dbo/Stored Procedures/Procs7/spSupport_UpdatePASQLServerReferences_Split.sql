Create Procedure dbo.spSupport_UpdatePASQLServerReferences_Split
@OldServer varchar(255),
@NewServer varchar(255)
AS
Declare @OldServerName varchar(255)
Declare @NewServerName varchar(255)
Select @OldServerName = @OldServer
Select @NewServerName = @NewServer
---Validate SQL Collation matches between GBDB & TEMPDB.  If a mismatch exists return and perform no updates.
Declare @TempDBCollation varchar(255)
Declare @PaDBCollation varchar(255)
SELECT @TempDBCollation = CONVERT (varchar, DATABASEPROPERTYEX('tempdb','collation'))
SELECT @PaDBCollation = collation_name FROM sys.columns WHERE name = N'DBTT_Desc'
If @TempDBCollation <> @PaDBCollation
 	 BEGIN
 	  	 SELECT 'No changes have been applied to the server.'
 	  	 SELECT 'Error:  @TempDBCollation <> @PaDBCollation'
 	  	 SELECT 'Collation of TempDB = ' + @TempDBCollation
 	  	 SELECT 'Collation of PA/SOA DB = ' + @PaDBCollation
 	  	 SELECT 'If viewing results in Grid Mode: Check the messages tab for resolution.'
 	  	 Print ' '
 	  	 Print 'Error:  @TempDBCollation <> @PaDBCollation.  No changes have been applied to the server.'
 	  	 Print ' '
 	  	 Print 'Issue:  The collation of the system databases does not match the Plant Apps Database.'
 	  	 Print 'Resolution: Please reference the solutions below on resolving Collation Conflicts:'
 	  	 Print ' '
 	  	 Print ' Option #1 - Rebuild the system Databases:'
 	  	 Print ' 	  	  	 SQL 2012:  http://technet.microsoft.com/en-us/library/dd207003.aspx'
 	  	 Print ' 	  	  	 SQL 2008:  http://technet.microsoft.com/en-us/library/dd207003(v=sql.105).aspx'
 	  	 Print ' 	 '
 	  	 Print ' Option #2 - Validate the Collation of the PlantApps and reinstall SQL using the correct collation.'
 	  	 Print ' 	  	  	 Rerun spSupport_UpdatePASQLServerReferences_Split after resolving the collation conflicts.'
 	  	 RETURN
 	 END
Print 'SQL Collation Validated & Matches:  TempDB = ' + @TempDBCollation + 'PlantApps DB = ' + @PaDBCollation
---Validate @@Servername matches value passed for @NewServerName.  If a mismatch exists return and perform no updates.
DECLARE @CheckSQLServername varchar(255),
        @IsAlwaysOn int
DECLARE @dns_names TABLE
(dns_name varchar(255))
SELECT @IsAlwaysOn = CAST(SERVERPROPERTY('IsHadrEnabled') AS Int)
IF (@IsAlwaysOn = 1)
 	 BEGIN
 	     INSERT INTO @dns_names
 	  	 SELECT dns_name FROM sys.availability_group_listeners GROUP BY dns_name 
 	  	 IF EXISTS (Select * FROM @dns_names where dns_name =  @NewServerName)
 	  	  	 SELECT @CheckSQLServername = @NewServerName
 	 END
ELSE
 	 BEGIN
 	  	 IF SERVERPROPERTY('InstanceName') IS NOT NULL
 	  	  	 SELECT @CheckSQLServername = CONCAT(CAST(SERVERPROPERTY('MachineName') AS varchar(255)),'\', CAST(SERVERPROPERTY('InstanceName') AS varchar(255)))
 	  	 ELSE
 	  	  	 SELECT @CheckSQLServername = CAST(SERVERPROPERTY('MachineName') AS varchar(255))
 	 END
If @CheckSQLServername <> @NewServerName
  	 BEGIN
  	    	 SELECT 'No changes have been applied to the server.'
  	    	 SELECT 'Error:  @@Servername <> @NewServername.'
  	     SELECT 'Local @@SERVERNAME = ' + @CheckSQLServername
  	    	 SELECT 'Physical SQL Server Name Passed (@NewServerName) = ' + @NewServerName
  	    	 SELECT 'If viewing results in Grid Mode: Check the messages tab for resolution.'
  	    	 Print ' '
  	    	 Print 'Error:  @@Servername <> @NewServername.  No changes have been applied to the server.'
  	    	 Print 'Issue:  The SQL @@SERVERNAME does not match the existing SQL Server Name.'
  	    	 Print 'Resolution: The following code can be used to update the @@Servername reference:'
  	    	 Print ' '
  	    	 Print '### Notes:  Replace Value_OldSQLServerName & Value_NewSQLServerName w/corresponding names before executing script. ###'
  	    	 Print ' '
  	    	 Print '  	    	    	  EXEC sp_dropserver ' + '''' + 'Value_OldSQLServerName' + ''''
  	    	 Print '  	    	    	  EXEC sp_addserver @server = ' + '''' + 'Value_NewSQLServerName' + '''' + ',@local = ' + '''' + 'local' + ''''
  	    	 Print ' '
  	    	 Print '  	    	    	  Stop and Restart SQL for the Changes to take effect'
  	    	 Print '  	    	    	  Rerun spSupport_UpdatePASQLServerReferences_Split after updating the @@Servername.'
  	    	 RETURN
    END
Print 'Validated - @@Servername matches PlantApps @NewServername:  @@Servername = ' + @CheckSQLServername + 'PA SQL @NewServername = ' + @NewServerName  	  
--Update Plant Apps SQL References
Update Historians
 	 Set Hist_Servername = Replace(Hist_Servername,@OldServerName,@NewServerName)
 	 where Hist_Id = -1
 	 
Update Report_Parameters Set Default_Value = Replace(Default_Value,@OldServerName,@NewServerName)  
 	 where Default_value like '%' + @OldServerName + '%' and rp_id = 36
Update Report_Definition_Parameters 
 	 Set Value = Replace(Value,@OldServerName,@NewServerName) 
 	 where value like '%' + @OldServerName + '%' and rtp_id 
 	 in (select rtp_id from Report_type_Parameters where rp_id = 36)
Update Report_Type_Parameters 
 	 Set Default_value = Replace(Default_value,@OldServerName,@NewServerName) 
 	 where default_value like  '%' + @OldServerName + '%' and rp_id = 36
Print 'Finished:  The Plant Apps SQL Server references have been updated.'
