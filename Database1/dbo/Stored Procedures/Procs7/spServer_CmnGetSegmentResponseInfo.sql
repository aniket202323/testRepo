CREATE PROCEDURE [dbo].[spServer_CmnGetSegmentResponseInfo]
@SRId int,
@Found int OUTPUT,
@MasterPUId int OUTPUT,
@EventKeys nVarChar(1000) OUTPUT,
@StartTime datetime OUTPUT,
@EndTime datetime OUTPUT,
@ErrorMsg nvarchar(200) OUTPUT
AS
Declare
  @S95Guid uniqueidentifier,
  @EquipmentId uniqueidentifier,
  @PUId int,
  @MaterialDefId uniqueidentifier,
  @ProdId int
Select @EventKeys = NULL
Select @Found = 0
Select @ErrorMsg = ''
Select @PUId = NULL
Select @StartTime = NULL
Select @EndTime = NULL
Select @EquipmentId = NULL
Select @S95Guid = NULL
Select @S95Guid = S95_Guid From S95_Event Where (Event_Id = @SRId) And (Event_Type = 31)
If (@S95Guid Is Null)
  Begin
    Select @ErrorMsg = 'S95_Event Not Found for Event_Id (' + Convert(nVarChar(20),@SRId) + ')'
    return
  End
 Select @EquipmentId = EquipmentId,
 	  	 @StartTime = dbo.fnServer_CmnConvertToDbTime(StartTime,'UTC'),
 	  	 @EndTime = dbo.fnServer_CmnConvertToDbTime(EndTime,'UTC')
 	 From SegmentResponse
 	 Where (SegmentResponseId = @S95Guid)
If (@EquipmentId Is Null)
  Begin
    Select @ErrorMsg = 'SegmentResponse Not Found for S95 Event_Id (' + Convert(nVarChar(20),@SRId) + ') And S95_Guid (' + Convert(nVarChar(100),@S95Guid) +')'
    return
  End
If (@EndTime Is Null)
  Begin
    Select @ErrorMsg = 'SegmentResponse for S95 Event_Id (' + Convert(nVarChar(20),@SRId) + ') Missing EndTime)'
    return
  End
If (@StartTime Is Null)
 	 Select @StartTime = @EndTime
Select @PUId = PU_Id From PAEquipment_Aspect_SOAEquipment Where (origin1equipmentid = @EquipmentId)
If (@PUId is NULL)
  Begin
    Select @ErrorMsg = 'PAEquipment_Aspect_SOAEquipment missing for EquipmentId (' + Convert(nVarChar(100),@EquipmentId) + ')'
    return
  End 
Select @MasterPUId = NULL
Select @MasterPUId = Master_Unit From Prod_Units_Base Where (PU_Id = @PUId)  
If (@MasterPUId Is NULL)
  Select @MasterPUId = @PUId
declare @Results table(MaterialDefinitionId uniqueidentifier, Prod_Id int null)
insert into @Results (MaterialDefinitionId)
 	 exec spServer_CmnGetSegRespMaterials @S95Guid
update @Results
   set Prod_Id = Products_Aspect_MaterialDefinition.Prod_Id
   from @Results
   join Products_Aspect_MaterialDefinition on Products_Aspect_MaterialDefinition.Origin1MaterialDefinitionId = MaterialDefinitionId
Select @EventKeys = ''
Declare ProdId_Cursor INSENSITIVE CURSOR
  For (Select Prod_Id From @Results)
  Open ProdId_Cursor  
Fetch_Loop:
  Fetch Next From ProdId_Cursor Into @ProdId
  If (@@Fetch_Status = 0)
    Begin
 	  	  	 If (@ProdId Is Not NULL)
 	  	  	  	 Begin
 	  	  	  	  	 If (@EventKeys <> '')
 	  	  	  	  	  	 Set @EventKeys = @EventKeys + ','
 	  	  	  	  	 Set @EventKeys = @EventKeys + CONVERT(nVarChar(100),@ProdId)
 	  	  	  	 End
      Goto Fetch_Loop
    End
Close ProdId_Cursor
Deallocate ProdId_Cursor
If (@EventKeys = '')
 	 Select @EventKeys = '-1'
Select @Found = 1
