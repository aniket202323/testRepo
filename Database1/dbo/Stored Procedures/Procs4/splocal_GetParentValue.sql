 /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-11-02  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Altered by  : ?  
Date   : ?  
Version  : 1.0.0  
Purpose  : ?   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
*/  
  
CREATE PROCEDURE dbo.splocal_GetParentValue  
@OutputValue varchar(25) OUTPUT,  
@Var_id int,  
@ParentEventId int,  
@ParentTimestamp varchar(25),  
@PU_ID int  
AS  
SET NOCOUNT ON  
Declare  
  @Var_IdDepend int,  
  @Pu_IdDepend int,  
  @Source_Event_Id int,  
  @Result varchar(25),  
  @@Event_id int,  
  @Event_id  int,  
  @Childtimestamp varchar(25),  
  @Value float,  
  @Var_ExtInfoDepend varchar(40),  
  @ChildVar_Id int,  
  @ChildPu_Id int  
  
-- Disable SP  
Return  
  
--- Get the depend variable and var_id  
Select @Var_IdDepend = d.Var_Id From calculation_instance_dependencies d   
  inner join variables v on(d.var_id = v.var_id)   
  Where d.Result_Var_Id = @var_id and v.pu_id = @Pu_Id  
  
If (@Var_IdDepend Is Null)  
  Return  
select @Pu_IdDepend = PU_Id from variables where var_id = @Var_IdDepend  
  
Select @ChildVar_id = d.Var_Id From calculation_instance_dependencies d   
  inner join variables v on(d.var_id = v.var_id)   
  Where d.Result_Var_Id = @var_id and v.pu_id <> @Pu_Id  
  
--- End depend  
Select @Value =  Result from tests where result_on = @ParentTimestamp and var_id = @Var_IdDepend  
--- get the parent Event_id  
/*Select Event_Id   
   Into #ChildEvent_id  
   from event_components  
   where Source_Event_Id = @ParentEventId */  
Select Event_Id   
   Into #ChildEvent_id  
   from events  
   where Source_Event = @ParentEventId  
  
---Temp table for result set  
Create Table #Var_Info(  
Var_Id     int null,  
Pu_Id    int null,  
User_Id    int null,  
Canceled   int null,  
Result    varchar(25),  
Result_On   varchar(30),  
Trasaction_Type   int,  
PostUpdate   int)  
  
--Fetch to find timestamp and put the data  
  
Declare Depend_Cursor INSENSITIVE CURSOR  
  For (Select Event_Id From #ChildEvent_id)  
  For Read Only  
  Open Depend_Cursor    
  
Fetch_Loop:  
  Fetch Next From Depend_Cursor Into @@Event_id  
  If (@@Fetch_Status = 0)  
    Begin  
      Select @Event_id = NULL  
      Select @Event_id = @@Event_id  
      If (@Event_id Is Not Null)   
 Begin  
   Select @Childtimestamp = Timestamp from events where event_id = @Event_Id  
        Select @ChildPu_Id  = Pu_Id from events where event_Id = @Event_Id   
   insert into #var_info (Var_Id,Pu_Id,User_Id,Canceled,Result,Result_On,Trasaction_Type,PostUpdate)   
   Values(@ChildVar_id,@ChildPu_Id,6,0,@Value,@Childtimestamp,1,0)  
   
       End  
       Goto Fetch_Loop  
     End  
  
Select 2,Var_Id,Pu_Id,User_Id,Canceled,Result,Result_On,Trasaction_Type,PostUpdate from #Var_info  
select @OutputValue = convert(varchar(25),@Var_IdDepend)  
  
Close Depend_Cursor  
Deallocate Depend_Cursor  
Drop Table #ChildEvent_id  
Drop Table #Var_Info  
--- end  
  
SET NOCOUNT OFF  
  
