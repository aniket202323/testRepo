/*
Declare @ECId int,@CommentId Int
execute spEMEC_CreateNewEC 32,0,'On Event Updates with Configured Status, Generates Waste',3,Null,1,@ECId Output,@CommentId output
select @ECId,@CommentId
*/
Create Procedure dbo.spEMEC_CreateNewEC
@PU_Id int,
@Is_Active tinyint,
@Desc nvarchar(50),
@ET_Id int,
@Event_Subtype_Id int = NULL,
@User_Id int,
@EC_Id int OUTPUT,
@CommentId 	 Int = Null Output
AS
Declare 	 @Id  	  	 int,
 	 @Insert_Id 	 int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMEC_CreateNewEC',
             Convert(nVarChar(10),@PU_Id) + ','  + 
             Convert(nVarChar(10),@Is_Active) + ','  + 
 	 @Desc + ',' +
             Convert(nVarChar(10),@ET_Id) + ','  + 
 	 Convert(nVarChar(10),@Event_Subtype_Id) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
if @ET_Id = 19 and (Select Count(*) From Event_Configuration Where PU_Id = @PU_Id and ET_Id = @ET_Id) > 0
 	 return
if @Desc = ''
  select @Desc = Null
/* Added 12/19/2000 */
Insert Into Comments (Comment,User_Id,Modified_On,CS_Id,ShouldDelete,Comment_Text) Values ('',@User_Id,dbo.fnServer_CmnGetDate(getUTCdate()),3,0,'')
  Select @CommentId = Scope_Identity()
if @Event_Subtype_Id is Null
  Begin
--    insert into event_configuration(PU_Id, ED_Model_Id, Is_Active, EC_Desc) Values (@PU_Id, @ED_Model_Id, @Is_Active, @Desc)
    insert into event_configuration(PU_Id, Is_Active, EC_Desc, ET_Id,Comment_Id) Values (@PU_Id, @Is_Active, @Desc, @ET_Id,@CommentId)
    select @EC_Id = Scope_Identity()
  End
else
  Begin
--    insert into event_configuration(PU_Id, ED_Model_Id, Is_Active, EC_Desc, Event_Subtype_Id) Values (@PU_Id, @ED_Model_Id, @Is_Active, @Desc, @Event_Subtype_Id)
    insert into event_configuration(PU_Id, Is_Active, EC_Desc, Event_Subtype_Id, ET_Id,Comment_Id) Values (@PU_Id, @Is_Active, @Desc, @Event_Subtype_Id, @ET_Id,@CommentId)
    select @EC_Id = Scope_Identity()
  End
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
