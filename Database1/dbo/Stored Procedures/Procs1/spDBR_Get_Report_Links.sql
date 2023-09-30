Create Procedure dbo.spDBR_Get_Report_Links
@reportid int
AS
 	 create table #report_links
 	 (
 	  	 report_link_id int IDENTITY (1, 1) NOT NULL,
 	  	 dashboard_report_link_id int,
 	  	 dashboard_report_to_id int,
 	  	 dashboard_report_name varchar(100),
 	  	 dashboard_template_id int,
 	  	 dashboard_template_name varchar(100)
 	 )
 	 insert into #report_links (dashboard_report_link_id, dashboard_report_to_id, dashboard_template_id, dashboard_template_name)
 	 select drl.dashboard_report_link_id,
 	  	  	 drl.dashboard_report_to_id, 
 	  	  	 t.dashboard_template_id,
 	  	  	 case when isnumeric(t.dashboard_template_name) = 1 then (dbo.fnDBTranslate(N'0', t.dashboard_template_name, t.dashboard_template_name) + ' v.' + Convert(varchar(7), t.version)) 
 	  	  	 else (t.dashboard_template_name + ' v.' + Convert(varchar(7), t.version))
 	  	  	 end as dashboard_template_name
 	  	  	 from dashboard_report_links drl, dashboard_templates t, dashboard_template_links dtl
 	  	  	  	 where drl.dashboard_report_from_id = @reportid
 	  	  	  	 and drl.dashboard_template_link_id = dtl.dashboard_template_link_id
 	  	  	  	 and t.dashboard_template_id = dtl.dashboard_template_link_to
 	  	  	  	 order by drl.dashboard_report_to_id
 	 declare @linkcount int
 	 declare @linkindex int
 	 declare @toid int
 	 declare @toname varchar(100)
 	 set @linkcount = (select count(*) from #report_links)
 	 set @linkindex = 1
 	 while (@linkindex <= @linkcount)
 	 begin
 	  	 set @toid = (select dashboard_report_to_id from #report_links where report_link_id = @linkindex)
 	  	 set @toname = (select dashboard_report_name from dashboard_reports where dashboard_report_id = @toid)
 	  	 update #report_links set dashboard_report_name = @toname where report_link_id = @linkindex
 	  	 set @linkindex = (@linkindex + 1)
 	 end
 	 
 	 select * from #report_links order by dashboard_template_id
 	 drop table #report_links
