CREATE PROCEDURE dbo.spRS_AddReportWebPageParameter
@RWP_Id int,
@RP_Id int
 AS
Declare @Exists int
Select @Exists = Rpt_WebPage_Param_Id
From Report_WebPage_Parameters
Where RWP_Id = @RWP_Id 
And   RP_Id = @RP_Id
If @Exists Is Null
  Begin
    Insert Into Report_WebPage_Parameters(RP_Id, RWP_ID)
    Values (@RP_Id, @RWP_Id)
    If @@Error = 0
      Return (0)
    Else
      Return (1)
  End
Else
  Begin
    -- This combination already exists
    Return (2)
  End
