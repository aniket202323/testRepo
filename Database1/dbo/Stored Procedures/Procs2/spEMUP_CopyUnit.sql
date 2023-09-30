CREATE Procedure dbo.spEMUP_CopyUnit
@Action tinyint,
@FromPUId int,
@ToPUId int,
@User_Id int
AS
Declare @Insert_Id int
INSERT Into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMUP_CopyUnit',
             Convert(nVarChar(10),@Action) + ','  + 
             Convert(nVarChar(10),@FromPUId) + ','  + 
             Convert(nVarChar(10),@ToPUId) + ','  + 
             Convert(nVarChar(10),@User_Id), dbo.fnServer_CmnGetDate(getUTCdate()))
Select @Insert_Id = Scope_Identity()
Declare @ListType int, @id1 int, @id2 int,  @id3 int, @id4 int, @name1 nvarchar(50), @id5 int, @id6 int
Declare @Valid_Status int
Declare @Found Int
DECLARE @DefaultStatus Int
if @FromPUId = @ToPUId
  return
if @Action = 0  --Copy Production Statuses/Transitions
BEGIN    
    declare @From_ProdStatus_Id int, @To_ProdStatus_Id int
--PRODUCTION STATUSES
    --COPY From UNIT (Production Statuses)
    Declare PEXPFrom Cursor For 
      Select Valid_Status From PrdExec_Status Where PU_Id = @FromPUId For Read Only
    Open PEXPFrom
    While (0=0)
    Begin    
      Fetch Next  From PEXPFrom  Into @Valid_Status
      If (@@Fetch_Status <> 0) Break
 	    Select @Found = 1
 	    If  @Valid_Status Is Null
 	     	 Select  @Found = Count(*) From PrdExec_Status Where PU_Id = @ToPUId and Valid_Status  is null
 	    Else
 	     	 Select  @Found = Count(*) From PrdExec_Status Where PU_Id = @ToPUId and Valid_Status = @Valid_Status
        If  @Found = 0
          Begin
            --zHandleProdStatusCheck(Checked)
            Select @ListType = 20, @id1 = @ToPUId, @id2 = 0, @id3 = @Valid_Status, @id4 = 0, @name1 = '' 
            exec spEMEPC_ExecPathConfig_TableMod  @ListType, @id1, @id2, @id3, @id4, @name1, @User_Id
          End
    End
    Close PEXPFrom
    Deallocate PEXPFrom
/* Set Default*/
 	 SELECT @DefaultStatus = Valid_Status FROM PrdExec_Status Where PU_Id = @FromPUId and Is_Default_Status = 1
 	 IF @DefaultStatus Is Not Null
 	  	 EXECUTE spEMEPC_ExecPathConfig_TableMod 23,@ToPUId,@DefaultStatus, 0,0,'',@User_Id
    --COPY TO UNIT (Production Statuses)
    Declare PEXPTo Cursor For 
      Select Valid_Status From PrdExec_Status Where PU_Id = @ToPUId For Read Only
    Open PEXPTo
    While (0=0) Begin        
    Fetch Next 
      From PEXPTo 
      Into @Valid_Status
      If (@@Fetch_Status <> 0) Break
 	    Select @Found = 1
 	    If  @Valid_Status Is Null
 	     	 Select  @Found = Count(*) From PrdExec_Status Where PU_Id = @FromPUId and Valid_Status Is null
 	    Else
 	     	 Select  @Found = Count(*) From PrdExec_Status Where PU_Id = @FromPUId and Valid_Status = @Valid_Status
        If  @Found = 0
          Begin
            --zHandleProdStatusCheck(UnChecked)
            Select @ListType = 21, @id1 = @ToPUId, @id2 = @Valid_Status, @id3 = 0, @id4 = 0, @name1 = '', @id5 = 0
            exec spEMEPC_ExecPathConfig_PathUpdate @ListType, @id1, @id2, @id3, @id4, @name1, @id5, @User_Id
          End
    End
    Close PEXPTo
    Deallocate PEXPTo
--PRODUCTION TRANSITIONS
    --COPY From UNIT (Production Transitions)
    Declare PEXTFrom Cursor For 
      Select From_ProdStatus_Id, To_ProdStatus_Id From PrdExec_Trans Where PU_Id = @FromPUId For Read Only
    Open PEXTFrom
    While (0=0) Begin        
    Fetch Next 
      From PEXTFrom 
      Into @From_ProdStatus_Id, @To_ProdStatus_Id
      If (@@Fetch_Status <> 0) Break
        If (Select Count(*) From PrdExec_Trans Where PU_Id = @ToPUId and From_ProdStatus_Id = @From_ProdStatus_Id and To_ProdStatus_Id = @To_ProdStatus_Id) = 0
          Begin
            --zHandleTransAdd
            Select @ListType = 25, @id1 = @ToPUId, @id2 = @From_ProdStatus_Id, @id3 = @To_ProdStatus_Id, @id4 = 0, @name1 = '' 
            exec spEMEPC_ExecPathConfig_TableMod @ListType, @id1, @id2, @id3, @id4, @name1, @User_Id
          End
    End
    Close PEXTFrom
    Deallocate PEXTFrom
    --COPY TO UNIT (Production Transitions)
    Declare PEXTTo Cursor For
      Select From_ProdStatus_Id, To_ProdStatus_Id From PrdExec_Trans Where PU_Id = @ToPUId For Read Only
    Open PEXTTo
    While (0=0) Begin        
    Fetch Next 
      From PEXTTo 
      Into @From_ProdStatus_Id, @To_ProdStatus_Id
      If (@@Fetch_Status <> 0) Break
        If (Select Count(*) From PrdExec_Trans Where PU_Id = @FromPUId and From_ProdStatus_Id = @From_ProdStatus_Id and To_ProdStatus_Id = @To_ProdStatus_Id) = 0
          Begin
            --zHandleTransRemove
            Select @ListType = 26, @id1 = @ToPUId, @id2 = @From_ProdStatus_Id, @id3 = @To_ProdStatus_Id, @id4 = 0, @name1 = '' 
            exec spEMEPC_ExecPathConfig_TableMod @ListType, @id1, @id2, @id3, @id4, @name1, @User_Id
          End
    End
    Close PEXTTo
    Deallocate PEXTTo
END
else if @Action = 1  --Copy Raw Material Inputs, Input Sources, Input Statuses, and Input Models
  begin
    declare @PEIS_Id int, @PU_Id int, @NewPEI_Id int, @NewPEIS_Id int
    declare @PEI_Id int, @EC_Id int, @NewEC_Id int, @NewED_Model_Id int
    --REMOVE ALL From UNIT (RAW MATERIAL INPUTS, INPUT SOURCES, INPUT STATUSES, AND INPUT MODELS)
    Declare PEXIFrom Cursor For
      Select PEI_Id From PrdExec_Inputs Where PU_Id = @ToPUId For Read Only
    Open PEXIFrom
    While (0=0) Begin        
    Fetch Next 
      From PEXIFrom 
      Into @PEI_Id
      If (@@Fetch_Status <> 0) Break
        If @PEI_Id > 0
          Begin
            exec spEMEPC_ExecPathConfig_PathUpdate 41, @PEI_Id, 0, 0, 0, '', 0, @User_Id
          End
    End
    Close PEXIFrom
    Deallocate PEXIFrom
    --COPY RAW MATERIAL INPUTS, INPUT SOURCES, INPUT STATUSES, AND INPUT MODELS
    Declare PEXITo Cursor For
      Select PEI_Id From PrdExec_Inputs Where PU_Id = @FromPUId For Read Only
    Open PEXITo
    While (0=0) Begin        
    Fetch Next   From PEXITo    Into @PEI_Id
      If (@@Fetch_Status <> 0) Break
        If @PEI_Id > 0
          Begin
            --zInputCreateNew
            Select @id1 = Max(Input_Order) + 1 From PrdExec_Inputs Where PU_Id = @ToPUId
 	     Select @id1 = isnull(@id1,1)
            Select @id3 = Event_Subtype_Id, @id4 = Coalesce(Primary_Spec_Id, 0), @name1 = Input_Name, @id5 = Coalesce(Alternate_Spec_Id, 0), @id6 = Lock_Inprogress_Input From PrdExec_Inputs Where PEI_Id = @PEI_Id
            exec spEMEPC_ExecPathConfig_PathUpdate 40, @id1, @ToPUId, @id3, @id4, @name1, @id5, @User_Id, @id6
            Select @NewPEI_Id = PEI_Id From PrdExec_Inputs Where PU_Id = @ToPUId and Input_Name = @name1
 	  	   
            Declare PEXISFrom Cursor For
              Select PEIS_Id, PU_Id From PrdExec_Input_Sources Where PEI_Id = @PEI_Id For Read Only
            Open PEXISFrom
            While (0=0) Begin        
            Fetch Next 
              From PEXISFrom 
              Into @PEIS_Id, @PU_Id
              If (@@Fetch_Status <> 0) Break
                If @PEIS_Id > 0
                  Begin
                    --zHandleSourceUnitAdd
                    exec spEMEPC_ExecPathConfig_TableMod 45, @PU_Id, @NewPEI_Id, 0, 0, '', @User_Id
                    Select @NewPEIS_Id = PEIS_Id From prdexec_input_sources Where PU_Id = @PU_Id and PEI_Id = @NewPEI_Id
                    Declare PEXISDFrom Cursor For
                      Select Valid_Status From PrdExec_Input_Source_Data Where PEIS_Id = @PEIS_Id For Read Only
                    Open PEXISDFrom
                    While (0=0) Begin        
                    Fetch Next 
                      From PEXISDFrom 
                      Into @Valid_Status
                      If (@@Fetch_Status <> 0) Break
                        If @Valid_Status > 0
                          Begin
                            --zHandleSrcUnitStatusAdd
                            Select @ListType = 47, @id1 = @NewPEIS_Id, @id2 = @Valid_Status, @id3 = 0, @id4 = 0, @name1 = ''
                            exec spEMEPC_ExecPathConfig_TableMod @ListType, @id1, @id2, @id3, @id4, @name1, @User_Id
                          End
                    End
                    Close PEXISDFrom
                    Deallocate PEXISDFrom
                  End
            End
            Close PEXISFrom
            Deallocate PEXISFrom
            --ModelClick - Movement Model
            Select @EC_Id = NULL, @NewEC_Id = NULL
            Select @EC_Id = EC_Id From Event_Configuration Where PEI_Id = @PEI_Id and ET_Id = 16
            If @EC_Id is NOT NULL
              exec spEMPU_CopyEC @ToPUId, @EC_Id, @NewPEI_Id, @User_Id, @NewEC_Id OUTPUT, @NewED_Model_Id OUTPUT
            --ModelClick - Consumption Model
            Select @EC_Id = NULL, @NewEC_Id = NULL
            Select @EC_Id = EC_Id From Event_Configuration Where PEI_Id = @PEI_Id and ET_Id = 18
            If @EC_Id is NOT NULL
              exec spEMPU_CopyEC @ToPUId, @EC_Id, @NewPEI_Id, @User_Id, @NewEC_Id OUTPUT, @NewED_Model_Id OUTPUT
            --ModelClick - Genealogy Model
            Select @EC_Id = NULL, @NewEC_Id = NULL
            Select @EC_Id = EC_Id From Event_Configuration Where PEI_Id = @PEI_Id and ET_Id = 17
            If @EC_Id is NOT NULL
              exec spEMPU_CopyEC @ToPUId, @EC_Id, @NewPEI_Id, @User_Id, @NewEC_Id OUTPUT, @NewED_Model_Id OUTPUT
          End
    End
    Close PEXITo
    Deallocate PEXITo
  end
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
Where Audit_Trail_Id = @Insert_Id
