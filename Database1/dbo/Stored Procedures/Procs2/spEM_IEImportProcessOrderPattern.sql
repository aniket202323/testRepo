CREATE PROCEDURE dbo.spEM_IEImportProcessOrderPattern
 	 @Path_Code  	  	  	  	  	 nVarChar(100),
 	 @Process_Order  	  	  	  	 nVarChar(100),
 	 @Pattern_Code  	  	  	  	 nVarChar(100),
 	 @ElementNumber 	   	  	  	 nVarChar(100),
 	 @ProdCode 	  	  	  	  	 nVarChar(100),
 	 @PP_Status_Desc  	  	  	 nVarChar(100),
 	 @TargetDim_A 	  	  	  	 nVarChar(100),
 	 @TargetDim_X 	  	  	  	 nVarChar(100),
 	 @TargetDim_Y 	  	  	  	 nVarChar(100),
 	 @TargetDim_Z 	  	  	  	 nVarChar(100),
 	 @ExtendedInfo 	  	  	  	 nvarchar(255),
  @UserGeneral1       nvarchar(255),
  @UserGeneral2       nvarchar(255),
  @UserGeneral3       nvarchar(255),
 	 @Comment_Text  	  	  	  	 nvarchar(255),
 	 @UserId 	  	  	  	  	  	 Int
AS
Declare 	 @Path_Id  	  	  	  	  	 Int,
 	  	 @PP_Status_Id 	   	  	  	 Int,
 	  	 @PP_Type_Id 	   	  	  	  	 Int,
 	  	 @Prod_Id 	  	  	  	  	 Int,
 	  	 @iElementNumber 	  	  	  	 Int,
 	  	 @rTargetDim_A 	   	  	  	 Real,
 	  	 @rTargetDim_X 	   	  	  	 Real,
 	  	 @rTargetDim_Y 	   	  	  	 Real,
 	  	 @rTargetDim_Z 	   	  	  	 Real,
 	  	 @Comment_id  	  	  	  	 Int,
    @PP_Id              Int,
    @PP_Setup_Id        Int,
    @PP_Setup_Detail_Id Int
/* Clean and verify arguments */
Select  	 @Path_Code 	  	  	 = ltrim(rtrim(@Path_Code)),
 	  	 @Process_Order 	  	 = ltrim(rtrim(@Process_Order)),
 	  	 @PP_Status_Desc  	 = ltrim(rtrim(@PP_Status_Desc)),
 	  	 @ProdCode  	  	  	 = ltrim(rtrim(@ProdCode)),
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
If isnumeric(@ElementNumber) = 0 
  Begin
 	 Select 'Failed - Element Number not correct'
    Return (-100)
  End
Select @iElementNumber = convert(int,@ElementNumber)
Select @Prod_Id = Prod_Id From Products Where Prod_Code = @ProdCode
If @Prod_Id is Null 
  Begin
 	 Select 'Failed - Product Code not found'
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
Select @PP_Status_Id = PP_Status_Id From Production_Plan_Statuses Where PP_Status_Desc = @PP_Status_Desc
If @PP_Status_Id is Null 
  Begin
 	 Select 'Failed - Status not found'
    Return (-100)
  End
If Len(@TargetDim_A) > 0
  Begin
 	  	 If isnumeric(@TargetDim_A) = 0
 	  	   Begin
 	  	  	 Select 'Failed - Target A not correct'
 	  	     Return (-100)
 	  	   End
  End
Else
  Select @TargetDim_A = 0
Select @rTargetDim_A = convert(Real,@TargetDim_A)
If Len(@TargetDim_X) > 0
  Begin
 	  	 If isnumeric(@TargetDim_X) = 0
 	  	   Begin
 	  	  	 Select 'Failed - Target X not correct'
 	  	     Return (-100)
 	  	   End
  End
Else
  Select @TargetDim_X = 0
Select @rTargetDim_X = convert(Real,@TargetDim_X)
If Len(@TargetDim_Y) > 0
  Begin
 	  	 If isnumeric(@TargetDim_Y) = 0
 	  	   Begin
 	  	  	 Select 'Failed - Target Y not correct'
 	  	     Return (-100)
 	  	   End
  End
Else
  Select @TargetDim_Y = 0
Select @rTargetDim_Y = convert(Real,@TargetDim_Y)
If Len(@TargetDim_Z) > 0
  Begin
 	  	 If isnumeric(@TargetDim_Z) = 0
 	  	   Begin
 	  	  	 Select 'Failed - Target Z not correct'
 	  	     Return (-100)
 	  	   End
  End
Else
  Select @TargetDim_Z = 0
Select @rTargetDim_Z = convert(Real,@TargetDim_Z)
/* Find the Parent Order */
Select @PP_Id = Null
If @Path_Id is NULL
  Select @PP_Id = PP_Id from Production_Plan Where Path_Id Is NULL and Process_Order = @Process_Order
Else
  Select @PP_Id = PP_Id from Production_Plan Where Path_Id = @Path_Id and Process_Order = @Process_Order
If @PP_Id is Null
  Begin
    Select 'Failed - Unable to find the Process Order on path'
      Return (-100)
  End
/* Find the Parent Sequence */
Select @PP_Setup_Id = Null
Select @PP_Setup_Id = PP_Setup_Id from Production_Setup Where PP_Id = @PP_Id and Pattern_Code = @Pattern_Code
If @PP_Setup_Id is Null
  Begin
    Select 'Failed - Unable to find the Production Setup with Pattern'
      Return (-100)
  End
/* Insert or Update of Production_Setup table? */
Select @PP_Setup_Detail_Id = Null
Select @PP_Setup_Detail_Id = PP_Setup_Detail_Id from Production_Setup_Detail Where PP_Setup_Id = @PP_Setup_Id and Element_Number = @ElementNumber
If @PP_Setup_Detail_Id is Null
  Begin
    Insert into Production_Setup_Detail (PP_Setup_Id, Element_Number, Element_Status, Prod_Id, Target_Dimension_A, 
        Target_Dimension_X, Target_Dimension_Y, Target_Dimension_Z, Extended_Info, User_General_1,
        User_General_2, User_General_3, User_Id)
    Values (@PP_Setup_Id, @iElementNumber, @PP_Status_Id, @Prod_Id, @rTargetDim_A, @rTargetDim_X,
            @rTargetDim_Y, @rTargetDim_Z, @ExtendedInfo, @UserGeneral1, @UserGeneral2, @UserGeneral3, @UserId)
    Select @PP_Setup_Detail_Id = Scope_Identity()
    If @Comment_Text is not Null and Len(@Comment_Text) > 0
      Begin
        Insert into Comments (CS_Id, Comment_Text, Comment, Entry_On, Modified_On, TopOfChain_Id, User_Id)
          Values (3, @Comment_Text, '', dbo.fnServer_CmnGetDate(getUTCdate()), dbo.fnServer_CmnGetDate(getUTCdate()), @PP_Setup_Detail_Id, @UserId)
        Select @Comment_Id = Scope_Identity()
        Update Production_Setup_Detail Set Comment_Id = @Comment_Id Where PP_Setup_Detail_Id = @PP_Setup_Detail_Id
      End    
  End
Else
  Begin
 	  	 SELECT @Comment_Id = Comment_Id
 	  	  	 FROM Production_Setup_Detail
 	  	  	 WHERE PP_Setup_Detail_Id = @PP_Setup_Detail_Id
    UPDATE Production_Setup_Detail Set Element_Number = @iElementNumber, Element_Status = @PP_Status_Id, 
           Prod_Id = @Prod_Id, Target_Dimension_A = Target_Dimension_A, Target_Dimension_X = Target_Dimension_X, 
           Target_Dimension_Y = Target_Dimension_Y, Target_Dimension_Z = Target_Dimension_Z, 
           Extended_Info = @ExtendedInfo, User_General_1 = @UserGeneral1, User_General_2 = @UserGeneral2, 
           User_General_3 = @UserGeneral3
    WHERE PP_Setup_Detail_Id = @PP_Setup_Detail_Id
 	  	 IF @Comment_Id Is Not NULL
 	  	 BEGIN
 	  	  	 UPDATE Comments Set Comment_Text = @Comment_Text,Comment = @Comment_Text 
 	  	  	  	 WHERE Comment_Id = @Comment_Id
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	 If @Comment_Text is not Null and Len(@Comment_Text) > 0
 	  	  	 Begin
 	  	  	  	 Insert into Comments (CS_Id, Comment_Text, Comment, Entry_On, Modified_On, TopOfChain_Id, User_Id)
 	  	  	  	 Values (3, @Comment_Text, '', dbo.fnServer_CmnGetDate(getUTCdate()), dbo.fnServer_CmnGetDate(getUTCdate()), @PP_Setup_Detail_Id, @UserId)
 	  	  	  	 Select @Comment_Id = Scope_Identity()
 	  	  	  	 Update Production_Setup_Detail Set Comment_Id = @Comment_Id Where PP_Setup_Detail_Id = @PP_Setup_Detail_Id
 	  	  	 End
 	  	 END
  End
