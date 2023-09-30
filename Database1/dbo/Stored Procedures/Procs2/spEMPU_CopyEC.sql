Create Procedure dbo.spEMPU_CopyEC
@PU_Id int,
@EC_Id int,
@PEI_Id int,
@User_Id int,
@NewEC_Id int OUTPUT,
@NewED_Model_Id int OUTPUT
AS
declare @Id int, @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMPU_CopyEC',
             Convert(nVarChar(10),@PU_Id) + ','  + 
             Convert(nVarChar(10),@EC_Id) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
Declare @ED_Model_Id int,
@ET_Id tinyint,
@Is_Active bit,
@Desc nvarchar(50),
@Ed_Field_Type_Id int,
@Alias nvarchar(50),
@ECV_Id int,
@NewECV_Id int,
@ED_Attribute_Id int,
@Sampling_Offset int,
@ST_Id tinyint,
@IsTrigger tinyint,
@SourcePtrVal varbinary(16),
@DestPtrVal varbinary(16),
@SourcePtrValValid int,
@Source_PUId int,
@Dest_PUId int,
@SourceComment_Id int,
@DestComment_Id int,
@SourcePtrComment varbinary(16),
@DestPtrComment varbinary(16),
@SourcePtrCommentValid int,
@SourcePtrCommentText varbinary(16),
@DestPtrCommentText varbinary(16),
@SourcePtrCommentTextValid int,
@EDFieldId int
create table #SourceLocations(
  SLId int IDENTITY(1, 1),
  PU_Id int,
  PU_Order int
)
create table #DestLocations(
  DLId int IDENTITY(1, 1),
  PU_Id int,
  PU_Order int
)
select @Source_PUId = pu_id
  from event_configuration
  where ec_id = @EC_Id
insert into #SourceLocations
  select pu_id, pu_order
    from prod_units
    where pu_id = @Source_PUId   or master_unit = @Source_PUId
    order by pu_order
insert into #DestLocations
  select pu_id, pu_order
    from prod_units
    where pu_id = @PU_Id  or master_unit = @PU_Id
    order by pu_order
select @ED_Model_Id = ed_model_id, @Is_Active = 0, @Desc = ec_desc, @SourceComment_Id = comment_id, @ET_Id = ET_Id
  from event_configuration
  where ec_id = @EC_Id
insert into event_configuration(PU_Id, ED_Model_Id, Is_Active, EC_Desc, ET_Id, PEI_Id) Values (@PU_Id, @ED_Model_Id, @Is_Active, @Desc, @ET_Id, @PEI_Id)
  select @NewEC_Id = Scope_Identity()
select @NewED_Model_Id = ed_model_id
  from event_configuration
  where ec_id = @NewEC_Id
if @SourceComment_Id > 0
  Begin
    insert into comments(Comment, Comment_Text, CS_Id, Modified_On, User_Id) values ('', '', 2, dbo.fnServer_CmnGetDate(getUTCdate()), @User_Id)
    select @DestComment_Id = Scope_Identity()
    update event_configuration set comment_id = @DestComment_Id where ec_id = @NewEC_Id
    select @SourcePtrComment = TEXTPTR(comment) from comments where comment_id = @SourceComment_Id
    select @SourcePtrCommentValid = TEXTVALID ('comments.comment', @SourcePtrComment)
    if @SourcePtrCommentValid = 1
      Begin
        select @DestPtrComment = TEXTPTR(comment) from comments where comment_id = @DestComment_Id
        UPDATETEXT comments.comment @DestPtrComment 0 0 WITH LOG comments.comment @SourcePtrComment
      End
    select @SourcePtrCommentText = TEXTPTR(comment_text) from comments where comment_id = @SourceComment_Id
    select @SourcePtrCommentTextValid = TEXTVALID ('comments.comment_text', @SourcePtrCommentText)
    if @SourcePtrCommentTextValid = 1
      Begin
        select @DestPtrCommentText = TEXTPTR(comment_text) from comments where comment_id = @DestComment_Id
        UPDATETEXT comments.comment_text @DestPtrCommentText 0 0 WITH LOG comments.comment_text @SourcePtrCommentText
      End
  End
Declare ECDataCursor INSENSITIVE CURSOR
 For select d.pu_id, t.ed_field_type_id, d.alias, d.ecv_id, d.ed_attribute_id, d.sampling_offset, d.st_id, d.istrigger 
    from event_configuration_data d
    join ed_fields f on f.ed_field_id = d.ed_field_id
    join ed_fieldtypes t on t.ed_field_type_id = f.ed_field_type_id
    where d.ec_id = @EC_Id
    order by d.ecv_id
  For Read Only
  Open ECDataCursor  
ECDataLoop:
  Fetch Next From ECDataCursor Into @Source_PUId, @Ed_Field_Type_Id, @Alias, @ECV_Id, @ED_Attribute_Id, @Sampling_Offset, @ST_Id, @IsTrigger
  If (@@Fetch_Status = 0)
    Begin
      select @Dest_PUId = NULL
      select @Dest_PUId = d.PU_Id
       from #DestLocations d
        join #SourceLocations s on s.SLId = d.DLId
        where s.PU_Id = @Source_PUId
      if @Dest_PUId > 0 or @Dest_PUId is NULL
        Begin
          Select @EDFieldId = ED_Field_Id 
            From ED_Fields f
            JOIN Event_Configuration c on c.ED_Model_Id = f.ED_Model_Id and c.EC_id = @EC_Id
            Where  f.ED_Field_Type_Id = @Ed_Field_Type_Id
          SELECT @NewECV_Id = NULL 
          Insert into Event_Configuration_Values (Value) Values('')
 	   	 select @NewECV_Id = IDENT_CURRENT('event_configuration_values')
          Insert into Event_Configuration_Data (EC_Id, ED_Field_Id, Alias, PU_Id, ECV_Id)
            values (@NewEC_Id, @EDFieldId, @Alias, @Dest_PUId, @NewECV_Id)
          update event_configuration_data set ED_Attribute_Id = @ED_Attribute_Id, Sampling_Offset = @Sampling_Offset, ST_Id = @ST_Id, IsTrigger = @IsTrigger
            where ecv_id = @NewECV_Id
          select @SourcePtrVal = TEXTPTR(value) from event_configuration_values where ecv_id = @ECV_Id
          select @SourcePtrValValid = TEXTVALID('event_configuration_values.value', @SourcePtrVal)
          if @SourcePtrValValid = 1
            Begin
              select @DestPtrVal = TEXTPTR(value) from event_configuration_values where ecv_id = @NewECV_Id
              UPDATETEXT event_configuration_values.value @DestPtrVal 0 0 WITH LOG event_configuration_values.value @SourcePtrVal
            End
        End
      Goto ECDataLoop
    End
Close ECDataCursor
Deallocate ECDataCursor
/* User Defined Properties */
INSERT INTO Event_Configuration_Properties (EC_Id,ED_Field_Prop_Id,Value) 
 	 SELECT @NewEC_Id,ED_Field_Prop_Id,Value 
 	  	 FROM Event_Configuration_Properties
 	  	 WHERE EC_Id = @EC_Id
drop table #SourceLocations
drop table #DestLocations
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
