CREATE PROCEDURE dbo.spXLAWbWiz_GetReportNavigation
 	   @Report_Type_Id   Int = NULL
 	 , @Report_Def_Id    Int = NULL
 	 , @Force            Int = NULL
 	 , @ClientCall       Int = NULL
AS
Declare @Class_Name varchar(25)
Declare @Page_Order Int
-- Is this a web client call?
If @ClientCall Is NULL -- Yes Web client makes this call
  BEGIN
    Create Table #TempTable(
          RTW_Id         Int
        , Report_Type_Id Int
        , RWP_Id         Int
        , Page_Order     Int
        , File_Name      varchar(50)
        , Title          varchar(50)
        )           
    -- do they want the Type or Definition Path?
    If @Report_Type_Id Is NULL -- By Definition
      BEGIN
        -- Get The Report Type It may be needed
        SELECT @Report_Type_Id = Report_Type_Id FROM Report_Definitions WHERE Report_Id = @Report_Def_Id
        -- First try navigation path by Report_Definition
        -- Then by the Parent Report_Type
        If (SELECT Count(*) FROM Report_Def_Webpages RDW
            LEFT JOIN Report_WebPages RW on RDW.RWP_Id = RW.RWP_Id
            WHERE report_Def_Id = @Report_Def_Id
           ) > 0
          BEGIN
            INSERT INTO #TempTable
              SELECT RDW.RDW_Id, @Report_Type_Id, RDW.RWP_Id, RDW.Page_Order, RW.File_Name, RW.Title
                FROM Report_Def_Webpages RDW
                LEFT JOIN Report_WebPages RW on RDW.RWP_Id = RW.RWP_Id
               WHERE Report_Def_Id = @Report_Def_Id OR RW.RWP_Id = 1
            ORDER BY Page_Order
          END
        Else --Count = 0
          BEGIN
            INSERT INTO #TempTable
              SELECT RTW.RTW_Id, RTW.Report_Type_Id, RTW.RWP_Id, RTW.Page_Order, RW.File_Name, RW.Title
                FROM Report_Type_Webpages RTW
                LEFT JOIN Report_WebPages RW on RTW.RWP_Id = RW.RWP_Id
               WHERE report_Type_Id = @Report_Type_Id OR RW.RWP_Id = 1
            ORDER BY Page_Order
          END
        --EndIf:Count > 0 
      END
    Else --@Report_Type_Id NOT NULL (By Type)
      BEGIN
        INSERT INTO #TempTable
          SELECT RTW.RTW_Id, RTW.Report_Type_Id, RTW.RWP_Id, RTW.Page_Order, RW.File_Name, RW.Title
            FROM Report_Type_Webpages RTW
           LEFT JOIN Report_WebPages RW on RTW.RWP_Id = RW.RWP_Id
           WHERE report_Type_Id = @Report_Type_Id
        ORDER BY Page_Order
      END
    --EndIf:@Report_Type_Id Is NULL
    SELECT @Class_Name = Class_Name FROM Report_Types WHERE Report_Type_Id = @Report_Type_Id
    SELECT @Page_Order = Max(Page_Order) + 1 FROM #TempTable
    If @Page_Order Is null SELECT @Page_Order = 1
    -- What type of appliction is it ?
    If @Class_Name = 'Active Server Page'
      BEGIN
        INSERT INTO #TempTable(RTW_Id, Report_Type_Id, RWP_Id, Page_Order, File_Name, Title)
          SELECT 1, @Report_Type_Id, 1, @Page_Order, File_Name, Title
            FROM Report_WebPages
           WHERE RWP_Id = 2
        INSERT INTO #TempTable(RTW_Id, Report_Type_Id, RWP_Id, Page_Order, File_Name, Title)
          SELECT 1, @Report_Type_Id, 1, @Page_Order + 1, Template_Path, 'ASP Based Report'  
            FROM Report_Types 
           WHERE Report_Type_Id = @Report_Type_Id
      END
    Else
      BEGIN
        INSERT INTO #TempTable(RTW_Id, Report_Type_Id, RWP_Id, Page_Order, File_Name, Title)
          SELECT 1, @Report_Type_Id, 1, @Page_Order, File_Name, Title FROM Report_WebPages WHERE RWP_Id = 1
      END
    --EndIf:@Class_Name
    SELECT * from #TempTable
    Drop Table #TempTable
  END
Else --@ClientCall NOT NULL (Admin is calling)
  BEGIN
    If @Report_Type_Id Is NULL
      BEGIN
        SELECT @Report_Type_Id = Report_Type_Id FROM Report_Definitions WHERE Report_Id = @Report_Def_Id        
        -- This will return an empty rs if no custom path has been setup
        If @Force = 1
          BEGIN
              SELECT RDW.*, RW.File_Name, RW.Title
                FROM Report_Def_Webpages RDW
                LEFT JOIN Report_WebPages RW on RDW.RWP_Id = RW.RWP_Id
               WHERE report_Def_Id = @Report_Def_Id
            ORDER BY Page_Order
          END
        Else --@Force <> 1
          BEGIN
            -- First try navigation path by Report_Definition
            -- Then by the Parent Report_Type
            If ( SELECT Count(*) FROM Report_Def_Webpages RDW
                 LEFT JOIN Report_WebPages RW on RDW.RWP_Id = RW.RWP_Id
                 WHERE report_Def_Id = @Report_Def_Id
               ) > 0
              BEGIN
                  SELECT RDW.*, RW.File_Name, RW.Title
                    FROM Report_Def_Webpages RDW
                    LEFT JOIN Report_WebPages RW on RDW.RWP_Id = RW.RWP_Id
                   WHERE report_Def_Id = @Report_Def_Id
                ORDER BY Page_Order
              END
            Else --Count = 0
              BEGIN
                  SELECT RTW.*, RW.File_Name, RW.Title
                    FROM Report_Type_Webpages RTW
                    LEFT JOIN Report_WebPages RW on RTW.RWP_Id = RW.RWP_Id
                   WHERE report_Type_Id = @Report_Type_Id
                ORDER BY Page_Order
              END
            --EndIf:Count>0
          END
        --EndIf:@Force > 1
      END
    Else --@Report_Type_Id NOT NULL (Check for Navigation by Report Type Id)
      BEGIN
          SELECT RTW.*, RW.File_Name, RW.Title
            FROM Report_Type_Webpages RTW
            LEFT JOIN Report_WebPages RW on RTW.RWP_Id = RW.RWP_Id
           WHERE report_Type_Id = @Report_Type_Id
        ORDER BY Page_Order
      END
    --EndIf:@Report_Type_Id Is NULL
  END
--EndIf:@ClientCall
