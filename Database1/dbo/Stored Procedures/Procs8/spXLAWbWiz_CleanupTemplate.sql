/* This Stored Procedure is based on spRS_DeleteReportType */
CREATE PROCEDURE dbo.spXLAWbWiz_CleanupTemplate 
 	   @Report_Type_Id Int
 	 , @Output_Status  Int OUTPUT
AS
DECLARE @@Fetched_Report_Def_Id                Int
DECLARE @DeleteReportDef_Status                Int
DECLARE @Error_Closing_Cursor                  Int
DECLARE @Error_Delete_Report_Type_Parameters   Int
DECLARE @Error_Delete_Report_Type_WebPages     Int
DECLARE @Error_Delete_Report_Tree_Nodes        Int
DECLARE @Error_Delete_Report_Type_Dependencies Int
DECLARE @Error_Delete_Report_Types             Int
-- Define Error Constants
SELECT @Error_Closing_Cursor                  = 1          
--SELECT @Error_Delete_Report_Definition        = 2
SELECT @Error_Delete_Report_Type_Parameters   = 3
SELECT @Error_Delete_Report_Type_WebPages     = 4
SELECT @Error_Delete_Report_Tree_Nodes        = 5
SELECT @Error_Delete_Report_Type_Dependencies = 6
SELECT @Error_Delete_Report_Types             = 7
SELECT @Output_Status = 0
BEGIN TRANSACTION
  -- We'll have to delete any existing report definitions first (Constraints)
  DECLARE MyCursor INSENSITIVE CURSOR FOR(SELECT Report_Id FROM Report_Definitions WHERE Report_Type_Id = @Report_Type_Id )FOR READ ONLY
  OPEN MyCursor
TOP_OF_LOOP:
  FETCH NEXT FROM MyCursor INTO @@Fetched_Report_Def_Id 
  If @@Fetch_Status <> 0  -- failed fetcn, we must be done
    BEGIN GOTO CLOSE_CURSOR
    END
  Else -- successful fetch
    BEGIN
      --EXECUTE spRS_DeleteReportDefinition @@Fetched_Report_Def_Id
      SELECT @DeleteReportDef_Status = 0
      EXECUTE spXLAWbWiz_DeleteReportDefinition @@Fetched_Report_Def_Id, @DeleteReportDef_Status OUTPUT
      If @DeleteReportDef_Status = 0 
        BEGIN GOTO TOP_OF_LOOP
        END
      Else -- had problem delete Report Definition
        BEGIN
          SELECT @Output_Status = @DeleteReportDef_Status
          GOTO CLOSE_CURSOR
        END
      --EndIf:@DeleteReportDef_Status <> 0 
    END
  --EndIf:@@Fetch_Status <> 0
CLOSE_CURSOR:
  CLOSE MyCursor
  DEALLOCATE MyCursor
  If @@Error <> 0 SELECT @Output_Status = @Error_Closing_Cursor
  If @Output_Status <> 0 GOTO END_OF_FUNC
  --Delete Report_Type_Parameters
  DELETE FROM Report_Type_Parameters Where Report_Type_Id = @Report_Type_Id
  If @@Error <> 0 SELECT @Output_Status = @Error_Delete_Report_Type_Parameters
  If @Output_Status <> 0 GOTO END_OF_FUNC
  --Delete Report_Type_WebPages
  DELETE FROM Report_Type_WebPages Where Report_Type_Id = @Report_Type_Id
  If @@Error <> 0 SELECT @Output_Status = @Error_Delete_Report_Type_WebPages
  If @Output_Status <> 0 GOTO END_OF_FUNC
  --Delete Report_Tree_Nodes
  DELETE FROM Report_Tree_Nodes Where Report_Type_Id = @Report_Type_Id
  If @@Error <> 0 SELECT @Output_Status = @Error_Delete_Report_Tree_Nodes
  If @Output_Status <> 0 GOTO END_OF_FUNC
  --Delete Report_Type_Dependencies
  DELETE FROM Report_Type_Dependencies Where Report_Type_Id = @Report_Type_Id
  If @@Error <> 0 SELECT @Output_Status = @Error_Delete_Report_Type_Dependencies
  If @Output_Status <> 0 GOTO END_OF_FUNC
  --Delete Report_Types
  DELETE FROM Report_Types Where Report_Type_Id = @Report_Type_Id
  If @@Error <> 0 SELECT @Output_Status = @Error_Delete_Report_Types
  If @Output_Status <> 0 GOTO END_OF_FUNC
END_OF_FUNC:
  If @Output_Status = 0
    BEGIN COMMIT TRANSACTION 
    END
  Else
    BEGIN ROLLBACK TRANSACTION
    END
  --EndIf:
