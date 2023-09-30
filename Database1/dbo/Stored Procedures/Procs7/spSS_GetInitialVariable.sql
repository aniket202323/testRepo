Create Procedure dbo.spSS_GetInitialVariable
AS
 Declare @NoDataSource nVarChar(25),
         @NoSamplingType nVarChar(25),
         @NoEventType nVarChar(25),
         @NoPU nVarChar(25)
 Select @NoEventType = '<Any>'
 Select @NoDataSource = '<Any>'
 Select @NoSamplingType = '<Any>'
 Select @NoPU = '<Any Unit>'
---------------------------------------------------------
-- Defaults
--------------------------------------------------------
Select @NoDataSource as NoDataSource, @NoSamplingType as NoSamplingType, @NoPU as NoPU,@NoEventType as NoEventType
/*
----------------------------------------------------------
-- DisplayOptions
---------------------------------------------------------
Select Null as name
*/
-----------------------------------------------------------
-- PL, PU, PG for Treeview
-----------------------------------------------------------
 Create Table #PL (PL_Id int, PL_Desc  nVarChar(50))
 Insert Into #PL 
  Select PL_Id, PL_Desc
   From Prod_Lines
    Where PL_Id<>0
 Insert Into #PL
  Select 0, @NoPU
 Select * From #PL
  Order by PL_Desc
 Select PU.PL_Id, PU_Id, PU_Desc, Master_Unit
  From Prod_Units PU  
   Where PU_Id<>0
    Order by PU_Desc
 Select PG.PU_Id, PUG_Id, PUG_Desc
  From PU_Groups PG  
   Where PUG_Id<>0
    Order by PUG_Desc
-----------------------------------------------------------
-- Data Source
-----------------------------------------------------------
 Create Table #DataSource (Ds_Id int, Ds_Desc nVarChar(50))
 Insert Into #DataSource
  Select DS_Id, DS_Desc
   From Data_Source
 Insert Into #DataSource  
  Select 0, @NoDataSource
 Select * 
  From #DataSource 
   Order by DS_Desc
-----------------------------------------------------------
-- Sampling type
-----------------------------------------------------------
 Create Table #SamplingType (ST_Id int, ST_Desc nVarChar(50))
 Insert Into #SamplingType
  Select ST_Id, ST_Desc
   From Sampling_Type
 Insert Into #SamplingType
  Select 0, @NoSamplingType
 Select * 
  From #SamplingType
   Order by ST_Desc
-----------------------------------------------------------
-- Event Type
-----------------------------------------------------------
 Create Table #EventType (ET_Id int, ET_Desc nVarChar(50))
 Insert Into #EventType
  Select ET_Id, ET_Desc
  From Event_Types
 	 Where Variables_Assoc = 1
 Insert Into #EventType
  Select -1, @NoEventType
 Select * 
  From #EventType
   Order by ET_Desc
----------------------------------------------------------
-- drop temporary tables
---------------------------------------------------------
 drop table #EventType
 drop table #SamplingType
 drop table #DataSource
 drop table #PL
