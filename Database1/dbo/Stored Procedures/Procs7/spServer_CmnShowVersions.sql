Create Procedure dbo.spServer_CmnShowVersions
AS
execute spserver_cmnversion
Print ''
Select ServiceDesc = SubString(App_Name,1,30),Version = App_Version, InstalledOn = Modified_On from appversions where app_id >= 100
Print ''
Select ActiveServiceDesc = SubString(Service_Desc,1,30),Monitor_Service,Auto_Start,Auto_Stop From CXS_Service Where Is_Active = 1 order by monitor_service
Print ''
Select NonActiveServiceDesc = SubString(Service_Desc,1,30),Monitor_Service,Auto_Start,Auto_Stop From CXS_Service Where Is_Active <> 1 order by monitor_service
Print ''
