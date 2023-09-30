-- spXLAWbWiz_DeleteReportDefinition modified from spRS_DeleteReportDefinition
-- ECR #25503(mt/5-6-2003): database has changed; code update needed. Added 'bail-out' code if transaction begins to fail
--
CREATE PROCEDURE dbo.spXLAWbWiz_DeleteReportDefinition
 	   @Report_Id    Int
 	 , @OutputStatus Int OUTPUT
AS
DECLARE @Schedule_Id                               Int
DECLARE @Delete_Report_Definition_Data_Error       SmallInt
DECLARE @Delete_Report_Definition_Parameters_Error SmallInt --1
DECLARE @Delete_Report_Que_Error                   SmallInt --2
DECLARE @Delete_Report_Schedule_Error              SmallInt --3
DECLARE @Delete_Report_Tree_Nodes_Error            SmallInt --4
DECLARE @Delete_Report_Runs_Error                  SmallInt
DECLARE @Delete_Report_Hits                        SmallInt
DECLARE @Delete_Report_Definitions_Error           SmallInt
DECLARE @Delete_Report_Def_Webpages_Error          SmallInt
SELECT @Delete_Report_Definition_Data_Error       = 100
SELECT @Delete_Report_Definition_Parameters_Error = 200
SELECT @Delete_Report_Que_Error                   = 300
SELECT @Delete_Report_Schedule_Error              = 400
SELECT @Delete_Report_Tree_Nodes_Error            = 500
SELECT @Delete_Report_Runs_Error                  = 600
SELECT @Delete_Report_Hits                        = 700
SELECT @Delete_Report_Definitions_Error           = 800
SELECT @Delete_Report_Def_Webpages_Error          = 900
SELECT @OutputStatus = 0
BEGIN TRANSACTION
  -- ECR #25503(mt5-6-2003)Delete From Report_Definition_Data 
  DELETE FROM Report_Definition_Data WHERE Report_Id = @Report_Id
  If @@Error <> 0 SELECT @OutputStatus = @Delete_Report_Definition_Data_Error
  If @OutputStatus <> 0 GOTO END_OF_FUNC
  -- Deleting from Report_Definition_Parameters
  DELETE FROM Report_Definition_Parameters WHERE Report_Id = @Report_Id
  If @@Error <> 0 SELECT @OutputStatus = @Delete_Report_Definition_Parameters_Error
  If @OutputStatus <> 0 GOTO END_OF_FUNC
  -- Deleting from Report_Que
  SELECT @Schedule_Id = Schedule_Id FROM Report_Schedule WHERE Report_Id = @Report_Id
  DELETE FROM Report_Que WHERE Schedule_Id = @Schedule_Id
  If @@Error <> 0 SELECT @OutputStatus = @Delete_Report_Que_Error
  If @OutputStatus <> 0 GOTO END_OF_FUNC
  -- Deleting from Report_Schedule
  DELETE FROM Report_Schedule WHERE Report_Id = @Report_Id
  If @@Error <> 0 SELECT @OutputStatus = @Delete_Report_Schedule_Error
  If @OutputStatus <> 0 GOTO END_OF_FUNC
  -- Deleting from Report_Tree_Nodes
  DELETE FROM Report_Tree_Nodes WHERE Report_Def_Id = @Report_Id
  If @@Error <> 0 SELECT @OutputStatus = @Delete_Report_Tree_Nodes_Error
  If @OutputStatus <> 0 GOTO END_OF_FUNC
  -- Deleting from Report_Runs
  SELECT * FROM Report_Runs WHERE Report_Id = @Report_Id
  DELETE FROM Report_Runs WHERE Report_Id = @Report_Id
  If @@Error <> 0 SELECT @OutputStatus = @Delete_Report_Runs_Error
  If @OutputStatus <> 0 GOTO END_OF_FUNC
  -- Deleting FROM Report_Hits
  DELETE FROM Report_Hits WHERE Report_Id = @Report_Id
  If @@Error <> 0 SELECT @OutputStatus = @Delete_Report_Hits 
  If @OutputStatus <> 0 GOTO END_OF_FUNC
  -- ECR #25503(mt/5-6-2003) Delete From Report_Def_Webpages
  DELETE FROM Report_Def_Webpages WHERE Report_Def_Id = @Report_Id
  If @@Error <> 0 SELECT @OutputStatus = @Delete_Report_Def_Webpages_Error
  If @OutputStatus <> 0 GOTO END_OF_FUNC
  -- Deleting from Report_Definitions
  DELETE FROM Report_Definitions WHERE Report_Id = @Report_Id
  If @@Error <> 0 SELECT @OutputStatus = @Delete_Report_Definitions_Error
  If @OutputStatus <> 0 GOTO END_OF_FUNC
END_OF_FUNC:
  If @OutputStatus = 0
    BEGIN COMMIT TRANSACTION 
    END
  Else
    BEGIN ROLLBACK TRANSACTION 
    END
--EndIf:@OutputStatus = 0
