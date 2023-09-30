--------------------------------------------------------------------------------------------------
-- Stored Procedure: splocal_WFCalled_PeriodicWorkflow_UpdateConfigPanelDataForTaskStep
--------------------------------------------------------------------------------------------------
-- Author                     : Sai
-- Date created               : 2013-09-16
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
-- 1.1                  2014-01-30        Saikrishna                                initial release
-- 1.2					2014-02-20		  Sai								Appversion count equation 
--------------------------------------------------------------------------------------------------
-- LOGIC --this code is periodic workflow data
CREATE PROCEDURE [dbo].[splocal_WFCalled_PeriodicWorkflow_UpdateConfigPanelDataForTaskStep]
(
      @StepId varchar(50),
      @ConfigPanelData varchar(max)
)
AS
BEGIN
DECLARE @currentDoc xml
declare @currentExecution varchar(100)
DECLARE @lastExecution varchar(100)
DECLARE @takeUpdateLastExecutionDoc xml
SET @takeUpdateLastExecutionDoc = @ConfigPanelData

SELECT @lastExecution = CONVERT(VARCHAR(MAX), CONVERT(XML, @takeUpdateLastExecutionDoc).query('/CustomPropertyMetadata/CustomProperties/CustomProperty[Name="Last Execution"]/Value/text()')) 

SELECT @currentDoc =  KeyValue FROM [dbo].eSop_TaskStepConfigPanelData WHERE TaskStep_Id= CAST(@StepId AS UniqueIdentifier)
SELECT @currentExecution = CONVERT(VARCHAR(MAX), CONVERT(XML, @currentDoc).query('/CustomPropertyMetadata/CustomProperties/CustomProperty[Name="Last Execution"]/Value/text()')) 
-- update text in the first manufacturing step
if(@currentExecution = '')
begin
set @currentDoc.modify('insert text{"xxx"}
        as first into (/CustomPropertyMetadata/CustomProperties/CustomProperty[Name="Last Execution"][1]/Value)[1]'
    )
end
SET @currentDoc.modify('
  replace value of (/CustomPropertyMetadata/CustomProperties/CustomProperty[Name="Last Execution"]/Value/text())[1]
  with  sql:variable("@lastExecution")')

            Update [dbo].eSop_TaskStepConfigPanelData
                  Set KeyValue = convert(varchar(max), @currentDoc)
           	Where TaskStep_Id= CAST(@StepId AS UniqueIdentifier) AND KeyName='PropertiesConfigData'
END
