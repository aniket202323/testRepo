CREATE PROCEDURE dbo.spEM_IEImportProcessOrder
 	 @Path_Code  	  	  	  	  	 nVarChar(100),
 	 @Process_Order  	  	  	  	 nVarChar(100),
 	 @Forecast_Start_Date 	  	 nVarChar(100),
 	 @Forecast_End_Date  	  	  	 nVarChar(100),
 	 @Forecast_Quantity  	  	  	 nVarChar(100),
 	 @Prod_Code  	  	  	  	  	 nVarChar(100),
 	 @Implied_Sequence  	  	  	 nVarChar(100),
 	 @PP_Status_Desc  	  	  	 nVarChar(100),
 	 @Block_Number  	  	  	  	 nVarChar(100),
 	 @PP_Type_Name  	  	  	  	 nVarChar(100),
 	 @Production_Rate  	  	  	 nVarChar(100),
 	 @Adjusted_Quantity  	  	  	 nVarChar(100),
 	 @Predicted_Total_Duration 	 nVarChar(100),
 	 @Control_Type  	  	  	  	 nVarChar(100),
   	 @ExtendedInfo         nvarchar(255),
   	 @UserGeneral1         nvarchar(255),
   	 @UserGeneral2         nvarchar(255),
   	 @UserGeneral3         nvarchar(255),
 	 @Comment_Text  	  	  	  	 nvarchar(255),
 	 @UserId 	  	  	  	  	  	 Int,
 	 @TransType 	  	  	  	  	 nVarChar(1)
AS
Declare 	 @dtForecast_Start_Date 	  	 Datetime,
 	  	 @dtForecast_End_Date  	  	 Datetime,
 	  	 @fForecast_Quantity  	  	 float,
 	  	 @Prod_Id  	  	  	  	  	 Int,
 	  	 @iImplied_Sequence  	  	  	 Int,
 	  	 @PP_Status_Id 	   	  	  	 Int,
 	  	 @PP_Type_Id 	   	  	  	  	 Int,
 	  	 @fProduction_Rate  	  	  	 Float,
 	  	 @fAdjusted_Quantity  	  	 Float,
 	  	 @Path_Id  	  	  	  	  	 Int,
 	  	 @fPredicted_Total_Duration 	 Float,
 	  	 @iControl_Type  	  	  	  	 Int,
 	  	 @Comment_id  	  	  	  	 Int,
 	  	 @PP_Id              Int,
 	  	 @Now 	  	  	  	  	  	 Datetime
SELECT @Now = dbo.fnServer_CmnGetDate(getUTCdate())
/* Clean and verify arguments */
Select  	 @Path_Code 	  	 = ltrim(rtrim(@Path_Code)),
 	  	 @Prod_Code 	  	 = ltrim(rtrim(@Prod_Code)),
 	  	 @PP_Status_Desc  	 = ltrim(rtrim(@PP_Status_Desc)),
 	  	 @Block_Number 	  	 = ltrim(rtrim(@Block_Number)),
 	  	 @PP_Type_Name 	  	 = ltrim(rtrim(@PP_Type_Name)),
 	  	 @Control_Type 	  	 = ltrim(rtrim(@Control_Type)),
 	  	 @Process_Order 	  	 = ltrim(rtrim(@Process_Order)),
 	  	 @ExtendedInfo 	  	 = ltrim(rtrim(@ExtendedInfo)),
 	  	 @UserGeneral1 	  	 = ltrim(rtrim(@UserGeneral1)),
 	  	 @UserGeneral2 	  	 = ltrim(rtrim(@UserGeneral2)),
 	  	 @UserGeneral3 	  	 = ltrim(rtrim(@UserGeneral3)),
 	  	 @Comment_Text 	  	 = ltrim(rtrim(@Comment_Text))
If @Forecast_Start_Date Is Null Or @Forecast_Start_Date = ''
  Begin
 	 Select 'Failed - Forecast Start Date not found'
    Return (-100)
  End
 If Len(@Forecast_Start_Date) <> 14 
  Begin
 	 Select 'Failed - Forecast Start Date not correct format'
    Return (-100)
  End
SELECT @dtForecast_Start_Date = 0
SELECT @dtForecast_Start_Date = DateAdd(year,convert(int,substring(@Forecast_Start_Date,1,4)) - 1900,@dtForecast_Start_Date)
SELECT @dtForecast_Start_Date = DateAdd(month,convert(int,substring(@Forecast_Start_Date,5,2)) - 1,@dtForecast_Start_Date)
SELECT @dtForecast_Start_Date = DateAdd(day,convert(int,substring(@Forecast_Start_Date,7,2)) - 1,@dtForecast_Start_Date)
SELECT @dtForecast_Start_Date = DateAdd(hour,convert(int,substring(@Forecast_Start_Date,9,2)) ,@dtForecast_Start_Date)
SELECT @dtForecast_Start_Date = DateAdd(minute,convert(int,substring(@Forecast_Start_Date,11,2)),@dtForecast_Start_Date)
If Len(@Forecast_End_Date) <> 14
  Begin
 	 Select 'Failed - Forecast End Date not correct format'
    Return (-100)
  End
SELECT @dtForecast_End_Date = 0
SELECT @dtForecast_End_Date = DateAdd(year,convert(int,substring(@Forecast_End_Date,1,4)) - 1900,@dtForecast_End_Date)
SELECT @dtForecast_End_Date = DateAdd(month,convert(int,substring(@Forecast_End_Date,5,2)) - 1,@dtForecast_End_Date)
SELECT @dtForecast_End_Date = DateAdd(day,convert(int,substring(@Forecast_End_Date,7,2)) - 1,@dtForecast_End_Date)
SELECT @dtForecast_End_Date = DateAdd(hour,convert(int,substring(@Forecast_End_Date,9,2)) ,@dtForecast_End_Date)
SELECT @dtForecast_End_Date = DateAdd(minute,convert(int,substring(@Forecast_End_Date,11,2)),@dtForecast_End_Date)
If isnumeric(@Forecast_Quantity) = 0
  Begin
 	 Select 'Failed - Forecast Quantity not correct'
    Return (-100)
  End
Select @fForecast_Quantity = convert(float,@Forecast_Quantity)
Select @Prod_Id = Prod_Id From Products Where Prod_Code = @Prod_Code
If @Prod_Id is Null 
  Begin
 	 Select 'Failed - Product Code not found'
    Return (-100)
  End
Select @PP_Status_Id = PP_Status_Id From Production_Plan_Statuses Where PP_Status_Desc = @PP_Status_Desc
If @PP_Status_Id is Null 
  Begin
 	 Select 'Failed - Status not found'
    Return (-100)
  End
Select @PP_Type_Id = PP_Type_Id From Production_Plan_Types Where PP_Type_Name = @PP_Type_Name
If @PP_Type_Id is Null 
  Begin
 	 Select 'Failed - Plan Type not found'
    Return (-100)
  End
Select @Path_Id = Null
If @Path_Code <> '' and @Path_Code is not null
  Begin
 	 Select @Path_Id = Path_Id From Prdexec_Paths Where Path_Code = @Path_Code
 	 If @Path_Id is Null 
   	 Begin
 	  	 Select 'Failed - Path Code not found'
     	 Return (-100)
  	 End
  End
Select @iControl_Type = Null
Select @iControl_Type = Control_Type_Id From Control_Type Where Control_Type_Desc = @Control_Type
If isnumeric(@Implied_Sequence) = 0
  Begin
 	 Select 'Failed - Implied Sequence not correct'
    Return (-100)
  End
Select @iImplied_Sequence = convert(int,@Implied_Sequence)
If Len(@Production_Rate) > 0
  Begin
 	  	 If isnumeric(@Production_Rate) = 0
 	  	   Begin
 	  	  	 Select 'Failed - Production Rate not correct'
 	  	     Return (-100)
 	  	   End
  End
Else
  Select @Production_Rate = 0
Select @fProduction_Rate = convert(float,@Production_Rate)
If Len(@Adjusted_Quantity) > 0
  Begin
 	  	 If isnumeric(@Adjusted_Quantity) = 0
 	  	   Begin
 	  	  	 Select 'Failed - Adjusted Quantity not correct'
 	  	     Return (-100)
 	  	   End
  End
Else
  Select @Adjusted_Quantity = 0
Select @fAdjusted_Quantity = convert(float,@Adjusted_Quantity)
If Len(@Predicted_Total_Duration) > 0
  Begin
 	  	 If isnumeric(@Predicted_Total_Duration) = 0
 	  	   Begin
 	  	  	 Select 'Failed - Predicted Total Duration not correct'
 	  	     Return (-100)
 	  	   End
  End
Else
  Select @Predicted_Total_Duration = 0
Select @fPredicted_Total_Duration = convert(float,@Predicted_Total_Duration)
/* Determine if update or insert */
Select @PP_Id = Null
If @Path_Id is Null
  Select @PP_Id = PP_Id from Production_Plan Where Path_Id is NULL and Process_Order = @Process_Order  
Else
  Select @PP_Id = PP_Id from Production_Plan Where Path_Id = @Path_Id and Process_Order = @Process_Order
If @PP_Id is Null
  Begin
    Insert into Production_Plan (Path_Id, Process_Order, Block_Number, Forecast_Start_Date, Forecast_End_Date,
            Forecast_Quantity, Production_Rate, PP_Type_Id, Prod_Id, Implied_Sequence, PP_Status_Id, Adjusted_Quantity,
            Control_Type, Predicted_Total_Duration, Extended_Info, User_General_1, User_General_2, User_General_3, 
            Entry_On, User_Id) 
    Values (@Path_Id, @Process_Order, @Block_Number, @dtForecast_Start_Date, @dtForecast_End_Date,
            @fForecast_Quantity, @fProduction_Rate, @PP_Type_Id, @Prod_Id, @iImplied_Sequence, @PP_Status_Id,
 	  	  	  	  	  	 @fAdjusted_Quantity, @iControl_Type, @fPredicted_Total_Duration, @ExtendedInfo, @UserGeneral1,
            @UserGeneral2, @UserGeneral3, @Now, @UserId)
    Select @PP_Id = Scope_Identity()
    If @Comment_Text is not Null and Len(@Comment_Text) > 0
      Begin
        Insert into Comments (CS_Id, Comment_Text, Comment, Entry_On, Modified_On, TopOfChain_Id, User_Id)
          Values (3, @Comment_Text, '', @Now, @Now, @PP_Id, @UserId)
        Select @Comment_Id = Scope_Identity()
        Update Production_Plan Set Comment_Id = @Comment_Id Where PP_Id = @PP_Id
      End
  End
Else
  Begin
 	 If @TransType = 'X'
 	   Begin
 	     Update Production_Plan Set Block_Number = @Block_Number, Forecast_Start_Date = @dtForecast_Start_Date,
 	       Forecast_End_Date = @dtForecast_End_Date, Forecast_Quantity = @fForecast_Quantity, Production_Rate = @fProduction_Rate,
 	       PP_Type_Id = @PP_Type_Id, Prod_Id = @Prod_Id, Implied_Sequence = @iImplied_Sequence, PP_Status_Id = @PP_Status_Id,
 	       Adjusted_Quantity = @fAdjusted_Quantity, Control_Type = @iControl_Type, Predicted_Total_Duration = @fPredicted_Total_Duration,
 	       Extended_Info = @ExtendedInfo, User_General_1 = @UserGeneral1, User_General_2 = @UserGeneral2,
 	  	  	  	 User_General_3 = @UserGeneral3
 	         Where Path_Id = @Path_Id and Process_Order = @Process_Order
    	  	 If @Comment_Text is not Null and Len(@Comment_Text) > 0
       	   Begin
         	 Insert into Comments (CS_Id, Comment_Text, Comment, Entry_On, Modified_On, TopOfChain_Id, User_Id)
         	   Values (3, @Comment_Text, '', @Now, @Now, @PP_Id, @UserId)
         	 Select @Comment_Id = Scope_Identity()
         	 Update Production_Plan Set Comment_Id = @Comment_Id Where PP_Id = @PP_Id
       	   End
 	   End
 	 Else If @TransType = 'D'
 	  	  	 Begin
 	  	  	  	 Update Event_Details set pp_Id = null Where PP_Id = @PP_Id
 	  	  	  	 Delete From Production_Plan_Alarms Where PP_Id = @PP_Id
 	  	  	  	 Delete From Production_Plan_Transitions Where PP_Id = @PP_Id
 	  	  	  	 Delete From Production_Plan_Starts Where PP_Id = @PP_Id
 	  	  	  	 Declare @PPSID int
 	  	  	  	 Declare pps_Cursor Cursor 
 	  	  	  	  	 For Select PP_Setup_Id From Production_Setup Where PP_Id = @PP_Id
 	  	  	  	 Open pps_Cursor
 	  	  	  	 pps_Cursor_Loop:
 	  	  	  	 Fetch Next From pps_Cursor Into @PPSID
 	  	  	  	 If @@Fetch_Status = 0
 	  	  	  	   Begin
 	  	  	  	  	 Update Event_Details Set PP_Setup_Id = Null Where PP_Setup_Id = @PPSID
 	  	  	  	  	 Delete From Production_Plan_Starts Where PP_Setup_Id = @PPSID
 	  	  	  	  	 Delete From Production_Setup_Detail Where PP_Setup_Id = @PPSID
 	  	  	  	  	 Delete From Production_Setup Where PP_Setup_Id = @PPSID
 	  	  	  	  	 GoTo pps_Cursor_Loop
 	  	  	  	   End
 	  	  	  	 Close pps_Cursor
 	  	  	  	 Deallocate pps_Cursor
 	  	  	  	 Delete From Production_Plan Where PP_Id = @PP_Id
 	  	  	 End
  End
