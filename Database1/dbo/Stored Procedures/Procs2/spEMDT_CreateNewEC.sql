Create Procedure dbo.spEMDT_CreateNewEC
@PU_Id int,
@ED_Model_Id int,
@Is_Active tinyint,
@Desc nvarchar(50),
@User_Id int,
@EC_Id int OUTPUT
AS
declare @Id int, @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMDT_CreateNewEC',
             Convert(nVarChar(10),@PU_Id) + ','  + 
             Convert(nVarChar(10),@ED_Model_Id) + ','  + 
             Convert(nVarChar(10),@Is_Active) + ','  + 
 	 @Desc + ',' +
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
--exec spEMDT_CheckECRow @PU_Id, @EC_Id OUTPUT, @Id OUTPUT
--update event_configuration set is_active = 0
--where ec_id = @EC_Id
insert into event_configuration(PU_Id, ED_Model_Id, Is_Active, EC_Desc, ET_Id) Values (@PU_Id, @ED_Model_Id, @Is_Active, @Desc, 2)
select @EC_Id = Scope_Identity()
Declare @ED_Field_Id int, 
  @ED_FieldType_Id int, 
  @Init varchar(8000), 
  @ECV_Id int
-- Don't add rows for script types.
Declare EDCursor INSENSITIVE CURSOR
  For (Select ED_Field_Id, ED_Field_Type_Id from ED_Fields where ED_Model_Id = @ED_Model_Id and ED_Field_Type_Id not in(17, 18, 19,20))
  For Read Only
  Open EDCursor  
EDLoop:
  Fetch Next From EDCursor Into @ED_Field_Id, @ED_FieldType_Id 
  If (@@Fetch_Status = 0)
    Begin
--       IF @ED_Field_Id  < 18 
--         BEGIN
           insert into event_configuration_values(value) values (NULL) 
       	  select @ECV_Id = IDENT_CURRENT('event_configuration_values')
--           If @Ed_FieldType_Id = 17  --Running Script
--            BEGIN
--             Select @init = '''Enter your running script here. 
--''You must have the statement(s) Running = True and/or Running = False'
--             Update event_configuration_values set value = @init where ECV_Id = @ECV_Id
--            END
--         END 
       insert into event_configuration_data (EC_Id, ED_Field_Id, ECV_Id) Values (@EC_Id, @ED_Field_Id,  @ECV_Id)
      Goto EDLoop
    End
Close EDCursor
Deallocate EDCursor
--exec spEMEC_UpdateIsActive @EC_Id, 0
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
