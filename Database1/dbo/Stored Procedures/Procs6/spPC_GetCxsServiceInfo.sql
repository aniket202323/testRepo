Create Procedure dbo.spPC_GetCxsServiceInfo
 	 @Listener_Address nVarChar(25) output,
 	 @Listener_Port 	 Int 	 Output,
 	 @IsCluster 	 Int 	 Output
  AS
select @IsCluster =  coalesce(Convert(int,Value),0)
 from site_parameters s
 Join  parameters p on p.Parm_Id = s.Parm_Id 
 Where Parm_Name = 'ClusteredSystem'
Select  @Listener_Address = Listener_Address,@Listener_Port = Listener_Port  From  cxs_Service  Where Service_Id = 14
