CREATE PROCEDURE dbo.spServer_CalcMgrGetCalcs
AS
select  	 c.Calculation_id,  	  	  	 Calculation_type_Id,  	 calculation_name,  	  	  	  	  	 equation,  	  	  	  	  	  	  	  	 script, 
 	  	  	  	 stored_procedure_name,  	 calc_input_id,  	  	  	  	 i.calc_input_attribute_id,  	 i.calc_input_entity_id,   	 input_name, 
 	  	  	  	 alias,  	  	  	  	  	  	  	  	  	 default_value,  	  	  	  	 optional,Lag_Time, 	  	  	  	  	 c.Trigger_Type_Id,  	  	  	  	 c.Max_Run_Time, 
 	  	  	  	 t.topic_id,  	  	  	  	  	  	 c.system_calculation, 	 c.Optimize_Calc_Runs,  	  	  	 i.non_triggering
from calculations c
left outer join calculation_inputs i on i.Calculation_id = c.calculation_id 
left outer join topics t on t.calculation_id = c.calculation_id
order by c.calculation_id, i.calc_input_order
