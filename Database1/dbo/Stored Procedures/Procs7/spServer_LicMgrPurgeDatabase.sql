CREATE PROCEDURE dbo.spServer_LicMgrPurgeDatabase
AS
Declare @EndTime DateTime
Select @EndTime = dateadd(Month,-2,dbo.fnServer_CmnGetDate(GetUTCDate())) 
Delete Client_Connection_Module_Data
 	 From Client_Connection_Module_Data cmd
            Join Client_Connections cc  on cc.Client_Connection_Id = cmd.Client_Connection_Id
                        and  (cc.End_Time is not null and cc.End_Time < @EndTime)
             or (cc.End_Time is null and cc.Last_Heartbeat < @EndTime)
Delete Client_Connection_App_Data
            From Client_Connection_App_Data cad
            Join Client_Connections cc  on cc.Client_Connection_Id = cad.Client_Connection_Id
                        and  (cc.End_Time is not null and cc.End_Time < @EndTime)
             or (cc.End_Time is null and cc.Last_Heartbeat < @EndTime)
Delete from Client_Connections 
where (End_Time is not null and End_Time < @EndTime)
 or (End_Time is null and Last_Heartbeat < @EndTime)
