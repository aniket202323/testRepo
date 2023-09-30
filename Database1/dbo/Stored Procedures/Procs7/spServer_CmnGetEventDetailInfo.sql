Create Procedure dbo.spServer_CmnGetEventDetailInfo
@EventId int,
@IDX float output,
@IDY float output,
@IDZ float output,
@IDA float output,
@FDX float output,
@FDY float output,
@FDZ float output,
@FDA float output,
@EventStatus int output,
@AppProdId int output,
@PUId int output,
@PriEventNum nVarChar(255) output,
@AltEventNum nVarChar(255) output,
@Timestamp datetime output,
@UserId int output,
@Found int output,
@PPId int = null output
AS
Select @IDX = NULL
Select @IDY = NULL
Select @IDZ = NULL
Select @IDA = NULL
Select @FDX = NULL
Select @FDY = NULL
Select @FDZ = NULL
Select @FDA = NULL
Select @EventStatus = NULL
Select @AppProdId = NULL
Select @PriEventNum = NULL
Select @AltEventNum = NULL
Select @Timestamp = NULL
Select @PUId = NULL
Select @UserId = NULL
Select @PPId = NULL
Select @IDX = Initial_Dimension_X, 
       @IDY = Initial_Dimension_Y, 
       @IDZ = Initial_Dimension_Z, 
       @IDA = Initial_Dimension_A, 
       @FDX = Final_Dimension_X, 
       @FDY = Final_Dimension_Y, 
       @FDZ = Final_Dimension_Z, 
       @FDA = Final_Dimension_A,
       @AltEventNum = Alternate_Event_Num,
       @UserId = Entered_By,
 	    @PPId = PP_Id
  From Event_Details 
  Where (Event_Id = @EventId)
Select @Found = NULL
Select @Found = Event_Id,
       @Timestamp = Timestamp,
       @EventStatus = Event_Status,
       @AppProdId = Applied_Product,
       @PriEventNum = Event_Num,
       @PUId = PU_Id
  From Events Where Event_Id = @EventId
If (@Found Is NULL)
  Select @Found = 0
