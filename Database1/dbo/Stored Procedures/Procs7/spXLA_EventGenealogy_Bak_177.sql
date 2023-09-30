-- DESCRIPTION: spXLA_EventGenealogy is derived from spXLAEventGenealogy_New. ECR #25046(mt/5-27-2003) Changes to include
-- more fields from Event_Components table
CREATE PROCEDURE dbo.[spXLA_EventGenealogy_Bak_177]
 	 @Event_Id 	  	 Int
 	 , @Event_Num 	  	 VarChar(50)
 	 , @Pu_Id 	  	 Int             -- needed to guarantee correct Event_Num (as it is not unique across all PU_Id)
 	 , @RelationSought 	 TinyInt = NULL 	 --1 = Child: 2 = Parent
 	 , @InTimeZone 	 varchar(200) = null
AS
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
DECLARE @Child 	                    TinyInt
DECLARE @Parent                    TinyInt
DECLARE @Row_Count                 Int
DECLARE @ReturnStatus              Int
DECLARE @Duplicate_Event_Num_Found Int
SELECT @Child  = 1
SELECT @Parent = 2
SELECT @Row_Count = 0
SELECT @Duplicate_Event_Num_Found = -500
--Set Default Values
If @RelationSought Is NULL SELECT @RelationSought = @Child
-- If we don't have Event_Id, get the right event from @Event_Num and @PU_Id
If @Event_Id Is NULL
  BEGIN
    If @Pu_Id Is NOT NULL
      BEGIN 
        SELECT @Event_Id = Event_Id FROM Events WHERE Pu_Id = @Pu_Id AND Event_Num = @Event_Num 
      END
    Else --@Pu_Id NULL (we should not get this if caller is ProficyAddIn(Client) as it prevents Event_Num without PU_Id)
      BEGIN
        SELECT @Event_Id = Event_Id FROM Events WHERE Event_Num = @Event_Num
        SELECT @Row_Count = @@ROWCOUNT
        If @Row_Count > 1 
          BEGIN
            SELECT @ReturnStatus = @Duplicate_Event_Num_Found
            RETURN
          END
        --EndIf:@Row_Count > 1
      END      
   --EndIf:@Pu_Id
  END
--EndIf:@Event_Id Is NULL
--NOTE: As of now (4-11-2002) most sites have NULL start_time in Events Table. Next Production Build (after 4-11-2002)
--      will ensure start_time is inserted.  The upgrade will offer optional one-time script update to Events Table so
--      that null start_time is filled with previous timeStamp. This one-time update is optional because it takes time
--      and disk space which customer may elect not to do. Without update start_time information will be incorrect, but
--      may not be an issue for some customers.  
--      Without one-time update, The row with null start_time will be replaced with 1 second before timeStamp (end_time).
--SET NOCOUNT OFF --commented out because ECR #26008 (mt/8-25-2003)
If @RelationSought = @Child -- we seek this event's child(ren)
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
         , [Event_Component_Timestamp]           = dbo.fnServer_CmnConvertFromDbTime(C.TimeStamp,@InTimeZone)
         , [Event_Component_Start_Time]          = dbo.fnServer_CmnConvertFromDbTime(C.Start_Time,@InTimeZone)
         , [Event_Component_Entry_On]            = dbo.fnServer_CmnConvertFromDbTime(C.Entry_On,@InTimeZone)
         , [Event_Component_User]                = U.Username
         , [Event_Component_Dimension_A]         = C.Dimension_A
         , [Event_Component_Dimension_X]         = C.Dimension_X
         , [Event_Component_Dimension_Y]         = C.Dimension_Y
         , [Event_Component_Dimension_Z]         = C.Dimension_Z
         , [Event_Component_Start_Coordinate_A]  = C.Start_Coordinate_A
         , [Event_Component_Start_Coordinate_X]  = C.Start_Coordinate_X
         , [Event_Component_Start_Coordinate_Y]  = C.Start_Coordinate_Y
         , [Event_Component_Start_Coordinate_Z]  = C.Start_Coordinate_Z
      FROM Event_Components C
      JOIN Events e ON e.Event_Id = C.Event_Id
      LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
      JOIN Prod_Units pu ON pu.Pu_Id = e.Pu_Id
      LEFT JOIN Users U ON U.User_Id = C.User_Id
     WHERE C.Source_Event_Id = @Event_Id
  END
Else --@RelationSought = @Parent(we seek this event's parent)
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
         , [Event_Component_Timestamp]           = dbo.fnServer_CmnConvertFromDbTime(C.TimeStamp,@InTimeZone)
         , [Event_Component_Start_Time]          = dbo.fnServer_CmnConvertFromDbTime(C.Start_Time,@InTimeZone)
         , [Event_Component_Entry_On]            = dbo.fnServer_CmnConvertFromDbTime(C.Entry_On,@InTimeZone)
         , [Event_Component_User]                = U.Username
         , [Event_Component_Dimension_A]         = C.Dimension_A
         , [Event_Component_Dimension_X]         = C.Dimension_X
         , [Event_Component_Dimension_Y]         = C.Dimension_Y
         , [Event_Component_Dimension_Z]         = C.Dimension_Z
         , [Event_Component_Start_Coordinate_A]  = C.Start_Coordinate_A
         , [Event_Component_Start_Coordinate_X]  = C.Start_Coordinate_X
         , [Event_Component_Start_Coordinate_Y]  = C.Start_Coordinate_Y
         , [Event_Component_Start_Coordinate_Z]  = C.Start_Coordinate_Z
      FROM Event_Components C
      JOIN Events e on e.Event_Id = C.Source_Event_Id
      LEFT OUTER JOIN Event_Details ed ON ed.Event_Id = e.Event_Id
      JOIN Prod_Units pu on pu.Pu_Id = e.Pu_Id
      LEFT JOIN Users U ON U.User_Id = C.User_Id
     WHERE C.Event_Id = @Event_Id
  END
--EndIf:@RelationSought=@Child
