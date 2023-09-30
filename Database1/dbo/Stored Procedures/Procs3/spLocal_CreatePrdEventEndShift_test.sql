



/*

Stored Procedure:	spLocal_CreatePrdEventEndShift

Author:			Steven Stier (Stier Automation LLC)

Date Created:		5/5/03

sp_help spLocal_CreatePrdEventEndShift_test

Description:

=========
drop proc spLocal_CreatePrdEventEndShift_test
This Sp is called by model 602 and Searches for the End of a shift run every 5 minutes. If it finds one it inserts a production event for the appriate production unit.



Change Date	Who	What

===========	====	=====

5/5/03	SLS	Initial Creation

*/



CREATE procedure spLocal_CreatePrdEventEndShift_test

@status 	int output,

@errormsg 	varchar(255) output,

@ecid 		int



as

Declare @Runtime             	 datetime,

	@pu_id 		int,  

       	 @CurrentTime 		datetime,

	@CT_10min		datetime,

        	@Count 		int, 

	@TimeStamp              	datetime,
	
	     @onehourahead datetime,
@onehourbefore datetime,

	@Julian_Date		varchar(25),

	@Event_Count		int,

	@Event_Id 		int,

	@Event_num 		varchar(30),	

        	@Loop_Count		int,

	@Duplicate_Count	int,

	@Prod_Start_Date	datetime,

	@Complete_Status	int,

	@Default_Window	int



Create Table #EventUpdates (

--	Result_Set_Type	int Default 1,

	Id		     	int Identity,

	Transaction_Type 	int Default 1, 

	Event_Id 		int Null, 

	Event_Num 		varchar(25) Null, 

	PU_Id 			int Null,

	TimeStamp 		datetime Null, 

	Applied_Product 	int Null, 

	Source_Event 		int Null, 

	Event_Status 		int Null, 

	Confirmed 		int Default 1,

	User_Id			int Default 1,

	Post_Update		int Default 0)



Create Table #VariableUpdates (

--	Result_Set_Type	int Default 2,

	Var_Id		     	int Null,

	PU_Id 			int Null, 

	User_Id			int Default 1,

	Cancelled 		int Default 0,

	Result	 		varchar(25) Null, 

	Result_On 		datetime Null, 

	Transaction_Type 	int Default 1, 

	Post_Update		int Default 0)



/* Initialization */

Select 	@Default_Window 	= 365,

	@Event_Count		= 0,

	@Loop_Count		= 0,

	@Duplicate_Count	= 1,

	@Complete_Status	= 5



select @status = 1

select @errormsg = ''



--The following lines are for debugging.  Sometime the model miss some record of crew schedule

select @runtime=getdate()



--get the puid where we should create an event

select @pu_id = pu_id from event_configuration where ec_id=@ecid





--find current time

select @currentTime=getdate()

--select @CurrentTimeStr=convert(varchar(30),@currentTime,20)

--select @currenttimestr=left(@currenttimestr,16)

--select @currenttime=convert(datetime,@currentTimeStr)

select @CT_10min = dateadd(mi,-6,@currenttime)


select  @onehourahead =dateadd(mi,60,@currenttime)
select @onehourbefore= dateadd(mi,-6,@onehourahead)



select @count=count(cs_id) from crew_schedule where pu_id=@pu_id and end_time between @onehourbefore and @onehourahead 

if @count=1

begin
	select @TimeStamp = dateadd(mi,-60,end_time) from crew_schedule where pu_id=@pu_id and end_time between @onehourbefore and @onehourahead  


--compare with crew schedule table

select @count=count(event_id) from events where timestamp = @TimeStamp and pu_id = @pu_id

	if @count =0

	begin

	          /* Get Julian date and starting event increment*/

	          Select @Julian_Date = right(datename(yy, @TimeStamp),1)+right('000'+datename(dy, @TimeStamp), 3)

	

	          Select @Event_Count = round((convert(float, @TimeStamp)-floor(convert(float, @TimeStamp)))*86400, 0)

	

	          /* Build the Event number, check for duplicates and if found increment counter and rebuild the event number */

	          While @Duplicate_Count > 0 And @Loop_Count < 1000

	               Begin

	               Select @Event_Num =  'PE' + @Julian_Date + right(convert(varchar(25),@Event_Count+1000000),5)

	

	               Select @Duplicate_Count = count(Event_Id) 

	               From Events 

	               Where PU_Id = @PU_Id And Event_Num = @Event_Num

	

	               Select @Event_Count = @Event_Count + 1

	               Select @Loop_Count = @Loop_Count + 1								/* Prevent infinite loops */

	               End



	          Insert into #EventUpdates (Transaction_Type, Event_Id, Event_Num, PU_Id, TimeStamp, Event_Status)

	          Values (1, Null, @Event_Num, @PU_Id, @TimeStamp, @Complete_Status)     

End

     



     /************************************************************************************************************************************************************************

     *                                                                                                        Output Results                                                                                               *

     ************************************************************************************************************************************************************************/

     /* Issue event updates */

     If (Select count(Transaction_Type) From #EventUpdates) > 0

          Select 1, * From #EventUpdates



     /* Issue variable updates */

     If (Select count(Transaction_Type) From #VariableUpdates) > 0

          Select 2, * From #VariableUpdates



end





select @count=count(cs_id) from crew_schedule where pu_id=@pu_id and end_time between @CT_10min and @currenttime



--If more than 0, create a column

if @count=1

begin

	select @TimeStamp = end_time from crew_schedule where pu_id=@pu_id and end_time between @CT_10min and @currenttime



	--verify if there is already an event at this timestamp

	select @count=count(event_id) from events where timestamp = @TimeStamp and pu_id = @pu_id

	if @count =0

	begin

	          /* Get Julian date and starting event increment*/

	          Select @Julian_Date = right(datename(yy, @TimeStamp),1)+right('000'+datename(dy, @TimeStamp), 3)

	

	          Select @Event_Count = round((convert(float, @TimeStamp)-floor(convert(float, @TimeStamp)))*86400, 0)

	

	          /* Build the Event number, check for duplicates and if found increment counter and rebuild the event number */

	          While @Duplicate_Count > 0 And @Loop_Count < 1000

	               Begin

	               Select @Event_Num =  'PE' + @Julian_Date + right(convert(varchar(25),@Event_Count+1000000),5)

	

	               Select @Duplicate_Count = count(Event_Id) 

	               From Events 

	               Where PU_Id = @PU_Id And Event_Num = @Event_Num

	

	               Select @Event_Count = @Event_Count + 1

	               Select @Loop_Count = @Loop_Count + 1								/* Prevent infinite loops */

	               End



	          Insert into #EventUpdates (Transaction_Type, Event_Id, Event_Num, PU_Id, TimeStamp, Event_Status)

	          Values (1, Null, @Event_Num, @PU_Id, @TimeStamp, @Complete_Status)     

End

     



     /************************************************************************************************************************************************************************

     *                                                                                                        Output Results                                                                                               *

     ************************************************************************************************************************************************************************/

     /* Issue event updates */

     If (Select count(Transaction_Type) From #EventUpdates) > 0

          Select 1, * From #EventUpdates



     /* Issue variable updates */

     If (Select count(Transaction_Type) From #VariableUpdates) > 0

          Select 2, * From #VariableUpdates



end





/* Cleanup */

Drop Table #EventUpdates

Drop Table #VariableUpdates



select @status=1

GRANT  EXECUTE  ON [dbo].[spLocal_CreatePrdEventEndShift_test]  TO [comxclient]
