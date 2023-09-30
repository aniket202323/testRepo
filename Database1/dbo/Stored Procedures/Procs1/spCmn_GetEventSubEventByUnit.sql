CREATE PROCEDURE dbo.spCmn_GetEventSubEventByUnit
@Sheet_Id int, 
@PUs varchar(7000) = NULL, 
@ReturnIDDescOnly tinyint = 0 
AS
/*
This proc was created to make sure the SOE Event type logic stays consistant. This proc is called by SOE and the Administrator. 
*/
 Create Table #PUET
 ( 
  PUId int,
  PUDesc Varchar(50) null,
  GroupId int null, 
  EventSubTypeId int,
  EventSubTypeDesc Varchar(50) Null,
  ETId int,
  DurationRequired bit null,
  CauseRequired bit null,
  ActionRequired bit null,
  AckRequired bit null,
  Selected bit null,
  ATId int NULL
  )
 Create Table #PUs (PU_id int)
 If @Sheet_Id IS NOT NULL 
   Begin
     Insert Into #PUs
       Select PU_Id from Sheet_Unit Where Sheet_Id = @Sheet_Id 
   End
 Else
   Begin
     Declare @V 	 VarChar(10)
 --declare @pus varchar(255) Select @pus = '2,3,4,5 ,6,  7,'
     Select @pus = CASE
        When RIGHT(LTRIM(RTRIM(@PUs)),1) = ',' Then LTRIM(RTRIM(@PUs))
        Else LTRIM(RTRIM(@PUs)) + ',' 
      END
     While (Datalength( LTRIM(RTRIM(@PUs))) > 1) 
       Begin
           Select @V = SubString(@PUs,1,CharIndex(',',@PUs)-1)
           Select @PUs = SubString(@PUs,CharIndex(',',@PUs),Datalength(@PUs))
           Select @PUs = Right(@PUs,Datalength(@PUs)-1)
           Insert Into #PUs Select CONVERT(int,@V)
       End
   End
-- build temporary table that shows all pUids that should be tracked down by SOE for this SHeeId
-- FOr each PUId gets the Event_Subtypes (from Event_config table) that indicates which ET_Ids
-- should be displayed for each area. IT includes only the ET's that have includeOnSoe=1 and can have subtypes
 Insert Into #PUET  
  Select PU.PU_Id, PU.PU_Desc,PU.Group_Id, ES.Event_SubType_Id, ES.Event_SubType_Desc, ES.ET_Id, ES.Duration_Required, 
         ES.Cause_Required,ES.Action_Required,ES.ACK_Required, 1, NULL
   From #PUs SU Inner Join Prod_Units PU on SU.PU_id = PU.PU_Id
                      Inner Join Event_Configuration EC on SU.PU_Id = EC.PU_Id
                      Inner Join Event_SubTypes ES on EC.Event_SubType_Id = ES.Event_SubType_Id
                      Inner Join Event_Types ET on ES.ET_Id = ET.ET_Id
    Where ET.IncludeOnSoe = 1
      And ET.SubTypes_Apply = 1
-- Include a generic event_subtype for each unit for each ET that can not have subtypes and should be displayed by SOE
--Alarms, DownTime, and Waste are handled separately down below.
 Insert Into #PUET
  Select SU.PU_Id, PU.PU_Desc, PU.Group_Id, (-1* ET.ET_Id) as Event_SubType_Id, ET.ET_Desc as Event_SubType_Desc, 
   ET.ET_Id, 1, 0, 0, 1, 1, NULL
    From Event_Types ET, #PUs SU Inner Join  Prod_Units PU on SU.PU_Id = PU.PU_Id
     Where ET.IncludeOnSoe = 1
      And ET.SubTypes_Apply = 0 
        And ET_Id <> 11 and ET_Id <> 2 and ET_Id <> 3
 Insert Into #PUET
  Select distinct SU.PU_Id, PU.PU_Desc, PU.Group_Id, (-1* ET.ET_Id) as Event_SubType_Id, ET.ET_Desc as Event_SubType_Desc, 
   ET.ET_Id, 1, 0, PE.Action_Tree_Id, 1, 1, NULL
    From Event_Types ET, #PUs SU Inner Join Prod_Units PU on SU.PU_Id = PU.PU_Id
     Left Outer Join Prod_Events PE on PE.PU_Id = SU.PU_Id
     Where ET.IncludeOnSoe = 1
      And ET.SubTypes_Apply = 0 
        And (ET_Id = 2 or ET_Id = 3)
         And PE.Event_Type = ET_Id
-- If alarms are being displayed by SOE, it includes a generic event_subtype for each different alarm level
Declare @AlarmEventDescription varchar(100)
 Select @AlarmEventDescription = Et_Desc From Event_Types Where ET_ID = 11
 If (Select IncludeOnSoe From Event_Types Where ET_Id = 11) = 1
  Begin
   Insert Into #PUET
    Select SU.PU_Id, PU.PU_Desc,PU.Group_Id, -10000, @AlarmEventDescription + ' Low',11,1,T.Cause_Tree_Id,T.Action_Tree_Id,1,1,T.AT_Id
     From #PUs SU Inner Join Prod_Units PU on SU.PU_id = PU.PU_Id
     Join Variables V on V.PU_Id = SU.PU_Id
     Join Alarm_Template_Var_Data D on D.Var_Id = V.Var_Id
     Join Alarm_Templates T on T.AT_Id = D.AT_Id
   Insert Into #PUET
    Select SU.PU_Id, PU.PU_Desc,PU.Group_Id, -10001, @AlarmEventDescription + ' Medium',12,1,T.Cause_Tree_Id,T.Action_Tree_Id,1,1,T.AT_Id
     From #PUs SU Inner Join Prod_Units PU on SU.PU_id = PU.PU_Id
     Join Variables V on V.PU_Id = SU.PU_Id
     Join Alarm_Template_Var_Data D on D.Var_Id = V.Var_Id
     Join Alarm_Templates T on T.AT_Id = D.AT_Id
   Insert Into #PUET
    Select SU.PU_Id, PU.PU_Desc,PU.Group_Id, -10002, @AlarmEventDescription + ' High',13,1,T.Cause_Tree_Id,T.Action_Tree_Id,1,1,T.AT_Id
     From #PUs SU Inner Join Prod_Units PU on SU.PU_id = PU.PU_Id
     Join Variables V on V.PU_Id = SU.PU_Id
     Join Alarm_Template_Var_Data D on D.Var_Id = V.Var_Id
     Join Alarm_Templates T on T.AT_Id = D.AT_Id
  End 
If @ReturnIDDescOnly = 1 
  Begin
    Select DISTINCT
      EventSubTypeId as [ID] ,
      EventSubTypeDesc as [DESC]
     from #puet
  End
Else
  Begin
    Select 
      PUId ,
      PUDesc ,
      GroupId, 
      EventSubTypeId ,
      EventSubTypeDesc ,
      ETId ,
      DurationRequired ,
      CauseRequired ,
      ActionRequired ,
      AckRequired ,
      Selected ,
      ATId 
     from #puet
  End
drop table #puet
drop table #pus
