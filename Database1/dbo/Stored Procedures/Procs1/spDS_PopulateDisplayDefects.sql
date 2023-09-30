CREATE Procedure dbo.spDS_PopulateDisplayDefects
 	 @EventId Int
As
Declare @ParentEvent Int
Select @ParentEvent = Source_Event_Id From Event_Components Where Event_Id = @EventId
If @ParentEvent is null
 	 Select @ParentEvent = @EventId
Declare @ParentLength 	 Real,
 	 @DefectId 	 Int,
 	 @Length 	  	 Real,
 	 @StartY 	  	 Real,
 	 @EndY 	  	 Real,
 	 @StartX 	  	 Real,
 	 @EndX 	  	 Real,
 	 @Ident 	  	 Int,
 	 @StartPos 	 Real,
 	 @EndPos 	  	 Real,
 	 @Event_Id 	 Int,
 	 @OldDefectId 	 Int,
 	 @OldEventID 	 Int,
 	 @SaveYStart 	 Real,
 	 @SaveYEnd 	 Real,
 	 @SaveXStart 	 Real,
 	 @SaveXEnd 	 Real,
 	 @OldEndX 	 Real,
 	 @OldEndY 	 Real,
 	 @Width 	  	 Real,
 	 @Orientation_Y 	 Real,
 	 @Orientation_X  Real
Select @ParentLength = ed.Final_Dimension_Y
 	 From Events e
 	 Join Event_Details ed On ed.Event_Id =  e.Event_Id
 	 Where e.Event_Id = @ParentEvent
Create Table #ChildDefects(Ident Int IDENTITY (1, 1) NOT NULL,Defect_Id int,TimeStamp DateTime,Event_Id Int,
 	  	  	    Final_Dimension_Y real,Orientation_Y Real Null,Final_Dimension_Z real,Orientation_X Real)
Create Table #Defects(Ident Int,Start_Y Real Null,End_Y Real Null,Event_Id Int,Start_X Real Null,End_X Real Null)
Create Table #ChildID(EventId Int)
INsert Into #ChildID Select Event_Id from Event_components 
where Source_Event_ID = @ParentEvent
Insert InTo #ChildDefects (Event_Id,TimeStamp,Final_Dimension_Y,Defect_Id,Orientation_Y,Final_Dimension_Z,Orientation_X)
 	 Select e.Event_Id,e.TimeStamp,ed.Final_Dimension_Y,dd.Defect_Detail_Id,ed2.Orientation_Y,ed.Final_Dimension_Z,ed2.Orientation_X
 	 From Events e 
 	 left Join Event_Details ed On ed.Event_Id =  e.Event_Id
 	 left Join Defect_Details dd With (Index (DefectDet_By_EventId)) on dd.Event_Id = @ParentEvent 
 	 Left Join Event_Details ed2 on ed2.event_Id = dd.Event_Id
 	 Where e.Event_Id  in ( Select EventId from #ChildID)
Drop table #ChildID
Select @OldDefectId = 0,@OldEventID = 0
Declare c Cursor For 
   Select Defect_Id,Final_Dimension_Y,Ident,Event_Id,Orientation_Y,Final_Dimension_Z,Orientation_X
     From #ChildDefects 
     Order by Defect_Id,TimeStamp
Open c
Loop:
Fetch Next From c into @DefectId,@Length,@Ident,@Event_Id,@Orientation_Y,@Width,@Orientation_X
IF @@Fetch_Status = 0
  Begin
        If @DefectId <> @OldDefectId
          Begin
 	     Select @StartPos = 0,@EndPos = 0
 	     Select @OldDefectId = @DefectId
            Select @StartY = d.Start_Coordinate_Y ,@EndY = d.Dimension_Y,@StartX = d.Start_Coordinate_X,@EndX = d.Dimension_X
 	       From Defect_Details d
              Where Defect_Detail_Id = @DefectId
 	     If @Orientation_Y <> 0 And @Orientation_Y is Not Null
 	      Begin
 	  	 Select @OldEndX = @EndX
 	  	 Select @EndX   = @Width - @StartX
 	  	 Select @StartX = @Width - @OldEndX
 	      End
 	     If @Orientation_X <> 0 And @Orientation_X is Not Null
 	      Begin
 	  	 Select @OldEndY = @EndY
 	  	 Select @EndY    = @ParentLength - @StartY
 	  	 Select @StartY  = @ParentLength - @OldEndY
 	         If @StartY < 0 
 	  	 Select @SaveYStart = 0
 	      Else
 	  	 Select @SaveYStart = @StartY - @StartPos
 	      If @EndY > @EndPos
 	  	 Select @SaveYEnd = @Length
 	      Else
 	         Select @SaveYEnd = @EndY - @StartPos
 	      End
          End
          Select @EndPos = @EndPos + @Length
          IF ((@StartY >= @StartPos) and  (@StartY < @EndPos)) 
 	      OR ((@EndY > @StartPos) and  (@EndY <= @EndPos)) 
 	      OR ((@StartY < @StartPos) and  (@EndY >= @EndPos))
 	     Begin
 	      Select @SaveXEnd =  @EndX
 	      Select @SaveXStart = @StartX
 	      If @StartY < @StartPos
 	  	 Select @SaveYStart = 0
 	      Else
 	  	 Select @SaveYStart = @StartY - @StartPos
 	      If @EndY > @EndPos
 	  	 Select @SaveYEnd = @Length
 	      Else
 	         Select @SaveYEnd = @EndY - @StartPos
 	         Insert InTo #Defects(Ident,Start_Y,End_Y,Event_Id,Start_X,End_X) Values (@Ident,@SaveYStart,@SaveYEnd,@Event_Id,@SaveXStart,@EndX)
            End
           Select @StartPos = @StartPos + @Length
    Goto Loop
  End
Close C
Deallocate C
Delete From #Defects Where Start_Y is null or End_Y is Null
If (Select count(*) from #Defects) > 0
Select Defect_Id,c.Event_Id,Final_Dimension_Y,Start_X ,End_X,Start_Y,End_Y
 from #ChildDefects c
 Join #Defects d on (d.Ident = c.Ident) and (c.Event_Id = d.Event_Id) 
 Where (Start_Y Is not null or End_Y Is not null) and  c.Event_Id = @EventId
Union
Select Defect_Id= Defect_Detail_Id,Event_Id,Final_Dimension_Y = 0,Start_X = Start_Coordinate_X,
 	 End_X = Dimension_X,Start_Y = Start_Coordinate_Y,End_Y = Dimension_Y
 from Defect_Details
 Where Event_Id = @EventId
Drop Table #ChildDefects
Drop Table #Defects
