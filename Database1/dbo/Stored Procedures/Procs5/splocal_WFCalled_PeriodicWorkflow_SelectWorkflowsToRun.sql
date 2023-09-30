--------------------------------------------------------------------------------------------------
-- Stored Procedure: splocal_WFCalled_PeriodicWorkflow_SelectWorkflowsToRun
--------------------------------------------------------------------------------------------------
-- Author                     : Sai
-- Date created               : 2013-09-20
-- Version                    : Version [1.0]
-- SP Type                    : Select
-- Caller                     : Custom App, Workflow
-- Description                : The update taskstep configuration
--                                   
-- Editor tab spacing   : 4
--------------------------------------------------------------------------------------------------
 
-------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ========       ====              ====                                      =====
-- 1.0                  2013-09-16        Saikrishna                                initial release 
-- 1.1                  2014-01-24        Saikrishna                                Fixed PErsmissions
-- 1.2					2014-02-20		  Sai								Appversion count equation 
--------------------------------------------------------------------------------------------------
-- LOGIC --this code is get workflow periodic workflow data
--------------------------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[splocal_WFCalled_PeriodicWorkflow_SelectWorkflowsToRun]
AS
BEGIN
 
-- Purge non running workflow data from Running Tasks Table
Exec [dbo].[splocal_WFCalled_RunningTasks_PurgeNonRunningTasks]
 
-- Selects Workflow Definition ID and Workflow Name and Quick View Step's Config Panel Data and the workflow is not running
SELECT
      A.Id,
      A.Name,
      A.DisplayName,
      Convert(varchar(max), Convert(xml, C.KeyValue)
            .query('/CustomPropertyMetadata/CustomProperties/CustomProperty[Name="Start Date"]/Value/text()')) AS StartDate,
      Convert(varchar(max), Convert(xml, C.KeyValue)
            .query('/CustomPropertyMetadata/CustomProperties/CustomProperty[Name="Frequency"]/Value/text()')) AS Frequency,
      Convert(varchar(max), Convert(xml, C.KeyValue)
            .query('/CustomPropertyMetadata/CustomProperties/CustomProperty[Name="Last Execution"]/Value/text()')) AS LastExecution
FROM
      eSop_Task AS A WITH(NOLOCK)
JOIN
      eSop_TaskStep AS B WITH(NOLOCK) ON
            A.[Enabled] = 1 AND
            A.Id = B.Task_Id AND
            A.Name NOT IN (SELECT D.TaskName from [SOADB].[dbo].[eSOP_MOTTaskRunning] AS D WITH(NOLOCK))
JOIN
      eSop_TaskStepConfigPanelData AS C WITH(NOLOCK) ON
            B.Sequence = 0
            AND (B.Id = C.TaskStep_Id) AND (C.KeyName = 'PropertiesConfigData')
            AND (Convert(xml, C.KeyValue)
                  .query('/CustomPropertyMetadata/CustomProperties/CustomProperty[Name="Periodic Workflow"]')
                  .exist('/CustomProperty/Value[contains(.,"True")]') = 1)   
END
