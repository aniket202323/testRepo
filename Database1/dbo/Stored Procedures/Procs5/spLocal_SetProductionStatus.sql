 /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-09  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
-- This procedure is used to flag a downtime event as planned or unplanned.  The variable Production Status is set to 'Planned' if the event is for planned downtime and 'Unplanned' if it is not.  
-- A planned event is determined by using a Proficy Data Type as a list of valid planned events.  The variable @CompareList is a constant variable that contains the  
-- the name of the Data Type.  The value of the Scheduled variable (@Result_VarId is the variable id for this variable, defined in the inputs) is compared to the  
-- data type list.  If the scheduled value is in the list, then we know that the downtime event is planned and the value is set to 'Planned'.  
--  
-- Vince King, Albany, Georgia July 2001  
*/  
  
CREATE PROCEDURE spLocal_SetProductionStatus  
@OutputValue varchar(25) OUTPUT,  
@Pu_Id int,  
@TimeStamp varchar(30),  
@Result_VarId int,  
@CompareList varchar(50),  
@Var_Id int,  
@TrueValue varchar(50),  
@FalseValue varchar(50)  
AS  
SET NOCOUNT ON  
  
Declare @Ext_Info varchar(50),  
 @Start_Position int,  
 @Compare_Result_DataType_Id int,   
 @PU_Compare_VarId int,  
 @Test_Result varchar(50),  
 @Count int,  
 @Compare_Result  varchar(50),  
 @Entry_Date   datetime,  
 @User_id    int,  
 @AppVersion   varchar(30)  
   
-- Get the Proficy database version  
SELECT @AppVersion = App_Version FROM [dbo].[AppVersions] WHERE App_Name = 'Database'  
  
-- user id for the resulset  
SELECT @User_id = User_id   
FROM [dbo].Users  
WHERE username = 'Reliability System'  
   
DECLARE @CompareList_tbl TABLE (  
 Phrase_Desc varchar(50))  
  
--Get variable id for the Prod Unit variable, Breakdown.  
Select @PU_Compare_VarId = @Var_Id  
  
--Get the Data_Type_Id for the Breakdown list Data Type.  
Select @Compare_Result_DataType_Id = Data_Type_Id  
From [dbo].Data_Type  
Where Data_Type_Desc = @CompareList  
  
--Select the list of Breakdowns (Categories) and insert them into a temporary table (#CompareList)  
INSERT INTO @CompareList_tbl (Phrase_Desc)  
 Select Phrase_Value as Phrase_Desc  
 From [dbo].Phrase   
 Where Data_Type_ID = @Compare_Result_DataType_Id  
  
--Get the Category Result from the Tests table for the Downtime Event.  
Select @Test_Result = Result   
From [dbo].Tests  
Where Var_Id = @Result_VarId and Result_On = @TimeStamp  
  
--If the downtime category value is in the list, @Compare_Result = 1, else @Compare_Result = 0  
If (Select Count(*) From @CompareList_tbl Where Phrase_Desc = @Test_Result) > 0   
  Select @Compare_Result = @TrueValue  
Else  
  Select @Compare_Result = @FalseValue  
  
Select @Entry_Date = GetDate()  
  
--MKW 08/06/01 - No temp table  
--insert into Local_TempBackCalcs (comment, time_stamp, result, entry_date) values (@PU_Compare_VarId, @TimeStamp, @Compare_Result, @Entry_Date)  
  
--Return the info required to have the Proficy service write Breakdown value to the Tests table.  
IF @AppVersion LIKE '4%'  
 BEGIN  
  Select 2,@PU_Compare_VarId,@PU_Id,@User_id,0,@Compare_Result,Result_On = Convert(varchar(30),@TimeStamp, 21),1,0,NULL,NULL,NULL,NULL,NULL  
 END  
ELSE  
 BEGIN  
  Select 2,@PU_Compare_VarId,@PU_Id,@User_id,0,@Compare_Result,Result_On = Convert(varchar(30),@TimeStamp, 21),1,0  
 END  
  
  
Select @OutputValue = @Compare_Result  
  
--Drop the temporary table.  
-- drop table #CompareList  
  
SET NOCOUNT OFF  
