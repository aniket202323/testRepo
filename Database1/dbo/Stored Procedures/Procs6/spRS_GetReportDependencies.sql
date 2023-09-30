CREATE PROCEDURE dbo.spRS_GetReportDependencies
@Table int,
@Id int
 AS
If @Table = 1
  Begin
    Select *
    From Report_Type_Dependencies
    Where Report_Type_Id = @Id
  End
Else
  Begin
    Select *
    From Report_WebPage_Dependencies
    Where RWP_Id = @Id  
  End
