Create Procedure dbo.spSupport_UpdatePAWebServerReferences_Split
@OldServer varchar(255),
@NewServer varchar(255)
AS
Declare @OldServerName varchar(255)
Declare @NewServerName varchar(255)
Select @OldServerName = @OldServer
Select @NewServerName = @NewServer
Update Cxs_Service
 	 Set Node_Name = Replace (Node_Name,@OldServerName,@NewServerName)
 	 where Node_Name like '%' + @OldServerName + '%' and Service_Id > 50
 	 
Update Cxs_Service
 	 Set Listener_Address = Replace (Listener_Address,@OldServerName,@NewServerName)
 	 where Listener_Address like '%' + @OldServerName + '%' and Service_Id > 50
Update Cxs_Service
 	 Set Service_Desc = Replace (Service_Desc,@OldServerName,@NewServerName),
 	 Service_Display = Replace (Service_Display,@OldServerName,@NewServerName),
 	 Node_Name = Replace (Node_Name,@OldServerName,@NewServerName) 
 	 where Service_Desc like '%' + @OldServerName + '%' + 'ReportEngine1%'
Update Cxs_Service
 	 Set Service_Desc = Replace (Service_Desc,@OldServerName,@NewServerName),
 	 Service_Display = Replace (Service_Display,@OldServerName,@NewServerName),
 	 Node_Name = Replace (Node_Name,@OldServerName,@NewServerName) 
 	 where Service_Desc like '%' + @OldServerName + '%' + 'ReportEngine2%'
 	 
Update Cxs_Service
 	 Set Service_Desc = Replace (Service_Desc,@OldServerName,@NewServerName),
 	 Service_Display = Replace (Service_Display,@OldServerName,@NewServerName),
 	 Node_Name = Replace (Node_Name,@OldServerName,@NewServerName) 
 	 where Service_Desc like '%' + @OldServerName + '%' + 'ReportEngine3%'
Update Cxs_Service
 	 Set Service_Desc = Replace (Service_Desc,@OldServerName,@NewServerName),
 	 Service_Display = Replace (Service_Display,@OldServerName,@NewServerName),
 	 Node_Name = Replace (Node_Name,@OldServerName,@NewServerName) 
 	 where Service_Desc like '%' + @OldServerName + '%' + 'ReportEngine4%'
 	 
Update Cxs_Service
 	 Set Service_Desc = Replace (Service_Desc,@OldServerName,@NewServerName),
 	 Service_Display = Replace (Service_Display,@OldServerName,@NewServerName),
 	 Node_Name = Replace (Node_Name,@OldServerName,@NewServerName) 
 	 where Service_Desc like '%' + @OldServerName + '%' + 'ProficyPDFGen%'
 	 
Update Cxs_Service 
 	 Set Service_Desc = Replace (Service_Desc,@OldServerName,@NewServerName),
 	 Service_Display = Replace (Service_Display,@OldServerName,@NewServerName),
 	 Node_Name = Replace (Node_Name,@OldServerName,@NewServerName) 
 	 where Service_Desc like '%' + @OldServerName + '%' + 'ASPEngine%'
 	 
Update Cxs_Service 
 	 Set Service_Desc = Replace (Service_Desc,@OldServerName,@NewServerName),
 	 Service_Display = Replace (Service_Display,@OldServerName,@NewServerName),
 	 Node_Name = Replace (Node_Name,@OldServerName,@NewServerName) 
 	 where Service_Desc like '%' + @OldServerName + '%' + 'PRASPPrinter%'
 	 
Update Cxs_Service  
 	 Set Service_Desc = Replace (Service_Desc,@OldServerName,@NewServerName),
 	 Service_Display = Replace (Service_Display,@OldServerName,@NewServerName),
 	 Node_Name = Replace (Node_Name,@OldServerName,@NewServerName) 
 	 where Service_Desc like '%' + @OldServerName + '%' + 'ProficyMgr%'
Update Cxs_Service 
 	 Set Service_Desc = Replace (Service_Desc,@OldServerName,@NewServerName),
 	 Service_Display = Replace (Service_Display,@OldServerName,@NewServerName),
 	 Node_Name = Replace (Node_Name,@OldServerName,@NewServerName) 
 	 where Service_Desc like '%' + @OldServerName + '%'+ 'ProfSch%'
Update Cxs_Service 
 	 set Auto_Start = 1 
 	 where Service_Desc like '%' + @NewServerName + '%' + 'ReportEngine2'
 	 
Update Dashboard_Gallery_Generator_Servers 
 	 set server = @NewServerName
 	 
Update Dashboard_Reports 
 	 set Dashboard_Report_Server = Replace(Dashboard_Report_Server,@OldServerName,@NewServerName) 
 	 where Dashboard_Report_Server like '%' + @OldServerName + '%'
Update Dashboard_Users 
 	 set Dashboard_Key = Replace(Dashboard_Key,@OldServerName,@NewServerName) 
 	 where Dashboard_Key like '%' + @OldServerName + '%'
 	 
Update Dashboard_Statistics 
 	 set Dashboard_Key = Replace(Dashboard_Key,@OldServerName,@NewServerName) 
 	 where Dashboard_Key like '%' + @OldServerName + '%'
 	 
Update Report_Definition_Parameters 
 	 Set Value = Replace(Value,@OldServerName,@NewServerName) 
 	 where value like '%' + @OldServerName + '%' and rtp_id 
 	 in (select rtp_id from Report_type_Parameters where rp_id in (35,42))
Update Report_Engines 
 	 set Engine_Name = Replace(Engine_Name,@OldServerName,@NewServerName) 
 	 where Engine_Name like '%' + @OldServerName + '%'
Update Report_Parameters 
 	 set Default_Value = Replace(Default_value,@OldServerName,@NewServerName) 
 	 where default_value like '%' + @OldServerName + '%' and rp_id in (35,42)
Update Report_Type_Parameters 
 	 Set Default_value = Replace(Default_value,@OldServerName,@NewServerName) 
 	 where default_value like  '%' + @OldServerName + '%' and rp_id in (35,42)
Update Report_types 
 	 Set Template_Path = Replace(Template_Path,@OldServerName,@NewServerName) 
 	 where Template_Path like '%' + @OldServerName + '%'
 	 
Update Report_Tree_Nodes 
 	 set URL = Replace(URL,@OldServerName,@NewServerName) 
 	 where URL like '%' + @OldServerName + '%'
Update Site_Parameters 
 	 Set Value = Replace(Value,@OldServerName,@NewServerName) 
 	 where Value like '%' + @OldServerName + '%'
 	 and Parm_id in (10,27,29,55,126,165,166,167)
Update Site_Parameters 
 	 Set HostName = Replace(HostName,@OldServerName,@NewServerName) 
 	 where HostName = @OldServerName 
 	 and Parm_id in (101,102)
Update User_parameters
 	 Set HostName = Replace(HostName,@OldServerName,@NewServerName)
 	 where HostName = @OldServerName 
 	 and user_id in (17,22,23,24,25,29,36) and parm_id in (50,51,52,53,101,102,126,146)
 	 
Print 'Finished:  The Plant Apps Web Server references have been updated.'
