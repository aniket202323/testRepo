Create Procedure dbo.spPC_GetCxsServiceAndDebugInfo
  AS
Declare @Listener_Address 	 nvarchar(25),
 	  	 @GateWay_Listener_Port 	  	 Int 	 ,
 	  	 @IsCluster 	  	  	 Int,
 	  	 @Manager_Listener_Port 	 Int
/*
User Id    Service
2           Reader
3           SummaryMgr
5           Stubber
6           EventMgr
8 	  	  	  	 Schedule manager
14          DatabaseMgr
15          Gateway
16          MessageBus
18          Writer
20          AlarmMgr
21          FTPEngine
26          CalculationMgr
*/
select @IsCluster =  coalesce(Convert(int,Value),0)
 from site_parameters s
 Join  parameters p on p.Parm_Id = s.Parm_Id 
 Where Parm_Name = 'ClusteredSystem'
Select  @Listener_Address = Listener_Address,@GateWay_Listener_Port = Listener_Port  From  cxs_Service  Where Service_Id = 14
Select  @Manager_Listener_Port = Listener_Port  From  cxs_Service  Where Service_Id = 15
Select Listener_Address = @Listener_Address,GateWay_Listener_Port = @GateWay_Listener_Port,Manager_Listener_Port = @Manager_Listener_Port,IsCluster = @IsCluster
Select u.User_Id,ServiceId = Case When u.User_Id = 2 Then 5
 	  	  	  	  	  	 When u.User_Id = 3 Then 7
 	  	  	  	  	  	 When u.User_Id = 5 Then 8
 	  	  	  	  	  	 When u.User_Id = 6 Then 4
 	  	  	  	  	  	 When u.User_Id = 8 Then 22
 	  	  	  	  	  	 When u.User_Id = 14 Then 2
 	  	  	  	  	  	 When u.User_Id = 15 Then 14
 	  	  	  	  	  	 When u.User_Id = 16 Then 9
 	  	  	  	  	  	 When u.User_Id = 18 Then 6
 	  	  	  	  	  	 When u.User_Id = 19 Then 16
 	  	  	  	  	  	 When u.User_Id = 20 Then 17
 	  	  	  	  	  	 When u.User_Id = 21 Then 18
 	  	  	  	  	  	 When u.User_Id = 26 Then 19
 	  	  	  	  	  	 When u.User_Id = 28 Then 20
 	  	  	  	  	 End,
  	 FullLogging = 0,DebugValue = Coalesce(p1.value,0)
 From Users u
 Left Join User_parameters p1 on p1.User_Id = u.User_id and p1.parm_Id = 112 and HostName = ''
 	 where u.User_Id in (2,3,5,6,8,14,15,16,18,19,20,21,26,28)
Select ec.EC_Id,Debug = coalesce(ec.debug,0),Line_Desc = Coalesce(pl.Pl_Desc,'<none>'),Unit_Desc = Coalesce(pu.PU_Desc,'<none>'),EC_Desc = coalesce(edm.Model_Desc,'<None>'),ModelNum = coalesce(Convert(nVarChar(10),modelnum),'<None>')
 from event_configuration ec
 Left Join ed_Models edm on edm.ED_Model_Id = ec.ED_Model_Id
left Join Prod_units pu On pu.PU_Id = ec.pu_Id
left Join Prod_Lines pl on pl.Pl_Id = pu.PL_Id
Where ec.Is_Active = 1
Order by Line_Desc,Unit_Desc,model_num
Select Service_Id,Service_Display From cxs_Service where Service_Id <> 50
Select Var_Id,Var_Desc,Debug,PU_Desc,PL_Desc
from Variables v
Join Prod_Units pu on pu.pu_Id = v.PU_Id
Join Prod_Lines pl on pl.pL_Id = pu.PL_Id
Where Debug <> 0 and Debug is not null and v.PU_Id > 0 and (System = 0 or System is null)
