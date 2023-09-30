Create Procedure dbo.spEMEC_DTAssociation 
@PU_Id int,
@ET_Id int = 2,
@Based tinyint = Null,
@User_Id int
--@Name_Id int = Null
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMEC_DTAssociation',
             Convert(nVarChar(10),@PU_Id) + ','  + 
 	 Convert(nVarChar(10),@ET_Id) + ','  + 
 	 Convert(nVarChar(10),@Based) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
if @Based > 0
  Begin
  if @ET_Id = 2
    Begin
      update prod_units set timed_event_association = @Based
      where pu_id = @PU_Id
    End
  else if @ET_Id = 3
    Begin
      if @Based = 1
        Begin
          update prod_units set waste_event_association = @Based
          where pu_id = @PU_Id
        End
      else if @Based = 2
        Begin
          update prod_units set waste_event_association = @Based
          where pu_id = @PU_Id
        End
      End
/*
    insert into prod_events(PU_ID, Name_Id, Event_Type) values (@PU_Id, @Name_Id, @ET_Id)
*/
  End
else if @Based = 0
  Begin
  if @ET_Id = 2
    Begin
      update prod_units set timed_event_association = @Based
      where pu_id = @PU_Id
    End
  else if @ET_Id = 3
    Begin
      update prod_units set waste_event_association = @Based
      where pu_id = @PU_Id
    End
    delete from prod_events
    where pu_id = @PU_Id
    and event_type = @ET_Id
  End
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
