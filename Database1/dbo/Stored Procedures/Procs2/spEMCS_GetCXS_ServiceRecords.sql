Create Procedure dbo.spEMCS_GetCXS_ServiceRecords
@Desc nvarchar(50) = null
 AS
if @desc is null
begin
 	 select  	 is_active, 
 	  	 Service_Desc,
 	  	 Service_Display,
 	  	 Node_Name,
 	  	 Listener_Port,
 	  	 Listener_Address,
 	  	 Auto_Start,
 	  	 Auto_Stop,
 	  	 Start_Check_Time,
 	  	 Stop_Check_Time,
 	  	 Start_Order,
 	  	 Restart_Wait_Time,
 	  	 Monitor_Service,
 	  	 Restart_Non_Responding
 	 from cxs_service
 	 order by Service_Desc DESC
end
else
begin
 	 select  	 is_active, 
 	  	 Service_Desc,
 	  	 Service_Display,
 	  	 Node_Name,
 	  	 Listener_Port,
 	  	 Listener_Address,
 	  	 Auto_Start,
 	  	 Auto_Stop,
 	  	 Start_Check_Time,
 	  	 Stop_Check_Time,
 	  	 Start_Order,
 	  	 Restart_Wait_Time,
 	  	 Monitor_Service,
 	  	 Restart_Non_Responding
 	 from cxs_service
 	 where Service_Desc = @desc
end
