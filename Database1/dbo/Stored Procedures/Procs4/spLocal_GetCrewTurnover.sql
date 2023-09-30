     /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-11-02  
Version  : 1.0.4  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_GetCrewTurnover  
Author:   Matthew Wells (MSI)  
Date Created:  10/29/01  
  
Description:  
=========  
This stored procedure is called by the Turnover Production Event model to get the Team currently running the machine at the time of the Turnover.    
The Event Configuration id (EC_Id) is passed which allows us to figure out which PU_Id we're on and then go look up that schedule in the   
Crew_Schedule table.    
  
The stored procedure retrieves the schedule PU_Id from a text string in the attached PU's Extended Info field.  The text string   
has to be in the following format: /PMKG_SCHEDULE_UNIT=###/ (ie.. /PMKG_SCHEDULE_UNIT=899/).  
  
Change Date Who What  
=========== ==== =====  
10/29/01 MKW Added PU_Id to the crew schedule query and changed from local to system table.  
03/19/02 MKW Use of single schedule required search for master schedule pu_id instead of pulling the attached one from Event_Configuration.  
04/02/02 MKW Changed master pu_id flag to actually provide the pu_id.  
*/  
CREATE procedure dbo.spLocal_GetCrewTurnover  
@TimeStamp  datetime,  -- a : Timestamp of the turnover  
@EC_ID int,   -- b : Turnover Production Event configuration id  
@OutputValue varchar(25) OUTPUT -- Team  
As  
SET NOCOUNT ON  
  
Declare @Crew    varchar(25),  
 @PU_Id  int,  
 @Extended_Info varchar(255),  
 @Schedule_PU_Str varchar(25),  
 @Schedule_PU_Id int,  
 @Start_Position  int,  
 @End_Position  int  
  
/* Get PU_Id to find schedule pointer */  
Select @PU_Id = PU_Id   
From [dbo].Event_Configuration  
Where EC_Id = @EC_Id  
  
/* Get Extended info field and parse out the schedule PU_Id */  
Select @Extended_Info = Extended_Info  
From [dbo].Prod_Units  
Where PU_Id = @PU_Id  
  
Select @Start_Position = charindex('/PMKG_SCHEDULE_UNIT=', @Extended_Info, 0) + 20  
Select @End_Position = charindex('/', @Extended_Info, @Start_Position)  
Select @Schedule_PU_Str = substring(@Extended_Info, @Start_Position, @End_Position-@Start_Position)  
  
/* If valid schedule PU_Id, use it, otherwise default to attached PU_Id */  
If IsNumeric(@Schedule_PU_Str) = 1  
     Select @Schedule_PU_Id = convert(int, @Schedule_PU_Str)  
Else  
     Select @Schedule_PU_Id = @PU_Id  
  
/* Get Crew description */  
Select @Crew = Crew_Desc  
From [dbo].Crew_Schedule  
Where Start_Time <= @TimeStamp And End_Time > @TimeStamp And PU_Id = @Schedule_PU_Id  
  
Select @OutputValue = @Crew  
  
SET NOCOUNT OFF  
  
