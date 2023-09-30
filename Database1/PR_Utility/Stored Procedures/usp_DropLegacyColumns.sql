-- ©2014 GE Intelligent Platforms, Inc. All rights reserved.

-- PR_Utility.usp_DropLegacyColumns
-- Stored procedure to drop columns identified by: https://devcloud.swcoe.ge.com/jira02/browse/PROFICYINF-13824
-- If the customer is using a database that has been upgraded from very early version of the product (pre 2.0)
-- their database has unused columns that the dacpacs don't know about.  Trying to run the utility against such
-- a database will cause an error.  The solution is to simply drop the columns if they exist. 

CREATE PROCEDURE [PR_Utility].[usp_DropLegacyColumns]
@Debug	BIT = 0,  -- when 1 print debug statements
@Test	BIT = 0   -- when 1 do not make any changes
AS

	SET NOCOUNT ON

	-- Variables for logging
	DECLARE @ProcedureName		VARCHAR(32)		= 'usp_DropLegacyColumns'
	DECLARE @LoggingPrefix		VARCHAR(100)	=  @ProcedureName + ': '

	IF (@Debug = 1)
	BEGIN
		PRINT @LoggingPrefix + 'Begin'
	END

	IF EXISTS(SELECT * FROM sys.columns Where name = 'AssemblyUrl' AND object_id = OBJECT_ID('dbo.SubProcessDefinition'))
	BEGIN
		ALTER TABLE dbo.SubProcessDefinition
		DROP COLUMN AssemblyUrl
	END
	
	IF EXISTS(SELECT * FROM sys.columns Where name = 'AssemblyUrl' AND object_id = OBJECT_ID('dbo.UserActivityDefinition'))
	BEGIN
		ALTER TABLE dbo.UserActivityDefinition
		DROP COLUMN AssemblyUrl
	END

	IF EXISTS(SELECT * FROM sys.columns Where name = 'WorkflowDefinitionVersion' AND object_id = OBJECT_ID('dbo.TaskInstance'))
	BEGIN
		ALTER TABLE dbo.TaskInstance
		DROP COLUMN WorkflowDefinitionVersion
	END

	IF EXISTS(SELECT * FROM sys.columns Where name = 'WorkflowScheduleVersion' AND object_id = OBJECT_ID('dbo.TaskInstance'))
	BEGIN
		ALTER TABLE dbo.TaskInstance
		DROP COLUMN WorkflowScheduleVersion
	END

	IF EXISTS(SELECT * FROM sys.columns Where name = 'LinkedResourceAddress' AND object_id = OBJECT_ID('dbo.TaskListVisibilityIT'))
	BEGIN
		ALTER TABLE dbo.TaskListVisibilityIT
		DROP COLUMN LinkedResourceAddress
	END

	IF EXISTS(SELECT * FROM sys.columns Where name = 'LinkedResourceAddress' AND object_id = OBJECT_ID('dbo.TaskListVisibilityPersonnel'))
	BEGIN
		ALTER TABLE dbo.TaskListVisibilityPersonnel
		DROP COLUMN LinkedResourceAddress
	END

	IF (@Debug = 1)
	BEGIN
		PRINT @LoggingPrefix + 'End'
	END

RETURN 0