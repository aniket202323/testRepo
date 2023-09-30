 /*  
Stored Procedure: spLocal_CreateParentRollEvents  
Author:   Matthew Wells (MSI)  
Date Created:  08/27/01  
  
Arguments:  
Alias Variable   Description  
==== =======  =========  
a @Turnover_PU_Id - Production unit Id of the turnover events   
b @Turnover_TimeStamp - Timestamp of the turnover  
c @Turnover_Event_Id - Id of the turnover event  
d @Var_Id  - Id of the variable that is linked to a specification under the product property that contains the roll   
      configuration.  The actual specification linked is irrelevant as it's just used to identify the correct product property.  
e @Roll_PU_Id  - Production Unit Id on which the parent roll events are going to be created.  
f @Default_Status - Default production status of the roll events, all parent roll events will be created with this status if it can be found in the   
      in list of available production statuses.  
  
Description:  
=========  
This procedure creates the parent roll events in the associated parent rolls production unit (XX01 Rolls) when a turnover is detected.  It is initiated by the  
'Create Parent Roll Events' variable under the turnover production unit (XX01 Production).  
  
The procedure first checks for 'orphaned' rolls and deletes them.  There is no way to detect automatically if a turnover is deleted from the Production unit.  
Therefore, whenever a new turnover is created (and this procedure run) we check to see if there are any unlinked rolls and then delete them.  
  
The attached variable must be linked to a Specification under the Property which contains the product based roll configuration.  The configuration is set by  
defining Characteristic groups with the same name as the running Product Code.  Individual rolls are defined as Characteristics and the number of  
characteristics within each Characteristic group determines how many rolls will be created.  The order and position of the rolls is determined by entering  
values against the relevant specifications.  As such, for each unique roll size and position a unique property must be created.  
  
The ULID is assigned according the following format;    AABCCCCCGGDDEEEEEEEF  
where:  
AA  = Application Qualifier   ie. 00  
B  = Packaging Type   ie. 4  
CCCCCCC = Country SpecificManufacturer ID ie. 00370  
GG  = Machine ID    ie. 13 = 6G  
DD  = Site specific identifier   ie. 63 (Mehoopany),   
EEEEEEE      = Shipping Unit Serial Number  ie. 1234567  
F  = Check digit  
The first 12 digits are passed as a constant while the Shipping Unit Serial Number is a fixed increment.  
  
Change Date Who What  
=========== ==== =====  
08/27/01 MKW Created procedure.  
10/22/01 MKW Added check for FIRE status  
10/23/01 MKW Changed Event_Num to ULID instead of PRID  
12/17/01 MKW Changed order of roll creation so that the 'A' roll appears at the left end  
01/25/02 MKW Changed the addition of 1001 to 1000 against @Turnover_Count in the PRID calculation  
   Pulled the current Turnover number directly from the Turnover Event_Num  
02/04/02 MKW Added check for total turnovers in the current production day and ensure that its greater than the number retrieved from the Turnover Event_Num  
02/11/02 MKW Added check for 'False Turnover' status  
03/13/02 MKW Undid previous check for total turnovers and pulled julian date from the Turnover Id b/c now want it to follow the Turnover Id as much as possible.  
04/03/02 MKW Added failsafe for ULID_SN, parse it from Event_Num if not in Primary_Event_Num  
04/08/02 MKW Changed Crew; get it from the TID instead of the Crew_Schedule table.  
04/17/02 MKW Added retrieval of QCS Turnover Weight  
   Retrieved the roll ratio from the specifications and put in Dimension_A of the Event_Components record so the QCS Event knows how to split the weight  
05/08/02 MKW Get QCS Turnover Weight from Event_Details instead of Events  
   Moved additional information retrieval back outside so both routines can see it.  
06/27/02 MKW Added teardown weight retrieval  
   Added code to move data between the turnover events in case of roll recreation.  
*/  
CREATE procedure dbo.spLocal_CreateParentRollEvents3  
@OutputValue   varchar(25) OUTPUT,  
@Turnover_Event_Id   int,  -- c 1  
@Var_Id    int,  -- d 2  
@Roll_PU_Id    int,  -- e 3  
@Default_Status   varchar(25), -- f 4  
@ULID_Header   varchar(25), -- g 5  
@ULID_SN_Reserved  int,  -- h 6  
@PRID_Header   varchar(25), -- i  7  
@Safety_Limit   int,  -- j  8  
@DT_PU_Id   int,  -- k 9  
@PRID_Var_Id   int,  -- l 10  
@False_Status   varchar(25), -- m 11  
@QCS_Weight_PU_Id  int,  -- a 12  
@QCS_Roll_Weight_Var_Id int,  -- n 13  
@Calling_User_Id  int,  -- a 14  
@AliasValues_Var_Id  int,  -- o 15  
@AliasValuesByRatio_Var_Id int,  -- p 16  
@AliasValuesByPosition_Var_Id int  -- q 17  
As  
  
/* Testing   
Select @Turnover_PU_Id  = 7,  
 @Turnover_TimeStamp  = '2001-11-02 16:57:18.000',  
 @Turnover_Event_Id  = 42427,  
 @Var_Id   = 75,  
 @Roll_PU_Id   = 11,  
 @Default_Status  = 'Good',  
 @ULID_Header  = '004003700163',  
 @ULID_SN_Reserved = 1000,  
 @PRID_Header  = '2M',  
 @Safety_Limit  = 48,  
 @DT_PU_Id  = 10  
*/  
  
--Select @PRID_Var_Id = 610  
  
Declare @Turnover_PU_Id   varchar(30),  
 @Turnover_TimeStamp   datetime,  
 @Turnover_Status  int,  
 @Turnover_Num   varchar(25),  
 @Turnover_Id   varchar(25),  
 @Turnover_User_Id  int,  
 @Prod_Code    varchar(25),  
 @Prod_Id    int,  
 @Prop_Id    int,  
 @Spec_Id    int,  
 @Char_Id   int,  
 @Char_Group_Id  int,  
 @Position_Label  varchar(25),  
 @Roll_TimeStamp  datetime,  
 @Roll_Id   int,  
 @Roll_Event_Id   int,  
 @Have_Events   int,  
 @Roll_Ratio   float,  
 @Last_TimeStamp  datetime,  
 @Last_Event_Id  int,  
 @Last_Event_Num  varchar(25),  
 @GCAS_Family_Desc  varchar(25),  
 @GCAS_Family_Id  int,  
 @GCAS_Prod_Id  int,  
 @Default_Status_Id  int,  
 @FIRE_Status_Id  int,  
 @FIRE_Count   int,  
 @Consumed_Status_Id  int,  
 @Value    varchar(25),  
 @Char_Base    int,   
 @Char_Index    int,   
 @Duplicate_Count  int,  
 @Loop_Count   int,  
 @Turnover_Count  int,  
 @Turnover_Total  int,  
 @Component_Id  int,   --   
 @DT_Count   int,   -- Downtime count for FIRE roll check  
 @Default_Window  int,   -- Default window for last roll search  
 @ULID    varchar(25),  -- ULID  
 @ULID_Length   int,   -- ULID  
 @ULID_SN   int,   -- ULID  
 @ULID_SN_String  varchar(25),  -- ULID  
 @ULID_SN_Max  int,   -- ULID  
 @Prod_Start_Date  datetime,  -- PRID start date for turnover count  
 @Julian_Date   varchar(25),  -- PRID julian date  
 @Crew    varchar(25),  -- PRID team designation  
 @PRID    varchar(25),  -- PRID  
 @Roll_Label_Spec_Id  int,  
 @Roll_Label_Spec_Info  varchar(25),  
 @Roll_Ratio_Spec_Id  int,  
 @Roll_Ratio_Spec_Info  varchar(25),  
 @Roll_Char_Id   int,  
 @False_Turnover_Status_Id int,  
 @Last_Roll_Event_Id  int,  
 @Position_Key   varchar(25),  
 @Position_Filter   varchar(25),  
 @Alias_DS_Id   int,  
 @Float_Data_Type_Id  int,  
 @Production_ET_Id  int  
  
  
Create Table #EventUpdates (  
 Result_Set_Type int Default 1,  
 Id        int Identity,  
 Transaction_Type  int Default 1,   
 Event_Id   int Null,   
 Event_Num   varchar(25) Null,   
 PU_Id    int Null,   
 TimeStamp   datetime Null,  
 Applied_Product  int Null,   
 Source_Event   int Null,   
 Event_Status   int Null,   
 Confirmed   int Default 1,  
 User_Id   int Default 1,  
 Post_Update  int Default 0)  
  
Create Table #VariableUpdates(  
 Result_Set_Type int Default 2,  
 Var_Id    int Null,  
 PU_Id   int Null,  
 User_Id   int Default 26,  
 Canceled  int Default 0,  
 Result   varchar(25) Null,  
 Result_On  datetime Null,  
 Transaction_Type int Default 1,  
 Post_Update  int Default 0)  
  
Create Table #EventDetails (  
 Result_Set_Type int Default 10,  
 Pre_Update       int Default 1,  
 User_Id   int Default 1,  
 Transaction_Type  int Default 1,   
 Transaction_Number int Null,   -- Must be NULL  
  Event_Id  int Null,  
  PU_Id   int Null,  
 Primary_Event_Num varchar(25) Null,  
 Alternate_Event_Num varchar(25) Null,  
 Comment_Id  int Null,  
 Event_Type  int Null,  
 Original_Product  int Null,  
 Applied_Product  int Null,  
 Event_Status  int Default 5,  
 TimeStamp  datetime Null,  
 Entered_On  datetime Null,  
 PP_Setup_Detail_Id int Null,  
 Shipment_Item_Id int Null,  
 Order_Id  int Null,  
 Order_Line_Id  int Null,  
 PP_Id   int Null,  
 Initial_Dimension_X float Null,  
 Initial_Dimension_Y float Null,  
 Initial_Dimension_Z float Null,  
 Initial_Dimension_A float Null,  
 Final_Dimension_X float Null,  
 Final_Dimension_Y float Null,  
 Final_Dimension_Z         float Null,  
 Final_Dimension_A         float Null,  
 Orientation_X   tinyint Null,  
 Orientation_Y   tinyint Null,  
 Orientation_Z  tinyint Null)  
  
Create Table #EventComponents (  
 Result_Set_Type int Default 11,  
 Pre_Update       int Default 1, -- 1=Pre-Update; 0=Post-Update  
 User_Id   int Default 1,  
 Transaction_Type  int Default 1,   
 Transaction_Number int Default 0, -- Must be 0  
 ComponentId  int Null,  
 EventId   int Null,  
 SrcEventId   int Null,  
 DimX   float Default 0,   
 DimY   float Default 0,   
 DimZ   float Default 0,   
 DimA   float Default 0)  
  
/* Get additional turnover information */  
Select  @Turnover_PU_Id = PU_Id,  
 @Turnover_TimeStamp = TimeStamp,  
 @Turnover_Status = Event_Status,  
 @Turnover_Id  = Event_Num,  
 @Turnover_User_Id = User_Id  
From Events  
Where Event_Id = @Turnover_Event_Id  
  
If ((@Turnover_User_Id = @Calling_User_Id) Or (@Turnover_User_Id > 50 And @Calling_User_Id = 26))  
     Begin  
     If (Select count(Event_Id) From Event_Components Where Source_Event_Id = @Turnover_Event_Id) = 0  
          Begin  
          /* Initialization */  
          Select @Consumed_Status_Id   = 8,  -- Status Id  
  @Char_Base    = 64,  -- Constant for incrementing event number  
  @Char_Index    = 28,  -- Constant for incrementing event number  
  @Default_Window   = 365,  -- Number of days the sp will look back for the most recent event  
  @Last_Event_Id   = Null,  
  @Last_Roll_Event_Id  = Null,  
  @ULID_SN_String  = Null,  
  @ULID_Length   = 19,  
  @ULID_SN_Max  = 9999999 - @ULID_SN_Reserved,  
  @ULID_SN   = 0,  
  @Roll_Label_Spec_Info  = '\Roll_Pos_Label\',  
  @Roll_Ratio_Spec_Info  = '\Roll_Ratio\',  
  @DT_Count   = 0,  
  @Crew    = 'X', -- Default crew  
  @Position_Key   = 'POSITION=',  
  @Alias_DS_Id   = 7,  
  @Float_Data_Type_Id  = 2,  
  @Production_ET_Id  = 1  
   
          /* Verify Arguments */  
          Select @ULID_Header  = LTrim(RTrim(IsNull(@ULID_Header, ''))),  
         @PRID_Header  = LTrim(RTrim(IsNull(@PRID_Header, '')))  
  
          /* Get default status id */  
          Select @Default_Status_Id = ProdStatus_Id  
          From Production_Status  
          Where ProdStatus_Desc = Ltrim(Rtrim(@Default_Status))  
  
          /************************************************************************************************************************************************************************  
          *                                                            Get last Turnover timestamp (for cleanup to check for FIRE status)                                                           *  
          ************************************************************************************************************************************************************************/  
          /* Get the last event timestamp by event id.  */  
          Select TOP 1 @Last_Event_Id = Event_Id, @Last_TimeStamp = TimeStamp  
          From Events  
          Where  PU_Id = @Turnover_PU_Id And TimeStamp < @Turnover_TimeStamp And TimeStamp > DateAdd(dd, -@Default_Window, @Turnover_TimeStamp)  
          Order By TimeStamp Desc  
  
          If @Last_Event_Id Is Not Null  
               Begin  
       
               /* Find rolls through genealogy and update status to FIRE - Omit all rolls that are or were set to FIRE*/  
               Select @FIRE_Count = Count(e.Event_Id)  
               From Events e  
                    Inner Join Event_Components ec On e.Event_Id = ec.Event_Id  
               Where e.Event_Status = @FIRE_Status_Id And ec.Source_Event_Id = @Turnover_Event_Id  
  
               If @FIRE_Count > 0 And Datediff(hh, @Last_TimeStamp, @Turnover_TimeStamp) > @Safety_Limit  
                    Begin  
                    /* Check for to see if there was a downtime since the last FIRE roll */  
                    If @DT_PU_Id Is Not Null  
                         Select @DT_Count = Count(TEDet_Id)  
                         From Timed_Event_Details  
                         Where PU_Id = @DT_PU_Id  And End_Time < @Turnover_TimeStamp And End_Time > @Last_TimeStamp  
  
                    If @DT_Count = 0  
                         Select @Default_Status_Id = @FIRE_Status_Id  
                    End  
               End  
          Else  
               Select @Last_TimeStamp = DateAdd(dd, -@Default_Window, @Turnover_TimeStamp)  
  
          /*********************************************************************************************************************  
          *                         Get product based roll configuration from the characteric groups                              *  
          *********************************************************************************************************************/  
          /* Find the current running product and its associated product code */  
          Select @Prod_Id = Prod_Id   
          From Production_Starts   
          Where PU_Id = @Turnover_PU_Id And Start_Time <= @Turnover_TimeStamp And (End_Time > @Turnover_TimeStamp Or End_Time Is Null)       
  
          Select @Prod_Code = Prod_Code  
          From Products   
          Where Prod_Id = @Prod_Id  
  
          /* Get Characteristic Group ID - Use the attached variables specification to determine which property to look under */  
          Select @Spec_Id = Spec_Id  
          From Variables   
          Where Var_Id = @Var_Id  
  
          Select @Prop_Id = Prop_Id   
          From Specifications   
          Where Spec_Id = @Spec_Id  
  
          Select @Char_Group_Id = Characteristic_Grp_Id  
          From Characteristic_Groups  
          Where Prop_Id = @Prop_Id And Characteristic_Grp_Desc = @Prod_Code  
  
          /* Get label to indicate position in PRID */  
          Select @Roll_Label_Spec_Id = Spec_Id  
          From Specifications  
          Where Extended_Info = @Roll_Label_Spec_Info And Prop_Id = @Prop_Id  
  
          /* Get ratio for Event components and QCS Weight split */  
          Select @Roll_Ratio_Spec_Id = Spec_Id  
          From Specifications  
          Where Extended_Info = @Roll_Ratio_Spec_Info And Prop_Id = @Prop_Id  
  
          /************************************************************************************************************************************************************************  
          *                                                                                           Initialize ULID Calculation                                                                                            *  
          ************************************************************************************************************************************************************************/  
          /* Find the most recently created event to get the last created ULID so we can increment it - ASSUME that ULID is unique per PU_Id */  
          Select TOP 1 @ULID_SN_String = substring(Event_Num, len(@ULID_Header) + 1, @ULID_Length - len(@ULID_Header) - 1)  
          From Events  
          Where PU_Id = @Roll_PU_Id And Timestamp > dateadd(d, -365, @Turnover_TimeStamp)  
          Order By Event_Id Desc  
  
          If IsNumeric(@ULID_SN_String) = 1  
               Select @ULID_SN = convert(int, @ULID_SN_String)  
  
          /************************************************************************************************************************************************************************  
          *                                                                                           Initialize PRID Calculation         *  
          ************************************************************************************************************************************************************************/  
          /* Parse TID for Team (T), Julian Date (J) and Turnover Number (N) from TID format XXJJJJTNNN */  
          Select  @Crew    = substring(@Turnover_Id, 7, 1),  
               @Julian_Date   = substring(@Turnover_Id, 3, 4),  
  @Turnover_Num  = right(@Turnover_Id, 3)  
  
          /* MKW 01/25/02 - Ensure valid else count number of events in the current day */  
          /* Get TimeStamp for the start of the current day in order to calculate number of events in the current day*/  
          Select @Prod_Start_Date = convert(datetime, floor(convert(float, @Turnover_TimeStamp)))  
           If IsNumeric(@Turnover_Num) = 1  
               Select @Turnover_Count = convert(int, @Turnover_Num)  
          Else  
               Select @Turnover_Count = count(Event_Id)  
               From Events   
               Where PU_Id = @Turnover_PU_Id And TimeStamp >= @Prod_Start_Date And TimeStamp < dateadd(dd, 1, @Prod_Start_Date)   
  
          /************************************************************************************************************************************************************************  
          *                                                                          Create Individual Parent Roll Production Events                                                                           *  
          ************************************************************************************************************************************************************************/  
          /* Initialize first roll's timestamp */  
          Select @Roll_TimeStamp = DateAdd(s, count(Char_Id)*-1+1, @Turnover_TimeStamp)  
          From Characteristic_Group_Data  
          Where Characteristic_Grp_Id = @Char_Group_Id  
  
          /* Create rows for the designated number of rolls and fill in the descriptions and characteristic ids */  
          Declare Rolls_Cursor Cursor For  
          Select cgd.Char_Id  
          From Characteristic_Group_Data cgd  
        Inner Join Characteristics c On cgd.Char_Id = c.Char_Id  
          Where cgd.Characteristic_Grp_Id = @Char_Group_Id  
          Order By c.Char_Desc Asc  
          For Read Only  
          Open Rolls_Cursor  
  
          Fetch Next From Rolls_Cursor Into @Roll_Char_Id  
          While @@FETCH_STATUS = 0  
               Begin  
               /* Initialization */  
               Select @Roll_Event_Id  = Null,  
                    @Component_Id  = Null,  
          @Roll_Ratio  = 0.0  
  
               /* Check for existing rolls */  
               Select @Roll_Event_Id = Event_Id From Events Where PU_Id = @Roll_PU_Id And TimeStamp = @Roll_TimeStamp  
  
               If @Roll_Event_Id Is Null  
                    Begin  
                    /************************************************************************************************************************************************************************  
                    *                                                                                                    Create ULID                                                                                                       *  
                    ************************************************************************************************************************************************************************/  
                    Select  @Duplicate_Count  = 1,  
           @Loop_Count  = 0  
  
                    /**** Create ULID ****/  
                    While @Duplicate_Count > 0 And @Loop_Count < 1000000  
                         Begin   
                         /* Increment Serial Number */  
                         Select @ULID_SN = @ULID_SN + 1  
            
                        /* If reach maximum serial number check to see if as many events in table to see whether should reset or just continue */  
                         If @ULID_SN >= @ULID_SN_Max  
                              If (Select Count(Event_Id) From Events Where PU_Id = @Roll_PU_Id) < @ULID_SN_Max  
                                   Select @ULID_SN = 0  
  
                         /* Build ULID */  
                         Execute spLocal_CreateULID @ULID OUTPUT, @ULID_Header, @ULID_SN  
  
                         /* Check for existing event numbers */  
                         Select @Duplicate_Count = Count(Event_Id)   
                         From Events   
                         Where PU_Id = @Roll_PU_Id And Event_Num = @ULID  
  
                         Select @Loop_Count = @Loop_Count + 1        /* Prevent infinite loops */  
                         End  
  
                    /************************************************************************************************************************************************************************  
                    *                                                                                                    Create PRID                                                                                                       *  
                    ************************************************************************************************************************************************************************/  
                    Select @Position_Label = Target  
                    From Active_Specs  
                    Where Spec_Id = @Roll_Label_Spec_Id And Char_Id = @Roll_Char_Id And  
                          Effective_Date <= @Turnover_TimeStamp and ((Expiration_Date > @Turnover_TimeStamp) or (Expiration_Date Is Null))  
  
                    Select  @Duplicate_Count  = 1,  
               @Loop_Count  = 0  
  
                    /* Build the Event number, check for duplicates and if found increment counter and rebuild the event number */  
                    While @Duplicate_Count > 0 And @Loop_Count < 1000  
                         Begin  
                         /* Build the PRID:  Header + Team + Turnover Count + Position + Julian Date */  
                         /* MKW 01/25/02 - Added 1000 instead of 1001 to the @Turnover_Count) */  
                         Select @PRID =  rtrim(ltrim(@PRID_Header)) +   
           rtrim(ltrim(@Crew)) +   
    right(convert(varchar(25),@Turnover_Count+1000),3) +   
    rtrim(ltrim(@Position_Label)) + @Julian_Date  
  
                         /* Check for existing event numbers */  
                         Select @Duplicate_Count = count(Event_Id)   
                         From Event_Details  
                         Where PU_Id = @Roll_PU_Id And Alternate_Event_Num = @PRID  
  
                         If @Duplicate_Count > 0  
                              Select @Turnover_Count = @Turnover_Count + 1  
  
                         Select @Loop_Count = @Loop_Count + 1        /* Prevent infinite loops */  
                         End  
                     If @PRID_Var_Id Is Not Null And @PRID_Var_Id > 0  
                         Insert Into #VariableUpdates (Var_Id, PU_Id, Result, Result_On)   
                         Values (@PRID_Var_Id, @Roll_PU_Id, @PRID, @Roll_TimeStamp)  
  
                    /************************************************************************************************************************************************************************                     *                                           
                                              Create Parent Roll Event                                                                                               *  
                    ************************************************************************************************************************************************************************/  
                    /* Hot insert roll into Events */  
                    Execute spServer_DBMgrUpdEvent  @Roll_Event_Id  OUTPUT,  
      @ULID,  
      @Roll_PU_Id,  
      @Roll_TimeStamp,  
      Null,  
      Null,  
      @Default_Status_Id,  
      1,  
      0,  
      6,  
      Null,  
      Null,  
      Null,  
      Null,  
      Null,  
      1  
  
                    Insert into #EventUpdates (Transaction_Type, Event_Id, Event_Num, PU_Id, TimeStamp, Applied_Product, Source_Event, Event_Status, Post_Update)  
                    Values(1, @Roll_Event_Id, @ULID, @Roll_PU_Id, @Roll_TimeStamp, @GCAS_Prod_Id, @Turnover_Event_Id, @Default_Status_Id, 1)  
  
                    /************************************************************************************************************************************************************************  
                    *                                                                                   Create Genealogy Link to Turnover                                                                                     *  
                    ************************************************************************************************************************************************************************/  
                    /* Get roll ratio */  
                    Select @Roll_Ratio = convert(float, Target)  
                    From Active_Specs  
                    Where Spec_Id = @Roll_Ratio_Spec_Id And Char_Id = @Roll_Char_Id And IsNumeric(Target) = 1 And  
                                Effective_Date <= @Turnover_TimeStamp and ((Expiration_Date > @Turnover_TimeStamp) or (Expiration_Date Is Null))  
  
                    /* Hot insert roll into Event_Components */  
                    Execute spServer_DBMgrUpdEventComp  1,  
       @Roll_Event_Id,  
       @Component_Id OUTPUT,  
       @Turnover_Event_Id,  
       0,  
       0,  
       0,  
       @Roll_Ratio,  
       0,  
       1,  
       Null  
  
                    Insert into #EventComponents (Pre_Update, Transaction_Type, ComponentId, EventId, SrcEventId)  
                    Values (0, 1, @Component_Id, @Roll_Event_Id, @Turnover_Event_Id)  
  
                    /************************************************************************************************************************************************************************  
                    *                                                                    Create Event Details for ULID Serial Number and PRID                                                                     *  
                    ************************************************************************************************************************************************************************/  
                    /* Fill out Event_Details with PRID into Alternate_Event_Num and Serial Number into Primary_Event_Num */  
                    Insert Into #EventDetails (Event_Id, PU_Id, TimeStamp, Alternate_Event_Num, Primary_Event_Num)  
                    Values( @Roll_Event_Id, @Roll_PU_Id, @Roll_TimeStamp, @PRID, convert(varchar(25), @ULID_SN))  
  
                    /************************************************************************************************************************************************************************  
                    *                                                                                   Process Associated Variables                                                                                              *  
                    ************************************************************************************************************************************************************************/  
                    Insert Into #VariableUpdates (Var_Id, PU_Id, Result, Result_On)   
                    Select v.Var_Id, v.PU_Id, s.Target, @Roll_TimeStamp  
                    From Variables v  
                         Inner Join Active_Specs s On s.Spec_Id = v.Spec_Id  
                    Where v.PU_Id = @Roll_PU_Id And s.Char_Id = @Roll_Char_Id And  
                          Effective_Date <= @Turnover_TimeStamp And ((Expiration_Date > @Turnover_TimeStamp) or (Expiration_Date Is Null))  
  
                    /************************************************************************************************************************************************************************  
                    *                                                                          Move any Turnover Data to Rolls by the Aliases                                                                          *  
                    ************************************************************************************************************************************************************************/  
                    /* Values */  
                    Insert Into #VariableUpdates (Var_Id, PU_Id, Result, Result_On)   
                    Select v.Var_Id,      -- Var_Id  
   v.PU_Id,      -- PU_Id  
   st.Result,      -- Result  
   @Roll_TimeStamp     -- Result_On              
                    From Variables v  
                         Inner Join Variable_Alias va On v.Var_Id = va.Dst_Var_Id  
                         Inner Join Calculation_Instance_Dependencies cid On va.Src_Var_Id = cid.Var_Id And cid.Result_Var_Id = @AliasValues_Var_Id  
                         Inner Join tests st On st.Result_On = @Turnover_TimeStamp And va.Src_Var_Id = st.Var_Id And st.Result Is Not Null  
                    Where v.PU_Id = @Roll_PU_Id And v.DS_Id = @Alias_DS_Id And v.Event_Type = @Production_ET_Id  
  
                    /* Values By Roll Ratio*/  
                    Insert Into #VariableUpdates (Var_Id, PU_Id, Result, Result_On)   
                    Select v.Var_Id,        -- Var_Id  
   v.PU_Id,        -- PU_Id  
   ltrim(str(convert(float, st.Result)*@Roll_Ratio/100, 15, Var_Precision)), -- Result  
   @Roll_TimeStamp       -- Result_On              
                    From Variables v  
                         Inner Join Variable_Alias va On v.Var_Id = va.Dst_Var_Id  
                         Inner Join Calculation_Instance_Dependencies cid On va.Src_Var_Id = cid.Var_Id And cid.Result_Var_Id = @AliasValuesByRatio_Var_Id  
                         Inner Join tests st On st.Result_On = @Turnover_TimeStamp And va.Src_Var_Id = st.Var_Id And st.Result Is Not Null  
                    Where v.PU_Id = @Roll_PU_Id And v.DS_Id = @Alias_DS_ID And v.Event_Type = @Production_ET_Id And v.Data_Type_Id = @Float_Data_Type_Id  
  
                    /* Values By Roll Position */  
                    Select @Position_Filter = '%' + @Position_Key + @Position_Label + '%'  
                    Insert Into #VariableUpdates (Var_Id, PU_Id, Result, Result_On)   
                    Select v.Var_Id,      -- Var_Id  
   v.PU_Id,      -- PU_Id  
   st.Result,      -- Result  
   @Roll_TimeStamp     -- Result_On              
                    From Variables v  
                         Inner Join Variable_Alias va On v.Var_Id = va.Dst_Var_Id  
                         Inner Join Calculation_Instance_Dependencies cid On va.Src_Var_Id = cid.Var_Id And cid.Result_Var_Id = @AliasValuesByPosition_Var_Id  
                         Inner Join Variables sv On cid.Var_Id = sv.Var_Id And upper(replace(sv.Extended_Info, ' ', '')) Like @Position_Filter  
                         Inner Join tests st On st.Result_On = @Turnover_TimeStamp And va.Src_Var_Id = st.Var_Id And st.Result Is Not Null  
                    Where v.PU_Id = @Roll_PU_Id And v.DS_Id = @Alias_DS_Id And v.Event_Type = @Production_ET_Id  
  
                    End       
  
               /*Increment time for next roll */  
               Select @Roll_TimeStamp = dateadd(s, 1, @Roll_TimeStamp)  
  
               Fetch Next From Rolls_Cursor Into @Roll_Char_Id  
               End  
  
          Close Rolls_Cursor  
          Deallocate Rolls_Cursor  
  
          /*********************************************************************************************************************  
          *                                                       Cleanup orphaned rolls                                                                *  
          *********************************************************************************************************************/  
          /* Cleanup - Check for and delete orphaned rolls */  
          If (Select count(Event_Id) From Events Where PU_Id = @Roll_PU_Id And TimeStamp > @Last_TimeStamp And TimeStamp < @Turnover_TimeStamp) > 0  
               Insert into #EventUpdates (Transaction_Type, Event_Id, Event_Num , PU_Id, TimeStamp, Source_Event, Event_Status)  
               Select 3, e.Event_Id, Event_Num, PU_Id, e.TimeStamp, Source_Event, Event_Status  
               From Events e  
                   Left Outer Join Event_Components ec On e.Event_Id = ec.Event_Id  
               Where  PU_Id = @Roll_PU_Id And e.TimeStamp > @Last_TimeStamp And e.TimeStamp <= @Turnover_TimeStamp And Event_Status <> @Consumed_Status_Id And ec.Event_Id Is Null  
          End  
     Else  
          Begin  
          /* Get false status id */  
          Select @False_Turnover_Status_Id = ProdStatus_Id  
          From Production_Status  
          Where ProdStatus_Desc = Ltrim(Rtrim(@False_Status))  
  
          /*********************************************************************************************************************  
          *                                                       Delete associated rolls                                                                *  
          *********************************************************************************************************************/  
          If @Turnover_Status = @False_Turnover_Status_Id  
               Insert into #EventUpdates (Transaction_Type, Event_Id, Event_Num , PU_Id, TimeStamp, Source_Event, Event_Status)  
               Select 3, e.Event_Id, Event_Num, PU_Id, e.TimeStamp, Source_Event, Event_Status  
               From Events e  
                   Inner Join Event_Components ec On e.Event_Id = ec.Event_Id  
               Where  ec.Source_Event_Id = @Turnover_Event_Id  
               Order By e.TimeStamp Desc  
          End  
  
     /**********************************************************************************************  
     * If the events haven't already been created, then return all values                         *  
     **********************************************************************************************/  
     Select @Have_Events = Count(Id)   
     From #EventUpdates  
  
     If @Have_Events > 0  
          Begin  
          /* Issue Roll Event Updates */  
         If (Select count(Result_Set_Type) From #EventUpdates) > 0  
               Select *  
               From #EventUpdates  
               Where Transaction_Type Is Not Null   
          /* Issue Event Details result sets */  
          If (Select count(Result_Set_Type) From #EventDetails) > 0  
               Select *  
               From #EventDetails  
               Where Transaction_Type Is Not Null   
          /* Issue Roll Event Component Updates */  
          If (Select count(Result_Set_Type) From #EventComponents) > 0   
               Select *  
               From #EventComponents  
               Where Transaction_Type Is Not Null   
          /* Create variable values */  
          If (Select count(Result_Set_Type) From #VariableUpdates) > 0  
               Select *  
               From #VariableUpdates  
               Where Transaction_Type Is Not Null           End      End  
  
/* Cleanup */  
Select @OutputValue = convert(varchar(25), @Have_Events)  
If @OutputValue Is Null  
     Select @OutputValue = '0'  
  
Drop Table #EventUpdates  
Drop Table #VariableUpdates  
Drop Table #EventDetails  
Drop Table #EventComponents  
  
  
  
  
  
  
