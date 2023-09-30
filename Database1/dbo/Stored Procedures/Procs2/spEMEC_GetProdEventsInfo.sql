Create Procedure dbo.spEMEC_GetProdEventsInfo 
@PU_Id int,
@Case tinyint,
@Action_Tree_Id int = NULL,
@Switch bit = NULL,
@ET_Id int = 2,
@User_Id int
AS
declare @Association tinyint,
@Tree_Name_Id int,
@Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMEC_GetProdEventsInfo',
             Convert(nVarChar(10),@PU_Id) + ','  + 
 	 Convert(nVarChar(10),@Case) + ','  + 
 	 Convert(nVarChar(10),@Action_Tree_Id) + ','  + 
 	 Convert(nVarChar(10),@Switch) + ','  + 
 	 Convert(nVarChar(10),@ET_Id) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
-- This is to insert an action tree only (must have a cause tree)
Select @Tree_Name_Id = Min(tree_name_id) From event_reason_tree
if @ET_Id = 2
  Begin
    select @Association = timed_event_association
    from prod_units
    where pu_id = @PU_Id
  End
else if @ET_Id = 3
  Begin
    select @Association = waste_event_association
    from prod_units
    where pu_id = @PU_Id
  End
if @Action_Tree_Id = 0
  select @Action_Tree_Id = Null
if @Case = 1
  Begin
    select Action_Reason_Enabled, Action_Tree_Id, Research_Enabled
    from Prod_Events
    where PU_Id = @PU_Id and Event_Type = @ET_Id
  End
else if @Case = 2 and @Association > 0
  Begin
 	 -- Check if exists
    If (Select Count(*) From Prod_Events Where PU_Id = @PU_Id and Event_Type = @ET_Id) = 0
      Insert into prod_events(PU_ID, Name_Id, Event_Type, Action_Reason_Enabled) values (@PU_Id, @Tree_Name_Id, @ET_Id, 1)
    Update Prod_Events set Action_Reason_Enabled =  CASE WHEN @Switch = 1 THEN 1  ELSE 0  END
      where PU_Id = @PU_Id and Event_Type = @ET_Id
  End
else if @Case = 2 and @Association = 0
  Begin
    if @ET_Id = 2
      Begin
        update prod_units set timed_event_association = 1
        where pu_id = @PU_Id
      End
    else if @ET_Id = 3
      Begin
        update prod_units set waste_event_association = 1
        where pu_id = @PU_Id
      End
    insert into prod_events(PU_ID, Name_Id, Event_Type, Action_Reason_Enabled) values (@PU_Id, @Tree_Name_Id, @ET_Id, 1)
  End
else if @Case = 3 and @Association > 0
  Begin
    update Prod_Events set Action_Tree_Id = @Action_Tree_Id
    where PU_Id = @PU_Id and Event_Type = @ET_Id
  End
else if @Case = 3 and @Association = 0
  Begin
    if @ET_Id = 2
      Begin
        update prod_units set timed_event_association = 1
        where pu_id = @PU_Id
      End
    else if @ET_Id = 3
      Begin
        update prod_units set waste_event_association = 1
        where pu_id = @PU_Id
      End
    insert into prod_events(PU_ID, Name_Id, Event_Type, Action_Tree_Id) values (@PU_Id, @Tree_Name_Id, @ET_Id, @Action_Tree_Id)
  End
else if @Case = 4 and @Association > 0
  Begin
    update Prod_Events set Research_Enabled =
     CASE
       WHEN @Switch = 1 THEN 1
        ELSE 0
     END
      where PU_Id = @PU_Id and Event_Type = @ET_Id
  End
else if @Case = 4 and @Association = 0
  Begin
    if @ET_Id = 2
      Begin
        update prod_units set timed_event_association = 1
        where pu_id = @PU_Id
      End
    else if @ET_Id = 3
      Begin
        update prod_units set waste_event_association = 1
        where pu_id = @PU_Id
      End
    insert into prod_events(PU_ID, Name_Id, Event_Type, Research_Enabled) values (@PU_Id, @Tree_Name_Id, @ET_Id, 1)
  End
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
