--  spEMEC_UpdateIsActive 118,0,1
CREATE Procedure dbo.spEMEC_UpdateIsActive
@EC_Id int,
@Activate bit,
@User_Id int
as
Declare @Insert_Id int, @InActive int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMEC_UpdateIsActive',
             Convert(nVarChar(10),@EC_Id) + ','  + 
 	 Convert(nVarChar(10),@Activate) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
DECLARE @ModelId Int, @ESId Int
Select @ModelId = ED_Model_Id,@ESId = Event_Subtype_Id  From Event_Configuration Where EC_Id = @EC_Id
IF @ModelId = 5400
BEGIN
 	 UPDATE Event_Configuration set Is_Active = 0,Is_Calculation_Active = @Activate,Priority = Null WHERE EC_Id = @EC_Id
 	 EXECUTE spEMEC_ConfigureModel5014 @EC_Id, @Activate
 	 RETURN
END
 Declare 
   @ETId int,
   @PUId int
 Select @ETId = ET_Id
   From ED_Models
   Where ED_Model_Id = @ModelId
 Select @PUId = PU_Id 
   From Event_Configuration c
   Where EC_Id = @EC_Id
If @ETId Is NULL
BEGIN
 Select @ETId = ET_Id
    From Event_Configuration c
    Where EC_Id = @EC_Id
END
-- For these types, secondary models cannot be stored in Event_Configuration 
Select @InActive = (Select Case When Single_Event_Configuration = 1 Then 0 Else 2 End From Event_Types Where ET_Id = @ETId)
Select @InActive = isnull(@InActive,0)
-- Genealogy (ET_Id = 10)
-- Import/Export (ET_Id = 7/8)
-- Only these event types can have multiple active models 
-- UserDefined (14)
If (Select Allow_Multiple_Active From Event_Types Where ET_Id = @ETId) = 0 
  Begin
    Update Event_Configuration set is_active = 0,Priority = Null
    From Event_Configuration c
    Join ED_Models m on m.ED_Model_Id = c.ED_Model_Id and m.ET_Id = @ETId
    Where EC_Id <> @EC_Id and PU_Id = @PUId
  End
Else
  Begin
    Update Event_Configuration set is_active = 0,Priority = Null
    From Event_Configuration c
    Join ED_Models m on m.ED_Model_Id = c.ED_Model_Id and m.ET_Id = @ETId
    Where EC_Id <> @EC_Id and PU_Id = @PUId and c.is_active = 2
  End
 update event_configuration set is_active = 
   CASE
     WHEN @Activate = 1 THEN 1
      ELSE @InActive
   END,
   Priority =    CASE
     WHEN @Activate <> 1 THEN Null
      ELSE 1
   END
    where ec_id = @EC_Id
DECLARE @ECId int, @IsActive tinyint
IF @ModelId = 100
BEGIN
 	 IF (select count(*) from event_configuration where ed_model_id = 100 and is_active = 1) > 0
 	 BEGIN
 	  	 if (select count(*) from event_configuration where ed_model_id = 49000 and pu_id = 0) > 0
 	  	 BEGIN
 	  	  	 select @ECId = EC_Id, @IsActive = Is_Active from event_configuration where ed_model_id = 49000 and pu_id = 0
 	  	  	 if @ECId is not NULL and @IsActive <> 1
 	  	  	    update event_configuration set is_active = 1 WHERE  EC_Id = @ECId
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	 exec spEMEC_CreateNewEC 0, 0, '', 7, Null, 1, @ECId OUTPUT
 	  	  	 exec spEMEC_UpdateAssignModel @ECId, 49000, 0, 1
 	  	 END
 	 END
 	 ELSE
 	 BEGIN
 	  	 select @ECId = EC_Id, @IsActive = Is_Active from event_configuration where ed_model_id = 49000 and pu_id = 0
 	  	 if @ECId is not NULL and @IsActive = 1
 	  	  	    update event_configuration set is_active = 0 WHERE  EC_Id = @ECId
 	 END
END
If @ETId = 2
 	 Update Prod_Units set Timed_Event_Association = 0 where pu_Id = @PUId and Timed_Event_Association is null
If @ETId = 14 AND  @ModelId = 5404   --Ude Model 802
 	 Update Event_Subtypes set Duration_Required = 1 where Event_Subtype_Id = @ESId
-- Update cxs_service set Reload_Flag = 2,Time_Stamp = dbo.fnServer_CmnGetDate(getUTCdate()) Where Service_Id = 4 and Reload_Flag IS NULL 
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
