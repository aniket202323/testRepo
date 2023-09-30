Create Procedure dbo.spDS_GetDefectData
  @EventId Int
 AS
Declare @Prompt 	  	 nVarChar(50),
 	 @DimZEU 	  	 nVarChar(50),
 	 @DimYEU  	 nVarChar(50),
        @PU_Id 	  	 Int,
 	 @CurrentEvent 	 Int,
 	 @NewEvent 	 Int,
 	 @StartPos 	 Float,
 	 @EndPos 	  	 Float,
 	 @GeneOrder 	 Int
Create Table #Genealogy(Event_Id 	  	 Int,
 	  	  	 Event_Num  	  	 nVarChar(50),
 	  	  	 PU_Id 	  	  	 Int,
 	  	  	 Final_Dimension_Z  	 Float Null,
 	  	  	 Final_Dimension_Y  	 Float Null,
 	  	  	 Gene_Order 	  	 Int )
Create Table #DefectTable(Defect_Detail_Id 	 Int,
 	  	  	   Event_Id  	  	 Int,
 	  	  	   Final_Dimension_Y  	 Float,
 	  	  	   Start_X  	  	 Float Null,
 	  	  	   End_X  	  	 Float Null,
 	  	  	   Start_Y  	  	 Float Null,
 	  	  	   End_Y  	  	 Float Null)
Select @PU_Id = Coalesce(pu.Master_Unit,pu.PU_Id)
  From Events e
  Join Prod_Units pu On pu.PU_Id = e.PU_Id
  Where e.Event_Id = @EventId
Select @Prompt =Event_Subtype_Desc ,@DimZEU = Dimension_Z_Eng_Units,@DimYEU = Dimension_Y_Eng_Units
  From Event_Configuration ec
  Join Event_SubTypes es on es.Event_Subtype_Id = ec.Event_Subtype_Id
  Where ec.pu_Id = @PU_Id and Is_Active = 1 and ec.ET_Id = 1
If @DimZEU is null 
  Select @DimZEU = 'mm'
If @DimYEU Is Null
  Select @DimYEU ='Meters'
If @Prompt Is Null
 Select  @Prompt = dbo.fnDBTranslate(N'0',13048,'Item #')
Select Defect_Name,Defect_Type_Id 
  From Defect_Types
  Order By Defect_Name
-- Labels 
Select Prompt = @Prompt,DimZLabel = @DimZEU,DimYLabel = @DimYEU
-- Event Numbers
Select @CurrentEvent = @EventId
Select @StartPos = Coalesce(Dimension_Z,0)
   From Event_Components 
   Where Event_Id = @EventId
Select @EndPos = Coalesce(Final_Dimension_Z,0) + @StartPos
 	 From Event_Details
 	 Where Event_Id = @EventId
Select @GeneOrder = 1
GeneLoop:
Insert Into #Genealogy(Event_Num,Event_Id,Final_Dimension_Z,Final_Dimension_Y,PU_Id,Gene_Order)
  Select e.Event_Num,e.Event_Id,Coalesce(ed.Final_Dimension_Z,0),
 	 Coalesce(ed.Final_Dimension_Y,0),e.PU_Id,@GeneOrder
   From Events e
   Left Join Event_Details ed on ed.Event_Id = e.Event_Id
   Where e.Event_Id = @CurrentEvent
  Select @NewEvent = Null
  Select @NewEvent = Source_Event_Id
   From  Event_Components 
   Where Event_Id = @CurrentEvent
If @NewEvent Is Not Null
  Begin
    Select @CurrentEvent = @NewEvent
    Select @GeneOrder = @GeneOrder + 1
    Goto GeneLoop
  End
-- Get Defect Data
Declare gCursor Cursor 
  For Select Distinct Event_Id From #Genealogy
Open gcursor
gLoop:
Fetch Next From gCursor into @NewEvent
If @@Fetch_Status = 0
  Begin
    Insert Into #DefectTable Execute spDS_PopulateDisplayDefects @NewEvent
--    Select @NewEvent
--    select * from #DefectTable
    Goto gLoop
  End
close gCursor
deallocate gCursor
Delete From #DefectTable 
 Where Start_X  > @EndPos or End_X < @StartPos
Select g.Event_Id,
 	 g.PU_Id,
 	 g.Event_Num,
 	 g.Final_Dimension_Z,
 	 g.Final_Dimension_Y,
 	 dd.Defect_Detail_Id,
 	 dd.Start_Coordinate_X,
 	 dd.Dimension_X,
 	 dd.Start_Coordinate_Y,
 	 dd.Dimension_Y,
 	 dd.Defect_Type_Id,
 	 Locked = 0,
 	 Severity = Coalesce(dd.Severity,0),
 	 g.Gene_Order
   From  #Genealogy g
   Left Join Defect_Details dd On dd.Event_Id = g.Event_Id
   Order by g.Gene_Order desc
