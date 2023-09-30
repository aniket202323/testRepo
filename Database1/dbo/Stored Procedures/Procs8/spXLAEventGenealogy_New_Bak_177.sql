-- DESCRIPTION: spXLAEventGenealogy_New is derived from spXLAEventGenealogy. Changes Include:
-- (1) Input: Add Pu_Id as input to narrow down Event_Num. PrfXla.XLA will enforce Production Unit
-- (2) Output: returns Start_Time also and Events.Extended_Info. [MT/4-11-2002]
-- Defect 24177:Mt/8-5-2002: Exposing 8 additional fields, all from Event_Details
--     Initial_Dimension_X, Initial_Dimension_Y, Initial_Dimension_Z, Initial_Dimension_A, 
--     Final_Dimension_X, Final_Dimension_Y, Final_Dimension_Z, Final_Dimension_A 
CREATE PROCEDURE dbo.[spXLAEventGenealogy_New_Bak_177]
 	 @Event_Id 	  	 Int
 	 , @Pu_Id 	  	 Int
 	 , @Event_Num 	  	 VarChar(50)
 	 , @RelationSought 	 TinyInt = NULL 	 --1 = Child: 2 = Parent
 	 , @InTimeZone 	 varchar(200) = null
AS
DECLARE @Child 	 TinyInt
DECLARE @Parent TinyInt
SELECT @Child  = 1
SELECT @Parent = 2
--Set Default Values
If @RelationSought Is NULL SELECT @RelationSought = @Child
--Get Event_Id
If @Event_Id Is NULL
  BEGIN
    If @Pu_Id Is NULL
      SELECT @Event_Id = Event_Id FROM Events WHERE Event_Num = @Event_Num
    Else --@Pu_Id NOT NULL
      SELECT @Event_Id = Event_Id FROM Events WHERE Pu_Id = @Pu_Id AND Event_Num = @Event_Num
   --EndIf:@Pu_Id
  END
--EndIf
--NOTE: As of now (4-11-2002) most sites have NULL start_time in Events Table. Next Production Build (after 4-11-2002)
--      will ensure start_time is inserted.  The upgrade will offer optional one-time script update to Events Table so
--      that null start_time is filled with previous timeStamp. This one-time update is optional because it takes time
--      and disk space which customer may elect not to do. Without update start_time information will be incorrect, but
--      may not be an issue for some customers.  
--      Without one-time update, The row with null start_time will be replaced with 1 second before timeStamp (end_time).
-- Input Event_Id seeking its child/children
If @RelationSought = @Child
  BEGIN
    SELECT e.Event_Num
         , e.Event_Id
         , [Start_Time] = COALESCE(dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), DATEADD(ss, -1, dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)))
         , TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
         , Production_Unit = pu.Pu_Desc
         , Event_Type = 'Event'
         , Relationship = 'Child'
         , e.Extended_Info
         , ed.Initial_Dimension_X
         , ed.Initial_Dimension_Y
         , ed.Initial_Dimension_Z
         , ed.Initial_Dimension_A
         , ed.Final_Dimension_X
         , ed.Final_Dimension_Y
         , ed.Final_Dimension_Z
         , ed.Final_Dimension_A
      FROM Event_Components C
      JOIN Events e with(index(Events_PK_EventId)) ON e.Event_Id = C.Event_Id
      LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
      JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
     WHERE C.Source_Event_Id = @Event_Id
  END
--Input Event_Id seeking its parent
Else --@RelationSought = @Parent
  BEGIN
    SELECT e.Event_Num
         , e.Event_Id
         , [Start_Time] = COALESCE(dbo.fnServer_CmnConvertFromDbTime(e.Start_Time,@InTimeZone), DATEADD(ss, -1, dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)))
         , TimeStamp = dbo.fnServer_CmnConvertFromDbTime(e.TimeStamp,@InTimeZone)
         , Production_Unit = pu.Pu_Desc
 	  , Event_Type = 'Event'
         , Relationship = 'Parent'
         , e.Extended_Info
         , ed.Initial_Dimension_X
         , ed.Initial_Dimension_Y
         , ed.Initial_Dimension_Z
         , ed.Initial_Dimension_A
         , ed.Final_Dimension_X
         , ed.Final_Dimension_Y
         , ed.Final_Dimension_Z
         , ed.Final_Dimension_A
      FROM Event_Components C 
      JOIN Events e with(index(Events_PK_EventId)) on e.Event_Id = C.Source_Event_Id 
      LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
      JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
     WHERE C.Event_Id = @Event_Id
  END
--EndIf
