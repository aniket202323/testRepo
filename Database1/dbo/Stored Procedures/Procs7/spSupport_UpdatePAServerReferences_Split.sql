Create Procedure dbo.spSupport_UpdatePAServerReferences_Split
@OldServer varchar(255),
@NewServer varchar(255)
AS
Declare @OldServerName varchar(255)
Declare @NewServerName varchar(255)
Select @OldServerName = @OldServer
Select @NewServerName = @NewServer
Update Site_Parameters 
 	 Set Value = Replace(Value,@OldServerName,@NewServerName) 
 	 where Value like '%' + @OldServerName + '%'
 	 and Parm_id in (12,29,101,102,119)
Update Site_Parameters 
 	 Set HostName = Replace(HostName,@OldServerName,@NewServerName) 
 	 where HostName = @OldServerName 
 	 and Parm_id in (12,29,101,102,119)
Update User_parameters
 	 Set HostName = Replace(HostName,@OldServerName,@NewServerName)
 	 where HostName = @OldServerName 
 	 and user_id in (17) and parm_id in (101,102,126)
 	 
Update User_parameters
 	 Set Value = Replace(Value,@OldServerName,@NewServerName)
 	 where Value like '%' + @OldServerName + '%'
 	 and user_id in (17) and parm_id in (101,102,126)
Update Cxs_Service Set Node_Name = Replace(Node_Name,@OldServerName,@NewServerName)  
 	 where Node_Name like '%' + @OldServerName + '%' and Service_id < 51
Update Cxs_Service Set Listener_Address = Replace(Listener_Address,@OldServerName,@NewServerName)  
 	 where Listener_Address like '%' + @OldServerName + '%' and Service_id < 51
Update Cxs_Service 
 	 Set Service_Desc = Replace (Service_Desc,@OldServerName,@NewServerName),
 	 Service_Display = Replace (Service_Display,@OldServerName,@NewServerName),
 	 Node_Name = Replace (Node_Name,@OldServerName,@NewServerName) 
 	 where Service_Desc like '%' + @OldServerName + '%'+ 'ContentGenerator%'
Update License_Mgr_Info Set License_Mgr_Node = Replace(License_Mgr_Node,@OldServerName,@NewServerName)  
 	 where License_Mgr_Node like '%' + @OldServerName + '%'  	 
 	 
Update Cxs_Service 
 	 set Is_Active = 1 
 	 where Service_Desc like '%ContentGenerator%' 
 	 
Print 'Finished:  The Plant Apps Server references have been updated.'
---Execute For 6.x Installations Only
--If (Select App_Version from Appversions where App_Id = 34) > '00013.00000.00000.00000'
-- 	 Begin 	 
-- 	  	 Update Equipment Set S95Id = Replace(S95Id,@OldServerName,@NewServerName)  
-- 	  	  	 where S95Id like '%' + @OldServerName + '%' 
-- 	  	 Update EquipmentClass Set Description = Replace(Description,@OldServerName,@NewServerName)  
-- 	  	  	 where Description like '%' + @OldServerName + '%' 
 	  	  	 
-- 	  	 Update StructuredType Set Description = Replace(Description,@OldServerName,@NewServerName)  
-- 	  	  	 where Description like '%' + @OldServerName + '%' 
-- 	 End
 	 
