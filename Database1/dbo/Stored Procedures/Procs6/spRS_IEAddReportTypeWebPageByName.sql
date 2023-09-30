Create Procedure [dbo].[spRS_IEAddReportTypeWebPageByName]
 	 @Report_Type_Id int,
 	 @File_Name varchar(255),
 	 @Page_Order int
AS
Declare @RWP_Id int 	 -- Report Webpage Id
-- Get Webpage Id By Unique File Name
Select @RWP_ID = RWP_Id From Report_Webpages Where Upper(@File_Name) = File_Name
If @RWP_Id Is Null
 	 Return (0)
-- Insert New Web Page
Insert Into Report_Type_WebPages(Report_Type_Id, RWP_Id, Page_Order) Values(@Report_Type_Id , @RWP_Id, @Page_Order)
