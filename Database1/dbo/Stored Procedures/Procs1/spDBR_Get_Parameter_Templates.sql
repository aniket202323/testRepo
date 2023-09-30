Create Procedure dbo.spDBR_Get_Parameter_Templates
@ParmTypeID int
AS
 	 select distinct(t.Dashboard_Template_ID), 
 	 case when isnumeric(t.Dashboard_Template_Name ) = 1 then (dbo.fnDBTranslate(N'0',t.Dashboard_Template_Name , t.Dashboard_Template_Name ) + ' v.' + Convert(varchar(7), t.version)) 
 	 else (t.Dashboard_Template_Name + ' v.' + Convert(varchar(7), t.version))
 	 end as Dashboard_Template_Name 
 	 
 	 from Dashboard_Templates t, Dashboard_Template_Parameters p
 	 where t.Dashboard_Template_ID = p.Dashboard_Template_Id and p.Dashboard_PArameter_Type_ID = @parmtypeid order by dashboard_template_name
 	 
