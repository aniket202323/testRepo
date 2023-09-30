CREATE Procedure dbo.spEMEPC_CopyExecPath
@Path_Id int,
@User_Id int,
@New_Path_Id int OUTPUT
AS
Declare @Insert_Id int
INSERT Into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMEPC_CopyExecPath',
             Convert(nVarChar(10),@Path_Id) + ','  + 
             Convert(nVarChar(10),@User_Id) + ','  + 
             Convert(nVarChar(10),@New_Path_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
Select @Insert_Id = Scope_Identity()
Declare
@SourceComment_Id int,
@DestComment_Id int,
@SourcePtrComment varbinary(16),
@DestPtrComment varbinary(16),
@SourcePtrCommentValid int,
@SourcePtrCommentText varbinary(16),
@DestPtrCommentText varbinary(16),
@SourcePtrCommentTextValid int
Insert Into Prdexec_Paths (PL_Id, Path_Desc, Path_Code, Is_Schedule_Controlled, Schedule_Control_Type, Is_Line_Production, Create_Children)
  Select * from (Select PL_Id, '(' + Path_Desc + ')' Path_Desc, '(' + Path_Code + ')' Path_Code, Is_Schedule_Controlled, Schedule_Control_Type, Is_Line_Production, Create_Children
    From Prdexec_Paths
    Where Path_Id = @Path_Id) T
Select @New_Path_Id = Scope_Identity()
Select @SourceComment_Id = comment_id
  From Prdexec_Paths
  Where Path_Id = @Path_Id
if @SourceComment_Id > 0
  Begin
    insert into comments(Comment, Comment_Text, CS_Id, Modified_On, User_Id, Entry_On) values ('', '', 2, dbo.fnServer_CmnGetDate(getUTCdate()), @User_Id, dbo.fnServer_CmnGetDate(getUTCdate()))
    update comments set TopOfChain_Id = Scope_Identity() where comment_id = Scope_Identity()
    select @DestComment_Id = Scope_Identity()
    update Prdexec_Paths set comment_id = @DestComment_Id Where Path_Id = @New_Path_Id
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
Insert Into PrdExec_Path_Units (PU_Id, Path_Id, Is_Schedule_Point, Is_Production_Point, Unit_Order)
  Select PU_Id, @New_Path_Id, Is_Schedule_Point, Is_Production_Point, Unit_Order
    From PrdExec_Path_Units
    Where Path_Id = @Path_Id
Insert Into PrdExec_Path_Products (Path_Id, Prod_Id)
  Select @New_Path_Id, Prod_Id
    From PrdExec_Path_Products
    Where Path_Id = @Path_Id
Insert Into PrdExec_Path_Inputs (Path_Id, PEI_Id, Event_Subtype_Id, Primary_Spec_Id, Alternate_Spec_Id, Lock_Inprogress_Input, Hide_Input, Allow_Manual_Movement)
  Select @New_Path_Id, PEI_Id, Event_Subtype_Id, Primary_Spec_Id, Alternate_Spec_Id, Lock_Inprogress_Input, Hide_Input, Allow_Manual_Movement
    From PrdExec_Path_Inputs
    Where Path_Id = @Path_Id
Insert Into PrdExec_Path_Input_Sources (Path_Id, PEI_Id, PU_Id)
  Select @New_Path_Id, PEI_Id, PU_Id
    From PrdExec_Path_Input_Sources
    Where Path_Id = @Path_Id
Insert Into PrdExec_Path_Input_Source_Data (PEPIS_Id, Valid_Status)
  Select Distinct ppis_to.PEPIS_Id, ppisd_from.Valid_Status
    From PrdExec_Path_Input_Source_Data ppisd_from
    Join PrdExec_Path_Input_Sources ppis_from on ppis_from.PEPIS_Id = ppisd_from.PEPIS_Id
    Join PrdExec_Path_Input_Sources ppis_to on ppis_to.pei_id = ppis_from.pei_id and ppis_to.path_id = @New_Path_Id and ppis_to.pu_id = ppis_from.pu_id
    Where ppisd_from.PEPIS_Id in (Select PEPIS_Id From PrdExec_Path_Input_Sources Where Path_Id = @Path_Id)
Insert Into Production_Plan_Status (To_PPStatus_Id, From_PPStatus_Id, Path_Id)
  Select To_PPStatus_Id, From_PPStatus_Id, @New_Path_Id
    From Production_Plan_Status
    Where Path_Id = @Path_Id
Insert Into PrdExec_Path_Status_Detail (Path_Id, PP_Status_Id, How_Many, AutoPromoteFrom_PPStatusId, AutoPromoteTo_PPStatusId, Sort_Order)
  Select @New_Path_Id, PP_Status_Id, How_Many, AutoPromoteFrom_PPStatusId, AutoPromoteTo_PPStatusId, Sort_Order
    From PrdExec_Path_Status_Detail
    Where Path_Id = @Path_Id
Insert Into PrdExec_Path_Alarms (Path_Id, PEPAT_Id, Threshold_Type_Selection, Threshold_Value)
  Select @New_Path_Id, PEPAT_Id, Threshold_Type_Selection, Threshold_Value
    From PrdExec_Path_Alarms    
    Where Path_Id = @Path_Id
Insert Into Table_Fields_Values (KeyId, TableId, Table_Field_Id, Value)
  Select @New_Path_Id, TableId, Table_Field_Id, Value
    From Table_Fields_Values
    Where KeyId = @Path_Id and TableId = 13
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
Where Audit_Trail_Id = @Insert_Id
