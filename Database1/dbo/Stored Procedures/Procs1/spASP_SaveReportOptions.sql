CREATE PROCEDURE [dbo].[spASP_SaveReportOptions]
 	 @NodeId Int,
  @Name nvarchar(50),
  @Description nvarchar(1000),
  @Saved_By INT = NULL,
  @Saved_On DATETIME = NULL,
  @SourceType Int,
  @Version nvarchar(10),
  @XmlData TEXT
AS
/*
  Return Values:
    Positive - Inserted Id
    -5 - Duplicate Name
*/
DECLARE @DuplicateName INTEGER
IF @Saved_On IS NULL
  SET @Saved_On = dbo.fnServer_CmnGetDate(getutcdate())
SELECT @DuplicateName = COUNT(*)
FROM Report_Definitions
WHERE Report_Name = @Name
IF @DuplicateName > 0
 	 BEGIN
 	  	 RAISERROR('Duplicate Name Found', -1, -1)
 	  	 Return -5
 	 END
Declare @NewDefinitionId Int
--Create the report type
INSERT INTO Report_Definitions
(Class, Priority, Report_Type_Id, Report_Name, [File_Name], AutoRefresh,
 	 [Timestamp], OwnerId, Xml_Data, Xml_Version, [Description])
VALUES(3, 1, @SourceType, @Name, @Name, 0, @Saved_On, @Saved_By, @XmlData,
 	 @Version, @Description)
Set @NewDefinitionId = Scope_Identity()
--If we have the nodeId, we can put a shortcut
--into their user tree in the right place.
If @NodeId Is Not Null
 	 Begin
 	  	 Declare @ReportTreeTemplateId Int
 	  	 Declare @ParentNode Int
 	  	 Select @ReportTreeTemplateId = rd.Report_Tree_Template_Id,
 	  	  	 @ParentNode = Parent_Node_Id
 	  	 From Report_Tree_Nodes rd
 	  	 Where rd.Node_Id = @NodeId
 	  	 --Put the report into the users tree automatically
 	  	 Exec spRS_AddReportTreeNode @ReportTreeTemplateId, 20, @Name, @ParentNode, @NewDefinitionId, @SourceType, null, null
 	 End
Return @NewDefinitionId
