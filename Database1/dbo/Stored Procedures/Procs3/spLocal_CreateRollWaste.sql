 /*  
  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-10-27  
Version  : 1.0.3  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Stored Procedure: spLocal_CreateRollWaste  
Author:   Matthew Wells (MSI)  
Date Created:  10/31/01  
  
Description:  
=========  
Assigns waste.  
  
Change Date Who What  
=========== ==== =====  
10/31/01 MKW Changed Reject Waste to go to separate unit as can have both slab and reject simultaneously.  
02/20/02 MKW Added ODBC Canonical varchar conversions to all dates selected from the table.  
05/22/02 MKW Added check for False Turnovers  
*/  
CREATE PROCEDURE dbo.spLocal_CreateRollWaste  
@OutputValue    varchar(25) OUTPUT,  
@Event_Id    int,  -- a  
@Reject_Weight_Str   varchar(25), -- b  
@Slab_Weight_Str  varchar(25), -- c  
@Teardown_Weight_Str  varchar(25), -- d  
@Reject_Status_Desc  varchar(25), -- e  
@Reject_WET_Name   varchar(25), -- f  
@Slab_WET_Name   varchar(25), -- g  
@Teardown_WET_Name  varchar(25), -- h  
@Reject_Reason_Name  varchar(25), -- i  
@Slab_Reason_Name   varchar(25), -- j  
@Teardown_Reason_Name varchar(25), -- k  
@Reject_Weight_Factor_Str varchar(25), -- l  
@Slab_Weight_Factor_Str varchar(25), -- m  
@Teardown_Weight_Factor_Str varchar(25), -- n  
@Reject_WEMT_Name  varchar(25), -- o  
@Slab_WEMT_Name  varchar(25), -- p  
@Teardown_WEMT_Name varchar(25) -- q  
As  
  
SET NOCOUNT ON  
  
Declare @Trans_Type   int,  
 @PU_Id   int,  
 @TimeStamp   datetime,  
   @Event_Status    int,  
   @Amount    decimal(10,2),  
   @WED_Id    int,  
 @Last_WED_Id   int,  
 @WET_Id   int,  
 @Reject_Status_Id  int,  
 @Reject_WET_Id  int,  
 @Reject_WEMT_Id  int,  
 @Reject_Weight_Factor  float,  
 @Reject_Weight   decimal(10,2),  
 @Reject_Reason_Id  int,  
 @Slab_WET_Id   int,  
 @Slab_WEMT_Id  int,  
 @Slab_Weight_Factor  float,  
 @Slab_Weight   decimal(10,2),  
 @Slab_Reason_Id  int,  
 @Teardown_WET_Id  int,  
   @Teardown_WED_Id   int,  
 @Teardown_WEMT_Id  int,  
 @Teardown_Weight_Factor float,  
 @Teardown_Weight   decimal(10,2),  
 @Teardown_Reason_Id  int,  
 @Turnover_Event_Id  int,  
 @Turnover_Status_Id  int,  
 @False_Turnover_Status_Id int,  
 @False_Turnover_Status_Desc varchar(25),  
 @User_id   int  
  
-- user id for the resulset  
SELECT @User_id = User_id   
FROM Users  
WHERE username = 'Reliability System'  
  
/* Waste Event Result Set -- Do not add columns to this table */  
DECLARE @WasteEvents TABLE(  
 Result_Set_Type int Default 9, -- 0  : Result Set Type  
 Pre   int Default 1,  -- 1  : Result Set Action - pre-update (1) / post-update (0)  
 TransNum   int Default 0, -- 2  : Result Set Transaction Number (Generally should be 0)  
 User_Id    int Default 1, -- 3  : User_Id  
 Transaction_Type int Default 1, -- 4  : Result Set Transaction Type - Add (1) / Update (2) / Delete (3)  
 WED_Id   int Null,   -- 5  : Waste Event Id  
 PU_Id    int Null,  -- 6  : PU Id on which the waste event resides  
 Source_PU_Id   int Null,   -- 7  : PU_Id on which the associated production event resides (for event based waste)  
 WET_Id   int Null,   -- 9  : Waste Event Type Id; slab =1  tear = 3 Roll = 6  
 WEMT_Id  int Null,   -- 10 : Waste Event Measure Type Id; 1(slab,tear) 3(Rolls)  
 Reason_Level1  int Null,   -- 11 :   
 Reason_Level2  int Null,   -- 12 :   
 Reason_Level3  int Null,   -- 13 :   
 Reason_Level4  int Null,   -- 14 :   
 Event_Id  int Null,  -- 15 : Event_Id of the associated production event (for event based waste)  
 Amount   float,  -- 16 : Waste Amount  
 Marker1   float Null,    -- 17 :   
 Marker2   float Null,  -- 18 :   
 TimeStamp  varchar(30),  -- 19 :   
 Action_Level1  int Null,   -- 20 :   
 Action_Level2  int Null,   -- 21 :   
 Action_Level3   int Null,   -- 22 :   
 Action_Level4  int Null,   -- 23 :   
 Action_Comment_Id int Null,   -- 24 :   
 Research_Comment_Id int Null,   -- 25 :   
 Research_Status_Id int Null,   -- 26 :   
 Research_Open_Date varchar(30) Null, -- 27 :   
 Research_Close_Date varchar(30) Null, -- 28 :   
 Cause_Comment_Id int Null,   -- 29 :   
 Target_Prod_Rate float Null,  -- 30 :   
 Research_User_Id  int Null)   -- 31 :   
  
/************************************************************************************************************************************************************************  
*                                                                                                          Initialization                                                                                                   *  
************************************************************************************************************************************************************************/  
/* Initialization */  
Select @Trans_Type   = 1,  
  @Reject_Status_Id  = Null,  
 @Reject_WET_Id  = Null,  
 @Slab_WET_Id   = Null,  
 @Teardown_WET_Id  = Null,  
 @Reject_Reason_Id  = Null,  
 @Slab_Reason_Id  = Null,  
 @Teardown_Reason_Id  = Null,  
 @Amount    = Null,  
 @WED_Id   = Null,  
 @Last_WED_Id   = Null,  
 @WET_Id   = Null,  
 @Reject_Weight_Factor  = 1.0,  
 @Slab_Weight_Factor  = 1.0,  
 @Teardown_Weight_Factor = 1.0,  
 @Reject_Weight  = 0.0,  
 @Slab_Weight   = 0.0,  
 @Teardown_Weight  = 0.0,  
 @False_Turnover_Status_Desc = 'False Turnover'  
  
  
  
/************************************************************************************************************************************************************************  
*                                                                                          Check Turnover Status                                                                                                *  
************************************************************************************************************************************************************************/  
Select @False_Turnover_Status_Id = ProdStatus_Id  
From [dbo].Production_Status  
Where ProdStatus_Desc = @False_Turnover_Status_Desc  
  
Select @Turnover_Event_Id = Source_Event_Id  
From [dbo].Event_Components  
Where Event_Id = @Event_Id  
  
Select @Turnover_Status_Id = Event_Status  
From [dbo].Events  
Where Event_Id = @Turnover_Event_Id  
  
If @Turnover_Status_Id <> @False_Turnover_Status_Id  
     Begin  
     /************************************************************************************************************************************************************************  
     *                                                                                             Convert Arguments                                                                                                    *  
     ************************************************************************************************************************************************************************/  
     /* Convert factors */  
     If IsNumeric(@Reject_Weight_Factor_Str) = 1  
 Select @Reject_Weight_Factor = convert(float, @Reject_Weight_Factor_Str)  
     If IsNumeric(@Slab_Weight_Factor_Str) = 1  
 Select @Slab_Weight_Factor = convert(float, @Slab_Weight_Factor_Str)  
     If IsNumeric(@Teardown_Weight_Factor_Str) = 1  
 Select @Teardown_Weight_Factor = convert(float, @Teardown_Weight_Factor_Str)  
  
     /* Convert Weights */  
     If IsNumeric(@Reject_Weight_Str) = 1  
 Select @Reject_Weight = convert(float, @Reject_Weight_Str) * @Reject_Weight_Factor  
     If IsNumeric(@Slab_Weight_Str) = 1  
 Select @Slab_Weight = convert(float, @Slab_Weight_Str) * @Slab_Weight_Factor  
     If IsNumeric(@Teardown_Weight_Str) = 1  
 Select @Teardown_Weight = convert(float, @Teardown_Weight_Str) * @Teardown_Weight_Factor  
  
     /* Get Reject Status Id */  
     Select @Reject_Status_Id = ProdStatus_Id From [dbo].Production_Status Where ProdStatus_Desc = LTrim(RTrim(@Reject_Status_Desc))  
  
     /* Get Waste Event Type Ids */  
     Select @Reject_WET_Id = WET_Id From [dbo].Waste_Event_Type Where WET_Name = LTrim(RTrim(@Reject_WET_Name))  
     Select @Slab_WET_Id = WET_Id From [dbo].Waste_Event_Type Where WET_Name = LTrim(RTrim(@Slab_WET_Name))  
     Select @Teardown_WET_Id = WET_Id From [dbo].Waste_Event_Type Where WET_Name = LTrim(RTrim(@Teardown_WET_Name))  
  
     /* Get Waste Reason Ids */  
     Select @Reject_Reason_Id = Event_Reason_Id From [dbo].Event_Reasons Where Event_Reason_Name = LTrim(RTrim(@Reject_Reason_Name))  
     Select @Slab_Reason_Id = Event_Reason_Id From [dbo].Event_Reasons Where Event_Reason_Name = LTrim(RTrim(@Slab_Reason_Name))  
     Select @Teardown_Reason_Id = Event_Reason_Id From [dbo].Event_Reasons Where Event_Reason_Name = LTrim(RTrim(@Teardown_Reason_Name))  
  
     /* Get Waste Event Measure Ids */  
     Select @Reject_WEMT_Id = WEMT_Id From [dbo].Waste_Event_Meas Where WEMT_Name = LTrim(RTrim(@Reject_WEMT_Name))  
     Select @Slab_WEMT_Id = WEMT_Id From [dbo].Waste_Event_Meas Where WEMT_Name = LTrim(RTrim(@Slab_WEMT_Name))  
     Select @Teardown_WEMT_Id = WEMT_Id From [dbo].Waste_Event_Meas Where WEMT_Name = LTrim(RTrim(@Teardown_WEMT_Name))  
  
     /************************************************************************************************************************************************************************  
     *                                                                                           Get Roll Event Parameters                                                                                          *  
     ************************************************************************************************************************************************************************/  
     /* Get the event status */  
     Select @PU_Id = PU_Id, @TimeStamp = TimeStamp, @Event_Status = Event_Status  
     From [dbo].Events   
     Where Event_Id  = @Event_Id  
  
     /************************************************************************************************************************************************************************  
     *                                                                                        Create waste for REJECT rolls                                                                                        *  
     ************************************************************************************************************************************************************************/  
     If (@Event_Status = @Reject_Status_Id And @Reject_Weight > 0 And @Reject_Weight Is Not Null)  
          Begin  
          /* Reinitialize */  
          Select  @Amount  = Null,  
     @WED_Id = Null,  
     @WET_Id = Null  
  
  
          /* Check for existing waste records */  
          Select @WED_Id = WED_Id, @Amount = Amount, @WET_Id = WET_Id  
          From [dbo].Waste_Event_Details  
          Where PU_Id = @PU_Id And Event_Id = @Event_Id  And WET_Id = @Reject_WET_Id  
        
          /* If no records then create a new waste record */  
          If (@WED_Id Is Null)     -- Must create new Reject Waste record  
               Begin  
               /* Find the first record so this waste type will appear first in the Waste header */  
               Select @WED_Id = Min(WED_Id)  
               From [dbo].Waste_Event_Details  
               Where PU_Id = @PU_Id And Event_Id = @Event_Id  
  
               If @WED_Id Is Null  
                    Insert Into @WasteEvents(Transaction_Type, PU_Id, Source_PU_Id, WET_Id, WEMT_Id, Reason_Level1, Event_Id, Amount, Timestamp,User_id)  
                    Values(1, @PU_Id, @PU_Id, @Reject_WET_Id, @Reject_WEMT_Id, @Reject_Reason_Id, @Event_Id, @Reject_Weight, convert(varchar(30), @TimeStamp, 120),@User_id)  
               Else  
                    Begin  
                    /* Insert any existing records as a new records and modify the original to a Reject waste record so can see it as the most recent */  
                    Insert Into @WasteEvents(Transaction_Type, WED_Id, PU_Id, Source_PU_Id, WET_Id, WEMT_Id, Reason_Level1, Event_Id, Amount, Timestamp,User_id)  
                    Values(2, @WED_Id, @PU_Id, @PU_Id, @Reject_WET_Id, @Reject_WEMT_Id, @Reject_Reason_Id, @Event_Id, @Reject_Weight, convert(varchar(30), @TimeStamp, 120),@User_id)  
  
                    Select @Last_WED_Id = @WED_Id  
  
                    End  
  
               End  
          /* If the weight has changed then modify the waste record */  
          Else If (@Amount <> @Reject_Weight )  
               Insert Into @WasteEvents(Transaction_Type, WED_Id, PU_Id, Source_PU_Id, WET_Id, WEMT_Id,  
  Reason_Level1, Reason_Level2, Reason_Level3, Reason_Level4, Event_Id, Amount, Timestamp,  
  Action_Level1, Action_Level2, Action_Level3, Action_Level4, Action_Comment_Id,  
  Research_Comment_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date,   
  Cause_Comment_Id, --Target_Prod_Rate, 
Research_User_Id,User_id)  
               Select 2, WED_Id, PU_Id, Source_PU_Id, WET_Id, WEMT_Id,  
  Reason_Level1, Reason_Level2, Reason_Level3, Reason_Level4, Event_Id, @Reject_Weight, convert(varchar(30), TimeStamp, 120),  
  Action_Level1, Action_Level2, Action_Level3, Action_Level4, Action_Comment_Id,  
  Research_Comment_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date,   
  Cause_Comment_Id, --Target_Prod_Rate,
Research_User_Id,@USer_id  
               From [dbo].Waste_Event_Details  
               Where WED_Id = @WED_Id  
          End  
     /* Check for Rejected rolls that have been Reaccepted And, if so, delete waste entry */  
     Else  
          Begin  
          /* Reinitialize */  
          Select @Amount  = Null,  
     @WED_Id = Null,  
     @WET_Id = Null  
  
          /* Check for existing waste records */  
          Select @WED_Id = WED_Id, @Amount = Amount, @WET_Id = WET_Id  
          From [dbo].Waste_Event_Details  
          Where PU_Id = @PU_Id And Event_Id = @Event_Id  And WET_Id = @Reject_WET_Id  
        
          /* If found Reject waste record and status is NOT reject then delete the waste record */  
          If (@Event_Status <> @Reject_Status_Id And @WED_Id Is Not Null)  
               Insert Into @WasteEvents(Transaction_Type, WED_Id, PU_Id, Source_PU_Id, WET_Id, WEMT_Id,  
  Reason_Level1, Reason_Level2, Reason_Level3, Reason_Level4, Event_Id, Amount, Timestamp,  
  Action_Level1, Action_Level2, Action_Level3, Action_Level4, Action_Comment_Id,  
  Research_Comment_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date,   
  Cause_Comment_Id, --Target_Prod_Rate,
 Research_User_Id,User_id)  
               Select 3, WED_Id, PU_Id, Source_PU_Id, WET_Id, WEMT_Id,  
  Reason_Level1, Reason_Level2, Reason_Level3, Reason_Level4, Event_Id, @Reject_Weight, convert(varchar(30), TimeStamp, 120),  
  Action_Level1, Action_Level2, Action_Level3, Action_Level4, Action_Comment_Id,  
  Research_Comment_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date,   
  Cause_Comment_Id, --Target_Prod_Rate,
Research_User_Id,@User_id  
               From [dbo].Waste_Event_Details  
               Where WED_Id = @WED_Id  
          End  
  
     /************************************************************************************************************************************************************************  
     *                                                                                        Create waste for Slab weight                                                                                          *  
     ************************************************************************************************************************************************************************/  
     If (@Slab_Weight > 0 And @Slab_Weight Is Not Null)  
          Begin  
          /* Reinitialize */  
          Select @Amount  = Null,  
     @WED_Id = Null,  
     @WET_Id = Null  
  
          /* Check for existing waste records */  
          Select @WED_Id = WED_Id, @Amount = Amount, @WET_Id = WET_Id  
          From [dbo].Waste_Event_Details  
          Where PU_Id = @PU_Id And Event_Id = @Event_Id  And (WET_Id = @Slab_WET_Id Or WET_Id = @Teardown_WET_Id)  
  
          /* If no records then create a new waste record */  
          If (@WED_Id Is Null)  
               Insert Into @WasteEvents(Transaction_Type, PU_Id, Source_PU_Id, WET_Id, WEMT_Id, Reason_Level1, Event_Id, Amount, Timestamp,User_id)  
               Values(1, @PU_Id, @PU_Id, @Slab_WET_Id, @Slab_WEMT_Id, @Slab_Reason_Id, @Event_Id, @Slab_Weight, convert(varchar(30), @TimeStamp, 120),@User_id)  
          /* Check to see if the record was already overwritten previously */  
          Else If @Last_WED_Id = @WED_Id  
               /* If there is an existing Teardown record exists then overwrite it with the Slab weight */  
               If (@WET_Id <> @Slab_WET_Id )  
                    Insert Into #WasteEvents(Transaction_Type, PU_Id, Source_PU_Id, WET_Id, WEMT_Id, Reason_Level1, Event_Id, Amount, Timestamp,User_id)  
                    Values(1, @PU_Id, @PU_Id, @Slab_WET_Id, @Slab_WEMT_Id, @Slab_Reason_Id, @Event_Id, @Slab_Weight, convert(varchar(30), @TimeStamp, 120),@User_id)  
               /* Re-Insert the existing waste record the new weight */  
               Else  
                    Insert Into @WasteEvents(Transaction_Type, PU_Id, Source_PU_Id, WET_Id, WEMT_Id,  
  Reason_Level1, Reason_Level2, Reason_Level3, Reason_Level4, Event_Id, Amount, Timestamp,  
  Action_Level1, Action_Level2, Action_Level3, Action_Level4, Action_Comment_Id,  
  Research_Comment_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date,   
  Cause_Comment_Id, --Target_Prod_Rate,
 Research_User_Id,User_id)  
                    Select 1, PU_Id, Source_PU_Id, WET_Id, WEMT_Id,  
  Reason_Level1, Reason_Level2, Reason_Level3, Reason_Level4, Event_Id, @Slab_Weight, convert(varchar(30), TimeStamp, 120),  
  Action_Level1, Action_Level2, Action_Level3, Action_Level4, Action_Comment_Id,  
  Research_Comment_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date,   
  Cause_Comment_Id, --Target_Prod_Rate,
Research_User_Id,@USer_id  
                    From [dbo].Waste_Event_Details  
                    Where WED_Id = @WED_Id  
          Else  
               /* If there is an existing Teardown record exists then overwrite it with the Slab weight */  
               If (@WET_Id <> @Slab_WET_Id )  
                    Insert Into @WasteEvents(Transaction_Type, WED_Id, PU_Id, Source_PU_Id, WET_Id, WEMT_Id, Reason_Level1, Event_Id, Amount, Timestamp,User_id)  
                    Values(2, @WED_Id, @PU_Id, @PU_Id, @Slab_WET_Id, @Slab_WEMT_Id, @Slab_Reason_Id, @Event_Id, @Slab_Weight, convert(varchar(30), @TimeStamp, 120),@User_id)  
               /* If the weight has changed then modify the waste record */  
               Else If (@Amount <> @Slab_Weight)  
                    Insert Into @WasteEvents(Transaction_Type, WED_Id, PU_Id, Source_PU_Id, WET_Id, WEMT_Id,  
  Reason_Level1, Reason_Level2, Reason_Level3, Reason_Level4, Event_Id, Amount, Timestamp,  
  Action_Level1, Action_Level2, Action_Level3, Action_Level4, Action_Comment_Id,  
  Research_Comment_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date,   
  Cause_Comment_Id, --Target_Prod_Rate, 
Research_User_Id,User_id)  
                    Select 2, WED_Id, PU_Id, Source_PU_Id, WET_Id, WEMT_Id,  
  Reason_Level1, Reason_Level2, Reason_Level3, Reason_Level4, Event_Id, @Slab_Weight, convert(varchar(30), TimeStamp, 120),  
  Action_Level1, Action_Level2, Action_Level3, Action_Level4, Action_Comment_Id,  
  Research_Comment_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date,   
  Cause_Comment_Id, --Target_Prod_Rate,
Research_User_Id,@User_id  
                    From [dbo].Waste_Event_Details  
                    Where WED_Id = @WED_Id  
          End  
     /************************************************************************************************************************************************************************  
     *                                                                                  Create waste for Teardown weight                                                                                       *  
     ************************************************************************************************************************************************************************/  
     /* If no slab weight then create Teardown waste */  
     Else If (@Teardown_Weight > 0 And @Teardown_Weight Is Not Null)  
          Begin  
          /* Reinitialize */  
          Select @Amount  = Null,  
     @WED_Id = Null,  
     @WET_Id = Null  
  
          /* Check for existing waste records */  
          Select @WED_Id = WED_Id, @Amount = Amount, @WET_Id = WET_Id  
          From [dbo].Waste_Event_Details  
          Where PU_Id = @PU_Id And Event_Id = @Event_Id  And (WET_Id = @Slab_WET_Id Or WET_Id = @Teardown_WET_Id)  
  
          /* If no records then create a new waste record */  
          If (@WED_Id Is Null)  
               Insert Into @WasteEvents(Transaction_Type, PU_Id, Source_PU_Id, WET_Id, WEMT_Id, Reason_Level1, Event_Id, Amount, Timestamp,User_id)  
               Values(1, @PU_Id, @PU_Id, @Teardown_WET_Id, @Teardown_WEMT_Id, @Teardown_Reason_Id, @Event_Id, @Teardown_Weight, convert(varchar(30), @TimeStamp, 120),@User_id)  
          /* Check to see if the record was already overwritten previously */  
          Else If @Last_WED_Id = @WED_Id  
               /* If there is an existing (but now defunct) Slab waste record then overwrite it with the Teardown weight */  
               If (@WET_Id <> @Teardown_WET_Id )  
                    Insert Into @WasteEvents(Transaction_Type, PU_Id, Source_PU_Id, WET_Id, WEMT_Id, Reason_Level1, Event_Id, Amount, Timestamp,User_id)  
                    Values(1, @PU_Id, @PU_Id, @Teardown_WET_Id, @Teardown_WEMT_Id, @Teardown_Reason_Id, @Event_Id, @Teardown_Weight, convert(varchar(30), @TimeStamp, 120),@User_id)  
               /* Re-Insert the existing waste record the new weight */  
               Else  
                    Insert Into @WasteEvents(Transaction_Type, PU_Id, Source_PU_Id, WET_Id, WEMT_Id,  
  Reason_Level1, Reason_Level2, Reason_Level3, Reason_Level4, Event_Id, Amount, Timestamp,  
  Action_Level1, Action_Level2, Action_Level3, Action_Level4, Action_Comment_Id,  
  Research_Comment_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date,   
  Cause_Comment_Id,-- Target_Prod_Rate,
 Research_User_Id,User_id)  
                    Select 1, PU_Id, Source_PU_Id, WET_Id, WEMT_Id,  
  Reason_Level1, Reason_Level2, Reason_Level3, Reason_Level4, Event_Id, @Teardown_Weight, convert(varchar(30), TimeStamp, 120),  
  Action_Level1, Action_Level2, Action_Level3, Action_Level4, Action_Comment_Id,  
  Research_Comment_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date,   
  Cause_Comment_Id, --Target_Prod_Rate,
Research_User_Id,@User_id  
                    From [dbo].Waste_Event_Details  
                    Where WED_Id = @WED_Id  
          Else   
               If (@WET_Id <> @Teardown_WET_Id)  
                    Insert Into @WasteEvents(Transaction_Type, WED_Id, PU_Id, Source_PU_Id, WET_Id, WEMT_Id, Reason_Level1, Event_Id, Amount, Timestamp,User_id)  
                    Values(2, @WED_Id, @PU_Id, @PU_Id, @Teardown_WET_Id, @Teardown_WEMT_Id, @Teardown_Reason_Id, @Event_Id, @Teardown_Weight, convert(varchar(30), @TimeStamp, 120),@User_id)  
               /* If the weight has changed then modify the waste record */  
               Else If (@Amount <> @Teardown_Weight)  
                    Insert Into @WasteEvents(Transaction_Type, WED_Id, PU_Id, Source_PU_Id, WET_Id, WEMT_Id,  
  Reason_Level1, Reason_Level2, Reason_Level3, Reason_Level4, Event_Id, Amount, Timestamp,  
  Action_Level1, Action_Level2, Action_Level3, Action_Level4, Action_Comment_Id,  
  Research_Comment_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date,   
  Cause_Comment_Id, --Target_Prod_Rate, 
Research_User_Id,User_id)  
                    Select 2, WED_Id, PU_Id, Source_PU_Id, WET_Id, WEMT_Id,  
  Reason_Level1, Reason_Level2, Reason_Level3, Reason_Level4, Event_Id, @Teardown_Weight, convert(varchar(30), TimeStamp, 120),  
  Action_Level1, Action_Level2, Action_Level3, Action_Level4, Action_Comment_Id,  
  Research_Comment_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date,   
  Cause_Comment_Id, --Target_Prod_Rate,
Research_User_Id,@User_id  
                    From [dbo].Waste_Event_Details  
                    Where WED_Id = @WED_Id  
          End  
  
     /* Output Results */  
     Select Result_Set_Type,Pre,TransNum,User_Id,Transaction_Type, WED_Id, PU_Id, Source_PU_Id, WET_Id, WEMT_Id,  
  Reason_Level1, Reason_Level2, Reason_Level3, Reason_Level4, Event_Id, Amount,Marker1,Marker2, Timestamp,  
  Action_Level1, Action_Level2, Action_Level3, Action_Level4, Action_Comment_Id,  
  Research_Comment_Id, Research_Status_Id, Research_Open_Date, Research_Close_Date,   
  Cause_Comment_Id, Target_Prod_Rate, Research_User_Id  
     From @WasteEvents  
  
     Select @OutputValue = @WED_Id  
     End  
  
/* Cleanup */  
--Drop Table #WasteEvents  
--- end  
SET NOCOUNT OFF  
  
