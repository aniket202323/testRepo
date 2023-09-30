Create Procedure dbo.spDBR_Update_Port_Num
@port int
AS
 	 delete from dashboard_ad_hoc_service_info
 	 insert into dashboard_ad_hoc_service_info values (@port)
