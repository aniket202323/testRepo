  /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-11-01  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Altered by  : ?  
Date   : ?  
Version  : 1.0.0  
Purpose  : ?   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
*/  
  
CREATE Procedure dbo.spLocal_GeneCvtgMovement  
@Success  int    OUTPUT,  
@ErrMsg  varchar(255)  OUTPUT,  
@JumpAheadTime datetime OUTPUT,  
@EC_ID  int,  
@ResevedInput1 varchar(255),  
@ResevedInput2 varchar(255),  
@ResevedInput3 varchar(255),  
@ResevedInput4 varchar(255),  
@Fault   varchar(255),  
@FaultOldValue  varchar(255),  
@FaultOldTime  varchar(255),  
@FaultNewValue varchar(255),  
@FaultNewTime  varchar(255),  
@HistorianTag  varchar(255),  
@HistorianTagValue varchar(255)  
As  
  
SET NOCOUNT ON  
  
DECLARE @EventInputs TABLE (  
 Result_Set_Type  int DEFAULT 12,  
 Pre_Update  int DEFAULT 1,  
 User_Id   int DEFAULT 6,  
 Transaction_Type  int DEFAULT 1,   -- 1 = ; 2 = ; 3 = Unload  
 Transaction_Number int DEFAULT 0,  -- Must be 0  
 TimeStamp   varchar(30) NULL,   
 Entry_On   varchar(30) NULL,   
 Comment_Id   int NULL,   
 PEI_Id    int NULL,   
 PEIP_Id   int NULL,   
 Event_Id   int NULL,   
 Dimension_X  float NULL,  
 Dimension_Y  float NULL,  
 Dimension_Z  float NULL,  
 Dimension_A  float NULL,  
 Unloaded   int NULL)  
  
Declare @PEI_Id  Int,  
 @InputEventId Int,  
 @EventId Int,  
 @PU_Id Int,  
 @EventNum VarChar(25),  
 @Status Int,  
 @Source Int,  
 @Now  DateTime,  
 @TimeStamp DateTime,  
 @User_id   int  
  
-- user id for the resulset  
SELECT @User_id = User_id   
FROM [dbo].Users  
WHERE username = 'Reliability System'  
  
/* Initialization */  
Select   @ErrMsg = '',  
 @Success = 1,  
 @JumpAheadTime = Null,  
 @InputEventId = Null  
  
Select @Now = Getdate()  
  
/*  
If @Trigger1OldTime < Dateadd(minute,-10,@Now)  
  Begin  
 Select @JumpAheadTime = @Now  
 return  
  End  
*/  
  
  
  
/* Find the input for the attached event */  
Select @PEI_Id = PEI_Id  
From [dbo].Event_Configuration   
Where EC_Id = @EC_Id  
  
/* Get the running event details */  
Select @InputEventId = Input_Event_Id, @EventId = Event_Id  
From [dbo].PrdExec_Input_Event  
Where PEI_Id = @PEI_Id And PEIP_Id = 1 And Event_Id Is Not Null  
  
If @InputEventId Is Not Null  
     Begin  
     /* Complete the running roll */  
     Insert Into @EventInputs(Transaction_Type, TimeStamp, Entry_On, PEI_Id, PEIP_Id,Event_Id, Unloaded,User_id)   
     Values (1, @Now, @Now, @PEI_Id, 1, Null, 1,@User_id)  
     End  
  
If (Select Count(Transaction_Type) From #InputEventUpdates) > 0  
     SELECT Result_Set_Type ,  
    Pre_Update ,  
    User_Id ,  
    Transaction_Type  ,     
    Transaction_Number ,  
    TimeStamp ,   
    Entry_On  ,   
    Comment_Id ,   
    PEI_Id ,   
    PEIP_Id ,   
    Event_Id ,   
    Dimension_X ,  
    Dimension_Y ,  
    Dimension_Z ,  
    Dimension_A ,  
    Unloaded    
 FROM @EventInputs  
  
Select @Success = 1  
  
SET NOCOUNT OFF  
  
