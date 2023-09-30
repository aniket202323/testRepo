Create Procedure dbo.spDBR_Get_User_Permissions
@userid int,
@reportid int
AS
declare @@securitygroupid 	  	 integer,
 	  	 @GroupAccessLevel 	  	 integer,
 	  	 @TreeAccessLevel 	  	 integer,
 	  	 @AdminAccessLevel 	  	 integer,
 	  	 @ReportSecurityLevel 	 integer
--VR 2018-08-31: Get user level in Administrators group
SET @AdminAccessLevel = 	 (
 	  	  	  	  	  	 SELECT 	 Access_Level
 	  	  	  	  	  	 FROM 	 dbo.User_Security 	 us 	 WITH(NOLOCK)
 	  	  	  	  	  	 JOIN 	 dbo.Security_Groups 	 sg 	 WITH(NOLOCK)
 	  	  	  	  	  	  	  	  	  	  	  	  	 ON 	 us.Group_Id = sg.Group_Id
 	  	  	  	  	  	 WHERE 	 sg.Group_Desc = 'Administrator'
 	  	  	  	  	  	 AND 	  	 us.User_Id = @userid
 	  	  	  	  	  	 ) 	  	 
 	  	  	  	  	  	 
--If user is member of the Administrator group with at least Read/Write permission, allow Saving
IF ISNULL(@AdminAccessLevel, 1) > 1
BEGIN
 	 SET @ReportSecurityLevel = ISNULL(@AdminAccessLevel, 1)
END
ELSE
BEGIN
 	 select @@securitygroupid = dashboard_report_security_group_id from dashboard_reports where dashboard_report_id = @reportid
 	 --If the report is assigned to a group, the user MUST be a member of this group to access it
 	 if (@@securitygroupid is not null)
 	 BEGIN
 	  	 SET @GroupAccessLevel = (SELECT max(access_level) from user_security where group_id = @@securitygroupid and user_id = @userid)
 	  	 SET @ReportSecurityLevel = ISNULL(@GroupAccessLevel, @AdminAccessLevel) --If the user has Read rights in the Administrator group, show the report
 	 END
 	 ELSE --If no group is assigned, report tree security applies
 	 BEGIN
 	  	 --VR 2018-08-31: Get Report Security Level
 	  	 SET @TreeAccessLevel = (
 	  	  	  	  	  	  	  	 SELECT 	 TOP 1 	 CASE 	 User_Rights
 	  	  	  	  	  	  	  	  	  	  	  	 WHEN 	 0 THEN 1
 	  	  	  	  	  	  	  	  	  	  	  	 WHEN 	 2 THEN 2
 	  	  	  	  	  	  	  	  	  	  	  	 WHEN 	 10 THEN 4
 	  	  	  	  	  	  	  	  	  	  	  	 END
 	  	  	  	  	  	  	  	 FROM 	 dbo.Report_Tree_Users
 	  	  	  	  	  	  	  	 WHERE 	 User_Id = @userid
 	  	  	  	  	  	  	  	 ORDER BY Report_Tree_Template_Id ASC
 	  	  	  	  	  	  	  	 )
 	  	 --If the user is not member of any relevant group, default to report tree security.  
 	  	 --Note that software rule ensure that a user should only be a member in one tree at a time
 	  	 IF ISNULL(@TreeAccessLevel, 1) > 1
 	  	 BEGIN
 	  	  	 SET @ReportSecurityLevel = ISNULL(@TreeAccessLevel, 1)
 	  	 END
 	  	 ELSE --If no applicable security is found, default to Read Only, disallow saving
 	  	 BEGIN
 	  	  	 SET @ReportSecurityLevel = 1
 	  	 END
 	 END
END
--Return security level
SELECT @ReportSecurityLevel AS securitylevel
