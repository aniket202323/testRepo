CREATE   PROCEDURE dbo.spEM_GetReportTemplates
AS
Create Table #Trees(Report_Tree_Template_Id int,Report_Tree_Template_Name nvarchar(255))
Insert into #Trees(Report_Tree_Template_Id,Report_Tree_Template_Name)
 	 select Report_Tree_Template_Id,Report_Tree_Template_Name from Report_Tree_Templates
Insert into #Trees(Report_Tree_Template_Id,Report_Tree_Template_Name)
 	 select -999,'<New Report Tree>' 
select * from #Trees
Drop table #Trees
