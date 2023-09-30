-- spXLAWbWiz_GetOrderedWebPages() gets webpates for a given report type in webpage order. 
-- PrfWbWiz.dll uses this to retrieve for Dialogs Tab. mt/10-25-2002
--
CREATE PROCEDURE dbo.spXLAWbWiz_GetOrderedWebPages
 	   @Report_Type_Id   Int
AS
  SELECT RTW.*, RW.File_Name, RW.Title
    FROM Report_Type_Webpages RTW
    LEFT JOIN Report_WebPages RW ON RTW.RWP_Id = RW.RWP_Id
   WHERE RTW.Report_Type_Id = @Report_Type_Id
ORDER BY RTW.Page_Order
