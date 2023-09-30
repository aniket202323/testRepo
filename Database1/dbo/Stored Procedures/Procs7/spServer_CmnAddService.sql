create procedure dbo.spServer_CmnAddService
@Service_Id int, 
@Proficy_Service_Name nVarChar(300), 
@Service_Desc nVarChar(300), 
@Service_Display nVarChar(300), 
@Node_Name nVarChar(300),
@Listener_Address nVarChar(300), 
@Listener_Port int, 
@Is_Active int, 
@Monitor_Service int, 
@Auto_Start int, 
@Auto_Stop int, 
@Start_Check_Time int, 
@Stop_Check_Time int, 
@Start_Order int, 
@Restart_Wait_Time int, 
@Restart_Non_Responding int
AS
Declare
  @count int
 	 select @count=0
 	 Select @count =count(service_id) from CXS_Service Where Service_Id = @service_id
 	 if (@count = 0 or @count is null)
 	 begin
 	  	 SET IDENTITY_INSERT CXS_Service ON
 	  	 INSERT CXS_Service(Service_Id, Proficy_Service_Name, Service_Desc, Service_Display, Listener_Address, Listener_Port, Is_Active, Monitor_Service, Auto_Start, Auto_Stop, Start_Check_Time, Stop_Check_Time, Start_Order, Restart_Wait_Time, Restart_Non_Responding,Node_Name) 
 	  	  	  	  	  	 VALUES( @Service_Id, @Proficy_Service_Name, @Service_Desc, @Service_Display, @Listener_Address, @Listener_Port, @Is_Active, @Monitor_Service, @Auto_Start, @Auto_Stop, @Start_Check_Time, @Stop_Check_Time, @Start_Order, @Restart_Wait_Time, @Restart_Non_Responding,@Node_Name)
 	  	 SET IDENTITY_INSERT CXS_Service OFF
 	  	 return
 	 end
 	 update CXS_Service 
 	  	  	  	 set Proficy_Service_Name=@Proficy_Service_Name, 
 	  	  	  	  	  	 Service_Desc = @Service_Desc, 
 	  	  	  	  	  	 Service_Display = @Service_Display, 
 	  	  	  	  	  	 Is_Active=@Is_Active, 
 	  	  	  	  	  	 Monitor_Service=@Monitor_Service, 
 	  	  	  	  	  	 Auto_Start=@Auto_Start, 
 	  	  	  	  	  	 Auto_Stop=@Auto_Stop, 
 	  	  	  	  	  	 Restart_Non_Responding = @Restart_Non_Responding 
 	  	  	  	 where Service_Id=@Service_Id
