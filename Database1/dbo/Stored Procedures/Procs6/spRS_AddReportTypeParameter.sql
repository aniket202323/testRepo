/* Stored Procedure Used in Report Server V2 */
/*
  Possible Return Values
  0 = No update was performed
  1 = A new parameter was added to the report type
  2 = An existing parameter was updated with new values
  ** changed DefaultValue = 7000 from 255 on  11-16-01
*/
CREATE PROCEDURE dbo.spRS_AddReportTypeParameter
@ReportTypeId int,
@ParamName varchar(50),
@DefaultValue varchar(7000), 
@Optional smallint, 
@ReturnVal int output
 AS
Declare @ParamId int
Declare @RowExists int
-- Check for valid Parameter Name
Select @ParamId = RP_Id
From Report_Parameters
Where RP_Name = @ParamName
Create Table #t(Report_Id int)
Insert Into #t(Report_Id)
  select Report_Id from report_definitions where report_type_Id = @ReportTypeId
-- If @ParamId is null then there is no such parameter by that name
If @ParamId Is Not Null
  Begin
    -- Check if Parameter already exists for this report type
    Select @RowExists = RTP_Id
    From Report_Type_Parameters
    where Report_type_Id = @ReportTypeId
    and RP_Id = @ParamId
    If @RowExists Is Null  -- Add a new row
      Begin
        Insert Into Report_Type_Parameters(Report_Type_Id, RP_Id, Default_Value, Optional)
        Values(@ReportTypeId, @ParamId, @DefaultValue, @Optional)
        Select @ReturnVal = Scope_Identity()
 	 Select @ReturnVal 'ReturnVal'
 	 -- Add To Report Def --
        Declare @MyId int
        Declare MyCursor INSENSITIVE CURSOR
          For (
               Select Report_Id From #t
              )
          For Read Only
          Open MyCursor  
        MyLoop1:
          Fetch Next From MyCursor Into @MyId 
          If (@@Fetch_Status = 0)
            Begin -- Begin Loop Here
 	       Exec spRS_AddReportDefParam @MyId, @ParamName, @DefaultValue
              Goto MyLoop1
            End -- End Loop Here
          Else -- Nothing Left To Loop Through
            goto myEnd
        myEnd:
          Close MyCursor
          Deallocate MyCursor
 	   Drop Table #t
        Return (1)
      End
    Else
      Begin  -- Update the existing row
        Update Report_Type_Parameters
        Set Default_Value = @DefaultValue,
            Optional = @Optional
        Where RTP_Id = @RowExists
        Select @ReturnVal = @RowExists
 	 Select @ReturnVal 'ReturnVal'
 	 Return (2)
      End
  End -- @ParamId is not null
Else
  Begin
    Select @ReturnVal = 0
    Select @ReturnVal 'ReturnVal'
    Return (0) 
  End
