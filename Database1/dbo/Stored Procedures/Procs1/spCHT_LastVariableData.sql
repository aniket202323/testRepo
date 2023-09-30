Create Procedure dbo.spCHT_LastVariableData 
@VarId int,
@ParameterDate datetime
AS
  -- Declare local variables.
 DECLARE @VarMasterId int, 
         @PUId Int,
         @IsEventBased int,
         @IsImmediateActivation int,
         @EventNum nvarchar(50),
         @ProdId int,
         @ProdCode nvarchar(50),
         @ActivationDate DateTime,
         @URL nvarchar(25),
         @UWL nvarchar(25),
         @TGT nvarchar(25),
         @LWL nvarchar(25),
         @LRL nvarchar(25),
         @StartTimeInterval datetime,
         @EndTimeInterval datetime,
         @TimeStamp datetime,
         @CommentID int,
         @Result nvarchar(25)
--  Select @StartTimeInterval  = dateadd(day,-2,getdate())
--  Select @EndTimeInterval = dateadd(day,1,getdate())
    Select @StartTimeInterval = dateadd(day,-2,@ParameterDate)
    Select @EndTimeInterval = dateadd(second,-1,@ParameterDate)
  Select @PUId = Pu_Id,
         @IsEventBased          = Case When Event_type = 1 Then 1 Else 0 End,
         @IsImmediateActivation = Case When sa_id = 1 Then 1 Else 0 End 
   From Variables 
   Where Var_id = @VarId
  Select @Result = NULL
  Select @TimeStamp=NULL
  Select @EventNum=NULL 
  Select @CommentId = NULL 
  Select @ProdId=NULL
  Select @ProdCode=NULL 
  Select @ActivationDate=NULL
  Select @URL =NULL
  Select @UWL =NULL
  Select @TGT =NULL
  Select @LWL =NULL
  Select @LRL =NULL
  If (@VarId IS Not NULL)
   Begin
-- Get Master Unit
  Select @VarMasterId = Case When Master_Unit Is Null Then PU_Id Else Master_Unit End
   From Prod_Units Where PU_id=@PUId
-- Get Last Result and TimeStamp
  Select @TimeStamp=Result_On, @Result=Result, @CommentId=Comment_Id
   From Tests 
   Where Var_id=@VarId and Result_On = 
    (Select Max(Result_On) 
     From Tests 
     Where Var_Id=@VarId 
     And Result_on between @StartTimeInterval and @EndTimeInterval)
  If (@TimeStamp Is Not Null)
   Begin
-- Get Events Attached To Data
    If (@IsEventBaseD=1)
     Begin
      Select @EventNum = Event_Num From Events Where Pu_id=@VarMasterId And  
       TimeStamp = @TimeStamp
    End
-- Get Products Attached To Data, Map Time Based On Spec Activation
    Select @ProdId=Prod_Id, @ActivationDate = Case When @IsImmediateActivation=1 Then @TimeStamp
                                              Else Start_Time End
     From Production_Starts Where Pu_id = @VarMasterID AND Start_Time < @TimeStamp AND
                                  ((@TimeStamp<End_Time) Or (End_Time Is Null))
    Select @ProdCode = Prod_Code
    From Products where Prod_Id = @ProdId
 -- Get Specs Attached To Data
    Select @URL=U_Reject, @UWL = U_Warning, @TGT=Target, @LWL=L_Warning, @LRL=L_Reject
     From Var_Specs Where Var_Id = @VarID And
                          Prod_Id = @ProdID And
                          Effective_date <= @ActivationDate And
                          ((Expiration_Date>@ACtivationDate) Or (Expiration_Date Is Null))
   End   
  End
  Select @VarId As VarId, @TimeStamp As LastTimeStamp, @Result As LastResult, 
         @EventNum as EventNum, @URL as URL, @UWL as UWL, @TGT as TGT, @LWL as LWL, 
         @LRL as LRL,@CommentId as LastCommentID, @ProdId as ProdId, @ProdCode as ProdCode
