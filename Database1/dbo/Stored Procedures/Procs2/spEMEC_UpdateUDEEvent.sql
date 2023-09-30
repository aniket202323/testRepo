/* This sp is called by dbo.spBatch_GetSingleUDEvent parameters need to stay in sync*/
/* This sp is called by dbo.spBatch_ProcessEventReport parameters need to stay in sync*/
/* This sp is called by dbo.spEM_IEImportEventSubTypes parameters need to stay in sync*/
Create Procedure dbo.spEMEC_UpdateUDEEvent
@Event_Subtype_Id int = NULL,
@Event_Subtype_Desc nvarchar(50),
@Icon_Id int,
@Duration_Required bit,
@Cause_Required bit,
@Action_Required bit,
@Ack_Required bit,
@ESignature_Level int,
@User_Id int,
@New_Event_Subtype_Id int OUTPUT,
@DefaultStatus Int  = Null OUTPUT
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMEC_UpdateUDEEvent',
             Convert(nVarChar(10),@Event_Subtype_Id) + ','  + 
 	 @Event_Subtype_Desc + ','  + 
             Convert(nVarChar(10),@Icon_Id) + ','  + 
             Convert(nVarChar(10),@Duration_Required) + ','  + 
             Convert(nVarChar(10),@Cause_Required) + ','  + 
             Convert(nVarChar(10),@Action_Required) + ','  + 
             Convert(nVarChar(10),@Ack_Required) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
if @Icon_Id = 0
  select @Icon_Id = Null
select @New_Event_Subtype_Id = @Event_Subtype_Id
if @Event_Subtype_Id is NULL
  Begin
 	 if @DefaultStatus = 0 SELECT @DefaultStatus = Null
    insert into event_subtypes (event_subtype_desc, icon_id, et_id, duration_required, cause_required, action_required, ack_required, ESignature_Level,Default_Event_Status) values 
                               (@Event_Subtype_Desc, @Icon_Id, 14, @Duration_Required, @Cause_Required, @Action_Required, @Ack_Required, @ESignature_Level,@DefaultStatus)
    select @New_Event_Subtype_Id = Scope_Identity()
  End
else
  Begin
 	 IF @DefaultStatus is null SELECT @DefaultStatus = Default_Event_Status  FROM event_subtypes WHERE event_subtype_id = @Event_Subtype_Id
 	 if @DefaultStatus = 0 SELECT @DefaultStatus = Null
    update event_subtypes set event_subtype_desc = @Event_Subtype_Desc, icon_id = @Icon_Id, duration_required = @Duration_Required, cause_required = @Cause_Required,
                                                action_required = @Action_Required, ack_required = @Ack_Required, ESignature_Level = @ESignature_Level,Default_Event_Status  = @DefaultStatus
    where event_subtype_id = @Event_Subtype_Id
  End
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
