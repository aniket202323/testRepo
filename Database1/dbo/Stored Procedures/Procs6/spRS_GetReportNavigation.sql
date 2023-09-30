CREATE PROCEDURE dbo.spRS_GetReportNavigation
@Report_Type_Id int = Null,
@Report_Def_Id int = Null,
@Force int = Null, 
@ClientCall int = Null
  AS
Declare @Class_Name varchar(25)
Declare @Page_Order int
-----------------------------
-- The Web Client Is Calling
-----------------------------
If @ClientCall Is Null -- Yes
  Begin
    Create Table #TempTable(
      RTW_Id int,
      Report_Type_Id int,
      RWP_Id int,
      Page_Order int,
      File_Name varchar(50),
      Title varchar(50),
 	   Tab_Title varchar(25), 
 	   Version varchar(20)
    )
 	 -------------------------------------------------
 	 -- Send Navigation Based On Report Definition Id
 	 -------------------------------------------------
    If @Report_Type_Id Is Null 
      Begin
        -- Get The Report Type It may be needed
        Select @Report_Type_Id = Report_Type_Id
        From Report_Definitions
        Where Report_Id = @Report_Def_Id
 	  	 ------------------------------------------------- 	 
        -- First try navigation path by Report_Definition
        -- Then by the Parent Report_Type
 	  	 -------------------------------------------------
        If (Select Count(*)
        From Report_Def_Webpages RDW
        Left Join Report_WebPages RW on RDW.RWP_Id = RW.RWP_Id
        Where report_Def_Id = @Report_Def_Id) > 0
          Begin
            Insert Into #TempTable
            Select RDW.RDW_Id, @Report_Type_Id, RDW.RWP_Id, RDW.Page_Order, RW.File_Name, RW.Title, RW.Tab_Title, RW.Version
            From Report_Def_Webpages RDW
            Left Join Report_WebPages RW on RDW.RWP_Id = RW.RWP_Id
            Where Report_Def_Id = @Report_Def_Id
            OR RW.RWP_Id = 1
            Order By Page_Order
          End
        Else
          Begin
            Insert Into #TempTable
            Select RTW.RTW_Id, RTW.Report_Type_Id, RTW.RWP_Id, RTW.Page_Order, RW.File_Name, RW.Title, RW.Tab_Title, RW.Version
            From Report_Type_Webpages RTW
            Left Join Report_WebPages RW on RTW.RWP_Id = RW.RWP_Id
            Where report_Type_Id = @Report_Type_Id
            OR RW.RWP_Id = 1
            Order By Page_Order
          End
      End
 	 --------------------------------------------
 	 -- Send Navigation Based On Report Type Id
 	 --------------------------------------------
    Else 
      Begin
        Insert Into #TempTable
        Select RTW.RTW_Id, RTW.Report_Type_Id, RTW.RWP_Id, RTW.Page_Order, RW.File_Name, RW.Title, RW.Tab_Title, RW.Version
        From Report_Type_Webpages RTW
        Left Join Report_WebPages RW on RTW.RWP_Id = RW.RWP_Id
        Where report_Type_Id = @Report_Type_Id
        Order By Page_Order
      End
 	 -----------------------------------
 	 -- Get The Report Type Class Name
 	 -----------------------------------
    Select @Class_Name = Class_Name
    From Report_Types
    Where Report_Type_Id = @Report_Type_Id
    Select @Page_Order = Max(Page_Order) + 1
    From #TempTable
    If @Page_Order Is null
      Select @Page_Order = 1
 	 -----------------------------------
    -- What type of appliction is it ?
 	 -----------------------------------
    If @Class_Name = 'Active Server Page' or @Class_Name = 'Active Server Application'
      Begin
        Insert Into #TempTable(RTW_Id, Report_Type_Id, RWP_Id, Page_Order, File_Name, Title, Tab_Title, Version)
        Select 1, @Report_Type_Id, 1, @Page_Order, File_Name, Title, Tab_Title, Version
        From Report_WebPages
        Where RWP_Id = 1 	 -- Finish.asp
--        Where RWP_Id = 2 	 -- ASPFinish.asp
      End
 	 --------------------
 	 -- All Other Types
 	 --------------------
    Else
      Begin
        Insert Into #TempTable(RTW_Id, Report_Type_Id, RWP_Id, Page_Order, File_Name, Title, Tab_Title, Version)
        Select 1, @Report_Type_Id, 1, @Page_Order, File_Name, Title, Tab_Title, Version
        From Report_WebPages
        Where RWP_Id = 1 	 -- Finish.asp
      End
 	 -----------------------------------
 	 -- Send Results Back To Web Client
 	 -----------------------------------
    Select * from #TempTable Order by Page_Order
    Drop Table #TempTable
  End
-------------------------------------
-- The Web Administrator Is Calling
-------------------------------------
Else
  Begin
 	 -------------------------------------------------
 	 -- Send Navigation Based On Report Definition Id
 	 -------------------------------------------------
    If @Report_Type_Id Is Null
      Begin
        Select @Report_Type_Id = Report_Type_Id
        From Report_Definitions
        Where Report_Id = @Report_Def_Id
        -- This will return an empty rs if no custom path has been setup
        If @Force = 1
          Begin
            Select RDW.*, RW.File_Name, RW.Title, RW.Version
            From Report_Def_Webpages RDW
            Left Join Report_WebPages RW on RDW.RWP_Id = RW.RWP_Id
            Where report_Def_Id = @Report_Def_Id
            Order By Page_Order
          End
        Else
          Begin
 	  	  	 ---------------------------------------------------
            -- First try navigation path by Report_Definition
            -- Then by the Parent Report_Type
 	  	  	 ---------------------------------------------------
            If (Select Count(*)
            From Report_Def_Webpages RDW
            Left Join Report_WebPages RW on RDW.RWP_Id = RW.RWP_Id
            Where report_Def_Id = @Report_Def_Id) > 0
              Begin
                Select RDW.*, RW.File_Name, RW.Title, RW.Version
                From Report_Def_Webpages RDW
                Left Join Report_WebPages RW on RDW.RWP_Id = RW.RWP_Id
                Where report_Def_Id = @Report_Def_Id
                Order By Page_Order
              End
            Else
              Begin
                Select RTW.*, RW.File_Name, RW.Title, RW.Version
                From Report_Type_Webpages RTW
                Left Join Report_WebPages RW on RTW.RWP_Id = RW.RWP_Id
                Where report_Type_Id = @Report_Type_Id
                Order By Page_Order
              End
         End
      End -- If @Report_Type_Id Is Null
 	 --------------------------------------------
 	 -- Send Navigation Based On Report Type Id
 	 --------------------------------------------
    Else
      Begin
            Select RTW.*, RW.File_Name, RW.Title, RW.Version
            From Report_Type_Webpages RTW
            Left Join Report_WebPages RW on RTW.RWP_Id = RW.RWP_Id
            Where report_Type_Id = @Report_Type_Id
            Order By Page_Order
      End
  End  -- If Administrator is calling
