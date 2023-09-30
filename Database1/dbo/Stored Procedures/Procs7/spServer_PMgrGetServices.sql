CREATE PROCEDURE dbo.spServer_PMgrGetServices
@NodeName nVarChar(50),
@IP nvarchar(50)
 AS
Select Node_Name, Service_Id, Proficy_Service_Name, Service_Display, Monitor_Service, 
       Auto_Start = COALESCE(Auto_Start, 0), Auto_Stop = COALESCE(Auto_Stop, 0), 
       Start_Check_Time, Stop_Check_Time, Restart_Wait_Time, Service_Desc, Restart_Non_Responding,Non_Responding_Kill_Script from cxs_service 
       where ( @NodeName = Node_Name or @IP = Node_Name or '127.0.0.1' = Node_Name)
         and Service_Id <> 15
         and is_active > 0
         and Monitor_Service > 0
       ORDER BY Start_Order
