CREATE PROCEDURE dbo.spRS_DeleteReportDependency
@Table int,
@Id int
 AS
If @Table = 1 -- Report Type Dependency
  Begin
    Delete From Report_Type_Dependencies
    Where RTD_ID = @Id
  End
Else  -- Report Web Page dependency
  Begin
    Delete From Report_WebPage_Dependencies
    Where RWD_Id = @Id
  End
