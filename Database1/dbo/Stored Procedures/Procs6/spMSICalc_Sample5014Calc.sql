CREATE Procedure dbo.spMSICalc_Sample5014Calc
@OutputValue varchar(25) OUTPUT,
@PU_Id int,
@TriggerTagTimeStamp datetime,
@AmountTagValue Varchar(30),
@FaultTagValue Varchar(30) = NULL,
@TypeValue Varchar(30) = NULL,
@MeasureValue Varchar(30) = NULL,
@ECId Int = Null
AS
-------------------------------------------------------------
-- Amount or Fault values of NULL will not cause this calc
-- to fire.
-- This is a Sample Stored Procedure and it will be replaced      
-- on the next upgrade.  If you want to customize it create a     
-- new procedure with a different name so you will not lose       
-- your changes on an upgrade.                                    
-------------------------------------------------------------
Declare @StartEventTime DateTime,@Now DateTime
Declare @EventId Int
Declare @WEFault_Id int
Declare @Event_Reason_Tree_Data_Id int
Declare @WEFault_Name varchar(100)
Declare @WEFault_Value varchar(25)
Declare @SPU_Id int,@R1 int,@R2 int,@R3 int,@R4 int,@Amount float,@Type int,@Meas int,@PrevET datetime,@NextET DateTime
------------------------------------------------------------
-- Initialzie
------------------------------------------------------------
Select  	 @Now = dbo.fnServer_CmnGetDate(getUTCdate()),
 	 @StartEventTime = Dateadd(day, -10, @TriggerTagTimeStamp),
 	 @OutputValue = 'WasteEvent Error',
 	 @Type = Null,
 	 @Meas = Null
Select @TypeValue = ltrim(rtrim(@TypeValue))
If @TypeValue = '' Select @TypeValue = null
If @TypeValue is Not Null
BEGIN
 	 Select @Type = WET_Id From Waste_Event_Type Where WET_Name = @TypeValue
END
Select @MeasureValue = ltrim(rtrim(@MeasureValue))
If @MeasureValue = '' Select @MeasureValue = null
If @MeasureValue is Not Null
BEGIN
 	 Select @Meas = WEMT_Id From Waste_Event_Meas Where WEMT_Name = @MeasureValue and PU_Id = @PU_Id
END
------------------------------------------------------------
-- Look for matching event
-- If no event id is found for the matching timestamp then
-- this will be treated as time based waste
------------------------------------------------------------
Select @EventId = Event_Id 
From Events
Where PU_Id = @PU_Id  
and TimeStamp  = @TriggerTagTimeStamp
------------------------------------------------------------
-- Attempt to translate the fault name
-- When @FaultTagValue is not numeric
------------------------------------------------------------
If isNumeric(@FaultTagValue) = 1
     Begin
          Select @SPU_Id = Source_PU_Id,
 	  	 @R1 = Reason_Level1,
 	  	 @R2 = Reason_Level2,
 	  	 @R3 = Reason_Level3,
 	  	 @R4 = Reason_Level4,
 	  	 @WEFault_Id = WEFault_Id,
 	  	 @Event_Reason_Tree_Data_Id = Event_Reason_Tree_Data_Id
          From Waste_Event_Fault 
 	   Where PU_ID = @PU_id 
 	   and WEFault_Value = @FaultTagValue
     End
Else
     Begin
          --Print '@FaultTagValue is varchar'
          -- Check Waste_Event_Fault table to locate a matching description
          Select @WEFault_Value=WEFault_Value 
 	   from Waste_Event_Fault 
 	   Where Upper(LTrim(RTrim(WEFault_Name))) = Upper(LTrim(RTrim(@FaultTagValue)))
 	   And PU_ID = @PU_Id
           -- If @WEFault_Value Is Null I cannot find a match
          If @WEFault_Value Is Not Null
               Begin
                    --Print '@WEFault_Value = ' + @WEFault_Value
                    Select @SPU_Id = Source_PU_Id,
 	  	  	 @R1 = Reason_Level1,
 	  	  	 @R2 = Reason_Level2,
 	  	  	 @R3 = Reason_Level3,
 	  	  	 @R4 = Reason_Level4,
 	  	  	 @WEFault_Id = WEFault_Id,
 	  	  	 @Event_Reason_Tree_Data_Id = Event_Reason_Tree_Data_Id
                    From Waste_Event_Fault 
 	  	     Where PU_ID = @PU_id 
 	  	     and WEFault_Value = @WEFault_Value                 
               End
     End
If isNumeric(@AmountTagValue) = 1
 	 Select @Amount = Convert(float,@AmountTagValue)
------------------------------------------------------------
-- Determine if this is an add, update or delete 
------------------------------------------------------------
Declare @WED_Id int
Declare @TransType int
If @EcId Is Null
 	 Select @WED_ID = WED_Id
 	 From Waste_Event_Details 
 	 Where Timestamp = @TriggerTagTimeStamp 	 AND   PU_Id = @PU_Id and EC_Id is Null
Else
 	 Select @WED_ID = WED_Id
 	 From Waste_Event_Details 
 	 Where Timestamp = @TriggerTagTimeStamp 	 AND   PU_Id = @PU_Id and EC_Id = @EcId 
If @WED_Id Is Null 
     Select @TransType = 1 -- Insert New Waste Event
Else If (@AmountTagValue Is Null) or (@AmountTagValue = '') -- Delete Waste Event
     Select @TransType = 3 -- Delete
Else -- Update Waste Event
     Select @TransType = 2 -- Update
--Save Data
EXECUTE dbo.spServer_DBMgrUpdWasteEvent @WED_Id OUTPUT,@PU_Id ,@SPu_Id, 	 @TriggerTagTimeStamp,@Type,@Meas,@R1,@R2,@R3,@R4,
 	  	  	  	  	  	  	  	  	  	 @EventId,@Amount,Null,Null,@TransType,0,6,Null,Null,Null,Null,Null,Null,Null,Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	  	  	  	 @WEFault_Id,@Event_Reason_Tree_Data_Id,Null,Null,Null,Null,Null,Null,Null,Null,Null,Null,Null,Null,Null,Null,
 	  	  	  	  	  	  	  	  	  	 @ECId,Null
------------------------------------------------------------
-- Send Out The Result Set
------------------------------------------------------------
IF @WED_Id Is Not NULL
 	 Select 9,0,0,6,@TransType,WED_Id,PU_Id,Source_PU_Id,WET_Id,WEMT_Id,
 	  	 Reason_Level1,Reason_Level2,Reason_Level3,Reason_Level4,
 	  	 Event_Id,Amount,Null,Null,TimeStamp,
 	  	 Action_Level1,Action_Level2,Action_Level3,Action_Level4,Action_Comment_Id,
 	  	 Research_Comment_Id,Research_Status_Id,Research_Open_Date,Research_Close_Date,
 	  	 Cause_Comment_Id,Null,Research_User_Id,
 	  	 WEFault_Id,Event_Reason_Tree_Data_Id,
 	  	 Dimension_X,Dimension_Y,Dimension_Z,Dimension_A,
 	  	 Start_Coordinate_X,Start_Coordinate_Y,Start_Coordinate_Z,Start_Coordinate_A,
 	  	 User_General_1,User_General_2,User_General_3,User_General_4,User_General_5,
 	  	 Work_Order_Number,EC_Id
 	 FROM Waste_Event_Details
 	 WHERE WED_Id = @WED_Id
Select @OutputValue = ''
