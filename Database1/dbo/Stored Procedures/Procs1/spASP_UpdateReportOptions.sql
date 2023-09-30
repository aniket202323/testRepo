CREATE PROCEDURE [dbo].[spASP_UpdateReportOptions]
  @Analysis_Id INT,
  @Name nvarchar(50),
  @Description nvarchar(1000),
  @Saved_On DATETIME = NULL,
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
--Find out if there are other reports in the same
--group with the same name
SELECT @DuplicateName = COUNT(*)
FROM Report_Definitions rd
WHERE rd.Report_Name = @Name
And rd.Report_Id <> @Analysis_Id
And rd.Report_Type_Id In (Select Report_Type_Id From Report_Definitions Where Report_Id = @Analysis_Id)
IF @DuplicateName > 0
 	 BEGIN
 	  	 RAISERROR('Duplicate Name Found, Update Failed', -1, -1)
 	  	 Return -5
 	 END
Update Report_Definitions
Set Report_Name = @Name,
 	 [Timestamp] = @Saved_On,
 	 Xml_Data = @XmlData,
 	 Xml_Version = @Version,
 	 [Description] = @Description
Where Report_Id = @Analysis_Id
