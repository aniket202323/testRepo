CREATE PROCEDURE dbo.spServer_CmnAddRoll
@MasterEventId int,
@User_Id int,
@PU_Id int,
@Event_Num nVarChar(100),
@Alternate_Event_Num nVarChar(100),
@TimeStamp datetime,
@AppliedProd_Id int,
@Event_Status int,
@Event_Type int,
@Dem_X float,
@Dem_Y float,
@Dem_Z float,
@Dem_A float,
@Order_Id int,
@Order_Line_Id int,
@Shipment_Item_Id int,
@AddIfMissing int,
@Event_Id int OUTPUT,
@Component_Id int OUTPUT,
@ErrorMsg nVarChar(255) OUTPUT
 AS
Declare
  @NewTimeStamp datetime,
  @Status int,
  @OrigProd_Id int,
  @MasterUnit int,
  @MasterTimeStamp datetime,
  @Event_Detail_Exists int
Select @ErrorMsg = ''
Select @MasterUnit = NULL
Select @MasterUnit = PU_Id, @MasterTimeStamp = TimeStamp From Events Where Event_Id = @MasterEventId
If (@MasterUnit Is NULL)
  Begin
    Select @Event_Id = 0
    Select @Component_Id = 0
    Select @ErrorMsg = 'Error Finding MasterEventId [' + Convert(nVarChar(20),@MasterEventId) + ']'
    Return
  End
Select @Event_Id = NULL
Select @Event_Id = Event_Id,
       @NewTimeStamp = TimeStamp
 From Events Where (PU_Id = @PU_Id) And (Event_Num = @Event_Num)
If (@Event_Id Is NULL)
  Begin
    If (@AddIfMissing = 1)
      Begin
        Select @Event_Id = 0
     	 Select @NewTimeStamp = @TimeStamp
     	 Execute @Status = spServer_DBMgrUpdEvent 
 	  	  	 @Event_Id OUTPUT,
 	  	  	 @Event_Num,
 	  	  	 @PU_Id,
 	  	  	 @NewTimeStamp,
 	  	  	 @AppliedProd_Id,
 	  	  	 @MasterEventId,
 	  	  	 @Event_Status,
 	  	  	 1,
 	  	  	 0,NULL,NULL,NULL,NULL,NULL,NULL,0
 	 If (@Status <> 1) Or (@Event_Id = 0) Or (@Event_Id Is NULL)
          Begin
 	     Select @Event_Id = 0
            Select @Component_Id = 0
            Select @ErrorMsg = 'Error Adding New Roll [' + @Event_Num + ',' + Convert(nVarChar(30),@NewTimeStamp) + ', PUId-' + Convert(nVarChar(10),@PU_Id) + ', AppProdId-' + Convert(nVarChar(10),@AppliedProd_Id) + ', Status' + Convert(nVarChar(10),@Event_Status) + ']' 
            Return
          End
      End
    Else
      Begin
        Select @Event_Id = 0
        Select @Component_Id = 0
        Select @ErrorMsg = 'Roll Not Found [' + @Event_Num + ']'
        Return
      End
  End
Else
  Begin
    Execute @Status = spServer_DBMgrUpdEvent 
 	  	 @Event_Id,
 	  	 @Event_Num,
 	  	 @PU_Id,
 	  	 @NewTimeStamp,
 	  	 @AppliedProd_Id,
 	  	 NULL,
 	  	 @Event_Status,
 	  	 2,
 	  	 0,NULL,NULL,NULL,NULL,NULL,NULL,0
    If (@Status <> 2) And (@Status <> 4)
      Begin
 	 Select @Event_Id = 0
        Select @Component_Id = 0
        Select @ErrorMsg = 'Error Updating Existing Roll [' + @Event_Num + ']'
        Return
      End
  End
Select @OrigProd_Id = Prod_Id
  From Production_Starts
  Where (PU_Id = @MasterUnit) And 
        (Start_Time < @MasterTimeStamp) And
        ((End_Time >= @MasterTimeStamp) Or (End_Time Is NULL))
Select @Event_Detail_Exists = NULL
Select @Event_Detail_Exists = Event_Id From Event_Details Where Event_Id = @Event_Id
If (@Event_Detail_Exists Is NULL)
  Begin
    If (@AddIfMissing = 1)
      Begin
        Insert Into Event_Details(Entered_On,Entered_By,Event_Id,PU_Id,Alternate_Event_Num,Initial_Dimension_X,Initial_Dimension_Y,Initial_Dimension_Z,Initial_Dimension_A,Final_Dimension_X,Final_Dimension_Y,Final_Dimension_Z,Final_Dimension_A,Order_Id,Order_Line_Id,Shipment_Item_Id)
          Values(dbo.fnServer_CmnGetDate(GetUTCDate()),@User_Id,@Event_Id,@PU_Id,@Alternate_Event_Num,@Dem_X,@Dem_Y,@Dem_Z,@Dem_A,@Dem_X,@Dem_Y,@Dem_Z,@Dem_A,@Order_Id,@Order_Line_Id,@Shipment_Item_Id)
      End
    Else
      Begin
        Select @Event_Id = 0
        Select @Component_Id = 0
        Select @ErrorMsg = 'Roll Detail Not Found [' + @Event_Num + ']'
        Return
      End
  End
Else
  Begin
    Update Event_Details Set
  	 Entered_On = dbo.fnServer_CmnGetDate(GetUTCDate()),
 	 Entered_By = @User_Id,
 	 Event_Id = @Event_Id,
 	 PU_Id = @PU_Id,
 	 Alternate_Event_Num = @Alternate_Event_Num,
 	 Initial_Dimension_X = @Dem_X,
 	 Initial_Dimension_Y = @Dem_Y,
 	 Initial_Dimension_Z = @Dem_Z,
 	 Initial_Dimension_A = @Dem_A,
 	 Final_Dimension_X = @Dem_X,
 	 Final_Dimension_Y = @Dem_Y,
 	 Final_Dimension_Z = @Dem_Z,
 	 Final_Dimension_A = @Dem_A,
 	 Order_Id = @Order_Id,
 	 Order_Line_Id = @Order_Line_Id,
 	 Shipment_Item_Id = @Shipment_Item_Id
      Where Event_Id = @Event_Id
  End
Select @Component_Id = NULL
Select @Component_Id = Component_Id From Event_Components Where Event_Id = @Event_Id
If (@Component_Id Is NULL)
  Begin
    If (@AddIfMissing = 1)
      Begin
 	 Insert Into Event_Components(Event_Id,Source_Event_Id,Dimension_X,Dimension_Y,Dimension_Z,Dimension_A)
          Values(@Event_Id,@MasterEventId,@Dem_X,@Dem_Y,@Dem_Z,@Dem_A)
        Select @Component_Id = Scope_identity()
      End
    Else
      Begin
        Select @Component_Id = 0
        Return
      End
  End
Else
  Begin
    Update Event_Components Set
 	 Source_Event_Id = @MasterEventId,
 	 Dimension_X = @Dem_X,
 	 Dimension_Y = @Dem_Y,
 	 Dimension_Z = @Dem_Z,
 	 Dimension_A = @Dem_A 	 
      Where Component_Id = @Component_Id
  End
