--------------------------------------------------------------------------------
-- Database Name    : SOADB
-- Object Name      : dbo.splocal_WFCalled_RunningTasks_GetPeriodicWorkflows
-- DecryptSQL Ver   : Ver 3.2.0
-- Website          : http://www.devlib.net
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
-- Stored Procedure: splocal_WFCalled_RunningTasks_GetPeriodicWorkflows
--------------------------------------------------------------------------------------------------
-- Author				: Sai
-- Date created			: 2013-09-16
-- Version 				: Version [1.0] 
-- SP Type				: Select
-- Caller				: Custom App, Workflow
-- Description			: The clear running tasks
--						  
-- Editor tab spacing	: 4
--------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ========		====	  		====							=====
-- 1.0			2013-09-16		Saikrishna						initial release  
-- 1.1			2014-01-16		Sathiyanarayanan Ramanathan		Task Step Location information added
-- 1.2			2014-01-24		Sathiyanarayanan Ramanathan		Priority Column Added	
-- 1.3          2014-02-18      Purnima Chadalawada	            Task Location information added
-- 1.4          2014-06-12      Shrikant Kalwade	            FL Number information added
--------------------------------------------------------------------------------------------------
-- LOGIC --this code is periodic workflow data

CREATE PROCEDURE [dbo].[splocal_WFCalled_RunningTasks_GetPeriodicWorkflows]
--WITH ENCRYPTION
AS
BEGIN

-- Selects Workflow Definition ID and Workflow Name and Quick View Step's Config Panel Data and the workflow is not running
Select
 	PeriodicWorkflow.Task_Id as TaskDefinitionId,
	PeriodicWorkflow.Name as TaskName,
	PeriodicWorkflow.TaskName as TaskDisplayName,
	PeriodicWorkflow.StartDate as TaskStartDate,
	PeriodicWorkflow.Frequency as TaskFrequency,
	PeriodicWorkflow.LastExecution as TaskLastExecution,
	PeriodicWorkflow.IsPeriodicWorkflow as IsPeriodicWorkflow,
	B.Id as TaskStepId,
	B.Name as TaskStepName,
	B.Sequence as TaskStepSequenceId,
	B.LocationAssignment As EquipmentID,
	D.Priority As Priority,
	D.LocationAssignment As TaskLocation,
	--B.EsigRequired as IsESignEnabled,
	--B.Instructions as WorkInstructions,
	--B.InstructionsText as WorkInstructionsText,
	C.KeyValue as CustomPanelData,
	dbo.fnLocal_GetFLCode(B.LocationAssignment) AS [TaskStepFLCode],
	dbo.fnLocal_GetFLCode(D.LocationAssignment) AS [TaskFLCode]
	from 
	(
		SELECT A1.Name, A1.Id AS Task_Id, A1.DisplayName AS TaskName,
			Convert(varchar(max), Convert(xml, C.KeyValue)
				.query('/CustomPropertyMetadata/CustomProperties/CustomProperty[Name="Start Date"]/Value/text()')) AS StartDate,
			Convert(varchar(max), Convert(xml, C.KeyValue)
				.query('/CustomPropertyMetadata/CustomProperties/CustomProperty[Name="Frequency"]/Value/text()')) AS Frequency,
			Convert(varchar(max), Convert(xml, C.KeyValue)
				.query('/CustomPropertyMetadata/CustomProperties/CustomProperty[Name="Last Execution"]/Value/text()')) AS LastExecution,
			Convert(varchar(max), Convert(xml, C.KeyValue)
				.query('/CustomPropertyMetadata/CustomProperties/CustomProperty[Name="Periodic Workflow"]/Value/text()')) as IsPeriodicWorkflow

		FROM eSop_Task AS A1 WITH(NOLOCK)
		JOIN eSop_TaskStep AS B1 WITH(NOLOCK) ON A1.Enabled = 1 AND A1.Id = B1.Task_Id
		JOIN eSop_TaskStepConfigPanelData AS C WITH(NOLOCK) ON 
			B1.Sequence = 0 AND (B1.Id = C.TaskStep_Id) AND (C.KeyName = 'PropertiesConfigData')
			AND (Convert(xml, C.KeyValue)
				.query('/CustomPropertyMetadata/CustomProperties/CustomProperty[Name="Periodic Workflow"]')
				.exist('/CustomProperty/Value[contains(.,"True")]') = 1)
			
	) As PeriodicWorkflow
	JOIN eSop_TaskStep AS B WITH(NOLOCK) ON PeriodicWorkflow.Task_Id = B.Task_Id 
	JOIN eSop_TaskStepConfigPanelData AS C WITH(NOLOCK) ON c.TaskStep_Id = B.Id AND B.Sequence != 0 
	JOIN eSop_Task As D WITH(NOLOCK) ON B.Task_Id = D.Id
Order by TaskName, TaskStepSequenceId 
END

--------------------------------------------------------------------------------




