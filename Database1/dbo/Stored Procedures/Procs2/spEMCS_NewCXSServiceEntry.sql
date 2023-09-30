Create Procedure dbo.spEMCS_NewCXSServiceEntry
@Active bit,
@Desc nvarchar(50),
@Display nvarchar(50),
@AStart tinyint = null,
@AStop tinyint = null,
@StartCT int = null,
@StopCT int = null,
@StartOrder int,
@RestartWait int,
@Monitor tinyint = null,
@RestartNonResp tinyint = null
AS
insert into cxs_Service (Is_Active, Service_Desc, Service_Display, Auto_Start, Auto_Stop, 
 	  	           Start_Check_Time, Stop_Check_Time, Start_Order, Restart_Wait_Time, Monitor_Service, Restart_Non_Responding)
 	            values (@Active, @Desc, @Display, @AStart, @AStop, 
 	  	           @StartCT, @StopCT, @StartOrder, @RestartWait, @Monitor, @RestartNonResp)
