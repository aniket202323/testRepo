CREATE PROCEDURE dbo.spEM_GetEventMapString
  @MU 	 Int,
  @EventStr  	 nvarchar(2000) Output,
  @EventSubtype nvarchar(max) Output, 
  @EventSubtypeDimensions nvarchar(2000) Output
  AS
DECLARE   @ETId 	  	 Int,
          @PreviousETId Int,
          @PreviousESId Int
DECLARE @SubType nVarChar(max)
DECLARE @ET Table (ET_Id Int,ES_ID Int Null, PEI_Id int Null)
DECLARE @ET2 Table (ET_Id Int,ES_ID Int Null, PEI_Id int Null)
IF @MU = -100
BEGIN
 	 SET @EventStr = ''
 	 Insert Into @ET (ET_ID,ES_ID,PEI_Id) Select DISTINCT ET_Id,Event_Subtype_Id, Null
 	  	 From  Event_configuration Where ET_Id is not null and ET_Id in ( 1,2,3,4,14)
END
ELSE
BEGIN
 	  	 SET @EventStr = 'Time,'
 	  	 Insert Into @ET (ET_ID,ES_ID,PEI_Id) Select ET_Id,Event_Subtype_Id, Null
 	  	   From  Event_configuration Where PU_Id = @MU and ET_Id is not null and ET_Id <> 0
 	  	 Insert Into @ET (ET_ID,ES_ID,PEI_Id)  Select Event_Type,Event_Subtype_Id,PEI_Id From  Variables Where PU_Id in (select pu_id from prod_units where  master_Unit = @MU or pu_Id = @MU )and Event_Type is not null and Event_Type <> 0
 	  	 If (Select count(*) from prdexec_inputs where PU_Id = @MU) > 0
 	  	  	 Insert into  @ET (ET_Id) Values (17)
END
Delete From @ET Where Et_Id in (Select Et_Id From Event_Types Where Variables_Assoc <> 1)
If (select count(*) from @ET Where ET_Id = 4) > 0
 	 Insert into  @ET (ET_Id) Values (5)
If (Select count(*) from prdexec_inputs where PU_Id = @MU) > 0
 	  	 Insert into  @ET (ET_Id) Values (17)
If (select count(*) from @ET Where ET_Id = 19) > 0
 	  	 Insert into  @ET (ET_Id) Values (28)
-- Add segment Response
 	 Insert Into @ET (ET_Id) Values (31)
-- Add Work Response
 	 Insert Into @ET (ET_Id) Values (32)
-- if we have downtime then we also have uptime
If (select count(*) from @ET Where ET_Id = 2) > 0
 	 Insert into  @ET (ET_Id) Values (22)
DECLARE ECS Cursor
     For Select Distinct ET_Id
 	 From @ET
    Open ECS
    ECSLoop:
    Fetch Next From ECS InTo @ETID
    If @@Fetch_Status = 0
      Begin
 	  	 Select @EventStr = @EventStr + ET_Desc + ',' From event_types Where ET_Id = @ETID
        If @ETID = 17
          Begin
            Insert Into @ET2 (ET_Id, ES_Id, PEI_Id) 
 	  	  	  	 Select 17, Event_Subtype_Id, PEI_Id From prdexec_inputs Where PU_Id = @MU
          End
 	 GoTo ECSLoop
      End
    Close ECS
    Deallocate ECS
    Insert Into @ET (ET_Id, ES_Id, PEI_Id) 
 	  	 Select ET_Id, ES_Id, PEI_Id   FROM @ET2
    Select @EventSubtype = ''
    DECLARE @ESId Int, @PEIId Int
    DECLARE EST Cursor
     For Select Distinct ET_Id,ES_Id,PEI_Id
 	 From @ET
 	 Where ES_Id is not null
 	 Order by ET_Id
    Open EST
    ESTLoop:
    Fetch Next From EST InTo @ETID,@ESId, @PEIId
    If @@Fetch_Status = 0
      Begin
        If @ETID = 17
          Begin
 	  	  	 SELECT @SubType = Char(3) +  Convert(nVarChar(10),@ETID) + Char(4) + Input_Name  From prdexec_inputs Where PEI_Id = @PEIId
 	  	  	 IF charindex(@SubType,@EventSubtype) = 0
            Select @EventSubtype = @EventSubtype +  @SubType
            GoTo ESTLoop
          End
        Else
          Begin
            Select @EventSubtype = @EventSubtype + Char(3) +  Convert(nVarChar(10),@ETID) + Char(4) + Event_Subtype_Desc  From event_subtypes Where Event_Subtype_Id = @ESID
            GoTo ESTLoop
          End
      End
    Close EST
    Deallocate EST
    Select @EventSubtypeDimensions = ''
    Select @PreviousETId = 0
    Select @PreviousESId = 0
    DECLARE ES Cursor
     For Select Distinct ES_Id, ET_Id
 	 From @ET
 	 Where ES_Id is not null
 	 Order by ES_Id, ET_Id
    Open ES
    ESLoop:
    Fetch Next From ES InTo @ESId, @ETId
    If @@Fetch_Status = 0
      Begin
        If @ESId = @PreviousESId and @ETId = @PreviousETId Goto ESLoop
        If @ETId = 1  --Production Event
          Begin
 	  	         Select @EventSubtypeDimensions = Coalesce(@EventSubtypeDimensions + Char(7) + Convert(nVarChar(10), @ETId) + Char(3) + '1' + Char(4) + Convert(nVarChar(10),@ESID) + Char(5) + Dimension_X_Name, '')  From event_subtypes Where Event_Subtype_Id = @ESID
 	  	         If (Select Dimension_Y_Enabled From Event_Subtypes Where Event_Subtype_Id = @ESID) = 1
 	  	             Begin
 	  	               Select @EventSubtypeDimensions = Coalesce(@EventSubtypeDimensions + Char(7) + Convert(nVarChar(10), @ETId) + Char(3) + '2' + Char(4) + Convert(nVarChar(10),@ESID) + Char(5) + Dimension_Y_Name, '')  From event_subtypes Where Event_Subtype_Id = @ESID
 	  	             End
 	  	         If (Select Dimension_Z_Enabled From Event_Subtypes Where Event_Subtype_Id = @ESID) = 1
 	  	             Begin
 	  	               Select @EventSubtypeDimensions = Coalesce(@EventSubtypeDimensions + Char(7) + Convert(nVarChar(10), @ETId) + Char(3) + '3' + Char(4) + Convert(nVarChar(10),@ESID) + Char(5) + Dimension_Z_Name, '')  From event_subtypes Where Event_Subtype_Id = @ESID
 	  	             End
 	  	         If (Select Dimension_A_Enabled From Event_Subtypes Where Event_Subtype_Id = @ESID) = 1
 	  	             Begin
 	  	               Select @EventSubtypeDimensions = Coalesce(@EventSubtypeDimensions + Char(7) + Convert(nVarChar(10), @ETId) + Char(3) + '4' + Char(4) + Convert(nVarChar(10),@ESID) + Char(5) + Dimension_A_Name, '')  From event_subtypes Where Event_Subtype_Id = @ESID
 	  	             End
 	  	         Select @EventSubtypeDimensions = Coalesce(@EventSubtypeDimensions + Char(7) + Convert(nVarChar(10), @ETId) + Char(3) + '5' + Char(4) + Convert(nVarChar(10),@ESID) + Char(5) + Dimension_X_Name, '')  From event_subtypes Where Event_Subtype_Id = @ESID
 	  	         If (Select Dimension_Y_Enabled From Event_Subtypes Where Event_Subtype_Id = @ESID) = 1
 	  	             Begin
 	  	               Select @EventSubtypeDimensions = Coalesce(@EventSubtypeDimensions + Char(7) + Convert(nVarChar(10), @ETId) + Char(3) + '6' + Char(4) + Convert(nVarChar(10),@ESID) + Char(5) + Dimension_Y_Name, '')  From event_subtypes Where Event_Subtype_Id = @ESID
 	  	             End
 	  	         If (Select Dimension_Z_Enabled From Event_Subtypes Where Event_Subtype_Id = @ESID) = 1
 	  	             Begin
 	  	               Select @EventSubtypeDimensions = Coalesce(@EventSubtypeDimensions + Char(7) + Convert(nVarChar(10), @ETId) + Char(3) + '7' + Char(4) + Convert(nVarChar(10),@ESID) + Char(5) + Dimension_Z_Name, '')  From event_subtypes Where Event_Subtype_Id = @ESID
 	  	             End
 	  	         If (Select Dimension_A_Enabled From Event_Subtypes Where Event_Subtype_Id = @ESID) = 1
 	  	             Begin
 	  	               Select @EventSubtypeDimensions = Coalesce(@EventSubtypeDimensions + Char(7) + Convert(nVarChar(10), @ETId) + Char(3) + '8' + Char(4) +  Convert(nVarChar(10),@ESID) + Char(5) + Dimension_A_Name, '')  From event_subtypes Where Event_Subtype_Id = @ESID
 	  	             End
          End
        Else
          If @ETId = 17 --Input Genealogy
            Begin
   	  	         Select @EventSubtypeDimensions = Coalesce(@EventSubtypeDimensions + Char(7) + Convert(nVarChar(10), @ETId) + Char(3) + '9' + Char(4) + Convert(nVarChar(10),@ESID) + Char(5) + Dimension_X_Name, '')  From event_subtypes Where Event_Subtype_Id = @ESID
 	  	         If (Select Dimension_Y_Enabled From Event_Subtypes Where Event_Subtype_Id = @ESID) = 1
 	  	             Begin
 	  	               Select @EventSubtypeDimensions = Coalesce(@EventSubtypeDimensions + Char(7) + Convert(nVarChar(10), @ETId) + Char(3) + '10' + Char(4) + Convert(nVarChar(10),@ESID) + Char(5) + Dimension_Y_Name, '')  From event_subtypes Where Event_Subtype_Id = @ESID
 	  	             End
 	  	         If (Select Dimension_Z_Enabled From Event_Subtypes Where Event_Subtype_Id = @ESID) = 1
 	  	             Begin
 	  	               Select @EventSubtypeDimensions = Coalesce(@EventSubtypeDimensions + Char(7) + Convert(nVarChar(10), @ETId) + Char(3) + '11' + Char(4) + Convert(nVarChar(10),@ESID) + Char(5) + Dimension_Z_Name, '')  From event_subtypes Where Event_Subtype_Id = @ESID
 	  	             End
 	  	         If (Select Dimension_A_Enabled From Event_Subtypes Where Event_Subtype_Id = @ESID) = 1
 	  	             Begin
 	  	               Select @EventSubtypeDimensions = Coalesce(@EventSubtypeDimensions + Char(7) + Convert(nVarChar(10), @ETId) + Char(3) + '12' + Char(4) + Convert(nVarChar(10),@ESID) + Char(5) + Dimension_A_Name, '')  From event_subtypes Where Event_Subtype_Id = @ESID
 	  	             End
                Select @EventSubtypeDimensions = Coalesce(@EventSubtypeDimensions + Char(7) + Convert(nVarChar(10), @ETId) + Char(3) + '13' + Char(4) + Convert(nVarChar(10),@ESID) + Char(5) + Dimension_X_Name, '')  From event_subtypes Where Event_Subtype_Id = @ESID
 	  	         If (Select Dimension_Y_Enabled From Event_Subtypes Where Event_Subtype_Id = @ESID) = 1
 	  	             Begin
 	  	               Select @EventSubtypeDimensions = Coalesce(@EventSubtypeDimensions + Char(7) + Convert(nVarChar(10), @ETId) + Char(3) + '14' + Char(4) + Convert(nVarChar(10),@ESID) + Char(5) + Dimension_Y_Name, '')  From event_subtypes Where Event_Subtype_Id = @ESID
 	  	             End
 	  	         If (Select Dimension_Z_Enabled From Event_Subtypes Where Event_Subtype_Id = @ESID) = 1
 	  	             Begin
 	  	               Select @EventSubtypeDimensions = Coalesce(@EventSubtypeDimensions + Char(7) + Convert(nVarChar(10), @ETId) + Char(3) + '15' + Char(4) + Convert(nVarChar(10),@ESID) + Char(5) + Dimension_Z_Name, '')  From event_subtypes Where Event_Subtype_Id = @ESID
 	  	             End
 	  	         If (Select Dimension_A_Enabled From Event_Subtypes Where Event_Subtype_Id = @ESID) = 1
 	  	             Begin
 	  	               Select @EventSubtypeDimensions = Coalesce(@EventSubtypeDimensions + Char(7) + Convert(nVarChar(10), @ETId) + Char(3) + '16' + Char(4) +  Convert(nVarChar(10),@ESID) + Char(5) + Dimension_A_Name, '')  From event_subtypes Where Event_Subtype_Id = @ESID
 	  	             End
            End
        Select @PreviousETId = @ETId
        Select @PreviousESId = @ESId
        GoTo ESLoop
      End
    Close ES
    Deallocate ES
