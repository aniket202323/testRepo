  /*  
  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-10-27  
Version  : 1.0.2  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Stored Procedure: spLocal_CreateRethreadRecord  
Author:   Matthew Wells (MSI)  
Date Created:  11/12/01  
  
Description:  
=========  
This stored procedure monitors a bit indicating the number of sheetbreak rethread attempts and creates an event record every time an attempt is made.  
  
This procedure is written for Model 603 and creates Production events.  As such, a Model 603 must be defined for the Production Event on the   
associated Production Unit.  The event model configuration in the Administrator must be as follows:  
Local spName = spLocal_CreateRethreadRecord (this procedure)  
PI Tag #1 = QCS weight signal  
  
Change Date Who What  
=========== ==== =====  
11/12/01 MKW Created procedure.  
03/13/02 MKW Fixed Julian Date  
*/  
  
CREATE procedure dbo.spLocal_CreateRethreadRecord  
@Success int OUTPUT,  
@ErrorMsg varchar(255) OUTPUT,  
@JumpToTime varchar(30) OUTPUT,  
@ECId int,  
@Reserved1 varchar(30),  
@Reserved2 varchar(30),  
@Reserved3 varchar(30),  
@ChangedTagNum int,  
@ChangedPrevValue varchar(30),  
@ChangedNewValue varchar(30),  
@ChangedPrevTime varchar(30),  
@ChangedNewTime varchar(30),  
@RethreadPrevValue varchar(30),  
@RethreadNewValue varchar(30),  
@RethreadPrevTime varchar(30),  
@RethreadNewTime varchar(30)  
AS  
  
Declare @RethreadPrev  int,  
 @RethreadNew  int,  
 @PU_Id  int,  
 @Event_Id  int,  
 @Start_Date  datetime,  
 @TimeStamp  datetime,  
 @Julian_Date  varchar(25),  
 @Event_Num  varchar(25),  
 @User_id   int,  
 @AppVersion   varchar(30),  
 @StrSQL    varchar(8000)  
  
  
SET NOCOUNT ON  
  
-- Get the Proficy database version  
SELECT @AppVersion = App_Version FROM [dbo].[AppVersions] WHERE App_Name = 'Database'   
  
-- user id for the resulset  
SELECT @User_id = User_id   
FROM Users  
WHERE username = 'Reliability System'  
  
  
If @RethreadNewValue <> @RethreadPrevValue  
     Begin  
  
     /* Convert Arguments */  
     Select @RethreadPrev = convert(int, @RethreadPrevValue)  
     Select @RethreadNew = convert(int, @RethreadNewValue)  
       
     If @RethreadPrev = 0 And @RethreadNew = 1  
          Begin  
  
          /************************************************************************************************************************************************************************  
          *                                                                                          Initialize and Get Additional Data                                                                                  *  
          ************************************************************************************************************************************************************************/  
          /* Initialization */  
          Select @Event_Id = Null  
  
          /* Get PU Id */  
          Select @PU_Id = PU_Id  
          From [DBO].Event_Configuration  
          Where EC_Id = @ECId  
  
          /* Convert More Arguments */  
          Select @TimeStamp  = convert(datetime, @RethreadPrevTime)  
  
          /************************************************************************************************************************************************************************  
          *                                                                       Get Most Recent Event TimeStamp to Prevent Reruns                                                                  *  
          ************************************************************************************************************************************************************************/  
          Select TOP 1 @Event_Id = Event_Id  
          From [DBO].Events  
          Where PU_Id = @PU_Id And TimeStamp >= @TimeStamp  
          Order By TimeStamp Desc  
  
          /* If no other events in the future (ie. this is the most recent event) then continue */  
          If @Event_Id Is Null  
               Begin  
              /************************************************************************************************************************************************************************  
               *                                                                Generate Event Record and Return Value With TimeStamp                                                                 *  
               ************************************************************************************************************************************************************************/  
               /* Get Julian date */  
               Select @Julian_Date = right(datename(yy, @TimeStamp),1)+right('000'+datename(dy, @TimeStamp), 3)  
  
               /* Get TimeStamp for the start of the current day and then calculate event number using events in the current day */  
               Select @Start_Date = convert(datetime, floor(convert(float, @TimeStamp)))  
               --Select @Start_Date = dateadd(hh, -datepart(hh, @TimeStamp), @TimeStamp)  
               --Select @Start_Date = dateadd(mi, -datepart(mi, @TimeStamp), @Start_Date)  
               --Select @Start_Date = dateadd(ss, -datepart(ss, @TimeStamp), @Start_Date)  
               --Select @Start_Date = dateadd(ms, -datepart(ms, @TimeStamp), @Start_Date)  
  
              /* Calculate Event Number using Julian Date and the number of events in the current day */  
               Select @Event_Num = @Julian_Date + right(convert(varchar(25),IsNull(Count(Event_ID), 0)+1001),3)  
               From [DBO].Events  
               Where PU_Id = @PU_Id AND TimeStamp > @Start_Date  
  
               /* Return Event result set to create event record */  
     Select @strSQL = 'Select 1, 1, 1, Null, ''' + @Event_Num + ''', ' + convert(varchar(10),@PU_Id) + ',''' + @RethreadPrevTime +''' , Null, Null, 5, 1,' + convert(varchar(10),@User_id) + ', 0'  
     IF @AppVersion like '4%'  
      select @strSQL = @strSQL + ',Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null, Null'  
  
     EXEC @StrSQL  
  
               End  
          Else  
               Begin  
                    Select @JumpToTime = convert(varchar(30), TimeStamp, 120)  
                    From [DBO].Events  
                    Where Event_Id = @Event_Id  
               End      
         End  
     End  
  
/* Return Values */  
Select @Success = -1  
Select @ErrorMsg = NULL  
  
SET NOCOUNT OFF  
  
