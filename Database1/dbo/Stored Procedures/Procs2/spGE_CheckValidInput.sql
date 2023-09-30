CREATE Procedure dbo.spGE_CheckValidInput
 	  	  	 @PEI_Id 	  	 Int,
 	  	  	 @Event 	  	 nvarchar(25),
 	  	  	 @IsId 	  	 bit,
 	  	  	 @ReturnEventId  int 	 Output
AS
-- @IsId = 0 From Drag & Drop : 1 From Scanner
-- Return Codes
-- 1 Event is ok
-- 2 Event not valid for this unit
-- 3 Problem with production starts
-- 4 Incorrect Product For unit
-- 5 Event is in progress
-- 6 Event Not Found - Okay to Create
-- 7 Event Not Found - Already on temp Unit
DECLARE @Status 	  	  	 int,
 	 @PU_Id 	  	  	 Int,
 	 @Event_PU 	  	 Int,
 	 @Primary_Prod_Id 	 Int,
 	 @Alternate_Prod_Id 	 Int,
 	 @CurrentProduct  	 Int,
 	 @Event_Prod_Id 	  	 Int,
 	 @Applied_Product 	 Int,
 	 @Alt_Spec 	  	 Int,
 	 @Prim_Spec 	  	 Int,
 	 @Event_Timestamp 	 Datetime,
 	 @Prop_Id 	  	 Int,
 	 @Char_Id 	  	 Int,
 	 @Primary_Prod_Code 	 nvarchar(25),
 	 @Alternate_Prod_Code 	 nvarchar(25),
 	 @Now 	  	  	 DateTime,
 	 @IntEvent 	  	 Int,
 	 @IsNumeric 	  	 Int,
 	 @sTempUnit 	  	 nvarchar(100),
 	 @TempUnit 	  	 Int
Declare @PathId Int
Select @Now = dbo.fnServer_CmnGetDate(GetUtcdate())
Select @PathId = Null,@Pu_Id = Null
Select @Pu_Id = Pu_Id from PrdExec_Inputs Where PEI_Id = @PEI_Id
Select @PathId from Prdexec_Path_Unit_Starts where PU_Id = @Pu_Id and End_Time is null
If @PathId is null
 	 select @Alt_Spec = Alternate_Spec_Id,@Prim_Spec = Primary_Spec_Id,@PU_Id = PU_Id
   	 From PrdExec_Inputs
   	 Where PEI_Id = @PEI_Id
Else
 	 select @Alt_Spec = Alternate_Spec_Id,@Prim_Spec = Primary_Spec_Id
   	 From PrdExec_Path_Inputs
   	 Where Path_Id  = @PathId
If @IsId = 1
  Begin
 	 Select @IsNumeric = Null
 	 Select @IsNumeric = Convert(int,value) From Site_Parameters where parm_Id = 75
 	 Select @IsNumeric = Coalesce(@IsNumeric,0)
 	 If  isnumeric(@Event) = 0 Or @IsNumeric = 1
 	    Select @IsId = 1
 	 Else
 	    Select @IsId = 0
  End
Select @IntEvent = Null
If @IsId = 0
BEGIN
 	 Select @IntEvent =  Convert(Int,@Event)
 	 If @IntEvent is null Return(2)
END
ELSE
BEGIN
 	 SELECT @IntEvent = Event_Id
 	  	 From Events
 	  	 Where Event_Num =  ltrim(rtrim(@Event)) and PU_Id in (Select PU_Id from PrdExec_Input_Sources Where PEI_Id = @PEI_Id)
 	 IF @IntEvent IS NULL
 	 BEGIN
 	  	 SELECT @sTempUnit = Value
 	  	  	 FROM Site_Parameters
 	  	  	 WHERE Parm_Id = 23
 	  	 SELECT @TempUnit = Null
 	  	 IF @sTempUnit != ''  AND @sTempUnit Is not Null
 	  	  	 SET @TempUnit = CONVERT(int,@sTempUnit)
 	  	 IF @TempUnit Is Not Null
 	  	 BEGIN
 	  	  	 SELECT @IntEvent = Event_Id
 	  	  	  	 FROM Events
 	  	  	  	 WHERE Event_Num =  ltrim(rtrim(@Event)) and PU_Id = @TempUnit
 	  	  	 IF @IntEvent Is Not Null
 	  	  	  	 RETURN(7)
 	  	 END
 	  	 RETURN(6)
 	 END
END
 If (select count(*) 
 	  	 From PrdExec_Input_Event  pie
 	  	 Join PrdExec_Inputs pis On pis.pei_Id = Pie.Pei_Id and pis.Lock_Inprogress_Input = 1
 	  	 Where Event_Id = @IntEvent) > 0
 	 Return(5)
Select @CurrentProduct = Prod_Id
 From Production_Starts ps
 Where pu_Id = @PU_Id and  ps.End_Time Is Null
if @CurrentProduct is null   Return(3)
If @Prim_Spec is not null
 Begin
   Select @Prop_Id = Prop_Id
     From Specifications
     Where Spec_Id = @Prim_Spec 
   Select @Char_Id = Null
   Select @Char_Id = Char_Id
     From  PU_Characteristics
     Where PU_Id  = @PU_Id And Prop_Id = @Prop_Id and Prod_Id = @CurrentProduct
   If @Char_Id is Null
     Select @Primary_Prod_Code = Null
   Else
     Select @Primary_Prod_Code = Target
      From Active_Specs
      Where Spec_Id  = @Prim_Spec and  Char_Id = @Char_Id
      and (Effective_Date < @Now and (Expiration_Date is null or Expiration_Date > @Now))
 End
else
  select @Primary_Prod_Code = Null
If @Alt_Spec is not null
 Begin
   Select @Prop_Id = Prop_Id
     From Specifications
     Where Spec_Id = @Alt_Spec 
   Select @Char_Id = Null
   Select @Char_Id = Char_Id
     From  PU_Characteristics
     Where PU_Id  = @PU_Id And Prop_Id = @Prop_Id and Prod_Id = @CurrentProduct
   If @Char_Id is null 
     Select @Alternate_Prod_Code = Null
   Else
     Select @Alternate_Prod_Code = Target
      From Active_Specs
      Where Spec_Id  = @Alt_Spec and  Char_Id = @Char_Id
      and (Effective_Date < @Now and (Expiration_Date is null or Expiration_Date > @Now))
 End
else
  select @Alternate_Prod_Code = Null
if @Primary_Prod_Code is not null 
 	 Select @Primary_Prod_Id = Prod_Id
 	  from Products where Prod_Code = @Primary_Prod_Code
else
 	 Select @Primary_Prod_Id = NULL
if @Alternate_Prod_Code is not null 
 	 Select @Alternate_Prod_Id = Prod_Id
 	  from Products where Prod_Code = @Alternate_Prod_Code
Else
 	 Select @Alternate_Prod_Id = Null
  Select @PU_Id = PU_Id ,@Status = Event_Status,@ReturnEventId = Event_Id,@Applied_Product = Applied_Product,@Event_Timestamp = timestamp
 	 From Events
 	 Where Event_Id =  @IntEvent
  Select @Event_PU = Null
  Select  @Event_PU = pis.pu_id
    From  PrdExec_Input_Sources pis
    Join  PrdExec_Input_Source_Data pisd on pisd.Valid_Status = @Status and pisd.PEIS_Id = pis.PEIS_Id
    where pis.PEI_Id = @PEI_Id and pis.PU_Id = @PU_Id
IF @Event_PU is Null 
 	 Return(2)   --invalid for unit
Else
  Begin
    If @Primary_Prod_Id is null and @Alternate_Prod_Id is null Return(1)  -- all product are valid
    Select @Event_Prod_Id = coalesce(@Applied_Product,Prod_Id)  
 	 From Production_Starts  s
 	 Where pu_id = @PU_Id and (Start_Time <= @Event_Timestamp and  (s.End_time > @Event_Timestamp or  s.End_time is null))
    If @Primary_Prod_Id is not null
      Begin
 	 If @Event_Prod_Id = @Primary_Prod_Id
 	   Return (1)
 	 Else
 	  if @Alternate_Prod_Id is not null
 	     If @Event_Prod_Id = @Alternate_Prod_Id
 	  	  Return (1)
 	     Else
 	  	 Return (4)
         Else
 	   Return (4)
      End
      Return(1)
  End
