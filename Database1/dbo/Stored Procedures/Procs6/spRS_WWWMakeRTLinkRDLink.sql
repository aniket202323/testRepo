CREATE   PROCEDURE dbo.spRS_WWWMakeRTLinkRDLink
@Node_Id int,
@Report_Id int
AS
Declare @Node_Name varchar(50)
/*
This stored procedure will update the report_tree_nodes table
and modify a row that was formerly pointing to a report type
and make it point to a specific report definition
Things to change
-Node_Id_Type 17 = asp application (might just leave this the same or maybe try and figure out what the parent is)
-Report_Def_Id = @ReportId
-URL = NULL
*/
Select @Node_Name = Node_Name From Report_Tree_Nodes where Node_Id = @Node_Id
-- Update ReportName Parameter
Exec sprs_AddReportDefParam @Report_Id, 'ReportName', @Node_Name
-- Update Report_Definition table
Update Report_Definitions SET
 	 Report_Name = @Node_Name,
 	 Class = 3
Where Report_Id = @Report_ID
-- Update Report_Tree_Nodes table
UPDATE Report_Tree_Nodes Set
 	 URL = NULL,
 	 Report_Def_Id = @Report_Id,
 	 Node_Id_Type = 7,
 	 ForceRunMode = 1
Where Node_Id = @Node_ID
