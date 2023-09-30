Create Procedure dbo.spDBR_Get_Procedure_Parameters
@TemplateID int
AS
select distinct p.Dashboard_Template_Parameter_ID, 
 	  	  	  	 p.Dashboard_Template_Parameter_Order, 
 	  	  	  	 dt.Dashboard_Parameter_Data_Type  
 	  	  	  	 
 	  	  	  	 from Dashboard_Template_Parameters p, 
 	  	  	  	 Dashboard_Parameter_Types dpt, 
 	  	  	  	 Dashboard_Parameter_Data_Types dt
 	  	  	  	 where p.Dashboard_Template_ID = @TemplateID 
 	  	  	  	 and p.Dashboard_Parameter_Type_ID = dpt.Dashboard_Parameter_Type_ID 
 	  	  	  	 and dt.Dashboard_Parameter_Data_Type_ID = dpt.Dashboard_Parameter_Data_Type_ID
 	 order by p.Dashboard_Template_Parameter_Order 
