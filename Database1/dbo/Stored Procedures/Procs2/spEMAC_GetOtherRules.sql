Create Procedure dbo.spEMAC_GetOtherRules
@Var_Id int,
@AT_Id int,
@User_Id int
AS
Declare @Insert_Id int
select Distinct alarm_templates.at_desc 
from alarm_templates 
join alarm_template_var_data on alarm_templates.at_id = alarm_template_var_data.at_id 
where alarm_template_var_data.var_id = @Var_Id
and alarm_template_var_data.at_id <> @AT_Id
