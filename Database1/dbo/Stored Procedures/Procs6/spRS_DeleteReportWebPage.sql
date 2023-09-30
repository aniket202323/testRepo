CREATE PROCEDURE dbo.spRS_DeleteReportWebPage 
@RWP_Id int
 AS
Declare @Page_Order int
Declare @Report_Type_Id int
--************************************************
-- Delete all references from Report_Type_WebPages
-- Re-Order all affected Report_Types
--************************************************
Declare MyCursor INSENSITIVE CURSOR
  For (
        Select Report_Type_Id, Page_Order
        From Report_Type_WebPages
        Where RWP_Id = @RWP_Id
      )
  For Read Only
  Open MyCursor  
Delete 
From Report_Type_WebPages
Where RWP_Id = @RWP_Id
MyLoop1:
  Fetch Next From MyCursor Into @Report_Type_Id, @Page_Order
  If (@@Fetch_Status = 0)
    Begin -- Begin Loop --
 	 -- Repair Each Affected Report_Type
      Update Report_Type_WebPages
      Set Page_Order = Page_Order - 1
      Where Report_Type_Id = @Report_Type_Id
        and Page_Order > @Page_Order
      GoTo MyLoop1
    End -- End Loop --
  Else -- No More Records
    Begin
      goto myEnd
    End
myEnd:
Close MyCursor
Deallocate MyCursor
--***********************************************
-- Delete all references from Report_Def_WebPages
-- Re-Order all affected Report_Types
--***********************************************
Declare MyCursor INSENSITIVE CURSOR
  For (
        Select Report_Def_Id, Page_Order
        From Report_Def_WebPages
        Where RWP_Id = @RWP_Id
      )
  For Read Only
  Open MyCursor  
Delete 
From Report_Def_WebPages
Where RWP_Id = @RWP_Id
Declare @Report_Def_Id int
MyLoop2:
  Fetch Next From MyCursor Into @Report_Def_Id, @Page_Order
  If (@@Fetch_Status = 0)
    Begin -- Begin Loop --
 	 -- Repair Each Affected Report_Type
      Update Report_Def_WebPages
      Set Page_Order = Page_Order - 1
      Where Report_Def_Id = @Report_Def_Id
        and Page_Order > @Page_Order
      GoTo MyLoop2
    End -- End Loop --
  Else -- No More Records
    Begin
      goto myEnd2
    End
myEnd2:
Close MyCursor
Deallocate MyCursor
--******************************************
--  Delete From Report_WebPage_Parameters
--******************************************
Delete 
From Report_WebPage_Parameters
Where RWP_Id = @RWP_Id
--******************************************
--  Delete From Report_WebPage_Dependencies
--******************************************
Delete
From Report_WebPage_Dependencies
Where RWP_Id = @RWP_Id
--******************************************
--  Delete From Report_WebPages
--******************************************
Delete
From Report_WebPages
Where RWP_Id = @RWP_Id
