Create Procedure dbo.spServer_CmnAddThreadPool
@Pool_Desc nVarChar(100),
@Is_Default bit,
@Is_Message_Pool bit,
@Thread_Count int,
@Service_Id smallint,
@Pool_Id int OUTPUT
AS
if (@Is_Default = 1)
 	 Begin
 	  	 Select @Pool_Id = NULL
 	  	 Select Top 1 @Pool_Id = Pool_Id From Service_ThreadPools Where Service_Id = @Service_Id and Is_Default = 1 order by Pool_Id
 	  	 if (@Pool_Id is not null)
 	  	  	 return
 	 End
Select @Pool_Id = NULL
Select @Pool_Id = Pool_Id From Service_ThreadPools Where Service_Id = @Service_Id and Pool_Desc = @Pool_Desc and Is_Default = @Is_Default and Is_Message_Pool = @Is_Message_Pool
if (@Pool_Id is null)
 	 Begin
 	  	 insert into Service_ThreadPools (Pool_Desc, Is_Default, Thread_Count, Service_Id, Is_Message_Pool) Values (@Pool_Desc, @Is_Default, @Thread_Count, @Service_Id, @Is_Message_Pool)
 	  	 Select @Pool_Id = Pool_Id From Service_ThreadPools Where Service_Id = @Service_Id and Pool_Desc = @Pool_Desc and Is_Default = @Is_Default and Is_Message_Pool = @Is_Message_Pool
 	 End
