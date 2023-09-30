CREATE PROCEDURE dbo.spRHMasterUnitInfo
@PU_Id int
AS
set nocount on
--
Declare @PE_Association int
Declare @Def_Destination int
Declare @Def_Source int
Declare @TempUnit int
--
--
--
select @PE_Association = Production_Event_Association,
       @Def_Destination = Def_Production_Dest,
       @Def_Source = Def_Production_Src
  from Prod_Units
  where PU_Id = @PU_Id
--
--
--Return Unit Specific Information
--
--
Select PE_Assn = @PE_Association,
       Def_Dest = @Def_Destination,
       Def_Src = @Def_Source
--
--
--Return List With All Master Units Related By Source and Destination
--
--
Create Table #PUs (PU_Id int, Is_Primary int NULL, Level_Count int NULL)
Create Table #SearchPUs (PU_Id int)
Declare @LevelCount int
Insert Into #PUs (PU_id) Values (@PU_Id)
--Go Through Tradiational Way To Get Unit Information
--
Select @TempUnit = @Def_Source
--
-- Chain Up Source
--
SourceLoop:
--   
  If (@TempUnit Is Not Null)
    Begin
      Insert Into #PUs (PU_Id) Values (@TempUnit)
      Select @TempUnit = Def_Production_Src
        From Prod_Units 
        Where PU_Id = @TempUnit
      Goto SourceLoop
    End    
--
--
-- Chain Down Destination
--
Select @TempUnit = @Def_Destination
--
--
Select @LevelCount = 1
DestLoop:
--
  If (@TempUnit Is Not Null)
    Begin
      If @LevelCount = 1 
        Insert Into #PUs (PU_Id, Is_Primary) Values (@TempUnit, 1) 
      Else
        Insert Into #PUs (PU_Id) Values (@TempUnit) 
      Select @TempUnit = Def_Production_Dest
        From Prod_Units 
        Where PU_Id = @TempUnit
      Select @LevelCount = @LevelCount + 1
      Goto DestLoop
    End    
--
--
-- Insert Anything That Has Source Of Destination And Not Already In Table
--
--
Insert Into #PUs (PU_Id)
  Select PU_Id From Prod_Units
  Where (Def_Production_Src = @Def_Destination) And
        (PU_Id Not In (Select PU_Id From #PUs)) 
--
--
-- Now Add Stuff From Production Execution Path Definition
-- First Search Forward
--
Select @LevelCount = 1
Insert Into #SearchPUs (PU_Id) Values (@PU_Id)
ForwardLoop:
Insert Into #PUs (PU_Id, Is_Primary, Level_Count)
  Select Distinct pxis.PU_Id, Case When @LevelCount = 1 Then 1 else Null End, @LevelCount 
    From PrdExec_Inputs pxi
    Join PrdExec_Input_Sources pxis on pxis.PEI_Id = pxi.PEI_Id
    Where (pxi.PU_Id In (Select PU_Id From #SearchPUs)) and
          (pxis.PU_Id Not In (Select PU_Id From #PUs)) 
Delete From #SearchPUs
Insert into #SearchPUs (PU_Id)
  Select PU_Id From #PUs Where Level_Count = @LevelCount
If (Select Count(PU_Id) From #SearchPUs) > 0 and @LevelCount <= 20
  Begin
    Select @LevelCount = @LevelCount + 1 
    Goto ForwardLoop
  End
Delete From #SearchPUs
Update #PUs set Level_Count = NULL
--
-- Now Search Backward
--
Select @LevelCount = 1
Insert Into #SearchPUs (PU_Id) Values (@PU_Id)
BackwardLoop:
Insert Into #PUs (PU_Id, Is_Primary, Level_Count)
  Select Distinct pxi.PU_Id, Null, @LevelCount 
  From PrdExec_Input_Sources pxis
  Join PrdExec_Inputs pxi on pxi.PEI_Id = pxis.PEI_Id
  Where (pxis.PU_Id In (Select PU_Id From #SearchPUs)) and
        (pxi.PU_Id Not In (Select PU_Id From #PUs)) 
Delete From #SearchPUs
Insert into #SearchPUs (PU_Id)
  Select PU_Id From #PUs Where Level_Count = @LevelCount
If (Select Count(PU_Id) From #SearchPus) > 0 and @LevelCount <= 20
  Begin
    Select @LevelCount = @LevelCount + 1 
    Goto BackwardLoop
  End
--
-- Return Results
--
Select PU_Id, 
           Is_Primary = Case When Is_Primary Is Null Then 0 Else Is_Primary End 
 from #PUs
--
--
--Return Production Calculation Variables For All Related Units
--
--
select v.Var_Id, v.PU_Id, v.ProdCalc_Type
  From Variables v
  Join Prod_Units p on p.PU_Id = v.PU_Id
  Where v.ProdCalc_Type Is Not Null and
        (
         (p.PU_Id in (Select PU_Id From #PUs)) or
         (p.Master_Unit in (Select PU_Id From #PUs))
        )
--  Where (((PU_Id = @PU_Id) or (PU_Id = (Select Master_Unit From Prod_Units Where PU_Id = @PU_Id))) OR 
--        ((PU_Id = @Def_Destination) or (PU_Id = (Select Master_Unit From Prod_Units Where PU_Id = @Def_Destination)))) AND
--        (ProdCalc_Type Is Not Null)
Drop Table #PUs
Drop Table #SearchPUs
