CREATE Procedure dbo.spEMEPC_CreateNewEC
@PU_Id int,
@Is_Active tinyint,
@Desc nvarchar(50),
@ET_Id int,
@Event_Subtype_Id int = NULL,
@User_Id int,
@PEI_Id int = NULL,
@EC_Id int OUTPUT
AS
Declare 	 @Id  	  	 int,
 	 @Insert_Id 	 int,
   	 @CommentId  	 Int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMEPC_CreateNewEC',
             Convert(nVarChar(10),@PU_Id) + ','  + 
             Convert(nVarChar(10),@Is_Active) + ','  + 
 	 @Desc + ',' +
             Convert(nVarChar(10),@ET_Id) + ','  + 
 	 Convert(nVarChar(10),@Event_Subtype_Id) + ','  + 
 	 Convert(nVarChar(10),@User_Id) + ','  + 
             Convert(nVarChar(10),@PEI_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
if @Desc = ''
  select @Desc = Null
/* Added 12/19/2000 */
Insert Into Comments (Comment,User_Id,Modified_On,CS_Id,ShouldDelete,Comment_Text) Values ('',@User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,0,'')
  Select @CommentId = Scope_Identity()
/*
@ED_Model_Id int
set rowcount 1
select @ED_Model_Id = ed_model_id
from ed_models
where et_id = @ET_Id
set rowcount 0
*/
if @Event_Subtype_Id is Null
  Begin
--    insert into event_configuration(PU_Id, ED_Model_Id, Is_Active, EC_Desc) Values (@PU_Id, @ED_Model_Id, @Is_Active, @Desc)
    insert into event_configuration(PU_Id, Is_Active, EC_Desc, ET_Id,Comment_Id, PEI_Id) Values (@PU_Id, @Is_Active, @Desc, @ET_Id,@CommentId, @PEI_Id)
    select @EC_Id = Scope_Identity()
  End
else
  Begin
--    insert into event_configuration(PU_Id, ED_Model_Id, Is_Active, EC_Desc, Event_Subtype_Id) Values (@PU_Id, @ED_Model_Id, @Is_Active, @Desc, @Event_Subtype_Id)
    insert into event_configuration(PU_Id, Is_Active, EC_Desc, Event_Subtype_Id, ET_Id,Comment_Id, PEI_Id) Values (@PU_Id, @Is_Active, @Desc, @Event_Subtype_Id, @ET_Id,@CommentId, @PEI_Id)
    select @EC_Id = Scope_Identity()
  End
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
/*
Declare @ED_Field_Id int, 
  @ED_FieldType_Id int, 
  @Init varchar(8000), 
  @ECV_Id int
--     Don't add rows for script types.
Declare EDCursor INSENSITIVE CURSOR
  For (Select ED_Field_Id, ED_Field_Type_Id from ED_Fields where ED_Model_Id = @ED_Model_Id and ED_Field_Type_Id not in(17, 18, 19,20))
  For Read Only
  Open EDCursor  
EDLoop:
  Fetch Next From EDCursor Into @ED_Field_Id, @ED_FieldType_Id 
  If (@@Fetch_Status = 0)
    Begin
      insert into event_configuration_values(value) values (NULL) 
 	  select @ECV_Id = IDENT_CURRENT('event_configuration_values')
      insert into event_configuration_data (EC_Id, ED_Field_Id, ECV_Id) Values (@EC_Id, @ED_Field_Id,  @ECV_Id)
      Goto EDLoop
    End
Close EDCursor
Deallocate EDCursor
*/
--exec spEMEC_UpdateIsActive @EC_Id, 0
