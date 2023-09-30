Create Procedure [dbo].[spRS_IEScriptReportTypeParameters]
 	 @Report_Type_Id int
AS
Declare @MyId int
Create Table #t(
 	 Id int NOT NULL IDENTITY (1, 1),
 	 Data varchar(8000)
)
Insert Into #t(Data) Select 'Set NoCount On'
---------------------------------------
-- Get Report Type Parameters
---------------------------------------
Insert Into #t(Data) Select '------------------------------------'
Insert Into #t(Data) Select '-- Verifying Required Parameters'
Insert Into #t(Data) Select '------------------------------------'
Declare ParameterCursor INSENSITIVE CURSOR
  For (
 	    Select RP_Id from report_type_Parameters where Report_Type_Id = @Report_Type_Id
      )
  For Read Only
  Open ParameterCursor  
BeginLoopParameters:
  Fetch Next From ParameterCursor Into @MyId 
  If (@@Fetch_Status = 0)
    Begin 
--      select @MyId
 	   Insert Into #t(Data)
 	   exec spRS_IEScriptReportParameter @MyId
      Goto BeginLoopParameters
    End 
  Else 
    goto EndLoopParameters
EndLoopParameters:
Close ParameterCursor
Deallocate ParameterCursor
Select Data From #t Order By Id
Drop Table #t
