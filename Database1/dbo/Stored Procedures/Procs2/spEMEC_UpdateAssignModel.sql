/* This sp is called by dbo.spBatch_CreateBatchUnit parameters need to stay in sync*/
Create Procedure dbo.spEMEC_UpdateAssignModel
@EC_Id int,
@ED_Model_Id int,
@PU_Id int,
@User_Id int
as
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMEC_UpdateAssignModel',
        Coalesce(Convert(nVarChar(10),@EC_Id),'(null)') + ','  + 
 	 Coalesce(Convert(nVarChar(10),@ED_Model_Id),'(null)') + ','  + 
 	 Coalesce(Convert(nVarChar(10),@PU_Id),'(null)') + ','  + 
        Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
update event_configuration set ed_model_id = @ED_Model_Id
where ec_id = @EC_Id
Declare @ED_Field_Id int, 
  @ED_FieldType_Id int, 
  @Init varchar(8000), 
  @ECV_Id int
--     Don't add rows for script types.
Declare EDCursor INSENSITIVE CURSOR
--For (Select ED_Field_Id, ED_Field_Type_Id from ED_Fields where ED_Model_Id = @ED_Model_Id and ED_Field_Type_Id not in(17, 18, 19,20)) -- Check With Joe on this One!!!
For (Select ED_Field_Id, ED_Field_Type_Id,Default_Value from ED_Fields where ED_Model_Id = @ED_Model_Id And ED_Field_Type_Id not in (66))
  For Read Only
  Open EDCursor  
EDLoop:
  Fetch Next From EDCursor Into @ED_Field_Id, @ED_FieldType_Id,@Init
  If (@@Fetch_Status = 0)
    Begin
      insert into event_configuration_values(value) values (@Init) 
      select @ECV_Id = IDENT_CURRENT('event_configuration_values')
      insert into event_configuration_data (EC_Id, ED_Field_Id, ECV_Id, PU_Id) Values (@EC_Id, @ED_Field_Id,  @ECV_Id, @PU_Id)
      Goto EDLoop
    End
Close EDCursor
Deallocate EDCursor
declare @ECId int, @IsActive tinyint
if (select count(*) from event_configuration where ed_model_id = 100) > 0
 	 begin
 	  	 if (select count(*) from event_configuration where ed_model_id = 49000 and pu_id = 0) > 0
 	  	   begin
 	  	  	  	 select @ECId = EC_Id, @IsActive = Is_Active from event_configuration where ed_model_id = 49000 and pu_id = 0
 	  	  	  	 if @ECId is not NULL and @IsActive <> 1
 	  	  	  	  	 exec spEMEC_UpdateIsActive @ECId, 1, @User_Id
 	  	  	 end
 	  	 else
 	  	  	 begin
 	  	  	  	 exec spEMEC_CreateNewEC 0, 0, '', 7, Null, @User_Id, @ECId OUTPUT
 	  	  	  	 exec spEMEC_UpdateAssignModel @ECId, 49000, 0, @User_Id
 	  	  	  	 --exec spEMEC_UpdateIsActive @ECId, 1, @User_Id
 	  	  	 end
 	 end
else
 	 begin
 	  	 select @ECId = EC_Id, @IsActive = Is_Active from event_configuration where ed_model_id = 49000 and pu_id = 0
 	  	 if @ECId is not NULL and @IsActive = 1
 	  	  	 exec spEMEC_UpdateIsActive @ECId, 0, @User_Id
 	 end
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
