CREATE PROCEDURE dbo.spRS_AdminGetReportServerLinkTypes
AS
Select Link_Type_Id, Link_Type_Name, Link_Type_Desc
From   Report_Server_Link_Types
