CREATE PROCEDURE dbo.spEM_IEImportProcessOrderSequence
 	 @Path_Code  	  	  	  	  	 nVarChar(100),
 	 @Process_Order  	  	  	  	 nVarChar(100),
 	 @PatternCode 	  	  	  	 nVarChar(100),
 	 @Implied_Sequence  	  	  	 nVarChar(100),
 	 @PP_Status_Desc  	  	  	 nVarChar(100),
 	 @PatternRepititions 	  	  	 nVarChar(100),
 	 @Base_A 	  	  	  	  	  	 nVarChar(100),
 	 @Base_X 	  	  	  	  	  	 nVarChar(100),
 	 @Base_Y 	  	  	  	  	  	 nVarChar(100),
 	 @Base_Z 	  	  	  	  	  	 nVarChar(100),
 	 @Forecast_Quantity  	  	  	 nVarChar(100),
 	 @BaseGen1 	  	  	  	  	 nVarChar(100),
 	 @BaseGen2 	  	  	  	  	 nVarChar(100),
 	 @BaseGen3 	  	  	  	  	 nVarChar(100),
 	 @BaseGen4 	  	  	  	  	 nVarChar(100),
 	 @ExtendedInfo 	  	  	  	 nvarchar(255),
 	 @Predicted_Total_Duration 	 nVarChar(100),
 	 @Shrinkage 	   	  	  	  	 nVarChar(100),
  @UserGeneral1       nvarchar(255),
  @UserGeneral2       nvarchar(255),
  @UserGeneral3       nvarchar(255),
 	 @Comment_Text  	  	  	  	 nvarchar(255),
 	 @UserId 	  	  	  	  	  	 Int
AS
Declare 	 @Path_Id  	  	  	  	  	 Int,
 	  	 @fForecast_Quantity  	  	 float,
 	  	 @iImplied_Sequence  	  	  	 Int,
 	  	 @PP_Status_Id 	   	  	  	 Int,
 	  	 @PP_Type_Id 	   	  	  	  	 Int,
 	  	 @iPatternRepititions 	  	 Int,
 	  	 @rBaseA 	  	  	   	  	  	 Real,
 	  	 @rBaseX 	  	  	   	  	  	 Real,
 	  	 @rBaseY 	  	  	   	  	  	 Real,
 	  	 @rBaseZ 	  	  	   	  	  	 Real,
 	  	 @rBaseGen1 	  	  	   	  	 Real,
 	  	 @rBaseGen2 	  	  	   	  	 Real,
 	  	 @rBaseGen3 	  	  	   	  	 Real,
 	  	 @rBaseGen4 	  	  	   	  	 Real,
 	  	 @fPredicted_Total_Duration 	 Float,
 	  	 @rShrinkage  	  	  	  	 Real,
 	  	 @Comment_id  	  	  	  	 Int,
    @PP_Id              Int,
    @PP_Setup_Id        Int
/* Clean and verify arguments */
Select  	 @Path_Code 	  	  	 = ltrim(rtrim(@Path_Code)),
 	  	 @Process_Order 	  	 = ltrim(rtrim(@Process_Order)),
 	  	 @PP_Status_Desc  	 = ltrim(rtrim(@PP_Status_Desc)),
 	  	 @PatternCode  	  	 = ltrim(rtrim(@PatternCode)),
 	  	 @ExtendedInfo 	  	 = ltrim(rtrim(@ExtendedInfo)),
 	  	 @UserGeneral1 	  	 = ltrim(rtrim(@UserGeneral1)),
 	  	 @UserGeneral2 	  	 = ltrim(rtrim(@UserGeneral2)),
 	  	 @UserGeneral3 	  	 = ltrim(rtrim(@UserGeneral3)),
 	  	 @Comment_Text 	  	 = ltrim(rtrim(@Comment_Text))
If @Process_Order Is Null Or @Process_Order = ''
  Begin
 	 Select 'Failed - Process Order not found'
    Return (-100)
  End
If isnumeric(@Implied_Sequence) = 0 or @Implied_Sequence is null
  Begin
 	 Select 'Failed - Implied Sequence not correct'
    Return (-100)
  End
Select @iImplied_Sequence = convert(int,@Implied_Sequence)
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
Select @PP_Status_Id = PP_Status_Id From Production_Plan_Statuses Where PP_Status_Desc = @PP_Status_Desc
If @PP_Status_Id is Null 
  Begin
 	 Select 'Failed - Status not found'
    Return (-100)
  End
If Len(@Forecast_Quantity) > 0 
  Begin
 	  	 If isnumeric(@Forecast_Quantity) = 0
 	  	   Begin
 	  	  	 Select 'Failed - Forcast Quanity not correct'
 	  	     Return (-100)
 	  	   End
  End
Else
  Select @Forecast_Quantity = 0
Select @fForecast_Quantity = convert(float,@Forecast_Quantity)
If isnumeric(@PatternRepititions) = 0
  Begin
 	 Select 'Failed - Pattern Repitations not correct'
    Return (-100)
  End
Select @iPatternRepititions = convert(Int,@PatternRepititions)
If Len(@Base_A) > 0
  Begin
 	  	 If isnumeric(@Base_A) = 0
 	  	   Begin
 	  	  	 Select 'Failed - Base A not correct'
 	  	     Return (-100)
 	  	   End
  End
Else
  Select @Base_A = 0
Select @rBaseA = convert(Real,@Base_A)
If Len(@Base_X) > 0
  Begin
 	  	 If isnumeric(@Base_X) = 0
 	  	   Begin
 	  	  	 Select 'Failed - Base X not correct'
 	  	     Return (-100)
 	  	   End
  End
Else
  Select @Base_X = 0
Select @rBaseX = convert(Real,@Base_X)
If Len(@Base_Y) > 0
  Begin
 	  	 If isnumeric(@Base_Y) = 0
 	  	   Begin
 	  	  	 Select 'Failed - Base A not correct'
 	  	     Return (-100)
 	  	   End
  End
Else
  Select @Base_Y = 0
Select @rBaseY = convert(Real,@Base_Y)
If Len(@Base_Z) > 0
  Begin
 	  	 If isnumeric(@Base_Z) = 0
 	  	   Begin
 	  	  	 Select 'Failed - Base Z not correct'
 	  	     Return (-100)
 	  	   End
  End
Else
  Select @Base_Z = 0
Select @rBaseZ = convert(Real,@Base_Z)
If Len(@BaseGen1) > 0 
  Begin
 	  	 If isnumeric(@BaseGen1) = 0
 	  	   Begin
 	  	  	 Select 'Failed - Base General 1 not correct'
 	  	     Return (-100)
 	  	   End
  End
Else
  Select @BaseGen1 = 0
Select @rBaseGen1 = convert(Real,@BaseGen1)
If Len(@BaseGen2) > 0
  Begin
 	  	 If isnumeric(@BaseGen2) = 0
 	  	   Begin
 	  	  	 Select 'Failed - Base General 2 not correct'
 	  	     Return (-100)
 	  	   End
  End
Else
  Select @BaseGen2 = 0
Select @rBaseGen2 = convert(Real,@BaseGen2)
If Len(@BaseGen3) > 0 
  Begin
 	  	 If isnumeric(@BaseGen3) = 0
 	  	   Begin
 	  	  	 Select 'Failed - Base General 3 not correct'
 	  	     Return (-100)
 	  	   End
  End
Else
  Select @BaseGen3 = 0
Select @rBaseGen3 = convert(Real,@BaseGen3)
If Len(@BaseGen4) > 0
  Begin
 	  	 If isnumeric(@BaseGen4) = 0
 	  	   Begin
 	  	  	 Select 'Failed - Base General 4 not correct'
 	  	     Return (-100)
 	  	   End
  End
Else
  Select @BaseGen4 = 0
Select @rBaseGen4 = convert(Real,@BaseGen4)
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
If Len(@Shrinkage) > 0
  Begin
 	  	 If isnumeric(@Shrinkage) = 0
 	  	   Begin
 	  	  	 Select 'Failed - Shrinkage not correct'
 	  	     Return (-100)
 	  	   End
  End
Else
  Select @Shrinkage = 0
Select @rShrinkage = convert(real,@Shrinkage)
/* Find the Parent Order */
Select @PP_Id = Null
If @Path_Id is Null
  Select @PP_Id = PP_Id from Production_Plan Where Path_Id is NULL and Process_Order = @Process_Order  
Else
  Select @PP_Id = PP_Id from Production_Plan Where Path_Id = @Path_Id and Process_Order = @Process_Order
If @PP_Id is Null
  Begin
    Select 'Failed - Unable to find the Parent Order'
      Return (-100)
  End
/* Update or Insert to Production_Setup table? */
Select @PP_Setup_Id = Null
Select @PP_Setup_Id = PP_Setup_Id from Production_Setup Where PP_Id = @PP_Id and Pattern_Code = @PatternCode
If @PP_Setup_Id is Null
  Begin
    Insert into Production_Setup (PP_Id, Forecast_Quantity, PP_Status_Id, Pattern_Repititions, Implied_Sequence,
        Base_General_1, Base_General_2, Base_General_3, Base_General_4, Base_Dimension_A, Base_Dimension_X,
        Base_Dimension_Y, Base_Dimension_Z, Pattern_Code, Shrinkage, Extended_Info, User_General_1,
        User_General_2, User_General_3, Predicted_Total_Duration, User_Id)
    Values (@PP_Id, @fForecast_Quantity, @PP_Status_Id, @iPatternRepititions, @iImplied_Sequence, @rBaseGen1,
            @rBaseGen2, @rBaseGen3, @rBaseGen4, @rBaseA, @rBaseX, @rBaseY, @rBaseZ, @PatternCode,
 	  	  	  	  	   @rShrinkage, @ExtendedInfo, @UserGeneral1, @UserGeneral2, @UserGeneral3, @fPredicted_Total_Duration, @UserId)
    Select @PP_Setup_Id = Scope_Identity()
    If @Comment_Text is not Null and Len(@Comment_Text) > 0
      Begin
        Insert into Comments (CS_Id, Comment_Text, Comment, Entry_On, Modified_On, TopOfChain_Id, User_Id)
          Values (3, @Comment_Text, '', dbo.fnServer_CmnGetDate(getUTCdate()), dbo.fnServer_CmnGetDate(getUTCdate()), @PP_Setup_Id, @UserId)
        Select @Comment_Id = Scope_Identity()
        Update Production_Setup Set Comment_Id = @Comment_Id Where PP_Setup_Id = @PP_Setup_Id
      End
  End
Else
  Begin
    Update Production_Setup Set Forecast_Quantity = @fForecast_Quantity, PP_Status_Id = @PP_Status_Id, 
           Pattern_Repititions = @iPatternRepititions, Implied_Sequence = @iImplied_Sequence,
           Base_General_1 = @rBaseGen1, Base_General_2 = @rBaseGen2, Base_General_3 = @rBaseGen3,
 	  	  	  	  	  Base_General_4 = @rBaseGen4, Base_Dimension_A = @rBaseA, Base_Dimension_X = @rBaseX,
           Base_Dimension_Y = @rBaseY, Base_Dimension_Z = @rBaseZ, Pattern_Code = @PatternCode, 
 	  	  	  	  	  Shrinkage = @rShrinkage, Extended_Info = @ExtendedInfo, User_General_1 = @UserGeneral1,
           User_General_2 = @UserGeneral2, User_General_3 = @UserGeneral3, 
 	  	  	  	  	  Predicted_Total_Duration = @fPredicted_Total_Duration
       Where PP_Setup_Id = @PP_Setup_Id
    If @Comment_Text is not Null and Len(@Comment_Text) > 0
      Begin
        Insert into Comments (CS_Id, Comment_Text, Comment, Entry_On, Modified_On, TopOfChain_Id, User_Id)
          Values (3, @Comment_Text, '', dbo.fnServer_CmnGetDate(getUTCdate()), dbo.fnServer_CmnGetDate(getUTCdate()), @PP_Setup_Id, @UserId)
        Select @Comment_Id = Scope_Identity()
        Update Production_Setup Set Comment_Id = @Comment_Id Where PP_Setup_Id = @PP_Setup_Id
      End
  End
