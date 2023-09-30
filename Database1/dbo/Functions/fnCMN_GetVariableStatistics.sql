CREATE FUNCTION [dbo].[fnCMN_GetVariableStatistics](@StartTime DATETIME, @EndTime DATETIME, @Var_Id INT, @Prod_Id INT, @NonProductiveTimeFilter int)
RETURNS @StatTable TABLE (Cp FLOAT, Cpu FLOAT, Cpl FLOAT, Cpk FLOAT, Pp FLOAT, Ppu FLOAT, Ppl FLOAT, Ppk FLOAT, USL FLOAT, TGT FLOAT, LSL FLOAT, [MIN] FLOAT, MEAN FLOAT, MAX FLOAT)
AS
BEGIN
--**********************************************************************/
/*
Definitions:
RBar     = Mean Range or Average of Subgroup Ranges
XBar     = Mean of all observations or Average value of all samples
XDblBar  = Mean XBar or Average of Subgroups Means (averages)
S        = Standard Deviation
SBar     = Mean Standard Deviation or Average of Subgroup Deviations
MRBar    = Mean moving Range of length 2 or Average of ranges taken with a moving length of 2
           (Subgroup must be equal to 1)
Supporting Calculations For Determining Sigma
1=Automatic Method: (Method 2, 3 or 4 will be used based on the subgroup size)
2=MRBar Method: MRBar(2) / d2(2) if m = 1 (MRBar with a moving length of 2 divided by d2 with a subgroup size of 2)
3=RBar Method:  RBar / d2  if 2 <= m <= 25
4=SBar Method:  SBar / C4 if m > 25
5=Stdev Method: Taken from Pierburg Stdev(SubgroupMEANS)
*/
 	 ----------------------------------------------
 	 -- Local Variables
 	 ----------------------------------------------
 	 Declare @GroupSize int, @SiteCalculationMethod int
 	 Declare @Mod int  --Number of elements to remove from list based on GroupSize
 	 -- Table Variables
 	 Declare @VariableData Table (Id int IDENTITY (1, 1), Value decimal(19,6), Range decimal(19,6)) -- Holds Variable Data
 	 Declare @SubAverages Table (Id int IDENTITY (1, 1), [Count] int, Subgroup_Average FLOAT, Subgroup_Range decimal(19,6), Subgroup_Std_Dev FLOAT, D2 FLOAT, D3 FLOAT, C4 FLOAT, FValue FLOAT, HValue FLOAT)  -- Holds Grouped Variable Data After Cursor
 	 Declare @TempAverages Table (Id int IDENTITY (1, 1), Value FLOAT, Mean_Range FLOAT) -- Temp table used in cursor
 	 Declare @Sigma_Hat FLOAT, @R_Bar FLOAT, @D2 FLOAT, @D3 FLOAT, @C4 FLOAT, @S_Bar FLOAT, @X_DblBar FLOAT, @MRBar2 FLOAT, @Stdev_SubGroupAvg FLOAT
 	 Declare @USL FLOAT, @TGT FLOAT, @LSL FLOAT, @Mean decimal(19,6), @Min FLOAT, @Max FLOAT
 	 Declare @Pp FLOAT, @PpK FLOAT, @Ppu FLOAT, @Ppl FLOAT
 	 Declare @Cp FLOAT, @CpK FLOAT, @Cpu FLOAT, @Cpl FLOAT
 	 Declare @STDev FLOAT
 	 Declare @CPKMultiplier FLOAT
 	 Declare @SampleCount INT
 	 Declare @DistinctRows INT
 	 Declare @MaxId int, @SubId int, @SubGroupRowCount int
 	 Declare @AUTOMATIC_METHOD INT, @RBAR_METHOD INT, @SBAR_METHOD INT, @MRBAR_METHOD INT, @STDEV_METHOD INT
 	 SELECT  @AUTOMATIC_METHOD = 1, @RBAR_METHOD = 2, @SBAR_METHOD = 3, @MRBAR_METHOD = 4, @STDEV_METHOD = 5
 	 ----------------------------------------------
 	 -- Non-Productive Filter
 	 ----------------------------------------------
 	 If @NonProductiveTimeFilter Is Null
 	  	 select @NonProductiveTimeFilter = 0
 	 ----------------------------------------------
 	 -- Get The Site Calculation Method
 	 ----------------------------------------------
 	 Select @SiteCalculationMethod = @AUTOMATIC_METHOD
 	 ----------------------------------------------
 	 -- Get The Site CpK Multiplier
 	 -- Default = 3.0 Industry Standard
 	 ---------------------------------------------- 	 
 	 Select @CPKMultiplier = convert(FLOAT,Value) From Site_Parameters Where Parm_Id = 152
 	 If @CPKMultiplier is Null 
 	  	 Select @CPKMultiplier = 3.0
 	 ----------------------------------------------
 	 -- Get The GroupSize for this Variable
 	 -- Default = 1
 	 ----------------------------------------------
 	 Select @GroupSize = Coalesce(CpK_Subgroup_Size, 1) From Variables Where Var_Id = @Var_Id
 	 ----------------------------------------------
 	 -- Get the variable Data
 	 ----------------------------------------------
 	 Declare @Unit int
 	 select @Unit = PU_ID From Variables Where Var_id = @Var_Id
 	 
 	 ----------------------------------------------
 	 -- Filter Production Starts to get correct 
 	 -- start and stop times for product run
 	 ----------------------------------------------
 	 Declare @ProductionStarts Table (Start_Time datetime, End_Time datetime, Prod_Id int, PU_ID int)
 	 insert into @ProductionStarts(Start_Time, End_Time, Prod_Id, PU_ID)
 	 select 
 	  	 [Start_Time] = Case When ps.Start_Time < @StartTime Then @StartTime Else ps.Start_Time End,
 	  	 [End_Time] = Case When ps.End_Time Is Null Then @EndTime
 	  	  	  	  	  	   When ps.End_Time > @EndTime Then @EndTime
 	  	  	  	  	  	   Else ps.End_Time END,
 	 prod_Id, PU_ID
 	 from production_Starts ps
 	 where ps.PU_ID=@Unit
 	 AND ps.prod_Id=@Prod_id
 	 AND 
 	 (
 	  	  	 (ps.Start_Time >= @StartTime AND (ps.Start_Time < @EndTime))
 	  	 or
 	  	  	 (ps.Start_Time <= @StartTime AND ((ps.End_Time > @StartTime) or ps.End_Time Is Null))
 	 )
 	 Insert into @VariableData(Value)
 	  	 Select Result 
 	  	 From tests_npt t
 	  	 join @ProductionStarts ps on ps.pu_id = @Unit 
 	  	 where var_id = @Var_Id 
 	  	 and result_On > ps.STart_Time and Result_On <= ps.End_Time
 	  	 and (@NonProductiveTimeFilter = 0 or t.Is_Non_Productive = 0) 
 	 ----------------------------------------------
 	 -- Determine Grouping 
 	 -- Check for Non-Uniform Groups
 	 ----------------------------------------------
 	 Select @SampleCount = count(*) from @VariableData 	    -- How many sample values
 	 
 	 -- If GroupSize > 1 then there must be at least 2 complete SubGroups
 	 -- If there is only 1 complete subgroup then MRBar must be used
 	 If (@SampleCount / @GroupSize) = 1
 	  	 Select @GroupSize = 1
 	 Select @mod = @SampleCount % @GroupSize  -- How many values are not part of a complete sub-group
 	 Select @MaxId=Max(Id) From @VariableData -- What is the last value in the result set
 	 ----------------------------------------------
 	 -- Get the upper and lower spec limits from
 	 -- Var_Specs Table
 	 ----------------------------------------------
 	 select top 1 @LSL=L_Reject, @Tgt=Target, @USL=U_Reject
 	 from var_specs d
 	 where var_id = @Var_id and Prod_Id = @Prod_Id
 	 and (
 	  	  	 ((d.Effective_Date between @StartTime and @EndTime )and d.Expiration_Date >= @EndTime)
 	  	  	 or  	  	 
 	  	  	 (d.Effective_Date >= @StartTime and d.Expiration_Date <= @EndTime)
 	  	  	 or
 	  	  	 (d.Effective_Date <= @StartTime and d.Expiration_Date >= @EndTime)
 	  	  	 or
 	  	  	 (d.Effective_Date <= @StartTime and (d.Expiration_Date between @StartTime and @EndTime))
 	  	  	 or
 	  	  	 (d.Effective_Date <= @StartTime and d.Expiration_Date is null)
 	  	  	 or
 	  	  	 ((d.Effective_Date between @StartTime and @EndTime) and d.Expiration_Date is Null) 	  	 
 	 )
 	 order by effective_date desc
 	 ----------------------------------------------
 	 -- Calculate Min, Mean, Max
 	 ----------------------------------------------
 	 Select @Max = max(value), @Min = min(value), @Mean = Avg(value) from @VariableData
 	 ----------------------------------------------
 	 -- If No Specs Exist then use the min and max 
 	 -- from the result set
 	 ----------------------------------------------
/*
 	 Print ''
 	 Print '====!!!! change logic around LSL and USL equal null !!!!===='
 	 Print ''
 	 -- This is for testing purposes only.
 	 If @LSL Is Null
 	  	 Select @LSL = @Min
 	 If @USL Is Null
 	  	 Select @USL = @Max
--*/
 	 
 	 ----------------------------------------------
 	 -- Failure Modes - No Spec Limits Defined
 	 ----------------------------------------------
 	 If (@LSL Is Null) and (@USL Is Null)
 	  	 GoTo RETURN_RESULTS
 	 ----------------------------------------------
 	 -- Get Pp (Overall LT Capability)
 	 -- Bhaskar: The cases that @USL = NULL or @LSL = NULL need to be checked before calculating Pp etc ?
 	 -- @Mean, I guess, would be non-NULL because all values in @VariableData is non-NULL, correct?
 	 -- Dan: If either @USL or @LSL are NULL, that equation will not be performed.  This means
 	 -- If @USL is NULL then @Pp and @Ppu will be NULL
 	 -- However, if data count is 1, stdev will be 0, that should be checked.
 	 -- Dan: There must be a minimum of 3 values in the result set else NULL is returned
 	 -- Basically data count = 1 implies inadequate data, return error/unavailable Pp etc.
 	 -- Dan: This is handled above
 	 -- ECR #32776 
 	 -- Pp, Ppu, Ppl, Ppk should be calculated using all samples
 	 -- Cp, Cpu, Cpl, Cpk should be calculated after grouping and padding
 	 ----------------------------------------------
    -- ECR #21459 Avodind Divide by Zero error
 	 Select 
  	  	  	   @Pp = case when (6*(CAST(Stdev(value) as decimal(19,8)))) = 0 Then 0 Else (@USL - @LSL) / (6*Stdev(value)) End,
   	      	   --@Pp = case when (6*(CAST(Stdev(value) as decimal(19,8))) = 0 Then 0 Else (@USL - @LSL) / (6*Stdev(value)) End, 
   	      	   @Ppu = case when (3*(CAST(Stdev(value) as decimal(19,8))))= 0 Then 0 Else (@USL - @Mean) / (3*Stdev(Value))End,
   	      	   @Ppl = case when (3*(CAST(Stdev(value) as decimal(19,8))))= 0 Then 0 Else (@Mean - @LSL) / (3*Stdev(Value))End 
   	   From @VariableData
 	 
--    Select 
-- 	  	 @Pp = (@USL - @LSL) / (6*Stdev(value)), 
-- 	  	 @Ppu = (@USL - @Mean) / (3*Stdev(Value)),
-- 	  	 @Ppl = (@Mean - @LSL) / (3*Stdev(Value))
-- 	 From @VariableData
 	 ----------------------------------------------
 	 -- Failure Modes
 	 ----------------------------------------------
 	 If (@Ppu Is Null) and (@Ppl Is Not Null)
 	  	 Select @PpK = @Ppl
 	 Else If (@Ppu Is Not Null) and (@Ppl Is Null)
 	  	 Select @PpK = @Ppu
 	 Else
 	  	 Select @PpK = Case when @Ppu < @Ppl Then @Ppu Else @Ppl End
 	 ----------------------------------------------
 	 -- Cannot mix groups of size 1 with any other size
 	 -- Bhaskar: if number of samples > 1 and last subgroup size is 1, it deletes last sample data.
 	 -- This is not correct because,
 	 -- 1) if subgroup size is 1, then last subgroup is valid
 	 -- 2) if Subgroup size > 1 and last subgroup size = 1, but there may be only 2 subgroups, so last sample shouldn't be discarded
 	 -- Dan: If Subgroup size = 1 then @Mod will always = 0 and this code will not be executed
 	 --      Code will have to prepare for swithing to MRBar with SubGroup=1
 	 --      See above code for switching to MRBar when only 1 subgroup is present.
 	 ----------------------------------------------
 	 If (Select Count(*) From @VariableData) > 1 and (@Mod = 1)
 	  	 Begin
 	  	  	 /*
 	  	  	 If there is one complete subgroup and 1 additional value then change subgroup size=1 and use MR Bar
 	  	  	 Else if there is more than 1 complete subgroup and 1 additional value, drop the 1 value and continue
 	  	  	 */
 	  	  	 Delete From @VariableData where Id = @MaxId
 	  	  	 select @mod = Count(*) % @GroupSize from @VariableData
 	  	 End
 	 
 	 ----------------------------------------------
 	 -- Failure Mode - Inadequate Data
 	 ----------------------------------------------
 	 if (Select Count(*) From @VariableData) < 3
 	  	 GoTo RETURN_RESULTS
 	 
 	 Select @Stdev = StDev(value) From @VariableData
 	 If @Stdev = 0
 	  	 GoTo RETURN_RESULTS  -- This implies no change in the process
 	 If @Stdev < .000000000000001
 	  	 GoTo RETURN_RESULTS 	  -- This implies almost no change in the process
 	 ----------------------------------------------
 	 -- Pad Non-Uniform Sub-groups with NULL
 	 ----------------------------------------------
 	 Declare @Loop int, @Count int
 	 If @Mod > 0
 	  	 Begin
 	  	  	 Select @Loop = @GroupSize-@Mod, @Count=0
 	  	  	 While @Count < @Loop
 	  	  	  	 Begin
 	  	  	  	  	 insert into @variabledata(value) values(null)
 	  	  	  	  	 Select @Count = @Count + 1
 	  	  	  	 End
 	  	 End
 	 ----------------------------------------------
 	 -- Calculate Range and Standard Deviation
 	 -- For Each SubGroup
 	 ----------------------------------------------
 	 Declare @ID int, @Value FLOAT, @PrevValue FLOAT, @TempGroupSize Int
 	 
 	 Declare MyCursor CURSOR
 	   For ( Select Id, Value From @VariableData )
 	   For Read Only
 	   Open MyCursor  
 	   Fetch Next From MyCursor Into @ID, @value 
 	   While (@@Fetch_Status = 0)
 	  	 Begin
 	  	  	 --------------------------------------------
 	  	  	 -- Calculate Moving Range With Length = 2
 	  	  	 --------------------------------------------
 	  	  	 if @PrevValue Is Not Null
 	  	  	  	 Begin
 	  	  	  	  	 If @PrevValue > @Value
 	  	  	  	  	  	 Update @VariableData Set Range = @PrevValue - @Value Where Id = @Id
 	  	  	  	  	 Else
 	  	  	  	  	  	 Update @VariableData Set Range = @Value - @PrevValue Where Id = @Id
 	  	  	  	 End
 	  	  	 Select @PrevValue = @Value
 	  	  	 --------------------------------------------
 	  	  	 -- Add another element to the subgroup
 	  	  	 --------------------------------------------
 	  	  	 Insert Into @TempAverages(Value) Values(@Value)
 	  	  	 
 	  	  	 --------------------------------------------
 	  	  	 -- If there is a complete sub-group
 	  	  	 -- Bhaskar: Where do we calculate the stuff for the last subgroup when "Count(*) From @TempAverages < @GroupSize"?
 	  	  	 -- Dan: In this case, the table @TempAverages is padded with enough NULL values to make a complete subgroup.
 	  	  	 --      When the subgroup values are calculated, the NULL values are eliminated by sql and Count(*) becomes
 	  	  	 --      the number of Non-NULL values.
 	  	  	 --------------------------------------------
 	  	  	 If (Select Count(*) From @TempAverages) = @GroupSize
 	  	  	  	 Begin
 	  	  	  	  	 Insert Into @SubAverages([Count], Subgroup_Average, Subgroup_Range, Subgroup_Std_Dev) 
 	  	  	  	  	  	 (Select Count(*), Avg(Value), Max(Value) - Min(Value), Stdev(Value) From @TempAverages where value is not null)
 	  	  	  	  	 Select @SubId = Scope_Identity()
 	  	  	  	  	 Select @SubGroupRowCount = [Count] From @SubAverages where Id = @SubId
 	  	  	  	  	 If @GroupSize > 1
 	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	 Update @SubAverages SET
 	  	  	  	  	  	  	  	 D2 = dbo.fnCMN_SampleSizeLookUp(@SubGroupRowCount, 'D2'),
 	  	  	  	  	  	  	  	 D3 = dbo.fnCMN_SampleSizeLookUp(@SubGroupRowCount, 'D3'),
 	  	  	  	  	  	  	  	 C4 = dbo.fnCMN_SampleSizeLookUp(@SubGroupRowCount, 'C4')
 	  	  	  	  	  	  	 Where ID = @SubId
 	  	  	  	  	  	  	 Update @SubAverages SET
 	  	  	  	  	  	  	  	 FValue = (D2 * D2) / (D3 * D3),
 	  	  	  	  	  	  	  	 HValue = (C4 * C4) / (1 - (C4 * C4))
 	  	  	  	  	  	  	 Where ID = @SubID
 	  	  	  	  	  	 End
 	  	  	  	  	 Delete From @TempAverages
 	  	  	  	 End
 	  	  	 Fetch Next From MyCursor Into @ID, @value 
 	  	 End 
 	 Close MyCursor
 	 Deallocate MyCursor
 	 --------------------------------------------
 	 -- Check for SubGroups of different size
 	 --------------------------------------------
 	 Declare @T Table(Id int) 	 
 	 Insert Into @T
 	 Select Distinct [Count] From @SubAverages
 	 Select @DistinctRows = Count(*) From @T
 	 --------------------------------------------
 	 -- If there is only 1 SubGroup Then
 	 -- Use MRBar Method
 	 -- Bhaskar: There is another case where we use @MRBar2
 	 --     number of subgroups = 2, last one is of size 1
 	 -- Dan: this is handled above.  Subgroups of size 1 are not allowed.
 	 --      The single value would have been deleted
 	 --------------------------------------------
 	 If (Select Count(*) From @SubAverages) = 1
 	  	 Select @GroupSize=1
 	 ----------------------------------------------
 	 -- Calculate Moving Range Length=2
 	 ----------------------------------------------
 	 Select @MRBar2 = Avg(Range) From @VariableData
 	 ----------------------------------------------
 	 -- Calculate R-Bar, X-DblBar, S-Bar
 	 ----------------------------------------------
 	 Select   
 	  	 @X_DblBar=Avg(Subgroup_Average),  
 	  	 @R_Bar=Avg(Subgroup_Range),      
 	  	 @S_Bar=Avg(Subgroup_Std_Dev),
 	  	 @Stdev_SubGroupAvg = Stdev(Subgroup_Average)
 	 From @SubAverages
 	 ----------------------------------------------
 	 -- Determine Calculation Method
 	 ----------------------------------------------
 	 If @GroupSize=1 GoTo MRBAR_METHOD
 	 ELSE If @GroupSize Between 2 and 25 GoTo RBAR_METHOD
 	 ELSE GoTo SBAR_METHOD
MRBAR_METHOD:
 	 -- This is for SubGroups = 1
 	 If @GroupSize Between 2 and 25 GoTo RBAR_METHOD
 	 If @GroupSize > 25 Goto SBAR_METHOD
-- 	 Print '==================='
-- 	 Print 'Using MR_BAR_METHOD'
-- 	 Print '==================='
 	 
 	 -- Bhaskar: if sample size < 3, it implies inadequate data return error
 	 -- Dan: this is handled above
 	 Select @Sigma_Hat = @MRBar2 / dbo.fnCMN_SampleSizeLookUp(2, 'D2')
 	 GoTo CALCULATE_CPK
RBAR_METHOD:
 	 -- This is for SubGroups between 2 and 25
 	 If @GroupSize = 1 GoTo MRBAR_METHOD
-- 	 Print '================='
-- 	 Print 'Using RBAR_METHOD'
-- 	 Print '================='
 	 if @DistinctRows = 1
 	  	 Begin
-- 	  	  	 Print 'Uniform SubGroups -> RBar / D2(' + convert(nVarChar(2), @GroupSize) + ')'
 	  	  	 Select @Sigma_Hat = @R_Bar / dbo.fnCMN_SampleSizeLookUp(@GroupSize, 'D2')
 	  	 End
 	 Else
 	  	 Begin
-- 	  	  	 Print 'Non-Uniform SubGroups -> Weighted RBar'
 	  	  	 Select @Sigma_Hat = Sum (FValue * SubGroup_Range / D2) / Sum(FValue) From @SubAverages
 	  	 End
 	 GoTo CALCULATE_CPK
SBAR_METHOD:
 	 -- This is for SubGroups greater than 25
 	 If @GroupSize = 1 GoTo MRBAR_METHOD
-- 	 Print '================='
-- 	 Print 'Using SBAR_METHOD'
-- 	 Print '================='
 	 if @DistinctRows = 1
 	  	 Begin
 	  	  	 --Print 'Uniform SubGroups -> SBar / C4(' + convert(nVarChar(2), @GroupSize) + ')'
 	  	  	 Select @Sigma_Hat = @S_Bar / dbo.fnCMN_SampleSizeLookUp(@GroupSize, 'C4')
 	  	 End
 	 Else
 	  	 Begin
 	  	  	 --Print 'Non-Uniform SubGroups'
 	  	  	 Select @Sigma_Hat = Sum(HValue * Subgroup_Std_Dev / C4) / Sum(HValue) From @SubAverages
 	  	 End
 	 GoTo CALCULATE_CPK
STDEV_METHOD:
 	 -- This method will no longer be used
 	 -- StDev(SubGroupMeans)
-- 	 Print 'STDEV_METHOD'
 	 Select @Sigma_Hat = @Stdev_SubGroupAvg
 	 GoTo CALCULATE_CPK
CALCULATE_CPK:
 	 ----------------------------------------------
 	 -- Get Cp (Potential ST Capability)
 	 -- Sigma Hat = StDev (ST) in MiniTab
 	 -- Bhaskar: Check if @Sigma_Hat is zero
 	 -- Dan: Done
 	 ----------------------------------------------
 	 If @Sigma_Hat=0
 	  	 Goto RETURN_RESULTS
 	 Select @Cp = (@USL - @LSL) / (6 * @Sigma_Hat)
 	 Select @Cpu = (@USL - @X_DblBar) /  (@CPKMultiplier * @Sigma_Hat)
 	 Select @Cpl = (@X_DblBar - @LSL) / (@CPKMultiplier * @Sigma_Hat)
 	 ----------------------------------------------
 	 -- Failure Modes
 	 ----------------------------------------------
 	 If (@Cpu Is Null) and (@Cpl Is Not Null)
 	  	 Select @CpK = @Cpl
 	 Else If (@Cpu Is Not Null) and (@Cpl Is Null)
 	  	 Select @CpK = @Cpu
 	 Else
 	  	 Select @CpK = Case when @Cpu < @Cpl Then @Cpu Else @Cpl End
RETURN_RESULTS:
 	 ----------------------------------------------
 	 -- Return Results
 	 ----------------------------------------------
 	 INSERT @StatTable
 	 Select @Cp [Cp], @Cpu [Cpu], @Cpl [Cpl], @Cpk [CpK], @Pp [Pp], @Ppu [Ppu], @Ppl [Ppl], @Ppk [Ppk], @LSL, @TGT, @USL, @Min, @Mean, @Max
-- Bhaskar: so we are returning NULL Cp, Pp etc. in case it fails to calculate them, correct?
/*
select * from @StatTable
--select * from @subaverages
--select @S_Bar [S_Bar], @X_DblBar [X_DblBar], @CPKMultiplier [CPKMultiplier], @GroupSize [GroupSize],@SampleCount [SampleCount], @Sigma_Hat [Sigma_Hat]
--**********************/
--/*******************************************************
RETURN
END
