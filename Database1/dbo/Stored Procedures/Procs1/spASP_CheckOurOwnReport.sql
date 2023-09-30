CREATE PROCEDURE dbo.spASP_CheckOurOwnReport
 	 @InputURL varchar(1024)
AS
Create Table #ReportNodes (URL varchar(7000))
Insert Into #ReportNodes (URL) 
select rtn.URL from Report_Tree_Nodes rtn 
where rtn.Node_Id_Type in (8,9) and rtn.URL like @InputURL+'%'
Insert Into #ReportNodes (URL)
select rt.Template_Path from Report_Tree_Nodes rtn 
Join Report_Types rt on rt.Report_Type_Id = rtn.Report_Type_Id
where rtn.Node_Id_Type = 18 and rt.Template_Path like '%'+@InputURL+'%'
select itemCount = count(*) from #ReportNodes
drop table #ReportNodes
