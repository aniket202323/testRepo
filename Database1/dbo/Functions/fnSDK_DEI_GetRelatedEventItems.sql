CREATE FUNCTION dbo.fnSDK_DEI_GetRelatedEventItems(
@PEI_Id int,
@StartTime datetime,
@EndTime datetime,
@ParentPU int,
@ParentEventId int,
@EventPU int,
@EventSubType int
)
returns @EventItems table
(
  ItemId int,
  ItemOrder int,
  ItemDisplayValue nvarchar(100),
  ItemValue nvarchar(100)
)
AS
begin
Declare @Now DateTime
Declare @LinkTime DateTime
Declare @PathId Int
Declare @Alt_Spec Int
Declare @Prim_Spec Int
Declare @Primary_Prod_Code Varchar(25)
Declare @Alternate_Prod_Code VarChar(25)
Declare @Primary_Prod_Id Int
Declare @Alternate_Prod_Id Int
Declare @Prop_Id Int
Declare @Char_Id Int
Declare @Prod_Id Int
Select @Now = dbo.fnServer_CmnGetDate(GetUtcdate())
Select @LinkTime = Coalesce(@EndTime, @StartTime, @Now)
Select @PathId = Path_Id
  from Prdexec_Path_Unit_Starts
  where PU_Id = @ParentPU and Start_Time <= @LinkTime and (End_Time is null or End_Time > @LinkTime)
If @PathId is null
 	 select @Prim_Spec = Primary_Spec_Id, @Alt_Spec = Alternate_Spec_Id
   	 From PrdExec_Inputs
   	 Where PEI_Id = @PEI_Id
Else
 	 select @Prim_Spec = Primary_Spec_Id, @Alt_Spec = Alternate_Spec_Id
   	 From PrdExec_Path_Inputs
   	 Where Path_Id  = @PathId
Select @Prod_Id = Prod_Id
  From Production_Starts
  Where PU_Id = @ParentPU and Start_Time <= @LinkTime and (End_Time is null or End_Time > @LinkTime)
If @Prim_Spec is not null
 Begin
   Select @Prop_Id = Prop_Id From Specifications Where Spec_Id = @Prim_Spec 
   Select @Char_Id = Null
   Select @Char_Id = Char_Id From PU_Characteristics Where PU_Id  = @ParentPU And Prop_Id = @Prop_Id and Prod_Id = @Prod_Id
   If @Char_Id is Null
     Select @Primary_Prod_Code = Null
   Else
     Select @Primary_Prod_Code = Target
       From Active_Specs
       Where Spec_Id  = @Prim_Spec and  Char_Id = @Char_Id and
             (Effective_Date < @LinkTime and (Expiration_Date is null or Expiration_Date > @LinkTime))
 End
else
  select @Primary_Prod_Code = Null
If @Alt_Spec is not null
 Begin
   Select @Prop_Id = Prop_Id From Specifications Where Spec_Id = @Alt_Spec 
   Select @Char_Id = Null
   Select @Char_Id = Char_Id From PU_Characteristics Where PU_Id  = @ParentPU And Prop_Id = @Prop_Id and Prod_Id = @Prod_Id
   If @Char_Id is null 
     Select @Alternate_Prod_Code = Null
   Else
     Select @Alternate_Prod_Code = Target
       From Active_Specs
       Where Spec_Id  = @Alt_Spec and  Char_Id = @Char_Id and
             (Effective_Date < @LinkTime and (Expiration_Date is null or Expiration_Date > @LinkTime))
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
insert into @EventItems
select  top 500 evt.Event_Id, DateDiff(second, evt.Timestamp, @Now), evt.Event_Num, evt.Event_Num
  from  Events evt
 	 left Join Events pe on pe.Event_Id = @ParentEventId
  left Join Production_Starts ps on ps.PU_Id = evt.PU_Id and ps.Start_Time <= pe.Timestamp and (ps.End_Time is null or ps.End_Time > pe.Timestamp)
  where evt.PU_Id = @EventPU and
        evt.Event_Status in (Select Valid_Status from PrdExec_Status where PU_Id = @EventPU) and
        evt.Event_Subtype_Id = @EventSubType and
        ((coalesce(@StartTime, @EndTime, pe.Timestamp) is null) or (evt.Timestamp >= coalesce(@StartTime, @EndTime, pe.Timestamp))) and
        ((@Primary_Prod_Id is null or coalesce(evt.Applied_Product, ps.Prod_Id) = @Primary_Prod_Id) or
         (@Alternate_Prod_Id is null or coalesce(evt.Applied_Product, ps.Prod_Id) = @Alternate_Prod_Id))
  order by evt.Timestamp desc
return
end
