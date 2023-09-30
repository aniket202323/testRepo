 /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-23  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Stored Procedure: spLocal_ClothingLifeSummary  
Author:   Matthew Wells (MSI)  
Date Created:  02/20/02  
  
Description:  
=========  
This procedure calculates the total current life for the running clothing.  
  
Change Date Who What  
=========== ==== =====  
02/20/02 MKW Created.  
03/04/02 MKW Changed '= Running_Status_Id' to '<> Next_On_Status_Id' in clothing event search so that if rerun after clothing is removed it won't return a 0.  
   Updated all associated description lookups as well.  
03/08/02 MKW Changed to add in Clothing Life Prior  
05/10/02 MKW Added different PU_Id for Clothing life downtime vs clothing life events.  
07/31/02 MKW Added check for new Inventory Status as well  
04/05/03 MKW Updated for 215.40  
04/07/03 MKW Removed calls to sub procedures and replaced with Query.  
*/  
CREATE PROCEDURE dbo.spLocal_ClothingLifeSummary  
@Output_Value   varchar(30) OUTPUT,  
@Var_Id   int,  
@Life_Prior_Var_Id  int,  
@DT_PU_Id   int,  
@End_Time   datetime,  
@Conversion   float,  
@Next_On_Status_Desc varchar(30),  
@Inventory_Status_Desc varchar(30)  
AS  
SET NOCOUNT ON  
  
DECLARE @Next_On_Status_Id  int,  
 @Inventory_Status_Id  int,  
 @Clothing_Start_Time  datetime,  
 @Production_Start_Time  datetime,  
 @Start_Time   datetime,  
 @Var_PU_Id   int,  
 @Clothing_PU_Id  int,  
 @Clothing_Life_Prior  varchar(30),  
 @Downtime   real,  
 @Uptime   real,  
 @AppVersion   varchar(30),  
 @User_id   int  
  
 -- user id for the resulset  
 SELECT @User_id = User_id   
 FROM [dbo].Users  
 WHERE username = 'Reliability System'  
   
 -- Get the Proficy database version  
 SELECT @AppVersion = App_Version FROM [dbo].[AppVersions] WHERE App_Name = 'Database'   
  
DECLARE @Tests TABLE(  
 Var_Id      int NULL,  
 PU_Id      int NULL,  
 User_Id     int NULL,  
 Canceled     int DEFAULT 0,  
 Result     varchar(25) NULL,  
 Result_On    datetime NULL,  
 Transaction_Type  int DEFAULT 1,  
 Post_Update    int DEFAULT 0,  
 SecondUserId  int Null,  
 TransNum    int Null,  
 EventId    int Null,  
 ArrayId    int Null,  
 CommentId   int Null)  
  
/* Get the Running status id */  
SELECT @Next_On_Status_Id = ProdStatus_Id  
FROM [dbo].Production_Status  
WHERE ProdStatus_Desc = @Next_On_Status_Desc  
  
SELECT @Inventory_Status_Id = ProdStatus_Id  
FROM [dbo].Production_Status  
WHERE ProdStatus_Desc = @Inventory_Status_Desc  
  
/* Get the sampling window FROM the variable configuration */  
SELECT  @Start_Time  = dateadd(mi, -Sampling_Window, @End_Time),   
  @Var_PU_Id  = PU_Id  
FROM [dbo].Variables  
WHERE Var_Id = @Var_Id  
  
SELECT @Clothing_PU_Id = PU_Id  
FROM [dbo].Variables  
WHERE Var_Id = @Life_Prior_Var_Id  
  
IF @Start_Time < @End_Time  
     BEGIN  
     /************************************************************************************************************************************************************************  
     *                                                                                         Process for all grade changes                                                                                        *  
     ************************************************************************************************************************************************************************/  
     -- Get all product changes in the Sampling Window  
     DECLARE ProductionStarts CURSOR FOR  
     SELECT dateadd(s, -1, Start_Time)  
     FROM [dbo].Production_Starts  
     WHERE PU_Id = @Var_PU_Id And Start_Time > @Start_Time And Start_Time < @End_Time  
     ORDER BY Start_Time ASC  
     OPEN ProductionStarts  
  
     FETCH NEXT FROM ProductionStarts INTO @Production_Start_Time  
     WHILE @@FETCH_STATUS = 0  
          BEGIN  
  
          /* Reinitialization */  
          SELECT  @Clothing_Start_Time = NULL,  
   @Output_Value  = '0.0',  
   @Clothing_Life_Prior = '0.0'  
  
          /* Get the timestamp of the current running clothing event */  
          SELECT TOP 1 @Clothing_Start_Time = TimeStamp  
          FROM [dbo].Events  
          WHERE PU_Id = @Clothing_PU_Id And Event_Status <> @Next_On_Status_Id And Event_Status <> @Inventory_Status_Id And TimeStamp < @Production_Start_Time  
          ORDER BY TimeStamp Desc  
  
          IF @Clothing_Start_Time IS NOT NULL  
               BEGIN  
--               Exec spLocal_UptimeSummary @Output_Value OUTPUT, @DT_PU_Id, @Clothing_Start_Time, @Production_Start_Time, @Conversion  
               SELECT  @Downtime  = 0.0,  
   @Uptime = 0.0  
  
               SELECT @Downtime = isnull(convert(real, sum(datediff(s,  CASE  
         WHEN Start_Time < @Clothing_Start_Time THEN @Clothing_Start_Time  
                ELSE Start_Time  
         END,  
             CASE  
         WHEN End_Time > @Production_Start_Time OR End_Time IS NULL THEN @Production_Start_Time  
          ELSE End_Time  
         END)))/@Conversion, 0.0)  
               FROM [dbo].Timed_Event_Details  
               WHERE PU_Id = @DT_PU_Id And Start_Time < @Production_Start_Time And (End_Time > @Clothing_Start_Time Or End_Time IS NULL)  
  
               SELECT @Uptime = convert(real, datediff(s, @Clothing_Start_Time, @Production_Start_Time))/@Conversion - @Downtime  
               END  
  
          /* Add in Clothing Life Prior */  
          SELECT @Clothing_Life_Prior = Result  
          FROM [dbo].tests  
          WHERE Var_Id = @Life_Prior_Var_Id And Result_On = @Clothing_Start_Time  
  
          IF isnumeric(@Clothing_Life_Prior) = 1  
               BEGIN  
               SELECT @Uptime = @Uptime + convert(real, @Clothing_Life_Prior)  
               END  
  
          /* Return test result set for Product Change */  
          INSERT INTO @Tests ( Var_Id,  
    PU_Id,  
    Result,  
    Result_On,User_id)  
          SELECT @Var_Id,   
   @Var_PU_Id,   
   convert(varchar(25), @Uptime),   
   @Production_Start_Time,  
   @User_id  
  
          /* FETCH NEXT record */  
          FETCH NEXT FROM ProductionStarts INTO @Production_Start_Time  
          END  
  
     /* Cleanup */  
     CLOSE ProductionStarts  
     DEALLOCATE ProductionStarts  
  
     /************************************************************************************************************************************************************************  
     *                                                                                         Process for the current time                                                                                           *  
     ************************************************************************************************************************************************************************/  
     /* Reinitialization */  
     SELECT  @Clothing_Start_Time = NULL,  
  @Output_Value  = '0.0',  
  @Clothing_Life_Prior = '0.0'  
  
     /* Get the timestamp of the current running clothing event */  
     SELECT TOP 1 @Clothing_Start_Time = TimeStamp  
     FROM [dbo].Events  
     WHERE PU_Id = @Clothing_PU_Id And Event_Status <> @Next_On_Status_Id And Event_Status <> @Inventory_Status_Id And TimeStamp < @End_Time  
     ORDER BY TimeStamp DESC  
  
     IF @Clothing_Start_Time Is Not NULL  
          BEGIN  
--        Exec spLocal_UptimeSummary @Output_Value OUTPUT, @DT_PU_Id, @Clothing_Start_Time, @End_Time, @Conversion  
          SELECT  @Downtime  = 0.0,  
  @Uptime = 0.0  
  
          SELECT @Downtime = isNULL(convert(real, Sum(Datediff(s,  Case   
        When Start_Time < @Clothing_Start_Time Then @Clothing_Start_Time  
               Else Start_Time   
        END,  
            Case   
        When End_Time > @End_Time Or End_Time Is NULL Then @End_Time  
         Else End_Time   
        END)))/@Conversion, 0.0)  
          FROM [dbo].Timed_Event_Details  
          WHERE PU_Id = @DT_PU_Id And Start_Time < @End_Time And (End_Time > @Clothing_Start_Time Or End_Time Is NULL)  
  
          SELECT @Uptime = convert(real, datediff(s, @Clothing_Start_Time, @End_Time))/@Conversion - @Downtime  
          END  
  
     /* Add in Clothing Life Prior */  
     SELECT @Clothing_Life_Prior = Result  
     FROM [dbo].tests  
     WHERE Var_Id = @Life_Prior_Var_Id And Result_On = @Clothing_Start_Time  
  
     IF IsNumeric(@Clothing_Life_Prior) = 1  
          BEGIN  
          SELECT @Uptime = @Uptime + convert(real, @Clothing_Life_Prior)  
          END  
  
     SELECT @Output_Value = convert(varchar(30), @Uptime)  
     END  
  
IF (SELECT count(*) FROM @Tests) > 0  
     BEGIN  
  IF @AppVersion LIKE '4%'  
   BEGIN  
    SELECT 2,  
      Var_Id,   
      PU_Id,   
      User_Id,   
      Canceled,   
      Result,   
      Result_On,   
      Transaction_Type,   
      Post_Update,   
      SecondUserId,   
      TransNum,   
      EventId,   
      ArrayId,   
      CommentId  
    FROM @Tests  
   END  
  ELSE  
   BEGIN  
    SELECT 2,  
      Var_Id,   
      PU_Id,   
      User_Id,   
      Canceled,   
      Result,   
      Result_On,   
      Transaction_Type,   
      Post_Update  
    FROM @Tests  
   END  
     END  
  
SET NOCOUNT OFF  
  
