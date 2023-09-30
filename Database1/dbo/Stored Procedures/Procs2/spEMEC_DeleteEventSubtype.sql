CREATE Procedure dbo.spEMEC_DeleteEventSubtype
@Event_Subtype_Id int,
@Case tinyint,
@User_Id int
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMEC_DeleteEventSubtype',
             Convert(nVarChar(10),@Event_Subtype_Id) + ','  + 
 	 Convert(nVarChar(10),@Case) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
/* Obsolete - see spEMEC_LoadEventSubtype.sql
if @Case = 1
  Begin
    select distinct event_configuration.pu_id, prod_units.pu_desc
    from event_configuration
    join prod_units on prod_units.pu_id = event_configuration.pu_id
    where event_configuration.event_subtype_id = @Event_Subtype_Id
  End
*/ 
If @Case = 2
  Begin
    Declare @EC_Id int, @Rows int, @Comment_Id int, @Action_Comment_Id int, @Cause_Comment_Id int, @Research_Comment_Id int, @UDE_Id int
    Declare ECCursor Cursor For
      Select EC_Id from Event_Configuration where Event_Subtype_Id = @Event_Subtype_Id for read only
    Open ECCursor
    While (0=0) Begin
      Fetch Next
        From ECCursor
        Into @EC_Id
      If (@@Fetch_Status <> 0) Break
      exec spEMEC_DeleteEC @EC_Id, 2, @User_Id, @Rows OUTPUT
    End
    Close ECCursor
    Deallocate ECCursor
    Declare UDECursor Cursor For
      Select UDE_Id, Comment_Id, Action_Comment_Id, Cause_Comment_Id, Research_Comment_Id 
      from User_Defined_Events where Event_Subtype_Id = @Event_Subtype_Id for read only
    Open UDECursor
    While (0=0) Begin
      Fetch Next
        From UDECursor
        Into @UDE_Id, @Comment_Id, @Action_Comment_Id, @Cause_Comment_Id, @Research_Comment_Id
      If (@@Fetch_Status <> 0) Break
      if @Comment_Id is not null
        exec spCSS_InsertDeleteComment @UDE_Id, 9, @User_Id, 1, null, @Comment_Id
      if @Action_Comment_Id is not null
        exec spCSS_InsertDeleteComment @UDE_Id, 11, @User_Id, 1, null, @Action_Comment_Id
      if @Cause_Comment_Id is not null
        exec spCSS_InsertDeleteComment @UDE_Id, 10, @User_Id, 1, null, @Cause_Comment_Id
      if @Research_Comment_Id is not null
        exec spCSS_InsertDeleteComment @UDE_Id, 12, @User_Id, 1, null, @Research_Comment_Id
      delete from user_defined_events where ude_id = @UDE_Id
    End
    Close UDECursor
    Deallocate UDECursor
    select @Comment_Id = comment_id from event_subtypes
    where event_subtype_id = @Event_Subtype_Id 
    if @Comment_Id is not null
      exec spCSS_InsertDeleteComment @Event_Subtype_Id, 26, @User_Id, 1, null, @Comment_Id
 	 UPDATE Variables_Base Set Event_Subtype_Id = Null,Event_Type  = 0,DS_Id = 4 WHERE Event_Subtype_Id = @Event_Subtype_Id
    delete from event_subtypes where event_subtype_id = @Event_Subtype_Id
  End
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
