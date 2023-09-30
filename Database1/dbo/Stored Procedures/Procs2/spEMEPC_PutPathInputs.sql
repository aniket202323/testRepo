CREATE Procedure dbo.spEMEPC_PutPathInputs
@Path_Id int,
@PEI_Id int,
@Event_Subtype_Id int,
@Primary_Spec_Id int,
@Alternate_Spec_Id int,
@Lock_Inprogress_Input bit,
@Hide_Input bit,
@Allow_Manual_Movement bit,
@User_Id int,
@PEPI_Id int = NULL OUTPUT
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMEPC_PutPathInputs',
             Convert(nVarChar(10),@Path_Id) + ','  + 
             Convert(nvarchar(50),@PEI_Id) + ','  + 
             Convert(nvarchar(50),@Event_Subtype_Id) + ','  + 
             Convert(nVarChar(10),@Primary_Spec_Id) + ','  + 
             Convert(nVarChar(10),@Alternate_Spec_Id) + ','  + 
             Convert(nVarChar(10),@Lock_Inprogress_Input) + ','  + 
             Convert(nVarChar(10),@Hide_Input) + ','  + 
             Convert(nVarChar(10),@Allow_Manual_Movement) + ','  + 
             Convert(nVarChar(10),@User_Id) + ','  + 
             Convert(nVarChar(10),@PEPI_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
If @PEPI_Id is NULL
  Begin
    Insert Into PrdExec_Path_Inputs (Path_Id, PEI_Id, Event_Subtype_Id, Primary_Spec_Id, Alternate_Spec_Id, Lock_Inprogress_Input, Hide_Input, Allow_Manual_Movement)
      Values (@Path_Id, @PEI_Id, @Event_Subtype_Id, @Primary_Spec_Id, @Alternate_Spec_Id, @Lock_Inprogress_Input, @Hide_Input, @Allow_Manual_Movement)
    Select @PEPI_Id = Scope_Identity()
  End
Else If @PEPI_Id is NOT NULL and @Path_Id is NOT NULL
  Begin
    Update PrdExec_Path_Inputs
      Set Event_Subtype_Id = @Event_Subtype_Id, Primary_Spec_Id = @Primary_Spec_Id, Alternate_Spec_Id = @Alternate_Spec_Id, 
        Lock_Inprogress_Input = @Lock_Inprogress_Input, Hide_Input = @Hide_Input, Allow_Manual_Movement = @Allow_Manual_Movement
      Where PEPI_Id = @PEPI_Id
  End
Else If @PEPI_Id is NOT NULL and @Path_Id is NULL
  Begin
    Delete From PrdExec_Path_Inputs
      Where PEPI_Id = @PEPI_Id
  End
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
