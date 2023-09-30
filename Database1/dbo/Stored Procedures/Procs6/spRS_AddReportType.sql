/* This Stored Procedure is Used with Report Server V2 */
/*
When called, 
If ReturnVal = 1, a new Report_Type was added
If ReturnVal = 2, a Report_Type was updated
If ReturnVal >=3, an Error occured while trying to 
   update a Report_Type
*/
CREATE PROCEDURE dbo.spRS_AddReportType
@Description varchar(255), 
@TemplatePath varchar(255) = Null,
@ClassName varchar(255) = Null,
@NativeExt varchar(20) = Null,
@ImageExt varchar(20) = Null,
@Version int = null,
@ReportTypeId int output
 AS
Declare @MyErr int
Select @MyErr = 0
If @ReportTypeId = 0 
  Select @ReportTypeId = Null
/*
    Select @ReportTypeId = Report_Type_Id
    From Report_Types
    Where Description = @Description
*/
If @ReportTypeId Is Not Null
  Begin  -- Update an existing Report Type
    If @TemplatePath Is Not Null
      Begin
        Begin Transaction
 	   Update Report_Types
 	   Set Description = @Description
          Where Report_Type_Id = @ReportTypeId
 	   If @@Error <> 0
 	      Select @MyErr = 3
          Update Report_Types
          Set Template_Path = @TemplatePath
          Where Report_Type_Id = @ReportTypeId
          If @@Error <> 0 
             Select @MyErr = 3
          Update Report_Types
          Set Class_Name = @ClassName
          Where Report_Type_Id = @ReportTypeId
          If @@Error <> 0 
             Select @MyErr = 4
          Update Report_Types
          Set Native_Ext = @NativeExt
          Where Report_Type_Id = @ReportTypeId
          If @@Error <> 0 
             Select @MyErr = 5
          Update Report_Types
          Set Image_Ext = @ImageExt
          Where Report_Type_Id = @ReportTypeId
          If @@Error <> 0 
             Select @MyErr = 6
 	   Update Report_Types
 	   Set Version = @Version
 	   Where Report_Type_Id = @ReportTypeId
 	   If @@Error <> 0 
 	      Select @MyErr = 7
          If @MyErr = 0 
            Begin
              Commit Transaction
              Return (2)
            End
          Else
            Begin
              Rollback Transaction
              Return @MyErr
            End
      End
  End
Else  -- Create a new Report Type
  Begin
    If @Version Is null
 	 Select @Version = 1
    Insert Into Report_Types(Description, Template_Path, Class_Name, Native_Ext, Image_Ext, Version)
    Values(@Description, @TemplatePath, @ClassName, @NativeExt, @ImageExt, @Version)
    Select @ReportTypeId = Scope_Identity() 
    -- Insert any default parameters
    -- The client is now responsible for adding the report_type_parameters
--    Insert Into Report_Type_Parameters(Report_Type_Id, Name, RP_Id, Default_Value, Optional)
--      Select @ReportTypeId , RP.RP_Name, RP.RP_Id, RP.Default_Value, 0  
--      from report_parameters RP
--      where Is_Default = 1
    Return (1)
  End
