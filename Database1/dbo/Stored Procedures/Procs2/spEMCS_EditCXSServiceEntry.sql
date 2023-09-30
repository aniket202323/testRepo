Create Procedure dbo.spEMCS_EditCXSServiceEntry 
@Active bit,
@Desc nvarchar(50),
@Display nvarchar(50),
@LPort Int_TCP_Port = null,
@LAddy nvarchar(15) = null,
@AStart tinyint = null,
@AStop tinyint = null,
@StartCT int = null,
@StopCT int = null,
@StartOrder int,
@RestartWait int,
@Monitor tinyint = null,
@RestartNonResp tinyint = null
as
update CXS_Service
set  	 is_Active = @Active,
 	 Service_Display = @Display,
 	 Listener_Port = @LPort,
 	 Listener_Address = @LAddy,
 	 Auto_Start = @AStart,
 	 Auto_Stop = @AStop,
 	 Start_Check_Time = @StartCT,
 	 Stop_Check_Time = @StopCT,
 	 Start_Order = @StartOrder,
 	 Restart_Wait_Time = @RestartWait,
 	 Monitor_Service = @Monitor,
 	 Restart_Non_Responding = @RestartNonResp
where Service_Desc = @Desc
